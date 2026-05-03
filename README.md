# BuyLedger

為個人代購業務而生的本地優先帳本 App，跨 iOS、iPadOS、macOS 三平台執行。

## 技術棧

- **Swift 6 + SwiftUI**：strict concurrency
- **TCA（[Swift Composable Architecture](https://github.com/pointfreeco/swift-composable-architecture)）**：feature 狀態、商業邏輯、副作用與依賴注入
- **SwiftData + CloudKit**：本機持久化為核心，CloudKit 同步介面（``PersistenceContainer.CloudKitOption``）已預留，待 Apple Developer 帳號 provision 後接上
- **Swift Charts**：Insights 頁的趨勢、類別與成本結構視覺化
- **[swift-snapshot-testing](https://github.com/pointfreeco/swift-snapshot-testing)**：UI 視覺迴歸測試

Xcode 專案：`BuyLedger/BuyLedger.xcodeproj`，scheme：`BuyLedger`。需要 **Xcode 26+** 與 Swift 6 toolchain。

## 專案結構

```text
BuyLedger/
├── BuyLedger.xcodeproj/          # Xcode 專案；project.pbxproj 提交、xcuserdata/ 不提交
├── BuyLedger/                    # App source root
│   ├── App/                      # 進入點：BuyLedgerApp、WindowGroup、macOS Settings scene、CommandGroup
│   ├── Core/
│   │   ├── Domain/               # LedgerOrder、FxRateSnapshot、CurrencyCode 等 model
│   │   ├── Persistence/          # OrderPersistence (@ModelActor)、PersistenceContainer、OrderRecord
│   │   ├── Dependencies/         # OrderRepository、HTTPClient、APIKeyProvider
│   │   └── Networking/           # APIError、HTTPClient、APIKeyProvider 介面
│   ├── Features/                 # 依功能切分的 TCA feature
│   │   ├── App/                  # RootFeature + RootView + RootSidebarLayout / RootTabLayout
│   │   ├── Dashboard/            # 總覽頁
│   │   ├── Orders/               # 訂單瀏覽與編輯（含三平台 view 分流）
│   │   ├── Insights/             # 趨勢分析
│   │   ├── Quote/                # 報價試算
│   │   ├── FX/                   # 匯率工具
│   │   ├── Customers/            # 客戶名單
│   │   ├── More/                 # iOS / macOS 「更多」入口
│   │   └── Settings/             # iOS SettingsView + macOS SettingsMacView
│   ├── Shared/
│   │   └── DesignSystem/
│   │       ├── Foundations/      # 色盤、字級、間距、圓角等 token
│   │       └── Components/       # BLAvatar、BLBadge、BLCard、BLBarChart 等元件
│   └── Resources/                # Info.plist、entitlements、Config.example.xcconfig（範本，實際 Config.xcconfig 自填且 gitignored）、assets
├── BuyLedgerTests/               # 單元測試 + swift-snapshot-testing baseline
└── BuyLedgerUITests/             # UI 與啟動畫面測試
```

Xcode project 使用 file system synchronized groups，新增或搬移檔案請優先動實體資料夾，再用 build 驗證 target 仍正確包含來源與資源。

## 開發環境設定

### 1. ExchangeRate-API 金鑰

1. 到 [exchangerate-api.com](https://www.exchangerate-api.com) 申請免費帳號取得 API key。
2. 複製 `BuyLedger/Resources/Config.example.xcconfig` 為 `Config.xcconfig`（同目錄）：

   ```bash
   cp BuyLedger/Resources/Config.example.xcconfig BuyLedger/Resources/Config.xcconfig
   ```

3. 編輯 `Config.xcconfig`，填入你的 key：

   ```text
   EXCHANGE_RATE_API_KEY = your-key-here
   ```

`Config.xcconfig` 已列入 `.gitignore`，**請勿提交**。

注入鏈路說明：`Config.xcconfig` → pbxproj 的 `baseConfigurationReference` 掛到 app target 的 Debug + Release config → `Info.plist` 內 `EXCHANGE_RATE_API_KEY` key 引用 `$(EXCHANGE_RATE_API_KEY)` build setting，build 時被注入 → `APIKeyProvider.liveValue` 從 `Bundle.main.infoDictionary` 讀回。

未設 key 時 App 仍可啟動，匯率工具與報價頁會顯示「尚未設定 ExchangeRate-API 金鑰」橫幅。

### 2. Build & Run

本專案預設用 `xcodebuildmcp` CLI 跑 build / run / test（MCP server `mcp__XcodeBuildMCP__*` 留給 UI 自動化、結構化測試結果與長時間操作可控中斷的情境）：

```bash
# iOS Simulator
xcodebuildmcp simulator build-and-run \
  --project-path BuyLedger/BuyLedger.xcodeproj \
  --scheme BuyLedger \
  --simulator-name "iPhone 17"

# iPadOS Simulator
xcodebuildmcp simulator build-and-run \
  --project-path BuyLedger/BuyLedger.xcodeproj \
  --scheme BuyLedger \
  --simulator-name "iPad Pro 13-inch (M5)"

# macOS
xcodebuildmcp macos build-and-run \
  --project-path BuyLedger/BuyLedger.xcodeproj \
  --scheme BuyLedger
```

> ⚠️ 三平台共用同一份 `DerivedData/.../XCBuildData/build.db`，**不可並行 build**——請序列化（`cmd1 && cmd2 && cmd3`）以避免 `database is locked` 失敗。
>
> ⚠️ build 失敗時 CLI 預設只回 trailing `BUILD FAILED`；用 `xcodebuildmcp --log-level error <subcommand> ...` 取得實際 diagnostic。
>
> 💡 simulator 名稱會隨 Xcode 升級變動，先用 `xcodebuildmcp simulator list-sims` 查當前可用名稱再改上方指令。macOS 重新跑前用 `xcodebuildmcp macos stop --app-name BuyLedger` 關掉舊 binary，否則會看到舊版。

### 3. 執行測試

```bash
xcodebuildmcp simulator test \
  --project-path BuyLedger/BuyLedger.xcodeproj \
  --scheme BuyLedger \
  --simulator-name "iPhone 17"
```

Snapshot baseline 第一次跑會自動 record 並回報 fail（屬正常），確認視覺正確後 commit baseline；之後變更若與 baseline 不符會 fail。所有 snapshot test 透過 `TestDependencies.withFixedNow { ... }` 注入固定 `Date / TimeZone / Calendar`（2026-04-30 UTC）避免跨日漂移；新加 snapshot 一律走這個 helper，不要在測試裡直接 `Date()`。

## 架構速覽

### App 進入點與平台導覽

`BuyLedgerApp.swift` 同時宣告 `WindowGroup` 與（macOS）`Settings { ... }` scene。`RootFeature.State.selectedTab` 驅動三種 layout：

| 平台                     | Layout              | 說明                                                       |
|--------------------------|---------------------|------------------------------------------------------------|
| macOS                    | `RootSidebarLayout` | `NavigationSplitView` + sidebar + 訂單頁 `.inspector(...)` |
| iPad（regular size class） | `RootSidebarLayout` | 同 macOS 的 split 結構但無 inspector                       |
| iPhone（compact）          | `RootTabLayout`     | `TabView`                                                  |

`OrdersView` 是平台分流入口（`#if os(macOS)` → `OrdersMacView`、否則依 `horizontalSizeClass` 切 `OrdersCompactView` / 內嵌 split）。`.sheet(...)` 編輯表單一律掛在 `OrdersView` 外層，三平台共用。

macOS 偏好設定走標準 `Settings { ... }` scene（⌘,），實作在 `Features/Settings/SettingsMacView.swift`，採 `TabView` + `Form` + `.formStyle(.grouped)`；iOS / iPadOS 沿用 `SettingsView`（`Form` + `Section`）由 `MoreView` push 進入。

### 資料層

- `OrderRepository`（`Core/Dependencies/`）：訂單資料的 dependency 介面，背後接 `OrderPersistence`（`@ModelActor`）操作 SwiftData。
- `liveValue`：純本機 SwiftData，**不自動 seed**——使用者首次啟動會看到真正的空狀態。
- `previewValue`：in-memory + 自動 seed `LedgerOrder.sampleOrders`，讓 SwiftUI Preview 與 snapshot 測試看得到內容。
- `LedgerOrder.sampleOrders` 與 `FxRateSnapshot.fallback` **僅供 Preview / 單元測試 / `previewValue`** 使用，runtime 不讀取。

### 外部 API

`ExchangeRateClient`（`Features/FX/`）封裝 ExchangeRate-API v6 的 `latest/{base}` endpoint。`fetchLatest(.twd)` 為唯一 runtime API call。

**Fallback 原則**：UI 寧可顯示空狀態（「—」、「尚無可用匯率資料」、「尚未有足夠可用於分析的資料」）也不顯示假資料，避免使用者誤信過期或內建匯率。

## Spec-Driven Development

本專案採用 [Spectra](https://github.com/kaochenlong/spectra-app)（SDD）：

- 規格在 `openspec/specs/`
- 變更提案在 `openspec/changes/`
- 工作流程：`discuss?` → `propose` → `apply` ⇄ `ingest` → `archive`

詳細 workflow 與貢獻者注意事項見 `CLAUDE.md`。

## Troubleshooting

### macOS 沙盒下回到「真正空狀態」

macOS 版的 SwiftData store 位於：

```text
~/Library/Containers/com.leoho.BuyLedger/Data/Library/Application Support/BuyLedger.store{,-shm,-wal}
```

要回到剛安裝、無任何訂單的空狀態時，先停掉 App（釋放檔案 lock）再手動刪除這三個檔案。

### macOS DNS 失敗（NSURLErrorDomain Code -1003）

如果 macOS build 出來連外部 API 都打不通，先檢查：

1. `BuyLedger.entitlements` 是否含 `com.apple.security.network.client = true`。
2. pbxproj 是否正確掛上 `CODE_SIGN_ENTITLEMENTS = BuyLedger/Resources/BuyLedger.entitlements;`——若沒掛，binary 上只會有 Xcode 自動加的 sandbox key，runtime 抓不到設定的 entitlements。

### Snapshot baseline 漂移

設計大改時請刪掉對應 baseline（`BuyLedgerTests/__Snapshots__/SnapshotTests/*.png`）讓下一次跑測試自動重建。Baseline 失準若不是來自設計變動，先確認測試是否走 `TestDependencies.withFixedNow { ... }` 注入固定 `Date`、`TimeZone`、`Calendar`。

## License

待補。
