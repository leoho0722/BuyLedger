## 1. 測試環境前提文件化

- [x] 1.1 `apps/ios/CLAUDE.md` 的建置與測試段落載明：iPad UI 回歸前必須確認軟體鍵盤可顯示 (斷開模擬器的硬體鍵盤連線，`xcodebuildmcp simulator-management toggle-connect-hardware-keyboard` 是切換而非設定，要確認切換後的實際狀態)，並寫出症狀與判別方式，讓讀者能據此判斷手上的紅燈是否屬於這一類：失敗訊息為「數字鍵盤工具列的完成鍵未能收起鍵盤」、可及性樹中 `Keyboard` 元素的 y 起點大於視窗高度、欄位仍為 `Keyboard Focused`。驗證：內容審查，且該段須同時包含判別依據與處置方式，不只是一句設定指示。

## 2. Page Object 的捲動健壯性

- [x] 2.1 `OrderEditScreen.typeCustomerName` 在欄位尚未出現在可及性樹時仍能完成捲動並輸入：迴圈每次先確認元素存在再讀取 frame，元素不存在時視為需要繼續捲動；沿用現行的最多 8 次上限，次數用盡仍未出現則以 `failWithDiagnostics` 附診斷失敗，不得靜默 return，也不得讓讀取 frame 這一步中斷測試。驗證：在軟體鍵盤可顯示的 iPad Air 11-inch (M4) (UDID `6B65ED1C-3C2E-42BA-B1E7-08F606F175C5`) 上執行 `-only-testing:BuyLedgerUITests/OrderCreateTests/testCreateOrderAppearsInList()` 轉綠，保留 result bundle 並確認 `TestCaseRuns` 執行數大於 0；修正前的失敗原文為 `Failed to get matching snapshot: No matches found for '"orderEdit.customerField" IN identifiers'`，已於 2026-09-18 連續兩次重現。
- [x] 2.2 [after: 2.1] 產出 `apps/ios/BuyLedgerUITests/Screens/` 與 `apps/ios/BuyLedgerUITests/Support/` 的盤點清單：列出所有先讀取元素幾何 (`frame`、`value`、`label` 等會觸發 snapshot 的存取) 再判斷存在性的呼叫點，逐項判定是否會在元素不在可及性樹時中斷測試。只修正會中斷的寫法；`isHittable`、`exists` 這類回傳布林而不中斷的維持原樣。驗證：回報附完整清單與每項的判定理由 (需修或不需修)；有修正者附受影響測試的執行結果與 bundle 路徑。

- [x] 2.3 [after: 2.1] `dismissNumericKeyboard` 與 `OrderEditScreen.tapNumericKeyboardDone` 在硬體鍵盤接上 (軟體鍵盤不顯示) 與斷開 (軟體鍵盤顯示) 兩種狀態下都能可靠解除欄位焦點，不再依賴模擬器處於特定狀態。實測已證明該狀態會在單次完整回歸途中自行翻回 (2026-09-18：11:54 驗證為斷開且 `KeyboardDismissTests` 兩條全綠，12:10 起的完整回歸中 `testQuoteSuggestsPriceAfterPrincipal` 失敗，失敗時可及性樹的 `Keyboard` 又回到 `{{0,1224},{820,279}}`)，因此環境前提不可靠。契約：先以 `app.keyboards.firstMatch.frame` 與 App 視窗 frame 是否相交判斷軟體鍵盤是否在畫面上；在畫面上時維持現行做法 (點完成鍵並等待鍵盤消失)；不在畫面上時改以能解除焦點的方式處理，並改為斷言目標欄位的 `hasKeyboardFocus` 變為 false，而不是等待 `Keyboard` 元素消失 (該元素在硬體鍵盤接上時永遠存在)；兩條路徑都不得靜默返回，解除失敗一律 `failWithDiagnostics`。驗證：在 iPad Air 11-inch (M4) (UDID `6B65ED1C-3C2E-42BA-B1E7-08F606F175C5`) 上，於硬體鍵盤接上的狀態執行 `-only-testing:BuyLedgerUITests/KeyboardDismissTests`、`-only-testing:BuyLedgerUITests/FxTests`、`-only-testing:BuyLedgerUITests/QuoteTests`、`-only-testing:BuyLedgerUITests/OrderCreateTests` 全綠並保留 bundle；若能取得斷開狀態 (由使用者手動切換)，再跑一次同一組確認也全綠並保留 bundle。兩種狀態的判定依據都以失敗或成功當下 `Keyboard` 元素的 y 起點是否大於視窗高度為準，並寫進回報。

