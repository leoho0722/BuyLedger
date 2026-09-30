## Problem

2026-09-14 以 ios-dev-kit 做全庫審查時，審查員逐檔讀過並對照產品程式碼，確認有一批測試「產品壞掉也會綠燈」。另外，UI 測試支援層有一個會打錯輸入值的邏輯錯誤。

- **單元測試無法失敗 (約 30 條，審查實測)**：
  - 斷言恆成立：例如 `OrderPersistenceTests` 的 4 條回滾測試斷言 `count <= 1`，而 store 起始為空、只寫入一筆，有沒有回滾都成立。
  - 期望值自我循環：例如 `PersistenceErrorContractTests` 整檔拿同一個字面值建出的 enum 跟自己比，沒有執行任何產品程式。
  - 重新載入時把原資料灌回去：`OrdersFeatureTests` 的「跨重新載入」測試直接送出 `.ordersLoaded([original])` 再斷言等於 original。
  - 沒有觸發名稱描述的行為：例如 `CampaignReminderFailureTests.removingAnAbsentEventRemainsANoOp` 從未呼叫移除事件的程式。
  - 取樣值讓正確與錯誤的實作得出相同結果：例如 `OrderEditFeatureTests.dateComponentsChangedMergesInjectedSeconds` 注入時間與選取時間的秒數都是 0。
  - 名稱宣稱的行為沒有被斷言：例如兩個 `cancelWithoutChangesDismissesDirectly` 沒有記錄 dismiss 是否被呼叫。
- **UI 測試無法失敗 (約 14 條，審查實測)**：
  - `FxTests`／`QuoteTests` 只檢查值非空，但 App 在無結果時顯示「—」或 NT$0，永遠非空。
  - `HarnessSelfCheckTests` 有 3 條的前置條件無法觸發被測行為 (兩次都以空資料啟動、注入時間等於預設值、啟動流程從不請求行事曆權限)。
  - 其餘為只檢查「有任一 alert」、否定斷言缺前置條件、以根容器存在代替分頁選取態等。
- **UI 測試支援層的輸入錯誤**：`FxScreen.typeAmount`、`QuoteScreen.typePrincipal`、`OrderEditScreen.typeChargedAmount` 在欄位現值等於要輸入的金額時跳過刪除，卻仍輸入一次，欄位變成重複的金額 (如 1000 變 10001000)。
- **UI 測試支援層遮蔽失敗**：
  - `waitUntilHittable` 與 `tapMenuItem` 標記 `@discardableResult`，Page Object 普遍丟棄等待結果後照樣點擊。2026-09-14 grep 實測 `waitUntilHittable()` 呼叫 57 處、`tapMenuItem(` 8 處。
  - `clearAndType` 找不到欄位時直接 `return`。
  - 7 個讀值方法在元素不存在時回傳空字串，與「值為空」無法區分。
  - 另有 6 處以 `_ =` 丟棄等待結果。

這些測試讓回歸套件看起來有保護，實際上守不住。後續整理 View 與 reducer 的重構需要一組真的能抓到回歸的測試當安全網，所以要先修。

## Root Cause

- 測試撰寫時只確認「現在會綠燈」，沒有確認「行為壞掉時會轉紅」。這類缺陷讀程式碼、看覆蓋率都難以發現，只能靠刻意破壞產品邏輯 (變異測試) 才抓得到。
- 取樣資料與注入值剛好讓正確與錯誤實作產生相同結果，斷言失去鑑別力。
- UI 支援層的 helper 以回傳 `Bool` 或空字串表達失敗，又允許呼叫端忽略結果，違反 `ui-test-support-layer` 規格「Failures are never masked」的精神。
- 輸入 helper 把「現值等於目標值」當成可以略過刪除的情況，但沒有同時略過輸入。

## Proposed Solution

- **單元測試**：逐條改寫成能區分正確與錯誤實作。
  - 讓斷言涵蓋名稱宣稱的行為：記錄 dismiss、搬移等副作用的呼叫，以 case key path 比對 delegate payload。
  - 讓讀回的資料真正來自儲存層，不由測試自己餵回。
  - 讓取樣值能分出兩種實作，例如注入秒數非 0 的時間、注入與 fallback 不同的匯率快照。
  - 無法改寫成有意義守門的測試 (例如整檔自我比較的錯誤合約測試) 改為觸發真實失敗路徑，或刪除。
  - 名稱與斷言不符的，擇一修正名稱或補齊斷言。
