## Problem

`load-failure-reload-loop` (2026-11-09 archive) 的後續待辦留下三個載入狀態缺口，使用者 2026-11-10 重排剩餘次序時把它們排為第 2 項並合成一個 change：

- **匯率頁與報價頁可能永遠停在載入中**：`FxView`、`QuoteView` 的 `.task` 等待 `finish()` (標為 `task-finish-exempt: 已知風險`)。兩頁是「更多」分頁堆疊 (`MoreFeature.State.path`) 的元素，切到其他根分頁時堆疊原樣保留、畫面消失，`.task` 被取消並連帶取消匯率讀取；回應沒送回 reducer，`isLoading` 停在 `true`。切回時 `view(.task)` 被「載入中」去重擋下，重試鍵在載入中也不顯示，只能離開工具再重新進入。推論鏈中「切分頁會取消 `.task`」這一環尚未實測，其餘各環已由讀碼確認 (見 design)。
- **客戶頁把讀取失敗與載入中顯示成「尚無客戶」**：`CustomersFeature` 沒有載入狀態，`CustomersView` 只看訂單是否為空。訂單讀取失敗或還在讀取時，畫面顯示建議「建立訂單」的空狀態，違反 honest-state-feedback「Load failure is surfaced with a reason and a recovery path」第一句 (要顯示失敗原因與重試)。
- **`OrderListFeature.State.isLoading` 投影已無畫面讀取**：`load-failure-reload-loop` 之後兩個清單 view 改由 `loadState` 推導，這個欄位只剩 `OrdersFeature` 建立時傳入與兩個測試引用。

## Root Cause

- 匯率與報價：兩頁的狀態壽命由「更多」堆疊元素決定 (切分頁保留、返回或換工具才移除)，`.task` 的壽命卻由畫面決定 (切分頁就取消)。等待 `finish()` 讓讀取綁在較短的那一個上；兩個載入器都以「只由回應清除的載入中旗標」去重，回應一次被丟棄就無法自行恢復 (同 `.claude/rules/ios-navigation.md` 對 `OrdersLoadFeature` 等載入器的描述)。
- 客戶頁：Root 只把訂單載入狀態投影給總覽與分析 (`RootFeature` 的 `.onChange(of: \.orders.loadState)`)，「更多」與客戶頁只收到訂單投影，沒有載入狀態可分辨「已載入且為空」、「失敗」與「載入中」。

## Proposed Solution

- **匯率頁與報價頁**：`.task` 改成只呼叫 `store.send(.view(.task))`，刪除兩處 `task-finish-exempt` 標記 (主對話決定)。讀取的壽命改跟狀態：切分頁時讀取繼續，回應寫回仍在堆疊內的元素；返回或換工具移除元素時，由 TCA 的 `forEach(\.path, action: \.path)` 取消該元素的 effect (TCA 1.26.2 的 API 文件與實作已確認，以 `TestStore` 回歸測試固定)。Root 直接呼叫 `showSettings()` 改堆疊時不經過「更多」的 reducer，apply 時實測確認取消會延後、回應送給已移除的元素，使用者選定改由 Root 送「更多」的專用請求 action。
- **先重現再修**：新增 UI 測試替身「匯率讀取延遲後失敗」，以 UI 測試在讀取中切到其他根分頁再切回；修改前預期停在載入中而失敗，修改後顯示失敗訊息與重試鍵。修改前沒有重現時停下回報使用者，客戶頁與訂單清單照常進行。
- **客戶頁**：Root 把訂單載入狀態也投影到「更多」(比照既有的訂單投影)，客戶頁以唯讀引用取得，並在 State 推導畫面狀態 (載入中、失敗、空狀態、客戶清單)；失敗時顯示原因與重試鍵，重試經既有的 `delegate(.ordersLoadRequested)` 由 Root 先讀主檔目錄再讀訂單。
- **移除 `OrderListFeature.State.isLoading`**：連同 `OrdersFeature` 的建立參數與兩個測試的引用一起移除，行為不變。
- **規格與規則**：honest-state-feedback 補上工具頁切分頁、客戶頁載入狀態的情境；customer-summary 的空狀態情境限定為「訂單已載入且沒有訂單」；`.claude/rules/ios-navigation.md`、`.claude/rules/ios-data-layer.md` 與 `apps/ios/CLAUDE.md` 同步現行做法。

決策來源、替代方案、提案審查紀錄見 design.md。

## Non-Goals (optional)

見 design.md 的 Goals / Non-Goals。

## Success Criteria

- 匯率頁與報價頁的切分頁 UI 測試 (匯率讀取延遲後失敗，讀取中切到其他根分頁再切回)：驗收目標是修改前在 iPhone 17 (iOS 26.5) 連跑 3 次都因停在載入中而失敗 (實際結果與時間軸在 apply 時寫進 design)；修改後在 iPhone 17 與 iPad Air 11-inch (M4) (iPadOS 27.0) 連跑 3 次都通過：切回時原讀取仍在進行，讀取結束後顯示失敗訊息與重試鍵且不再回到載入中，按重試會再次讀取。
- `FxView`、`QuoteView` 不再有 `task-finish-exempt` 標記，`TaskFinishConventionScanTests` 通過；`FxFeatureTests`、`QuoteFeatureTests` 不改預期值通過。
- `TestStore` 回歸測試確認：匯率頁或報價頁在讀取中經 production 的返回與換工具路徑移出「更多」堆疊時，讀取被取消，不會把回應送給已不存在的元素；訂單頁的 AI 設定深連結改經「更多」的請求後同樣取消 (修改前失敗已實測)。
- 客戶頁 UI 測試：訂單每次讀取失敗時顯示失敗訊息與重試鍵，不顯示空狀態；訂單延遲讀取時先顯示載入中，不顯示空狀態，讀取失敗後轉為失敗畫面；按重試後回到載入中再顯示失敗。兩台模擬器各連跑 3 次通過。customer-summary 的四種畫面狀態以參數化單元測試守住。
- 既有 `CustomersTests`、`SnapshotCustomersTests` 不改預期值、snapshot 不重錄通過；`LoadFailureReloadLoopTests` 的離開客戶頁案例改以載入中作為進入證據後通過；`ProjectionWriteBoundary` 守門涵蓋新的載入狀態投影 (「更多」與客戶頁只能讀，只有 Root 寫)。
- `OrderListFeature.State` 沒有 `isLoading`，`OrderListFeatureTests`、`OrdersFeatureListRequestsTests` 通過。
- 單元測試全套在 iPhone 17 (iOS 26.5) 通過；完整 UI 回歸在 iPhone 17 與 iPad Air 11-inch (M4) 各跑一次通過。

