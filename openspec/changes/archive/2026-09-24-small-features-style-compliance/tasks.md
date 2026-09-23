## 0. 開工前基準

- [x] 0.1 確認逐檔待修明細與現況相符：`findings.md` 已載入 23 個檔案的 491 筆項目，逐檔打開原始碼抽驗每個檔案至少兩筆 (不足兩筆的檔案全驗)，確認違規現在仍然成立；第 1、2 步已修掉的項目 (幣別顯示 3 筆、客戶頭像尺寸 1 筆) 與預填結論逐筆核對。驗證：23 個檔案各有抽驗記錄寫在本 task 下方，不成立的項目在 `findings.md` 就地寫明原因

  抽驗記錄（2026-09-22）：23 個檔案均以現行原始碼核對；`H1` 與預填項目只核對、不改寫，抽驗項目如下
  - `Features/AISummary/AISummaryFeature.swift`：`H1 L1` 已預填；`MK4 L40` 成立
  - `Features/AISummary/AISummaryView.swift`：`H1 L1` 已預填；`MK1 L15` 成立
  - `Features/AISummary/OllamaClient.swift`：`H1 L1` 已預填；`S·Client 放在 Feature 資料夾 L12` 成立
  - `Features/AISummary/OllamaDTO.swift`：`H1 L1` 已預填；`FN1 L1` 成立
  - `Features/Customers/CustomerRankBadgeStyle.swift`：`H1 L1` 已預填；`MK1 L13` 成立
  - `Features/Customers/CustomersFeature.swift`：`H1 L1` 已預填；`S·模型型別獨立成檔 L12` 成立
  - `Features/Customers/CustomersView.swift`：`H1 L1` 已預填；`MK1 L14` 成立；`S·尺寸單一來源 L245` 已預填，現行 `customerAvatarSize` 同時供頭像與分隔線使用
  - `Features/FX/FxFeature.swift`：`H1 L1` 已預填；`S·sheet 未走 Destination L43` 成立
  - `Features/FX/FxView.swift`：`H1 L1` 已預填；`FM4 L1` 成立，現行非空行數仍超過 300；`S·View 內含業務規則的格式化 L401` 已預填，現行幣別顯示已呼叫 `CurrencyDisplayName`
  - `Features/More/MoreView.swift`：`H1 L1` 已預填；`MK1 L14` 成立
  - `Features/Quote/QuoteFeature.swift`：`H1 L1` 已預填；`S·縮寫大小寫 L31` 成立
  - `Features/Quote/QuoteView.swift`：`H1 L1` 已預填；`FM4 L1` 成立，現行非空行數仍超過 300；`S·View 內含業務規則的格式化 L490` 已預填，現行幣別顯示已呼叫 `CurrencyDisplayName`
  - `Features/Settings/AISummaryModelCatalog.swift`：`H1 L1` 已預填；`MK1 L13` 成立
  - `Features/Settings/SettingsFeature.swift`：`H1 L1` 已預填；`S·doc comment 不準確 L11` 成立
  - `Features/Settings/SettingsSnapshot.swift`：`H1 L1` 已預填；`MK1 L13` 成立
  - `Features/Settings/SettingsStorage.swift`：`H1 L1` 已預填；`S·型別後綴只用已定義角色 L12` 已預填
  - `Features/Settings/SettingsView.swift`：`H1 L1` 已預填；`MK1 L14` 成立
  - `BuyLedgerTests/AISummaryFeatureTests.swift`：`H1 L1` 已預填；`IM2 L12` 成立
  - `BuyLedgerTests/CustomersFeatureTests.swift`：`H1 L1` 已預填；`IM2 L11` 成立
  - `BuyLedgerTests/FxFeatureTests.swift`：`H1 L1` 已預填；`IM2 L11` 成立
  - `BuyLedgerTests/OllamaClientTests.swift`：`H1 L1` 已預填；`IM2 L10` 成立
  - `BuyLedgerTests/QuoteFeatureTests.swift`：`H1 L1` 已預填；`FM4 L1` 成立，現行非空行數仍超過 300
  - `BuyLedgerTests/SettingsFeatureTests.swift`：`H1 L1` 已預填；`IM2 L11` 成立
- [x] 0.2 取得單元測試基準：在 design「測試環境」指定的 iPhone (以 `--simulator-id` 指定) 上，以 `xcodebuildmcp simulator-management set-appearance --mode light` 鎖淺色外觀並確認成功後，以 `BuyLedger.xctestplan` 跑完整單元回歸。驗證：本 task 下方記錄 xcresult 頂層 `totalTestCount`、通過數、失敗清單與 result bundle 絕對路徑 (以 `xcrun xcresulttool get test-results summary --path <bundle>` 讀取，不採用裝置層 `passedTests` 展開數)

  - 2026-09-22，先執行 `xcodebuildmcp simulator-management set-appearance --simulator-id DDAA3311-B464-4DD3-96B8-360B26AF1929 --mode light --output json`，輸出 `didError: false`、`status: SUCCEEDED`
  - 完整回歸命令：`xcodebuildmcp simulator test --project-path apps/ios/BuyLedger.xcodeproj --scheme BuyLedger --simulator-id DDAA3311-B464-4DD3-96B8-360B26AF1929 --output json`
  - `xcrun xcresulttool get test-results summary` 頂層結果：`totalTestCount` 731、通過 729、失敗 2、跳過 0；裝置層另有 `passedTests` 879，未用於基準比較
  - 失敗清單：`BuyLedgerTests/SnapshotTests/orderEditViewBaseline()`、`BuyLedgerTests/SnapshotTests/quoteViewBaseline()`；兩條都在常駐規則列出的已知渲染雜訊清單內
  - 完整回歸 result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-22T14-01-24-069Z_pid35597_77a5f8ed.xcresult`
  - 已知失敗單獨重跑 `xcodebuildmcp simulator test --project-path apps/ios/BuyLedger.xcodeproj --scheme BuyLedger --simulator-id DDAA3311-B464-4DD3-96B8-360B26AF1929 --extra-args "-only-testing:BuyLedgerTests/SnapshotTests/orderEditViewBaseline()" --output json`：`totalTestCount` 1、通過 1、失敗 0、跳過 0；result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-22T14-05-12-946Z_pid42058_26d4d194.xcresult`
  - 已知失敗單獨重跑 `xcodebuildmcp simulator test --project-path apps/ios/BuyLedger.xcodeproj --scheme BuyLedger --simulator-id DDAA3311-B464-4DD3-96B8-360B26AF1929 --extra-args "-only-testing:BuyLedgerTests/SnapshotTests/quoteViewBaseline()" --output json`：`totalTestCount` 1、通過 1、失敗 0、跳過 0；result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-22T14-05-50-744Z_pid42704_01cb3fe3.xcresult`
  - 判定：兩條單獨重跑均以方法層 `()` 執行且轉綠，確認為已知渲染雜訊；未修改程式碼、未重錄既有基準圖
- [x] 0.3 取得 UI 測試基準：在 design「測試環境」指定的 iPhone 與 iPad 各跑一次 `BuyLedgerUITests` 主回歸 (`--extra-args -only-testing:BuyLedgerUITests --extra-args -skip-testing:BuyLedgerUITests/LaunchPerformanceTests`)，iPad 前確認軟體鍵盤可顯示 (見 `apps/ios/CLAUDE.md`)。驗證：本 task 下方記錄兩台裝置的測試數、通過數、失敗清單與 bundle 路徑

  - 2026-09-22，iPad 軟體鍵盤前置檢查：`xcodebuildmcp simulator test --project-path apps/ios/BuyLedger.xcodeproj --scheme BuyLedgerUITests --simulator-id 6B65ED1C-3C2E-42BA-B1E7-08F606F175C5 --extra-args "-only-testing:BuyLedgerUITests/KeyboardDismissTests" --output json`；`xcrun xcresulttool get test-results summary` 頂層結果為 `totalTestCount` 2、通過 2、失敗 0、跳過 0，確認軟體鍵盤可顯示；result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-22T14-07-37-933Z_pid44186_0a1d9874.xcresult`
  - iPhone 主回歸命令：`xcodebuildmcp simulator test --project-path apps/ios/BuyLedger.xcodeproj --scheme BuyLedgerUITests --simulator-id DDAA3311-B464-4DD3-96B8-360B26AF1929 --extra-args "-only-testing:BuyLedgerUITests" --extra-args "-skip-testing:BuyLedgerUITests/LaunchPerformanceTests" --output json`
  - iPhone `xcrun xcresulttool get test-results summary` 頂層結果：裝置 `iPhone 17`、`totalTestCount` 64、通過 64、失敗 0、跳過 0、失敗清單空；result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-22T14-10-23-789Z_pid46517_076eb2d5.xcresult`
  - iPad 主回歸命令：`xcodebuildmcp simulator test --project-path apps/ios/BuyLedger.xcodeproj --scheme BuyLedgerUITests --simulator-id 6B65ED1C-3C2E-42BA-B1E7-08F606F175C5 --extra-args "-only-testing:BuyLedgerUITests" --extra-args "-skip-testing:BuyLedgerUITests/LaunchPerformanceTests" --output json`
  - iPad `xcrun xcresulttool get test-results summary` 頂層結果：裝置 `iPad Air 11-inch (M4)`、`totalTestCount` 64、通過 64、失敗 0、跳過 0、失敗清單空；result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-22T14-43-47-466Z_pid70495_5013473e.xcresult`
- [x] 0.4 取得畫面比對基準 (design 驗收條件 8)：以 `xcodebuildmcp simulator launch-app --launch-args` 在 design「測試環境」指定的 iPhone 上，帶 UI 測試 harness 參數 `-BLUITest -BLUITestSeed fullOrders -BLUITestNow 2026-04-26T08:00:00Z` 啟動 (AI 總結畫面另加 `-BLUITestAiSummary`)，淺色外觀下以 `xcodebuildmcp ui-automation` 截取匯率工具、報價試算、設定、客戶名單、更多、AI 總結六個畫面的一般狀態，共六張 (harness 沒有模擬匯率失敗的選項，錯誤狀態由 0.5 與既有 `quoteViewRateUnavailable` 守)。截圖存到 repo 以外的 `/private/tmp/buyledger-step3-screens/before/`，檔名 `01-fx.png`、`02-quote.png`、`03-settings.png`、`04-customers.png`、`05-more.png`、`06-ai-summary.png`。驗證：每張的啟動參數、進入畫面的操作步驟與檔案路徑記錄在本 task 下方，讓 8.5 能逐字重現

  - 2026-09-22，先在 `apps/ios` 執行 `agvtool next-version`，成功將專案版本號遞增為 `355`；接著執行 `xcodebuildmcp simulator build-and-run --project-path apps/ios/BuyLedger.xcodeproj --scheme BuyLedger --simulator-id DDAA3311-B464-4DD3-96B8-360B26AF1929 --output json`，結果 `SUCCEEDED`，bundle id 為 `com.leoho.BuyLedger`
  - 一般畫面重新啟動完整參數：`-BLUITest -BLUITestSeed fullOrders -BLUITestNow 2026-04-26T08:00:00Z`；實際命令：`xcodebuildmcp simulator launch-app --simulator-id DDAA3311-B464-4DD3-96B8-360B26AF1929 --bundle-id com.leoho.BuyLedger --launch-args "-BLUITest" --launch-args "-BLUITestSeed" --launch-args "fullOrders" --launch-args "-BLUITestNow" --launch-args "2026-04-26T08:00:00Z" --output json`
  - AI 畫面重新啟動完整參數：`-BLUITest -BLUITestSeed fullOrders -BLUITestNow 2026-04-26T08:00:00Z -BLUITestAiSummary`；實際命令同上並追加 `--launch-args "-BLUITestAiSummary"`
  - 操作路徑與檔案：`01-fx.png`：`dashboard.root → root.tab.more (更多) → more.root → more.row.fx (匯率工具) → fx.root`，檔案 `/private/tmp/buyledger-step3-screens/before/01-fx.png`
  - 操作路徑與檔案：`02-quote.png`：`fx.root → BackButton (返回更多) → more.root → more.row.quote (報價試算) → quote.root`，檔案 `/private/tmp/buyledger-step3-screens/before/02-quote.png`
  - 操作路徑與檔案：`03-settings.png`：`quote.root → BackButton (返回更多) → more.root → more.row.settings (設定) → settings.root`，檔案 `/private/tmp/buyledger-step3-screens/before/03-settings.png`
  - 操作路徑與檔案：`04-customers.png`：`settings.root → BackButton (返回更多) → more.root → more.row.customers (客戶名單) → customers.list.root`，檔案 `/private/tmp/buyledger-step3-screens/before/04-customers.png`
  - 操作路徑與檔案：`05-more.png`：`dashboard.root → root.tab.more (更多) → more.root`，檔案 `/private/tmp/buyledger-step3-screens/before/05-more.png`
  - 操作路徑與檔案：`06-ai-summary.png`：AI 參數啟動後 `dashboard.root → root.tab.orders (訂單) → orders.list.root → orders.list.batchMenuButton (更多操作) → orders.list.aiSummaryButton (AI 總結) → aiSummary.root`，檔案 `/private/tmp/buyledger-step3-screens/before/06-ai-summary.png`