- **UI 測試**：斷言改為可觀察的具體結果 (換算後的金額、選取中的期間、alert 內的對應按鈕)，前置條件改成能觸發被測行為的流程，否定斷言先確認目標原本存在。
- **UI 支援層**：
  - 等待與點擊 helper 不再允許靜默忽略結果，元素缺失時一律以附診斷的方式失敗。
  - 讀值方法能區分「元素不存在」與「值為空」。
  - 輸入 helper 一律讓欄位最終內容等於要輸入的文字。
- **驗證方式**：每一條修正都要做一次變異驗證，暫時破壞對應的產品邏輯或 helper，確認該測試轉紅後再還原。

## Non-Goals (optional)

見 design.md 的 Goals / Non-Goals。

## Success Criteria

- 每一條被修正的測試，都附有一次變異驗證紀錄：寫明破壞了哪段邏輯，以及該測試因此失敗的訊息原文。
- `FxScreen`、`QuoteScreen`、`OrderEditScreen` 的金額輸入在欄位現值等於目標值時，欄位最終內容等於目標值。
- UI 支援層中不再有可被靜默忽略的等待或點擊結果：`waitUntilHittable`、`tapMenuItem` 不再標記 `@discardableResult`，Page Object 中沒有丟棄等待結果後直接互動的寫法。
- 主 scheme 單元測試與 `BuyLedgerUITests` 主回歸在 iPhone 與 iPad 模擬器上的結果，不得比變更前的基準多出失敗；新增或加強的斷言若揭露產品缺陷，於本 change 內修正產品程式並記錄。

## Impact

