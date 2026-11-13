## Problem

iPad 模擬器跑 XCUITest 時，偶爾進入「App 一直不閒置」的狀態：此後同一個 App 程序每次「等 App 閒置」都等滿 60 秒 (log 出現 `App animations complete notification not received, will attempt to continue`)，直到 App 被終止；下一條測試的前置步驟還會對殘留的程序再等一次。步驟多的測試因此逼近或超過 10 分鐘的執行上限，完整 UI 回歸的時間也不可預期。`.claude/rules/ios-ui-tests.md` 目前只寫現象與「單獨重跑」的判讀，沒有防止的手段。

觸發點不只一種：

- 轉向之後：主對話 2026-11-13 在 iPad Air 11-inch (M4) iPadOS 27.0 模擬器、Xcode 27.2，跑 `AdaptiveNavigationContinuityUITests/testSidebarPreferenceSurvivesTabChange_側邊欄展開_目的地與徽章正確` 18 次，4 次在轉向後觸發 (量測值)；正常每次 44 至 47 秒，觸發時 343 至 460 秒 (約 6 至 8 分鐘)。
- 鍵盤輸入與搜尋欄步驟：archive 紀錄 (`2026-11-07-input-focus-selection`、`2026-11-10-load-state-identifier-literals`、`2026-11-11-root-task-lock-cancellation`) 記錄 `OrderEditInputFocusUITests` 與 `AdaptiveNavigationContinuityUITests/testSearchKeepsOrClearsSelection_訂單清單並排_命中保留選取且排除後清空` 在這些步驟反覆等滿 60 秒，2026-11-11 的 iPad 完整回歸有 6 條因此超過上限。這兩類測試沒有轉向。

## Root Cause

**觀察到的現象** (主對話 2026-11-13 以暫時診斷量測，診斷碼已刪除)：

- 卡住期間 App 所有 window 的圖層上沒有一般動畫；持續存在的只有 Liquid Glass 系統元件內部的 `CAMatchMoveAnimation`／`CAMatchPropertyAnimation` (時長無限)，它們在沒有卡住的時段也一樣存在。App 的轉圈指示器只在讀取中出現，與觸發時機無關。
- 全程只有 1 個 scene、1 個 window，排除多視窗多出一份畫面。
- UI 測試模式暫時關閉 UIView 動畫後，同一條轉向測試連跑 16 次 0 次觸發。

**假說**：介面變化 (轉向、鍵盤、搜尋欄切換) 時，XCTest 對 App 動畫的追蹤失步，之後一直等不到「動畫結束」。XCTest 與 UIKit 的內部追蹤無法從 App 端觀察，這是目前最符合上述現象的解釋，不是已證實的機制；本 change 是有實驗支持的對策，不依賴證明內部機制。

## Proposed Solution

- **UI 測試模式關閉 UIView 動畫**：harness 啟用時、建立第一個 scene 之前關閉 UIKit 的 UIView 動畫，App 與 harness 之後都不重新開啟；不帶 `-BLUITest` 的啟動 (含啟動效能測試) 不受影響。只承諾 UIKit 的 UIView 動畫，SwiftUI 轉場、鍵盤與系統呈現是否也停止不在保證範圍內。
- **呈現競態測試保留動畫**：新增啟動參數 `-BLUITestKeepViewAnimations` (`LaunchOptions.shouldKeepViewAnimations`)，帶上時不關閉動畫。驗證「sheet、確認框或提示關閉之後接著呈現提示或確認框」的 UI 測試帶上它。依據是主對話 2026-11-13 的變異實驗 (把主檔刪除寫入失敗提示改回與確認框共用呈現狀態，即重現 2026-11-04 修正前的缺陷，iPad 上每條測試各 3 次)：

  | 測試 | 動畫開著 | 動畫關閉 |
  | --- | --- | --- |
  | `testRequestDeletion_寫入失敗提示關閉後再刪除_重新呈現確認框` | 3 次失敗 3 次 | 3 次全過 |
  | `testRequestDeletion_刪除寫入失敗_顯示提示並保留項目` | 3 次失敗 2 次 | 3 次失敗 2 次 |
  | `testRequestDeletion_長按選單刪除寫入失敗_項目保留且筆數不變` | 3 次全過 | 3 次全過 |

  關閉動畫後，第一條完全偵測不到這個缺陷。另一組變異 (拿掉「表單關閉中先暫存通知」) 在動畫開著時對應的 UI 測試也偵測不到，不受這個 change 影響。
- **常駐守門**：關閉動畫的判斷抽成可注入的函式，以單元測試守住四種啟動參數組合；另以原始碼掃描守住 App target 內只有 harness 接到 `UIView.setAnimationsEnabled`、沒有任何地方以 `true` 重新開啟。
- **文件**：改寫 `.claude/rules/ios-ui-tests.md` 的閒置等待條目，`apps/ios/CLAUDE.md` 的手動實測一節與 `apps/ios/README.md` 各補一句。

## Success Criteria

- 同一輪、同一台 iPad 模擬器上先量未修改建置的基準，再量修正後的建置：轉向、搜尋欄、鍵盤輸入三類測試在修正後全部實際跑完，log 中 `App animations complete notification not received` 為 0 次，轉向測試每次不超過 120 秒；與基準比較的結果記進 design。
- 單元測試：關閉動畫判斷的參數化測試與掃描守門通過，且各自的變異檢查會讓它們失敗。
- 帶保留參數的呈現競態測試，在上表的變異下仍會失敗 (偵測力保留)。
- 完整 `BuyLedgerTests` 0 失敗 (既有 3 條預期失敗除外)，snapshot 不重錄；iPhone 17 iOS 26.5 與 iPad Air 11-inch (M4) iPadOS 27.0 完整 UI 回歸 0 失敗，未保留動畫的測試 log 中上述訊息 0 次。

## Impact

- Affected specs: `ui-test-launch-harness`
- Affected code:
  - Modified:
    - apps/ios/BuyLedger/App/Testing/BLUITestHarness.swift
    - apps/ios/BuyLedger/App/Testing/Configuration/BLUITestConfiguration.swift
    - apps/ios/BuyLedgerUITests/Support/LaunchOptions.swift
    - apps/ios/BuyLedgerUITests/Tests/More/LookupManagementTests.swift
    - apps/ios/BuyLedgerUITests/Tests/Campaigns/CampaignFlowTests.swift
    - apps/ios/BuyLedgerTests/App/Testing/BLUITestConfigurationTests.swift
    - .claude/rules/ios-ui-tests.md
    - apps/ios/CLAUDE.md
    - apps/ios/README.md
  - New:
    - apps/ios/BuyLedgerTests/App/Testing/BLUITestHarnessViewAnimationTests.swift
    - apps/ios/BuyLedgerTests/Guards/ViewAnimationSwitchScanTests.swift
  - Removed: (none)
- 只影響 Debug 建置的 UI 測試模式；Release 建置沒有 harness，正式使用者不受影響。
- 未保留動畫的 UI 測試改在沒有 UIView 動畫的條件下執行；`-BLUITest` 也是 `ui-automation` 手動實測取得種子資料的方式，這類實測同樣沒有動畫，要看轉場時加保留參數。