- [x] 0.5 在改動任何 production code 之前，於 `SnapshotTests` 新增匯率工具的兩條 snapshot 測試並錄製基準圖：`fxViewBaseline` (以固定快照呈現已連線狀態) 與 `fxViewRateFailureBaseline` (以 `errorMessage` 呈現錯誤橫幅與重試鍵)，寫法比照既有 `quoteViewBaseline` (`TestDependencies.withFixedNow`、正體中文 locale、393×852)，但 store 用 `EmptyReducer()`，狀態只傳 `snapshot: FxRateSnapshot.fallback` 或 `errorMessage:` 既有文案 (見 design 驗收條件 8)，錄製前鎖淺色外觀；依 `apps/ios/README.md`，第一次執行會自動錄製並回報失敗，屬正常，逐張確認畫面內容後再執行一次才是比對。驗證：第二次執行時兩條以方法層 `-only-testing` (帶 `()`) 單獨跑通過且 `totalTestCount` ≥ 1；本 task 只動 `SnapshotTests.swift` 與兩張新基準圖，不動任何 production code；bundle 路徑記在本 task 下方 [after: 0.2]

  - 2026-09-22，先鎖定 iPhone 淺色外觀：`xcodebuildmcp simulator-management set-appearance --simulator-id DDAA3311-B464-4DD3-96B8-360B26AF1929 --mode light --output json`，結果 `SUCCEEDED`
  - 新增測試：`fxViewBaseline` 使用 `FxRateSnapshot.fallback`，`fxViewRateFailureBaseline` 使用既有 transport 文案 `網路連線異常；無法顯示即時匯率，請稍後再試。`；兩者均使用明確型別的 `Store<FxFeature.State, FxFeature.Action>`、`EmptyReducer()`、`TestDependencies.withFixedNow`、正體中文 locale 與 393×852
  - `fxViewBaseline()` 第一次錄製：`totalTestCount` 1、通過 0、失敗 1；因找不到 reference 而自動產生 `/Users/leoho/Develop/BuyLedger/apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/fxViewBaseline.1.png`；result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-22T15-22-06-599Z_pid762_aabe1466.xcresult`
  - `fxViewRateFailureBaseline()` 第一次錄製：`totalTestCount` 1、通過 0、失敗 1；因找不到 reference 而自動產生 `/Users/leoho/Develop/BuyLedger/apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/fxViewRateFailureBaseline.1.png`；result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-22T15-23-14-713Z_pid1883_5a466134.xcresult`
  - 兩張 PNG 已目視確認：`fxViewBaseline.1.png` 顯示綠色已連線橫幅與匯率列表；`fxViewRateFailureBaseline.1.png` 顯示橘色錯誤橫幅、重試鍵與未連線匯率列表
  - `fxViewBaseline()` 第二次方法層重跑命令：`xcodebuildmcp simulator test --project-path apps/ios/BuyLedger.xcodeproj --scheme BuyLedger --simulator-id DDAA3311-B464-4DD3-96B8-360B26AF1929 --extra-args "-only-testing:BuyLedgerTests/SnapshotTests/fxViewBaseline()" --output json`；頂層 `totalTestCount` 1、通過 1、失敗 0、跳過 0；result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-22T15-23-58-347Z_pid2588_3f4b7351.xcresult`
  - `fxViewRateFailureBaseline()` 第二次方法層重跑命令：`xcodebuildmcp simulator test --project-path apps/ios/BuyLedger.xcodeproj --scheme BuyLedger --simulator-id DDAA3311-B464-4DD3-96B8-360B26AF1929 --extra-args "-only-testing:BuyLedgerTests/SnapshotTests/fxViewRateFailureBaseline()" --output json`；頂層 `totalTestCount` 1、通過 1、失敗 0、跳過 0；result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-22T15-24-28-138Z_pid3095_b1b26dd5.xcresult`
  - 本 task 新增基準圖：`/Users/leoho/Develop/BuyLedger/apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/fxViewBaseline.1.png`、`/Users/leoho/Develop/BuyLedger/apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/fxViewRateFailureBaseline.1.png`
  - Step 3 batch 1 完成狀態：0.1、0.2、0.3、0.4、0.5 全部完成；依 scratchpad 指示不開始 1.x，等待 review
  - Step 3 batch 1 完成時完整 `git status --short`：

    ```text
     M apps/ios/BuyLedger.xcodeproj/project.pbxproj
     M apps/ios/BuyLedgerTests/SnapshotTests.swift
    ?? apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/fxViewBaseline.1.png
    ?? apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/fxViewRateFailureBaseline.1.png
    ?? openspec/changes/small-features-style-compliance/
    ```

## 1. 共用入口

- [x] 1.1 依「View 以獨立 View 型別拆檔，格式化移出 View」新增月日短日期的唯一入口 `BLFormatters.shortDate(_:locale:)`，`OrderFormatters.shortDate(_:locale:)` 改為一行轉呼叫 (簽章與輸出不變，Orders 其他呼叫端不動)。驗證：`BLFormattersTests` 新增正體中文與英文各一條逐字斷言；`grep -rn "month(.defaultDigits)" apps/ios/BuyLedger` 在本 change 完工後只剩 `BLFormatters.swift` 與 `FxFormatters.swift` 兩處 (後者是月日時分，不同規則)；專案可編譯 [after: 0.5]

  - 新增 `BLFormatters.shortDate(_:locale:)` 作為月日短日期唯一入口，`OrderFormatters.shortDate` 改為單行委派；`BLFormattersTests` 補正體中文與英文逐字斷言
  - 驗證命令：`xcodebuildmcp simulator test --project-path apps/ios/BuyLedger.xcodeproj --scheme BuyLedger --simulator-id DDAA3311-B464-4DD3-96B8-360B26AF1929 --extra-args "-only-testing:BuyLedgerTests/BLFormattersTests" --output json`
  - 頂層結果：`totalTestCount` 18、通過 18、失敗 0、跳過 0；result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-22T15-38-20-650Z_pid15497_73c72ca8.xcresult`
  - review 修正第 1 輪：兩條月日測試合併為 `@Test(arguments:)`，改用 UTC 2026-04-30 12:00 的 `DateComponents` 固定日期，避免裝置時區跨日；`BLFormatters` 型別說明補上日期規則
  - review 修正後 `BLFormattersTests` class-level focused test：頂層 `totalTestCount` 17、通過 17、失敗 0、跳過 0；result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-22T16-10-08-617Z_pid43661_897722e2.xcresult`
- [x] 1.2 依「匯率換算收斂到 FxRateSnapshot」在 `FxRateSnapshot` 新增 `twdRate(for:)`，回傳規則為新台幣回 1、以新台幣為基準且匯率大於 0 回倒數、以該幣別為基準回其新台幣匯率、其餘回 `nil`。驗證：新增 `FxRateSnapshotTests.swift` 涵蓋四種分支，預期值寫死數字，不用與實作相同的算式 [after: 0.5]

  - 新增 `FxRateSnapshot.twdRate(for:)` 與四條分支測試，預期值使用固定數字且未重用實作算式
  - 驗證命令：`xcodebuildmcp simulator test --project-path apps/ios/BuyLedger.xcodeproj --scheme BuyLedger --simulator-id DDAA3311-B464-4DD3-96B8-360B26AF1929 --extra-args "-only-testing:BuyLedgerTests/FxRateSnapshotTests" --output json`
  - 頂層結果：`totalTestCount` 4、通過 4、失敗 0、跳過 0；result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-22T15-38-52-015Z_pid15991_9d040f16.xcresult`
- [x] 1.3 依「OllamaClient 搬到 Core/Networking」把 `OllamaClient` 搬到 `Core/Networking/`，DTO 改名 `OllamaChatRequest`／`OllamaChatResponse` 各一檔，網址改字面值常數並刪掉偽造 `NSURLErrorDomain` 的分支，`testValue` 改用自有 domain `com.leoho.BuyLedger.networking` 與代碼 `2` (比照 `ExchangeRateClient` 的 `dependencyNotInjectedCode`，以 `OllamaClient` 自己的 private 常數宣告)，三個 `catch` 子句改單一 `catch`，移除冗餘 `nonisolated`。`OllamaClientTests` 依「測試定型：Given／When／Then、case key path、LockIsolated 與 fixture」改用 `try #require`、以 `@Test(arguments:)` 合併空行與壞格式輸入。驗證：`apps/ios/BuyLedger/Features/AISummary/` 只剩 `AISummaryFeature.swift` 與 `AISummaryView.swift`；`grep -rn "NSURLErrorDomain" apps/ios/BuyLedger/Core/Networking/OllamaClient.swift` 無輸出；`OllamaClientTests` 與 `LayerBoundaryTests` 全綠 [after: 0.5]

  - 以一般 `mv` 將 `OllamaClient` 搬到 `Core/Networking/`，並拆出 `OllamaChatRequest.swift`、`OllamaChatResponse.swift`；保留 `streamSummary` closure 簽章、`overallStreamDuration` 與 `parse(line:)`，呼叫端未修改
  - `OllamaClient` 改用固定 `chatURL`、自有 networking domain 與 code `2`，移除 `NSURLErrorDomain` 分支、冗餘 `nonisolated` 與分散的 `catch`
  - `OllamaClientTests` 改為 `Tests` 分區，補 doc 與 Given／When／Then、`try #require`，空白與壞格式輸入合併為參數化測試
  - 驗證命令：`xcodebuildmcp simulator test --project-path apps/ios/BuyLedger.xcodeproj --scheme BuyLedger --simulator-id DDAA3311-B464-4DD3-96B8-360B26AF1929 --extra-args "-only-testing:BuyLedgerTests/OllamaClientTests" --output json`
  - 頂層結果：`totalTestCount` 6、通過 6、失敗 0、跳過 0；result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-22T15-43-28-950Z_pid19751_891a2437.xcresult`
  - 驗證命令：`xcodebuildmcp simulator test --project-path apps/ios/BuyLedger.xcodeproj --scheme BuyLedger --simulator-id DDAA3311-B464-4DD3-96B8-360B26AF1929 --extra-args "-only-testing:BuyLedgerTests/LayerBoundaryTests" --output json`
  - 頂層結果：`totalTestCount` 6、通過 6、失敗 0、跳過 0；result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-22T15-46-40-026Z_pid22358_97ebce7a.xcresult`
  - `AISummaryFeatureTests` class-level focused test：`totalTestCount` 6、通過 6、失敗 0、跳過 0；result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-22T15-47-05-333Z_pid22740_3fe94692.xcresult`
  - `TestSuiteIntegrityTests` class-level focused test：`totalTestCount` 3、通過 3、失敗 0、跳過 0；result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-22T15-47-28-630Z_pid23088_970bd508.xcresult`
  - `apps/ios/BuyLedger/Features/AISummary/` 只剩 `AISummaryFeature.swift` 與 `AISummaryView.swift`；`grep -rn "NSURLErrorDomain" apps/ios/BuyLedger/Core/Networking/OllamaClient.swift` 無輸出
- [x] 1.4 新增 `apps/ios/BuyLedgerTests/LedgerOrder+Fixture.swift`，提供全部參數都有預設值的 `LedgerOrder.fixture(...)`，預設值為固定日期與固定識別值，不含隨機值或目前時間，品項預設為空陣列 (避免 `LedgerOrderItem` 的 `$newUUID` 預設)。驗證：檔案通過機械檢查；`grep -n "Date()\|UUID()\|\.now" apps/ios/BuyLedgerTests/LedgerOrder+Fixture.swift` 無輸出；實際使用由 4.1 與 6.1 的測試涵蓋 (本 task 不另寫測試來測 fixture 自己) [after: 0.5]

  - 新增 `LedgerOrder+Fixture.swift` 的 `LedgerOrder` extension；`fixture` 參數依 memberwise init 順序一一對應且全部有預設值，固定日期為 `Date(timeIntervalSince1970: 0)`，品項預設為空陣列
  - 機械驗證：`grep -n "Date()\|UUID()\|\.now" apps/ios/BuyLedgerTests/LedgerOrder+Fixture.swift` 無輸出；測試 target 編譯時已包含此檔
  - batch2 六個指定 class-level focused tests 均通過：`BLFormattersTests` 18/18（result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-22T15-49-12-084Z_pid24436_478ee35c.xcresult`）、`FxRateSnapshotTests` 4/4（result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-22T15-49-35-343Z_pid24796_fb383683.xcresult`）、`OllamaClientTests` 6/6、`AISummaryFeatureTests` 6/6、`LayerBoundaryTests` 6/6、`TestSuiteIntegrityTests` 3/3；所有 focused test 的頂層 `totalTestCount` 均大於 0
  - 最後一次 Swift 寫入後的完整 unit regression：頂層 `totalTestCount` 738、737 通過、1 失敗、0 跳過；唯一失敗為已知 snapshot noise `BuyLedgerTests/SnapshotTests/orderEditViewBaseline()`；完整 result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-22T15-52-55-553Z_pid27538_cf939a19.xcresult`
  - 依 scratchpad 指示以方法層 selector `-only-testing:BuyLedgerTests/SnapshotTests/orderEditViewBaseline()` 重跑：`totalTestCount` 1、通過 1、失敗 0、跳過 0；result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-22T15-53-41-651Z_pid28159_5805f5aa.xcresult`
  - 修正 `OllamaClient` 分區名後重跑 `OllamaClientTests`：`totalTestCount` 6、通過 6、失敗 0、跳過 0；result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-22T15-56-33-327Z_pid30438_ac88cc36.xcresult`
  - 最後一次 Swift 寫入後再次完整 unit regression：`totalTestCount` 738、通過 738、失敗 0、跳過 0；result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-22T15-57-08-824Z_pid30940_cd7b6095.xcresult`
  - review 修正第 1 輪：`OllamaClient` 恢復 `DependencyKey` protocol 分區；`chatURL`、networking domain 與錯誤代碼移入型別本體 `Properties`；兩個 DTO 巢狀 `Message` 移除內嵌 MARK；`OllamaChatRequest.swift` 檔頭日期改為 `2026/9/22`
  - review 修正第 1 輪：三條 Ollama 解析測試恢復完整 API 欄位，Preview 測試改斷言收到 5 段且以 `## 商品明細總結` 開頭；`findings.md` 的 Ollama L56 結論同步記錄本輪修正
  - review 修正後 `OllamaClientTests` class-level focused test：頂層 `totalTestCount` 6、通過 6、失敗 0、跳過 0；result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-22T16-13-23-038Z_pid46481_8b106811.xcresult`
  - review 修正後 `LayerBoundaryTests` class-level focused test：頂層 `totalTestCount` 6、通過 6、失敗 0、跳過 0；result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-22T16-10-35-676Z_pid44081_f35bbd32.xcresult`
  - 最後一次 Swift 寫入後的完整 unit regression：頂層 `totalTestCount` 737、通過 736、失敗 1、跳過 0；唯一失敗為已知 snapshot noise `BuyLedgerTests/SnapshotTests/ordersCompactViewMultiSelectBaseline()`；result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-22T16-14-27-694Z_pid47578_0be8fa45.xcresult`
  - 依 scratchpad 指示以方法層 selector `-only-testing:BuyLedgerTests/SnapshotTests/ordersCompactViewMultiSelectBaseline()` 重跑：頂層 `totalTestCount` 1、通過 1、失敗 0、跳過 0；result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-22T16-15-15-560Z_pid48216_bf9adbda.xcresult`
  - 外觀設定依 fix1 要求執行 iPhone 與 iPad，兩台均在初次設定失敗後以 `xcodebuildmcp simulator list` 確認為 Booted/available 並重試，仍因 CoreSimulatorService connection invalid 失敗；完整回歸仍已執行並取得上述 xcresult
  - batch3 第 0 項：`OllamaClientTests.parseMarksDoneOnFinalLine` 的 JSON 恢復為單行字串；該約 101 字元字串依 formatting 與 design 驗收例外保留超過 100 字元的單行字串字面值

