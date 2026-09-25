## 1. 正規化共用化

- [x] 1.1 讓手動編輯與回溯不可能產生兩套語意：把訂單編輯器既有的旗標正規化規則（切離無卡時折抵與補款歸零、切離無卡與銀行匯款時對帳狀態清空、貨到付款依旗標決定）抽成可共用的形式，行為逐字不變。依 design「回溯重算沿用訂單編輯器的正規化，不另立規則」。驗證：既有的訂單編輯測試全數維持綠燈，證明此步為純搬移（apps/ios/BuyLedger/Features/App/RootFeature.swift）。

## 2. 回溯重算

- [x] 2.1 先寫紅燈測試釘住旗標更正真的修正既有訂單：補勾貨到付款後斷言受影響訂單的成本增加三種運費之和、獲利相應減少；清除無卡後斷言折抵與補款為零；清除無卡與銀行匯款後斷言對帳狀態被清空，只清除其一時保留。對應 spec requirement「Payment method editing via the editor sheet」與「Reconciliation status persistence and clearing rule」。驗證：四條斷言在實作前皆失敗（apps/ios/BuyLedgerTests/RootFeatureTests.swift）。
- [x] 2.2 讓主檔旗標確認後，使用該付款方式的既有訂單一併以共用正規化重算並批次落盤。驗證：2.1 四條斷言轉綠；`PaymentMethodPersistenceTests.applyEditPersistsMasterAndNormalizedOrdersTogether` 以四個非預設受管欄位驗證長命 `OrderPersistence` 讀回，丟棄 container 後以同 URL 重建並重新讀取仍為新值。
- [x] 2.3 讓主檔更新與訂單重算在同一次操作內完成：任一步失敗則兩者皆不生效。依 design「重算與主檔更新在同一次操作內完成」。驗證：`orderNotFound` 與唯讀 store 的 `save()` 失敗測試皆通過；後者丟棄失敗 context、以新 context 讀實體 store，主檔與訂單仍逐欄維持操作前值。
- [x] 2.4 確認回溯與手動編輯對同一組旗標變更產生相同結果：以同一筆訂單分別走兩條路徑，斷言欄位結果一致。驗證：對照測試通過，佐證兩者走同一處正規化。

## 3. 重寫前的確認

- [x] 3.1 先寫紅燈測試釘住確認流程：斷言旗標變更會影響既有訂單時先出現確認且未寫入任何內容；取消後訂單與主檔旗標皆維持原狀。對應 spec requirement「Payment method editing via the editor sheet」的確認要求。驗證：兩條斷言在實作前皆失敗。
- [x] 3.2 讓不可逆的重寫在執行前被明示：確認對話框說明將重算的訂單筆數，筆數與重算對象取自同一次過濾結果。依 design「重寫前先確認，並告知受影響筆數」。驗證：3.1 兩條斷言轉綠；另斷言對話框顯示的筆數等於實際重算筆數。
- [x] 3.3 讓取消是完整的取消：取消確認時主檔旗標也不套用，避免主檔與訂單對同一事實有不同答案。依 design「取消確認時，主檔旗標也不套用」。驗證：新增測試斷言取消後主檔旗標與操作前相同。
- [x] 3.4 讓零筆影響時不打斷使用者：沒有任何訂單使用該付款方式時不出現確認，主檔旗標直接套用。驗證：新增測試斷言零筆情境下無確認且旗標已套用。

## 4. 文案與驗收

- [x] 4.1 補齊確認對話框文案的中英對照並納入本地化目錄的必備清單。驗證：本地化目錄測試綠燈，英文模式下無語言回退（apps/ios/BuyLedger/Resources/Localizable.xcstrings）。
- [x] 4.2 執行整體驗收：主 scheme 全套單元測試綠燈、UI 主回歸綠燈，並以 UI Automation 實際補勾一次貨到付款、確認回溯重算、重啟 App 後再次讀取同一筆訂單的獲利數字。驗證：測試通過數不低於改動前；`OrderDetailTests.testCashOnDeliveryCorrectionPersistsAfterRelaunch` 以專用 persistent UI test store 證明重啟後數字仍為新值。
