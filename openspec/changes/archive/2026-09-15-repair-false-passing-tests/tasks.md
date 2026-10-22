## 1. 變更前基準

- [x] 1.1 記錄變更前基準：選定一台 iOS 26.x iPhone 模擬器與一台 iOS 26.x iPad 模擬器，把兩台的名稱與 UDID 寫在本節下方；本 change 之後所有單元測試與 UI 測試都以這兩個 UDID 指定執行，iPhone 的單元測試與 UI 測試使用同一台。在該 iPhone 模擬器跑主 scheme 單元測試與 `BuyLedgerUITests` 主回歸，在該 iPad 模擬器跑 `BuyLedgerUITests` 主回歸 (主回歸皆為整個 target 排除 `LaunchPerformanceTests`)，把三份結果的通過數、失敗數與失敗測試名稱寫在本節下方。驗證：本節下方有兩台模擬器的名稱與 UDID，以及三份含失敗測試名稱的結果，作為 6.1「失敗數不多於基準」的比對依據。

基準模擬器：

- iPhone：iPhone 17，iOS 26.5，UDID `DDAA3311-B464-4DD3-96B8-360B26AF1929`
- iPad：iPad Air 11-inch (M4)，iOS 26.5，UDID `6B65ED1C-3C2E-42BA-B1E7-08F606F175C5`

基準結果 (2026-09-14，兩台皆鎖定淺色外觀)：

- iPhone 主 scheme 單元測試 (`BuyLedger`)：705 discovered，703 completed，701 passed，2 failed，0 skipped。失敗：`SnapshotTests/orderEditViewBaseline()`、`SnapshotTests/quoteViewBaseline()`，皆為既有 snapshot mismatch。
- iPhone UI 主回歸 (`BuyLedgerUITests`，排除 `LaunchPerformanceTests`)：55 passed，0 failed，0 skipped。
- iPad UI 主回歸 (`BuyLedgerUITests`，排除 `LaunchPerformanceTests`)：55 passed，0 failed，0 skipped。

## 2. 單元測試：儲存層與寫入失敗

- [x] 2.1 [after: 1.1] 依「A test fails when the behaviour it names is broken」修正 `OrderPersistenceTests` 的 save 失敗清理測試：斷言改為能區分「有回滾」與「沒回滾」的讀回結果，並涵蓋 `create`、`update`、`upsertAll`、`mergeOrders`、`updatePersistingPhotos`、`seedIfEmpty` 六條插入後可能失敗的路徑；另補 `mergeOrders` 來源訂單讀取失敗路徑的有效測試與反向變異驗證。驗證：逐一暫時移除對應 save 失敗清理，測試轉紅並記錄失敗訊息原文；來源讀取變異須確認實際執行數大於 0；還原後 focused 測試轉綠。封存後 review 的最新結果以本檔「Claude review follow-up」為準。

變異驗證紀錄 (2026-09-14，iPhone 17 / iOS 26.5，`BuyLedgerTests/OrderPersistenceTests`)：

實作補強：save 失敗後先執行 `rollback()`，再依該次操作保留的 `OrderRecord` 實例清除 SwiftData context 仍可讀到的 pending 新資料；既有訂單只回滾欄位變更，不會被清除。

- 六條 save 失敗變異的失敗原文與結果已完整記在 follow-up §2；每條均是「save 失敗後 rollback 應只保留 save 前已存在的資料列」或 seed 不應留下 pending 訂單。還原後 focused persistence 測試通過。
- [x] 2.2 [after: 1.1] 依「讀回資料改由儲存層提供而非測試餵回」修正 `OrdersFeatureTests` 的 `statusChangeFailurePreservesPresentedOrderAcrossReload`、`receiptStatusChangeFailurePreservesPresentedOrderAcrossReload`、`batchStatusChangeFailureLeavesAllSelectedOrdersUnchangedAcrossReload`、`deletionFailurePreservesPresentedOrderAcrossReload`、`editSaveFailurePreservesPresentedOrderAcrossReload`：重新載入的訂單來自寫入所針對的儲存層 (in-memory container 搭配 `OrderRepository.live(container:)`，或寫入與讀取共用同一個記錄替身)，不再由測試送出 `.ordersLoaded` 餵回原資料；若某條無法讓儲存層以 in-memory 方式寫入失敗，則改名為只驗證畫面狀態並記錄原因。驗證：暫時讓對應的產品寫入在拋錯前已落盤，保留「跨重新載入」宣稱的測試轉紅並記錄訊息原文；還原後轉綠。

實作與驗證紀錄 (2026-09-14，iPhone 17 / iOS 26.5，`BuyLedgerTests/OrdersFeatureTests`)：

- 五條測試共用 `OrderRepository.live(container:)` 搭配獨立 in-memory container，先以真實 repository 落盤，再只替換對應寫入 closure 為失敗；重載一律送 `.task`，主檔載入以明確失敗替身抑制，另以正規化品項識別值與 ID 排序處理 SwiftData round-trip 差異。
- 暫時讓 `statusChange` 寫入成功後再拋錯：`Expectation failed: ... status: .arrived ... == ... status: .shipping ...: 冷啟動前後畫面呈現的訂單集合應一致`；68 passed，1 failed，0 skipped。
- 暫時讓 `receiptStatusChange` 寫入成功後再拋錯：`Expectation failed: ... paymentReceiptStatus: .received ... == ... paymentReceiptStatus: .pending ...: 冷啟動前後畫面呈現的訂單集合應一致`；68 passed，1 failed，0 skipped。
- 暫時讓批次狀態寫入成功後再拋錯：`Expectation failed: ... O1/O2/O3/O4 status: .arrived ... == ... O1/O2/O3/O4 status: .shipping ...: 冷啟動前後畫面呈現的訂單集合應一致`；68 passed，1 failed，0 skipped。
- 暫時讓刪除寫入成功後再拋錯：`Expectation failed: (store.state.orders.map(Self.normalizingItemIdentifiers) → []) == ([persistedOriginal] → [O1]): 冷啟動前後畫面呈現的訂單集合應一致`，以及 `Expectation failed: (store.state.selectedOrderID → nil) == (original.id → "O1")`；68 passed，1 failed，0 skipped。
- 暫時讓編輯寫入成功後再拋錯：`Expectation failed: ... BL-2604-018 customer.name: "改名嘗試" ... == ... customer.name: "林書宇" ...: 冷啟動前後畫面呈現的訂單集合應一致`；68 passed，1 failed，0 skipped。
- 還原後 focused class：69 passed，0 failed，0 skipped。
- [x] 2.3 [after: 2.2] 讓 `OrdersFeatureTests.mergeCompletionOpensPrefilledDraft` 不再依賴牆鐘：`continuousClock` 改注入 `TestClock` 並以 `advance(by:)` 推進延遲，移除 `receive` 的 3 秒逾時。驗證：該測試連續單獨執行三次皆通過；暫時拿掉 `advance(by:)` 時測試因未收到 `mergeConfirmationReady` 而失敗，並記錄訊息原文。

實作與驗證紀錄 (2026-09-14，iPhone 17 / iOS 26.5，`BuyLedgerTests/OrdersFeatureTests/mergeCompletionOpensPrefilledDraft`)：

- `continuousClock` 改注入 `TestClock`，在收到合併 delegate 後以 `await clock.advance(by: .milliseconds(500))` 推進效果，移除 `receive` 的 3 秒逾時。
- 暫時移除 `clock.advance(by:)` 後執行 `OrdersFeatureTests`：`1 test failed，68 passed，0 skipped`；失敗訊息原文：`Expected to receive a matching action, but received none after 1.0 seconds.`，並指出有 clock/scheduler effect in-flight；還原後通過。
- 還原後目標測試連續單獨執行三次皆 `Test succeeded` (exit 0；各次均 discovered 1 test)，耗時 45.4 秒、24.2 秒、35.5 秒。
- [x] 2.4 [after: 1.1] 依「無法成為有效守門的測試改名或刪除」處理 `PersistenceErrorContractTests` 與 `PersistenceFailureFeatureTests.confirmedRecoveryMovesFilesThenRequiresRelaunch`：
  - 自我比較的錯誤合約測試，改為呼叫會拋出對應錯誤的產品路徑 (例如以空代碼清單寫入幣別主檔時拋出 `emptyCodeList`) 並以 `#expect(throws:)` 驗證；找不到可觸發路徑的案例則刪除。
  - 復原測試以計數替身記錄 `quarantine` 被呼叫一次。

  驗證：暫時移除空代碼清單的防護，對應測試轉紅；暫時讓復原流程略過 `quarantine`，復原測試轉紅；兩者都記錄訊息原文。

