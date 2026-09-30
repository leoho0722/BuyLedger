## 1. 先把錯誤承載拆開

- [x] 1.1 先寫紅燈測試釘住「操作失敗不殘留」：斷言一次寫入失敗後關閉提示，列表呈現不含任何錯誤文字，且後續一次成功寫入不被先前失敗遮蔽。對應 spec requirement「One-shot operation failures are presented separately from load failures」。驗證：測試在實作前失敗（apps/ios/BuyLedgerTests/OrdersFeatureTests.swift）。
- [x] 1.2 讓一次性操作失敗與持續性載入失敗不再共用同一個訊息欄位：操作失敗改以可呈現的對話框狀態承載，載入失敗維持既有的失敗狀態與重試控制。依 design「一次性操作失敗與持續性載入失敗分成兩種呈現」。驗證：1.1 測試轉綠；既有的載入失敗與重試測試維持綠燈（apps/ios/BuyLedger/Features/Orders/OrdersFeature.swift、apps/ios/BuyLedgerTests/OrdersLoadStateTests.swift）。
- [x] 1.3 讓列表不再以常駐紅字呈現一次性失敗：兩種版面移除列表標頭的錯誤文字呈現，改掛對話框。驗證：兩個版面檔案中不再出現對錯誤訊息字串的直接呈現；UI 主回歸維持綠燈（apps/ios/BuyLedger/Features/Orders/OrdersView.swift、apps/ios/BuyLedger/Features/Orders/OrdersCompactView.swift）。實作備註：兩版面的持續性失敗文字改讀 `loadState`（`case .failed(let message)`）而非直接讀 `errorMessage`，視覺與行為不變，但不再與一次性失敗共用欄位。

## 2. 五條寫入路徑改為先寫後改

- [x] 2.1 先寫紅燈測試釘住五條路徑的不變性：以注入失敗的儲存層分別執行單筆狀態變更、批次狀態變更、收款狀態變更、刪除、編輯儲存，逐一斷言畫面狀態未變。對應 spec requirement「Order write paths update presented state only after persistence resolves」。驗證：五條斷言在實作前，除刪除外皆失敗（刪除已符合，作為對照）。實作備註：窮舉後發現刪除路徑實際上**未**符合既有規則（見任務 2.5 備註），故五條在改動前皆會失敗；已對五條逐一以刻意重現舊行為→確認轉紅→還原的方式驗證。
- [x] 2.2 讓單筆狀態變更與收款狀態變更在寫入成功後才更新畫面：兩條路徑改為由落盤成功的動作帶回結果並更新畫面狀態，失敗僅呈現對話框。依 design「五條寫入路徑一律改為寫入成功才更新畫面」。驗證：2.1 對應的兩條斷言轉綠，既有的成功路徑測試維持綠燈。
- [x] 2.3 讓編輯儲存在寫入成功後才更新畫面。驗證：2.1 對應斷言轉綠，且既有的編輯儲存流程測試維持綠燈。實作備註：連帶處理了新建 (create) 分支——改為先寫後改後，`state.orders` 從未被樂觀插入過，change 5 加入的 `orderCreationFailed` 快照回滾機制因此變得多餘並已移除（design 的 Decision 1 明確點名此為「不採用的替代方案」）。
- [x] 2.4 讓批次狀態變更在單次寫入失敗時一筆都不改變，不出現部分套用：改為寫入成功才套用整批變更。對應 spec requirement「Batch status persistence is atomic on Apple」的新增失敗語意，依 design「批次原子性補上失敗語意」。驗證：2.1 對應斷言轉綠，且以四筆選取訂單注入失敗後逐一斷言狀態與操作前相同。
- [x] 2.5 確認刪除路徑仍符合既有規則且未被本次改動破壞：對應 spec requirement「Deletion updates state only after persistence succeeds」；依 design「既有的刪除規則推廣為訂單寫入通則，而非新寫一條」，其範圍在本次推廣為涵蓋所有訂單寫入路徑。驗證：既有的刪除失敗測試維持綠燈，新增一條斷言非刪除路徑失敗時的行為與刪除一致。**實作備註（偏離 design 的前提）**：design 的 Context 段落斷言「刪除路徑已依規格採寫入成功才改狀態」，但實際程式碼中 `deletionConfirmation` 的 `confirmDelete` 分支在呼叫 `removeOrder` **之前**就先 `state.orders.remove(at:)`，失敗時僅落在共用的 `.ordersFailed`（只設 `errorMessage`，不回滾），故刪除路徑**並未**符合既有規則。已依 Implementation Contract（五條路徑一律先寫後改）一併修正，使其實際符合 spec；舊有的 `detailPathPrunesRemovedOrderAfterDelete` 測試同步改為 `await store.receive(\.orderDeleted)` 以等待新的成功動作套用。

## 3. 一致性驗證

- [x] 3.1 讓「畫面等於資料庫」成為可驗證的性質：新增測試在任一寫入失敗後重新自儲存層載入，斷言重載結果與失敗當下的畫面呈現相同。對應 spec requirement 中的重載一致性情境。驗證：五條路徑各一次，皆通過。
- [x] 3.2 補齊對話框文案的中英對照：新增字串納入本地化目錄的必備清單。驗證：本地化目錄測試綠燈，英文模式下無語言回退（apps/ios/BuyLedger/Resources/Localizable.xcstrings）。
- [x] 3.3 在 spec 補上合併路徑例外條款：`order-write-ordering` 的「Order write paths update presented state only after persistence resolves」補 Exception 段落與對應 scenario，明記合併路徑維持樂觀更新加快照回滾的既有例外及理由；`destructive-action-safeguard` 的 MODIFIED 段落同步指向該例外，避免歸檔後兩份 spec 與程式碼互相矛盾。對應 design「Risks/Trade-offs」第二條。驗證：三份 spec delta 皆可用 `merge` 檢索到對應敘述；`spectra validate orders-write-then-update` 通過。

