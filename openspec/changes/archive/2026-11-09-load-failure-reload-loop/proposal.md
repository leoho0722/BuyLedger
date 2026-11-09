## Problem

訂單載入持續失敗時切換分頁，訂單清單會一直停在「載入中」，看不到失敗訊息。這違反 `honest-state-feedback` 已有的要求「載入失敗要顯示原因與重試、不得無限停在載入中、不得自動重試成迴圈」。另外，訂單清單的載入失敗本來就只顯示一行文字，沒有重試鍵 (`OrderListFeature` 有 `view(.retryTapped)`，但沒有任何畫面送出它)，同樣不符合這條 requirement；而且失敗訊息下方同時顯示「沒有符合的訂單」空狀態，讓人誤以為是篩選條件的問題。

重現 (2026-11-08 於 `localization-resource-unification` 的 4.3 實測發現，iPhone 17 iOS 26.5 模擬器)：以 `-BLUITestLoadFailure orders` 啟動 → 切到訂單分頁 → 切到更多分頁 → 回到訂單分頁，訂單清單停在載入中。以改動前的 commit `1837124` 建置做同樣步驟，症狀相同，是既有缺陷。使用者 2026-11-08 決定另開本 change 修正；2026-11-08 規劃審查 (五位 agent 與 `opus-arch-reviewer`) 後，使用者決定本 change 一併處理：訂單清單補重試鍵且失敗時不顯示空狀態、新增「讀取延遲後失敗」的測試情境驗證取消問題、客戶頁納入修正、開團清單無條件修正、新增 `.task` 等待 `finish()` 的掃描守門。

## Root Cause

讀原始碼與官方文件後有兩條會造成同一症狀的機制，實際是哪一條 (或兩條都有) 由 tasks 的重現測試確認：

**分支互換重跑 `.task`**：`DashboardView` 把 `.task` 掛在 `content` 上，而 `content` 是 `Group { switch store.screenState { ... } }`。Apple 的 `Group` 文件寫明「套在 group 上的修飾器套用到 group 的所有成員，而不是 group 本身；例如把 `onAppear(perform:)` 套在包著 `if` 的 group 上，條件每次改變都會執行」。所以載入中與失敗兩個分支互換時，新分支出現就會再跑一次 `.task`：

1. `DashboardFeature` 收到 `view(.task)` 送 `delegate(.refresh)`。
2. `RootFeature` 轉成 `.more(.catalogLoadRequested)`；主檔已載入時 `LookupCatalogFeature` 立即回 `loadFinished`，Root 再送 `.orders(.rootRequest(.load))`。
3. `OrdersLoadFeature.loadRequested` 只在「不在讀取中且尚未成功載入」時開始讀取；上一次失敗後兩個條件都成立，於是開始讀取並把共享的 `errorMessage` 清成 `nil`，總覽的 `screenState` 變回載入中，換分支後 `.task` 又被觸發。
4. 讀取失敗寫回 `errorMessage`，`screenState` 變成失敗，再換一次分支，`.task` 再次觸發，回到第 1 步。

當時以 TCA `_printChanges(.actionLabels)` 觀察到 `dashboard(.view(.task))` 反覆出現 (次數與間隔沒有記錄)。

**等待 `finish()` 時取消共用讀取**：總覽與分析的 `.task` 是 `await store.send(.view(.task)).finish()`。依 Apple `task` 文件，view 消失或身分改變時 SwiftUI 會取消尚未完成的工作；TCA 1.26.2 的 `StoreTask.finish()` 被取消時會取消這次送出所衍生的 effect，`Send` 在已取消時直接丟棄 action。一次 `send` 衍生的 effect 與 effect 內再送出 action 所產生的 task 都併入同一份清單 (TCA 1.26.2 `Core.swift`，主對話與架構審查都已讀原始碼確認)，所以讀取若由這個 `.task` 經 Root 發起，取消會讓 `loadResponse` 遺失，`OrdersLoadFeature` 的 `isLoading` 留在 `true`，之後的請求全被擋掉，所有畫面停在載入中且重試無效。`.claude/rules/ios-navigation.md` 已規定清單的 `.task` 只送出、不等待 `finish()`，總覽與分析違反這條；客戶頁 (`CustomersView`) 也等待 `finish()` 並經 Root 觸發同一條讀取。TCA 這一半已由原始碼證實，SwiftUI 何時取消的時序尚未實測。

`InsightsView` 的寫法與總覽相同 (同樣的 `Group` 與 `finish()`，`view(.task)` 同樣送 `delegate(.refresh)`)。`CampaignListView` 把 `.task` 掛在依 `loadState` 切換的 `@ViewBuilder` `switch` 上 (沒有 `Group`，只送出、不等待 `finish()`)；官方文件沒有保證一般條件內容會把修飾器分給各分支，是否會重跑由重現測試確認。

## Proposed Solution

