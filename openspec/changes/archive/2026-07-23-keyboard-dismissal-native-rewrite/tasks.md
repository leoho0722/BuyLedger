## 1. 前置確認與完整性清點

- [x] 1.1 確認三個前置 change 已落地：design-system-component-reduction 已刪除自製搜尋欄、touch-target-and-input 已為訂單編輯導入焦點狀態與鍵盤工具列、ui-polish-and-safeguards 已建立收鍵盤回歸測試。行為：改寫建立在穩定的基礎上而非移動中的程式碼。驗證：逐項檢視三者的成果確實存在；任一未落地則不啟動後續任務。
- [x] 1.2 以文字輸入元件的使用位置逐檔清點所有會呈現鍵盤的畫面，確認待導入清單完整涵蓋，並記錄清點結果。行為：移除全域手勢後不會有畫面失去收鍵盤能力。驗證：清點結果寫入本 change 目錄下的筆記，列出每個畫面及其對應的收鍵盤路徑 (return 鍵／鍵盤工具列／捲動／背景點擊)；與 1.1 確認的訂單編輯成果比對確認無遺漏。

## 2. 共用機制

- [x] 2.1 依決策〈以背景層點擊取代 window 級攔截，把黑名單換成白名單〉與〈共用修飾子以泛型承載各畫面不同的焦點型別〉，建立背景點擊收鍵盤的共用修飾子：以泛型參數承載焦點綁定，於背景修飾子內放置透明且宣告可命中形狀的區域，點擊時依決策〈收鍵盤以焦點狀態實作，不呼叫 UIKit 的結束編輯〉將焦點設為無而非呼叫結束編輯；修飾子不持有任何狀態。滿足 Every keyboard type has an identifiable dismissal path 與 Keyboard dismissal does not intercept touches globally。行為：套用該修飾子的畫面點擊空白背景即收鍵盤，且背景層位於內容之下不遮蔽觸控。驗證：以一個試作畫面確認點背景收鍵盤、點控制項不收鍵盤且控制項行為正常。

## 3. 綁定 store 的畫面導入焦點

- [x] 3.1 [P] 依決策〈焦點狀態的放置依專案既有慣例分流〉，為 CampaignEditView 在 CampaignEditFeature 狀態加入焦點欄位並以綁定連結，套用背景點擊修飾子，關閉時清除焦點。滿足 Focus state placement follows the existing project convention 與 Dismissal clears the focus state。行為：點背景收鍵盤、重開表單不沿用上次焦點。驗證：以 TestStore 斷言關閉時焦點清除；實機確認點背景收鍵盤且點控制項不收。
- [x] 3.2 [P] 為 FxView 在 FxFeature 狀態加入焦點欄位並以綁定連結，套用背景點擊修飾子，離開時清除焦點。滿足 Focus state placement follows the existing project convention。行為：匯率輸入欄可由點背景收鍵盤。驗證：以 TestStore 斷言焦點清除；實機確認收鍵盤行為。
- [x] 3.3 [P] 為 QuoteView 在 QuoteFeature 狀態加入焦點欄位並以綁定連結，套用背景點擊修飾子，離開時清除焦點。滿足 Focus state placement follows the existing project convention。行為：試算輸入欄可由點背景收鍵盤。驗證：以 TestStore 斷言焦點清除；實機確認收鍵盤行為。
- [x] 3.4 [P] 為 SettingsView 在 SettingsFeature 狀態加入焦點欄位並以綁定連結，套用背景點擊修飾子；注意該功能的綁定動作帶有存檔副作用，焦點欄位需比照既有作法排除於副作用之外。滿足 Focus state placement follows the existing project convention。行為：設定的數值欄可由點背景收鍵盤，且切換焦點不觸發存檔。驗證：以 TestStore 斷言焦點變更不觸發存檔副作用；實機確認收鍵盤行為。
- [x] 3.5 [P] 為 LookupManagementView 在 LookupManagementFeature 狀態加入焦點欄位並以綁定連結，套用背景點擊修飾子。滿足 Focus state placement follows the existing project convention。行為：主檔名稱輸入可由點背景收鍵盤。驗證：以 TestStore 斷言焦點清除；實機確認收鍵盤行為。

