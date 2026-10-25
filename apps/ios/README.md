# BuyLedger — Apple 平台 (iOS / iPadOS)

BuyLedger 的 Apple 平台實作。產品介紹與 monorepo 結構見 repo 根目錄的 [`README.md`](../../README.md)；本檔涵蓋開發環境設定、build / test 與架構速覽。

## 技術棧

- **Swift 6 + SwiftUI**：strict concurrency
- **TCA ([Swift Composable Architecture](https://github.com/pointfreeco/swift-composable-architecture))**：feature 狀態、商業邏輯、副作用與依賴注入
- **SwiftData + CloudKit**：本機持久化為核心，CloudKit 同步介面 (`PersistenceContainer.CloudKitOption`) 已預留，待 Apple Developer 帳號 provision 後接上
- **Swift Charts**：Insights 頁的趨勢、類別與成本結構視覺化
- **EventKit**：開團訂購提醒寫入／移除系統行事曆 (`CalendarReminderService`)；因需移除既有事件而請求 full access
- **Ollama Cloud**：訂單 AI 商品明細總結 (chat streaming，`AISummaryService`)
- **Firebase (Analytics／Crashlytics／Performance)**：崩潰與使用分析遙測 (`TelemetryService`)
- **[swift-snapshot-testing](https://github.com/pointfreeco/swift-snapshot-testing)**：UI 視覺迴歸測試

Xcode 專案：`apps/ios/BuyLedger.xcodeproj`，scheme：`BuyLedger`。需要 **Xcode 27+** (專案檔 `project.xcproj` 是 Xcode 27 的 JSON 格式，Xcode 26 讀不到)，App 最低支援 **iOS / iPadOS 26.0**。

Xcode project 使用 file system synchronized groups，新增或搬移檔案請優先動實體資料夾，再用 build 驗證 target 仍正確包含來源與資源。

## 專案結構

```text
apps/ios/
├── BuyLedger.xcodeproj/          # Xcode 專案；project.xcproj (JSON 格式) 提交、xcuserdata/ 不提交
├── BuyLedger/                    # App source root
│   ├── App/                      # 進入點：BuyLedgerApp、AppDelegate、AppLaunchConfigurator
│   │   └── Testing/              # UI 測試啟動 harness (#if DEBUG，進入點 BLUITestHarness)
│   │       ├── Configuration/    # 啟動參數解析 (BLUITestConfiguration 與各參數列舉)
│   │       ├── Seed/             # 種子資料組合 (BLUITestSeedProfile) 與各情境資料
│   │       ├── TestDoubles/      # 幣別 API、設定、照片快取等依賴替身
│   │       └── Overrides/        # 依啟動設定換上替身的 DependencyValues extension
│   ├── Core/
│   │   ├── Domain/               # LedgerOrder、Campaign、FxRateSnapshot、CurrencyCode 等領域 model 與手寫 extension
│   │   │   └── Generated/        # 由 shared/data-model schema 產生的型別 (不可手改)
│   │   ├── Persistence/
│   │   │   ├── Database/         # BuyLedgerDatabase (actor)、PersistenceContainer、BuyLedgerSchema (版本與遷移)
│   │   │   ├── Records/          # SwiftData @Model Record
│   │   │   └── Errors/           # 持久化錯誤型別
│   │   ├── Authentication/       # BiometricAuthService (App 鎖定與設定頁共用的本機驗證)
│   │   ├── Currency/             # CurrencyMetadataService (幣別主檔快取)、ExchangeRateService (最新匯率)
│   │   ├── Storage/              # UserDefaultsStore、AppConfigurationStore (讀 Info.plist 設定)
│   │   ├── Networking/
│   │   │   ├── Client/           # HTTPClient (send／stream) 與 APIError
│   │   │   └── ExchangeRate/     # ExchangeRateEndpoint 與回應型別
│   │   ├── Environment/          # RuntimeEnvironment (判斷 Preview／UI 測試／單元測試)
│   │   ├── Diagnostics/          # CrashDiagnosticsClient (啟動診斷的可替換介面)
│   │   ├── Telemetry/            # TelemetryService (開啟 Firebase 遙測收集)
│   │   └── Extensions/           # 系統型別的通用 extension (一型一檔)
│   ├── Features/                 # 依功能切分的 TCA feature，依 ios-dev-kit 分 Presentation／Domain／Data
│   │   ├── AISummary/            # 訂單 AI 商品明細總結 (Ollama Cloud 串流)
│   │   │   ├── Presentation/
│   │   │   │   └── Root/         # AISummaryFeature + AISummaryView
│   │   │   └── Data/             # AISummaryService 與 Ollama 請求／回應型別
│   │   ├── App/                  # App 殼層
│   │   │   ├── Presentation/
│   │   │   │   ├── Root/         # RootFeature + RootView、RootSidebarLayout／RootTabLayout 與跨頁導覽
│   │   │   │   ├── RootLaunch/   # 無畫面：啟動幣別載入與系統重大時間變更
│   │   │   │   ├── AppLock/      # AppLockFeature + AppLockView
│   │   │   │   └── PersistenceFailure/ # 資料庫無法開啟時的復原畫面
│   │   │   ├── Domain/           # RootTab、AppScenePhase
│   │   │   └── Data/             # PersistenceRecoveryService、SignificantTimeChangeService
│   │   ├── Campaigns/            # 開團管理
│   │   │   ├── Presentation/
│   │   │   │   ├── Root/         # CampaignFeature (容器) + CampaignView
│   │   │   │   ├── CampaignList/ # CampaignListFeature
│   │   │   │   │   ├── Views/    # 列表、區段與列
│   │   │   │   │   └── Queries/  # 日期區段與分組
│   │   │   │   ├── CampaignDetail/ # CampaignDetailFeature + 詳情畫面
│   │   │   │   ├── CampaignEdit/ # CampaignEditFeature + 編輯表單與 CampaignDraft
│   │   │   │   ├── CampaignLoad/ # 無畫面：載入與自動結單
│   │   │   │   ├── CampaignWrites/ # 無畫面：寫入
│   │   │   │   ├── CampaignReminder/ # 無畫面：訂購提醒
│   │   │   │   ├── CampaignPresentation/ # 無畫面：表單、確認框與通知的呈現
│   │   │   │   └── Formatting/   # CampaignFormatters 與狀態樣式
│   │   │   ├── Domain/           # 日期脈絡、提醒連結、行事曆權限與錯誤型別
│   │   │   └── Data/             # CampaignService、CalendarReminderService、OpenSettingsService
│   │   ├── Customers/            # 客戶名單
│   │   │   └── Presentation/
│   │   │       ├── Root/         # CustomersFeature + CustomersView
│   │   │       └── Formatting/   # CustomerFormatters 與名次徽章樣式
│   │   ├── Dashboard/            # 總覽頁
│   │   │   ├── Presentation/
│   │   │   │   ├── Root/         # DashboardFeature
│   │   │   │   │   └── Views/    # DashboardView 與各區段
│   │   │   │   └── Formatting/   # DashboardFormatters
│   │   │   └── Domain/           # DashboardStats、DashboardDateContext
│   │   ├── FX/                   # 匯率工具
│   │   │   └── Presentation/
│   │   │       ├── Root/         # FxFeature + FxView
│   │   │       └── Formatting/   # FxFormatters
│   │   ├── Insights/             # 趨勢分析
│   │   │   ├── Presentation/
│   │   │   │   ├── Root/         # InsightsFeature
│   │   │   │   │   └── Views/    # InsightsView 與五張分析卡
│   │   │   │   └── Formatting/   # InsightsFormatters
│   │   │   └── Domain/           # InsightsStats 與各卡統計、日期範圍與脈絡
│   │   ├── Lookups/              # 主檔管理 (訂單來源／商品類別／付款方式／對帳狀態)
│   │   │   ├── Presentation/
│   │   │   │   ├── Root/         # LookupManagementFeature 與讀寫分派
│   │   │   │   │   └── Views/    # 管理頁、列表與名稱編輯 sheet
│   │   │   │   ├── LookupAddForm/、LookupRenameForm/、PaymentMethodEditForm/ # 三種表單的無畫面 Feature
│   │   │   │   ├── PaymentMethodCorrection/ # 無畫面：付款方式更正
│   │   │   │   └── LookupCatalog/ # 無畫面：載入與新增主檔目錄
│   │   │   ├── Domain/           # LookupCatalog、LookupKind 與請求／結果型別
│   │   │   └── Data/             # LookupService
│   │   ├── More/                 # iOS「更多」分頁
│   │   │   └── Presentation/
│   │   │       └── Root/         # MoreFeature + MoreView
│   │   ├── Orders/               # 訂單
│   │   │   ├── Presentation/
│   │   │   │   ├── Root/         # OrdersFeature (容器，持有共用訂單與 Root 投影)
│   │   │   │   │   ├── Views/    # OrdersView 與 compact／regular 版面
│   │   │   │   │   ├── Requests/ # Root 與清單／詳情送進容器的請求
│   │   │   │   │   └── Plans/    # 容器的請求、寫入與呈現計畫
│   │   │   │   ├── OrderList/    # OrderListFeature (搜尋、多選、日期分組與 iPad 選取)
│   │   │   │   │   ├── Views/
│   │   │   │   │   ├── Operations/
│   │   │   │   │   └── Queries/
│   │   │   │   ├── OrderDetail/  # OrderDetailFeature (iPhone 推入與 iPad 詳情欄共用)
│   │   │   │   │   └── Views/
│   │   │   │   ├── OrdersDetailNavigation/ # 無畫面：iPhone 詳情堆疊與 iPad 詳情欄同步
│   │   │   │   ├── OrderEdit/    # OrderEditFeature (草稿、驗證、焦點與存檔請求)
│   │   │   │   │   ├── Views/    # 表單畫面與欄位
│   │   │   │   │   │   └── Sections/ # 九個表單區段
│   │   │   │   │   ├── Models/   # OrderDraft、OrderEditOptions
│   │   │   │   │   └── Operations/
│   │   │   │   ├── OrderEditPhotos/ # 表單的照片載入、匯入與編輯
│   │   │   │   ├── OrderEditPickers/ # 表單的選項清單與選擇器路由
│   │   │   │   ├── OrderFilter/  # OrderFilterFeature (iPhone 篩選 sheet)
│   │   │   │   │   └── Views/
│   │   │   │   ├── OrderCategoryPicker/ # iPad 類別選擇器
│   │   │   │   ├── OrderMerge/   # OrderMergeFeature (合併候選與照片挑選)
│   │   │   │   ├── OrdersLoad/   # 無畫面：訂單載入與共享載入狀態
│   │   │   │   ├── OrderWrites/  # 無畫面：寫入與交易後的調整
│   │   │   │   ├── OrdersPresentation/ # 無畫面：編輯、合併、AI 摘要與 alert 的呈現
│   │   │   │   ├── Components/   # 跨畫面共用的列、選單與類別篩選元件
│   │   │   │   └── Formatting/   # OrderFormatters 與狀態樣式
│   │   │   ├── Domain/           # 日期脈絡、狀態規則、載入狀態、OrderError 等訂單領域型別
│   │   │   └── Data/             # OrderService、PhotoService
│   │   ├── Quote/                # 報價試算
│   │   │   └── Presentation/
│   │   │       ├── Root/         # QuoteFeature + QuoteView
│   │   │       ├── QuoteRate/    # 無畫面：匯率來源與來源幣別選擇
│   │   │       └── Formatting/   # QuoteFormatters
│   │   └── Settings/             # 設定
│   │       ├── Presentation/
│   │       │   └── Root/         # SettingsFeature + SettingsView (含 App 鎖定的啟用驗證)
│   │       ├── Domain/           # SettingsSnapshot、AISummaryModelCatalog
│   │       └── Data/             # SettingsService
│   ├── Shared/
│   │   ├── Localization/         # AppLanguage、CurrencyDisplayName
│   │   ├── Media/                # PhotoDataProcessor (照片降採樣與重編碼)
│   │   └── DesignSystem/
│   │       ├── Foundations/      # 色彩、字級、間距等 token，BLLayoutClass、BLFormatters 與 ViewModifiers/
│   │       └── Components/       # 可重用元件，依類型分 Avatar、Badges、Buttons、Cards、Charts、Chips、Forms、Images、Pickers、Progress、States、Status、Tags
│   └── Resources/                # Info.plist、PrivacyInfo.xcprivacy、字串目錄、assets 與設定範本 (見「開發環境設定」)
├── BuyLedgerAccessibilityIDs/    # UI 測試 identifier 常數 (BLAccessibilityID+<區域>.swift，同時編入 App 與 UITests)
├── BuyLedgerTests/               # 單元測試，鏡像正式程式碼目錄
│   ├── Features/<Feature>/、Core/、Shared/、App/Testing/ # 對應正式程式碼同名目錄的測試
│   ├── AccessibilityIDs/         # BLAccessibilityID 測試
│   ├── Guards/                   # 原始碼掃描與守門測試；多檔的守門分 ActionGrouping、DependencyConvention、DesignSystemSourceScan、LayerBoundary、LocalizationCatalog、ProjectionWriteBoundary、ServiceOwnership，共用掃描器在 Scanning/
│   ├── SnapshotTests/            # snapshot 測試；baseline 在 __Snapshots__/<測試檔名>/
│   ├── Mocks/                    # Database、HTTPClient、Store 的 Mock 與 MockURLProtocol
│   ├── Fixtures/                 # 測試用固定資料
│   └── Support/                  # TestDependencies、TestPaths 與共用的 <Base>TestSupport
├── BuyLedgerUITests/             # XCUITest
│   ├── Support/                  # 共用 helper：Launch、Interactions、Assertions、Layout
│   ├── Screens/                  # Page Object，依區域分 App、Orders、Campaigns、Dashboard、Insights、Customers、More、Tools，跨區共用的放 Shared
│   └── Tests/                    # 流程、冒煙 (Smoke) 與效能 (Performance) 測試，依功能分組 (Orders 再分 Filters、Regular、Edit、Detail)
├── scripts/                      # upload-testflight.sh (Release 打包並上傳 TestFlight)
├── BuyLedger.xctestplan          # 單元測試計畫
├── BuyLedgerUITests.xctestplan   # UI 主回歸測試計畫
└── BuyLedgerUITests-Performance.xctestplan  # UI 效能測試計畫 (啟動量測)
```

## 開發環境設定

需要 Xcode 27+ 與 `mobilebuildmcp` CLI (`npm install -g mobilebuildmcp@<版本>`，版本與 `.github/workflows/ci.yml` 的 `MOBILEBUILDMCP_VERSION` 相同)；改 data model 時另需 Bun (見第 6 節)。

### 1. API 金鑰 (Config.xcconfig)

App 使用兩把 API key，皆透過 `Config.xcconfig` 注入 (機密)：

| 變數 | 用途 | 申請位置 |
| --- | --- | --- |
| `EXCHANGE_RATE_API_KEY` | 匯率與幣別清單 (ExchangeRate-API v6) | [exchangerate-api.com](https://www.exchangerate-api.com) |
| `OLLAMA_API_KEY` | 訂單 AI 商品明細總結 (Ollama Cloud chat streaming) | [ollama.com](https://ollama.com) → Account → API keys |

1. 複製範本 (`Config.xcconfig` 已列入 `.gitignore`，**請勿提交**)：

   ```bash
   cp apps/ios/BuyLedger/Resources/Config.example.xcconfig apps/ios/BuyLedger/Resources/Config.xcconfig
   ```

2. 編輯 `Config.xcconfig`，填入你的 key：

   ```text
   EXCHANGE_RATE_API_KEY = your-key-here
   OLLAMA_API_KEY = your-key-here
   ```

金鑰在 build 時注入產物：`Config.xcconfig` 掛在 app target 的 Debug 與 Release config，`Info.plist` 以 `$(EXCHANGE_RATE_API_KEY)`／`$(OLLAMA_API_KEY)` 引用，執行期由 `AppConfigurationStore` 從 `Bundle.main` 讀回 (空字串或未展開的 `$(KEY)` 視為未設定)。兩個服務的請求都以 Authorization header (`Bearer <key>`) 攜帶金鑰，網址不含金鑰。

未設 key 時 App 仍可啟動：匯率工具與報價頁顯示「尚未設定 ExchangeRate-API 金鑰」的提示，AI 總結面板顯示「AI 總結尚未完成設定，目前無法使用。」並提供重試。

金鑰內嵌於產物 (而非執行期由使用者提供) 是已評估並接受的風險，其成立前提與前提失效時的作法見 [`.claude/rules/ios-integrations.md`](../../.claude/rules/ios-integrations.md) 的「外部 API」。

#### 撤換金鑰

金鑰疑似外洩或需要更換時：

1. **ExchangeRate-API**：登入 [exchangerate-api.com](https://www.exchangerate-api.com) 帳號後台，撤銷既有 key 並產生新 key。
2. **Ollama Cloud**：登入 [ollama.com](https://ollama.com) → Account → API keys，撤銷舊 key 並建立新 key。
3. 將新值填入本機 `Config.xcconfig` 對應變數。
4. **重新 build 並重新安裝 App**：金鑰在建置期寫入產物，App 執行期不會重讀 `Config.xcconfig`。

完成第 4 步前換發不算生效；服務商後台撤銷舊 key 後，尚未重裝的產物會立即進入 `invalidKey` 失敗狀態。

### 2. Firebase 設定 (GoogleService-Info.plist)

從 Firebase Console 下載 `GoogleService-Info.plist`，放到 `apps/ios/BuyLedger/Resources/` (已列入 `.gitignore`)，並移除其中的 `IS_ANALYTICS_ENABLED` (在 iOS 無效，留著會讓人誤以為能關閉 Analytics)。缺少這個檔時 Crashlytics 的 build phase 會讓 build 失敗，一般啟動也會在 `FirebaseApp.configure()` 崩潰 (單元測試與 UI 測試模式略過 Firebase 初始化)。

同目錄的 `GoogleService-Info.example.plist` 是只給 CI 用的佔位範本，**本機開發請勿拿它覆蓋真實的 `GoogleService-Info.plist`**。產品組合與隱私清單的規則見 [`.claude/rules/ios-firebase-privacy.md`](../../.claude/rules/ios-firebase-privacy.md)。

### 3. Build & Run

日常 build / run / test 用 `mobilebuildmcp` CLI；UI 自動化、結構化測試結果與需要中斷長時間操作的情境改用它的 MCP server (`mobilebuildmcp mcp`)。下列指令一律從 repo 根目錄執行：

```bash
# 查詢模擬器識別碼 (名稱會隨 Xcode 版本變動，以識別碼指定)
mobilebuildmcp simulator list

# 在 iPhone 或 iPad 模擬器建置並啟動
mobilebuildmcp simulator build-and-run \
  --project-path apps/ios/BuyLedger.xcodeproj \
  --scheme BuyLedger \
  --simulator-id <模擬器識別碼>
```

> ⚠️ iOS 與 iPadOS 兩個 simulator build 共用同一份 `DerivedData/.../XCBuildData/build.db`，**不可並行 build**，請序列化 (`cmd1 && cmd2`) 以避免 `database is locked`。
>
> ⚠️ build 失敗時 CLI 預設只回 `BUILD FAILED`；用 `mobilebuildmcp --log-level error <subcommand> ...` 取得實際 diagnostic。

### 4. 執行測試

三份測試計畫的語言／地區都鎖 zh-Hant／TW (不隨模擬器系統設定變動)，覆蓋率只統計 App target。

單元測試與 snapshot 測試 (`BuyLedger` scheme，`BuyLedger.xctestplan`)：

```bash
mobilebuildmcp simulator test \
  --project-path apps/ios/BuyLedger.xcodeproj \
  --scheme BuyLedger \
  --simulator-id <模擬器識別碼>
```

Snapshot baseline 第一次跑會自動 record 並回報 fail (屬正常)，確認視覺正確後 commit baseline；之後變更若與 baseline 不符會 fail。跑之前先把模擬器外觀鎖淺色 (`mobilebuildmcp simulator-management set-appearance --simulator-id <模擬器識別碼> --mode light`)，否則自動外觀入夜切深色會讓整批 baseline 失敗。固定時間注入的規則見 [`.claude/rules/ios-unit-tests.md`](../../.claude/rules/ios-unit-tests.md) 的「Snapshot 測試」。

查 App target 覆蓋率 (不設門檻，僅供盤點盲區)：

```bash
mobilebuildmcp simulator get-coverage-report --xcresult-path <測試輸出的 .xcresult 路徑> --target BuyLedger
```

UI 自動化測試 (XCUITest，`BuyLedgerUITests` scheme，預設跑 `BuyLedgerUITests.xctestplan` 主回歸；啟動效能量測在 `BuyLedgerUITests-Performance.xctestplan`)：

```bash
mobilebuildmcp simulator test \
  --project-path apps/ios/BuyLedger.xcodeproj \
  --scheme BuyLedgerUITests \
  --simulator-id <模擬器識別碼>
```

UI 測試以啟動參數宣告前置條件：測試端用 `LaunchOptions` 組出、App 端由 `BLUITestConfiguration` 解析，常用旗標為 `-BLUITest` (開啟測試模式)、`-BLUITestSeed <profile>` (種子資料)、`-BLUITestNow <ISO8601>` (固定時間)、`-BLUITestLanguage <traditionalChinese|english>`、`-BLUITestLoadFailure <orders|...>`。整套 harness 以 `#if DEBUG` 圈住、不進 Release。硬規則 (一律用 identifier 定位、測試前必 seed、不得以 skip 掩蓋、僅覆蓋 iOS 26.x) 見 [`.claude/rules/ios-ui-tests.md`](../../.claude/rules/ios-ui-tests.md)。

> 💡 CLI 端篩選測試一律用 `-only-testing:`／`-skip-testing:` 旗標，不要用 `-testPlan`：`mobilebuildmcp` 的 `test` 子命令不理會經 `--extra-args` 傳入的 `-testPlan`。

### 5. 持續整合 (CI)

`.github/workflows/ci.yml` 在 push 到 `main`、每個 PR 與手動觸發時執行兩個 job：`codegen` (Linux runner，相依安裝 → 漂移檢查 → generator 測試 → 型別檢查) 與 `ios-unit-tests` (macOS runner，以釘選版本的 `mobilebuildmcp` 執行主 scheme 測試，排除 snapshot 與效能測試)；UI 回歸只在手動觸發時執行。repo 為公開專案，macOS runner 不計費。

CI 不使用任何 repository secret：建置前把 `Config.example.xcconfig` 與 `GoogleService-Info.example.plist` 兩個入庫範本 (值皆為明顯假字串) 複製成正式檔名，讓 build 不缺設定檔。

### 6. 重新產生 data model (codegen)

`Core/Domain/Generated/` 的型別由 `shared/data-model` 的跨平台 schema 產生，**不可手改**；schema 格式、完整指令與改欄位流程見 [shared/data-model/README.md](../../shared/data-model/README.md)。常用指令 (需 Bun >= 1.3，`brew install bun`)：

```bash
cd shared/data-model/generator && bun install   # 首次安裝產生器依賴
bun run generate                                # 改 schema/ 後重新產生
bun run check                                   # 提交前確認生成檔與 schema 同步 (exit 0 才算同步)
```

iOS 端注意事項：

- 生成檔與 schema 一起 commit；生成檔在磁碟上預設唯讀，Xcode 編譯不受影響。
- 新增或刪除型別後 iOS 與 iPadOS 各 build 一次，確認 synchronized group 拾取新檔。
- 手寫業務邏輯 (computed properties、display title、自訂 `Codable`) 放在 `Core/Domain/` 與型別同名的 extension 檔，不放生成檔。

### 7. 發佈 TestFlight

先在 `project.xcproj` 改好 `BuyLedger` target 的 `MARKETING_VERSION` 與 `CURRENT_PROJECT_VERSION` (兩個測試 target 同步為相同值) 並提交、標 `ios-v<版號>` tag，再從 repo 根目錄執行：

```bash
# Release 打包並上傳 TestFlight (上傳前會詢問確認，加 --yes 略過)
apps/ios/scripts/upload-testflight.sh

# 只打包並匯出 .ipa 到本機，不上傳
apps/ios/scripts/upload-testflight.sh --export-only

# 改用 App Store Connect API key 驗證 (三個變數要同時設定)
ASC_KEY_PATH=~/.appstoreconnect/private_keys/AuthKey_XXXX.p8 \
ASC_KEY_ID=XXXX \
ASC_ISSUER_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx \
  apps/ios/scripts/upload-testflight.sh
```

- 未設定 API key 時沿用 Xcode Settings › Accounts 已登入的帳號，該帳號要能發佈 team `23JEQ2524P`。
- 腳本不遞增 build 號，上傳時也關閉 Xcode 的自動改號，上傳的版號與 build 號就是提交的值；同一版號的 build 號不可重複上傳。
- `BuyLedger/`、`BuyLedger.xcodeproj/`、`BuyLedgerAccessibilityIDs/` 有未提交變更時拒絕打包；HEAD 沒有對應的 `ios-v<版號>` tag 時只警告。
- archive 放在 `~/Library/Developer/Xcode/Archives/` (Xcode Organizer 看得到)；每次執行的 `ExportOptions.plist`、log 與匯出的 .ipa 放在 `apps/ios/build/testflight/<版號>-<build>-<時間>/` (已 gitignore)。
- 打包後若 `.xcstrings` 被 Xcode 改寫，腳本會列出變更，確認後再還原。

## 架構速覽

整體與各 Feature 的架構圖在 repo 根目錄的 `.archify/` (HTML，於本機以瀏覽器開啟)。

### App 進入點與平台導覽

`BuyLedgerApp` 以單一 `RootFeature` store 驅動 `RootView`：啟動時讀出一次設定快照直接傳入 `RootFeature.State`，首幀即使用已保存的語言、月目標與鎖定狀態；SwiftData container 不經 SwiftUI environment 注入，統一由 `BuyLedgerDatabase` 持有；單元測試 host 不建立根畫面。`RootView` 依版面分類選擇 layout，`RootFeature.State.selectedTab` 驅動分頁：

| 版面分類 | Layout | 說明 |
| --- | --- | --- |
| regular 版面 (水平與垂直尺寸分類都是 regular，例如 iPad 全螢幕) | `RootSidebarLayout` | `NavigationSplitView`；訂單分頁為側邊欄、清單、詳情三欄，其他分頁為側邊欄與內容兩欄 |
| compact 版面 (其餘組合，含 iPhone 任何機型橫向與 iPad 窄視窗) | `RootTabLayout` | `TabView` |

版面分類由 `BLLayoutClass` 判斷：`RootView` 依視窗決定一次，以 `.environment(\.blLayoutClass, …)` 交給子樹，畫面不直接讀 `horizontalSizeClass`／`verticalSizeClass`；沒有經過 `RootView` 的 Preview 與截圖測試才由尺寸分類推導。大尺寸 iPhone 橫向的水平尺寸分類是 regular、垂直是 compact，所以仍走 compact 版面。

- **訂單**：`OrdersView` 在 compact 版面走 `OrdersCompactView` (`NavigationStack`，以 `OrdersDetailNavigationFeature` 的 `StackState` 推入 `OrderDetailFeature`)；regular 版面提供三欄的清單欄與詳情欄 (`OrdersRegularDetailColumn`，沿用同一個 `OrderDetailFeature`，無選取時顯示空狀態)。編輯、合併與 AI 摘要 sheet 綁定 `OrdersPresentationFeature` 的單一 `destination`，掛在 `OrdersView` 外層、兩種版面共用。
- **總覽與分析**：regular 版面並排卡片，compact 版面上下堆疊。
- **更多**：`MoreFeature` 以 `StackState` 推入匯率工具、客戶名單、報價試算、四種主檔管理與設定，返回即釋放子畫面狀態；iPhone 切換分頁時保留堆疊，iPad 側邊欄切換前先清空 (`NavigationSplitView` 在路徑非空時切分頁會崩潰)。

### 資料層

- **Service 層**：`OrderService`、`LookupService`、`CampaignService` 等以資料庫為下層的 Service 放在各 Feature 的 `Data/`，透過 `BuyLedgerDatabase` 操作 SwiftData，每次讀寫使用一次性 context；跨 Feature 共用的 Service 放 `Core/` (依能力分資料夾)。production 唯一的 `ModelContainer` 由 `BuyLedgerDatabaseKey.liveValue` 從 `PersistenceContainer.bootstrap` 取得，Feature 以 `@Dependency(\.xxxService)` 取用 Service。
- **訂單資料**：`OrdersFeature` 持有無鍵 `@Shared` 訂單，只有 `OrdersLoadFeature` 與 `OrderWritesFeature` 在 reducer 內更新，清單與詳情只拿 `SharedReader`。Root 在來源改動的同一次 action 把訂單投影給開團、「更多」、首頁與分析，並把開團、預設幣別與 AI 摘要設定投影給 Orders。
- **主檔資料** (訂單來源／商品類別／付款方式／對帳狀態)：以 `@Shared(.lookupCatalog)` 的 `LookupCatalog` 為單一來源，讀寫經 `LookupService`；寫入者只有 `LookupCatalogFeature` (載入與表單新增選項) 與 `LookupManagementFeature` (管理頁 CRUD)，訂單端唯讀。改名由 `LookupService.renameItem` 在同一筆交易內改主檔與引用訂單，Root 再以 `.orders(.rootRequest(.cascade(...)))` 同步共用訂單。
- **啟動順序**：Root 先讀主檔目錄，讀取結束後才載入訂單；開團載入與自動結單由 `CampaignLoadFeature` 負責，幣別快取載入到 `@Shared(.currencyCodes)`。訂單表單的選項 (主檔、開團、幣別與行事曆) 一律由容器建立 `OrderEditOptions` 交入，表單不自行讀取。
- **範例資料**：`liveValue` 是純本機 SwiftData、**不自動 seed**，首次啟動是真正的空狀態；`BuyLedgerDatabaseKey.previewValue` 是 seed 過 `LedgerOrder.sampleOrders` 與 `CurrencyCode.defaults` 的記憶體資料庫，以資料庫為下層的 Service 的 `previewValue` 共用它，只能在 Preview 與測試使用。`LedgerOrder.sampleOrders` 與 `FxRateSnapshot.fallback` runtime 不讀取。
- **Schema 版本化**：`BuyLedgerSchema.swift` 以 `VersionedSchema` (floor `BuyLedgerSchemaV15` → target `BuyLedgerSchemaV17`) 與 `BuyLedgerMigrationPlan` 管理遷移，新增欄位／表走 lightweight，改既有欄位型別或 `@Model` 類別名走 custom dump-and-restore；硬規則見 [`.claude/rules/ios-data-layer.md`](../../.claude/rules/ios-data-layer.md) 的「Schema 與遷移」。開團訂購提醒連結表 `CampaignReminderRecord` 是唯一的 iOS-only 表，不入跨平台 schema。

### 隱私與遙測

遙測強制開啟，設定頁不提供任何相關開關或說明：產物不對外散布、僅安裝於開發者自己的裝置，不涉及第三方使用者的同意權。相關揭露只放在產物內的 `PrivacyInfo.xcprivacy` 隱私資訊清單 (宣告使用者預設值的具名理由與所連結遙測 SDK 的資料類型)；細節見 [`.claude/rules/ios-firebase-privacy.md`](../../.claude/rules/ios-firebase-privacy.md)。

### 帳本保護

「更多 → 設定」的「帳本保護」單一開關同時啟用「App 進入背景即上鎖」與「回到前景或冷啟動需通過驗證才顯示內容」，關閉時完全回到現況。開啟前需先通過一次系統本機驗證 (`BiometricAuthService`，涵蓋生物辨識與裝置密碼後備)，成功才寫入偏好；失敗、取消或裝置不支援時開關回到關閉並以對話框說明原因。上鎖只保證回到前景需要驗證，不保證多工切換器縮圖排除內容 (已知取捨)；觸發訊號與接線規則見 [`.claude/rules/ios-navigation.md`](../../.claude/rules/ios-navigation.md) 的「App 鎖定」。

- `AppLockFeature`：鎖定／解鎖狀態機，常駐於 `RootFeature.State.appLock`，啟用狀態由 Root 依偏好同步；`BuyLedgerApp` 把 `\.scenePhase` 轉成 `AppScenePhase` 交給它決定上鎖與解鎖。
- `AppLockView`：鎖定時取代整個介面的阻斷畫面，只提供「重新驗證」(不提供跳過)。
- `SettingsFeature`：負責啟用前的驗證與失敗說明，成功才寫回 `SettingsService`，並以 `delegate(.preferencesChanged)` 回報給 Root。
- UI 測試以 `-BLUITestAppLockEnabled` 直接抵達鎖定狀態、`-BLUITestBiometricScenario` 選擇驗證情境，全程不觸發系統生物辨識提示。

### 外部 API

- **ExchangeRate-API v6**：`latest/{base}` (匯率) 與 `codes` (幣別清單) 兩個 endpoint，請求組裝、解碼與服務錯誤分類集中在 `ExchangeRateEndpoint`。`ExchangeRateService.fetchLatest(.twd)` 取最新匯率；App 啟動時經 `CurrencyMetadataService.refreshIfStale` 打 `/codes` 載入幣別主檔並 cache 7 天。
- **Ollama Cloud**：`AISummaryService` 串接 chat streaming (`POST https://ollama.com/api/chat`)，在訂單詳情串流產生 Markdown 商品明細總結 (逐位元組串流走 `HTTPClientProtocol.stream`)；缺金鑰或服務錯誤時進入失敗狀態並提供重試，面板關閉時取消串流。

**Fallback 原則**：遵循 root [README.md › 產品政策](../../README.md#產品政策)，匯率與分析 UI 顯示「—」、「尚無可用匯率資料」、「尚未有足夠可用於分析的資料」等空狀態，避免使用者誤信過期或內建匯率。

## Troubleshooting

### Snapshot baseline 漂移

設計大改時請刪掉對應 baseline (`BuyLedgerTests/SnapshotTests/__Snapshots__/<測試檔名>/*.png`) 讓下一次跑測試自動重建。Baseline 失準若不是來自設計變動，先確認模擬器外觀是淺色，以及測試是否走 `TestDependencies.withFixedNow { ... }` 注入固定 `Date`、`TimeZone`、`Calendar`。
