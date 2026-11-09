<!-- 平行分工 (主對話依 2026-11-08 `hc ls` 代選，開工時依當下 `hc ls` 重新確認；審查依根目錄 `CLAUDE.md`，由審查用終端 (例如右側 Codex) 與主對話同步審查)

| 平行組 | 任務 (同組依序) | 改動檔案 | 實作 | 唯讀審查 |
| --- | --- | --- | --- | --- |
| A | 1.1 → 1.7 → 2.3 | `BLAccessibilityID+Orders.swift`、`BLAccessibilityID+Insights.swift`、`RootNavigationScreen.swift`、`OrdersCompactListView.swift`、`OrdersRegularListColumn.swift`、新檔 `OrdersListLoadFailureRow.swift`、新檔 `Tests/Orders/OrderListLoadFailureTests.swift` | claude-sonnet-xhigh-impl | 審查用終端＋主對話 |
| B | 1.2 → 1.3 | `BLUITestLoadFailure.swift`、`DependencyValues+BLUITestOverrides.swift`、`LaunchOptions.swift`；新檔 `BuyLedgerTests/Features/App/RootFeatureLoadCancellationTests.swift` | claude-haiku-max-impl | 審查用終端＋主對話 |
| C | 1.4 → 1.5 → 1.6 | 新檔 `Tests/Navigation/LoadFailureReloadLoopTests.swift`、新檔 `Tests/Campaigns/CampaignListLoadFailureLoopTests.swift` | codex-sol-xhigh-impl | 審查用終端＋主對話 |
| D | 2.1 → 2.2 → 2.4 | `DashboardView.swift`、`InsightsView.swift`、`CustomersView.swift`、`CampaignListView.swift`；新檔 `BuyLedgerTests/Guards/TaskFinishConventionScanTests.swift`；7 個保留 `finish()` 的 view 的豁免註解 (`RootView`、`AISummaryView`、`CampaignView`、`FxView`、`QuoteView`、`LookupManagementView`、`SettingsView`) | codex-luna-max-impl | 審查用終端＋主對話 |
| E | 2.5 | `.claude/rules/ios-navigation.md` | 主對話 | 審查用終端＋主對話 |

- 可立即開工：1.1、1.2、2.5。2.1、2.2、2.3 都要等對應的重現測試在修改前跑完 (先紅後綠的流程依賴，修正不能先落在工作樹)；2.4 要等 2.1 拿掉三處 `finish()`，守門才會在 repo 上通過。
- `design.md` 由主對話在 1.4 至 1.7、3.1 記錄實測結果，是文件熱點，agent 不改。
- agent 只改檔案；建置、測試、勾選 task 由主對話依序執行，同一時間只跑一組測試。每次派工前後比對 `git status --short`。
-->

## 1. 測試支援與重現

