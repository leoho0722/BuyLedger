## 1. 映射回歸保護先補起來

- [x] 1.1 讓映射漏寫任何一欄都會立即失敗：把既有的「同編號寫入會更新既有資料列」測試由斷言四個欄位升級為斷言整個領域值相等，並改用一筆二十六個欄位皆為非預設值的樣本。對應 spec requirement「Field mapping is protected by whole-value round-trip coverage」，依 design「映射回歸保護由四欄升級為整體相等」。驗證：暫時在映射中拿掉任一欄位的寫入，該測試必須轉紅，驗畢還原（apps/ios/BuyLedgerTests/OrderPersistenceTests.swift）。

## 2. 編號強度

- [x] 2.1 讓新建訂單取得完整長度的編號，且既有短編號訂單不受影響：編號產生點改回傳完整識別碼，需要短碼的顯示端自行由儲存值推導，不改變儲存值。對應 spec requirement「Order identifiers are generated at full strength」，依 design「編號改用完整識別碼，短碼只存在於顯示層」。驗證：全專案搜尋編號截短的呼叫零命中；新增測試斷言新建訂單編號為完整長度，且以短編號樣本走讀取、編輯、儲存三條路徑均正常（apps/ios/BuyLedger/Features/Orders/OrdersFeature.swift）。

## 3. 寫入意圖

- [x] 3.1 先寫紅燈測試釘住不覆寫契約：新增測試斷言建立意圖遇到既有同編號資料列時失敗，且既有資料列每一欄在失敗後皆未變動。對應 spec requirement「Writes declare create or update intent, and create never overwrites」。驗證：測試在實作前失敗（apps/ios/BuyLedgerTests/OrderPersistenceTests.swift）。
- [x] 3.2 讓持久層區分建立與更新兩種意圖，使靜默覆寫成為不可表達的狀態：建立意圖偵測到既有同編號資料列時拋出可辨識錯誤且不寫入任何內容，更新意圖維持既有替換語意。依 design「寫入區分建立意圖與更新意圖」。驗證：3.1 測試轉綠，且既有的更新路徑測試維持綠燈（apps/ios/BuyLedger/Core/Persistence/OrderPersistence.swift）。
- [x] 3.3 讓所有訂單寫入呼叫點各自宣告正確的意圖：新建走建立意圖、編輯與狀態變更走更新意圖，逐一檢視現有的十個持久層取得點。驗證：新建與編輯兩條路徑的既有 reducer 測試維持綠燈，且刻意讓新建走更新意圖時 3.1 測試轉紅（apps/ios/BuyLedger/Core/Dependencies/OrderRepository.swift）。

## 4. 並發序列化

- [x] 4.1 先寫紅燈測試釘住並發契約：新增測試以同編號並發寫入，斷言最終只有一列。對應 spec requirement「Concurrent writes to the same entity are serialized through one context」。驗證：測試在實作前失敗。
- [x] 4.2 讓同一實體的所有寫入序列化在單一長命持久層實例，消除「各自查無、各自插入」的可能：把每次操作各自建立實例改為建立一次後重用。依 design「同一實體的寫入序列化在單一長命持久層實例」。驗證：4.1 測試轉綠；另補測試斷言重複取用回傳同一實例（apps/ios/BuyLedger/Core/Dependencies/OrderRepository.swift）。

## 5. 合併的衝突情境

- [x] 5.1 讓合併在編號衝突時整批不生效，不會吃掉不相干的訂單：合併產生的新訂單改以建立意圖寫入，衝突時整個操作失敗、來源訂單狀態不變。依 design「合併儲存的原子性延伸到編號衝突」。對應 spec requirement「Saving a merged draft commits atomically」的新增衝突情境。驗證：新增測試斷言衝突時既有訂單逐欄未變、兩筆來源訂單狀態未變，且既有的合併原子性測試維持綠燈（apps/ios/BuyLedgerTests/OrderMergeFeatureTests.swift）。

## 6. 驗收

- [x] 6.1 執行整體驗收：主 scheme 全套單元測試綠燈、UI 主回歸綠燈，並確認訂單列表與詳情在編號變長後版面未破。驗證：測試通過數不低於改動前；訂單相關畫面以既有 snapshot 比對無非預期差異。

## 7. QA 複核：阻斷缺陷修正

