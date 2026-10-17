## Summary

把訂單分頁 (`apps/ios/BuyLedger/Features/Orders/`) 與對應單元測試對齊 `/ios-dev-kit`，涵蓋第 6 步拆出的 6a (訂單編輯) 與 6b (訂單分頁拆分) 兩部分：

- 1,405 行的 `OrdersFeature` 比照第 5 步開團的方案 B，拆成容器 `OrdersFeature` (唯一呈現者)、清單 `OrderListFeature`、詳情 `OrderDetailFeature` (iPhone 推入與 iPad 右欄共用)，以及無 View 的載入子 Feature `OrdersLoadFeature` 與寫入子 Feature `OrderWritesFeature`。
- 訂單編輯 (`OrderEditFeature`／`OrderEditView`) 整檔對齊，照片管理抽成子 Feature，表單選項改在建立時帶入，接上新訂單預設幣別。
- 一併修正兩部分已知缺陷，並根除 `SnapshotTests` 整批執行時訂單編輯 snapshot 的「Unimplemented: …Service」外溢。

change 名稱沿用最初只含 6a 時的 `order-edit-style-compliance`。範圍演變：

- 2026-10-04 第 6 步 discuss 定出各項內容。
- 2026-10-06 使用者裁決：幣別清單由 Root 載入並共用；改到的測試檔與 `OrdersFeature` 整檔對齊。
- 2026-10-07 Codex 審查實測：`/ios-dev-kit` 規定 State、Action、依賴與 `body` 必須在 Feature 主檔，`OrdersFeature` 光這三塊就有 421 行，不拆 Feature 就無法壓到 300 行。使用者因此裁決把 6b 的 Feature 拆分併入本 change，並把 `OrderEditFeature` 的照片管理抽成子 Feature。

## Motivation

- **規模與結構** (2026-10-06 實測)：
    - `OrdersFeature` 1,405 行：55 個平放 Action、7 個 `@Presents`、三段 inline `Reduce`。
    - `OrderEditFeature` 1,086 行，`body` 是 467 行的 inline `Reduce`。
    - `OrderEditView` 1,035 行；`OrderDetailView` 894 行，是無 store 的純 View，iPhone 與 iPad 各自在父層寫一套狀態與「更多」選單。
    - 整檔基準 201 筆機械問題 (見 `findings.md`，另有本次擴大範圍的檔待補量)。
- **表單自己抓選項造成重複與測試外溢**：
    - `OrderEditFeature` 在 `.task` 自行抓四種主檔、開團與幣別，父層其實早已持有前五種。
    - Root 從首頁開新訂單只帶 id 與日期。
    - snapshot 測試沒覆寫這些 Service，整批執行 log 記錄三條 orderEditView 共 18 個 Unimplemented issue。
- **Root 直接驅動 Orders 內部**：Root 送 `.task`、`.receiptStatusChanged`、`.paymentMethodFlagsApplied` 這些 Orders 內部 action，直接改篩選欄位，並在 `RootFeature` 內建立表單 State。
- **開團資料只在進過開團分頁後才有**：開團只在 `CampaignListView` 出現時載入，首頁開團卡與分析頁每團毛利排行冷啟動時空白 (第 5 步 task 0.3 實測)。訂單端另有一份重複的結單日自動轉狀態寫入。
- **已確認的缺陷** (2026-10-06／07 唯讀調查)：
    - 合併確認一開就判定為已修改。
    - 金額綁定 `.binding(\.draft.chargedAmount)` 從畫面永遠不成立，編輯中不夾限。
    - 費率經 `Double` 丟精度 (4.56 存成 0.04559999999999998976)。
    - 重選日期可能改變草稿。
    - 新訂單幣別寫死 TWD。
    - 表單新增主檔選項先改畫面再寫入、失敗不撤回。
    - `statusChanged` 沒擋 `.merged`。
    - `pruneDetailPath` 用 `removeAll` (規則要 `pop(from:)`)。
    - 合併資格判斷在四處 View 重複。
    - 日標題與完整時間以裝置時區格式化，而不是注入 calendar 的時區。
    - dead code：`selectedOrder(referenceDate:)`、`Field.itemQuantity`、`canRemovePhotos`、永不回 nil 的 `resolveWriteResult`，以及從未被畫面送出的「訂單依開團篩選」。

## Proposed Solution