## 4. 驗收

- [x] 4.1 執行整體驗收：主 scheme 全套單元測試綠燈且新增測試全程未關閉窮舉檢查、UI 主回歸在兩種尺寸各一次綠燈。驗證：測試通過數不低於改動前；對本次新增測試搜尋關閉窮舉檢查的呼叫零命中。實測：主 scheme 415 passed / 0 failed（改動前 409）；UI 主回歸 iPhone 49/50、iPad 49/50，唯一失敗皆為既有已知 flaky 的 `OrderCreateTests.testCreateOrderAppearsInList`。

## 5. Coding Style 審查修正

- [x] 5.1 讓寫入失敗對話框內文能真正本地化：`makeWriteFailureAlert` 與測試端 `expectedWriteFailureAlert` 的 `message` 參數型別由 `String` 改為 `LocalizedStringKey`（首選作法，比照 `DashboardView.kpiTile(delta:)`），呼叫端字面值自然命中；`orderWriteFailed` 攜帶的 `String` 在 reducer 內顯式包 `LocalizedStringKey(message)` 再傳入。堵住 `TextState(String 變數)` 命中 `@_disfavoredOverload` 的 verbatim init、英文模式露中文的缺陷。驗證：415 tests 綠燈；英文模式實機驗證對話框內文顯示英文（apps/ios/BuyLedger/Features/Orders/OrdersFeature.swift、apps/ios/BuyLedgerTests/OrdersFeatureTests.swift）。
- [x] 5.2 讓 `ToggleableFailureBox` 的巢狀替身錯誤改用檔案層既有的 `StubWriteError`（兩者語意重複），消除巢狀型別與段落順序違規，不必額外外移 extension。驗證：測試維持綠燈（apps/ios/BuyLedgerTests/OrdersFeatureTests.swift）。
- [x] 5.3 為 `private extension LedgerOrder`（測試端訂單複本 helper）補上遺漏的 `// MARK: - Private Method`。驗證：與同檔其餘 extension 段落排版一致（apps/ios/BuyLedgerTests/OrdersFeatureTests.swift）。
- [x] 5.4 修正三段 Reduce 拆分處與其他既有註解不符現況：由「兩個」改「三個」、「上一個 Reduce」改「前兩個 Reduce」（apps/ios/BuyLedger/Features/Orders/OrdersFeature.swift）。

## 6. QA 複驗修正

- [x] 6.1（阻斷）在 spec 補上合併路徑例外條款：見任務 3.3。
- [x] 6.2 讓開團詳情頁的收款勾稽寫入失敗也能看到說明對話框：`CampaignDetailView` 補掛 `.alert($store.scope(state: \.orders.writeFailureAlert, action: \.orders.writeFailureAlert))`，與同頁既有的 `campaigns.settleConfirmation`／`campaigns.detailDeletionConfirmation` 同一寫法（觸發當下所在畫面才會呈現）；`OrdersView` 原本的繫結維持不動，兩者互斥（分頁同時只會有一個在畫面上）。驗證：415 tests 綠燈（apps/ios/BuyLedger/Features/Campaigns/CampaignDetailView.swift）。
- [x] 6.3 讓冷啟動一致性測試證明「失敗的寫入沒有在 DB 留下半套資料」而非測試自行斷言：`deletionFailurePreservesPresentedOrderAcrossReload` 改為注入 `fetchOrders` 替身、以真正的 `.task` 觸發重載並 `store.receive(\.ordersLoaded)`，其餘四條路徑維持現狀不動。驗證：該測試綠燈（apps/ios/BuyLedgerTests/OrdersFeatureTests.swift）。
- [x] 6.4 評估並落實三段 Reduce 的編譯期窮舉檢查：把第三段 `default:` 改為逐一列舉前兩段已處理的 28 個 case（`return .none`），換回編譯器的窮舉保障。經實測驗證可行：build 59 秒完成（未逾時），415 tests 綠燈；另以臨時新增未歸類的 action case 驗證第三段 switch 會如預期編不過（`switch must be exhaustive`），驗證後已移除臨時 case（apps/ios/BuyLedger/Features/Orders/OrdersFeature.swift）。
- [x] 6.5 補齊「訂單載入失敗，請稍後再試。」的本地化目錄英文對照——此為 `.task` 載入失敗僅有的訊息、也是持續性失敗橫幅 `Text(LocalizedStringKey(message))` 現在唯一會渲染的字串，先前未被納入 change 7 的必備清單（apps/ios/BuyLedger/Resources/Localizable.xcstrings）。
- [x] 6.6 為 change 5（`order-identity-and-write-integrity`）任務 7.1 補上現況註記：該任務所述的建立失敗快照回滾機制與測試 `newOrderSaveRollsBackOptimisticInsertWhenCreateFails` 已在本案改為先寫後改後移除／更名，本案 spec 未要求該機制存在，移除不違反其規格（openspec/changes/order-identity-and-write-integrity/tasks.md）。
- [x] 6.7 在 `apps/ios/CLAUDE.md`「TCA TestStore」補一條 gotcha：純 `AlertState` 的 `.ifLet` 收到 `.presented` 動作時會由框架隱含自動清空該呈現（`PresentationReducer.swift`，`AlertState` 遵循 `_EphemeralState`；清空發生在 `base._reduce` 之後，父層仍讀得到該次呈現的值），窮舉測試容易多寫或漏寫一次 `$0.xxx = nil`（apps/ios/CLAUDE.md）。