實作與驗證紀錄 (2026-09-14，iPhone 17 / iOS 26.5)：

- 刪除 `PersistenceErrorContractTests` 中三組只把錯誤值與自身比較的測試，保留一條可由 `CurrencyMetadataPersistence.replace(codes: [], at:)` 實際觸發的 `emptyCodeList` 產品路徑，改以 `#expect(throws:)` 驗證。
- `confirmedRecoveryMovesFilesThenRequiresRelaunch` 注入 `QuarantineCallBox`，復原成功後斷言 `quarantine` 呼叫次數為 1。
- 暫時移除空代碼清單 guard：`PersistenceErrorContractTests` 為 `1 test failed，0 passed，0 skipped`；失敗訊息原文：`Expectation failed: an error was expected but none was thrown`。
- 暫時略過產品流程的 `quarantine` 呼叫：`PersistenceFailureFeatureTests` 為 `2 tests failed，2 passed，0 skipped`；主要失敗訊息原文：`Expectation failed: (box.callCount → 0) == 1`。
- 還原後 `PersistenceErrorContractTests`：`1 passed，0 failed，0 skipped`；`PersistenceFailureFeatureTests`：`4 passed，0 failed，0 skipped`。

## 3. 單元測試：Feature 行為與 delegate

- [x] 3.1 [after: 1.1] 修正 `OrderMergeFeatureTests.candidateTappedWithinPhotoLimitCompletesDirectly` 與 `photoStepConfirmDeliversKeptPhotosInOrder`：以 case key path 比對 `delegate.completed` 的照片 payload (主單照片在前、保留的照片依索引順序)，刪除把索引對應回同一份陣列再比較的恆真斷言。驗證：暫時把合併照片改成副單在前，以及暫時改成保留全部照片，兩條測試分別轉紅並記錄訊息原文。

實作與驗證紀錄 (2026-09-14，iPhone 17 / iOS 26.5，`BuyLedgerTests/OrderMergeFeatureTests`)：

- 以 `AnyCasePath(\\.delegate.completed)` 擷取 delegate payload，直接比對 primary、secondary 與 `keptPhotos`；移除由同一份 `selectedPhotoIndices` 與 `combined` 陣列重新計算的恆真照片斷言。
- 暫時改成副單照片在前：`6 tests failed，5 passed，0 skipped`；`candidateTappedWithinPhotoLimitCompletesDirectly` 收到的 `keptPhotos` 順序與預期不符。
- 暫時改成保留全部照片：`1 test failed，10 passed，0 skipped`；`photoStepConfirmDeliversKeptPhotosInOrder` 收到 7 張照片而非預期 3 張。
- 還原後 focused class：`11 passed，0 failed，0 skipped`。
- [x] 3.2 [after: 1.1] 修正 `CampaignEditFeatureTests.cancelWithoutChangesDismissesDirectly` 與 `OrderEditFeatureTests.cancelWithoutChangesDismissesDirectly`：注入會記錄呼叫的 `DismissEffect`，斷言沒有未儲存變更時 `cancelTapped` 會呼叫 dismiss。驗證：暫時移除兩個 Feature 在無變更分支的 dismiss 呼叫，兩條測試轉紅並記錄訊息原文。

實作與驗證紀錄 (2026-09-14，iPhone 17 / iOS 26.5)：

- 兩條測試各注入 `DismissEffect` 計數替身，送出 `cancelTapped` 後等待 effect 完成，再斷言 `callCount == 1`。
- 暫時移除 `CampaignEditFeature` 無變更分支的 dismiss：`1 test failed，7 passed，0 skipped`；失敗訊息原文：`Expectation failed: (dismissBox.callCount → 0) == 1`。
- 暫時移除 `OrderEditFeature` 無變更分支的 dismiss：`1 test failed，41 passed，0 skipped`；失敗訊息原文：`Expectation failed: (dismissBox.callCount → 0) == 1`。
- 還原後 `CampaignEditFeatureTests`：`8 passed，0 failed，0 skipped`；`OrderEditFeatureTests`：`42 passed，0 failed，0 skipped`。
- [x] 3.3 [after: 3.2] 依「取樣值必須讓正確與錯誤實作得出不同結果」修正 `OrderEditFeatureTests.dateComponentsChangedMergesInjectedSeconds`：注入秒數非 0 的時間 (例如第 42 秒)，預期值直接寫出秒數。另外處理 `OrderEditFocusTests.reopeningStartsFromACleanFocusState`：透過父層實際「開啟、設定焦點、關閉、再開啟」後斷言焦點為空；若父層流程無法以 TestStore 表達，改名為只驗證初始狀態。驗證：暫時讓 reducer 不合併注入時間的秒數，前者轉紅；後者若保留重開流程，暫時讓重開沿用上次焦點時轉紅；都記錄訊息原文或改名理由。

實作與驗證紀錄 (2026-09-14，iPhone 17 / iOS 26.5)：

- `dateComponentsChangedMergesInjectedSeconds` 改注入 `TestDependencies.fixedNow + 42 秒`，預期值直接指定 `expectedComponents.second = 42`。
- `OrderEditFocusTests` 原測試只建立 `OrderEditFeature.State`，沒有父層開啟、關閉、再開啟流程可供驗證；因此改名為 `newFormInitialStateStartsFromACleanFocusState`，明確只驗證 initializer 的初始焦點。實際 child flow 已由同檔的 blank-order、cancel 與 save 測試覆蓋。
- 暫時讓 reducer 將補秒改為 `0`：`OrderEditFeatureTests` 為 `1 test failed，41 passed，0 skipped`；失敗訊息指出預期 `Date(2026-06-15T09:30:42.000Z)`、實際為 `Date(2026-06-15T09:30:00.000Z)`。
- 還原前 focused classes：`OrderEditFeatureTests` `42 passed，0 failed，0 skipped`；`OrderEditFocusTests` `5 passed，0 failed，0 skipped`。
- [x] 3.4 [after: 1.1] 修正開團與根導覽相關的四條測試：
  - `CampaignReminderFailureTests.removingAnAbsentEventRemainsANoOp`：改送會實際呼叫 `removeReminder` 的操作，替身拋出錯誤時仍不出現 alert。
  - `CampaignFeatureTests.ordersProjectionDrivesCampaignSummary`：改為由 `RootFeature` 送出訂單變更後驗證開團投影更新，無法表達時刪除。
  - `CampaignIntegrationTests.anyCampaignActionSyncsOrdersCampaignCopy`：改名為實際驗證的 `campaignsLoaded` 情境。
  - `RootFeatureTests.smartGroupSelection_updatesReducerStatusFilter`：改名並只驗證 reducer 寫入的選取狀態，不新增測試專用的產品 API。

  驗證：前兩條與第四條各自做一次變異 (讓移除事件的錯誤觸發 alert、讓投影不再同步、讓 chip 判斷恆為選取)，測試轉紅並記錄訊息原文；第三條以名稱與斷言一致作內容審查。

實作與驗證紀錄 (2026-09-15，iPhone 17 / iOS 26.5，UDID `DDAA3311-B464-4DD3-96B8-360B26AF1929`)：

- `removingAnAbsentEventRemainsANoOp` 先建立已有提醒連結的開團，再以 `wantsReminder = false` 送出實際的 `.editCampaign(.presented(.saveTapped))`；行事曆移除替身記錄呼叫一次後拋錯，測試仍驗證連結被清除且 `noticeAlert` 為 `nil`。
- `ordersProjectionDrivesCampaignSummary` 改由 `RootFeature` 收到 `.orders(.ordersLoaded(updatedOrders))`，直接驗證 `campaigns.orders` 投影，以及摘要由 1 筆／500 元更新為 2 筆／800 元。
- `CampaignIntegrationTests.anyCampaignActionSyncsOrdersCampaignCopy` 改名為 `campaignsLoadedSyncsOrdersCampaignCopy`；測試本來就送出 `.campaigns(.campaignsLoaded(...))`，名稱與操作一致。
- Root 測試驗證購買狀態後 reducer 的 `selectedStatus`；`OrdersView` 與 `OrdersCompactView` 保持直接比較 `store.selectedStatus == filter`，沒有新增測試專用的產品 API。
- 變異驗證：
  - 在移除不存在事件的錯誤分支暫時送出 `campaignWriteFailed("提醒連結移除失敗，請稍後再試。")`：`CampaignReminderFailureTests` 為 `1 test failed，10 passed，0 skipped`；原文包含 `Received unexpected action: CampaignFeature.Action.campaignWriteFailed("提醒連結移除失敗，請稍後再試。")`，並指出 `reminderLinks` 未清除與 `noticeAlert` 不為 `nil`。
  - 暫時移除 `RootFeature` 的 `state.campaigns.orders = state.orders.orders`：`CampaignFeatureTests` 為 `1 test failed，34 passed，0 skipped`；原文為 `store.state.campaigns.orders` 只有 `O1` 而預期含 `O1、O2`，摘要也由 `orderCount 1`／`receivables 500` 錯誤地維持原值而非 `2`／`800`。
  - 舊版 chip helper 恆回傳 `true` 的變異曾轉紅；該 helper 後續已撤掉，現行測試直接觀察 reducer 的 `selectedStatus`。
