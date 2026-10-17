## 1. 收鍵盤規格對齊現況

- [x] 1.1 讓收鍵盤路徑的定義只描述實際存在的三條，並讓已被否定的背景點擊不再出現在可施工的敘述中：套用「Every keyboard type has an identifiable dismissal path」的改寫，加入「每個有輸入的畫面至少提供其中兩條」，並移除背景點擊的 scenario。驗證：封存後對該規格檔搜尋背景點擊相關字樣，於 requirement 與 scenario 區塊零命中（資產目錄檔名不計）；requirement 正文可同時搜到 return 鍵、鍵盤工具列、捲動三條路徑名稱。
- [x] 1.2 讓「不得全域攔截觸控」這條仍然有效的禁令原文保留，同時把它指向的補救方案由背景層改為具名的三條路徑，並明文記載背景層點擊已被實測否定：套用「Keyboard dismissal does not intercept touches globally」的改寫，連帶修正原本描述「不被背景層收掉」的 scenario 措辭，避免矛盾只是換個位置。驗證：封存後該 requirement 仍逐字含 window 級手勢禁令句，且新增的否定敘述可被搜尋到；全檔無「attached to a screen's background layer」的正面主張。
- [x] 1.3 讓焦點清除的 scenario 以實際存在的路徑描述：套用「Dismissal clears the focus state」的改寫，把原本以背景點擊為觸發的 scenario 改為以鍵盤工具列完成動作觸發。驗證：封存後該 requirement 的 scenario 不再提及背景點擊，且既有的跨呈現焦點 scenario 保持不變。

## 2. 開團提醒規格對齊現況

- [x] 2.1 讓提醒設定的規格描述現行的表單內開關加 inline 日期選擇器，且不與既有的 sheet 規格互相打架：移除舊條目「Reminder is configured via a date-and-time popup on the add/edit form」並新增「Reminder is configured inline on the add/edit form」（原標題含 popup 字樣，直接改標題會在封存時比對失敗而多出重複條目，故走 REMOVED 加 ADDED），新條目用詞與 sheet-nested-presentation 的 inline 敘述對齊。驗證：封存後對該規格檔搜尋 popup 零命中；新標題在該檔恰好出現一次；requirement 總數維持為 7（證明是汰換而非新增）。

## 3. 平台指引去矛盾

- [x] 3.1 讓平台指引對提醒呈現方式只有一個敘述：刪除描述 sheet 與 graphical 日期選擇器、螢幕高度比例的子句，保留與呈現方式無關的資料規則（預設值取結單日或當日上午九點、儲存時重新校準事件），並指向 inline 那一條。驗證：對 apps/ios/CLAUDE.md 搜尋 presentationDetents 與 graphical 零命中，同時搜尋 09:00 與 reconcile 仍各有命中（證明有效規則未被誤刪）。
- [x] 3.2 讓版面規則的範例只舉仍然存在的元件：移除已改為開關而不再使用該元件的範例，保留仍在使用的那一個。驗證：對 apps/ios/CLAUDE.md 搜尋該已失效範例字樣零命中，且保留的範例在對應原始檔中仍可搜到對應修飾詞。

## 4. 孤兒字串清除與回歸守門

- [x] 4.1 讓兩個從未被顯示的本地化字串不再存在於目錄中：移除兩個孤兒條目（含兩種語言的字串單元），兩者在產品程式碼中僅出現於註解。驗證：對本地化目錄搜尋兩個字串零命中；對產品原始碼搜尋僅剩註解命中（apps/ios/BuyLedger/Resources/Localizable.xcstrings）。
- [x] 4.2 讓已退役的字串不會被手動或工具寫回：在本地化目錄測試中加入一組已退役字串斷言，失敗訊息說明該字串已退役不得復活。驗證：本地化目錄測試全綠；暫時把其中一個字串加回目錄可讓該測試轉紅，驗畢還原（apps/ios/BuyLedgerTests/LocalizationCatalogTests.swift）。

## 5. 驗收

- [x] 5.1 確認規格庫與程式碼一致且無回歸：執行規格驗證、以模擬器建置一次確認移除字串後仍可編譯、執行主 scheme 全套單元測試。驗證：規格驗證退出碼為 0；建置成功；單元測試通過數與改動前一致。
- [x] 5.2 確認建置未污染本地化目錄：建置後檢視該檔差異，只保留兩個刻意移除的區塊，其餘由 Xcode 產生的結構性差異一律還原（已知踩雷：建置會寫入格式字串與 InfoPlist 類條目）。驗證：該檔的差異僅含兩個移除區塊。

## 6. 修正輪：QA／Style 審查意見回應

- [x] 6.1 修正 `apps/ios/CLAUDE.md:98` 提醒預設時間的措辭歧義：原句「結單日或今天上午 09:00」可讀成兩個並列選項，改寫為「結單日 (無結單日則取今天) 的上午 09:00」，只改這一句，同段其他內容不動。驗證：對照 `CampaignFeature.swift` 的 `defaultReminderTimestamp(closeDate:)` 語意（`closeDate ?? date.now` 取當天 09:00），新措辭不再有歧義讀法。
- [x] 6.2 修補第四份權威來源與本案的矛盾：`design-system-hygiene` 的 requirement「Mechanisms depending on non-public identifiers are covered by regression tests」兩條 scenario 仍描述已刪除的 window 級手勢與 identifier matching，與本案剛強化的 `keyboard-dismissal-paths`「no window-level gesture and no matching against non-public type names remain」直接打架。已獨立複驗全庫零命中任何非公開識別碼比對機制（`dismissKeyboardOnTap`／`UIGestureRecognizerDelegate`／`NSClassFromString`／`objc_`／`swizzl` 等關鍵字掃描皆為零），且三個 parked change（`shared-helper-dedup`、`orders-dual-layout-consolidation`、`design-token-convergence`）改的是 `design-system-hygiene` 的其他 requirement，與此條無撞車。採 REMOVED：新增 `design-system-hygiene` spec delta 移除該 requirement 並寫明 Reason／Migration；同步在 `keyboard-dismissal-paths` 的「Keyboard dismissal does not intercept touches globally」補一句，註明「System text menu does not dismiss the keyboard」與「Interactive controls are unaffected」兩條 scenario 各自由回歸測試把關（對應 `KeyboardDismissTests.swift:23,56`），承接原 requirement 失去的測試覆蓋敘述。驗證：`spectra validate spec-contradiction-cleanup` 通過；`openspec/specs/design-system-hygiene/spec.md` 該 requirement 封存後移除，`keyboard-dismissal-paths` 不再與之矛盾。
- [x] 6.3 補記 `.searchable` 的豁免說明：`keyboard-dismissal-paths` 的「Every keyboard type has an identifiable dismissal path」要求「每個有文字輸入的畫面至少提供兩條命名路徑」，但 `OrdersView`／`OrderFilterSheet`／`OrderMergeCandidateSheet` 三個純 `.searchable` 畫面靠系統預設的 Cancel 鈕與捲動收合滿足、並無顯式 `scrollDismissesKeyboard`。於該 requirement 本文與「Every input screen offers at least two paths」scenario 補上豁免說明，避免未來逐條稽核誤判為違規。驗證：`apps/ios/CLAUDE.md:147` 既有的 `.searchable` 豁免敘述與新 spec 條文語意一致。