- 總覽與分析的 `.task` 移到不隨載入狀態換分支的 `NavigationStack` 這一層並改成只送出、不等待 `finish()`；客戶頁的 `.task` 改成只送出。共用讀取只在畫面出現時發起一次，離開畫面也不取消。重試仍由重試鍵觸發。
- 開團清單一律以單一容器包住依載入狀態切換的內容後再掛 `.task`，重現測試只作實測紀錄。
- 訂單清單抽出共用的失敗列 (失敗訊息與重試鍵，接上既有 `view(.retryTapped)`)，清單內容改由載入狀態單一推導，失敗時不顯示空狀態。
- UI 測試支援層：訂單清單與分析頁的載入 identifier 具名化，`RootNavigationScreen` 的分析頁就緒判斷納入失敗重試鍵，新增「訂單讀取延遲後每次都失敗」的啟動情境 (只在 `DEBUG` 的 UI 測試替身內)。
- 新增測試：切換分頁迴圈與離開發起讀取 (`Tests/Navigation/`)、訂單清單失敗與重試 (`Tests/Orders/`)、開團清單 (`Tests/Campaigns/`)，以及把 TCA 取消語意固定成確定性證據的 `RootFeatureLoadCancellationTests`。
- 新增原始碼掃描守門：Features 的 view 在 `.task` 內等待 `finish()` 時必須寫 `// task-finish-exempt: <理由>`，既有保留的呼叫點逐一寫明理由。
- `.claude/rules/ios-navigation.md` 把 `.task` 掛載位置、只送出與等待 `finish()` 的時機、載入中旗標去重的教訓合併成一條規則，並列 `RootView` 為已知例外。
- `RootView` 根層 `.task`、匯率與報價頁、客戶頁載入狀態等相關問題不在本 change 修，記在 design 的「後續待辦」，archive 時開成後續項目。

## Success Criteria

- 以訂單每次都讀取失敗的情境啟動，依「訂單 → 更多 → 訂單 → 總覽 → 分析」切換分頁後，三頁各自穩定顯示失敗訊息與重試鍵；訂單清單不顯示空狀態。
- 以訂單讀取延遲後失敗的情境，在第一次失敗後由分析分頁或客戶頁發起新讀取並在讀取中離開，訂單清單最後顯示失敗訊息，不停在載入中。
- 訂單清單按重試鍵會重新讀取一次，再次失敗時回到失敗訊息且不自動重試。
- 兩組訂單重現案例修改前在 iPhone 17 連跑 3 次都因目標缺陷失敗，修改後所有新案例在 iPhone 17 (iOS 26.5) 與 iPad Air 11-inch (M4) (iPadOS 27.0) 都通過；開團案例記錄修改前結果，修改後兩台都通過。
- 掃描守門在 repo 上通過，刪掉任一豁免標記時轉紅。
- 完整單元回歸與完整 UI 回歸 0 失敗，既有 snapshot 不重錄。

## Impact

- Affected specs: `honest-state-feedback` (修改 requirement「Load failure is surfaced with a reason and a recovery path」：載入中與失敗互換本身不得觸發新的載入，共用資料的讀取結果不因發起畫面離開而遺失；新增訂單清單失敗不顯示空狀態、切換分頁與離開發起讀取的情境)
- Affected code:
  - Modified:
    - apps/ios/BuyLedger/Features/Dashboard/Presentation/Root/Views/DashboardView.swift
    - apps/ios/BuyLedger/Features/Insights/Presentation/Root/Views/InsightsView.swift
    - apps/ios/BuyLedger/Features/Customers/Presentation/Root/CustomersView.swift
    - apps/ios/BuyLedger/Features/Campaigns/Presentation/CampaignList/Views/CampaignListView.swift
    - apps/ios/BuyLedger/Features/Orders/Presentation/OrderList/Views/OrdersCompactListView.swift
    - apps/ios/BuyLedger/Features/Orders/Presentation/Root/Views/OrdersRegularListColumn.swift
    - apps/ios/BuyLedgerAccessibilityIDs/BLAccessibilityID+Orders.swift
    - apps/ios/BuyLedgerAccessibilityIDs/BLAccessibilityID+Insights.swift
    - apps/ios/BuyLedger/App/Testing/Configuration/BLUITestLoadFailure.swift
    - apps/ios/BuyLedger/App/Testing/Overrides/DependencyValues+BLUITestOverrides.swift
    - apps/ios/BuyLedgerUITests/Support/LaunchOptions.swift
    - apps/ios/BuyLedgerUITests/Screens/App/RootNavigationScreen.swift
    - 7 個保留 `finish()` 的 view，只加豁免註解：apps/ios/BuyLedger/Features/App/Presentation/Root/RootView.swift、apps/ios/BuyLedger/Features/AISummary/Presentation/Root/AISummaryView.swift、apps/ios/BuyLedger/Features/Campaigns/Presentation/Root/CampaignView.swift、apps/ios/BuyLedger/Features/FX/Presentation/Root/FxView.swift、apps/ios/BuyLedger/Features/Quote/Presentation/Root/QuoteView.swift、apps/ios/BuyLedger/Features/Lookups/Presentation/Root/Views/LookupManagementView.swift、apps/ios/BuyLedger/Features/Settings/Presentation/Root/SettingsView.swift
    - .claude/rules/ios-navigation.md
  - New:
    - apps/ios/BuyLedger/Features/Orders/Presentation/OrderList/Views/OrdersListLoadFailureRow.swift
    - apps/ios/BuyLedgerUITests/Tests/Navigation/LoadFailureReloadLoopTests.swift
    - apps/ios/BuyLedgerUITests/Tests/Orders/OrderListLoadFailureTests.swift
    - apps/ios/BuyLedgerUITests/Tests/Campaigns/CampaignListLoadFailureLoopTests.swift
    - apps/ios/BuyLedgerUITests/Support/XCTestCase+LoadStateSampling.swift
    - apps/ios/BuyLedgerTests/Features/App/RootFeatureLoadCancellationTests.swift
    - apps/ios/BuyLedgerTests/Guards/TaskFinishConventionScanTests.swift
  - Removed: none