- 還原後 focused classes：`CampaignReminderFailureTests` `11 passed，0 failed，0 skipped`；`CampaignFeatureTests` `35 passed，0 failed，0 skipped`；`CampaignIntegrationTests` `6 passed，0 failed，0 skipped`；`RootFeatureTests` `35 passed，0 failed，0 skipped`，合計 `87 passed，0 failed，0 skipped`。
- [x] 3.5 [after: 1.1] 修正主檔與匯率相關測試：
  - `LookupCatalogTests.renamingPaymentMethodMergesFlagsWhenEitherSideIsTrue`：改名前先同時存在兩個付款方式，讓合併旗標的分支真正被執行。
  - `LookupManagementFeatureTests.addConfirmedWritesThroughToTheSharedCatalogFromAStandaloneContainer`：改從同一 scope 另宣告的 `@Shared(.lookupCatalog)` 讀取。
  - `FxFeatureTests.switchingCurrencyRecomputesRateFromSnapshot` 與 `bindingAmountUpdatesConvertedTwd`：注入與 `FxRateSnapshot.fallback` 不同的快照，預期匯率與金額直接寫出數值。

  驗證：暫時讓合併旗標只取目標方、讓 feature 寫入本地副本而非共享目錄、讓匯率改讀 fallback，對應測試各自轉紅並記錄訊息原文。

實作與驗證紀錄 (2026-09-15，iPhone 17 / iOS 26.5，UDID `DDAA3311-B464-4DD3-96B8-360B26AF1929`)：

- `renamingPaymentMethodMergesFlagsWhenEitherSideIsTrue` 先建立同名目標付款方式與來源付款方式，來源提供 `isBankTransfer`、目標提供 `isCardless`／`isCashOnDelivery`，改名後逐一驗證三個旗標都保留；`addConfirmedWritesThroughToTheSharedCatalogFromAStandaloneContainer` 從同一 scope 的另一個 `@Shared(.lookupCatalog)` 讀取；兩條 FX 測試注入非 fallback 的自訂 snapshot，直接驗證匯率 `200`／`8` 與換算金額。
- 暫時讓合併旗標只取目標方：`LookupCatalogTests` 為 `1 test failed，9 passed，0 skipped`；原文：`Expectation failed: (renamed?.isBankTransfer → false) == true`。
- 暫時讓 feature 把資料寫入 local copy：`LookupManagementFeatureTests` 為 `2 tests failed，21 passed，0 skipped`；standalone 測試原文：`Expectation failed: (sharedCatalog.categories → []) == ["手工藝品"]`，另有兩條 add-confirmed state expectation 失敗。
- 暫時讓匯率改讀 `FxRateSnapshot.fallback`：`FxFeatureTests` 為 `3 tests failed，6 passed，0 skipped`；`switchingCurrencyRecomputesRateFromSnapshot` 實際得到 `0.2105...` 而預期 `200`，`bindingAmountUpdatesConvertedTwd` 實際得到匯率 `0.0228...` 而預期 `8`。
- 還原後 focused classes：`LookupCatalogTests` `10 passed，0 failed，0 skipped`；`LookupManagementFeatureTests` `23 passed，0 failed，0 skipped`；`FxFeatureTests` `9 passed，0 failed，0 skipped`。
- [x] 3.6 [after: 1.1] 修正名稱與斷言不符的五條測試，逐條擇一補齊斷言或把名稱改成實際驗證的行為：
  - `AppLockFeatureTests.becomingActiveDoesNothingWhenProtectionIsDisabled`：明寫注入的 `biometryType`。
  - `BiometricAuthClientTests.successIsMappedRegardlessOfError`：涵蓋帶錯誤的成功回呼。
  - `InsightsStatsTests.costSegmentsExcludeZeroValueSegmentsAndTotalCostAggregatesAcrossAllRealizedOrders`：至少兩筆已實現與一筆未實現訂單。
  - `OrderDraftTests.existingOrderWritesPhotosOnlyWhenLoadedAndEdited`：涵蓋未載入完成的情境。
  - `OrderStatusTests.mergedIsOrderedAfterCancelled`：斷言與已取消的相對位置。

  驗證：補齊斷言的每一條各做一次變異並記錄訊息原文；改名的每一條以名稱與斷言一致作內容審查。

實作與驗證紀錄 (2026-09-15，iPhone 17 / iOS 26.5，UDID `DDAA3311-B464-4DD3-96B8-360B26AF1929`)：

- `becomingActiveDoesNothingWhenProtectionIsDisabled` 注入 `BiometricAuthClient.biometryType = .faceID` 並驗證前景事件仍更新類型；`successIsMappedRegardlessOfError` 新增 `success: true` 搭配非 nil error；成本測試加入兩筆已實現 (`delivered`／`pickedUp`) 與一筆未實現 (`quoting`) 訂單，預期成本總和為 `800`；照片測試加入 `.notLoaded` 且 `hasEditedPhotos = true` 的情境；順序測試直接比較 `merged` 與 `cancelled` 的索引。
- 暫時移除 AppLock 前景事件的 `biometryType` 更新：`AppLockFeatureTests` 為 `7 tests failed，7 passed，0 skipped`；目標測試原文顯示預期 `.faceID`、實際 `.unavailable`。
- 暫時讓成功 mapping 只有在 `error == nil` 時才回傳 success：`BiometricAuthClientTests` 為 `1 test failed，8 passed，0 skipped`；原文：`Expectation failed: (BiometricAuthClient.mapAuthenticationResult(success: true, error: error) → .failure) == .success`。
- 暫時讓 `totalCost` 只累加第一筆 attributed order：`InsightsStatsTests` 為 `1 test failed，8 passed，0 skipped`；原文：`Expectation failed: (stats.totalCost → 500) == 800`。
- 暫時讓既有訂單只依 `hasEditedPhotos` 判斷是否寫照片：`OrderDraftTests` 為 `1 test failed，11 passed，0 skipped`；未載入情境原文顯示實際照片為 `[3 bytes]` 且 `writesPhotos` 為 `true`，預期分別為 `[]` 與 `false`。
- 暫時把生成 enum 的 `merged` 排在 `cancelled` 前：`OrderStatusTests` 為 `1 test failed，5 passed，0 skipped`；原文：`(allCases.firstIndex(of: .merged)! → 8) > (allCases.firstIndex(of: .cancelled)! → 9)`。
- 還原後 focused classes：`AppLockFeatureTests` `14 passed`、`BiometricAuthClientTests` `9 passed`、`InsightsStatsTests` `9 passed`、`OrderDraftTests` `12 passed`、`OrderStatusTests` `6 passed`，合計 `50 passed，0 failed，0 skipped`。
- [x] 3.7 [after: 1.1] 修正斷言鑑別力不足的五條測試：
  - `CampaignSummaryTests.unassignedOrdersAreExcluded`：以明確的客戶名單取代空集合也成立的 `allSatisfy`。
  - `BLPhotoViewerTests.zoomAnimationIsNonNilWhenReduceMotionIsDisabled`：比對實際動畫值。
  - `ColorContrastTests.layerStackIsCompositedFromTheBottomUp`：改用只有由下往上合成才會得到的半透明異色圖層。
  - `ProjectionWriteBoundaryTests.projectionOwnerHomeFilesResolveToExistingSwiftFiles`：刪除比對同檔常數的數量斷言。
  - `LocalizationCatalogTests` 的 `sidebarSmartGroupAccessibilityDoesNotConcatenateLocalizedText` 與 `compactOrderFilterSummaryDoesNotConcatenateLocalizedText`：改用容忍空白與換行的比對。

  驗證：暫時讓分配表包含未歸團訂單、把縮放動畫換成其他動畫、把合成順序反轉、在來源檔插入含換行的 `Text + Text` 串接，對應測試各自轉紅並記錄訊息原文；刪除的斷言在本任務下方註明原因。