## Impact

- Affected specs: honest-state-feedback (modified)、customer-summary (modified)
- Affected code:
  - Modified:
    - apps/ios/BuyLedger/Features/FX/Presentation/Root/FxView.swift
    - apps/ios/BuyLedger/Features/FX/Presentation/Root/FxStatusBanner.swift
    - apps/ios/BuyLedger/Features/Quote/Presentation/Root/QuoteView.swift
    - apps/ios/BuyLedger/Features/Quote/Presentation/Root/QuoteStatusBanner.swift
    - apps/ios/BuyLedger/Features/Customers/Presentation/Root/CustomersFeature.swift
    - apps/ios/BuyLedger/Features/Customers/Presentation/Root/CustomersView.swift
    - apps/ios/BuyLedger/Features/More/Presentation/Root/MoreFeature.swift
    - apps/ios/BuyLedger/Features/App/Presentation/Root/RootFeature.swift
    - apps/ios/BuyLedger/Features/Orders/Presentation/OrderList/OrderListFeature.swift
    - apps/ios/BuyLedger/Features/Orders/Presentation/Root/OrdersFeature.swift
    - apps/ios/BuyLedgerAccessibilityIDs/BLAccessibilityID+More.swift
    - apps/ios/BuyLedger/App/Testing/Configuration/BLUITestLoadFailure.swift
    - apps/ios/BuyLedger/App/Testing/Overrides/DependencyValues+BLUITestOverrides.swift
    - apps/ios/BuyLedger/App/Testing/TestDoubles/BLUITestErrorFactory.swift
    - apps/ios/BuyLedgerUITests/Support/LaunchOptions.swift
    - apps/ios/BuyLedgerUITests/Screens/App/RootNavigationScreen.swift
    - apps/ios/BuyLedgerUITests/Tests/Navigation/LoadFailureReloadLoopTests.swift
    - apps/ios/BuyLedgerTests/Features/Customers/CustomersFeatureTests.swift
    - apps/ios/BuyLedgerTests/Features/More/MoreFeatureTests.swift
    - apps/ios/BuyLedgerTests/Features/More/MoreFeatureRelaysTests.swift
    - apps/ios/BuyLedgerTests/Features/App/RootFeatureLoadRequestsTests.swift
    - apps/ios/BuyLedgerTests/Features/App/RootFeatureSharedOrdersTests.swift
    - apps/ios/BuyLedgerTests/Features/App/RootFeatureOrderFiltersTests.swift
    - apps/ios/BuyLedgerTests/Features/App/RootFeatureDeepLinksTests.swift
    - apps/ios/BuyLedgerTests/Features/App/RootFeatureCampaignLoadingTests.swift
    - apps/ios/BuyLedgerTests/Features/App/RootFeatureLoadCancellationTests.swift
    - apps/ios/BuyLedgerTests/Features/App/RootFeatureLookupCatalogTests.swift
    - apps/ios/BuyLedgerTests/Features/App/RootFeatureLookupCatalogFailuresTests.swift
    - apps/ios/BuyLedgerTests/Features/Campaigns/CampaignIntegrationTests.swift
    - apps/ios/BuyLedgerTests/Support/RootFeatureTestSupport.swift
    - apps/ios/BuyLedgerTests/SnapshotTests/SnapshotCustomersTests.swift
    - apps/ios/BuyLedgerTests/Features/Orders/OrderListFeatureTests.swift
    - apps/ios/BuyLedgerTests/Features/Orders/OrdersFeatureListRequestsTests.swift
    - apps/ios/BuyLedgerTests/Guards/ProjectionWriteBoundary/ProjectionWriteBoundaryGuardsTests.swift
    - apps/ios/BuyLedgerTests/Guards/ProjectionWriteBoundary/ProjectionWriteBoundaryScanner.swift
    - .claude/rules/ios-navigation.md
    - .claude/rules/ios-data-layer.md
    - .claude/rules/ios-unit-tests.md
    - apps/ios/CLAUDE.md
  - New:
    - apps/ios/BuyLedgerTests/Features/More/MoreFeatureToolLoadCancellationTests.swift
    - apps/ios/BuyLedgerTests/Features/App/RootFeatureToolLoadCancellationTests.swift
    - apps/ios/BuyLedgerTests/Features/App/RootFeatureCustomersLoadStateTests.swift
    - apps/ios/BuyLedgerUITests/Tests/Tools/ToolLoadTabSwitchTests.swift
    - apps/ios/BuyLedgerUITests/Tests/Customers/CustomersLoadStateTests.swift
  - Removed: (none)
- 行為：匯率頁與報價頁切分頁時讀取繼續，切回不再可能停在載入中；客戶頁在訂單讀取失敗與讀取中改顯示失敗畫面與載入中，不再顯示「尚無客戶」。其他畫面沒有變化。