## 2. 設定

- [x] 2.1 依「設定儲存改名 SettingsStore 並修正月度目標預設」把 `SettingsStorage` 改名 `SettingsStore` (檔案同步改名，留在 `Features/Settings/`)，讀寫抽成 `snapshot(from:)` 與 `save(_:to:)` 兩個接收 `UserDefaults` 的純函式，nested key 型別改名 `Keys`，刪除 `SettingsSnapshot.testDefault`。落實「A setting that was never written reads as its documented default」：月度目標 key 不存在時回 80,000，已寫入的值 (含 0) 照舊以 `double(forKey:)` 讀取。本 task 的欄位一律沿用改名前的名稱 (`monthlyProfitGoalTwd`、`useAiSummary`)，改名由 2.2 處理。直接修改的檔：`SettingsStore.swift` (由 `SettingsStorage.swift` 改名)、`SettingsFeature.swift` (依賴宣告的型別名)、`SettingsSnapshot.swift` (刪 `testDefault`)。連帶只改型別名稱的檔：`BuyLedgerApp`、`OrdersFeature`、`BLUITestDependencyOverrides`、`OrdersFeatureTests`、`RootFeatureTests`。驗證：新增 `SettingsStoreTests.swift`，以 `UserDefaults(suiteName:)` 獨立網域覆蓋「從未寫入回 80,000」「寫入 0 讀回 0」「寫入 120,000 讀回 120,000」三組 (`@Test(arguments:)`) 與完整快照往返，測後清除網域；`grep -rn "SettingsStorage" apps/ios --include='*.swift'` 無輸出 (README 由 7.2 處理) [after: 0.2] [after: 0.5]

  - `SettingsStoreTests` focused test：頂層 `totalTestCount` 2、通過 2、失敗 0、跳過 0；result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-22T16-32-04-429Z_pid62362_12e84c68.xcresult`
  - `rg -n "SettingsStorage" apps/ios --glob '*.swift'` 無輸出；`SettingsSnapshot.testDefault` 已移除
- [x] 2.2 依「命名改正與 UserDefaults key 不變」把 `monthlyProfitGoalTwd` 改 `monthlyProfitGoalTWD`、`useAiSummary` 改 `isAISummaryEnabled` (`SettingsFeature.State`、`SettingsSnapshot`)，連帶只改名稱：`RootFeature` 的 `onChange` 與賦值、`OrdersFeature` 的讀取與 doc、`OrdersFeatureTests`、`BLUITestDependencyOverrides`；`DashboardFeature`、`BLUITestConfiguration`、`LaunchOptions` 的同名欄位不改。落實「Stored preference keys survive code renames」與「AI summary setting and model configuration」(範圍依「ai-order-summary 規格只改用詞」，其餘三個既有情境不改行為)：六個 UserDefaults key 字串一律不變。驗證：`SettingsStoreTests` 新增一條以六個舊 key 字串直接寫入、再以 `snapshot(from:)` 讀回的測試，六個欄位都讀得到寫入值；`git diff` 中 `settings.` 開頭的字串字面值零變動 [after: 2.1]

  - 欄位改名後 `SettingsStoreTests`：頂層 `totalTestCount` 3、通過 3、失敗 0、跳過 0；包含六個舊 key 直接寫入讀回測試；result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-22T16-35-59-650Z_pid65420_5fd3066c.xcresult`
- [x] 2.3 依「父層不送子層 action，設定在建立 State 時帶齊」落實「Settings are available from the first frame」：`SettingsFeature.State` 新增 `appVersion` 欄位與寫在本體的 `init(snapshot: = .default, appVersion: = "—")` (既有 `SettingsFeature.State()` 呼叫不改)；`Bundle+Extensions` 新增 `appVersion` (格式 `短版號 (建置號)`；短版號或建置號任一缺值，整串輸出「—」，邏輯直接寫在 computed property 內不另抽純函式，兩者均為使用者裁決，見 design「App 版本字串」)；`RootFeature.State.init` 改為 `(persistenceStatus:settings:)`；`BuyLedgerApp` 把讀出的快照與版本字串交給它；`RootFeature` 刪掉 `.task` 與 `.dashboard(.delegate(.refresh))` 內的兩處 `.send(.settings(.task))`。驗證：`RootFeatureTests` 以非預設值的快照 (英文、USD、月度目標 120,000) 建立 State，斷言建立當下 `state.settings` 的各欄位就是這些值 (對應「Settings are available from the first frame」的 first-frame 情境)；啟動 `.task` 不再收到任何 `.settings` 的載入 action；總覽重整測試只收到 `.orders(.task)`，且注入的 `SettingsStore` 替身以 `LockIsolated` 記錄 `load` 呼叫次數，斷言為 0；`AppLockFeatureTests` 與 `RootFeatureTests` 的鎖定測試維持綠燈 [after: 2.2]

  - first-frame 注入與版本純函式整合驗證：RootFeature、BundleExtensions、SettingsStore 合計頂層 `totalTestCount` 39、通過 39、失敗 0、跳過 0；result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-22T16-42-21-954Z_pid70615_1425eb6d.xcresult`
- [x] 2.4 依「TCA Feature 型別的分區與 Action 分組範本」與「同一次請求的結果合併成 Result」重整 `SettingsFeature`：分區 `State`／`Action`／`Dependencies`／`Body`、`Reduce(core)`、`Action` 分 `binding`／`view(task, defaultCurrencySelected, aiSummaryModelSelected)`／`appLock`／`currencyCodesResponse`，`.view(.task)` 只載入幣別清單，失敗或空清單時保留目前清單。依「設定寫入維持同步」存檔維持在 reducer 內同步呼叫，落實「Settings writes preserve the order of edits」。`SettingsFeature.Action` 與 `RootFeature.Action` 移除 `Equatable`。App 鎖定相關攔截不動。`SettingsFeatureTests` 依「測試定型：Given／When／Then、case key path、LockIsolated 與 fixture」改寫，`AppLanguage` 的四條搬到新的 `AppLanguageTests.swift` 並參數化，`SnapshotBox` 改 `LockIsolated`，重複的存檔測試合併為參數化「會存檔的 binding 欄位都會存檔」，參數是 `language`、`isAISummaryEnabled`、`monthlyProfitGoalTWD` 三個欄位，另寫一條斷言 `isGoalFieldFocused` 的 binding 不觸發存檔 (維持現況)。驗證：新增一條連續送三次月度目標 binding 的測試，斷言存檔替身依序收到三份快照且最後一份等於最後輸入值；幣別清單失敗與空清單各一條測試；`SettingsFeatureTests`、`AppLanguageTests`、`RootFeatureTests` 全綠 [after: 2.3]

-  - continuation 放行：實際只有三處以值比對的 `receive`，其中兩處改為 case key path 加 expected value，保留剩餘一處可由 action 型別直接比對；不以值自由的 `receive` 取代
-  - `SettingsFeatureTests`、`AppLanguageTests`、`SettingsStoreTests`、`BundleExtensionsTests`、`RootFeatureTests` 等 focused unit 共 156/156 通過
- [x] 2.5 讓 `SettingsView` 符合 View 規則：`body` 只放 `Form` 與六個 Section 的 Private View 呼叫加整個畫面的 modifier，鍵盤工具列抽成 `keyboardToolbar`，Properties 依 `@Environment` → `@FocusState` → `store` 排序，modifier 依四組排序，除了 `.appLock(.enableToggled(_:))` (第 8 步) 以外只送 `.view(...)`，焦點以 `$store` 綁定寫入，版本列讀 `store.appVersion`。`AISummaryModelCatalog`、`SettingsSnapshot`、`SettingsStore` 的分區、doc 與冗餘 `nonisolated` 一併處理。驗證：`grep -n "binding(.set" apps/ios/BuyLedger/Features/Settings/SettingsView.swift` 無輸出、`Bundle.main` 在該檔無輸出；`LocalizationCatalogTests` 的根畫面 navigationTitle 掃描維持綠燈 [after: 2.4]

  - full unit regression: `xcodebuildmcp simulator test --project-path apps/ios/BuyLedger.xcodeproj --scheme BuyLedger --simulator-id DDAA3311-B464-4DD3-96B8-360B26AF1929 --output json`，top-level `totalTestCount` 743、passed 743、failed 0、skipped 0，xcresult `/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-22T17-17-38-675Z_pid99161_33dcc4ec.xcresult`
  - focused unit regression: `SettingsStoreTests`、`SettingsFeatureTests`、`AppLanguageTests`、`BundleExtensionsTests`、`RootFeatureTests`、`OrdersFeatureTests`、`AppLockFeatureTests`、`OllamaClientTests`、`LocalizationCatalogTests` 共 156/156 通過，xcresult `/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-22T17-21-15-957Z_pid2254_f062d854.xcresult`
  - iPhone UI regression: `AppLockTests`、`LaunchSmokeTests`、`HarnessSelfCheckTests` 共 14/14 通過，xcresult `/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-22T17-29-48-073Z_pid8827_81c5e750.xcresult`；`CurrencyPickerTests` 8/8 通過，xcresult `/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-22T17-33-59-392Z_pid11878_6aed6a94.xcresult`

## 3. 匯率工具

- [x] 3.1 依「TCA Feature 型別的分區與 Action 分組範本」、「幣別選擇 sheet 改由 Destination 驅動」與「同一次請求的結果合併成 Result」重整 `FxFeature`：`Action` 分 `binding`／`view(task, retryTapped, quickAmountTapped, currencyPickerTapped, currencySelected)`／`destination`／`currencyCodesResponse`／`ratesResponse`，`@Presents var destination` 取代 `showsCurrencySheet`，補 `Destination.State` 的 `Equatable` 與 `Sendable` extension，`.task` 分支抽成回傳 `Effect<Action>` 的 Private Method，`displayRate(for:)` 改用 `FxRateSnapshot.twdRate(for:)`，新增 `ratesListCurrencies`，`convertedTwd` 改名 `convertedTWD`。`FxFeatureTests` 依測試定型一節改寫並修掉以 fallback 快照驗證的假測試。驗證：新增重試、幣別選取後 `destination` 為 `nil`、幣別清單失敗保留清單三條測試；修正後的匯率測試以自訂快照與寫死數字斷言；`FxFeatureTests` 全綠 [after: 0.5] [after: 1.2] [after: 2.4]

  - `FxFeatureTests` 11/11 通過、失敗 0、跳過 0；result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-22T18-00-40-024Z_pid34388_567a7568.xcresult`