實作與驗證紀錄 (2026-09-15，iPhone 17 / iOS 26.5，UDID `DDAA3311-B464-4DD3-96B8-360B26AF1929`)：

- `unassignedOrdersAreExcluded` 改以 `distribution.map(\.customerName) == ["A"]` 驗證實際名單；PhotoViewer 測試以 `String(reflecting:)` 比對 `.snappy(duration: 0.2)`；ColorContrast 改用 `[Color.black.opacity(0.5), .white]`，預期由下往上合成的實際 ratio `5.28`；projection home-file 測試保留逐項檔案存在檢查並移除與 `projectionOwners` 同檔定義重複的 `count == 4`；兩個 localization scan 先折疊連續 whitespace，再比對禁止 pattern。
- 暫時讓 `CampaignSummary` 把所有非 merge-result 訂單都算入：`CampaignSummaryTests` 為 `3 tests failed，10 passed，0 skipped`；目標測試原文包含 `summary.orderCount → 2 == 1`、`summary.receivables → 1099 == 100`、`distribution ... ["A", "B"] == ["A"]`。
- 暫時把 PhotoViewer 動畫換成 `.easeIn(duration: 0.2)`：`BLPhotoViewerTests` 為 `1 test failed，1 passed，0 skipped`；原文直接比較 `AnyAnimator(SwiftUI.BezierAnimation(...))` 與預期的 `AnyAnimator(SwiftUI.FluidSpringAnimation(...))`。
- 暫時反轉色彩圖層合成順序：`ColorContrastTests` 為 `2 tests failed，6 passed，0 skipped`；目標測試原文為 `abs(ratio - 5.28) → 15.72`，另既有 success ratio 也由錯誤順序轉紅。
- 暫時在 RootSidebar 與 OrdersCompactView 插入含換行的 `Text + Text`：`LocalizationCatalogTests` 為 `2 tests failed，10 passed，0 skipped`；兩條 source scan 各自以 `Expectation failed: !normalizedSource.contains(forbiddenPattern)` 轉紅。
- 移除 `projectionOwners.count == 4` 的原因：該斷言只會重複驗證測試檔自己宣告的常數，無法偵測路徑內容正確性；保留的逐項 `fileExists` 與 declaration scan 才直接驗證清單每一項對應現有 Swift source。
- 還原後 focused classes：`CampaignSummaryTests` `13 passed`、`BLPhotoViewerTests` `2 passed`、`ColorContrastTests` `8 passed`、`ProjectionWriteBoundaryTests` `3 passed`、`LocalizationCatalogTests` `12 passed`，合計 `38 passed，0 failed，0 skipped`。

## 4. UI 測試支援層

- [x] 4.1 [after: 1.1] 依「等待與點擊 helper 失敗時直接附診斷失敗」與「Helpers cannot silently absorb a missing element」，在 `apps/ios/BuyLedgerUITests/Support` 新增會在逾時時附截圖與可及性樹並 `XCTFail` 的互動 helper (點擊前等待可點、點選單項目、清空並輸入)，接收呼叫端 `file`／`line`；`clearAndType(_:in:)`、`OrderEditScreen.typeCustomerName(_:)`、`AppNavigator.selectTab(_:)` 改用它們，不再於元素缺失時直接返回。驗證：UI 測試 target 建置成功；暫時新增一條點擊不存在 identifier 的探測測試，失敗訊息含該 identifier 且附兩個診斷附件，確認後刪除探測測試並記錄訊息原文。

實作與驗證紀錄 (2026-09-15，iPhone 17 / iOS 26.5，UDID `DDAA3311-B464-4DD3-96B8-360B26AF1929`)：

- `failWithDiagnostics` 併入 `Diagnostics.swift`，等待與點擊 helper 併入 `Waiting.swift`；逾時時以 `XCTContext` 附上「失敗畫面」與「失敗時的可及性樹」，再以傳入的 `file`／`line` 呼叫 `XCTFail`。`tapMenuItem`、`clearAndType`、`OrderEditScreen.typeCustomerName` 與 `AppNavigator.selectTab` 均改走這條失敗路徑；未保留暫時的 `Interaction.swift`。
- `xcodebuildmcp simulator build --scheme BuyLedgerUITests` 建置成功。
- 暫時加入 `InteractionDiagnosticsProbeTests` 點擊 `repair-false-passing-tests.missing`：預期 `1 test failed`；XCTest 原文為 `Failed to get matching snapshot: No matches found for Elements matching predicate '"repair-false-passing-tests.missing" IN identifiers'`，失敗訊息含該 identifier，確認診斷附件後刪除探測測試。
- [x] 4.2 [after: 4.1] 依「金額輸入一律先清空再輸入」與「Retyping a field leaves exactly the requested content」，讓 `FxScreen.typeAmount`、`QuoteScreen.typePrincipal`、`OrderEditScreen.typeChargedAmount` 共用同一個清空後輸入的 helper，欄位原本有任何內容 (含與目標相同的值) 都先刪除再輸入。在 `FxTests` 新增一條連續兩次輸入 1000 後斷言換算結果等於輸入 1000 的預期金額的測試。驗證：新測試在 1.1 記錄的 iPhone 模擬器通過；暫時恢復「現值等於目標值就略過刪除」的條件，新測試轉紅並記錄訊息原文。

實作與驗證紀錄 (2026-09-15，iPhone 17 / iOS 26.5，UDID `DDAA3311-B464-4DD3-96B8-360B26AF1929`)：

- `FxScreen.typeAmount`、`QuoteScreen.typePrincipal` 與 `OrderEditScreen.typeChargedAmount` 改共用 `clearAndType(_:in:)`；該 helper 不再比較現值與目標值，一律先送出刪除鍵，再輸入新文字。`FxTests.testRetypingSameAmountKeepsTheExpectedConversion` 連續輸入兩次 `1000`，以 UI 測試固定結果 `"$23"` 作為預期值。
- 還原後 `FxTests`：`3 passed，0 failed，0 skipped`。
- 暫時把 helper 改回「現值等於目標值時略過刪除」：`FxTests` 為 `1 test failed，2 passed，0 skipped`；目標測試原文：`XCTAssertEqual failed: ("$228,021") is not equal to ("$23")`。
- [x] 4.3 [after: 4.2] 把訂單相關 Page Object 與測試 (`OrdersScreen`、`OrderEditScreen`、`OrderDetailScreen`、`MergeFlowScreen`、`OptionPickerScreen`、`PhotoViewerScreen`、`Tests/Orders` 下的測試) 中「丟棄等待結果後直接點擊」與 `_ =` 丟棄等待結果的寫法，遷移到 4.1 的 helper。驗證：在這些檔案中搜尋，已沒有忽略 `waitUntilHittable` 或 `waitForExistence` 結果後繼續互動的寫法；1.1 記錄的 iPhone 模擬器上 `Tests/Orders` 的 UI 測試類別失敗數不多於 1.1 基準。

實作與驗證紀錄 (2026-09-15，iPhone 17 / iOS 26.5，UDID `DDAA3311-B464-4DD3-96B8-360B26AF1929`)：

- `OrdersScreen`、`OrderEditScreen`、`OrderDetailScreen`、`MergeFlowScreen`、`OptionPickerScreen`、`PhotoViewerScreen` 與 `Tests/Orders` 的互動均改用 fail-fast helper；`scrollToHittableGently` 修正為必須真的 `isHittable` 才成功，避免只因 frame 相交就繼續輸入。
- 搜尋確認沒有丟棄 `waitUntilHittable`／`waitForExistence` 結果後直接互動的未處理寫法；必要的座標點擊與原生焦點 fallback 均先處理存在／可互動結果並驗證後續狀態。
- iPhone 主回歸 `BuyLedgerUITests`：`56 passed，0 failed，0 skipped`；其中 `Tests/Orders` 全部通過。