- **四個 Feature 與兩個無 View 子 Feature**：
    - **容器 `OrdersFeature`**：持有無鍵 `@Shared` 訂單 (自己不寫) 與單一 `Destination` (編輯表單、合併、AI 摘要、alert)。是唯一呈現者，寫入失敗等表單關好才顯示。
    - **載入 `OrdersLoadFeature`**：無 View，載入訂單與四種主檔，在「載入中或已載入」時略過。
    - **清單 `OrderListFeature`**：負責篩選、搜尋、多選、篩選 sheet、日期分組與 `dateContext`。
    - **詳情 `OrderDetailFeature`**：無 effect，負責詳情內容、可選狀態、可否合併、成本組成；iPhone 以 `StackState` 推入，iPad 右欄共用同一個 Feature。
    - **寫入 `OrderWritesFeature`**：無 View，所有訂單與新增主檔選項的寫入、Root 的 cascade 與付款方式旗標套用都由它處理，先落盤、成功才更新共用資料 (合併維持既有的樂觀更新加快照回滾例外)。
- **Root 只送請求、讀投影**：
    - Root 啟動時送 `.orders(.loadRequested)`、`.campaigns(.loadRequested)`；首頁、分析、客戶的重試經 delegate 由 Root 再送。
    - 開團載入與結單日自動轉狀態從 `CampaignListFeature` 移到開團端的無 View 子 Feature。
    - 收款切換、付款方式旗標與 cascade 改為請求 action；「父層請求」這一組寫進規格 `app-layer-boundaries`。
    - 篩選深連結與首頁新訂單改呼叫容器的 State 方法。
    - AI 摘要設定、預設幣別、開團以投影提供。
- **訂單編輯**：
    - 選項整理成一個值，四個入口以同一個建構方式在建立表單時帶入，幣別清單由 Root 載入到記憶體內共用狀態。
    - 預設幣別成為新訂單的初始草稿。
    - Action 分 `view`／`delegate`，父層只攔 delegate。
    - 照片管理抽成子 Feature；畫面拆區段，六個選擇列合成保留按壓高亮的共用元件。
- **其他**：
    - 修正上列缺陷。
    - 日標題、開團年月標題與完整時間改用注入 calendar 的時區並移到共用層。
    - 刪除訂單依開團篩選與規格 `order-campaign-filter`。
    - 移除 iPad 側邊欄的「智慧分組」(使用者 2026-10-09 裁決)：八個訂單狀態捷徑、各列筆數與對應的深連結一併刪除，保留「訂單」列的進行中徽章。
- **測試**：
    - 改動前先錄必要的 snapshot 與 UI 測試基準。
    - 補「重試後載入成功」UI 測試。
    - 所有受影響的測試檔 (含 `OrdersFeatureTests` 3,244 行) 依 Feature 與主題拆檔並整檔對齊。
    - 整批 snapshot 外溢以修正前後的整批量測驗收。

## Non-Goals (optional)

- **6c**：Service 搬到擁有者 (`OrderService` → `Orders/Data/`、四個主檔 Service → `Lookups/Data/`)、訂單只讀 `lookupCatalog`、表單新增選項經 Root 轉主檔端、改名改由主檔與開團 Service 在同一交易更新訂單。本 change 期間訂單對主檔 Service 的注入維持，登記為過渡例外。
- **6d**：訂單篩選 sheet 的重新設計；本 change 只把它改綁到清單 Feature，畫面不變。
- **第 7 步**：首頁與分析頁的現在時間與畫面計算移進 reducer。
- **範圍外的已知問題**：
    - 試算頁 `quoteView` 兩條同型的 `fetchCodes` Unimplemented：屬 `QuoteRateFeature`，結案時回報。
    - 幣別清單為空時退回 `CurrencyCode.defaults` 的既有行為不變，是否違反「幣別清單不可 hardcode」另案討論。
- **目錄**：`Features/Orders/` 維持除 `Components/` 與 `Data/` 外扁平 (比照開團，資料夾重整留第 10 步)。

## Alternatives Considered (optional)

- **`OrdersFeature` 只整檔對齊、行數登記例外到 6b**：工作量較小，但使用者 2026-10-07 選擇本 change 直接拆 Feature。
- **State／Action 分檔而不拆 Feature**：`@CasePathable` 明確標註後技術上可編譯，但違反 `/ios-dev-kit`「State 與 Action 必須在本體」，不採用。
- **表單只保留抓幣別**：snapshot 仍要覆寫幣別 Service，表單仍有自己的資料來源；使用者 2026-10-06 選擇由 Root 載入並共用。

