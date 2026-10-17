## Why

工具鏈由 Xcode 26.6.0 換到 27.0.0 之後，iPad Air 11-inch (M4) 的 `BuyLedgerUITests` 主回歸出現 6 條失敗，其中 5 條的失敗訊息都是「數字鍵盤工具列的完成鍵未能收起鍵盤」。同一份測試碼在 Xcode 26.6.0 下是 56 passed、0 failed。

實測已排除產品缺陷：斷開模擬器的硬體鍵盤連線後，`KeyboardDismissTests` 2 條全部通過 (bundle `test_sim_2026-09-18T02-00-34-943Z`)，`FxTests`、`QuoteTests`、`OrderCreateTests` 由 5 條失敗變成 7 passed、1 failed (bundle `test_sim_2026-09-18T02-03-01-423Z`)。

成因是模擬器接著硬體鍵盤時 iPadOS 不顯示軟體鍵盤，鍵盤工具列改以浮動附件呈現。失敗當下的可及性樹顯示：完成鍵 `common.keyboard.doneButton` 位於 `{{764,1120},{28,36}}` 在畫面內、欄位 `orderEdit.chargedAmountField` 仍是 `Keyboard Focused`、`Keyboard` 元素位於 `{{0,1224},{820,279}}` 在畫面外。XCUITest 送到回報座標的點擊打不中實際命中區，焦點因此不解除，`app.keyboards` 元素也永遠不消失，`dismissNumericKeyboard` 的等待必然逾時。

剩下的 1 條失敗換成另一種成因：`OrderEditScreen.typeCustomerName` 的捲動迴圈直接讀 `field.frame`，但 SwiftUI 的 Form 會把捲出可視範圍的列移出可及性樹，此時該行會拋出 `Failed to get matching snapshot` 而不是回傳零矩形，迴圈進不到 `swipeDown`。軟體鍵盤顯示後可視範圍變小才會踩到，已連續兩次重現。

不處理的話，iPad 的 UI 主回歸會長期帶著紅燈，後續每一步重構的驗收基準都會被污染。

## What Changes

- 在 `apps/ios/CLAUDE.md` 的測試環境設定補上硬規則：iPad UI 回歸前要確認軟體鍵盤可顯示 (斷開模擬器的硬體鍵盤連線)，並寫明症狀與判別方式，讓換機或換 Xcode 時能快速對應。
- 修正 `OrderEditScreen.typeCustomerName` 的捲動迴圈：先確認欄位存在再讀取 frame，元素不在可及性樹上時繼續捲動，捲動次數用盡則附診斷失敗。
- 盤點 `apps/ios/BuyLedgerUITests/Screens/` 與 `apps/ios/BuyLedgerUITests/Support/` 內同型寫法，只修正會在元素不存在時中斷測試的存取。
- 判定 `OrderDetailTests.testCashOnDeliveryCorrectionPersistsAfterRelaunch` 的 `Activation point invalid` 屬環境雜訊或真缺陷，並依判定結果記錄或修正。

## Non-Goals

- 不重構產品端的鍵盤工具列：實測已證明軟體鍵盤顯示時完成鍵運作正常，工具列的零尺寸節點與 `Invalid frame dimension` 警告不是致命原因。
- 不重錄任何 snapshot 參考圖。
- 不處理 `repair-false-passing-tests` 留下的其他弱斷言清單 (`OrdersFeatureTests` 的 `aiSummaryTapped`、`HarnessSelfCheckTests` 的 KPI 非空、`OrderDetailTests` 的 `XCTAssertNotEqual` 收尾)。
- 不調整 iPhone 的測試環境設定：iPhone 17 的主回歸在同一工具鏈下維持 56 passed。
- 不為了讓測試轉綠而放寬斷言、加入 `XCTSkip` 或改成靜默 return。

## Impact

- Affected specs: none
- Affected code:
  - New: (none)
  - Modified:
    - apps/ios/CLAUDE.md
    - apps/ios/BuyLedgerUITests/Screens/OrderEditScreen.swift
    - apps/ios/BuyLedgerUITests/Screens/ 內經盤點判定需修正的其他 Page Object (清單由任務 2.2 產出)
    - apps/ios/BuyLedgerUITests/Support/ 內經盤點判定需修正的其他 helper (清單由任務 2.2 產出)
    - apps/ios/BuyLedgerUITests/Tests/Orders/OrderDetailTests.swift (僅在任務 3.1 判定為真缺陷時)
  - Removed: (none)
- Compatibility: no capability-level observable behavior changes