- [x] 1.1 依「UI 測試支援層與延遲失敗情境」與「訂單清單的失敗態由載入狀態單一推導並附重試鍵」新增 `BLAccessibilityID.Orders.listLoadFailure`、`listLoading`、`listLoadFailureRetryButton` 與 `BLAccessibilityID.Insights.loading`、`loadFailure`、`loadFailureRetryButton` (值與 `InsightsView` 現有內聯 key 相同)；把訂單的前兩個掛在 `OrdersCompactListView`、`OrdersRegularListColumn` 現有的失敗 `Text` 與載入中 `ProgressView` 本身 (列修飾之前)；`RootNavigationScreen.isForegroundDestinationReady(for: .insights)` 納入 `Insights.loadFailureRetryButton`。畫面外觀不變。驗證：建置通過；`SnapshotOrdersTests`、`SnapshotOrdersBaselineTests` 不重錄即通過；`InsightsTests`、`InsightsLayoutSmokeTests` 在 iPhone 17 通過；以 `mobilebuildmcp ui-automation snapshot-ui` 在 `-BLUITestLoadFailure orders` 啟動後看到訂單清單失敗訊息帶 `orders.list.loadFailure`。
- [x] 1.2 依「UI 測試支援層與延遲失敗情境」新增 `BLUITestLoadFailure.ordersDelayed` 與 `LaunchOptions.LoadFailure.ordersDelayed` (`rawValue` 對齊)，替身讓訂單每次讀取先以 `Task.sleep` 等待後失敗 (初始估計 3 秒)，被取消時仍回傳同樣的失敗；只在 `DEBUG`。驗證：建置通過；以 `-BLUITestLoadFailure ordersDelayed` 啟動後用 `ui-automation` 確認總覽先顯示載入中、約 3 秒後顯示失敗畫面；`DashboardLaunchLoadingTests` 通過。
- [x] 1.3 [after: 1.2，同一實作者依序] 依「取消機制以 TestStore 固定為確定性證據」新增 `RootFeatureLoadCancellationTests`：`fetchOrders` 停在可控的 continuation，送出 `.insights(.view(.task))` 後取消回傳的 task，斷言訂單載入的 `isLoading` 維持 `true`、下一次 `refresh` 不再發起讀取；doc comment 寫明是 TCA 取消語意的特性測試。驗證：iPhone 17 單元測試通過且實際執行數大於 0。
- [x] 1.4 [after: 1.1，測試要用新識別碼與分析頁就緒判斷] 依「重現測試依關注點分檔」新增 `LoadFailureReloadLoopTests` 的切換分頁迴圈案例，對應 spec requirement「Load failure is surfaced with a reason and a recovery path」的情境「Switching tabs after a load failure does not start a reload loop」：訂單、總覽、分析三頁各自先等失敗第一次出現，再穩定取樣。驗證：修改前在 iPhone 17 (iOS 26.5) 連跑 3 次都因目標缺陷失敗，記錄每次失敗的斷言、型態 (斷言或逾時) 與畫面狀態；另以 `_printChanges(.actionLabels)` 暫時觀察啟動後總覽在前景時是否已出現迴圈、隱藏分頁是否仍收到 `view(.task)`，觀察後還原，結果寫進 design。時好時壞或修改前就通過時停下回報使用者。
- [x] 1.5 [after: 1.2、1.4，要用延遲失敗情境且同一測試檔] 依「重現測試依關注點分檔」新增離開發起讀取的案例，對應情境「Leaving a screen during a shared load keeps the load result」：`LaunchOptions(loadFailure: .ordersDelayed)`，第一次失敗出現後由分析分頁、另一案例由客戶頁發起新讀取，切到訂單分頁後立刻斷言 `Orders.listLoading` 存在，再斷言延遲後轉成 `listLoadFailure` 並穩定取樣。驗證：修改前在 iPhone 17 連跑 3 次都因卡在載入中而失敗，結果與失敗型態寫進 design；時好時壞或通過時停下回報使用者。
- [x] 1.6 [after: 1.1，要用分析頁就緒判斷] 依「重現測試依關注點分檔」與「開團清單一律以單一容器掛 .task」新增 `CampaignListLoadFailureLoopTests`：`LaunchOptions(loadFailure: .campaigns)`，在開團分頁與其他分頁之間來回切換，等 `Campaigns.listLoadFailure` 出現後穩定取樣。驗證：修改前在 iPhone 17 與 iPad Air 11-inch (M4) (iPadOS 27.0) 各連跑 3 次，結果寫進 design 的「開團清單一律以單一容器掛 .task」(只作實測紀錄，不決定是否修正)。
- [x] 1.7 [after: 1.1、1.2，要用新識別碼與延遲失敗情境] 依「重現測試依關注點分檔」新增 `OrderListLoadFailureTests`，對應情境「Order list failure is not shown as an empty result」：`LaunchOptions(loadFailure: .ordersDelayed)`，訂單清單失敗後斷言 `listEmptyState` 不存在；按 `listLoadFailureRetryButton` 後斷言 `listLoading` 出現再回到 `listLoadFailure`，之後穩定取樣。驗證：修改前在 iPhone 17 因空狀態存在、找不到重試鍵而失敗 (先紅後綠的「紅」)。

## 2. 修正與守門