## Impact

- Affected specs：
    - 修改 `order-campaign-assignment`、`app-layer-boundaries`
    - 修改 `navigation-path-integrity`、`order-category-filter`、`interface-consistency` (移除智慧分組相關的情境與側邊欄色相軌)
    - 移除 `order-campaign-filter`
    - 新增 `order-editor-options`
    - 在 `app-settings`、`sheet-dismissal-safeguard`、`campaign-analytics-surfaces`、`app-localization`、`order-write-integrity` 各新增需求
- Affected code:
  - Modified:
    - apps/ios/BuyLedger/Features/Orders/ 下訂單分頁與編輯的 Feature、View、Components、Operations 檔 (`OrdersFeature`、`OrderEditFeature`、`OrderEditView`、`OrderDraft`、`OrderMergeFeature`、`OrdersView`、`OrdersCompactView`、`OrdersRegularListColumn`、`OrdersRegularDetailColumn`、`OrdersFilterOperations`、`OrdersBatchOperations`、`OrdersMergeFlowOperations`、`Components/OrderDetailView`、`Components/OrderFilterSheet`、`Components/OrderMergeCandidateSheet`、`Components/OrdersToolbarContent`、`Components/OrderSelectableRow`、`Components/OrderFormatters`、`OrderDateSection`)
    - apps/ios/BuyLedger/Features/Campaigns/ 的 `CampaignFeature`、`CampaignListFeature`、`CampaignFormatters`
    - apps/ios/BuyLedger/Features/App/ 的 `RootFeature`、`RootNavigationOperations`、`RootCascadeOperations`、`RootSidebarLayout`、`SidebarBadgeCounts`
    - apps/ios/BuyLedger/Features/Orders/Components/OrderStatus+Presentation.swift (刪除側邊欄色相)、apps/ios/BuyLedgerAccessibilityIDs/BLAccessibilityID+App.swift
    - apps/ios/BuyLedger/Features/Dashboard/、Insights/、Customers/、More/ 中引用 `OrdersFeature.State.LoadState` 或轉送載入的檔
    - apps/ios/BuyLedger/Features/Dashboard/DashboardFeature.swift、DashboardOngoingCampaignsSection.swift、DashboardView.swift、DashboardRecentOrdersSection.swift 與 apps/ios/BuyLedger/Features/Insights/InsightsFeature.swift、InsightsView.swift (7.1 第一輪後整檔對齊 Feature、畫面只改送出點)
    - apps/ios/BuyLedgerTests/ 中 Orders、OrderEdit、OrderDraft、OrderMerge、OrdersFilterOperations、Root、Campaign 整合、守門掃描 (`ActionGroupingScanTests`、`ProjectionWriteBoundaryTests`、`LocalizationCatalogTests+SourceGuards`) 與 snapshot 的相關檔
    - apps/ios/BuyLedgerUITests/ 中 Orders 與首頁相關測試及 page object
    - apps/ios/CLAUDE.md、apps/ios/README.md、.claude/rules/ios-navigation.md、.claude/rules/ios-data-layer.md 等受影響的規則檔
  - New:
    - `OrderListFeature`、`OrderDetailFeature`、`OrdersLoadFeature`、`OrderWritesFeature`、OrderEdit 的照片子 Feature、開團載入子 Feature、`OrdersFeature+Destination`／`+Path`，以及請求值、呈現佇列、選項值、查詢輔助等純型別檔
    - apps/ios/BuyLedger/Core/Dependencies/SharedKey+CurrencyCodes.swift
    - 共用層的日期區段標題格式化檔 (位置依 design)
    - 依 Feature 與主題拆出的測試檔、新增的 UI 測試檔
    - openspec/changes/order-edit-style-compliance/findings.md 與 reference/ (含 7.1 第一輪紀錄 reference/gate71-round1.md)
  - Removed:
    - apps/ios/BuyLedger/Features/Orders/OrdersFeature+StateQuery.swift (成員分到各 Feature 與輔助型別)
    - apps/ios/BuyLedger/Features/Orders/OrderDetailPath.swift (由 `OrderDetailFeature` 取代)
    - apps/ios/BuyLedger/Features/App/SidebarSmartGroup.swift (智慧分組移除)
    - openspec/specs/order-campaign-filter/ (歸檔時移除)
