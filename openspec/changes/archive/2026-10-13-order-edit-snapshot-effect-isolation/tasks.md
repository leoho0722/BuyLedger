## 1. 追查與回歸保護

- [x] 1.1 依 design 的現行載入流程，確認表單與照片子 Feature 的 `.task`、相依擷取和完成生命週期；iPhone 17 鎖淺色，以 BuyLedger scheme 的 `-only-testing:BuyLedgerTests/SnapshotTests` 執行一次修改前整批，記錄實際數量、完整 issue、bundle 與 log；在本 change 的證據文件分列歷史結果與本次結果，不把未重現當成已驗證隔離
- [x] 1.2 在 `SnapshotTests+OrderEdit.swift` 集中三條 snapshot 的初始 State，保留可見選項、固定時間與 `.loaded` 照片；同檔新增窮舉 TestStore 測試，確定且重複送出 `.view(.task)` 與 `.photos(.view(.task))`，所有 Service 維持未覆寫，確認 State 不變及 finish 無剩餘效果。驗證：受控測試先綠燈；暫移除共用 State 的照片已載入設定後，同一方法至少執行一條且出現 `OrderService.fetchOrderPhotos` Unimplemented；還原後通過；三條方法層 snapshot 各有大於零的實際執行數，修改前後差異圖逐像素相同且無新增圖片差異；design 所列四條既有日期排列圖片失敗依使用者確認另案處理並如實記錄，baseline 無變動。正式 reducer、共用 harness 或 Service testValue 需改動時停下回報 [after: 1.1]

## 2. 回歸與文件

- [x] 2.1 以最終設定於同台 iPhone 17 淺色外觀連續執行五輪完整 `SnapshotTests`，再執行完整 `BuyLedgerTests` 單元回歸；每次記錄大於零的實際數量、issue、完整 bundle 與 log 路徑，xcresult 與日誌皆無訂單編輯載入的 Unimplemented (含 No test reporter)，只有 design 所列四條修改前已存在的日期排列圖片失敗，無新增失敗；完整回歸中刻意預期的 ServiceTestValueStrictnessTests issue 對照來源與 xcresult 分類；`git status --short apps/ios/BuyLedgerTests/__Snapshots__` 無變動 [after: 1.2]
- [x] 2.2 對照根目錄 `CLAUDE.md` 文件同步表，只有形成新測試 gotcha 才更新 `.claude/rules/ios-unit-tests.md`；改動 Swift 依 ios-dev-kit 逐條自檢並完成 style 閘門。驗證：記錄「有影響，已同步」或「確認無文件影響」，明確檔案清單 style_checks 無違規，spectra analyze 與 spectra validate 通過；證據均在本 change 內 [after: 2.1]

## 變更記錄 (不計為已完成任務)

- 原 pending 1.1 要求重現六個主檔未覆寫失敗：由 design「Supersedes：以確定送出的現行事件驗證沒有載入效果」取代，改追查現行 action 與修改前整批，舊六種載入已不存在。
- 原 pending 1.2 要求完整注入六個主檔 closure、移除其中一個覆寫做變異：取消，由 design「Supersedes：以共用初始 State 取代六個主檔載入替身」取代為共用 State、明確事件測試與移除 `.loaded` 的變異。
- 原 pending 2.1／2.2 的五輪、完整回歸與文件要求保留，驗證對象依更新後 design 對齊。

- 原 pending 1.2 的三條圖片方法全綠與 pending 2.1 僅依既有像素雜訊規則判讀的要求：依使用者明確確認，由 design「Supersedes：以無新增圖片差異取代既有圖片方法全綠要求」取代；三條方法仍須實際執行且修改前後差異圖相同，四條修改前已存在的日期排列失敗保留另案處理，其他測試與日誌要求不變。