## 4. 不綁 store 的元件導入焦點

- [x] 4.1 [P] 為 OptionPickerSheet 在元件內部持有焦點狀態並套用背景點擊修飾子，依專案對閉包式可重用元件的既有例外規定不下放至功能狀態。滿足 Focus state placement follows the existing project convention。行為：選擇器內的搜尋或輸入可由點背景收鍵盤。驗證：以元件預覽確認點背景收鍵盤、點選項不收且選取行為正常。
- [x] 4.2 [P] 為 PaymentMethodEditorSheet 在元件內部持有焦點狀態並套用背景點擊修飾子。滿足 Focus state placement follows the existing project convention。行為：付款方式名稱輸入可由點背景收鍵盤。驗證：以元件預覽確認點背景收鍵盤，且既有的開關類欄位互動不受影響。

## 5. 移除全域手勢

- [x] 5.1 依決策〈移除整個手勢檔案，而非留下停用的程式碼〉，刪除 KeyboardDismissOnTap.swift (含視窗追蹤輔助視圖、手勢代理與私有型別名稱比對) 並移除 RootView 的掛載。滿足 Keyboard dismissal does not intercept touches globally。行為：程式碼中不再有 window 級手勢與私有名稱比對。驗證：全專案搜尋不到該修飾子與相關型別；iOS 與 iPadOS 皆建置成功 (build 前先於 apps/ios 執行 agvtool next-version 遞增 build number)。
- [x] 5.2 依 Implementation Contract 失敗模式所述，將 OrdersCompactView 既有採立即模式的捲動收鍵盤改為互動模式以貼近系統行為，並確認各可捲動輸入畫面皆已具備捲動收鍵盤。滿足 Every keyboard type has an identifiable dismissal path。行為：捲動時鍵盤隨之漸進收起而非立即消失。驗證：實機於各可捲動輸入畫面捲動確認鍵盤收起且體感自然。

## 6. 測試與驗收

- [x] 6.1 依決策〈沿用既有回歸測試作為改寫的驗證基準〉，確認 ui-polish-and-safeguards 建立的收鍵盤回歸測試在改寫後未經修改即通過；若失敗則修正新機制而非放寬測試。滿足 Keyboard dismissal does not intercept touches globally。行為：選取文字後點系統選單不收鍵盤的保證在換實作後仍成立。驗證：執行該測試確認通過，且測試檔案未因本 change 而被修改。
- [x] 6.2 新增測試斷言點擊背景收鍵盤、點擊互動控制項不收鍵盤兩種行為。滿足 Keyboard dismissal does not intercept touches globally。行為：新機制的正確性有測試守住。驗證：兩項新測試通過。
- [x] 6.3 於實機逐一走過 1.2 清點出的所有輸入畫面，對每個畫面確認四項：點背景收鍵盤、點互動控制項不收鍵盤、選取文字後點系統選單不收鍵盤、該畫面既有的收鍵盤路徑仍可用。行為：改寫前後使用者感受一致。驗證：逐畫面逐項對照 Implementation Contract 的行為清單，不以整體感覺正常作為通過依據。

## 7. 收尾

- [x] 7.1 依文件同步鐵則改寫 apps/ios/CLAUDE.md 中關於收鍵盤實作的硬規則：移除「以 window 級手勢實作」與「不可改成對所有 touch 都收鍵盤」等已失效的描述，改為記錄四條收鍵盤路徑與「不得以全域攔截加排除清單實作」的新規則。行為：文件無與現況矛盾的內容，後續實作者不會依過時規則行事。驗證：對照根目錄 CLAUDE.md 的文件同步表逐列確認，結論為「有影響，已同步」。
- [x] 7.2 重錄受背景層加入影響的 snapshot baseline (若有)，並確認既有單元測試全數通過。行為：baseline 與新實作一致。驗證：snapshot 測試全綠；若無差異則記錄「確認無 snapshot 影響」。