- [x] 3.2 依「View 以獨立 View 型別拆檔，格式化移出 View」新增 `FxFormatters` (`rate`、`snapshotTimestamp`、`presetAmount`) 與 `Features/FX/Components/` 的 `FxStatusBanner`、`FxRatesList`，`FxView` 的 `body` 只放大框架，重試送 `.view(.retryTapped)`，鍵盤工具列的完成鍵改為直接寫入 `store.isAmountFieldFocused = false` (不再手組 `.binding(.set(...))`，否則 7.1 的掃描一開始就會失敗)，`.sheet` 移到 `body` 的呈現組，刪除 `rateSourceSubtitle` 中永遠不會執行的新台幣分支，加入初始、載入中、錯誤、已連線四個具名 `#Preview`。驗證：`FxView.swift` 與兩個元件檔各不超過 300 行 (不含檔頭與空行)；`grep -rn "binding(.set" apps/ios/BuyLedger/Features/FX` 無輸出；0.5 新增的 `fxViewBaseline()` 與 `fxViewRateFailureBaseline()` 單獨重跑通過、不重錄；`grep -n "formatted(" apps/ios/BuyLedger/Features/FX/FxView.swift` 無輸出；UI 測試 `FxTests` 與 `CurrencyPickerTests` 單獨跑全綠 [after: 0.5] [after: 3.1]

  - `FxView.swift` 286 行、`FxStatusBanner.swift` 86 行、`FxRatesList.swift` 81 行（不含檔頭與空行）；FX 目錄 `binding(.set` 與 `FxView.swift` 的 `formatted(` 掃描皆無輸出
  - `fxViewBaseline()` 1/1 通過，未重錄；xcresult：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-22T18-09-33-254Z_pid41499_7d16c234.xcresult`
  - `fxViewRateFailureBaseline()` 1/1 通過，未重錄；xcresult：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-22T18-10-50-431Z_pid42619_e165baa3.xcresult`
  - iPhone `FxTests` 3/3 通過；xcresult：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-22T18-12-12-748Z_pid43876_b0f3c16f.xcresult`
  - iPhone `CurrencyPickerTests` 8/8 通過；xcresult：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-22T18-14-41-343Z_pid45793_c55a3cf3.xcresult`
  - 最後回歸補正字串插值以符合既有本地化 key；`LocalizationCatalogTests` 12/12 通過；xcresult：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-22T18-54-55-031Z_pid78037_ba9c5823.xcresult`
  - review 修正第 1 輪：六個 FX／Quote View 與元件的 MARK 分區改為 `Properties`、`Body`、`Private Views`、`Computed Properties`，並依規範調整分區順序；畫面內容未改變
  - review 修正第 1 輪的行寬紀錄：review 指出的 `FxView.swift:229` 在分區搬移後為現行 `FxView.swift:214`；該行與 `FxStatusBanner.swift:99` 是單一本地化字串字面值，`OllamaClientTests.swift:36` 是單一 JSON 字串字面值，三行皆依 design 驗收條件 1 保留，不拆字串、不改測試資料

## 4. 報價試算

- [x] 4.1 依「TCA Feature 型別的分區與 Action 分組範本」、「幣別選擇 sheet 改由 Destination 驅動」與「同一次請求的結果合併成 Result」重整 `QuoteFeature`：`Action` 分 `binding`／`view(task, retryTapped, currencyPickerTapped, currencySelected)`／`destination`／`currencyCodesResponse`／`ratesResponse`，`rate` 改用 `FxRateSnapshot.twdRate(for:)`，九個 `...Twd` 屬性改 `...TWD`，新增 `displayedSuggestedTWD` 與 `heroMessage`，`loadRates` 改為回傳 `Effect<Action>` 的 instance 方法。`QuoteFeatureTests` 依測試定型一節改寫：毛利公式與 100%／150%／80% 改參數化、手刻訂單改 `LedgerOrder.fixture`、`QuoteRateClientStub` 移進 `Nested Types`、英文註解與錯誤算式註解改正。`SnapshotTests` 只改 `QuoteFeature.State(...)` 的參數標籤。驗證：新增 `displayedSuggestedTWD` 與 `heroMessage` 三種情形的測試；`QuoteFeatureTests` 全綠 (4.1 與 0.5 都改 `SnapshotTests.swift`，必須在 0.5 之後) [after: 0.5] [after: 1.2] [after: 1.4] [after: 2.4]

  - `QuoteFeatureTests` focused test：頂層 `totalTestCount` 20、通過 20、失敗 0、跳過 0；result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-22T18-32-07-110Z_pid59562_4b399721.xcresult`
  - review 修正第 1 輪：將 `HeroMessage`、`Destination` 與 `Equatable`／`Sendable` conformance 移至 `QuoteFeature+Destination.swift`；`QuoteFeature.swift` 298 行、`QuoteFeature+Destination.swift` 28 行（均不含檔頭與空行），行為不變
- [x] 4.2 依「View 以獨立 View 型別拆檔，格式化移出 View」新增 `Features/Quote/Components/` 的 `QuoteStatusBanner` 與 `QuoteBreakdownCard` (三元素 tuple 改 nested `BreakdownItem`、移除未使用的 `palette` 參數)，`QuoteView` 的 `body` 只放大框架，鍵盤工具列的完成鍵改為直接寫入 `store.isAmountFieldFocused = false` (不再手組 `.binding(.set(...))`)，hero 卡改讀 `displayedSuggestedTWD` 與 `heroMessage`，`suggestedHero` 改 `var`，加入可試算、匯率不可用、毛利達 100% 三個具名 `#Preview`。驗證：三個檔各不超過 300 行；`grep -rn "binding(.set" apps/ios/BuyLedger/Features/Quote` 無輸出；`quoteViewBaseline()` 與 `quoteViewRateUnavailable()` 以方法層 `-only-testing` (帶 `()`) 單獨重跑通過且 `totalTestCount` ≥ 1，不重錄基準圖；UI 測試 `QuoteTests` 單獨跑全綠 [after: 4.1]

  - `QuoteView.swift` 300 行、`QuoteStatusBanner.swift` 92 行、`QuoteBreakdownCard.swift` 129 行（均不含檔頭與空行）；Quote 目錄 `binding(.set` 掃描無輸出
  - `quoteViewBaseline()` 1/1 通過，未重錄；xcresult：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-22T18-50-13-251Z_pid73753_e3c9d85c.xcresult`
  - `quoteViewRateUnavailable()` 1/1 通過，未重錄；xcresult：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-22T18-46-41-535Z_pid70813_0f307737.xcresult`
  - iPhone `QuoteTests` 2/2 通過；xcresult：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-22T18-47-54-132Z_pid71818_6192d222.xcresult`
  - 四條指定快照合併重跑 (`fxViewBaseline()`、`fxViewRateFailureBaseline()`、`quoteViewBaseline()`、`quoteViewRateUnavailable()`) 4/4 通過，未重錄；xcresult：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-22T18-53-14-719Z_pid76683_58dc798c.xcresult`
  - Quote/FX 實作完成時完整單元回歸：頂層 `totalTestCount` 746、通過 746、失敗 0、跳過 0；相較 0.2 基準 743，增量為 `FxFeatureTests` +2、`QuoteFeatureTests` +1；xcresult：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-22T19-04-47-858Z_pid85653_30ad7e8c.xcresult`
  - Quote/FX 實作完成時 iPhone UI：`FxTests` 3/3（xcresult：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-22T18-55-44-685Z_pid78744_ffe08188.xcresult`）、`QuoteTests` 2/2（xcresult：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-22T18-58-19-390Z_pid80834_f681bdfd.xcresult`）、`CurrencyPickerTests` 8/8（xcresult：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-22T18-59-37-219Z_pid81829_9549d57e.xcresult`）
  - 最後的 Swift 註解與 Preview 排版寫入後再次回歸：頂層 `totalTestCount` 746、通過 745、失敗 1、跳過 0；唯一失敗為既有渲染雜訊 `SnapshotTests/orderEditViewMergeContextBaseline()`，單獨重跑 1/1 通過；完整 bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-22T19-09-05-254Z_pid89516_6a1bb4f3.xcresult`；單獨重跑 bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-22T19-10-12-715Z_pid90512_c179b73e.xcresult`
  - 最後的 Swift 寫入後 iPhone 三個指定 UI 測試類別合併跑 13/13 通過：`FxTests` 3、`QuoteTests` 2、`CurrencyPickerTests` 8；xcresult：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-22T19-10-48-748Z_pid91029_c29e7946.xcresult`
  - review 修正第 1 輪：`QuoteView.swift` 維持 300 行，`QuoteStatusBanner.swift` 92 行、`QuoteBreakdownCard.swift` 129 行；六個 View／元件的分區名稱與順序已修正，無新的畫面差異
  - review 修正後 `QuoteFeatureTests` 20/20 通過；xcresult：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-22T23-12-54-088Z_pid65252_d11e0f61.xcresult`
  - review 修正後 `FxFeatureTests` 11/11 通過；xcresult：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-22T23-14-24-845Z_pid67080_d1202a6e.xcresult`
  - review 修正後四條方法層 snapshot (`fxViewBaseline()`、`fxViewRateFailureBaseline()`、`quoteViewBaseline()`、`quoteViewRateUnavailable()`) 4/4 通過，未重錄；xcresult：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-22T23-14-52-464Z_pid67474_8245a4eb.xcresult`
  - review 修正後最後一次 Swift 寫入後完整單元回歸：`totalTestCount` 746、通過 746、失敗 0、跳過 0，與 746 基準相同；xcresult：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-22T23-15-20-864Z_pid67884_0d76a0d1.xcresult`
  - review 修正第 1 輪的行寬紀錄：本 change 保留的超長行只有 `FxView.swift:214`（匯率顯示字串字面值例外）、`FxStatusBanner.swift:99`（連線狀態字串字面值例外）、`OllamaClientTests.swift:36`（JSON 字串字面值例外），其餘本輪觸及行均需符合 100 字元上限
  - batch5 第 0 項：`FxView.swift` 與 `QuoteView.swift` 的 `keyboardToolbar` 已併回 `Private Views`，刪除空的 `ViewModifier` 分區

## 5. AI 總結

- [x] 5.1 依「AISummary 的金鑰檢查移進 Effect」與「TCA Feature 型別的分區與 Action 分組範本」重整 `AISummaryFeature`：`Action` 分 `view(task, retryTapped, closeTapped)` 與四個串流回應，四個依賴移到 `Dependencies` 區，`Phase`、`StreamResult`、`CancelID` 移到 `Nested Types`，串流與逾時競速抽成 `startStream(state:)`，金鑰讀取與 log 移進 Effect，`APIError.summaryFailureMessage` 改為本 Feature 的 private static 方法 (文案逐字不變)，`catch` 各改單一子句。`AISummaryFeatureTests` 依測試定型一節改寫，`CancellationRecorder` 改 `LockIsolated`，關閉測試移除 `Task.yield()` 輪詢改用 `store.finish()`，刪除窮舉 `receive` 後的冗餘斷言。驗證：缺金鑰測試斷言先 `phase = .streaming` 再收到 `streamFailed` 且文案不變；`grep -rn "summaryFailureMessage" apps/ios/BuyLedger` 只在 `AISummaryFeature.swift`；`AISummaryFeatureTests` 全綠 [after: 1.3]

  - `AISummaryFeatureTests` 6/6 通過；缺金鑰測試先驗證 `.streaming`，再收到 `streamFailed` 與原文案；關閉流程以 `LockIsolated`、`store.finish()` 驗證 dismiss 與取消
  - `summaryFailureMessage` 的 grep 只命中 `Features/AISummary/AISummaryFeature.swift`
- [x] 5.2 讓 `AISummaryView` 符合 View 規則：關閉鍵抽成 `closeToolbarItem`，modifier 依四組排序 (`aiDisclaimerCapsule` 的 `frame` 留在 `background` 外層並加理由註解)，加入串流中、失敗、逾時截斷三個具名 `#Preview`，Preview 移除 `withDependencies`。驗證：UI 測試 `AISummaryTests` 單獨跑全綠 [after: 5.1]

  - `AISummaryTests` 2/2 通過；三個具名 Preview 已建立，且 Preview 未覆寫依賴；result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-22T23-39-03-425Z_pid87640_b036c49a.xcresult`

## 6. 客戶名單與更多

- [x] 6.1 依「客戶名單的 CustomerRow 獨立成檔」與「父層不送子層 action，設定在建立 State 時帶齊」把 `CustomerRow` 搬到 `CustomerRow.swift` (`id` 移到 `Identifiable` extension)，`CustomersFeature` 的 `Action` 分 `view(task, customerTapped)` 與 `delegate(ordersLoadRequested, customerSelected)`，`RootFeature` 改為只攔截這兩個 delegate 並轉發到既有的 `.orders(.task)` 與 `.customerSelected(_:)`。`CustomersFeatureTests` 改以 `.view` 送出並以 case key path 收 delegate、手刻訂單改 `LedgerOrder.fixture`；兩條直接測 `aggregate` 的測試搬到新的 `CustomerRowTests.swift`。驗證：`RootFeatureTests` 的客戶點選與客戶頁載入測試改走 delegate 後全綠；`grep -rn "customers(.task)" apps/ios/BuyLedger` 無輸出 [after: 1.4] [after: 2.4]

  - `CustomersFeatureTests` 4/4、`CustomerRowTests` 2/2、`RootFeatureTests` 36/36 通過，合計 42/42；result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-22T23-49-11-256Z_pid96319_e35db230.xcresult`
  - `customers(.task)` 在 `apps/ios/BuyLedger` 無輸出；Root 客戶點選先收到 child delegate，再轉發既有 `customerSelected`
