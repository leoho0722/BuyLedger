# BuyLedger — Apple 平台 (iOS / iPadOS)

BuyLedger 的 Apple 平台實作。產品介紹與 monorepo 結構見 repo 根目錄的 [`README.md`](../../README.md)；本檔涵蓋開發環境設定、build / test 與架構速覽。

## 技術棧

- **Swift 6 + SwiftUI**：strict concurrency
- **TCA ([Swift Composable Architecture](https://github.com/pointfreeco/swift-composable-architecture))**：feature 狀態、商業邏輯、副作用與依賴注入
- **SwiftData + CloudKit**：本機持久化為核心，CloudKit 同步介面 (``PersistenceContainer.CloudKitOption``) 已預留，待 Apple Developer 帳號 provision 後接上
- **Swift Charts**：Insights 頁的趨勢、類別與成本結構視覺化
- **EventKit**：開團訂購提醒寫入／移除系統行事曆 (`CalendarReminderClient`)；因需支援移除既有事件而請求 full access，Info.plist 帶 `NSCalendarsFullAccessUsageDescription`
- **Ollama Cloud**：訂單 AI 商品明細總結 (chat streaming，`OllamaClient`)
- **[swift-snapshot-testing](https://github.com/pointfreeco/swift-snapshot-testing)**：UI 視覺迴歸測試

Xcode 專案：`apps/ios/BuyLedger.xcodeproj`，scheme：`BuyLedger`。需要 **Xcode 26+** 與 Swift 6 toolchain。

Xcode project 使用 file system synchronized groups，新增或搬移檔案請優先動實體資料夾，再用 build 驗證 target 仍正確包含來源與資源。

## 專案結構

```text
apps/ios/
├── BuyLedger.xcodeproj/          # Xcode 專案；project.pbxproj 提交、xcuserdata/ 不提交
├── BuyLedger/                    # App source root
│   ├── App/                      # 進入點：BuyLedgerApp、WindowGroup、AppLaunchConfigurator
│   │   └── Testing/              # UI 測試啟動 harness (BLUITestConfiguration / SeedProfile / SeedData / DependencyOverrides；#if DEBUG)，組裝根與呼叫它的啟動設定同層
│   ├── Core/
│   │   ├── Domain/               # LedgerOrder、FxRateSnapshot、FxRates、CurrencyCode 等 model
│   │   ├── Persistence/          # OrderPersistence (@ModelActor)、PersistenceContainer、OrderRecord
│   │   ├── Dependencies/         # Repository 與 system-call client (type-based @Dependency 注入；不綁定數量)，含 BiometricAuthClient (帳本保護的系統本機驗證)
│   │   ├── Networking/           # APIError、HTTPClient (send/stream)、HTTPMethod、URLRequestBuilder、AppConfiguration、ExchangeRateClient、ExchangeRateDTO
│   │   └── Diagnostics/          # 啟動診斷送往當機診斷服務的可替換介面 (CrashDiagnosticsClient)
│   ├── Features/                 # 依功能切分的 TCA feature
│   │   ├── AISummary/            # 訂單 AI 商品明細總結 (Ollama Cloud 串流)
│   │   ├── App/                  # RootFeature + RootView + RootSidebarLayout / RootTabLayout；AppLockFeature + AppLockView (帳本保護鎖定畫面) + AppScenePhaseCoordinator (場景階段接線)
│   │   ├── Campaigns/            # 開團管理
│   │   ├── Customers/            # 客戶名單
│   │   ├── Dashboard/            # 總覽頁
│   │   ├── FX/                   # 匯率工具 (FxFeature + FxView)
│   │   ├── Insights/             # 趨勢分析
│   │   ├── Lookups/              # 主檔管理 (訂單來源／商品類別／付款方式)
│   │   ├── More/                 # iOS「更多」入口
│   │   ├── Orders/               # 訂單瀏覽與編輯 (含 iPhone/iPad view 分流)；OrdersFeature 三個子域的分支主體外移至 OrdersFilterOperations／OrdersBatchOperations／OrdersMergeFlowOperations (同域輔助型別，非子 reducer)，State 查詢擴充外移至 OrdersFeature+StateQuery，訂單建構收成單一路徑於 OrderDraft，LedgerOrder 的變更擴充收於 LedgerOrder+OrderMutation
│   │   ├── Quote/                # 報價試算
│   │   └── Settings/             # iOS SettingsView
│   ├── Shared/
│   │   ├── Localization/         # 跨 feature 共用的語言型別 (AppLanguage 與 rootNavigationTitle 修飾子)
│   │   ├── Media/                # 照片載入的降採樣與 JPEG 重編碼 (PhotoDataProcessor)
│   │   ├── DesignSystem/
│   │   │   ├── Foundations/      # 色盤、字級、間距、圓角等 token
│   │   │   └── Components/       # BLAvatar、BLBadge、BLCard、BLBarChart、Pickers (OptionPickerSheet)、Forms (PaymentMethodEditorSheet) 等元件
│   │   └── Extensions/           # Swift/SwiftUI 內建型別的通用 extension (Image/Color/Locale/Decimal 等，一型一檔)
│   └── Resources/                # Info.plist、entitlements、PrivacyInfo.xcprivacy (隱私資訊清單)、Config.example.xcconfig (範本，實際 Config.xcconfig 自填且 gitignored)、assets
├── BuyLedgerAccessibilityIDs/    # UI 測試 identifier 常數 (共用資料夾，同時編入 App 與 UITests 兩個 target)
├── BuyLedgerTests/               # 單元測試 + swift-snapshot-testing baseline
├── BuyLedgerUITests/             # XCUITest：Support/ (共用互動 helper)、Screens/ (Page Object)、Tests/ (流程與冒煙)
├── BuyLedger.xctestplan          # 主 scheme 測試計畫 (鎖 zh-Hant/TW、字母序執行、覆蓋率僅統計 App target)
├── BuyLedgerUITests.xctestplan   # UI 主回歸測試計畫 (鎖 zh-Hant/TW、關閉隨機順序)
└── BuyLedgerUITests-Performance.xctestplan  # UI 效能測試計畫 (啟動量測，獨立於主回歸)
```

## 開發環境設定

### 1. API 金鑰 (Config.xcconfig)

App 使用兩把 API key，皆透過 `Config.xcconfig` 注入 (機密)：

| 變數 | 用途 | 申請位置 |
|---|---|---|
| `EXCHANGE_RATE_API_KEY` | 匯率與幣別清單 (ExchangeRate-API v6) | [exchangerate-api.com](https://www.exchangerate-api.com)；30 日 sparkline 需 Pro/Business 方案 |
| `OLLAMA_API_KEY` | 訂單 AI 商品明細總結 (Ollama Cloud chat streaming) | [ollama.com](https://ollama.com) → Account → API keys |

1. 複製 `apps/ios/BuyLedger/Resources/Config.example.xcconfig` 為 `Config.xcconfig` (同目錄)：

   ```bash
   cp apps/ios/BuyLedger/Resources/Config.example.xcconfig apps/ios/BuyLedger/Resources/Config.xcconfig
   ```

2. 編輯 `Config.xcconfig`，填入你的 key：

   ```text
   EXCHANGE_RATE_API_KEY = your-key-here
   OLLAMA_API_KEY = your-key-here
   ```

`Config.xcconfig` 已列入 `.gitignore`，**請勿提交**。

注入鏈路說明 (兩把 key 相同)：`Config.xcconfig` → pbxproj 的 `baseConfigurationReference` 掛到 app target 的 Debug + Release config → `Info.plist` 內以 `$(EXCHANGE_RATE_API_KEY)` / `$(OLLAMA_API_KEY)` 引用 build setting，build 時被注入 → `AppConfiguration.liveValue` 從 `Bundle.main.infoDictionary` 讀回。以上是金鑰如何進到產物內；金鑰進到產物後，兩個服務的實際請求皆以 Authorization header (`Bearer <key>`) 攜帶金鑰，端點路徑本身不含金鑰。

未設 key 時 App 仍可啟動：匯率工具與報價頁顯示「尚未設定 ExchangeRate-API 金鑰」橫幅；AI 總結面板顯示「尚未設定 OLLAMA_API_KEY。」並提供重試。

金鑰內嵌於產物 (而非執行期由使用者提供) 是已評估並接受的風險，其成立前提與前提失效時的作法見 [`CLAUDE.md` › 外部 API 實作](CLAUDE.md#外部-api-實作)。

#### 撤換金鑰

金鑰疑似外洩或需要更換時：

1. **ExchangeRate-API**：登入 [exchangerate-api.com](https://www.exchangerate-api.com) 帳號後台，撤銷既有 key 並產生新 key。
2. **Ollama Cloud**：登入 [ollama.com](https://ollama.com) → Account → API keys，撤銷舊 key 並建立新 key。
3. 將新值填入本機 `Config.xcconfig` 對應變數。
4. **重新 build 並重新安裝 App**：金鑰是建置期注入 `Info.plist`、寫入產物 (見上方注入鏈路)，App 執行期不會重讀 `Config.xcconfig`；只改設定檔而不重新 build 並安裝，執行中的 App 仍使用舊金鑰。

第 4 步完成前，換發不算生效；服務商後台撤銷舊 key 後，未完成第 4 步的已安裝產物會立即改為 `invalidKey` 失敗狀態。

### 2. Build & Run

本專案預設用 `xcodebuildmcp` CLI 跑 build / run / test (MCP server `mcp__XcodeBuildMCP__*` 留給 UI 自動化、結構化測試結果與長時間操作可控中斷的情境)。下列指令一律從 repo 根目錄執行：

```bash
# iOS Simulator
xcodebuildmcp simulator build-and-run \
  --project-path apps/ios/BuyLedger.xcodeproj \
  --scheme BuyLedger \
  --simulator-name "iPhone 17"

# iPadOS Simulator
xcodebuildmcp simulator build-and-run \
  --project-path apps/ios/BuyLedger.xcodeproj \
  --scheme BuyLedger \
  --simulator-name "iPad Pro 13-inch (M5)"
```

> ⚠️ iOS 與 iPadOS 兩個 simulator build 共用同一份 `DerivedData/.../XCBuildData/build.db`，**不可並行 build**——請序列化 (`cmd1 && cmd2`) 以避免 `database is locked` 失敗。
>
> ⚠️ build 失敗時 CLI 預設只回 trailing `BUILD FAILED`；用 `xcodebuildmcp --log-level error <subcommand> ...` 取得實際 diagnostic。
>
> 💡 simulator 名稱會隨 Xcode 升級變動，先用 `xcodebuildmcp simulator list-sims` 查當前可用名稱再改上方指令。

### 3. 執行測試

單元測試與 snapshot 測試 (主 scheme，掛 `BuyLedger.xctestplan`，語言／地區鎖 zh-Hant/TW、不隨模擬器系統狀態變動，覆蓋率僅統計 App target)：

```bash
xcodebuildmcp simulator test \
  --project-path apps/ios/BuyLedger.xcodeproj \
  --scheme BuyLedger \
  --simulator-name "iPhone 17"
```

Snapshot baseline 第一次跑會自動 record 並回報 fail (屬正常)，確認視覺正確後 commit baseline；之後變更若與 baseline 不符會 fail。固定時間注入的硬規則 (`TestDependencies.withFixedNow`) 見 [CLAUDE.md › 測試準則](CLAUDE.md#測試準則)。

跑完測試後想查 App target 覆蓋率 (不設門檻，僅供盤點盲區)：

```bash
xcodebuildmcp simulator get-coverage-report --xcresult-path <測試輸出的 .xcresult 路徑> --target BuyLedger
```

UI 自動化測試 (XCUITest，獨立 scheme)：

```bash
xcodebuildmcp simulator test \
  --project-path apps/ios/BuyLedger.xcodeproj \
  --scheme BuyLedgerUITests \
  --simulator-name "iPhone 17"
```

UI 測試以啟動參數宣告前置條件 (資料、語言、時間、外部相依)，測試端用 `LaunchOptions` 組出、App 端由 `BLUITestConfiguration` 解析；常用旗標：`-BLUITest` (開啟測試模式)、`-BLUITestSeed <profile>` (注入種子資料)、`-BLUITestNow <ISO8601>` (固定時間)、`-BLUITestLanguage <traditionalChinese|english>`、`-BLUITestLoadFailure <orders|...>`。整套 harness 以 `#if DEBUG` 圈住、不進 Release。共用測試工具在 `BuyLedgerUITests/Support/` 與 `BuyLedgerUITests/Screens/`，identifier 常數在 `BuyLedgerAccessibilityIDs/BLAccessibilityID.swift` (同時編入 App 與 UITests 兩個 target)。硬規則 (一律用 identifier 定位、測試前必 seed、不得以 skip 掩蓋、僅覆蓋 iOS 26.x) 見 [CLAUDE.md › 測試準則](CLAUDE.md#測試準則)。

> 💡 CLI 端篩選測試一律用 `-only-testing:`／`-skip-testing:` 旗標，不要用 `-testPlan`：`xcodebuildmcp` 的 `test` 子命令不理會經 `--extra-args` 傳入的 `-testPlan`，會退回 scheme 預設計畫。

### 4. 持續整合 (CI)

`.github/workflows/ci.yml` 定義兩個自動執行的 job：`codegen` (Linux runner，相依安裝 → 漂移檢查 → generator 測試 → 型別檢查) 與 `ios-unit-tests` (macOS runner，以釘選版本的 `xcodebuildmcp` CLI 執行主 scheme 測試，首波排除 snapshot 與效能測試)；UI 回歸僅在手動觸發時執行。repo 為公開專案，macOS runner 不計費。

CI 不使用任何 repository secret：`apps/ios/BuyLedger/Resources/GoogleService-Info.example.plist` 是入庫的佔位範本 (值皆為明顯假字串)，CI 建置前會複製成正式檔名讓測試宿主 App 能啟動；此檔僅供 CI 使用，**本機開發請勿拿它覆蓋真實的 `GoogleService-Info.plist`**。

### 5. 重新產生 data model (codegen)

`Core/Domain/` 的資料形狀由 `shared/data-model` 的跨平台 schema 產生 (格式與細節見 [shared/data-model/README.md](../../shared/data-model/README.md))，生成檔在 `Core/Domain/Generated/`，**不可手改**。增刪欄位或改型別時：

```bash
# 首次安裝產生器依賴 (需 Bun >= 1.3，brew install bun)
cd shared/data-model/generator && bun install

# 改 shared/data-model/schema/ 後重新產生 Swift (輸出到 apps/ios 的 Core/Domain/Generated/)
bun run generate

# 提交前確認生成檔與 schema 同步 (exit 0 才算同步)
bun run check

# (少用) 把生成檔改回可寫，僅供刻意手動檢視／實驗；下次 generate 會重新鎖唯讀
bun run unlock
```

生成檔與 schema 一起 commit。生成檔在磁碟上**預設唯讀** (`generate` 會 chmod `0o444` 防手改)；Xcode 編譯只讀取、不受影響，重生成會自動解鎖重寫。`Core/Domain/` 是 file system synchronized group，新增／刪除型別後請 iOS + iPadOS 各 build 一次，確認新檔被正確拾取。手寫業務邏輯 (computed properties、display title、自訂 `Codable`) 放在與型別同名的 extension 檔，不放生成檔。

## 架構速覽

### App 進入點與平台導覽

`BuyLedgerApp.swift` 以單一 `RootFeature` store 驅動：`WindowGroup` 掛上 `RootView` 並以 `.modelContainer(...)` 注入共用 SwiftData container。`RootFeature.State.selectedTab` 驅動兩種 layout：

| 平台                      | Layout              | 說明                                          |
|---------------------------|---------------------|-----------------------------------------------|
| iPad (regular size class) | `RootSidebarLayout` | `NavigationSplitView` + sidebar，無 inspector |
| iPhone (compact)          | `RootTabLayout`     | `TabView`                                     |

`OrdersView` 是平台分流入口：iPhone (compact) → `OrdersCompactView` (`NavigationStack`)；iPad (regular) → `NavigationStack` 內以 `HStack` 自排「清單 + 詳情」兩欄 (不用巢狀 `NavigationSplitView`，避免兩層 split 互搶寬度)。`.sheet(...)` 編輯表單一律掛在 `OrdersView` 外層，iPhone / iPad 共用。

### 資料層

- **Repository 層** (`Core/Dependencies/`)：`OrderRepository` 等各主檔與開團的 repository (清單見該目錄，不在此綁定數量)，各自背後接對應的 `@ModelActor` persistence (`Core/Persistence/`) 操作 SwiftData。所有 repo 共用 `PersistenceContainer.shared` 單一 `ModelContainer`，注入一律走 type-based `@Dependency(SomeRepository.self)`。
- **主檔資料** (訂單來源／商品類別／付款方式／對帳狀態) 由 `LookupManagementFeature` (`Features/Lookups/`，以 `LookupKind` 分流) 提供 CRUD，並與 `OrdersFeature` 以共享的記憶體儲存 `LookupCatalog` 作為單一來源；rename 會 cascade 到所有引用該名稱的訂單，此段落由 `RootFeature` 攔截處理 (`LookupKind.isReferenced(by:name:)`／`LookupKind.renamingReference(in:from:to:)` 分派)。
- `liveValue`：純本機 SwiftData，**不自動 seed**——使用者首次啟動會看到真正的空狀態。
- `previewValue`：in-memory + 自動 seed `LedgerOrder.sampleOrders`，讓 SwiftUI Preview 與 snapshot 測試看得到內容。
- `LedgerOrder.sampleOrders` 與 `FxRateSnapshot.fallback` **僅供 Preview / 單元測試 / `previewValue`** 使用，runtime 不讀取。
- **Schema 版本化**：`Core/Persistence/BuyLedgerSchema.swift` 以 `VersionedSchema` (floor `BuyLedgerSchemaV15` → target `BuyLedgerSchemaV17`) + `BuyLedgerMigrationPlan` 管理遷移。新增欄位／表走 lightweight、改既有欄位型別或 `@Model` 類別名走 custom dump-and-restore；版本移除、shadow 凍結等硬規則見 [`CLAUDE.md › SwiftData Schema 與 Migration`](CLAUDE.md#swiftdata-schema-與-migration)。開團訂購提醒連結表 `CampaignReminderRecord` 是唯一的 iOS-only 表 (記行事曆 `eventIdentifier` 與提醒時間戳，與跨平台 `Campaign` 解耦、不入跨平台 schema)。

### 隱私與遙測

遙測強制開啟，設定頁不提供任何相關開關或說明；本 App 產物不對外散布、僅安裝於開發者自己的裝置，不涉及第三方使用者的同意權議題。產物內含 `PrivacyInfo.xcprivacy` 隱私資訊清單，宣告使用者預設值的具名理由與所連結遙測 SDK 的資料類型，遙測相關揭露僅以此清單呈現；細節與 gotcha 見 `CLAUDE.md` 的「Firebase (遙測底座、無雲端同步)」一節。

### 帳本保護

「更多 → 設定」的「帳本保護」區塊提供單一開關：開啟時同時啟用「App 進入背景即上鎖」與「回到前景或冷啟動需通過驗證才顯示內容」兩項保護，關閉時完全回到現況。啟用路徑本身需先通過一次系統本機驗證 (`BiometricAuthClient`，`LAContext` 的 `.deviceOwnerAuthentication` 政策，涵蓋生物辨識與裝置密碼後備)，成功才寫入偏好；失敗、取消或裝置不支援則開關回到關閉並以對話框說明原因。上鎖只保證回到前景需要驗證，不保證多工切換器縮圖排除內容 (已知取捨，見 `CLAUDE.md › App 進入點與平台導覽`)。

- `AppLockFeature` (`Features/App/`)：啟用驗證、鎖定／解鎖狀態機，巢狀於 `SettingsFeature.State.appLock`；`SettingsFeature` 攔截其驗證成功與關閉事件寫回 `SettingsStorage`。
- `AppLockView` (`Features/App/`)：鎖定時取代整個正常介面的阻斷畫面，提供「重新驗證」(不提供跳過)。
- `AppScenePhaseCoordinator` (`Features/App/`)：由 `BuyLedgerApp` 的 `\.scenePhase` 呼叫，依場景階段 (`.background`／`.active`) 轉送 `AppLockFeature` 的鎖定／解鎖動作；觸發訊號的選擇與該踩過的坑見 `CLAUDE.md` 同節。
- UI 測試以 `-BLUITestAppLockEnabled` 直接抵達鎖定狀態、`-BLUITestBiometricScenario` 選擇驗證情境，全程不觸發系統生物辨識提示。

### 外部 API

`ExchangeRateClient` (`Core/Networking/`) 封裝 ExchangeRate-API v6 的兩個 endpoint：`latest/{base}` (匯率) 與 `codes` (幣別清單)。runtime 有兩個 call——`fetchLatest(.twd)` 取最新匯率；App 啟動時經 `CurrencyMetadataRepository.refreshIfStale` 打 `/codes` 載入幣別主檔並 cache 7 天 (幣別清單不再 hardcode)。

`OllamaClient` (`Features/AISummary/`) 串接 Ollama Cloud chat streaming (`POST https://ollama.com/api/chat`)，在訂單詳情串流產生 Markdown 商品明細總結；缺金鑰或服務錯誤時進入 failed 狀態並提供重試，面板關閉時取消串流。逐位元組串流走 `HTTPClient.stream`。

**Fallback 原則**：遵循 root [README.md › 產品政策](../../README.md#產品政策)——匯率與分析 UI 顯示「—」、「尚無可用匯率資料」、「尚未有足夠可用於分析的資料」等空狀態，避免使用者誤信過期或內建匯率。

## Troubleshooting

### Snapshot baseline 漂移

設計大改時請刪掉對應 baseline (`BuyLedgerTests/__Snapshots__/SnapshotTests/*.png`) 讓下一次跑測試自動重建。Baseline 失準若不是來自設計變動，先確認測試是否走 `TestDependencies.withFixedNow { ... }` 注入固定 `Date`、`TimeZone`、`Calendar`。
