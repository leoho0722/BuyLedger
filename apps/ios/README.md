# BuyLedger — Apple 平台 (iOS / iPadOS)

BuyLedger 的 Apple 平台實作。產品介紹與 monorepo 結構見 repo 根目錄的 [`README.md`](../../README.md)；本檔涵蓋開發環境設定、build / test 與架構速覽。

## 技術棧

- **Swift 6 + SwiftUI**：strict concurrency
- **TCA ([Swift Composable Architecture](https://github.com/pointfreeco/swift-composable-architecture))**：feature 狀態、商業邏輯、副作用與依賴注入
- **SwiftData + CloudKit**：本機持久化為核心，CloudKit 同步介面 (``PersistenceContainer.CloudKitOption``) 已預留，待 Apple Developer 帳號 provision 後接上
- **Swift Charts**：Insights 頁的趨勢、類別與成本結構視覺化
- **EventKit**：開團訂購提醒寫入／移除系統行事曆 (`CalendarReminderService`)；因需支援移除既有事件而請求 full access，Info.plist 帶 `NSCalendarsFullAccessUsageDescription`
- **Ollama Cloud**：訂單 AI 商品明細總結 (chat streaming，`AISummaryService`)
- **[swift-snapshot-testing](https://github.com/pointfreeco/swift-snapshot-testing)**：UI 視覺迴歸測試

Xcode 專案：`apps/ios/BuyLedger.xcodeproj`，scheme：`BuyLedger`。需要 **Xcode 26+** 與 Swift 6 toolchain，App 最低支援 **iOS / iPadOS 26.0**。

Xcode project 使用 file system synchronized groups，新增或搬移檔案請優先動實體資料夾，再用 build 驗證 target 仍正確包含來源與資源。

## 專案結構

```text
apps/ios/
├── BuyLedger.xcodeproj/          # Xcode 專案；project.xcproj (JSON 格式) 提交、xcuserdata/ 不提交
├── BuyLedger/                    # App source root
│   ├── App/                      # 進入點：BuyLedgerApp、WindowGroup、AppDelegate、AppLaunchConfigurator
│   │   └── Testing/              # UI 測試啟動 harness (#if DEBUG)，組裝根與呼叫它的啟動設定同層；進入點 BLUITestHarness
│   │       ├── Configuration/    # 啟動參數解析 BLUITestConfiguration 與五個參數列舉 Language／LoadFailure／CalendarAccess／BiometricScenario／PersistenceMode
│   │       ├── Seed/             # 種子資料組合 BLUITestSeedProfile 與依組合寫入的 BLUITestSeedData (+各情境資料)
│   │       ├── TestDoubles/      # 依賴替身：幣別 API client 與設定來源、記憶體設定、照片快取、首讀失敗閘門、錯誤工廠與共用 stub
│   │       └── Overrides/        # DependencyValues+BLUITestOverrides／+BLUITestLookupOverrides，依啟動設定換上替身
│   ├── Core/
│   │   ├── Domain/               # LedgerOrder、FxRateSnapshot、FxRates、CurrencyCode 等 model
│   │   ├── Persistence/
│   │   │   ├── Database/         # BuyLedgerDatabase (actor，每次讀寫一次性 ModelContext)、PersistenceContainer、BuyLedgerSchema、store 隔離
│   │   │   ├── Records/          # 各 SwiftData @Model Record 與 NameLookupRecordProtocol
│   │   │   └── Errors/           # PersistenceError、PersistenceRecoveryError、RecordDecodingError 等持久化錯誤
│   │   ├── Dependencies/         # 跨 Feature 共用的 Service (`@Dependency(\.xxxService)` 注入)：幣別與匯率、BiometricAuthService；SharedKey+CurrencyCodes (記憶體內共用幣別清單)
│   │   ├── Storage/              # UserDefaultsStore、AppConfigurationStore (讀 Info.plist 設定) 的 protocol、實作與 Preview 替身
│   │   ├── Networking/
│   │   │   ├── Client/           # APIError、HTTPClient (send/stream)、HTTPMethod、URLRequestBuilder 與 Preview 替身
│   │   │   └── ExchangeRate/     # ExchangeRateEndpoint (ExchangeRate-API 請求與錯誤分類)、ExchangeRateLatestResponse、ExchangeRateCodesResponse
│   │   ├── Environment/          # RuntimeEnvironment (Preview／UI 測試／單元測試的執行環境判斷)
│   │   ├── Diagnostics/          # 啟動診斷送往當機診斷服務的可替換介面 (CrashDiagnosticsClient)
│   │   ├── Telemetry/            # TelemetryService：啟動時開啟 Firebase Analytics／Crashlytics／Performance 收集
│   │   └── Extensions/           # 系統型別的通用 extension (Bundle／Decimal／Image，一型一檔)
│   ├── Features/                 # 依功能切分的 TCA feature
│   │   ├── AISummary/            # 訂單 AI 商品明細總結 (Ollama Cloud 串流)，依 ios-dev-kit 的 Feature 結構分層
│   │   │   ├── Presentation/
│   │   │   │   └── Root/         # AISummaryFeature + AISummaryView
│   │   │   └── Data/             # AISummaryService、OllamaChatRequest、OllamaChatResponse
│   │   ├── App/                  # App 殼層，依 ios-dev-kit 的 Feature 結構分層
│   │   │   ├── Presentation/
│   │   │   │   ├── Root/         # RootFeature (殼層) + RootView + RootSidebarLayout / RootTabLayout；RootNavigationOperations (跨頁導覽)、SidebarBadgeCounts (分頁徽章計數與朗讀值)
│   │   │   │   ├── RootLaunch/   # 無畫面的 RootLaunchFeature (啟動幣別載入與重大時間變更) + RootLaunchOperations (其 effect)
│   │   │   │   ├── AppLock/      # AppLockFeature + AppLockView + AppLockFormatters
│   │   │   │   └── PersistenceFailure/ # PersistenceFailureFeature + PersistenceFailureView (資料庫無法開啟時的復原畫面)
│   │   │   ├── Domain/           # RootTab (分頁列舉)、AppScenePhase (殼層的場景階段)
│   │   │   └── Data/
│   │   │       ├── PersistenceRecovery/   # PersistenceRecoveryService (store 隔離)
│   │   │       └── SignificantTimeChange/ # SignificantTimeChangeService (系統重大時間變更監聽)
│   │   ├── Campaigns/            # 開團管理，依 ios-dev-kit 的 Feature 結構分層
│   │   │   ├── Presentation/
│   │   │   │   ├── Root/         # CampaignFeature (容器，+Path) + CampaignView；CampaignRequest、CampaignRequestPlan (請求分派)
│   │   │   │   ├── CampaignList/ # CampaignListFeature
│   │   │   │   │   ├── Views/    # CampaignListView、CampaignSectionList、CampaignRow
│   │   │   │   │   └── Queries/  # 日期區段與分組：CampaignDateSectionBuilder、CampaignDateSection、CampaignSubgroup、CampaignSectionTitle、CampaignGrouping
│   │   │   │   ├── CampaignDetail/ # CampaignDetailFeature + CampaignDetailView、CampaignDetailContent 與資訊／結算／分布區段
│   │   │   │   ├── CampaignEdit/ # CampaignEditFeature + CampaignEditView、CampaignEditNotesSection、CampaignDraft
│   │   │   │   ├── CampaignLoad/ # 無畫面的 CampaignLoadFeature (載入與自動結單)
│   │   │   │   ├── CampaignWrites/ # 無畫面的 CampaignWritesFeature + CampaignSavePlan
│   │   │   │   ├── CampaignReminder/ # 無畫面的 CampaignReminderFeature + CampaignReminderRequest、CampaignReminderReconcile
│   │   │   │   ├── CampaignPresentation/ # 無畫面的 CampaignPresentationFeature (表單、確認框與通知的呈現，+Destination) + CampaignPresentationQueue
│   │   │   │   └── Formatting/   # CampaignFormatters、CampaignStatusStyle (狀態的視覺語意)
│   │   │   ├── Domain/           # CampaignDateContext (列表記錄的現在時間與行事曆)
│   │   │   └── Data/
│   │   │       ├── Campaign/     # CampaignService (開團與提醒連結讀寫) + CampaignReminderLink (提醒連結值型別)
│   │   │       ├── CalendarReminder/ # CalendarReminderService (系統行事曆) + CalendarReminderError
│   │   │       └── OpenSettings/ # OpenSettingsService
│   │   ├── Customers/            # 客戶名單，依 ios-dev-kit 的 Feature 結構分層
│   │   │   └── Presentation/
│   │   │       ├── Root/         # CustomersFeature + CustomersView、CustomerTopCard、CustomerListRow；顯示用的 CustomerRow、CustomerRank
│   │   │       └── Formatting/   # CustomerFormatters、CustomerRankBadgeStyle (名次徽章配色)
│   │   ├── Dashboard/            # 總覽頁，依 ios-dev-kit 的 Feature 結構分層
│   │   │   ├── Presentation/
│   │   │   │   ├── Root/         # DashboardFeature (State.ongoingCampaignRows 提供進行中開團卡資料)
│   │   │   │   │   └── Views/    # DashboardView 與摘要、主卡、KPI、進行中開團、近期訂單區段
│   │   │   │   └── Formatting/   # DashboardFormatters
│   │   │   └── Domain/           # DashboardStats (本月與走勢統計)、DashboardDateContext
│   │   ├── FX/                   # 匯率工具，依 ios-dev-kit 的 Feature 結構分層
│   │   │   └── Presentation/
│   │   │       ├── Root/         # FxFeature + FxView、FxStatusBanner、FxRatesList
│   │   │       └── Formatting/   # FxFormatters
│   │   ├── Insights/             # 趨勢分析，依 ios-dev-kit 的 Feature 結構分層
│   │   │   ├── Presentation/
│   │   │   │   ├── Root/         # InsightsFeature
│   │   │   │   │   └── Views/    # InsightsView 與走勢、成本結構、每團毛利、熱力圖、類別排行五張卡
│   │   │   │   └── Formatting/   # InsightsFormatters
│   │   │   └── Domain/           # InsightsStats (+Trend) 與各卡的統計資料、InsightsDateRange、InsightsDateContext
│   │   ├── Lookups/              # 主檔管理 (訂單來源／商品類別／付款方式／對帳狀態)，依 ios-dev-kit 的 Feature 結構分層
│   │   │   ├── Presentation/
│   │   │   │   ├── Root/         # LookupManagementFeature (+Destination)；LookupItemOperations (讀寫分派)
│   │   │   │   │   └── Views/    # LookupManagementView、LookupItemList、LookupItemRow、LookupNameEditorSheet
│   │   │   │   ├── LookupAddForm/、LookupRenameForm/、PaymentMethodEditForm/ # 三種表單的無畫面 Feature (由 LookupNameEditorSheet 呈現)
│   │   │   │   ├── PaymentMethodCorrection/ # 無畫面的 PaymentMethodCorrectionFeature (付款方式更正確認與寫入)
│   │   │   │   └── LookupCatalog/ # 無畫面的 LookupCatalogFeature，載入與新增主檔目錄
│   │   │   ├── Domain/           # LookupCatalog + SharedKey+LookupCatalog、LookupKind、新增／改名請求與付款方式編輯結果
│   │   │   └── Data/             # LookupService (四種主檔的讀寫與改名、付款方式更正)
│   │   ├── More/                 # iOS「更多」入口，依 ios-dev-kit 的 Feature 結構分層
│   │   │   └── Presentation/
│   │   │       └── Root/         # MoreFeature (以 StackState 推入匯率、客戶、報價、主檔管理、設定) + MoreView
│   │   ├── Orders/               # 訂單容器、清單、詳情、寫入、載入與編輯流程，依 ios-dev-kit 的 Feature 結構分層
│   │   │   ├── Presentation/
│   │   │   │   ├── Root/         # OrdersFeature (容器組合子 Feature，共用訂單引用與 Root 投影，core 逐 case 轉送)
│   │   │   │   │   ├── Views/    # OrdersView (compact 分流與共用 sheet)、OrdersCompactView、OrdersRegularListColumn／OrdersRegularDetailColumn、OrdersToolbarContent
│   │   │   │   │   ├── Requests/ # OrdersRootRequest (根功能送進容器的請求)、OrderRequest + OrderRequestPlan (清單與詳情共用請求)
│   │   │   │   │   └── Plans/    # OrdersContainerPlan (+Requests／+Writes／+Presentation，回傳 OrdersRequestOutcome／OrdersWriteOutcome)、OrdersEditorOptions、OrdersMergeFlowOperations、OrderSummaryPrompt
│   │   │   │   ├── OrderList/    # OrderListFeature (搜尋、多選、日期分組與 iPad 選取；+Destination 呈現篩選 sheet 與 iPad 類別選擇器)
│   │   │   │   │   ├── Views/    # OrdersCompactListView、OrderSelectableRow
│   │   │   │   │   ├── Operations/ # OrderListInteraction、OrderListDestinationOperations、OrdersBatchOperations、OrdersFilterOperations
│   │   │   │   │   └── Queries/  # OrdersListQuery、OrdersQuery、OrderListSnapshot、OrderDateSection
│   │   │   │   ├── OrderDetail/  # OrderDetailFeature (iPhone 推入與 iPad 詳情欄共用的唯讀詳情)、OrderCostBreakdown
│   │   │   │   │   └── Views/    # OrderDetailView 與內容、成本、品項、備註、來源、摘要等子 View，OrderDetailToolbarContent、OrderDetailMenu
│   │   │   │   ├── OrdersDetailNavigation/ # 無畫面子 Feature：iPhone 詳情堆疊 (+Path) 與 iPad 詳情欄同步；OrdersDetailSelection
│   │   │   │   ├── OrderEdit/    # OrderEditFeature (草稿、驗證、焦點、捨棄確認與存檔請求)
│   │   │   │   │   ├── Views/    # OrderEditView、OrderEditDecimalField／PercentField、OrderEditSelectionRow、OrderEditPickerDestination
│   │   │   │   │   │   └── Sections/ # 基本、開團、成本、費用、品項、備註、原始、付款、狀態九個表單區段
│   │   │   │   │   ├── Models/   # OrderDraft (+WriteResult)、OrderEditOptions
│   │   │   │   │   └── Operations/ # OrderEditOperations、OrderEditDraftOperations、OrderEditOptionNormalizer、OrderPercentConversion
│   │   │   │   ├── OrderEditPhotos/ # OrderEditPhotosFeature (照片載入、匯入與編輯) + OrderEditPhotosSection
│   │   │   │   ├── OrderEditPickers/ # OrderEditPickersFeature (六種選項清單、選擇器路由與操作請求) + OrderEditPickerOperations
│   │   │   │   ├── OrderFilter/  # OrderFilterFeature (iPhone 篩選 sheet，暫存日期、付款方式與類別)、OrderFilterSelection、OrderFilterConfirmations (與類別選擇器共用的捨棄確認)
│   │   │   │   │   └── Views/    # OrderFilterSheet 與日期、付款方式、類別三個區段，OrderFilterPreviewFixtures
│   │   │   │   ├── OrderCategoryPicker/ # OrderCategoryPickerFeature (iPad 類別選擇器) + OrderCategoryPickerSheet
│   │   │   │   ├── OrderMerge/   # OrderMergeFeature (合併候選與照片挑選) + 候選 sheet 與照片挑選；OrderMergeCandidates (合併資格的純計算)
│   │   │   │   ├── OrdersLoad/   # 無畫面的 OrdersLoadFeature (訂單載入與共享載入狀態)
│   │   │   │   ├── OrderWrites/  # 無畫面的 OrderWritesFeature (寫入與交易後的調整) + OrderWriteOperations、OrderMergeSavePlan、OrdersCascadeOperations
│   │   │   │   ├── OrdersPresentation/ # 無畫面子 Feature：edit／merge／aiSummary／alert 呈現 (+Destination)；OrdersPresentationQueue (通知佇列與合併轉場)
│   │   │   │   ├── Components/   # 跨畫面共用：OrderRowView、OrderDetailRowMenu、OrderCategoryGrid、OrderCategoryFilterRows (兩個類別篩選畫面共用的搜尋列、全部列與空狀態列)
│   │   │   │   └── Formatting/   # OrderFormatters、OrderStatus+Presentation
│   │   │   ├── Domain/           # OrderDateContext、OrderDatePeriod、OrderStatusFilter、OrderStatusRules (可選狀態與合併入口資格)、OrderCategoryGroups (類別分組的純計算)、OrdersLoadState (首頁、分析與清單共用)、OrderAISummarySettings、LedgerOrder+OrderMutation
│   │   │   └── Data/
│   │   │       ├── Order/        # OrderService (訂單讀寫，+Reads／+Writes)、OrderError (訂單持久化錯誤)
│   │   │       └── Photo/        # PhotoService (相簿選取照片的匯入)、PhotoImportResult
│   │   ├── Quote/                # 報價試算，依 ios-dev-kit 的 Feature 結構分層
│   │   │   └── Presentation/
│   │   │       ├── Root/         # QuoteFeature + QuoteView、QuoteStatusBanner、QuoteBreakdownCard、QuoteInputsCard
│   │   │       ├── QuoteRate/    # 無畫面的 QuoteRateFeature 子 reducer (匯率來源與來源幣別選擇)
│   │   │       └── Formatting/   # QuoteFormatters
│   │   └── Settings/             # 設定，依 ios-dev-kit 的 Feature 結構分層
│   │       ├── Presentation/
│   │       │   └── Root/         # SettingsFeature (+Destination) + SettingsView；App 鎖定的啟用驗證與失敗說明也在這裡
│   │       ├── Domain/           # SettingsSnapshot (設定持久化的最小快照)、AISummaryModelCatalog (Ollama 模型目錄)
│   │       └── Data/             # SettingsService (使用者偏好的讀寫)
│   ├── Shared/
│   │   ├── Localization/         # 跨 feature 共用的語言型別 (AppLanguage 與 rootNavigationTitle 修飾子)、幣別顯示名稱單一入口 (CurrencyDisplayName)
│   │   ├── Media/                # 照片載入的降採樣與 JPEG 重編碼 (PhotoDataProcessor)
│   │   ├── DesignSystem/
│   │   │   ├── Foundations/      # 色盤、字級、間距、圓角等 token，BLLayoutClass 版面分類、BLFormatters 金額與日期區段／完整時間格式化
│   │   │   └── Components/       # BLAvatar、BLBadge、BLCard、BLBarChart、Pickers (OptionPickerSheet)、Forms (PaymentMethodEditorSheet) 等元件
│   └── Resources/                # Info.plist、entitlements、PrivacyInfo.xcprivacy (隱私資訊清單)、Config.example.xcconfig (範本，實際 Config.xcconfig 自填且 gitignored)、assets
├── BuyLedgerAccessibilityIDs/    # UI 測試 identifier 常數，BLAccessibilityID 依區域分檔為 +<區域>.swift (共用資料夾，同時編入 App 與 UITests 兩個 target)
├── BuyLedgerTests/               # 單元測試，依 ios-dev-kit 鏡像正式程式碼到 Feature 層
│   ├── Features/<Feature>/       # 各功能的 reducer、Service 與計算測試
│   ├── Core/、Shared/、App/Testing/ # 對應正式程式碼同名目錄的測試
│   ├── AccessibilityIDs/         # BLAccessibilityID 測試
│   ├── Guards/                   # 原始碼掃描與守門測試；多檔的守門依類別分資料夾 (LayerBoundary、DependencyConvention、ProjectionWriteBoundary、ServiceOwnership、LocalizationCatalog 等)，共用掃描器放 Scanning/
│   ├── SnapshotTests/            # swift-snapshot-testing 測試；baseline 在 __Snapshots__/<測試檔名>/
│   ├── Mocks/                    # BuyLedgerDatabase、HTTPClient、UserDefaultsStore、AppConfigurationStore 的 Mock 與 MockURLProtocol
│   ├── Fixtures/                 # Campaign、LedgerOrder 的測試用固定資料
│   └── Support/                  # TestDependencies、TestPaths 與測試容器等共用輔助
├── BuyLedgerUITests/             # XCUITest
│   ├── Support/                  # 共用 helper：Launch (BLUITestCase、LaunchOptions、AppNavigator)、Interactions (alert、選單、sheet、輸入、捲動)、Assertions (斷言、等待、診斷)、Layout (欄位邊界、轉向、平台範圍)
│   ├── Screens/                  # Page Object，依區域分 App、Orders、Campaigns、Dashboard、Insights、Customers、More、Tools，跨區共用的選擇器與編輯器放 Shared
│   └── Tests/                    # 流程與冒煙測試，依功能分組 (Orders 再分 Filters、Regular、Edit、Detail)；More 為「更多」入口的主檔管理流程
├── scripts/                      # upload-testflight.sh (Release 打包並上傳 TestFlight)
├── BuyLedger.xctestplan          # 主 scheme 測試計畫 (鎖 zh-Hant/TW、字母序執行、覆蓋率僅統計 App target)
├── BuyLedgerUITests.xctestplan   # UI 主回歸測試計畫 (鎖 zh-Hant/TW、關閉隨機順序)
└── BuyLedgerUITests-Performance.xctestplan  # UI 效能測試計畫 (啟動量測，獨立於主回歸)
```

## 開發環境設定

### 1. API 金鑰 (Config.xcconfig)

App 使用兩把 API key，皆透過 `Config.xcconfig` 注入 (機密)：

| 變數 | 用途 | 申請位置 |
| --- | --- | --- |
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

注入鏈路說明 (兩把 key 相同)：`Config.xcconfig` → `project.xcproj` 中 app target 的 `specialized-configurations` 掛到 Debug + Release config → `Info.plist` 內以 `$(EXCHANGE_RATE_API_KEY)` / `$(OLLAMA_API_KEY)` 引用 build setting，build 時被注入 → `AppConfigurationStoreKey.liveValue` 提供的 `AppConfigurationStore` 從 `Bundle.main` 的 Info.plist 讀回並正規化 (去除空白，空字串或未展開的 `$(KEY)` 視為未設定)。以上是金鑰如何進到產物內；金鑰進到產物後，兩個服務的實際請求皆以 Authorization header (`Bearer <key>`) 攜帶金鑰，端點路徑本身不含金鑰。

未設 key 時 App 仍可啟動：匯率工具與報價頁顯示「尚未設定 ExchangeRate-API 金鑰」橫幅；AI 總結面板顯示「尚未設定 OLLAMA_API_KEY。」並提供重試。

金鑰內嵌於產物 (而非執行期由使用者提供) 是已評估並接受的風險，其成立前提與前提失效時的作法見 [`.claude/rules/ios-integrations.md`](../../.claude/rules/ios-integrations.md) 的「外部 API」。

#### 撤換金鑰

金鑰疑似外洩或需要更換時：

1. **ExchangeRate-API**：登入 [exchangerate-api.com](https://www.exchangerate-api.com) 帳號後台，撤銷既有 key 並產生新 key。
2. **Ollama Cloud**：登入 [ollama.com](https://ollama.com) → Account → API keys，撤銷舊 key 並建立新 key。
3. 將新值填入本機 `Config.xcconfig` 對應變數。
4. **重新 build 並重新安裝 App**：金鑰是建置期注入 `Info.plist`、寫入產物 (見上方注入鏈路)，App 執行期不會重讀 `Config.xcconfig`；只改設定檔而不重新 build 並安裝，執行中的 App 仍使用舊金鑰。

第 4 步完成前，換發不算生效；服務商後台撤銷舊 key 後，未完成第 4 步的已安裝產物會立即改為 `invalidKey` 失敗狀態。

### 2. Build & Run

本專案預設用 `mobilebuildmcp` CLI 跑 build / run / test (MCP server `mobilebuildmcp mcp` 留給 UI 自動化、結構化測試結果與長時間操作可控中斷的情境)。下列指令一律從 repo 根目錄執行：

```bash
# iOS Simulator
mobilebuildmcp simulator build-and-run \
  --project-path apps/ios/BuyLedger.xcodeproj \
  --scheme BuyLedger \
  --simulator-name "iPhone 17"

# iPadOS Simulator
mobilebuildmcp simulator build-and-run \
  --project-path apps/ios/BuyLedger.xcodeproj \
  --scheme BuyLedger \
  --simulator-name "iPad Pro 13-inch (M5)"
```

> ⚠️ iOS 與 iPadOS 兩個 simulator build 共用同一份 `DerivedData/.../XCBuildData/build.db`，**不可並行 build**——請序列化 (`cmd1 && cmd2`) 以避免 `database is locked` 失敗。
>
> ⚠️ build 失敗時 CLI 預設只回 trailing `BUILD FAILED`；用 `mobilebuildmcp --log-level error <subcommand> ...` 取得實際 diagnostic。
>
> 💡 simulator 名稱會隨 Xcode 升級變動，先用 `mobilebuildmcp simulator list` 查當前可用名稱再改上方指令。

### 3. 執行測試

單元測試與 snapshot 測試 (主 scheme，掛 `BuyLedger.xctestplan`，語言／地區鎖 zh-Hant/TW、不隨模擬器系統狀態變動，覆蓋率僅統計 App target)：

```bash
mobilebuildmcp simulator test \
  --project-path apps/ios/BuyLedger.xcodeproj \
  --scheme BuyLedger \
  --simulator-name "iPhone 17"
```

Snapshot baseline 第一次跑會自動 record 並回報 fail (屬正常)，確認視覺正確後 commit baseline；之後變更若與 baseline 不符會 fail。固定時間注入的硬規則 (`TestDependencies.withFixedNow`) 見 [`.claude/rules/ios-unit-tests.md`](../../.claude/rules/ios-unit-tests.md) 的「Snapshot 測試」。

跑完測試後想查 App target 覆蓋率 (不設門檻，僅供盤點盲區)：

```bash
mobilebuildmcp simulator get-coverage-report --xcresult-path <測試輸出的 .xcresult 路徑> --target BuyLedger
```

UI 自動化測試 (XCUITest，獨立 scheme)：

```bash
mobilebuildmcp simulator test \
  --project-path apps/ios/BuyLedger.xcodeproj \
  --scheme BuyLedgerUITests \
  --simulator-name "iPhone 17"
```

UI 測試以啟動參數宣告前置條件 (資料、語言、時間、外部相依)，測試端用 `LaunchOptions` 組出、App 端由 `BLUITestConfiguration` 解析；常用旗標：`-BLUITest` (開啟測試模式)、`-BLUITestSeed <profile>` (注入種子資料)、`-BLUITestNow <ISO8601>` (固定時間)、`-BLUITestLanguage <traditionalChinese|english>`、`-BLUITestLoadFailure <orders|...>`。整套 harness 以 `#if DEBUG` 圈住、不進 Release。共用測試工具在 `BuyLedgerUITests/Support/` 與 `BuyLedgerUITests/Screens/`，identifier 常數在 `BuyLedgerAccessibilityIDs/` 的 `BLAccessibilityID+<區域>.swift` (同時編入 App 與 UITests 兩個 target)。硬規則 (一律用 identifier 定位、測試前必 seed、不得以 skip 掩蓋、僅覆蓋 iOS 26.x) 見 [`.claude/rules/ios-ui-tests.md`](../../.claude/rules/ios-ui-tests.md)。

> 💡 CLI 端篩選測試一律用 `-only-testing:`／`-skip-testing:` 旗標，不要用 `-testPlan`：`mobilebuildmcp` 的 `test` 子命令不理會經 `--extra-args` 傳入的 `-testPlan`，會退回 scheme 預設計畫。

### 4. 持續整合 (CI)

`.github/workflows/ci.yml` 定義兩個自動執行的 job：`codegen` (Linux runner，相依安裝 → 漂移檢查 → generator 測試 → 型別檢查) 與 `ios-unit-tests` (macOS runner，以釘選版本的 `mobilebuildmcp` CLI 執行主 scheme 測試，首波排除 snapshot 與效能測試)；UI 回歸僅在手動觸發時執行。repo 為公開專案，macOS runner 不計費。

CI 不使用任何 repository secret：`apps/ios/BuyLedger/Resources/GoogleService-Info.example.plist` 是入庫的佔位範本 (值皆為明顯假字串)，CI 建置前會複製成正式檔名，因為 Crashlytics 的 build phase 缺少這個檔會讓 build 失敗 (錯誤訊息為 `Could not get GOOGLE_APP_ID in Google Services file from build environment`)；此檔僅供 CI 使用，**本機開發請勿拿它覆蓋真實的 `GoogleService-Info.plist`**。

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

### 6. 發佈 TestFlight

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
- archive 放在 `~/Library/Developer/Xcode/Archives/`，Xcode Organizer 看得到；每次執行的 `ExportOptions.plist`、log 與 `--export-only` 匯出的 .ipa 放在 `apps/ios/build/testflight/<版號>-<build>-<時間>/` (已 gitignore)。
- 打包後若 `.xcstrings` 被 Xcode 改寫，腳本會列出變更，確認後再還原。

## 架構速覽

### App 進入點與平台導覽

`BuyLedgerApp.swift` 以單一 `RootFeature` store 驅動：`WindowGroup` 掛上 `RootView`；啟動時讀出一次設定快照直接傳入 `RootFeature.State`，首幀即使用已保存的語言、月目標與鎖定狀態；SwiftData container 不經 SwiftUI environment 注入，統一由 `BuyLedgerDatabase` 持有。單元測試 host 不建立根畫面，`BuyLedgerApp.init` 在 `RuntimeEnvironment.isUnitTesting` 時直接略過。`RootFeature.State.selectedTab` 驅動兩種 layout，由 `RootView` 依版面分類選擇：

| 版面分類 | Layout | 說明 |
| --- | --- | --- |
| regular 版面 (水平與垂直尺寸分類都是 regular，例如 iPad 全螢幕) | `RootSidebarLayout` | `NavigationSplitView`；訂單分頁為側邊欄、清單、詳情三欄，其他分頁為側邊欄與內容兩欄 |
| compact 版面 (其餘組合，含 iPhone 任何機型橫向與 iPad 窄視窗) | `RootTabLayout` | `TabView` |

版面分類由 `BLLayoutClass` (`Shared/DesignSystem/Foundations/`) 判斷，畫面以 `@Environment(\.blLayoutClass)` 讀取，不直接讀 `horizontalSizeClass`／`verticalSizeClass`。`RootView` 依視窗決定一次版面，並以 `.environment(\.blLayoutClass, …)` 交給子樹；split view 欄位回報的尺寸分類不在子樹重新推導。沒有經過 `RootView` 的 Preview 與截圖測試，由尺寸分類推導。大尺寸 iPhone 橫向的水平尺寸分類是 regular，但垂直是 compact，所以仍走 compact 版面。

`OrdersView` 依版面分類分流：compact 版面 → `OrdersCompactView` (`NavigationStack`)；regular 版面 → 根層三欄的清單欄 (`regularListContent`)，搜尋欄、標題、工具列與清單 sheet 都在清單欄內 (多選筆數顯示在清單欄頂部)，清單欄寬由 `RootSidebarLayout` 設定 (側邊欄並排時與詳情欄平分)，詳情欄由 `OrdersRegularDetailColumn` 提供，有選取的訂單時顯示 `OrderDetailView`，無選取或選取的訂單已不存在時顯示空狀態。`OrderDetailView` 提供詳情內容、導覽列的客戶名稱標題與操作選單 (`OrderDetailToolbarContent`)，iPhone 推入詳情使用同一個畫面，內容排版不分版面。iPhone 以詳情導覽子 Feature (`OrdersDetailNavigationFeature`) 的 `StackState` 推入 `OrderDetailFeature`，iPad 詳情欄以同一子 Feature 的 `regularDetail` 使用同一個 Feature。編輯、合併與 AI 摘要 sheet 綁定呈現子 Feature (`OrdersPresentationFeature`) 的單一 `destination`，一律掛在 `OrdersView` 外層，兩種版面共用。總覽頁 (hero 與 KPI 卡) 與分析頁 (卡片) 同樣依版面分類排列：regular 版面並排，compact 版面上下堆疊。

「更多」分頁由 `MoreFeature` 以 `StackState` 推入匯率工具、客戶名單、報價試算、四種主檔管理與設定，返回即釋放子畫面狀態；iPhone 切換分頁時保留堆疊，iPad 側邊欄切換前先清空 (`NavigationSplitView` 在路徑非空時切分頁會崩潰)。

### 資料層

- **Service 層** (`Core/Dependencies/` 與各 Feature 的 `Data/`)：`OrderService` (`Features/Orders/Data/Order/`)、`LookupService` (`Features/Lookups/Data/`)、`CampaignService` (`Features/Campaigns/Data/Campaign/`) 等以資料庫為下層的 Service 透過 `BuyLedgerDatabase` (`Core/Persistence/`) 操作 SwiftData，每次讀寫使用一次性 context；production 唯一的 `ModelContainer` 由 `BuyLedgerDatabaseKey.liveValue` 從 `PersistenceContainer.bootstrap` 取得，Feature 以 `@Dependency(\.xxxService)` 取用 Service。
- **訂單資料**：`OrdersFeature` 持有無鍵 `@Shared` 訂單，`OrderListFeature` 與 `OrderDetailFeature` 只拿 `SharedReader`；`OrdersLoadFeature` 與 `OrderWritesFeature` 在 reducer 內更新來源。Root 在來源改動的同一次 action 把訂單投影給開團、「更多」、首頁與分析，並把開團、預設幣別與 AI 摘要設定投影給 Orders。
- **主檔資料** (訂單來源／商品類別／付款方式／對帳狀態) 以 `@Shared(.lookupCatalog)` 的 `LookupCatalog` 為單一來源，讀寫經 `LookupService` (`Features/Lookups/Data/`)。主檔目錄的寫入者是 `LookupCatalogFeature` (無畫面，載入與表單新增選項，由 `MoreFeature` 組合) 與 `LookupManagementFeature` (管理頁 CRUD，以 `LookupKind` 分流)，訂單端以 `SharedReader` 唯讀。表單新增選項經 Root 與 `MoreFeature` 交給 `LookupCatalogFeature` 先落盤，結果回到發起的表單。主檔改名由 `LookupService.renameItem` 在同一筆交易內改主檔與引用訂單；`MoreFeature` 轉送改名 delegate，Root 送 `.orders(.rootRequest(.cascade(...)))`，由 `writes` 在 reducer 內以 `OrdersCascadeOperations` 改寫共用訂單，分派經 `LookupKind.isReferenced(by:name:)`／`LookupKind.renamingReference(in:from:to:)` 處理。
- **啟動與表單選項**：Root 啟動時先送 `more.catalogLoadRequested` 讀主檔目錄，讀取結束後才送訂單的 `rootRequest(.load)`，開團則送 `campaigns.loadRequested`；開團載入與自動結單由 `CampaignLoadFeature` 負責；幣別快取載入到 `@Shared(.currencyCodes)`。訂單新增、編輯、合併確認與首頁新增都由容器建立 `OrderEditOptions` (主檔、開團、幣別與行事曆)，表單不在 `.task` 讀取選項；首頁以 `presentNewOrder` 共用新增入口。
- `liveValue`：純本機 SwiftData，**不自動 seed**——使用者首次啟動會看到真正的空狀態。
- `previewValue`：in-memory + 自動 seed `LedgerOrder.sampleOrders`，讓 SwiftUI Preview 與 snapshot 測試看得到內容。
- `LedgerOrder.sampleOrders` 與 `FxRateSnapshot.fallback` **僅供 Preview / 單元測試 / `previewValue`** 使用，runtime 不讀取。
- **Schema 版本化**：`Core/Persistence/Database/BuyLedgerSchema.swift` 以 `VersionedSchema` (floor `BuyLedgerSchemaV15` → target `BuyLedgerSchemaV17`) + `BuyLedgerMigrationPlan` 管理遷移。新增欄位／表走 lightweight、改既有欄位型別或 `@Model` 類別名走 custom dump-and-restore；版本移除、shadow 凍結等硬規則見 [`.claude/rules/ios-data-layer.md`](../../.claude/rules/ios-data-layer.md) 的「Schema 與遷移」。開團訂購提醒連結表 `CampaignReminderRecord` 是唯一的 iOS-only 表 (記行事曆 `eventIdentifier` 與提醒時間戳，與跨平台 `Campaign` 解耦、不入跨平台 schema)。

### 隱私與遙測

遙測強制開啟，設定頁不提供任何相關開關或說明；本 App 產物不對外散布、僅安裝於開發者自己的裝置，不涉及第三方使用者的同意權議題。產物內含 `PrivacyInfo.xcprivacy` 隱私資訊清單，宣告使用者預設值的具名理由與所連結遙測 SDK 的資料類型，遙測相關揭露僅以此清單呈現；細節與 gotcha 見 [`.claude/rules/ios-firebase-privacy.md`](../../.claude/rules/ios-firebase-privacy.md)。

### 帳本保護

「更多 → 設定」的「帳本保護」區塊提供單一開關：開啟時同時啟用「App 進入背景即上鎖」與「回到前景或冷啟動需通過驗證才顯示內容」兩項保護，關閉時完全回到現況。啟用路徑本身需先通過一次系統本機驗證 (`BiometricAuthService`，`LAContext` 的 `.deviceOwnerAuthentication` 政策，涵蓋生物辨識與裝置密碼後備)，成功才寫入偏好；失敗、取消或裝置不支援則開關回到關閉並以對話框說明原因。上鎖只保證回到前景需要驗證，不保證多工切換器縮圖排除內容 (已知取捨，見 [`.claude/rules/ios-navigation.md`](../../.claude/rules/ios-navigation.md) 的「App 鎖定」)。

- `AppLockFeature` (`Features/App/Presentation/AppLock/`)：鎖定／解鎖狀態機，常駐於 `RootFeature.State.appLock`，啟用狀態由 Root 依偏好同步。
- `SettingsFeature` (`Features/Settings/Presentation/Root/`)：負責啟用前的驗證與失敗說明，成功才寫回 `SettingsService`，並以 `delegate(.preferencesChanged)` 回報給 Root。
- `AppLockView` (`Features/App/Presentation/AppLock/`)：鎖定時取代整個正常介面的阻斷畫面，提供「重新驗證」(不提供跳過)。
- `AppScenePhase` (`Features/App/Domain/`)：`BuyLedgerApp` 把 `\.scenePhase` 轉成這個殼層列舉，送 `AppLockFeature` 的 `.view(.scenePhaseChanged)`，進入背景上鎖、回到前景或冷啟動驗證解鎖由 reducer 決定；觸發訊號的選擇見 [`.claude/rules/ios-navigation.md`](../../.claude/rules/ios-navigation.md) 的「App 鎖定」。
- UI 測試以 `-BLUITestAppLockEnabled` 直接抵達鎖定狀態、`-BLUITestBiometricScenario` 選擇驗證情境，全程不觸發系統生物辨識提示。

### 外部 API

ExchangeRate-API v6 有兩個 endpoint：`latest/{base}` (匯率) 與 `codes` (幣別清單)，請求組裝、解碼與服務錯誤分類集中在 `ExchangeRateEndpoint` (`Core/Networking/ExchangeRate/`)。runtime 有兩個 call：`ExchangeRateService.fetchLatest(.twd)` (`Core/Dependencies/`) 取最新匯率；App 啟動時經 `CurrencyMetadataService.refreshIfStale` 打 `/codes` 載入幣別主檔並 cache 7 天 (幣別清單不再 hardcode)。

`AISummaryService` (`Features/AISummary/Data/`) 串接 Ollama Cloud chat streaming (`POST https://ollama.com/api/chat`)，在訂單詳情串流產生 Markdown 商品明細總結；缺金鑰或服務錯誤時進入 failed 狀態並提供重試，面板關閉時取消串流。逐位元組串流走 `HTTPClientProtocol.stream`。

**Fallback 原則**：遵循 root [README.md › 產品政策](../../README.md#產品政策)——匯率與分析 UI 顯示「—」、「尚無可用匯率資料」、「尚未有足夠可用於分析的資料」等空狀態，避免使用者誤信過期或內建匯率。

## Troubleshooting

### Snapshot baseline 漂移

設計大改時請刪掉對應 baseline (`BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotTests*/*.png`，依測試檔分資料夾) 讓下一次跑測試自動重建。Baseline 失準若不是來自設計變動，先確認測試是否走 `TestDependencies.withFixedNow { ... }` 注入固定 `Date`、`TimeZone`、`Calendar`。
