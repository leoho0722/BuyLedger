# BuyLedger — Apple 平台 (iOS / iPadOS / macOS)

BuyLedger 的 Apple 平台實作。產品介紹與 monorepo 結構見 repo 根目錄的 [`README.md`](../../README.md)；本檔涵蓋開發環境設定、build / test 與架構速覽。

## 技術棧

- **Swift 6 + SwiftUI**：strict concurrency
- **TCA ([Swift Composable Architecture](https://github.com/pointfreeco/swift-composable-architecture))**：feature 狀態、商業邏輯、副作用與依賴注入
- **SwiftData + CloudKit**：本機持久化為核心，CloudKit 同步介面 (``PersistenceContainer.CloudKitOption``) 已預留，待 Apple Developer 帳號 provision 後接上
- **Swift Charts**：Insights 頁的趨勢、類別與成本結構視覺化
- **Ollama Cloud**：訂單 AI 商品明細總結 (chat streaming，`OllamaClient`)
- **[swift-snapshot-testing](https://github.com/pointfreeco/swift-snapshot-testing)**：UI 視覺迴歸測試

Xcode 專案：`apps/apple/BuyLedger.xcodeproj`，scheme：`BuyLedger`。需要 **Xcode 26+** 與 Swift 6 toolchain。

Xcode project 使用 file system synchronized groups，新增或搬移檔案請優先動實體資料夾，再用 build 驗證 target 仍正確包含來源與資源。

## 專案結構

```text
apps/apple/
├── BuyLedger.xcodeproj/          # Xcode 專案；project.pbxproj 提交、xcuserdata/ 不提交
├── BuyLedger/                    # App source root
│   ├── App/                      # 進入點：BuyLedgerApp、WindowGroup、macOS Settings scene、CommandGroup
│   ├── Core/
│   │   ├── Domain/               # LedgerOrder、FxRateSnapshot、CurrencyCode 等 model
│   │   ├── Persistence/          # OrderPersistence (@ModelActor)、PersistenceContainer、OrderRecord
│   │   ├── Dependencies/         # OrderRepository 等 5 個 Repository (type-based @Dependency 注入)
│   │   ├── Networking/           # APIError、HTTPClient (send/stream)、HTTPMethod、URLRequestBuilder、AppConfiguration
│   │   └── Sync/                 # 跨裝置同步基礎件：Hlc / HlcClient (每欄位 HLC)、BackendAPIClient (PATCH/DELETE)、SyncMeta / SyncMetaPersistence、SyncQueueItem / SyncQueuePersistence (待送佇列)、CloudSyncFieldMerge、PhotoRefResolver、NetworkPathMonitor
│   ├── Features/                 # 依功能切分的 TCA feature
│   │   ├── AISummary/            # 訂單 AI 商品明細總結 (Ollama Cloud 串流)
│   │   ├── App/                  # RootFeature + RootView + RootSidebarLayout / RootTabLayout
│   │   ├── Campaigns/            # 開團管理
│   │   ├── Customers/            # 客戶名單
│   │   ├── Dashboard/            # 總覽頁
│   │   ├── FX/                   # 匯率工具
│   │   ├── Insights/             # 趨勢分析
│   │   ├── Lookups/              # 主檔管理 (訂單來源／商品類別／付款方式)
│   │   ├── More/                 # iOS / macOS 「更多」入口
│   │   ├── Orders/               # 訂單瀏覽與編輯 (含三平台 view 分流)
│   │   ├── Quote/                # 報價試算
│   │   └── Settings/             # iOS SettingsView + macOS SettingsMacView
│   ├── Shared/
│   │   └── DesignSystem/
│   │       ├── Foundations/      # 色盤、字級、間距、圓角等 token
│   │       └── Components/       # BLAvatar、BLBadge、BLCard、BLBarChart 等元件
│   └── Resources/                # Info.plist、entitlements、Config.example.xcconfig (範本，實際 Config.xcconfig 自填且 gitignored)、assets
├── BuyLedgerTests/               # 單元測試 + swift-snapshot-testing baseline
└── BuyLedgerUITests/             # UI 與啟動畫面測試
```

## 開發環境設定

### 1. API 金鑰 (Config.xcconfig)

App 使用兩把 API key，皆透過 `Config.xcconfig` 注入 (機密)：

| 變數 | 用途 | 申請位置 |
|---|---|---|
| `EXCHANGE_RATE_API_KEY` | 匯率與幣別清單 (ExchangeRate-API v6) | [exchangerate-api.com](https://www.exchangerate-api.com)；30 日 sparkline 需 Pro/Business 方案 |
| `OLLAMA_API_KEY` | 訂單 AI 商品明細總結 (Ollama Cloud chat streaming) | [ollama.com](https://ollama.com) → Account → API keys |

1. 複製 `apps/apple/BuyLedger/Resources/Config.example.xcconfig` 為 `Config.xcconfig` (同目錄)：

   ```bash
   cp apps/apple/BuyLedger/Resources/Config.example.xcconfig apps/apple/BuyLedger/Resources/Config.xcconfig
   ```

2. 編輯 `Config.xcconfig`，填入你的 key：

   ```text
   EXCHANGE_RATE_API_KEY = your-key-here
   OLLAMA_API_KEY = your-key-here
   ```

`Config.xcconfig` 已列入 `.gitignore`，**請勿提交**。

注入鏈路說明 (兩把 key 相同)：`Config.xcconfig` → pbxproj 的 `baseConfigurationReference` 掛到 app target 的 Debug + Release config → `Info.plist` 內以 `$(EXCHANGE_RATE_API_KEY)` / `$(OLLAMA_API_KEY)` 引用 build setting，build 時被注入 → `AppConfiguration.liveValue` 從 `Bundle.main.infoDictionary` 讀回。

跨裝置同步的後端位址 `BACKEND_API_BASE_URL` 為非機密，直接定義於 `Info.plist` (本機預設 `http://localhost:4000/api`)，同樣由 `AppConfiguration` 讀回供 `BackendAPIClient` 使用。

未設 key 時 App 仍可啟動：匯率工具與報價頁顯示「尚未設定 ExchangeRate-API 金鑰」橫幅；AI 總結面板顯示「尚未設定 OLLAMA_API_KEY。」並提供重試。

### 2. Build & Run

本專案預設用 `xcodebuildmcp` CLI 跑 build / run / test (MCP server `mcp__XcodeBuildMCP__*` 留給 UI 自動化、結構化測試結果與長時間操作可控中斷的情境)。下列指令一律從 repo 根目錄執行：

```bash
# iOS Simulator
xcodebuildmcp simulator build-and-run \
  --project-path apps/apple/BuyLedger.xcodeproj \
  --scheme BuyLedger \
  --simulator-name "iPhone 17"

# iPadOS Simulator
xcodebuildmcp simulator build-and-run \
  --project-path apps/apple/BuyLedger.xcodeproj \
  --scheme BuyLedger \
  --simulator-name "iPad Pro 13-inch (M5)"

# macOS
xcodebuildmcp macos build-and-run \
  --project-path apps/apple/BuyLedger.xcodeproj \
  --scheme BuyLedger
```

> ⚠️ 三平台共用同一份 `DerivedData/.../XCBuildData/build.db`，**不可並行 build**——請序列化 (`cmd1 && cmd2 && cmd3`) 以避免 `database is locked` 失敗。
>
> ⚠️ build 失敗時 CLI 預設只回 trailing `BUILD FAILED`；用 `xcodebuildmcp --log-level error <subcommand> ...` 取得實際 diagnostic。
>
> 💡 simulator 名稱會隨 Xcode 升級變動，先用 `xcodebuildmcp simulator list-sims` 查當前可用名稱再改上方指令。macOS 重新跑前用 `xcodebuildmcp macos stop --app-name BuyLedger` 關掉舊 binary，否則會看到舊版。

### 3. 執行測試

```bash
xcodebuildmcp simulator test \
  --project-path apps/apple/BuyLedger.xcodeproj \
  --scheme BuyLedger \
  --simulator-name "iPhone 17"
```

Snapshot baseline 第一次跑會自動 record 並回報 fail (屬正常)，確認視覺正確後 commit baseline；之後變更若與 baseline 不符會 fail。固定時間注入的硬規則 (`TestDependencies.withFixedNow`) 見 [CLAUDE.md › 測試準則](CLAUDE.md#測試準則)。

### 4. 重新產生 data model (codegen)

`Core/Domain/` 的資料形狀由 `shared/data-model` 的跨平台 schema 產生 (格式與細節見 [shared/data-model/README.md](../../shared/data-model/README.md))，生成檔在 `Core/Domain/Generated/`，**不可手改**。增刪欄位或改型別時：

```bash
# 首次安裝產生器依賴 (需 Bun >= 1.3，brew install bun)
cd shared/data-model/generator && bun install

# 改 shared/data-model/schema/ 後重新產生 Swift (輸出到 apps/apple 的 Core/Domain/Generated/)
bun run generate

# 提交前確認生成檔與 schema 同步 (exit 0 才算同步)
bun run check

# (少用) 把生成檔改回可寫，僅供刻意手動檢視／實驗；下次 generate 會重新鎖唯讀
bun run unlock
```

生成檔與 schema 一起 commit。生成檔在磁碟上**預設唯讀** (`generate` 會 chmod `0o444` 防手改)；Xcode 編譯只讀取、不受影響，重生成會自動解鎖重寫。`Core/Domain/` 是 file system synchronized group，新增／刪除型別後請 iOS + iPadOS + macOS 各 build 一次，確認新檔被正確拾取。手寫業務邏輯 (computed properties、display title、自訂 `Codable`) 放在與型別同名的 extension 檔，不放生成檔。

## 架構速覽

### App 進入點與平台導覽

`BuyLedgerApp.swift` 以單一 `RootFeature` store 驅動：`WindowGroup` 掛上 `RootView` 並以 `.modelContainer(...)` 注入共用 SwiftData container；macOS 額外加 `.windowStyle(.hiddenTitleBar)`、用 `CommandGroup` 在 File 選單提供「新訂單」(⌘N，透過 `FocusedValues` 與當前畫面連線)，並宣告獨立的 `Settings { ... }` scene。`RootFeature.State.selectedTab` 驅動三種 layout：

| 平台                      | Layout              | 說明                                                       |
|---------------------------|---------------------|------------------------------------------------------------|
| macOS                     | `RootSidebarLayout` | `NavigationSplitView` + sidebar + 訂單頁 `.inspector(...)` |
| iPad (regular size class) | `RootSidebarLayout` | 同 macOS 的 split 結構但無 inspector                       |
| iPhone (compact)          | `RootTabLayout`     | `TabView`                                                  |

`OrdersView` 是平台分流入口：`#if os(macOS)` → `OrdersMacView` (`List` + `OrderRowView` + 右側 `.inspector(...)`)；iPhone (compact) → `OrdersCompactView` (`NavigationStack`)；iPad (regular) → `NavigationStack` 內以 `HStack` 自排「清單 + 詳情」兩欄 (不用巢狀 `NavigationSplitView`，避免兩層 split 互搶寬度)。`.sheet(...)` 編輯表單一律掛在 `OrdersView` 外層，三平台共用。

macOS 偏好設定走標準 `Settings { ... }` scene (⌘,)，實作在 `Features/Settings/SettingsMacView.swift`，採 `TabView` + `Form` + `.formStyle(.grouped)`；iOS / iPadOS 沿用 `SettingsView` (`Form` + `Section`) 由 `MoreView` push 進入。

### 資料層

- **Repository 層** (`Core/Dependencies/`)：`OrderRepository`、`CategoryRepository`、`PaymentMethodRepository`、`OrderSourceRepository`、`CurrencyMetadataRepository`，各自背後接對應的 `@ModelActor` persistence (`Core/Persistence/`) 操作 SwiftData。所有 repo 共用 `PersistenceContainer.shared` 單一 `ModelContainer`，注入一律走 type-based `@Dependency(SomeRepository.self)`。
- **主檔資料** (訂單來源／商品類別／付款方式) 由 `LookupManagementFeature` (`Features/Lookups/`，以 `LookupKind` 分流) 提供 CRUD；rename 會 cascade 到所有引用該名稱的訂單，cascade 與 in-memory 同步由 `RootFeature` 攔截處理。
- `liveValue`：純本機 SwiftData，**不自動 seed**——使用者首次啟動會看到真正的空狀態。
- `previewValue`：in-memory + 自動 seed `LedgerOrder.sampleOrders`，讓 SwiftUI Preview 與 snapshot 測試看得到內容。
- `LedgerOrder.sampleOrders` 與 `FxRateSnapshot.fallback` **僅供 Preview / 單元測試 / `previewValue`** 使用，runtime 不讀取。
- **Schema 版本化**：`Core/Persistence/BuyLedgerSchema.swift` 以 `VersionedSchema` (floor `BuyLedgerSchemaV10` → target `BuyLedgerSchemaV12`，floor 以下版本已移除) + `BuyLedgerMigrationPlan` 管理遷移。新增欄位／表走 lightweight、改型別走 custom dump-and-restore；改動流程的硬規則見 [`CLAUDE.md › SwiftData Schema 與 Migration`](CLAUDE.md#swiftdata-schema-與-migration)。`V12` 為 lightweight，加入同步專屬的 `SyncMeta` / `SyncQueueItem` 本機 sidecar 表 (與領域型別解耦)；sync 關閉時這兩張表保持空、on-disk 行為與導入前等價。

### 外部 API

`ExchangeRateClient` (`Features/FX/`) 封裝 ExchangeRate-API v6 的兩個 endpoint：`latest/{base}` (匯率) 與 `codes` (幣別清單)。runtime 有兩個 call——`fetchLatest(.twd)` 取最新匯率；App 啟動時經 `CurrencyMetadataRepository.refreshIfStale` 打 `/codes` 載入幣別主檔並 cache 7 天 (幣別清單不再 hardcode)。

`OllamaClient` (`Features/AISummary/`) 串接 Ollama Cloud chat streaming (`POST https://ollama.com/api/chat`)，在訂單詳情串流產生 Markdown 商品明細總結；缺金鑰或服務錯誤時進入 failed 狀態並提供重試，面板關閉時取消串流。逐位元組串流走 `HTTPClient.stream`。

**Fallback 原則**：遵循 root [README.md › 產品政策](../../README.md#產品政策)——匯率與分析 UI 顯示「—」、「尚無可用匯率資料」、「尚未有足夠可用於分析的資料」等空狀態，避免使用者誤信過期或內建匯率。

### 跨裝置同步 (離線優先、預設關閉)

同一帳號的任意兩平台 (iOS↔web) 經後端 (Postgres 為 source of truth) + per-user Firestore 即時投影傳播 Order/Campaign 變更；iOS 端為**離線優先 + opt-in**：SwiftData 維持本機 source of truth，總開關 `Features/App/CloudSyncFeatureFlag.swift` 的 `isEnabled` **預設關閉**。關閉時純本機可用、零網路、不實例化任何引擎；開啟 (Firebase 登入後) 才接通同步通道。基礎件集中在 `Core/Sync/`：

- **欄位級合併以 HLC 決勝**：每欄位帶 Hybrid Logical Clock (`Hlc` / `HlcClient`，序列 `p → c → writerId`，writerId 為 Firebase Installation ID)；client 只送變更欄位的 partial patch，合併集中在後端——不同欄位的並行修改全部保留、同欄位以 HLC 決定性決勝，後端為線性化點並 clamp 時鐘偏移 (5 分鐘)。本機合併套用走 `CloudSyncFieldMerge` 與單一 `OrderPersistence @ModelActor`，使 TCA 功能不與引擎競態。
- **同步引擎**：`Features/App/CloudSyncEngine.swift` 以 `handleLocalSave` (單筆 diff 推送) / `syncAllLocalChanges` (批次／合併／改名全量重比) / `handleLocalDelete` 接收 `OrderRepository` 層統一發出的異動通知，推送 dirty 欄位 patch 至 `BackendAPIClient` (`PATCH`／`DELETE /orders/:id`)，並把投影拉回 upsert 進 SwiftData、觸發 `OrdersFeature.reloadFromStore` 即時刷新畫面。
- **刪除為帶時鐘 tombstone**：刪除帶 `deleteClock`、後端保留 tombstone 90 天，較晚的欄位修改可非破壞性復活 (保留未觸及欄位)，避免殭屍重推。
- **同步失敗不丟資料**：寫入失敗 client retry 3 次後該筆顯示可觀察的待同步／失敗狀態，留在持久化本機佇列 (`SyncQueueItem` / `SyncQueuePersistence`)，連線恢復 (`NetworkPathMonitor`) 或下次啟動自動重送；重送以 client UUID upsert + 確定性伺服器時鐘保證冪等。每欄位時鐘、dirty 集、tombstone、pending／failed、lastIssued HLC、照片參照等同步 metadata 放本機專屬 sidecar (`SyncMeta` / `SyncMetaPersistence`)，不污染 `OrderRecord` 或生成型別。照片參照 (Firestore 投影的 `photoRefs`) 在欄位合併前先經 `PhotoRefResolver` 解析回 `[Data]`。

> 後端鏡像失敗的自我修復 (有限次內聯重試後標 `mirrorDirty`、由 `@Interval` 每 30 秒掃描自 Postgres 重新鏡像) 屬後端職責，見 [`apps/backend/README.md`](../backend/README.md)。

## Troubleshooting

### macOS 沙盒下回到「真正空狀態」

macOS 版的 SwiftData store 位於：

```text
~/Library/Containers/com.leoho.BuyLedger/Data/Library/Application Support/BuyLedger.store{,-shm,-wal}
```

要回到剛安裝、無任何訂單的空狀態時，先停掉 App (釋放檔案 lock) 再手動刪除這三個檔案。

### macOS DNS 失敗 (NSURLErrorDomain Code -1003)

如果 macOS build 出來連外部 API 都打不通，先檢查：

1. `BuyLedger.entitlements` 是否含 `com.apple.security.network.client = true`。
2. pbxproj 是否正確掛上 `CODE_SIGN_ENTITLEMENTS = BuyLedger/Resources/BuyLedger.entitlements;`——若沒掛，binary 上只會有 Xcode 自動加的 sandbox key，runtime 抓不到設定的 entitlements。

### Snapshot baseline 漂移

設計大改時請刪掉對應 baseline (`BuyLedgerTests/__Snapshots__/SnapshotTests/*.png`) 讓下一次跑測試自動重建。Baseline 失準若不是來自設計變動，先確認測試是否走 `TestDependencies.withFixedNow { ... }` 注入固定 `Date`、`TimeZone`、`Calendar`。