- [x] 4.4 [after: 4.2] 把其餘 Page Object (`CampaignsScreen`、`CampaignDetailScreen`、`CampaignEditScreen`、`CustomersScreen`、`DashboardScreen`、`InsightsScreen`、`FxScreen`、`QuoteScreen`、`SettingsScreen`、`AISummaryScreen`、`AppLockScreen`) 的相同寫法遷移到 4.1 的 helper，`InsightsScreen.selectRange(_:)` 找不到分段時改為附診斷失敗。驗證：在這些檔案中搜尋，已沒有忽略等待結果後繼續互動的寫法；1.1 記錄的 iPhone 模擬器上 `Tests/Campaigns`、`Tests/Customers`、`Tests/Insights`、`Tests/Tools`、`Tests/Smoke` 的 UI 測試類別失敗數不多於 1.1 基準。

實作與驗證紀錄 (2026-09-15，iPhone 17 / iOS 26.5，UDID `DDAA3311-B464-4DD3-96B8-360B26AF1929`)：

- 其餘 Page Object 的等待、選單、輸入與讀值路徑均改用 fail-fast helper；`InsightsScreen.selectRange(_:)` 對未知 range 會附畫面與可及性樹診斷後失敗。
- 搜尋確認沒有忽略等待結果後繼續互動的未處理寫法；Campaigns、Customers、Insights、Tools、Smoke 類別均包含在完整回歸中並通過。
- iPhone 主回歸 `BuyLedgerUITests`：`56 passed，0 failed，0 skipped`。

- [x] 4.5 [after: 4.3, 4.4] 依「讀值方法回傳 Optional 區分元素不存在」完成收斂：
  - `DashboardScreen.kpiValue`、`CampaignDetailScreen.summaryValue`、`OrderDetailScreen.summaryValue`、`FxScreen.convertedValue`、`QuoteScreen.suggestedPriceValue`、`InsightsScreen.totalProfitValue`、`InsightsScreen.accessibilityValue(of:)` 改回傳 `String?`，呼叫端把「元素不存在」與「值為空」分成兩種失敗訊息。
  - 移除 `waitUntilHittable`、`tapMenuItem` 與查詢方法 `hasOrder`、`hasCandidate`、`hasPageCount`、`hasCustomer`、`hasCampaign` 的 `@discardableResult`。

  驗證：UI 測試 target 建置成功，編譯器不再有未處理的回傳值；在 `apps/ios/BuyLedgerUITests/Screens` 中搜尋，已沒有回傳空字串的讀值方法；暫時讓一條讀值測試查詢不存在的 identifier，失敗訊息明確指出元素不存在並記錄原文。

實作與驗證紀錄 (2026-09-15，iPhone 17 / iOS 26.5，UDID `DDAA3311-B464-4DD3-96B8-360B26AF1929`)：

- 所有指定讀值 API 改回傳 `String?`，呼叫端分別回報元素不存在與 accessibility value 為空；指定查詢方法與 `waitUntilHittable`／`tapMenuItem` 均移除 `@discardableResult`。
- `Screens` 搜尋無讀值方法 `return ""`；UI 測試 target 建置成功。將 Dashboard KPI identifier 暫改為不存在值後，`HarnessSelfCheckTests.testPopulatedProfileShowsContent` 轉紅，原文為 `淨獲利 KPI 卡的元素不存在`；還原後通過。

## 5. UI 測試斷言

- [x] 5.1 [after: 4.5] 依「UI 斷言改讀具體結果」與「UI assertions observe the outcome under test」修正四條 UI 測試：
  - `FxTests` 與 `QuoteTests.testQuoteSuggestsPriceAfterPrincipal`：在測試資料的固定匯率下，斷言預期金額且不是「—」。
  - `InsightsTests.testRangeSwitchingKeepsReady`：每次切換後斷言對應分段為選取狀態。
  - `CampaignDetailTests.testSettleFlowCancelDoesNotSettle`：取消後斷言開團仍未結團。

  驗證：暫時讓匯率換算回傳錯誤值、讓報價試算回傳 nil、讓期間切換不改變選取、讓取消結團也執行結團，對應測試在 1.1 記錄的 iPhone 模擬器轉紅並記錄訊息原文。

實作與驗證紀錄 (2026-09-15，iPhone 17 / iOS 26.5，UDID `DDAA3311-B464-4DD3-96B8-360B26AF1929`)：

- 正常實作 focused 驗證：5 passed，0 failed，0 skipped (Fx 兩條、Quote、Insights、Campaign settle cancel)。
- 變異驗證：匯率改動後得到 `"$22"` 而非 `"$23"`；Quote value 改為 nil 後得到 `"—"` 而非 `"$230"`；Insights 未切換時 `thirtyDays` 非選取；取消結團改為立即結團後「取消結團後開團不應顯示『已結團』狀態」失敗。全部還原後 focused 驗證通過。

- [x] 5.2 [after: 4.5] 修正 `HarnessSelfCheckTests` 三條自我檢查的前置條件：
  - `testDataDoesNotSurviveRelaunch`：先以有訂單的 seed 啟動並確認非空，再以空資料重啟斷言空狀態。
  - `testFixedNowGivesStableDateGrouping`：注入與 `BLUITestConfiguration.defaultReferenceDate` 不同的參考時間，並斷言該時間下應排第一的訂單列。
  - `testCalendarStubDoesNotPrompt`：經由開團提醒流程觸發行事曆權限請求。

  驗證：暫時讓 UI 測試模式改用磁碟 store、讓 `-BLUITestNow` 解析一律回預設值、讓行事曆替身不接管授權，三條測試各自轉紅並記錄訊息原文。

實作與驗證紀錄 (2026-09-15，iPhone 17 / iOS 26.5，UDID `DDAA3311-B464-4DD3-96B8-360B26AF1929`)：

- 正常實作 focused 驗證：3 passed，0 failed，0 skipped (data relaunch、fixed date、calendar stub)。
- 合併變異驗證 (build 284)：三條均轉紅；行事曆變異為 `行事曆替身驗收開團列表未就緒`，資料變異為 `空狀態容器「dashboard.emptyState」逾時仍未出現`，日期變異為 subtitle 未反映 `6月15日星期一`。還原後 3/3 通過。

- [x] 5.3 [after: 4.5] 修正其餘鑑別力不足的 UI 斷言：
  - `AppLockTests` 中重新驗證失敗後維持鎖定的測試：等重試結果回來後才斷言鎖定畫面仍在。
  - `OrdersListTests.testStatusChipFiltersOutOtherStatuses` 與 `testSearchByCustomerNameKeepsOnlyThatCustomer`：否定斷言前先確認目標列存在。
  - `OrderDetailTests.testCashOnDeliveryCorrectionPersistsAfterRelaunch`：比對含受影響筆數的完整確認語句。
  - `RootNavigationScreen.isTabSelected(_:)`：iPhone 版面改讀分頁按鈕的選取狀態。
  - `CampaignDetailScreen` 與 `OrderDetailScreen` 的結團／刪除確認檢查：改以確認 alert 的專屬按鈕辨識。
  - 未使用的 `assertProgressPairing`：刪除。

  驗證：每一項各做一次變異 (讓重試錯誤地解鎖、讓篩選不生效、改動確認文案筆數、讓 iPhone 版面停在錯誤分頁、以錯誤 alert 取代確認)，對應測試在 1.1 記錄的 iPhone 模擬器轉紅並記錄訊息原文；搜尋確認 `assertProgressPairing` 已無定義。

實作與驗證紀錄 (2026-09-15，iPhone 17 / iOS 26.5，UDID `DDAA3311-B464-4DD3-96B8-360B26AF1929`)：

- 正常實作 focused 驗證：8 passed，0 failed，0 skipped。
- 變異驗證：AppLock 未送失敗結果、status/search guard 被移除、主檔 count 被加 1、tab selection 恆真、結團／刪除確認文案改錯，對應測試均轉紅；代表性訊息包含 `重新驗證後未等到失敗結果文字`、目標列仍存在、預期 count 不符、錯誤分頁未回報選取態，以及確認 alert 不存在。還原後 8/8 通過；`assertProgressPairing` 無定義。

## 6. 收尾驗證

- [ ] 6.1 [after: 1.1, 2.1, 2.2, 2.3, 2.4, 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 5.1, 5.2, 5.3] 完整回歸：最後一次程式修改後，在固定 iPhone 17 與 iPad Air 11-inch (M4) 以淺色外觀完成主 scheme 單元測試與兩台 UI 主回歸；失敗數不多於基準，且沒有 UI skip。

## Claude review follow-up (2026-09-18，change 封存後的未提交修正)

本節是封存後依 r6、r7、r8、r9、r10 清單完成或待驗證的實際紀錄；change 不重新開啟、不 commit、不 archive。

### 1. P0 與 iPad 數字鍵盤