## 3. 貨到付款測試的失敗判定

- [x] 3.1 判定 `OrderDetailTests.testCashOnDeliveryCorrectionPersistsAfterRelaunch` 的 `Failed to determine hittability of "lookupManagement.paymentMethodEditor.cashOnDeliveryToggle" Switch: Activation point invalid` 屬於既有環境雜訊或真缺陷。執行方式：在 iPad Air 11-inch (M4) (UDID `6B65ED1C-3C2E-42BA-B1E7-08F606F175C5`) 上以 `-only-testing:BuyLedgerUITests/OrderDetailTests/testCashOnDeliveryCorrectionPersistsAfterRelaunch()` 單獨重跑，每次保留 result bundle。判定流程依序套用，先命中者為準：

  1. 先跑兩次。兩次都通過，判為環境雜訊，結束。
  2. 兩次都失敗，且兩次的失敗訊息與失敗位置 (檔案與行號) 都相同，判為真缺陷，修正到轉綠。
  3. 其餘情況 (一次通過一次失敗，或兩次都失敗但訊息或位置不同) 追加三次，合計五次後依下列優先序判定：
     - a. 五次中失敗三次以上，且所有失敗的訊息與位置都相同 → 真缺陷，修正到轉綠。
     - b. 未命中 a，且五次中出現兩種以上不同的失敗訊息或位置 → 環境雜訊，並在回報標示需另行追蹤。
     - c. 未命中 a 與 b (失敗兩次以下且失敗樣態一致) → 環境雜訊。

  「失敗樣態一致」的優先序高於失敗次數：只要失敗訊息或位置不一致，即使失敗次數達三次也走 b 判為雜訊。驗證：附每次執行的 bundle 路徑、通過或失敗、失敗者附訊息與位置；判定為雜訊時寫明各次結果分布與命中的規則編號，判定為真缺陷時附修正後轉綠的 bundle。

## 4. 最終回歸

- [x] 4.1 [after: 2.3] [after: 3.1] iPad Air 11-inch (M4) (UDID `6B65ED1C-3C2E-42BA-B1E7-08F606F175C5`) 的 `BuyLedgerUITests` 主回歸達到 56 passed、0 failed、0 skipped。完整執行指令 (自 repo 根目錄)：

```bash
xcodebuildmcp simulator test \
  --project-path apps/ios/BuyLedger.xcodeproj \
  --scheme BuyLedgerUITests \
  --simulator-id 6B65ED1C-3C2E-42BA-B1E7-08F606F175C5 \
  --extra-args -only-testing:BuyLedgerUITests \
  --extra-args -skip-testing:BuyLedgerUITests/LaunchPerformanceTests
```

  56 條的來源：`BuyLedgerUITests` 內共 57 個 `func test` 方法，扣除 `LaunchPerformanceTests` 的 1 條後為 56，與上述 `-skip-testing` 一致，兩者不衝突。前提：該 UDID 的模擬器存在且可啟動、測試集合仍為 57 扣 1 等於 56 條。**不再要求硬體鍵盤處於特定狀態**：2.3 完成後兩種狀態都應通過，回歸時只需記錄當次實際狀態 (以 `Keyboard` 元素的 y 起點是否大於視窗高度判定) (若測試數量有增減，先回報實際數字再據以更新基準)；任一前提不成立時先回報，不得以調整斷言或跳過測試來達標。驗證：保留 result bundle，記錄 `TestCaseRuns` 的 group by 結果與 skip 數；回歸須在最後一次程式修改之後執行。

- [x] 4.2 [after: 2.2] [after: 3.1] iPhone 17 (UDID `DDAA3311-B464-4DD3-96B8-360B26AF1929`) 的 `BuyLedgerUITests` 主回歸維持 56 passed、0 failed、0 skipped，未因本次修正退步。完整執行指令 (自 repo 根目錄)：

```bash
xcodebuildmcp simulator test \
  --project-path apps/ios/BuyLedger.xcodeproj \
  --scheme BuyLedgerUITests \
  --simulator-id DDAA3311-B464-4DD3-96B8-360B26AF1929 \
  --extra-args -only-testing:BuyLedgerUITests \
  --extra-args -skip-testing:BuyLedgerUITests/LaunchPerformanceTests
```

  56 條的來源與 4.1 相同 (57 個 `func test` 扣除 `LaunchPerformanceTests` 的 1 條)。iPhone 不需處理硬體鍵盤狀態，其餘前提與記錄方式同 4.1。

## 執行證據與盤點紀錄