- Affected specs: `test-guard-effectiveness` (新增需求)、`ui-test-support-layer` (新增需求)
- Affected code:
  - Modified:
    - apps/ios/BuyLedger.xcodeproj/project.pbxproj
    - apps/ios/BuyLedger.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
    - apps/ios/BuyLedger/Core/Dependencies/OrderRepository.swift
    - apps/ios/BuyLedger/Core/Persistence/OrderPersistence.swift
    - apps/ios/BuyLedger/Features/App/AppLockFeature.swift
    - apps/ios/BuyLedger/Features/App/AppLockView.swift
    - apps/ios/BuyLedger/Features/Campaigns/CampaignDetailView.swift
    - apps/ios/BuyLedger/Features/Dashboard/DashboardView.swift
    - apps/ios/BuyLedger/Shared/DesignSystem/Components/Status/BLStatusPill.swift
    - apps/ios/BuyLedgerAccessibilityIDs/BLAccessibilityID.swift
    - apps/ios/BuyLedgerTests/OrderPersistenceTests.swift
    - apps/ios/BuyLedgerTests/OrdersFeatureTests.swift
    - apps/ios/BuyLedgerTests/OrderMergeFeatureTests.swift
    - apps/ios/BuyLedgerTests/CampaignReminderFailureTests.swift
    - apps/ios/BuyLedgerTests/CampaignFeatureTests.swift
    - apps/ios/BuyLedgerTests/CampaignEditFeatureTests.swift
    - apps/ios/BuyLedgerTests/OrderEditFeatureTests.swift
    - apps/ios/BuyLedgerTests/OrderEditFocusTests.swift
    - apps/ios/BuyLedgerTests/PersistenceFailureFeatureTests.swift
    - apps/ios/BuyLedgerTests/RootFeatureTests.swift
    - apps/ios/BuyLedgerTests/LookupManagementFeatureTests.swift
    - apps/ios/BuyLedgerTests/LookupCatalogTests.swift
    - apps/ios/BuyLedgerTests/FxFeatureTests.swift
    - apps/ios/BuyLedgerTests/ProjectionWriteBoundaryTests.swift
    - apps/ios/BuyLedgerTests/ColorContrastTests.swift
    - apps/ios/BuyLedgerTests/CurrencyMetadataCacheTests.swift
    - apps/ios/BuyLedgerTests/BLPhotoViewerTests.swift
    - apps/ios/BuyLedgerTests/CampaignSummaryTests.swift
    - apps/ios/BuyLedgerTests/LocalizationCatalogTests.swift
    - apps/ios/BuyLedgerTests/AppLockFeatureTests.swift
    - apps/ios/BuyLedgerTests/BiometricAuthClientTests.swift
    - apps/ios/BuyLedgerTests/CampaignIntegrationTests.swift
    - apps/ios/BuyLedgerTests/InsightsStatsTests.swift
    - apps/ios/BuyLedgerTests/OrderDraftTests.swift
    - apps/ios/BuyLedgerTests/OrderStatusTests.swift
    - apps/ios/BuyLedgerTests/PaymentMethodPersistenceTests.swift
    - apps/ios/BuyLedgerTests/TestDependencies.swift
    - apps/ios/BuyLedgerUITests/Support/Waiting.swift
    - apps/ios/BuyLedgerUITests/Support/MenuInteraction.swift
    - apps/ios/BuyLedgerUITests/Support/TextInput.swift
    - apps/ios/BuyLedgerUITests/Support/Scrolling.swift
    - apps/ios/BuyLedgerUITests/Support/Assertions.swift
    - apps/ios/BuyLedgerUITests/Support/Diagnostics.swift
    - apps/ios/BuyLedgerUITests/Support/AppNavigator.swift
    - apps/ios/BuyLedgerUITests/Screens/FxScreen.swift
    - apps/ios/BuyLedgerUITests/Screens/QuoteScreen.swift
    - apps/ios/BuyLedgerUITests/Screens/OrderEditScreen.swift
    - apps/ios/BuyLedgerUITests/Screens/DashboardScreen.swift
    - apps/ios/BuyLedgerUITests/Screens/CampaignDetailScreen.swift
    - apps/ios/BuyLedgerUITests/Screens/OrderDetailScreen.swift
    - apps/ios/BuyLedgerUITests/Screens/InsightsScreen.swift
    - apps/ios/BuyLedgerUITests/Screens/RootNavigationScreen.swift
    - apps/ios/BuyLedgerUITests/Screens/PhotoViewerScreen.swift
    - apps/ios/BuyLedgerUITests/Screens/CampaignEditScreen.swift
    - apps/ios/BuyLedgerUITests/Screens/SettingsScreen.swift
    - apps/ios/BuyLedgerUITests/Tests/Tools/FxTests.swift
    - apps/ios/BuyLedgerUITests/Tests/Tools/QuoteTests.swift
    - apps/ios/BuyLedgerUITests/Tests/Smoke/HarnessSelfCheckTests.swift
    - apps/ios/BuyLedgerUITests/Tests/Smoke/AppLockTests.swift
    - apps/ios/BuyLedgerUITests/KeyboardDismissTests.swift
    - apps/ios/BuyLedgerUITests/Tests/Insights/InsightsTests.swift
    - apps/ios/BuyLedgerUITests/Tests/Campaigns/CampaignDetailTests.swift
    - apps/ios/BuyLedgerUITests/Tests/Orders/OrdersListTests.swift
    - apps/ios/BuyLedgerUITests/Tests/Orders/OrderDetailTests.swift
    - 其餘呼叫 `waitUntilHittable` 或 `tapMenuItem` 的 Page Object 與 UI 測試 (隨 helper 簽章調整)
  - New:
    - apps/ios/BuyLedgerTests/LedgerOrder+TestSupport.swift
  - Removed:
    - apps/ios/BuyLedgerTests/PersistenceErrorContractTests.swift

`Interaction.swift` 曾作為暫時整併方案存在，但已刪除；最終診斷邏輯位於 `Diagnostics.swift`，等待／點擊 helper 位於 `Waiting.swift`，因此不列為新增檔案。

`Package.resolved` 的外部相依圖由 `swift-composable-architecture` 1.25.5 升至 1.26.2，並新增 `swift-issue-reporting` 2.1.0；`xctest-dynamic-overlay` 同步升至 1.13.1 以配合相依 target。這項升版是為了在 Xcode 27 上解除 TCA 舊版的編譯阻塞，讓本 change 的 AppLock 狀態修正與變異驗證可以執行，不是以相依套件變更取代產品行為修正。