- `CurrencyMetadataCacheTests.swift` 已恢復 HEAD 的 `emptyRefreshPreservesExistingCacheAndReportsAnomaly`、`nonEmptyRefreshReplacesExistingCache`、`failedRefreshLeavesExistingCacheUnchanged`，保留 HEAD 檔頭 `2026/7/29`；搬入的 `replaceEmptyCodeList_rejectsWithEmptyCodeListError` 附加在檔案末端。
- `OrdersFeatureTests.editSaveFailure_preservesPresentedOrderAcrossReload` 的樣本查找已改成 `try #require(...)`。其餘命中 `originalID }!` 的行是既有改動檔內容，不是本輪新增；自檢原文已保留在最終回報。
- `mergeOrders_sourceFetchFailure_removesInsertedOrder` 已以可注入的來源查詢 closure 重寫；預設實作仍是 `modelContext.fetch`，測試只讓來源查詢拋錯，避免碰撞查詢先失敗。r6 先以完整 `performWithRollback` 清理版本與只呼叫 `rollback()` 的版本執行，兩者都通過；r7 再移除來源讀取 catch 的 `rollback()` 做擊殺變異，結果見第 5 節。因此來源讀取路徑保留 rollback-only，沒有新增產品清理。
- 這個結果與 save 失敗路徑並不矛盾：六條 save 變異都發生在 `save()` 嘗試失敗後，長命 context 仍可讀到 pending 插入，必須依保留的記錄實例直接刪除並掃殘留；來源讀取失敗發生在任何 `save()` 之前，r7 的擊殺變異證明單純 `rollback()` 正是該時序所需的清理。先前不帶 `()` 的 `merge-source-rollback-only.xcresult` 是 0 條執行，已不列為驗收證據。
- `quarantine_fileMoveFailure_reportsFileName()` 以唯讀來源目錄實際觸發 `PersistenceError.fileMoveFailed`，focused 測試已通過並保留在 `source-and-filemove-normal.xcresult`；此路徑不是只比較自行建構的錯誤值。
- iPad `dismissNumericKeyboard` 與 `OrderEditScreen.tapNumericKeyboardDone` 都只尋找並點擊 App 的 `Common.keyboardDoneButton`；元素不可互動時改點擊元素 frame 中心，仍未收起鍵盤就附診斷並失敗。共用 helper 不含 `XCTSkip`、系統收鍵盤鍵、return 鍵或平台分支，因此匯率、報價、建立訂單等測試不會被整條跳過。專用 `KeyboardDismissTests` 也不再使用 `throws`／`try` skip。

### 2. AppLock、產品支援與變異驗證

- `AppLockTests` 先等待冷啟動失敗，再確認重試按鈕進入停用中的驗證狀態、恢復可用並重新顯示失敗訊息；不再依賴測試專用的 accessibility value。UI 測試替身只在失敗情境延遲 3 秒回覆，讓既有的 `isUnlocking` 可觀察，並不改變驗證結果。
- `AppLockFeature.State` 沒有 `unlockRetryCount`；新增的 `isUnlocking` 是產品可觀察的驗證進行中狀態，`.retryUnlockTapped` 會清除既有的 `unlockDidFail` 並重新發起驗證，`AppLockView` 在驗證期間停用重試按鈕。
- AppLock 無作用重試變異：暫時將 `.retryUnlockTapped` 改為不發起驗證，以 `-only-testing:BuyLedgerUITests/AppLockTests/testAppLockEnabledStartsLockedAndStaysLockedWhenAuthenticationFails()` 執行；bundle `/private/tmp/repair-false-passing-tests-r10-bundles/applock-retry-no-auth.xcresult` 的 `TestCaseRuns` 為 `Failure|1`，失敗原文為 `重新驗證沒有完成一次新的失敗驗證`，位置為 `AppLockTests.swift:51`。產品程式已還原，正常 focused 測試 bundle `/private/tmp/repair-false-passing-tests-r10-bundles/applock-retry-fixed-3s.xcresult` 為 `Success|1`。
- `OrderStatusFilter.isSelected(current:)` 已移除，相關測試改名為 `smartGroupSelection_updatesReducerStatusFilter` 並只驗證 reducer state。
- `OrderPersistence` 的 save 失敗清理抽成 typed-throws `performWithRollback`；先取得插入記錄 id，再 rollback、直接刪除實例、處理殘留查詢；清理失敗不覆蓋原始 save 錯誤。六條 save 失敗變異的原文如下：
  - `Expectation failed: (stored.map(\.id) → ["BL-ROLLBACK-CREATE", "BL-ROLLBACK-SEED"]) == ["BL-ROLLBACK-SEED"]: save 失敗後 rollback 應只保留 save 前已存在的資料列`
  - `Expectation failed: (stored.map(\.id) → ["BL-ROLLBACK-UPDATE", "BL-ROLLBACK-SEED"]) == ["BL-ROLLBACK-SEED"]: save 失敗後 rollback 應只保留 save 前已存在的資料列`
  - `Expectation failed: (stored.map(\.id) → ["BL-ROLLBACK-UPSERT", "BL-ROLLBACK-SEED"]) == ["BL-ROLLBACK-SEED"]: save 失敗後 rollback 應只保留 save 前已存在的資料列`
  - `Expectation failed: (stored.map(\.id) → ["BL-ROLLBACK-SEED", "BL-ROLLBACK-MERGE"]) == ["BL-ROLLBACK-SEED"]: save 失敗後 rollback 應只保留 save 前已存在的資料列`
  - `Expectation failed: (stored.map(\.id) → ["BL-ROLLBACK-PHOTOS", "BL-ROLLBACK-SEED"]) == ["BL-ROLLBACK-SEED"]: save 失敗後 rollback 應只保留 save 前已存在的資料列`
  - `Expectation failed: (stored → [...BL-ROLLBACK-SEED-1, BL-ROLLBACK-SEED-2...]).isEmpty → false: seed save 失敗後不應留下任何 pending 新訂單`
- `OrderPersistence` 沒有 `#if DEBUG`／`ForTesting` 專用 hook；`consumedOrderFetcher` 是 `production-safe` optional seam，預設仍走 `modelContext.fetch`，目前只被來源讀取失敗測試注入。來源讀取 catch 維持 rollback-only，r7 的擊殺變異已證明測試會轉紅。

### 3. ios-dev-kit 與範圍紀錄

- 測試替身改用 `LockIsolated`；移除本 change 新增的 `@unchecked Sendable`、重複 Interaction 診斷檔與空診斷 helper；Given／When／Then、`try #require`、`- Throws`、V12 測試命名、case key path 與 Page Object 呼叫端 `file`／`line` 已依清單修正。
- `BLStatusPill` 新增 `.accessibilityElement(children: .combine)`，實際影響 8 個使用端，包含訂單列／訂單詳情與 `BLTagPill` 內部使用；已包含在 iPhone UI 回歸，未觀察到功能性 UI 失敗。`AppLockView`、`DashboardView`、`CampaignDetailView`、`BLAccessibilityID` 的 identifier 是接受的 UI 測試定位範圍例外。
- `failWithDiagnostics` 現在位於 `Diagnostics.swift`，等待／點擊 helper 位於 `Waiting.swift`；`apps/ios/BuyLedgerUITests/Support/Interaction.swift` 未保留。`PersistenceErrorContractTests.swift` 已刪除。
- `CURRENT_PROJECT_VERSION` 依 CLAUDE.md 建置規則由 264 推進至 353；這是建置副作用，尚未提交，決定隨本次 change 一併保留。
- 早期變異 bundle 已被系統清除：r6、r7、r8 的 bundle 目錄目前不存在，r9 只剩三個 AppLock bundle；那些輪次的變異證據以當時記錄的失敗原文為準，不能再以 bundle 複驗。r10 的三次變異 bundle 仍完整保留並可重新解析。
- save 變異 bundle 的輸出無法單獨分辨是「只呼叫 `rollback()`」還是「整段清理完全移除」；但 HEAD 的 `create` 原本就是插入後 save 失敗只呼叫 `rollback()`，等同 rollback-only 變異，因此該結論另有程式碼獨立佐證。

### 4. r10 最終回歸紀錄 (TCA 1.26.2)

回歸前以 `xcodebuildmcp simulator-management set-appearance --simulator-id DDAA3311-B464-4DD3-96B8-360B26AF1929 --mode light` 與 `xcodebuildmcp simulator-management set-appearance --simulator-id 6B65ED1C-3C2E-42BA-B1E7-08F606F175C5 --mode light` 成功鎖定淺色。兩次原文如下：