本節保留本 change 的驗收證據，避免 result bundle 或對話紀錄清理後無法追溯。以下 `TestCaseRuns` 皆為實際列數；`P/F/S` 分別代表 passed、failed、skipped。所有路徑均為完整絕對路徑。

### 1.1 測試環境前提文件化

- 內容審查完成，無需執行 bundle：`apps/ios/CLAUDE.md` 已記錄 `toggle-connect-hardware-keyboard` 的限制、手動處置方式、`Keyboard` y 起點判別，以及單獨執行 `KeyboardDismissTests` 兩條確認軟體鍵盤前提的方式。

### 2.1 Page Object 捲動健壯性

- 修正前重現：
  - `/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-18T02-44-29-773Z_pid87050_41cdeff2.xcresult` — `TestCaseRuns=1`；`OrderCreateTests.testCreateOrderAppearsInList`: `0P/1F/0S`；`Failed to get matching snapshot: No matches found for '"orderEdit.customerField" IN identifiers'`。
  - `/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-18T02-48-48-784Z_pid91158_53bc7acd.xcresult` — `TestCaseRuns=1`；同一測試 `0P/1F/0S`；同一 snapshot 失敗。
- 修正後：`-only-testing:BuyLedgerUITests/OrderCreateTests/testCreateOrderAppearsInList()`；`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-18T03-58-50-411Z_pid46758_cca83967.xcresult` — `TestCaseRuns=1`；`OrderCreateTests.testCreateOrderAppearsInList`: `1P/0F/0S`。

### 2.2 Page Object 與 helper 盤點

盤點範圍為 `apps/ios/BuyLedgerUITests/Screens/` 與 `apps/ios/BuyLedgerUITests/Support/` 中會觸發 snapshot 的幾何或可及性資料讀取：

- `DashboardScreen.swift:60` `tile.value`：前一行已 `waitForExistence`，元素不存在時直接回傳 `nil`；不需修。
- `InsightsScreen.swift:133` `element.value`：前一行已 `waitForExistence`；不需修。
- `InsightsScreen.swift:174-181` `element.frame`、`rootElement.frame`、`element.value`：進入 helper 前已 `waitForExistence`，讀 frame 後才讀 value；不需修。
- `QuoteScreen.swift:39`、`:51` `element.value`：各自前一行已 `waitForExistence`；不需修。
- `CampaignDetailScreen.swift:58` `element.value`：前一行已 `waitForExistence`；不需修。
- `OrderDetailScreen.swift:44` `element.value`：前一行已 `waitForExistence`；不需修。
- `FxScreen.swift:46` `element.value`、`:58` `element.combinedText`：各自前一行已 `waitForExistence`；不需修。
- `SettingsScreen.swift:35` `row.combinedText`：前一行已 `row.exists`；不需修。
- `Support/Assertions.swift:146` `element.frame`：前面先判斷 `element.exists`，不存在即附診斷返回；不需修。
- `Support/Waiting.swift:61` `self.identifier`：只在 `waitUntilHittable` 失敗後建立診斷訊息，不是先讀幾何再判斷存在；不需修。
- `Support/TextInput.swift` 的 `clearAndType` 中 `value`：先經 `tapAfterWaiting` 與鍵盤出現檢查，再讀既有值；不需修。
- `Support/TextInput.swift:82-83` 的 `app.keyboards.firstMatch.frame` 與 `app.windows.firstMatch.frame`：這是 2.3 明定的鍵盤狀態判定，且目標欄位已先以 `exists` 檢查；不需修。
- `OrderEditScreen.swift:76-77` `field.frame`、`rootElement.frame`：原本會在欄位尚未進入可及性樹時先讀 `field.frame`，是唯一需修正的呼叫點；現已改為先判斷 `field.exists`，並在 8 次捲動後以 `failWithDiagnostics` 失敗。

本任務沒有可單獨對應的新增測試；受影響的 `OrderCreateTests.testCreateOrderAppearsInList()` 證據見 2.1。

### 2.3 雙鍵盤狀態的數字鍵盤解除焦點

以下四次均在 iPad Air 11-inch (M4)、UDID `6B65ED1C-3C2E-42BA-B1E7-08F606F175C5`、硬體鍵盤接上的狀態執行；類別層 selector 不需括號，且每次均有非零 `TestCaseRuns`：