- [x] 2.1 [after: 1.3、1.4、1.5，修改前要先跑完兩組訂單重現案例與特性測試] 依「載入用的 .task 掛在不隨載入狀態換分支的容器上」與「觸發共用讀取的 .task 只送出不等待 finish」：`DashboardView`、`InsightsView` 的 `.task` 從 `content` 移到 `NavigationStack` 這一層並改成 `store.send(.view(.task))`，`InsightsView` 的載入 identifier 改引用 `BLAccessibilityID.Insights` 的具名常數；`CustomersView` 的 `.task` 改成只送出。驗證：切換分頁迴圈與離開發起讀取兩組案例在 iPhone 17 與 iPad Air 通過；主對話變異確認只還原分析頁、總覽或客戶頁其中一處時對應案例失敗，確認後還原；`DashboardLaunchLoadingTests`、`InsightsLaunchLoadingTests`、`CustomersTests` 不改預期即通過；`SnapshotDashboardTests`、`SnapshotInsightsTests`、`SnapshotCustomersTests` 不重錄即通過。
- [x] 2.2 [after: 1.6、2.1，修改前要先記錄開團案例，且同一實作者依序] 依「開團清單一律以單一容器掛 .task」在 `CampaignListView.body` 以單一容器包住 `content` 後再掛 `.task`、`.rootNavigationTitle` 與 `.toolbar`。驗證：開團案例在 iPhone 17 與 iPad Air 通過；`CampaignFlowTests` 與 `SnapshotCampaignsTests` 不改預期即通過。
- [x] 2.3 [after: 1.1、1.7，同改訂單清單兩個 view，且修改前要先跑完訂單清單案例] 依「訂單清單的失敗態由載入狀態單一推導並附重試鍵」抽出 `OrdersListLoadFailureRow` (失敗訊息與重試鍵，水平內距由呼叫端傳入)，`OrdersCompactListView`、`OrdersRegularListColumn` 改用它，清單內容改由 `store.loadState` 單一推導 (`.loading` 載入中、`.failed` 只有失敗列、`.loaded` 才是空狀態或訂單列)。驗證：`OrderListLoadFailureTests` 在 iPhone 17 與 iPad Air 通過；`SnapshotOrdersTests`、`SnapshotOrdersBaselineTests`、`SnapshotOrderFilterEmptyStatesTests` 不重錄即通過 (有變化時停下請使用者裁決)；`OrdersListTests`、`OrderListFeature` 的 `view(.retryTapped)` 既有測試通過。
- [x] 2.4 [after: 2.1，三處 finish 移除後守門才會在 repo 上通過；同一實作者依序] 依「.task 等待 finish 的掃描守門」新增 `TaskFinishConventionScanTests`，並在 7 個保留 `finish()` 的 view 寫上 `// task-finish-exempt: <理由>`。驗證：合成樣本 (無標記、理由空白判違規；有理由、只送出判合法) 判讀正確；守門在 repo 上通過；主對話變異確認刪掉任一既有標記時轉紅後還原；寫成「已知風險，待後續 change」的項目列在 design 的「後續待辦」。
- [x] 2.5 依「規則寫進 ios-navigation.md」把 `.claude/rules/ios-navigation.md` 中「清單的 `.task` 不等待 `finish()`」與「長效 effect 以 cancel id 管理」兩處合併成一條獨立主 bullet，寫明掛載位置、只送出、何時才等待並加豁免標記、載入中旗標去重的教訓與 `RootView` 已知例外；sheet 段原條目只留情境並指向新 bullet。驗證：對照根目錄 `CLAUDE.md` 文件同步鐵則逐列檢查，內容只寫現行規則與理由，不寫事件經過，沿用該檔縮排。

## 3. 驗收與審查

- [x] 3.1 [after: 2.1、2.2、2.3、2.4、2.5，驗收需要全部修改完成] 依 spec requirement「Load failure is surfaced with a reason and a recovery path」實測：以 `mobilebuildmcp ui-automation` 在 iPhone 17 模擬器依 proposal 的重現步驟操作，訂單清單顯示失敗訊息與重試鍵且沒有空狀態、總覽與分析顯示失敗畫面與重試鍵，按重試後再次失敗仍停在失敗畫面；跑完整單元回歸 (iPhone 17 iOS 26.5)。驗證：實測結果寫進 design；單元回歸 0 失敗且實際執行數大於 0，snapshot 未重錄。
- [x] 3.2 [after: 3.1，審查需要先取得實測與回歸結果] 審查：依當下 `hc ls` 挑選未參與實作的審查者 (優先用審查用終端；沒有時改派未參與實作的 agent；都沒有時由主對話獨自審查並記錄)，審查者唯讀審查全部變更並逐檔逐條做 style 閘門，主對話同步審查架構、正確性、測試與風格，結論合併取捨並記錄決策來源；審查前後比對檔案雜湊確認審查者沒有改檔。驗證：各份審查結論合併後的修正全部處理或記錄取捨。
- [x] 3.3 [after: 3.2，審查修正後再驗證] 審查修正後跑完整單元回歸 (iPhone 17 iOS 26.5) 與完整 UI 回歸 (iPhone 17 (iOS 26.5) 與 iPad Air 11-inch (M4) (iPadOS 27.0) 模擬器，排除效能測試，iPad 先單獨跑 `KeyboardDismissTests` 確認不在硬體鍵盤狀態)：總覽是幾乎所有 UI 測試啟動後的第一個分頁，`.task` 位置與等待方式改變會影響它們的啟動流程，所以跑完整回歸 (主對話代選)。驗證：0 失敗 (逾時類失敗單獨重跑最多兩次並記錄)，三個新 UI 測試檔在兩台都通過；archive 前把 design「後續待辦」開成後續項目。