```text
🎨 Set Appearance

   Simulator: DDAA3311-B464-4DD3-96B8-360B26AF1929
   Mode: light

✅ Appearance successfully set to light mode

🎨 Set Appearance

   Simulator: 6B65ED1C-3C2E-42BA-B1E7-08F606F175C5
   Mode: light

✅ Appearance successfully set to light mode
```

- iPhone 17 主 scheme 單元測試：`/private/tmp/repair-false-passing-tests-r10-bundles/final-iphone-unit-tca1262.xcresult`；UDID `DDAA3311-B464-4DD3-96B8-360B26AF1929`；本地起訖 `2026-09-17 22:28:24 +0800`–`2026-09-17 22:29:48 +0800`；CLI 結果為 `704 passed`、`3 failed`、`0 skipped`，`TestCaseRuns` 為 `Failure|3`、`Success|853`。失敗：`SnapshotTests/orderEditViewBaseline()`、`SnapshotTests/orderEditViewMergeContextBaseline()`、`SnapshotTests/quoteViewBaseline()`；三條原文均為 `Issue recorded: Snapshot does not match reference.`。`dashboardViewBaseline()` 已通過。
- iPhone 17 `BuyLedgerUITests` 主回歸：`/private/tmp/repair-false-passing-tests-r10-bundles/final-iphone-ui-tca1262.xcresult`；UDID `DDAA3311-B464-4DD3-96B8-360B26AF1929`；本地起訖 `2026-09-17 22:31:36 +0800`–`2026-09-17 23:00:42 +0800`；CLI 結果為 `56 passed`、`0 failed`、`0 skipped`，`TestCaseRuns` 為 `Success|56`；無失敗或 skip 名稱。
- iPad Air 11-inch (M4) `BuyLedgerUITests` 主回歸：`/private/tmp/repair-false-passing-tests-r10-bundles/final-ipad-ui-tca1262.xcresult`；UDID `6B65ED1C-3C2E-42BA-B1E7-08F606F175C5`；本地起訖 `2026-09-17 23:01:04 +0800`–`2026-09-17 23:23:00 +0800`；CLI 結果為 `50 passed`、`6 failed`、`0 skipped`，`TestCaseRuns` 為 `Failure|6`、`Success|50`。失敗：`FxTests.testFxConvertsAfterSelectingCurrencyAndAmount()`、`FxTests.testRetypingSameAmountKeepsTheExpectedConversion()`、`KeyboardDismissTests.testNumericKeyboardToolbarDismissesKeyboard()`、`OrderCreateTests.testCreateOrderAppearsInList()`、`QuoteTests.testQuoteSuggestsPriceAfterPrincipal()` 均為 `數字鍵盤工具列的完成鍵未能收起鍵盤`；`OrderDetailTests.testCashOnDeliveryCorrectionPersistsAfterRelaunch()` 為 `Failed to determine hittability of \"lookupManagement.paymentMethodEditor.cashOnDeliveryToggle\" Switch: Activation point invalid and no suggested hit points based on element frame`。無 skip 名稱。
- 工具鏈對照：9/16 以前使用 Xcode 26.6.0／`iphonesimulator26.6`，9/17 起改用 Xcode 27.0.0／SDK `iphonesimulator27.0`；模擬器 runtime 兩邊仍是 iOS 26.5。`test_sim_2026-09-16T16-38-14-225Z…log` 顯示同一台 iPad、同一批 UI 測試在舊工具鏈為 `Executed 56 tests, with 0 failures`；數字鍵盤相關檔案在該綠燈後未再修改。本次新增的 6 條 iPad 失敗因此列為 SDK 換版待查，不歸因為本 change 的測試遮蔽修正。
- TCA 舊版在 Xcode 27.0.0 的建置錯誤原文為 `NavigationStack+Observation.swift:149: cannot form key path to main actor-isolated subscript`；因此才升級 `swift-composable-architecture` 至 1.26.2。三份回歸都在 TCA 1.26.2、固定 UDID 與淺色外觀執行，沒有重錄 snapshot 參考圖。三份回歸各自開始後至完成沒有修改 Swift 或 `project.pbxproj`；其後僅為本輪規範修正修改 `AppLockView.swift`。
- 本次 `dashboardViewBaseline()` 已通過，因此沒有 dashboard 差異待裁決。`orderEditViewMergeContextBaseline()` 與 `ordersCompactViewMultiSelectBaseline()`、`orderEditViewLongIdentifierBaseline()` 同屬不穩定 snapshot；舊工具鏈歷次回歸曾兩次通過、兩次失敗。本次未重錄參考圖，6.1 因單元測試 3 條失敗高於基準 2 條而維持未勾選；iPad 的 6 條失敗以工具鏈換版待查處理。

### 5. r7 focused 變異與收尾驗證

- 來源讀取擊殺變異：暫時移除 `mergeOrders` 來源讀取 catch 的 `modelContext.rollback()`，以 `-only-testing:BuyLedgerTests/OrderPersistenceTests/mergeOrders_sourceFetchFailure_removesInsertedOrder()` 執行；`1 discovered`、`1 completed`、`0 passed`、`1 failed`、`0 skipped`。失敗原文為 `Expectation failed: (stored → [BuyLedger.LedgerOrder(id: "BL-ROLLBACK-SOURCE", customer: ...)]).isEmpty → false: 來源讀取失敗後不應留下尚未落盤的合併結果`，位置為 `OrderPersistenceTests.swift:824`；bundle 目前已被系統清除，僅保留這段文字紀錄。產品檔已還原為只呼叫 `rollback()`。
- save 不對稱擊殺變異：將 `create` 暫時改回只呼叫 `rollback()`，以 `-only-testing:BuyLedgerTests/OrderPersistenceTests/create_saveFailure_removesInsertedOrder()` 執行；`1 discovered`、`1 completed`、`0 passed`、`1 failed`、`0 skipped`。失敗原文為 `Expectation failed: (stored.map(\.id) → ["BL-ROLLBACK-CREATE", "BL-ROLLBACK-SEED"]) == ["BL-ROLLBACK-SEED"]: save 失敗後 rollback 應只保留 save 前已存在的資料列`，位置為 `OrderPersistenceTests.swift:734`；bundle 目前已被系統清除，僅保留這段文字紀錄。產品檔已還原為 `performWithRollback`。
- 兩次變異均使用帶括號的 Swift Testing selector，且已逐一還原；class 級 focused 測試 `-only-testing:BuyLedgerTests/OrderPersistenceTests` 結果為 39 passed、0 failed、0 skipped，bundle 目前已被系統清除。

### 6. r8 假測試修正與變異驗證

- `CampaignDetailTests.testDetailReadyWithSummaryValues` 移除自我指涉的 count／非空斷言，改以 `campaignsWithOrders` seed 的具體結算值 `[$16,780, $11,800]` 守門。暫時把產品顯示的 `summary.receivables` 改成 `summary.receivedAmount` 後，focused 變異結果為 1 failed、0 passed、0 skipped；失敗原文為 `XCTAssertEqual failed: ("[\"$11,800\", \"$11,800\"]") is not equal to ("[\"$16,780\", \"$11,800\"]")`，位置為 `CampaignDetailTests.swift:54`；bundle 目前已被系統清除，僅保留這段文字紀錄。產品檔已還原。
- `FxTests.testFxConvertsAfterSelectingCurrencyAndAmount` 改選非預設的 USD、輸入 1000，具體預期為 `$32,468`，並額外確認結果卡片含 `1 USD`。暫時讓 `.fromCurrencySelected` 不更新 state 後，focused 變異結果為 1 failed、0 passed、0 skipped；失敗原文為 `XCTAssertTrue failed - 匯率頁來源幣別應為 USD，實際為：= 新台幣、$23、1 KRW = 0.0228 TWD $23`，位置為 `FxTests.swift:77`；bundle 目前已被系統清除，僅保留這段文字紀錄。產品檔已還原。
- `DashboardView.currentDateSubtitle()` 已套用注入的 `\.timeZone`，讓固定 UTC 依賴不再讀取機器時區；iPhone／iPad UI 的 `testFixedNowGivesStableDateGrouping` 均通過。單元 snapshot 仍需為 `dashboardViewBaseline` 提供 test dependency，已在本次完整回歸中揭露，未於回歸開始後修改。
- `OrderPersistence.swift` 的長行已按規範將註解移到上一行；`PersistenceRecoveryTests.swift` 的 `// MARK: - Nested Types` 後已補空行；r8 自檢無新增 Swift 行寬或排版輸出。