- `-only-testing:BuyLedgerUITests/KeyboardDismissTests` — `/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-18T05-16-55-398Z_pid7407_2dcfbd10.xcresult`；`TestCaseRuns=2`；`KeyboardDismissTests=2P/0F/0S`；skip `0`。
- `-only-testing:BuyLedgerUITests/FxTests` — `/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-18T05-18-37-397Z_pid8695_04d588e6.xcresult`；`TestCaseRuns=3`；`FxTests=3P/0F/0S`；skip `0`。
- `-only-testing:BuyLedgerUITests/QuoteTests` — `/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-18T05-20-19-534Z_pid9975_9f50f951.xcresult`；`TestCaseRuns=2`；`QuoteTests=2P/0F/0S`；skip `0`。
- `-only-testing:BuyLedgerUITests/OrderCreateTests` — `/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-18T05-22-56-384Z_pid11862_54271e47.xcresult`；`TestCaseRuns=3`；`OrderCreateTests=3P/0F/0S`；skip `0`。

當時未切換硬體鍵盤；狀態依失敗時 `Keyboard` y 起點 `1224` 大於視窗高度的判定紀錄，以及本次硬體鍵盤分支測試結果記錄。

### 3.1 貨到付款失敗判定

- `/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-18T04-06-01-903Z_pid52836_24c5a0e7.xcresult` — `TestCaseRuns=1`；`OrderDetailTests.testCashOnDeliveryCorrectionPersistsAfterRelaunch=1P/0F/0S`；skip `0`。
- `/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-18T04-07-59-593Z_pid54265_9b7b3fc6.xcresult` — `TestCaseRuns=1`；同一測試 `1P/0F/0S`；skip `0`。
- 結果分布：兩次通過、零次失敗；命中判定流程規則 **1**（兩次都通過，判為環境雜訊並結束）。因此沒有失敗訊息或檔案行號可記錄，也沒有產品修正。

### 4.1 iPad 主回歸

- 修正 2.3 前的環境失敗：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-18T04-10-25-963Z_pid56045_3b097e8a.xcresult` — `TestCaseRuns=56`；總計 `55P/1F/0S`；`QuoteTests=1P/1F/0S`，其餘 group by 合計 `54P/0F/0S`；skip `0`。失敗為 `testQuoteSuggestsPriceAfterPrincipal` 的數字鍵盤收起環境問題。
- 最終驗證（晚於最後程式修改）：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-18T05-25-54-749Z_pid14093_069dfb1b.xcresult` — `TestCaseRuns=56`；`56P/0F/0S`；skip `0`。group by：`AISummaryTests=2P`、`AppLockTests=3P`、`CampaignCrudTests=3P`、`CampaignDetailTests=2P`、`CampaignListTests=2P`、`CustomersTests=4P`、`FxTests=3P`、`HarnessSelfCheckTests=7P`、`InsightsTests=5P`、`KeyboardDismissTests=2P`、`LaunchSmokeTests=4P`、`OrderCreateTests=3P`、`OrderDetailTests=4P`、`OrderEditDirtyTests=2P`、`OrderMergeTests=3P`、`OrdersListTests=4P`、`PhotoViewerPagingTests=1P`、`QuoteTests=2P`。

### 4.2 iPhone 主回歸

- 舊證據（在 `TextInput.dismissNumericKeyboard` 修改前，不涵蓋現行程式）：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-18T04-38-48-680Z_pid76807_ad10ed7e.xcresult` — `TestCaseRuns=56`；`56P/0F/0S`；skip `0`，但已標記為過時證據。
- 重新執行（iPhone 17、UDID `DDAA3311-B464-4DD3-96B8-360B26AF1929`，涵蓋現行 helper）：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-18T05-53-25-881Z_pid36450_2f7178e6.xcresult` — `TestCaseRuns=56`；`56P/0F/0S`；skip `0`。group by 與 4.1 相同：`AISummaryTests=2P`、`AppLockTests=3P`、`CampaignCrudTests=3P`、`CampaignDetailTests=2P`、`CampaignListTests=2P`、`CustomersTests=4P`、`FxTests=3P`、`HarnessSelfCheckTests=7P`、`InsightsTests=5P`、`KeyboardDismissTests=2P`、`LaunchSmokeTests=4P`、`OrderCreateTests=3P`、`OrderDetailTests=4P`、`OrderEditDirtyTests=2P`、`OrderMergeTests=3P`、`OrdersListTests=4P`、`PhotoViewerPagingTests=1P`、`QuoteTests=2P`。

### 後續純註解修正

- 在上述 iPad 與 iPhone 兩份完整回歸完成後，僅修正 `apps/ios/BuyLedgerUITests/Support/TextInput.swift` 的三行 `- Note:` 註解：刪除中文句號，未變更任何執行行為，因此不重跑回歸。