- [x] 6.2 讓 `CustomersView` 與 `CustomerRankBadgeStyle` 符合 View 規則：`body` 不宣告區域變數 (色盤改 computed property、客戶清單直接讀 store)，`formatDate` 刪除改呼叫 `BLFormatters.shortDate`，點選送 `.view(.customerTapped(name))`，`topHighlightCount` 移到 Properties，modifier 依四組排序並一行一個，加入空狀態 `#Preview`。驗證：`grep -n "func formatDate\|store.send(.delegate" apps/ios/BuyLedger/Features/Customers/CustomersView.swift` 無輸出；UI 測試 `CustomersTests` 單獨跑全綠 [after: 6.1] [after: 1.1]

  - `CustomersFeatureTests` 4/4、`CustomerRowTests` 2/2、`RootFeatureTests` 36/36 通過；前述單元測試合計 42/42
  - `CustomersTests` 4/4 通過；`formatDate` 與 View 直接送 delegate 的 grep 均無輸出，並新增空狀態 Preview；result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-23T00-03-05-064Z_pid7043_ef57ae8d.xcresult`
- [x] 6.3 依「更多頁以 MoreRoute 為唯一來源」刪除 `MoreView.ToolItem` (含無人讀取的 `subtitle`)，標題、圖示、色彩改由以 `RootFeature.MoreRoute` 為輸入的 Private Method 提供，八個 route (七個工具加設定) 的 `NavigationLink` 全部改走 `routeLink(_:)`，`accessibilityKey` 擴充改為 private 方法 `accessibilityRow(for:)`，空重試 closure 的 `BLLoadFailureView` 改不帶按鈕的 `ContentUnavailableView` (沿用既有字串)，`body` 不宣告區域變數。`morePath` 與根 store 不動。驗證：`grep -n "ToolItem\|extension RootFeature.MoreRoute" apps/ios/BuyLedger/Features/More/MoreView.swift` 無輸出；經由更多頁進入各畫面的 UI 測試 `LaunchSmokeTests`、`HarnessSelfCheckTests`、`CurrencyPickerTests` 單獨跑全綠 [after: 0.5]

  - `CurrencyPickerTests` 8/8 通過；result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-23T00-12-40-339Z_pid14247_b1a8e7e9.xcresult`
  - `LaunchSmokeTests` 4/4 通過；result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-23T00-18-14-629Z_pid18412_12b2dadd.xcresult`
  - `HarnessSelfCheckTests` 7/7 通過；result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-23T00-20-21-263Z_pid19988_409cee68.xcresult`
  - `ToolItem`、`subtitle`、`accessibilityKey` 與 `extension RootFeature.MoreRoute` 在 MoreView 均無輸出；八個目的地列均經由 `routeLink(_:)` 建立
  - 最後一次 Swift 寫入後完整 unit regression：`totalTestCount` 748、通過 748、失敗 0、跳過 0；相較 746 基準，新增 `CustomersFeatureTests/customerTappedSendsSelectedDelegate()`、`CustomersFeatureTests/taskDelegatesOrdersLoadRequest()`、`CustomerRowTests` 兩條、`RootFeatureTests/customersLoadDelegateSendsOrdersTask()`，移除舊 Customers aggregate 兩條與 `customerTappedDelegateMutatesNoState()`，淨增 2；result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-23T00-23-45-182Z_pid22639_5e645648.xcresult`
  - 最後一次 Swift 寫入後 iPhone UI：`AISummaryTests` 2/2、`CustomersTests` 4/4、`LaunchSmokeTests` 4/4、`HarnessSelfCheckTests` 7/7，合計 17/17 通過，失敗 0；result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-23T00-26-14-048Z_pid25116_e447087d.xcresult`
  - 類別層 unit 驗證中的 `OrdersFeatureTests` 69/69 通過；result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-23T00-34-20-594Z_pid31165_53f5ab28.xcresult`
  - 回歸前兩次以 `xcodebuildmcp simulator-management set-appearance --simulator-id DDAA3311-B464-4DD3-96B8-360B26AF1929 --mode light --output json` 嘗試鎖定淺色外觀，均因 CoreSimulatorService connection invalid 失敗；`xcodebuildmcp simulator list` 仍確認指定 iPhone 與 iPad 可用，測試命令本身均成功

## 7. 守門與文件

- [x] 7.1 依「新增 Action 分組守門」新增 `ActionGroupingScanTests.swift`，落實「Feature actions are grouped by who is allowed to send them」：已遷移 Feature 的 View 只送 `.view(...)` (以帶理由的 allowlist 豁免 `SettingsView` 的 `.appLock(`)，任何 reducer 不送也不攔截子層的 `.view(...)`。另含 design 表列的掃描器自我測試。驗證：自我測試全綠；兩條規則各做一次變異驗證 (在 `FxView` 加一個手組的 `store.send(.binding(...))`、在 `RootFeature` 加一個 `.send(.settings(.view(.task)))`)，對應測試轉紅、訊息指出檔名與違規寫法、xcresult `totalTestCount` > 0，還原後轉綠；變異與還原的時間記在本 task 下方 [after: 2.5] [after: 3.2] [after: 4.2] [after: 5.2] [after: 6.2] [after: 6.3]

  - A 段修正後 focused unit：`AISummaryFeatureTests`、`CustomersFeatureTests`、`CustomerRowTests` 共 `totalTestCount` 12、通過 12、失敗 0、跳過 0；result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-23T00-48-20-980Z_pid43843_188c49c4.xcresult`
  - `ActionGroupingScanTests` 首次綠燈：`totalTestCount` 5、通過 5、失敗 0、跳過 0；其中 `scannerClassifiesSourceFragments` 含 design 指定 10 組動態案例；result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-23T00-56-48-822Z_pid50808_4e1cde1e.xcresult`
  - FX 變異：在 `FxView` 暫時加入 `store.send(.binding(.set(\.amount, store.amount)))`；2026-09-23T00:57:51Z bundle `totalTestCount` 5、通過 4、失敗 1，失敗訊息指出 `Features/FX/FxView.swift` 與 `.binding(.set(...))`；result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-23T00-57-51-307Z_pid52270_c5622887.xcresult`
  - FX 還原：移除上述暫時送出點後，2026-09-23T00:58:43Z `ActionGroupingScanTests` `totalTestCount` 5、通過 5、失敗 0；result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-23T00-58-43-384Z_pid53439_69dec726.xcresult`
  - Root 第一次放置於大型 reducer body 的變異因 test runner 建立連線前 hang，bundle `totalTestCount` 0，不作為變異通過證據；已還原並改用同一 `RootFeature` 的暫時 private helper 重做
  - Root 變異：在 `RootFeature` 暫時加入 `.send(.settings(.view(.task)))`；2026-09-23T01:06:09Z bundle `totalTestCount` 5、通過 4、失敗 1，失敗訊息指出 `Features/App/RootFeature.swift` 與 `.settings(.view(`；result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-23T01-06-09-506Z_pid59433_fc4ebdfd.xcresult`
  - Root 還原：移除暫時 private helper 後，2026-09-23T01:06:59Z `ActionGroupingScanTests` `totalTestCount` 5、通過 5、失敗 0；result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-23T01-06-59-944Z_pid60168_ab6e7b18.xcresult`
  - 使用者 review comments：`Bundle.appVersionText` 已全數改為 `Bundle.appVersion`／`appVersion(from:)`，測試方法改為 `appVersionFormatsInfoDictionary`；`rg -n "appVersionText" apps/ios` 無輸出 (第 9 批依使用者裁決把 `appVersion(from:)` 內聯並刪除該測試檔，見本檔第 9 批一節)
  - 使用者 review comments：Customers、FX、Quote 三個畫面的同值雙軸 padding 已各合併為 `.padding(BLSpacing.large)`；指定的四條 snapshot 與 `BundleExtensionsTests`、`SettingsFeatureTests` 合併 focused run 為 `totalTestCount` 22、通過 22、失敗 0、跳過 0；result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-23T01-33-03-026Z_pid81577_30c9526c.xcresult`
  - 使用者 review comments：`CustomersTests` 以 `BuyLedgerUITests` scheme 執行，4/4 通過、失敗 0；result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-23T01-41-03-598Z_pid88242_469729bc.xcresult`
  - review 修正：`ActionGroupingScanTests` 已拆為主檔、`ActionGroupingScanTests+Scanner.swift` 與 `ActionGroupingScanTests+Scenarios.swift` (第三檔於第 8 批為恢復案例多行寫法而拆出)；最終 `wc -l` 為 164／290／95，扣除檔頭與空行的非空行為 132／243／81，均低於 300 行
  - review 修正：三個掃描模式改用 Swift Regex literal 與 `matches(of:)`／`firstMatch(of:)`，不再使用 `NSRegularExpression` 或 `try!`；stored pattern 由 `@MainActor` 保護以符合 Swift 6 concurrency-safety
  - review 修正：主檔 `Properties` 在 `Tests` 之前，scanner 依 `Nested Types` → `Computed Properties` → `Private Method` 排列；nested type 內的 `Properties` MARK 已移除；ActionGrouping 與 OllamaClientTests 現存 doc comment 的參數標記前均有空的 `///`
  - review 修正：`apps/ios/CLAUDE.md` 架構分層新增條目的句尾已補全形句號；最新 FxView mutation 紅燈為 `totalTestCount` 5、通過 4、失敗 1，還原後綠燈為 5/5；紅燈 bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-23T01-39-05-461Z_pid86635_b60df288.xcresult`；還原綠燈 bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-23T01-39-52-725Z_pid87294_42fc3a6c.xcresult`
- [x] 7.2 同步文件：`apps/ios/CLAUDE.md` 的「ios-dev-kit 規範與既有差異」登記測試方法維持單段 lowerCamel 與設定寫入維持同步兩條，「架構分層」加入父層不送子層 action、啟動資料在建立子層 State 時帶齊、子層以 delegate 請父層做事三點；`apps/ios/README.md` 更新 `OllamaClient` 的位置與 `SettingsStore` 名稱；`.claude/rules/ios-unit-tests.md` 補測試替身用 `LockIsolated`、不以 `Task.yield` 輪詢，以及 `SettingsStore` 測試用獨立 `UserDefaults` 網域。驗證：`grep -rn "SettingsStorage\|Features/AISummary/.*OllamaClient" apps/ios/CLAUDE.md apps/ios/README.md .claude/rules` 無輸出；新增條目符合根 `CLAUDE.md` 的「只寫現行規則與理由」 [after: 7.1]

  - 文件已同步 `apps/ios/CLAUDE.md`、`apps/ios/README.md`、`.claude/rules/ios-unit-tests.md`；舊名稱與舊路徑 grep 無輸出
  - README 結構已補目前存在的 `Features/FX/Components/` 與 `Features/Quote/Components/`，外部 API 位置為 `Core/Networking/`，設定儲存型別為 `SettingsStore`
  - 新增條目只描述現行規則與理由，未加入事件歷史；`git diff --check` 無輸出
  - 最後一次 Swift 寫入後完整 unit regression：頂層 `totalTestCount` 753、通過 753、失敗 0、跳過 0；相較 batch5 的 748 為新增 ActionGroupingScanTests 的 +5；result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-23T01-13-42-838Z_pid65284_b664dadf.xcresult`
  - 完整回歸後 `find apps/ios -name '*.swift' -newermt '2026-09-23 09:13:42 +0800' -print` 無輸出；確認回歸晚於最後一次 Swift 還原
  - 本輪文件與命名核對：`rg -n "SettingsStorage|Features/AISummary/.*OllamaClient|appVersionText" apps/ios/CLAUDE.md apps/ios/README.md .claude/rules apps/ios` 無輸出；`git diff --check` 無輸出
  - tuple 修正前的中間完整 unit regression：`totalTestCount` 753、通過 753、失敗 0、跳過 0，與 batch5 的 748 相比為 +5；result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-23T01-45-30-549Z_pid91744_624776cc.xcresult`
  - 中間回歸後 `find apps/ios -name '*.swift' -newermt '2026-09-23 09:45:30 +0800' -print` 無輸出；tuple 修正後另行重跑最終回歸
  - tuple 修正後的本批最終完整 unit regression：`totalTestCount` 753、通過 753、失敗 0、跳過 0，與 batch5 的 748 相比為 +5；result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-23T01-50-33-470Z_pid96335_9088915a.xcresult`
  - tuple 修正後首次完整回歸的已知 snapshot 雜訊 `ordersCompactViewMultiSelectBaseline()` 以方法層 selector 單獨重跑為 1/1 通過；result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-23T01-50-05-641Z_pid95940_bc1c141b.xcresult`
  - 最終回歸後 `find apps/ios -name '*.swift' -newermt '2026-09-23 09:50:33 +0800' -print` 無輸出；確認回歸晚於 tuple 修正後最後一次 Swift 寫入

## 8. 驗收

- [x] 8.1 機械與分區檢查 (design 驗收條件 1 至 4)：以 `git status --porcelain` 列出本 change 全部新增與修改的 Swift 檔 (不採用 `spectra scope`)，依 design「檢查範圍分兩組」分成 A 組 (整檔) 與 B 組 (只查 `git diff` 改到的行、宣告與測試)，跑行寬 (python3 按字元)、尾隨空白與 tab、檔頭完整正規表示式、MARK 段名允許清單、頂層分區順序與重複、modifier 跨組順序 (只用 `formatting.md` 表中明列的 modifier)、宣告缺 `///`、`@Test` 的 doc 與三段標記 (標記底下第一個非空行不是 `}` 或另一個標記)、四組單一入口 `grep`。驗證：兩組的檔案清單與每一項的命令、輸出筆數記在本 task 下方，全部為 0；之後逐檔閱讀至少一半的變更檔並列出檔名 [after: 7.2]

  - `git status --porcelain --untracked-files=all | ... '\.swift$'` 列出 52 檔；依 design Context 分為 A 組 40 檔 (23 檔審查基準加全部新增 Swift) 與 B 組 12 檔 (連帶改動既有檔)
  - A 組整檔、B 組 `git diff --unified=0` 改動行的 Python 字元行寬檢查：原始超長 3 筆，均為既定單一字串字面值例外 `Features/FX/Components/FxStatusBanner.swift:99`、`Features/FX/FxView.swift:213`、`BuyLedgerTests/OllamaClientTests.swift:36`；扣除例外 0 筆
  - 同一範圍的尾隨空白 0、Tab 0、檔頭第 5 行 `^//  Created by Leo Ho on \d{4}/\d{1,2}/\d{1,2}\.$` 不符 0
  - A 組 MARK allowlist 0、nested type 內 MARK 0、頂層分區重複候選 0、分區順序逆序候選 0；modifier 機械檢查原始 1 筆，唯一命中是 design 明文保留的 `AISummaryView.aiDisclaimerCapsule` `frame` 位於 `background` 外層，宣告例外後 actionable 0
  - 作用域內宣告缺 `///` 0、doc summary 與參數區之間缺空 `///` 0、`@Test` 缺 doc 0、`@Test` 缺 Given／When／Then 或 When／Then 後第一個非空行不合法 0
  - 四組單一入口檢查：`rg -n 'func formatDate|showsCurrencySheet|SettingsStorage' apps/ios --glob '*.swift'` 0；`rg -n 'summaryFailureMessage\(for' apps/ios --glob '*.swift'` 只命中 `AISummaryFeature.swift` 2 處；`useAiSummary` 的直接引用只在 design 明列的 UI test harness／其覆寫與測試，UserDefaults key 字串另保留；`rg -n 'month\(\.defaultDigits\)' apps/ios --glob '*.swift'` 2 處且只在 `BLFormatters.swift`／`FxFormatters.swift`
  - `python3` 逐檔讀取本次全部 52 個變更 Swift 檔，已超過至少一半要求；檔名清單：`BuyLedgerApp.swift`、`BLUITestDependencyOverrides.swift`、`FxRateSnapshot.swift`、`OllamaChatRequest.swift`、`OllamaChatResponse.swift`、`OllamaClient.swift`、`AISummaryFeature.swift`、`AISummaryView.swift`、`RootFeature.swift`、`CustomerRankBadgeStyle.swift`、`CustomerRow.swift`、`CustomersFeature.swift`、`CustomersView.swift`、`FxRatesList.swift`、`FxStatusBanner.swift`、`FxFeature.swift`、`FxFormatters.swift`、`FxView.swift`、`MoreView.swift`、`OrderFormatters.swift`、`OrdersFeature.swift`、`QuoteBreakdownCard.swift`、`QuoteStatusBanner.swift`、`QuoteFeature+Destination.swift`、`QuoteFeature.swift`、`QuoteView.swift`、`AISummaryModelCatalog.swift`、`SettingsFeature.swift`、`SettingsSnapshot.swift`、`SettingsStore.swift`、`SettingsView.swift`、`BLFormatters.swift`、`Bundle+Extensions.swift`、`AISummaryFeatureTests.swift`、`ActionGroupingScanTests+Scanner.swift`、`ActionGroupingScanTests+Scenarios.swift`、`ActionGroupingScanTests.swift`、`AppLanguageTests.swift`、`BLFormattersTests.swift`、`BundleExtensionsTests.swift`、`CustomerRowTests.swift`、`CustomersFeatureTests.swift`、`FxFeatureTests.swift`、`FxRateSnapshotTests.swift`、`LedgerOrder+Fixture.swift`、`OllamaClientTests.swift`、`OrdersFeatureTests.swift`、`QuoteFeatureTests.swift`、`RootFeatureTests.swift`、`SettingsFeatureTests.swift`、`SettingsStoreTests.swift`、`SnapshotTests.swift`
- [x] 8.2 `findings.md` 491 筆全部有結論，「判讀級 findings 的逐筆處置」表的處置方向與結論一致，預填結論未被改掉。驗證：`grep -c "結論：待填" findings.md` 為 0，結論總數 491 [after: 8.1]

  - 原始 findings 區段的 `^- L` 項目數 491；逐筆區塊含 `結論：` 491，缺結論 0，`結論：待填` 0
  - 文件全體的結論行為 512，其中原始 491 筆加上 Batch6／Batch7 補充核對摘要的 21 行；驗收對象的原始 findings 491 筆結論總數為 491
  - design「判讀級 findings 的逐筆處置」表逐項以目前結論核對：不修項目均保留 `不修`／已登記例外理由，應修項目均以 `已修正`／任務涵蓋收斂；預填結論區塊未在本批改寫
- [x] 8.3 完整單元回歸 (design 驗收條件 6)：鎖淺色外觀並確認成功後，以 `BuyLedger.xctestplan` 跑完整回歸。驗證：本 task 下方記錄頂層 `totalTestCount`、通過數、失敗清單與 bundle 路徑；測試數不少於 0.2 基準加上本步新增數、失敗清單是 0.2 的子集；每條 snapshot 失敗都以方法層 `-only-testing` (帶 `()` ) 單獨重跑並記錄 `totalTestCount`；xcresult 時間晚於最後一次 Swift 寫入 (以 `find apps/ios -name '*.swift' -newermt <xcresult 時間>` 無輸出證明) [after: 8.2]

  - 2026-09-23，完整回歸前以 `xcodebuildmcp simulator-management set-appearance --simulator-id DDAA3311-B464-4DD3-96B8-360B26AF1929 --mode light --output json` 重試，仍因 `CoreSimulatorService connection invalid` 失敗；指定 iPhone 與 iPad 的 XcodeBuildMCP 測試流程仍可執行，外觀鎖定成功前不將本項標為完成
  - 完整 unit regression：透過 XcodeBuildMCP `test_sim` 使用 `BuyLedger` scheme；`xcrun xcresulttool get test-results summary --path <bundle>` 頂層 `totalTestCount` 753、通過 753、失敗 0、跳過 0、result `Passed`；result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-23T02-16-49-132Z_pid29101_2a425efe.xcresult`
  - 測試數相對 0.2 基準 731 的 `+22` 由既有回歸節點組成：731→738 `+7`、738→743 `+5`、743→746 `+3`、746→748 `+2`、748→753 `+5`；最後一段是本批 `ActionGroupingScanTests` 的 5 條測試，未刪減基準測試
  - 最終失敗清單為空，是 0.2 已知失敗 `orderEditViewBaseline()`、`quoteViewBaseline()` 的子集；本次沒有 snapshot failure，無需新增方法層重跑；0.2 的兩條已知 snapshot noise 仍各以帶 `()` 的方法 selector 單獨重跑並通過
  - 回歸後執行 `find apps/ios -name '*.swift' -newermt '2026-09-23 10:16:49 +0800' -print`，無輸出；確認 xcresult 晚於最後一次 Swift 寫入
  - 外觀設定後重新執行 `xcodebuildmcp simulator-management set-appearance --simulator-id DDAA3311-B464-4DD3-96B8-360B26AF1929 --mode light --output json`，輸出 `didError: false`、`status: SUCCEEDED`
  - 外觀成功後以 XcodeBuildMCP `test_sim` 執行 `BuyLedger` scheme；`BuyLedger.xcodeproj/xcshareddata/xcschemes/BuyLedger.xcscheme` 明確引用 `container:BuyLedger.xctestplan`
  - `xcrun xcresulttool get test-results summary` 頂層 `totalTestCount` 753、通過 752、失敗 1、跳過 0、result `Failed`；唯一失敗為已知 snapshot noise `BuyLedgerTests/SnapshotTests/ordersCompactViewMultiSelectBaseline()`；result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-23T05-08-58-871Z_pid29101_cdc83101.xcresult`
  - 測試數相對 0.2 基準 731 為 `+22`，且 753 不少於基準加本步新增 5 條；唯一失敗是 0.2 已知 snapshot failure 的子集
  - 以 `-only-testing:BuyLedgerTests/SnapshotTests/ordersCompactViewMultiSelectBaseline()` 方法層 selector 單獨重跑，`totalTestCount` 1、通過 1、失敗 0、跳過 0；result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-23T05-10-42-929Z_pid29101_50d50fbc.xcresult`
  - 以 `find apps/ios -name '*.swift' -newermt '2026-09-23 13:08:58 +0800' -print` 檢查回歸後較新的 Swift 檔，無輸出
- [x] 8.4 UI 回歸 (design 驗收條件 7)：iPhone 與 iPad 各跑一次 `BuyLedgerUITests` 主回歸。驗證：兩台結果不比 0.3 基準差，數字、失敗清單與 bundle 路徑記在本 task 下方，執行時間晚於最後一次 Swift 寫入 [after: 8.3]

  - iPad 軟體鍵盤前置確認：`KeyboardDismissTests` `totalTestCount` 2、通過 2、失敗 0、跳過 0；鍵盤顯示與收起兩條測試均通過；result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-23T02-21-20-751Z_pid29101_93f61c57.xcresult`
  - iPhone 主回歸命令：`xcodebuildmcp simulator test --project-path apps/ios/BuyLedger.xcodeproj --scheme BuyLedgerUITests --simulator-id DDAA3311-B464-4DD3-96B8-360B26AF1929 --extra-args=-only-testing:BuyLedgerUITests --extra-args=-skip-testing:BuyLedgerUITests/LaunchPerformanceTests --progress=false --output json`；頂層 `totalTestCount` 64、通過 64、失敗 0、跳過 0、失敗清單空；result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-23T03-10-06-548Z_pid59755_efd0f810.xcresult`
  - iPad 主回歸命令：`xcodebuildmcp simulator test --project-path apps/ios/BuyLedger.xcodeproj --scheme BuyLedgerUITests --simulator-id 6B65ED1C-3C2E-42BA-B1E7-08F606F175C5 --extra-args=-only-testing:BuyLedgerUITests --extra-args=-skip-testing:BuyLedgerUITests/LaunchPerformanceTests --progress=false --output json`；頂層 `totalTestCount` 64、通過 64、失敗 0、跳過 0、失敗清單空；result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-23T03-43-30-144Z_pid83610_d986e464.xcresult`
  - 兩台均達到 0.3 基準 64/64，且測試均在最後一次 Swift 寫入與 unit regression 後執行；iPhone 第一次重跑因 MCP 逾時後背景程序與 CLI 重疊而捨棄，清除競爭後以單一 CLI 程序重新取得上述 64/64
- [x] 8.5 畫面比對 (design 驗收條件 8)：以 0.4 記錄的啟動參數與操作步驟重新截圖，存到 `/private/tmp/buyledger-step3-screens/after/` 同名檔，逐張與 `before/` 比對。驗證：每張的比對結論記在本 task 下方，除了 design「Implementation Contract」宣告的改變以外沒有差異；有差異就改回程式碼，不得以「預期」帶過 [after: 8.4]

  - 截圖前在 `apps/ios` 執行 `agvtool next-version`，建置號由 355 遞增為 356；再以 XcodeBuildMCP `build-and-run` 建置並以 `-BLUITest -BLUITestSeed fullOrders -BLUITestNow 2026-04-26T08:00:00Z` 啟動，AI 畫面追加 `-BLUITestAiSummary`
  - 六張 after 與 before 均為 368×800，存放於 `/private/tmp/buyledger-step3-screens/after/01-fx.png`、`02-quote.png`、`03-settings.png`、`04-customers.png`、`05-more.png`、`06-ai-summary.png`
  - rs/1 語意快照在當前 XcodeBuildMCP 環境只回傳零尺寸 application 節點，無法提供既定 elementRef；改用現有 UI test Page Object 逐條重現 0.4 路徑，測試停在目標畫面時以 `xcodebuildmcp ui-automation screenshot` 擷取，暫時導覽測試已還原且未留在工作樹
  - 以 Python Pillow 將每張 before/after 排除狀態列後縮小、模糊並逐像素比較，六張均為 `content_mean_abs_diff=0.00`、`content_pixels_over_12=0/17112`；設定頁兩張均顯示月度目標 `80000`，代表 80,000 預設值
  - `01-fx.png`：`dashboard.root → root.tab.more → more.root → more.row.fx → fx.root`；after 與 before 的匯率、金額、匯率列表及版面一致，只有狀態列時間不同；導覽測試 1/1 通過，bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-23T04-57-58-303Z_pid41404_e0403d36.xcresult`
  - `02-quote.png`：`fx.root → more.root → more.row.quote → quote.root`；after 與 before 的輸入列、建議售價卡、成本拆解版面一致，只有狀態列時間不同；導覽測試 1/1 通過，bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-23T04-59-33-187Z_pid42645_e999c10a.xcresult`
  - `03-settings.png`：`quote.root → more.root → more.row.settings → settings.root`；月度目標採用宣告的 80,000 預設值，畫面欄位以 `80000` 顯示，其餘設定內容與版面一致，只有狀態列時間不同；導覽測試 1/1 通過，bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-23T05-00-59-917Z_pid43784_3b3bfd24.xcresult`
  - `04-customers.png`：`settings.root → more.root → more.row.customers → customers.list.root`；客戶排行、金額、日期與列表版面一致，只有狀態列時間不同；導覽測試 1/1 通過，bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-23T05-02-27-652Z_pid44931_ca250f02.xcresult`
  - `05-more.png`：`dashboard.root → root.tab.more → more.root`；工具、管理、App 三組列與底部導覽版面一致，只有狀態列時間不同；導覽測試 1/1 通過，bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-23T05-04-01-369Z_pid46149_dad913e7.xcresult`
  - `06-ai-summary.png`：`dashboard.root → root.tab.orders → orders.list.root → orders.list.batchMenuButton → orders.list.aiSummaryButton → aiSummary.root`；訂單背景、sheet 內容及遮罩一致，只有狀態列時間不同；導覽測試 1/1 通過，bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-23T05-05-28-500Z_pid47308_d78b2a91.xcresult`
  - 六張一般狀態圖均未呈現幣別 picker，故沒有未宣告的 picker 列標題差異；其標題規則已由既有 `CurrencyPickerTests` 8/8 覆蓋
- [x] 8.6 `spectra validate small-features-style-compliance` 通過，工作樹變更範圍全在 design「範圍邊界」內。驗證：validate 輸出與 `git status --porcelain` 清單記在本 task 下方 [after: 8.5]

  - `spectra validate small-features-style-compliance`：`✓ small-features-style-compliance — valid`
  - 範圍核對：變更均落在 proposal Impact 清單、本 change 目錄文件，或 design 明確允許的 `project.pbxproj` 建置號遞增；暫時 UI 導覽檔已還原，沒有清單外的持久檔案
  - 最終 `git status --porcelain --untracked-files=all`：

    ```text
     M .claude/rules/ios-unit-tests.md
     M apps/ios/BuyLedger.xcodeproj/project.pbxproj
     M apps/ios/BuyLedger/App/BuyLedgerApp.swift
     M apps/ios/BuyLedger/App/Testing/BLUITestDependencyOverrides.swift
     M apps/ios/BuyLedger/Core/Domain/FxRateSnapshot.swift
     M apps/ios/BuyLedger/Features/AISummary/AISummaryFeature.swift
     M apps/ios/BuyLedger/Features/AISummary/AISummaryView.swift
     D apps/ios/BuyLedger/Features/AISummary/OllamaClient.swift
     D apps/ios/BuyLedger/Features/AISummary/OllamaDTO.swift
     M apps/ios/BuyLedger/Features/App/RootFeature.swift
     M apps/ios/BuyLedger/Features/Customers/CustomerRankBadgeStyle.swift
     M apps/ios/BuyLedger/Features/Customers/CustomersFeature.swift
     M apps/ios/BuyLedger/Features/Customers/CustomersView.swift
     M apps/ios/BuyLedger/Features/FX/FxFeature.swift
     M apps/ios/BuyLedger/Features/FX/FxView.swift
     M apps/ios/BuyLedger/Features/More/MoreView.swift
     M apps/ios/BuyLedger/Features/Orders/Components/OrderFormatters.swift
     M apps/ios/BuyLedger/Features/Orders/OrdersFeature.swift
     M apps/ios/BuyLedger/Features/Quote/QuoteFeature.swift
     M apps/ios/BuyLedger/Features/Quote/QuoteView.swift
     M apps/ios/BuyLedger/Features/Settings/AISummaryModelCatalog.swift
     M apps/ios/BuyLedger/Features/Settings/SettingsFeature.swift
     M apps/ios/BuyLedger/Features/Settings/SettingsSnapshot.swift
     D apps/ios/BuyLedger/Features/Settings/SettingsStorage.swift
     M apps/ios/BuyLedger/Features/Settings/SettingsView.swift
     M apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLFormatters.swift
     M apps/ios/BuyLedger/Shared/Extensions/Bundle+Extensions.swift
     M apps/ios/BuyLedgerTests/AISummaryFeatureTests.swift
     M apps/ios/BuyLedgerTests/BLFormattersTests.swift
     M apps/ios/BuyLedgerTests/CustomersFeatureTests.swift
     M apps/ios/BuyLedgerTests/FxFeatureTests.swift
     M apps/ios/BuyLedgerTests/OllamaClientTests.swift
     M apps/ios/BuyLedgerTests/OrdersFeatureTests.swift
     M apps/ios/BuyLedgerTests/QuoteFeatureTests.swift
     M apps/ios/BuyLedgerTests/RootFeatureTests.swift
     M apps/ios/BuyLedgerTests/SettingsFeatureTests.swift
     M apps/ios/BuyLedgerTests/SnapshotTests.swift
     M apps/ios/CLAUDE.md
     M apps/ios/README.md
     ?? apps/ios/BuyLedger/Core/Networking/OllamaChatRequest.swift
     ?? apps/ios/BuyLedger/Core/Networking/OllamaChatResponse.swift
     ?? apps/ios/BuyLedger/Core/Networking/OllamaClient.swift
     ?? apps/ios/BuyLedger/Features/Customers/CustomerRow.swift
     ?? apps/ios/BuyLedger/Features/FX/Components/FxRatesList.swift
     ?? apps/ios/BuyLedger/Features/FX/Components/FxStatusBanner.swift
     ?? apps/ios/BuyLedger/Features/FX/FxFormatters.swift
     ?? apps/ios/BuyLedger/Features/Quote/Components/QuoteBreakdownCard.swift
     ?? apps/ios/BuyLedger/Features/Quote/Components/QuoteStatusBanner.swift
     ?? apps/ios/BuyLedger/Features/Quote/QuoteFeature+Destination.swift
     ?? apps/ios/BuyLedger/Features/Settings/SettingsStore.swift
     ?? apps/ios/BuyLedgerTests/ActionGroupingScanTests+Scanner.swift
     ?? apps/ios/BuyLedgerTests/ActionGroupingScanTests+Scenarios.swift
     ?? apps/ios/BuyLedgerTests/ActionGroupingScanTests.swift
     ?? apps/ios/BuyLedgerTests/AppLanguageTests.swift
     ?? apps/ios/BuyLedgerTests/BundleExtensionsTests.swift
     ?? apps/ios/BuyLedgerTests/CustomerRowTests.swift
     ?? apps/ios/BuyLedgerTests/FxRateSnapshotTests.swift
     ?? apps/ios/BuyLedgerTests/LedgerOrder+Fixture.swift
     ?? apps/ios/BuyLedgerTests/SettingsStoreTests.swift
     ?? apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/fxViewBaseline.1.png
     ?? apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/fxViewRateFailureBaseline.1.png
     ?? openspec/changes/small-features-style-compliance/.openspec.yaml
     ?? openspec/changes/small-features-style-compliance/design.md
     ?? openspec/changes/small-features-style-compliance/findings.md
     ?? openspec/changes/small-features-style-compliance/proposal.md
     ?? openspec/changes/small-features-style-compliance/specs/ai-order-summary/spec.md
     ?? openspec/changes/small-features-style-compliance/specs/app-layer-boundaries/spec.md
     ?? openspec/changes/small-features-style-compliance/specs/app-settings/spec.md
     ?? openspec/changes/small-features-style-compliance/tasks.md
    ```

## 第 9 批：使用者 diff review comments (2026-09-23)

使用者在 diff 上留了五類重點式 comment，並指定「不只挑出來的這幾行」，因此每一類都在本次 diff 的新增行內全域掃描後修正。

- **宣告的大括號本體不得壓成單行** (`QuoteFeature.swift:73` 與 `:78` 的 comment)：掃描本次新增行，7 處單行 `guard ... else { ... }` 與 3 處單行 computed property 本體全部展開。作為引數傳入的 inline closure (`map { $0.id }`) 依 `formatting.md` 維持單行，不在此規則內。
  - 檔案分布：`QuoteFeature.swift` (1 guard + 3 computed，隨計算屬性一起搬到新檔)、`QuoteView.swift` (1 guard)、`ActionGroupingScanTests+Scanner.swift` (5 guard)。
  - `QuoteFeature.swift` 展開後會從 298 行增至 304 行、超過 300 行上限，依 `formatting.md` 的 `<Name>+<Domain>.swift` 分檔規則把 `State` 的計算屬性整組移到新檔 `QuoteFeature+Calculation.swift` (`extension QuoteFeature.State`)；主檔降為 215 行、新檔 93 行 (非空行、不含檔頭)。`heroMessage` 的回傳型別在跨檔 extension 內須寫成 `QuoteFeature.HeroMessage`，否則編譯錯誤 `cannot find type 'HeroMessage' in scope`。
- **屬性包裝器與宣告同行** (`QuoteFeature.swift:218` 的「排版凸出去了」)：本次改動把 12 處 `@Dependency(...)` 拆成兩行，與全庫既有 65 處單行寫法不一致，已全部合回單行 (合併後最長 90 字元，未超過 100)。分布：`AISummaryFeature` 4、`FxFeature` 2、`QuoteFeature` 2、`SettingsFeature` 2、`OrdersFeature` 1、`OllamaClient` 1。
  - `PersistenceFailureFeature.swift:59` 的拆行屬本 change 範圍外的既有寫法，未動。
- **檔頭建立日期不得更動** (`QuoteView.swift:5` 的 comment)：`QuoteView.swift` 由 `2026/5/1` 被改為 `2026/9/23`，已還原。全檔頭 diff 重掃後無其他日期變動；由既有檔拆分而來的新檔 (`OllamaChatRequest`／`OllamaChatResponse`) 給新日期，沿用第 1 步 `ExchangeRateLatestResponse` 的先例；純移動的檔 (`OllamaClient` 2026/5/27、`SettingsStore` 2026/5/31) 保留原日期，正確。
- **由外部注入的 State 值用 `let` 且宣告處不給預設值** (`SettingsFeature.swift:46` 的 comment)：`var appVersion: String = "—"` 改為 `let appVersion: String`，值只由 `init(snapshot:appVersion:)` 帶入。`init` 參數保留 `= "—"` 預設值，因為 `SettingsFeature.State()` 有 14 個無參數呼叫點 (含 `RootFeature.State` 的兩處預設值與 `SettingsView` 的 Preview)。
- **不為單一呼叫點抽出 helper method** (`Bundle+Extensions.swift:39` 的 comment)：`Bundle.appVersion(from:)` 內聯進 `Bundle.appVersion` computed property，`// MARK: - Internal Method` 分區整個移除。
  - 連帶刪除 `BuyLedgerTests/BundleExtensionsTests.swift`：它唯一的測試對象就是被內聯掉的純函式，內聯後只能對 `Bundle.main` 做「非空」之類的弱斷言，屬假測試。單元測試總數因此由 753 降為 752。
  - 已確認 diff 內沒有第二個同型案例：`FxRateSnapshot.twdRate(for:)`、`FxFormatters.rate`、`FxFeature.State.displayRate(for:)` 各有兩個以上 production 呼叫點，屬真正的共用 helper。

### 本批驗證

- 掃描器重跑：單行 `guard`／computed／`func` 本體與 `@Dependency` 拆行在本次新增行內皆為 0。
- 機械檢查重跑 (52 檔)：行寬、尾隨空白、檔頭、MARK 段名與順序、缺 `///` 的結果與第 8 批相同，只剩三筆單一字串字面值的寬度例外 (`FxStatusBanner.swift` L99 105、`FxView.swift` L213 105、`OllamaClientTests.swift` L36 116) 與兩筆已知誤報。
- 完整單元回歸：`xcrun xcresulttool get test-results summary` 頂層 `totalTestCount` 752、通過 752、失敗 0、跳過 0；相對第 8 批的 753／752／1，測試數 -1 (刪除 `BundleExtensionsTests`)、失敗 -1 (第 8 批的 `ordersCompactViewMultiSelectBaseline` 像素雜訊本次未重現)。result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-23T11-10-13-732Z_pid9619_9fbc1545.xcresult`；`find apps/ios -name '*.swift' -newermt '2026-09-23 19:10:12'` 無輸出，證明回歸晚於最後一次 Swift 寫入。
- UI 主回歸 (命令同 8.4，`--scheme BuyLedgerUITests`)：iPhone 17 `totalTestCount` 64、通過 64、失敗 0；iPad Air 11-inch (M4) `totalTestCount` 64、通過 64、失敗 0，與 0.3 基準相同。result bundle：iPhone `/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-23T11-13-52-921Z_pid14511_a74c3d4b.xcresult`、iPad `/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-23T11-47-38-227Z_pid43178_006867a8.xcresult`。
- 畫面未重新截圖：本批唯二動到畫面的 FX 與報價都有 snapshot 基準圖 (`fxViewBaseline`、`fxViewRateFailureBaseline`、`quoteViewBaseline`、`quoteViewRateUnavailable`)，四條在 752/752 內全綠，即版面未變的證據；設定頁的改動只是 `var` 改 `let`，顯示值相同。
- `spectra validate small-features-style-compliance` 通過；檔案清單仍為 69 個路徑 (新增 `QuoteFeature+Calculation.swift`、刪除 `BundleExtensionsTests.swift`，一增一減)。

### 第 9 批後續：使用者手動排版與 `/ios-dev-kit` 審查 (2026-09-23)

使用者在第 9 批驗證完成後逐一手動調整排版，之後要求以 `/ios-dev-kit` 審查現況。審查列出 B1 至 B4 與 S1，處置如下。

- **B1 尾隨空白 78 處、12 檔 (已清)**：手動排版帶進兩種樣貌，參數換行後逗號帶空格 (`"商品定價", `) 與 `switch` case 之間空行殘留縮排。以 `sed -i '' 's/[[:space:]]*$//'` 清除，範圍限定本次變更的 52 個 Swift 檔。
- **B2 行寬超過 100 兩處 (已清)**：`OrdersFeature.swift` 的 `fetchReconciliationStatuses()` 呼叫 (110) 與 `send(.mergeConfirmationReady(...))` (106) 被改回單行，依 `formatting.md` 的續行縮排 4 格與右括號獨立一行改回換行。
- **B3 破折號字元 (已改)**：`Bundle.appVersion` 的缺值輸出由半形 `"-"` 改回全形 `"—"` (U+2014)，與全庫其餘 8 處空狀態一致。全庫半形 `"-"` 只剩 `BLUITestConfiguration` 的 `hasPrefix("-")`，屬啟動參數判斷，不動。
- **B4 缺值時整串顯示「—」(使用者裁決保留)**：原設計是短版號與建置號各自獨立替代 (`1.7.0 (—)`)，手動改成任一缺值即整串「—」。使用者確認保留，design 的「App 版本字串」一節與輸出對照表、task 2.3 的敘述已同步改寫。
- **S1 closure 參數列獨立一行 (使用者裁決採慣例寫法，本 change 範圍內已改)**：`SettingsFeature.swift` 的 `merged.sorted` 改為 `sorted { lhs, rhs in`，參數列與 `{` 同行。規則已登記進 `apps/ios/CLAUDE.md`。
  - 全庫同型另有 5 處，依「機械規則碰到哪個檔修哪個檔」留給各自步驟：`CampaignListView.swift:224` (第 5 步)、`OrderEditView.swift:722` (第 6 步)、`DashboardView.swift:147` 與 `:605`、`InsightsView.swift:311` (第 7 步)。

另同步更正 design 與 proposal 中已被裁決推翻的敘述：design 的「`@Dependency(...)` 與 `private var name` 分兩行」改為維持同一行 (第 9 批的使用者裁決)，proposal 的 Impact 把 `BundleExtensionsTests.swift` 由新增清單移到移除清單。

**本輪驗證** (每次改檔後都重跑)：完整單元回歸 `totalTestCount` 752、通過 752、失敗 0、跳過 0，最後一次 result bundle `/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-23T13-03-46-297Z_pid10435_1796f346.xcresult`，`find apps/ios -name '*.swift' -newermt '2026-09-23 21:03:44'` 無輸出。機械掃描回到乾淨基準：尾隨空白 0、行寬只剩三筆單一字串字面值例外、缺 `///` 只剩兩筆已知誤報 (`BuyLedgerApp:38` 是 `init()` 內區域變數、`BLFormattersTests:90` 是多行 `@Test(arguments:)`)。UI 回歸未重跑，因為本輪只動排版、破折號字元與版本字串的缺值分支，UI 測試沒有斷言版本字串。

### 第 10 批：`/ios-dev-kit` 分區審查與後續處置 (2026-09-23)

使用者要求以 `/ios-dev-kit` 逐檔 (不抽查) 審查全部變更檔的 MARK 分區。55 檔逐一列出實際分區比對，另把 B 組檔案中本次 diff 有改到的 MARK 行單獨列出核對 (10 行全部合規)。**MARK 分區本身 0 問題**；先前掃描器把「型別本體內的 MARK」誤判為巢狀，判定條件已改為 `indent > 4`。查實過程另抓到四項，逐項處置如下。

- **M1 四個新增元件檔缺 `Preview` 分區 (已補)**：`file-templates.md`「`#Preview` 必備」與本 design L153「含本步新增的多狀態 `#Preview`」都要求。`FxStatusBanner` 補三種 (載入中／已連線／載入失敗)、`FxRatesList` 補兩種、`QuoteStatusBanner` 補三種、`QuoteBreakdownCard` 補兩種。
- **M2 `QuoteFeature+Calculation.swift` 把 State 衍生值移出 State (已改，使用者裁決拆子 Feature)**：原作法違反 `tca-architecture.md`「能從其他狀態算出的值放同一個 `State` 內」與本 design L67 的決策。依 `tca-architecture.md` 拆分順序第 2 步抽出 `QuoteRateFeature`，以 `Scope` 組合。
  - `QuoteRateFeature.State` 收 `fromCurrency`、`snapshot`、`isLoading`、`errorMessage`、`availableCurrencies`、`@Presents destination` 與三個衍生值 (`rate`／`hasUsableRate`／`rateUnavailableReason`)；計算屬性全部搬回 `QuoteFeature.State` 內、stored 之後。
  - **`QuoteRateFeature.Action` 刻意不設 `view` 分組**：它沒有自己的 View，事件一律由 `QuoteFeature` 轉送 (`task`／`refreshRequested`／`pickerTapped`／`currencySelected`)，父層轉送的因此不是子層 `.view`，不觸犯 `ActionGroupingScanTests` 規則二。
  - `Destination` 移到 `QuoteRateFeature`、`HeroMessage` 留 `QuoteFeature` 的 `Nested Types`；刪除 `QuoteFeature+Calculation.swift` 與 `QuoteFeature+Destination.swift`。跨檔 extension 內引用兄弟巢狀型別要寫全名，`heroMessage` 一度因只寫 `HeroMessage` 而編譯失敗。
  - 連帶更新 `QuoteView` (10 處)、`QuoteFeatureTests` (22 處 State 建構，動作流程改走 `receive(\.rateSource.…)`)、`SnapshotTests` (2 處)。
- **M3 `ActionGroupingScanTests+Scenarios.swift` 整檔無 MARK (已補)**：檔內是 `struct ScanScenario` 巢狀型別，補 `// MARK: - Nested Types`，與姊妹檔 `+Scanner.swift` 一致。
- **M4 300 行上限違規 2 檔 (已修)**：`QuoteView` 336 行、`CustomersView` 304 行，違反本 design 的 Goal「每個 View 檔不超過 300 行」與 L153。成因是使用者手動把多參數呼叫改成一參數一行。
  - `QuoteView` 抽出 `Components/QuoteInputsCard.swift` (幣別列 + 七個數值輸入欄 + `numberField`)，主檔降至 213 行。
  - `CustomersView` 抽出 `Components/CustomerTopCard.swift` (Top 卡片 + 名次膠囊)，降至 221 行。
  - 使用者追問後再抽 `Components/CustomerListRow.swift` (單列呈現)，降至 174 行：理由是它與 `CustomerTopCard` 是同一份資料的兩種版面，一個在 `Components/`、一個留在 View 內會在改分級配色時漏改一邊。`topThree`／`customerList`／`emptyState`／`content` 評估後保留，因為它們剩下的內容是 `ForEach` 加 Button 包裝與三個無障礙屬性，都要送 `store.send(...)`，抽出去會讓 closure 與無障礙屬性一路往下傳。
  - 順帶收掉一處跨層寫死：`customerList` 原本以 `BLSpacing.large + customerAvatarSize + BLSpacing.small` 手算列內版面，改由 `CustomerListRow.dividerInset(avatarSize:)` 推導，頭像基準尺寸的單一來源是 `CustomerListRow.avatarSize`。

### 第 10 批驗證

- 完整單元回歸 (每次改檔後重跑，最後一次於分區順序修正後)：`totalTestCount` 752、通過 752、失敗 0、跳過 0；result bundle `/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-23T15-01-16-905Z_pid9888_f89a29d6.xcresult`；`find apps/ios -name '*.swift' -newermt '2026-09-23 23:01:14'` 無輸出。`quoteViewBaseline` 與 `quoteViewRateUnavailable` 全程綠燈，是 `QuoteView` 版面未因拆子 Feature 與抽元件而改變的證據。
- 機械掃描：尾隨空白 0、MARK 分區 0、單行大括號本體與 `@Dependency` 拆行 0，行寬只剩三筆單一字串字面值例外。
- A 組全部檔案 300 行上限逐檔量測，無超標。
- UI 主回歸 (抽出 `CustomerListRow` 之後重跑，涵蓋本批全部 View 結構變更)：iPhone 17 `totalTestCount` 64、通過 64、失敗 0；iPad Air 11-inch (M4) `totalTestCount` 64、通過 64、失敗 0，與 0.3 基準相同。result bundle：iPhone `/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-23T15-03-22-939Z_pid11888_d05f6921.xcresult`、iPad `/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-23T15-37-10-421Z_pid36370_f9bedcf5.xcresult`；`find apps/ios -name '*.swift' -newermt '2026-09-23 23:03:21'` 無輸出。

### 第 11 批：`/ios-dev-kit` 內容感知分區審查 (2026-09-24)

使用者指出第 10 批回報的「MARK 分區 0 問題」不實。根因是稽核腳本**只比對 MARK 名稱與順序，不檢查區塊內實際放了什麼**，另有一個「同檔多個頂層型別時把所有 MARK 當成一串」的誤判。兩個缺陷都已修正 (`mark_content.py` 新增內容感知檢查；`mark_audit.py` 遇到開頭區名即重設順序基準)，重掃後處置如下。

- **A2 View 不該有 `Computed Properties` 分區 (使用者裁決照樣板改)**：`tca-architecture.md` 的 View 一節與 `file-templates.md` 的 `presentation/View.swift` 一節都把 View 分區寫死為 Properties → (Init) → Body → Private Views → Nested Types → Private Method → Preview，樣板檔 `tca/FeatureView.swift` 的插槽亦同，**都沒有 `Computed Properties`**；鐵則 9 是「不自創分區名稱」。第 2 步的 design 把 `formatting.md` 的通用六區與 View 專屬順序混用，訂出含 `Computed Properties` 的 View 順序，是本次偏差的來源。
  - 11 個 View 檔處置：`FxRatesList`、`MoreView` 原本把 `palette` 與其他計算拆在兩個 extension (違反「避免同一區塊拆成兩個 extension」)，合併為單一 `Private Method`；`CustomerTopCard`、`CustomersView`、`FxView`、`QuoteBreakdownCard`、`QuoteInputsCard`、`QuoteStatusBanner`、`QuoteView` 區名改為 `Private Method`；`CustomerListRow` 另調整為 `Internal Method` → `Private Method`。
  - **A1 (computed property 放在 `Private Method`) 因此自然消解**：照樣板改之後 `Private Method` 就是 View 內純 UI 計算的唯一歸宿，`FxRatesList.rateSourceSubtitle` 與 `SettingsView.appLockToggleBinding` 留在該區即為正確。
  - 規則已寫入 `apps/ios/CLAUDE.md`。第 2 步已提交的 10 個 `Shared/DesignSystem/` View 檔仍有此分區，留給第 10 步。
- **`RootFeature` 與 `OrdersFeature` 的分區提前修 (使用者裁決)**：兩者原屬第 8、6 步範圍。`Dependency Properties` → `Dependencies`、`Reducer Body` → `Body`、`Identifiable Properties`／`Data Properties` → `Properties`，刪除巢狀型別內的 MARK (RootFeature 2 處、OrdersFeature 3 處)，合併 `OrderDateSection` 重複的 `Properties`。
- **`RootFeature` 改用 `Reduce(core)` (使用者指出未遵循樣板)**：原本是 195 行的 inline `Reduce { state, action in }`，抽成 `Private Method` 的第一個方法 `core(state:action:)`，`body` 只剩 `Reduce(core)`。本 change 範圍內的 7 個 Feature 現已全部使用 `Reduce(core)`。順帶移除 `RootFeature` 一行違反「註解結尾不加中文句號」的註解。
- **`OrdersFeature` 的三段 `Reduce` 留給第 6 步 (使用者裁決)**：三段各自綁不同的 `.ifLet`／`.forEach`，TCA 的執行順序是「父1 → 子1 → 父2 → 子2 → 父3 → 子3」，併成單一 `Reduce(core)` 會讓 `.editOrder(.presented(.saveTapped))` 的攔截相對於 `OrderEditFeature` 子 reducer 的順序改變，而該路徑正是 `ios-data-layer.md` 標註「撞號會退回靜默覆寫」之處。正解是照 `tca-architecture.md` 拆分順序第 2 步抽子 Feature，屬第 6 步工作。
- **`OrdersFeature.swift` 的檔案層級 MARK 撞名 (使用者指出)**：同檔三個型別讓 `// MARK: - Internal Method` 出現三次，Xcode jump bar 分不出歸屬。只搬位置、不改邏輯：`OrdersFeature.State` 的 `Nested Types` 與 `Internal Method` 併入既有的 `OrdersFeature+StateQuery.swift` (該檔本就是 `OrdersFeature.State` extension 的歸屬)，`OrderDateSection` 型別與其 extension 獨立為 `OrderDateSection.swift` (同目錄的 `OrderDatePeriod`、`OrderStatusFilter`、`OrderDraft` 都是一型一檔)。
  - 結果：`OrdersFeature.swift` 1062 → 974 行且只剩一個型別、`OrderDateSection.swift` 45 行、`OrdersFeature+StateQuery.swift` 199 → 222 行且四個分區各自唯一。
  - 順帶補上搬移那兩塊 doc 缺的空 `///`，並清除 `OrdersFeature+StateQuery.swift` 的 5 處尾隨空白。

### 第 11 批驗證

- 完整單元回歸 (最後一次於最後一次 Swift 寫入之後)：`totalTestCount` 752、通過 752、失敗 0、跳過 0；result bundle `/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-23T16-49-23-284Z_pid241_e473f863.xcresult`；`find apps/ios -name '*.swift' -newermt '2026-09-24 00:49:21'` 無輸出。
- MARK 名稱／順序／重複／巢狀稽核 0、區塊內容稽核 0、單行大括號與 `@Dependency` 拆行 0、尾隨空白 0、A 組 300 行上限逐檔無超標。
- 行寬與 doc 空 `///` 的殘留均在本次未改動的既有行：`FxStatusBanner` L104、`FxView` L215、`OllamaClientTests` L36 是單一字串字面值例外；`OrdersFeature+StateQuery.swift` 的 6 處 doc 與 1 處行寬 113 經 `git diff` 確認不在本次新增行內，屬第 6 步。
- **UI 回歸未重跑**：本批只動 MARK 區名、檔案歸屬與 `Reduce(core)` 抽取，未改任何 View 階層、`accessibilityIdentifier` 或 action 語意。
