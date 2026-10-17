## Why

訂單編輯 snapshot 曾在整批執行時記錄未覆寫 Service 的 Unimplemented。現行表單已改成初始化時接收選項，需依目前程式確認載入隔離並補上會確定觸發表單與照片載入事件的回歸測試，避免只憑圖片通過判定沒有外溢。

## What Changes

- 追查現行 `OrderEditView`、`OrderEditOperations` 與 `OrderEditPhotosFeature` 的載入事件、效果與完成生命週期，分開記錄歷史失敗和本次整批實測。
- 集中三條訂單編輯 snapshot 的初始 State 設定，保留既有選項、固定時間與已載入照片，不注入目前不會被呼叫的六個主檔 Service。
- 在同檔以 Swift Testing 與窮舉 TestStore 確定送出表單與照片區段的 `.view(.task)`，確認狀態不變、效果完成且 Service 維持未覆寫仍無 issue；暫移除共用初始 State 的照片已載入設定，必須觀察到 `OrderService.fetchOrderPhotos` 的 Unimplemented，還原後通過。
- 保留三條方法層 snapshot、五輪整批 snapshot 與完整單元回歸驗證；同時檢查 xcresult 和日誌，基準圖不重錄。依使用者確認，圖片驗收採修改前後無新增差異；本次修改前實測已存在的四條日期排列圖片失敗另案處理，仍如實記錄為失敗。

## Non-Goals

- 不改正式 reducer、View、Service `testValue` 或共用 `TestDependencies.withFixedNow`。
- 不注入不會被呼叫的 Service、不加入產品端 snapshot 分支、不忽略 issue。
- 不處理進度元件、毛利朗讀、iPad 環境、既有導覽列像素雜訊或修改前已存在的 DatePicker 日期排列差異。

## Impact

- Affected specs: none
- Affected code:
  - New: (none)
  - Modified: apps/ios/BuyLedgerTests/SnapshotTests+OrderEdit.swift
  - Modified (僅形成新的測試 gotcha 時): .claude/rules/ios-unit-tests.md
  - Removed: (none)
- Compatibility: no capability-level observable behavior changes；既有三個 snapshot 方法名稱、可見表單與基準圖維持相同。