### 7. r9 修正與變異驗證

- `TestDependencies.withFixedNow` 現在同時注入 `$0.date`、`$0.calendar` 與 `$0.timeZone`，時區與 `fixedCalendar` 一致；因此 `dashboardViewBaseline()` 不再因缺少 `timeZone` test implementation 失敗，且未重錄 snapshot 參考圖。
- r9 要求的 `OrderDetailTests.testDetailSummaryTilesHaveValues` 已移除自我指涉的 `values.count`／`allSatisfy` 恆真斷言，改以 `fullOrders` seed 的具體摘要值 `[$11,800, $9,069, +$2,731]` 比對；r10 的變異 bundle 與原文見第 8 節。
- r9 要求的 `QuoteTests.testQuoteReadyAfterSelectingCurrency` 改選非預設的 USD，並以 Quote picker 的 accessibility value 斷言來源幣別確實套用；r10 的變異 bundle 與原文見第 8 節。
- `AppLockTests.testAppLockEnabledStartsLockedAndStaysLockedWhenAuthenticationFails` 改以既有失敗訊息、`isUnlocking` 對應的按鈕停用／恢復可用狀態，以及再次出現的失敗結果判定重試確實發生；移除 `AppLockFeature.State` 的重試計數器與 View 的測試專用 accessibility value。r9 時的重試無作用變異受環境阻塞，已在 r10 補做並記於下方。
- `PersistenceRecoveryTests` 的 quarantine 測試改為 `quarantine_fileMoveFailure_reportsFileName()`；defer 內的 `try?` 已補上失敗可忽略的理由，兩處 `Issue.record` 訊息改為正體中文且無句末句號。
- `CampaignDetailTests` 具體結算值斷言後已刪除冗餘的非空守門。r9 的 focused bundle 目前已清除，僅保留文字紀錄；`ordersCompactViewMultiSelectBaseline()`、`orderEditViewLongIdentifierBaseline()` 與 `orderEditViewMergeContextBaseline()` 均記為不穩定 snapshot，未重錄參考圖。r10 的 iPhone UI 正式回歸為 `Success|56`。

### 8. r10 AppLock、假測試變異與 TCA 1.26.2

- AppLock 正常 focused 驗證：`testAppLockEnabledStartsLockedAndStaysLockedWhenAuthenticationFails()` 在 UI 測試替身失敗回覆延遲 3 秒、產品使用 `isUnlocking` 可觀察狀態的版本上為 `Success|1`；bundle `/private/tmp/repair-false-passing-tests-r10-bundles/applock-retry-fixed-3s.xcresult`。
- AppLock 變異：暫時讓 `.retryUnlockTapped` 不發起新的驗證；以帶括號的 `-only-testing:BuyLedgerUITests/AppLockTests/testAppLockEnabledStartsLockedAndStaysLockedWhenAuthenticationFails()` 執行，bundle `/private/tmp/repair-false-passing-tests-r10-bundles/applock-retry-no-auth.xcresult`，`TestCaseRuns` 為 `Failure|1`。失敗原文為 `重新驗證沒有完成一次新的失敗驗證`，位置為 `AppLockTests.swift:51`；產品程式已還原。
- OrderDetail 變異：暫時把摘要第一張營收卡改顯示成本；以 `-only-testing:BuyLedgerUITests/OrderDetailTests/testDetailSummaryTilesHaveValues()` 執行，bundle `/private/tmp/repair-false-passing-tests-r10-bundles/order-detail-summary-mutated.xcresult`，`TestCaseRuns` 為 `Failure|1`。失敗原文為 `XCTAssertEqual failed: ("["$9,069", "$9,069", "+$2,731"]") is not equal to ("["$11,800", "$9,069", "+$2,731"]")`，位置為 `OrderDetailTests.swift:64`；產品顯示已還原。
- Quote 變異：暫時讓 `.fromCurrencySelected` 不更新來源幣別；以 `-only-testing:BuyLedgerUITests/QuoteTests/testQuoteReadyAfterSelectingCurrency()` 執行，bundle `/private/tmp/repair-false-passing-tests-r10-bundles/quote-selection-not-applied.xcresult`，`TestCaseRuns` 為 `Failure|1`。失敗原文為 `XCTAssertEqual failed: ("KRW") is not equal to ("USD") - 報價頁來源幣別應為 USD，實際為：KRW`，位置為 `QuoteTests.swift:81`；reducer 已還原。
- 上述三次變異均有實際執行數、使用帶 `()` 的方法 selector，並在每次執行後還原產品程式。
- TCA 升版已保留為本 change 的一部分：`swift-composable-architecture` 由 `1.25.5` 升至 `1.26.2`，並帶入 `swift-issue-reporting 2.1.0`；為避免同一 `IssueReporting`／`XCTestDynamicOverlay` target 的相依衝突，`xctest-dynamic-overlay` 同步由 `1.9.0` 升至 `1.13.1`。升版不是把 AppLock 測試改綠的產品修正；它先解除了 Xcode 27／TCA 舊版的編譯阻塞，讓 AppLock 的真實狀態修正與變異驗證可以執行。
- 升版影響評估：TCA 1.26.2 上主 scheme 已成功編譯，focused `AppLockFeatureTests.failedUnlockCanBeRetriedUntilSuccessful()` 為 `Success|1`；完整單元回歸未出現新的 deprecation 警告，僅保留既有警告與 Swift 6 module dependency scanner 對新相依圖的警告。未觀察到 `TestStore` 或既有 `exhaustivity = .off` 行為差異；目前沒有足以形成新硬規則或 gotcha 的升版行為，因此不另改 `CLAUDE.md`／`.claude/rules/`。

### 9. 知情接受與後續處理

- `AppLockView.swift` 的規範修正只移除 Private View 內的區域變數、補 `body` 的 `///`，沒有改變行為；固定 iPhone 17 的 `-only-testing:BuyLedgerUITests/AppLockTests` focused 驗證為 `3 passed`、`0 failed`、`0 skipped`，bundle `/private/tmp/repair-false-passing-tests-r10-bundles/applock-view-doc-focused.xcresult`，`TestCaseRuns` 為 `Success|3`。
- 6.1 形式上未達成：單元測試為 3 條失敗而基準為 2 條，iPad UI 為 6 條失敗而基準為 0 條。依使用者裁決知情放行；同一內容在 Xcode 26.6.0 下的 iPad 對照為 56 passed／0 failed，新增失敗歸入 Xcode 27.0.0／`iphonesimulator27.0` 工具鏈換版待查。
- AppLock 重試測試的綠燈依賴 UI 測試替身的 3 秒失敗回覆延遲；無延遲與 1 秒版本的變異 bundle 都是 `Failure|1`，原文均為 `重新驗證未進入執行中狀態`。這是已知的時序敏感點，未以測試專用正式 state、skip 或放寬斷言處理。
- r6、r7、r8 的 bundle 目錄已被系統清掉，r9 目前只剩三個 AppLock bundle；那些輪次的變異證據只剩文字紀錄。r10 的 AppLock、OrderDetail、Quote 三次變異都有完整 bundle、實際執行數與失敗原文，可重新複驗。
- `OrderPersistence.consumedOrderFetcher` 與其第二個 init 留在 release 編譯路徑，唯一注入端是測試；連帶使 `OrderRepository` 需要顯式 `Task<OrderPersistence, Never>` 型別標註，目前只有 inline 註解，未另建立測試專用編譯分支。
- `set-appearance` 的成功證據只有 CLI 自述原文，XcodeBuildMCP 不為此操作留下 log；本輪已把兩台模擬器的成功原文保留在第 4 節。
- 殘留弱斷言列為後續候選：`OrdersFeatureTests` 的 `aiSummaryTapped` 以產品自身的 `aiSummaryPrompt` 當期望值且只驗非空、`HarnessSelfCheckTests` 以 KPI 非空收尾、`OrderDetailTests` 的貨到付款流程以 `XCTAssertNotEqual` 收尾。
- iPad 在 iOS 27 SDK 下數字鍵盤工具列完成鍵收不起鍵盤已確認為確定性行為，且同檔 return 鍵測試通過；不在本 change 範圍內。另開一輪用 `xcodebuildmcp ui-automation` 實測判斷是 App 工具列完成鍵失效，還是 XCUITest 互動方式需要調整；本輪不放寬斷言、不加 skip、不嘗試修正。