- [x] 7.1 讓建立意圖寫入失敗時回滾樂觀插入，堵住「create 被拒後改走更新意圖靜默覆寫」的繞路：`applyEditDraft` 改回傳實際走的分支結果 (更新既有列或插入新列)，`saveTapped` 直接採用該值判斷意圖並在建立失敗時以快照回復 `state.orders`。驗證：新增測試 `newOrderSaveRollsBackOptimisticInsertWhenCreateFails` 斷言 create 撞號失敗後 `state.orders` 不含被拒的新訂單；移除回滾邏輯可讓該測試轉紅，已實測驗證 (apps/ios/BuyLedger/Features/Orders/OrdersFeature.swift、apps/ios/BuyLedgerTests/OrdersFeatureTests.swift)。**後續更新**：change 7 (`orders-write-then-update`) 將五條訂單寫入路徑全面改為先寫後改，`state.orders` 因此從未被樂觀插入過，本任務所述的快照回滾機制連同 `newOrderSaveRollsBackOptimisticInsertWhenCreateFails` 測試已於該次改動移除 (測試更名為 `newOrderSaveDoesNotInsertWhenCreateFails`)；本案 spec 並未要求此機制存在，移除不違反本案規格，僅本任務紀錄與現況不再一致，特此註記。
- [x] 7.2 讓長命 context 的 `update`／`upsertAll`／`mergeOrders` 在 `save()` 失敗時 `rollback()` 後 rethrow，避免 pending mutation 外洩到下一次成功的 save：三個函式各補上 do/catch + rollback。驗證：新增 `updateRollsBackPendingMutationWhenSaveFails`／`upsertAllRollsBackPendingMutationWhenSaveFails`／`mergeOrdersRollsBackPendingMutationWhenSaveFails`，以 `allowsSave: false` 的 in-memory container 強制 save 失敗；移除 rollback 呼叫可讓三者轉紅，已實測驗證 (apps/ios/BuyLedger/Core/Persistence/OrderPersistence.swift、apps/ios/BuyLedgerTests/OrderPersistenceTests.swift)。
- [x] 7.3 讓編輯表單「原始訂單」區塊改顯示 `displayID` 短碼，避免完整長度編號撐爆或擠壓版面。驗證：新增 snapshot baseline `orderEditViewLongIdentifierBaseline` 以 45 字元編號渲染，鎖住這類回歸 (apps/ios/BuyLedger/Features/Orders/OrderEditView.swift、apps/ios/BuyLedgerTests/SnapshotTests.swift)。
- [x] 7.4 讓 `create(_:)` 的非撞號 save 失敗路徑同樣 rollback：撞號 guard 發生在任何 mutation 之前不受影響、維持不動；`insert()` 之後若因非撞號原因 (磁碟錯誤、儲存體滿) 導致 `save()` 失敗，比照 7.2 補 `modelContext.rollback()` 後 rethrow，堵住長命 context 改造前不存在、改造後才出現的同一類失效模式。驗證：新增 `createRollsBackPendingMutationWhenSaveFailsForNonCollisionReason`，暫時拿掉該處 rollback 可讓測試轉紅 (`stored.count` 1→2)，已實測驗證 (apps/ios/BuyLedger/Core/Persistence/OrderPersistence.swift、apps/ios/BuyLedgerTests/OrderPersistenceTests.swift)。
- [x] 7.5 補充 `apps/ios/CLAUDE.md` 測試準則：`TestStore` 的 `exhaustivity = .off` 搭 `store.finish()` 不保證效果派送的 action 已處理完成，斷言其造成的 state 變更前須明確 `await store.receive(\.actionName)`，否則是一類容易被忽略的假測試 (實作 7.1 時發現並修正) (apps/ios/CLAUDE.md)。

## 8. QA 複核：應修事項

- [x] 8.1 讓 insert/update 判定謂詞單一化：`applyEditDraft` 回傳值一併帶出本次實際分支，呼叫端不再自行重算 `editState.original == nil`，消除兩者在 `original` 存在但已不在 `state.orders` 時的分歧 (apps/ios/BuyLedger/Features/Orders/OrdersFeature.swift)。
- [x] 8.2 讓 `.original`／`.updated` 全欄位樣本互換 `paymentReceiptStatus`／`isCashOnDelivery`，使 `.original` 不再有欄位恰好等於 `OrderRecord` 的 stored default，堵住漏寫欄位仍可能假綠的孔 (apps/ios/BuyLedgerTests/OrderPersistenceTests.swift)。
- [x] 8.3 重新命名 `concurrentCreateWithSameIdentifierYieldsExactlyOneRow` 為 `concurrentCreateAttemptsAllHonorCreateIntentCollisionSemantics`，並改寫註解點明它守的是建立意圖的撞號語意、非單一實例序列化 (該保證改由 `persistenceInstanceProviderReusesTheSameInstance` 守住) (apps/ios/BuyLedgerTests/OrderPersistenceTests.swift)。
- [x] 8.4 讓 `DataExportFeatureTests.orderRepository(returning:)` 改用「取 `OrderRepository.testValue` 基底再覆寫 `fetchOrders`」的寫法，與同檔 `gatedBy` 版本一致，避免日後 `OrderRepository` 加欄位時擴散 diff (apps/ios/BuyLedgerTests/DataExportFeatureTests.swift)。

## 9. QA 複核：Style 違規

- [x] 9.1 V4：把 `FullFieldVariant`／`CreateOutcome` 移出 `struct OrderPersistenceTests` 主體，改置於檔案層 `private extension OrderPersistenceTests { }`，MARK 置於該行上方 (apps/ios/BuyLedgerTests/OrderPersistenceTests.swift)。
- [x] 9.2 V5：移除 `private extension` 內 `makeFullFieldOrder`／`attemptCreate` 重複的 `private` 修飾詞 (apps/ios/BuyLedgerTests/OrderPersistenceTests.swift)。
- [x] 9.3 V6：刪除兩處「顯式標 private 是因為…會編不過」的辯解註解，並將併發測試的 actor 語意說明壓縮為兩行 (apps/ios/BuyLedgerTests/OrderPersistenceTests.swift)。
- [x] 9.4 V1：把 `OrdersFeatureTests.swift` 兩處註解的破折號改為分號 (apps/ios/BuyLedgerTests/OrdersFeatureTests.swift)。
- [x] 9.5 V2：把 `apps/ios/CLAUDE.md` 新增 bullet 的破折號改為冒號 (既有／前案的行不動)。
- [x] 9.6 V3：把 `PersistenceInstanceProvider.instance()` 外移為 `extension OrderRepository.PersistenceInstanceProvider { }`，MARK 置於該行上方 (Data Properties／Init 留主體不動) (apps/ios/BuyLedger/Core/Dependencies/OrderRepository.swift)。
- [x] 9.7 V7：把 `upsertAll` doc comment 殘留的 `upsert` API 名改為「逐筆寫入」(同檔 :99 與 `OrderRepository.swift` 描述語意的 `upsert` 不動) (apps/ios/BuyLedger/Core/Persistence/OrderPersistence.swift)。
