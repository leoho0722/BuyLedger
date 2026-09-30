## 1. 未知數實測 (決定後續範圍)

- [x] 1.1 依 design 決策：D3 外部儲存與 propertiesToFetch 雙保險，在拋棄式分支上實測 `@Attribute(.externalStorage)` 對 `OrderRecord.photos` 這個 `[Data]` 屬性是否成立：寫入三張各約 300 KB 的 JPEG 後，store 旁應出現外部資料檔 (檢查 `_SUPPORT/_EXTERNAL_DATA` 或等效路徑)。驗證：既有 `upsertPersistsPhotosRoundTrip` 維持綠，且人工確認外部檔存在與否。結論二選一並記錄——成立則 V17 保留該 attribute，不成立則拿掉 attribute、主目標改由 `propertiesToFetch` 獨立達成，並把實測結論寫進 `apps/ios/CLAUDE.md` 避免重複嘗試。實驗成果只留結論、不進最終 diff
- [x] 1.2 [P] 依 design 決策：D4 索引限縮在訂單表的 id 與 date，實測 `#Index` 是否計入 schema 指紋：只對 `CampaignRecord` 加一個索引，以既有 `v16StoreReopensWithoutMigration` 的落地 store 開啟，看是否被要求遷移。驗證：該測試綠代表索引不進指紋 (則小表索引可零成本補齊)，紅代表計入指紋 (則索引範圍維持只在訂單表)。結論寫入本 change 的 design 之 Open Questions 對應項並據以定案，實驗成果不進最終 diff

## 2. Schema V17：凍結 shadow

- [x] 2.1 依 design 決策：D5 移除同步兩表改以凍結 shadow 達成，在 `BuyLedgerSchemaV15` 與 `BuyLedgerSchemaV16` 主體的 `// MARK: - Nested Types` 內各新增 `SyncMeta` 與 `SyncQueueItem` 的內嵌 shadow，內容自 `Core/Sync/` 兩檔原樣搬入、屬性不增不減，並把兩個版本的 `models` 改為引用各自的 shadow。shadow 註解改寫為「僅為保住該版本指紋而凍結，runtime 恆為空、勿新增讀寫」，刪除描述 HLC、tombstone、Firestore Storage 的原始敘述。此即規格 Entities dropped from the target schema stay frozen in retained versions 的落地。驗證：專案可編譯，且既有 `v16StoreReopensWithoutMigration` 與 V15 起始的落地遷移測試仍綠 (證明兩版指紋未被改動)
- [x] 2.2 在 `BuyLedgerSchemaV16` 主體的 `// MARK: - Nested Types` 內新增改動前形狀的 `OrderRecord` shadow，逐欄複製目前 top-level 的全部屬性 (含帶 `originalName` 的對帳狀態欄位)，不加 `.externalStorage`、不加 `#Index`，並把 V16 的 `models` 改為引用該 shadow。逐欄對照以 `git show HEAD:apps/ios/BuyLedger/Core/Persistence/OrderRecord.swift` 為準。驗證：`v16StoreReopensWithoutMigration` (改寫為以 V16 shadow 建 store 的版本) 綠，代表 V16 指紋與改動前一致

## 3. Schema V17：新增版本與遷移段

- [x] 3.1 新增 `enum BuyLedgerSchemaV17: VersionedSchema`，`versionIdentifier` 為 `Schema.Version(17, 0, 0)`，`models` 列出全部 top-level `@Model` 且不含 `SyncMeta` 與 `SyncQueueItem`；`BuyLedgerMigrationPlan.schemas` append V17。驗證：新測試 `syncEntitiesAreAbsentFromV17Models` 綠——斷言 V17 的 `models` 型別名集合不含兩張同步表，而 V15 與 V16 仍含 (此測試同時防止未來誤刪 shadow)
- [x] 3.2 依 design 決策：D6 遷移 stage 種類以實測決定，先以 `.lightweight(fromVersion: BuyLedgerSchemaV16.self, toVersion: BuyLedgerSchemaV17.self)` append 到 `stages`，並把 `PersistenceContainer.make` 的 `Schema(versionedSchema:)` 由 V16 改指 V17。驗證：新測試 `v16StoreMigratesToV17PreservingOrdersAndPhotos` 綠；若該測試紅，改為 `.custom` 且 `willMigrate` / `didMigrate` 皆留空 (不搬動照片)，並在本 change 的 design 記錄實測原因。此為規格 Data preservation across retained migrations 中「stage 種類由測試證據決定」的落地
- [x] 3.3 改寫 `BuyLedgerSchema.swift` 檔頭 doc comment：保留版本列為 V15 (floor) / V16 / V17 (target)，說明 V17 移除兩張同步表並將照片位元組移出訂單列。驗證：內容審視——敘述與 `BuyLedgerMigrationPlan.schemas`、`stages` 的實際宣告逐項相符

## 4. 訂單記錄：照片儲存位置與索引

- [x] 4.1 讓 `OrderRecord.photos` 帶 `@Attribute(.externalStorage)` (依任務 1.1 結論決定是否保留)，doc comment 說明位元組存於 store 外部、未讀取此屬性的查詢不會載入。此即規格 Order photo bytes live outside the order row 的落地。驗證：新測試 `upsertPersistsMultiplePhotosRoundTrip` 綠——以三張較大 `Data` 寫入後讀回，位元組逐張相等
- [x] 4.2 依 design 決策：D4 索引限縮在訂單表的 id 與 date，在 `OrderRecord` 型別主體加 `#Index<OrderRecord>([\.id], [\.date])` (id 供等值查詢、date 供排序)；依任務 1.2 結論決定是否同時對小表補索引，不補時在 doc comment 記錄判準。驗證：`v17StoreReopensWithoutMigration` 綠，代表加索引後的 V17 指紋即為容器建構時的指紋

  > QA 修正輪修正記錄 (2026-08-01)：本任務驗證條件引用的 `v17StoreReopensWithoutMigration` 未實際走 `PersistenceContainer.make`，見任務 12.3 的修正記錄；`apps/ios/CLAUDE.md` 「`#Index` 不計入 schema 指紋」一句的舉證方式亦經 QA 證明不成立，已改寫，見任務 13.2 的修正記錄。`OrderRecord.swift`／六張小表記錄檔內引用同一舉證的 doc comment 已同步改寫用詞，`#Index` 宣告在六張小表記錄檔內的位置並統一移至 `// MARK: - Data Properties` 之下 (原放該段之上)，與 `OrderRecord.swift` 既有位置一致。

## 5. 移除死碼同步層

- [x] 5.1 依 design 決策：D5 移除同步兩表改以凍結 shadow 達成，刪除 `apps/ios/BuyLedger/Core/Sync/SyncMeta.swift` 與 `SyncQueueItem.swift` 兩檔與該空目錄；專案採 file system synchronized group，不需改 `project.pbxproj`。驗證：`grep -rn "SyncMeta\|SyncQueueItem" apps/ios/BuyLedger` 只命中 `BuyLedgerSchema.swift` 內 V15 與 V16 的 shadow，且 `apps/ios/BuyLedger/Core/Sync/` 不存在；iPhone 與 iPad 各 build 成功代表 group 正確拾取刪除

## 6. 持久層：讀取路徑不帶照片

- [x] 6.1 依 design 決策：D1 照片位元組退出清單讀取路徑，把 `OrderRecord` 的領域轉換改為可指定是否帶照片的形式 (不帶時照片欄位為空陣列)，並讓 `fetchAll()` 取不帶照片的形式、在其 `FetchDescriptor` 上以 `propertiesToFetch` 明確列出除照片外的欄位；`fetch(id:)` 維持帶照片。此即規格 Order collection reads exclude photo bytes 的落地。驗證：新測試 `fetchAllReturnsOrdersWithoutPhotoBytes` 綠——庫內含帶照片訂單，讀取全部後每筆的照片欄位皆為空

  > QA 修正輪修正記錄 (2026-08-01)：QA 變異測試證明整段拿掉 `propertiesToFetch` 後 `fetchAllReturnsOrdersWithoutPhotoBytes` 仍維持綠燈；該測試斷言的「照片為空」由 `toDomain(includingPhotos: false)` 單獨達成，`propertiesToFetch` 這層在測試中不可觀察，本案核心價值 (位元組不進記憶體) 唯一的實作機制沒有任何測試守著。已把 `FetchDescriptor` 組建抽成純函式 `OrderPersistence.fetchAllDescriptor()`，新增 `fetchAllDescriptorExcludesPhotosFromPropertiesToFetch` 直接斷言其 `propertiesToFetch` 內容含預期欄位且不含 `photos`；拿掉 `propertiesToFetch` 賦值後該測試轉紅。
- [x] 6.2 新增依訂單編號讀取照片的方法，回傳該訂單持久化順序的照片陣列；訂單不存在時回空陣列而非拋錯。驗證：新測試 `fetchPhotosReturnsStoredBytesInOrder` 與 `fetchPhotosForUnknownIDReturnsEmpty` 綠

## 7. 持久層：寫入路徑不可能清空照片

- [x] 7.1 依 design 決策：D2 apply 不再寫入照片，讓 `OrderRecord.apply(_:)` 移除對照片欄位的賦值，doc comment 寫明此路徑永不寫入照片、照片須走專用寫入；新增訂單的插入分支維持寫入呼叫端提供的照片。此即規格 Writes that do not carry photos leave stored photos intact 的落地。驗證：新測試 `upsertWithoutPhotosLeavesStoredPhotosIntact` 與 `insertingNewOrderPersistsItsPhotos` 綠
- [x] 7.2 新增帶照片的訂單寫入方法與帶照片的合併寫入方法，兩者都要求呼叫端顯式傳入照片陣列，並以既有的單次 `save()` 落盤維持原子性。驗證：新測試 `writeWithPhotosReplacesStoredSet` 綠——以不同照片集合寫入既有訂單後，讀回的照片等於傳入集合
- [x] 7.3 新增照片保全回歸測試，涵蓋所有經 `apply(_:)` 落地的路徑：批次改狀態、五種主檔與開團更名 (訂單來源、商品類別、付款方式、對帳狀態、開團)、以及不帶照片的一般寫入。驗證：新測試 `photosSurviveBatchStatusChange` 與 `photosSurviveEveryCascadeRename` 綠——執行上述每一種操作後，目標訂單的照片位元組與操作前逐張相等

  > QA 修正輪修正記錄 (2026-08-01)：`photosSurviveEveryCascadeRename` 內的交叉引用誤寫成 `PaymentMethodPersistenceTests.applyEditPreservesUnrelatedOrderPhotos`，實際測試名稱為 `applyEditPreservesExistingOrderPhotos`，已修正。

## 8. 持久層：收斂全表掃描

- [x] 8.1 讓 `upsertAll` 改用捕獲 `[String]` 訂單編號的 `#Predicate` 只撈相關列以建字典，取代無 predicate 的全表 fetch；插入分支與單次 `save()` 不變，並加註解說明只撈相關列的理由。驗證：新測試 `upsertAllLeavesUnrelatedOrdersUntouched` 綠——庫內 500 筆訂單、只批次更新 3 筆，其餘 497 筆的狀態、日期與照片完全未變

  > QA 修正輪修正記錄 (2026-08-01)：QA 指出 `upsertAllLeavesUnrelatedOrdersUntouched`／`mergeOrdersLeavesUnrelatedOrdersUntouched` (任務 8.2)／`upsertAllHandlesLargeIDBatch` (任務 8.3) 三條邏輯上偵測不到 `#Predicate` 被移除；退回全表 fetch 後 `recordByID` 雖含全部列，迴圈仍只套用傳入的 `orders`，斷言結果完全相同；三條命名寫「收斂全表掃描」，實際守的是「沒寫壞」而非「有收斂」。已把 predicate 組建抽成純函式 `OrderPersistence.idMembershipPredicate(_:)`，新增 `idMembershipPredicateMatchesOnlyGivenIDs` 直接對 `Predicate` 求值驗證只命中集合內的訂單編號；把 predicate 本體改為恆真後該測試轉紅。三條既有測試保留不刪 (仍守「沒寫壞」有價值)，doc comment 已改寫為如實描述其實際守備範圍，並指向 `idMembershipPredicateMatchesOnlyGivenIDs` 補上的收斂驗證。
- [x] 8.2 讓 `mergeOrders` 的第二段全表掃描改用捕獲被合併訂單編號的同型 predicate，排除新訂單編號的判斷維持在迴圈內。驗證：新測試 `mergeOrdersLeavesUnrelatedOrdersUntouched` 綠——只有指定的來源訂單轉為已合併狀態

  > QA 修正輪修正記錄 (2026-08-01)：見任務 8.1 的修正記錄，本任務改用同一份 `OrderPersistence.idMembershipPredicate(_:)`。
- [x] 8.3 補批次規模守門測試，確認捕獲陣列的 `#Predicate` 在實務可能的批次量級下可正確轉譯。驗證：新測試 `upsertAllHandlesLargeIDBatch` 綠 (一次 300 筆訂單編號)；若轉譯失敗則改為每 100 筆分批讀取、字典合併後仍以單一 `save()` 落盤，並更新該測試斷言。**實作備註**：`upsertAllHandlesLargeIDBatch` 以 300 筆訂單編號實測 `#Predicate` 直接轉譯可正確執行，未觸發上述分批 fallback，故本 change 未實作該分批讀取路徑；未實作不代表遺漏，若日後批次規模超出此實測範圍導致轉譯失敗，再依上述設計補上

  > QA 修正輪修正記錄 (2026-08-01)：見任務 8.1 的修正記錄，本任務 doc comment 已同步改寫為「驗證結果正確、不驗證是否真的收斂」。

## 9. Repository 層

- [x] 9.1 在 `OrderRepository` 新增三個 `@Sendable` 閉包欄位——依訂單編號讀取照片、帶照片的訂單寫入、帶照片的合併寫入——並補齊 `liveValue`、`testValue`、`previewValue` 三處實作；既有欄位語意不變。驗證：專案可編譯且既有 `OrderRepository` 相關測試全綠，代表既有呼叫端未受影響。**實作備註（已獲協調者核准之偏離）**：實際只新增兩個 closure（`fetchOrderPhotos`、`saveOrderPersistingPhotos`），而非 design Implementation Contract 字面要求的三個。第三個「帶照片的合併寫入」未新增：既有 `mergeOrders` 閉包恆為 insert（合成新 ID），照片本來就經 `OrderRecord.init` 無條件寫入，另開一個行為完全相同的閉包只是重複；design D8「把使用者挑選保留的照片顯式落地」已由呼叫端把使用者勾選集合賦值給 `newOrder.photos` 後交給既有 `mergeOrders` 達成，目標已兌現。此理由留供後續 QA 與 Style 審查參考，避免被誤判為遺漏

## 10. 訂單編輯器

- [x] 10.1 依 design 決策：D7 編輯器在照片載入完成前不寫入照片，在 `OrderEditFeature.State` 新增照片載入階段 (未載入／載入中／已載入／載入失敗) 與「使用者是否實際增刪過照片」兩項資訊；開啟既有訂單時不再自傳入訂單取照片，改為發出依訂單編號讀取照片的 effect，新訂單則直接視為已載入且為空。驗證：新測試 `editingExistingOrderLoadsPhotosOnAppear` 綠——TestStore 斷言開啟時送出載入 effect，收到結果後照片草稿等於庫內照片

  > 歸屬記錄：本任務的 `editingExistingOrderLoadsPhotosOnAppear` 為抑制其餘四種主檔載入 action 而以 `throw` 停用，其註解 (`OrderEditFeatureTests.swift`) 內含 `exhaustivity = .off` 字面字樣以說明「藉此不必呼叫」；此字樣會被別案 (`test-effectiveness-repair`) 的守門檔 `TestSuiteIntegrityTests.swift` 之 `exhaustivityRelaxationsDoNotExceedTheRecordedBound()` 正則掃描誤計入次數。已在該守門檔加註解行排除 (只計非註解行)，屬本案動到別案守門檔，於此補記歸屬；`isCommentLine` 排除邏輯與同檔既有的其他掃描共用同一種寫法，非本案獨創。

  > QA 修正輪修正記錄 (2026-08-01)：上一則歸屬記錄由本輪 QA 補齊 (原 tasks.md 未記錄此次跨案觸及)。
- [x] 10.2 讓儲存流程依載入階段與更動旗標分流：未更動 (含載入中、載入失敗) 走不帶照片的寫入，確實增刪過才走帶照片的專用寫入。此即規格 Photos persist with the order 中「僅在草稿已載入且使用者更動過時才寫入照片」的落地。驗證：新測試 `savingBeforePhotoLoadCompletesKeepsStoredPhotos`、`savingAfterPhotoLoadFailureKeepsStoredPhotos`、`savingWithEditedPhotosWritesEditedSet` 三條綠

  > QA 修正輪修正記錄 (2026-08-01)：QA 指出三條測試 (定義於 `OrdersFeatureTests.swift`，覆蓋 `OrdersFeature.resolveWriteResult` 的 `writesPhotos` 判斷) 分別是 `hasEditedPhotos = false` (loading／failed) 或 `.loaded + true`，沒有 `hasEditedPhotos = true` 但 `photoLoadPhase ≠ .loaded` 的案例，拿掉 `photoLoadPhase == .loaded` 這個判斷式三條仍全綠。已新增 `savingWithEditedFlagBeforePhotoLoadCompletesKeepsStoredPhotos` 補上該組合；拿掉 `.loaded` 判斷後該測試轉紅。另修正 `savingBeforePhotoLoadCompletesKeepsStoredPhotos` 的註解與實作不符：註解聲稱「即使 draftPhotos 意外非空」卻未實際設值，已補設非空 `draftPhotos` 使註解與測試相符。順帶修正 `OrdersFeature.swift` 同一段落 (`resolveWriteResult`) 內一處簡體字「维持」為「維持」。
- [x] 10.3 讓 `OrderEditView` 的照片區塊在載入中顯示載入狀態、載入失敗顯示失敗狀態，兩種情形都停用加入與刪除控制項，使用者無從產生更動；新增字串同步補進 `Localizable.xcstrings` 的 `en`。驗證：人工於模擬器確認兩種狀態的呈現與控制項停用，並確認英文模式不露中文

## 11. 合併流程

- [x] 11.1 依 design 決策：D8 合併流程在挑選步驟前載入雙方照片，讓合併流程在判斷是否需要進入照片挑選步驟之前，先依訂單編號載入兩張來源訂單的照片，並以載入結果計算合計張數與挑選畫面內容。驗證：新測試 `mergeLoadsBothSourcePhotosBeforeSelectionStep` 綠——TestStore 斷言載入完成前不進入挑選步驟，且挑選畫面的照片集合等於雙方庫內照片串接

  > QA 修正輪修正記錄 (2026-08-01)：QA 指出原實作以 `try?` 吞掉 `fetchOrderPhotos` 失敗，失敗時該方照片以空陣列進入挑選步驟、合併結果靜默無照片，違反 design.md 失敗模式「此失敗必須對使用者可見，不得靜默」(原文針對編輯器，但原則一致)；來源訂單未刪除故非不可逆資料遺失，但屬設計原則不一致。已改為 `do/catch`：任一方載入失敗即視為整體失敗 (不採「失敗方視為零張、成功方照常繼續」，避免低估合計張數)，送出新增的 `candidatePhotosLoadFailed` action，於 `State.photoLoadFailureAlert` 呈現一次性說明對話框並停留在候選選擇步驟，使用者可重新點選同一候選訂單重試。新增測試 `candidateTappedPhotoLoadFailureShowsAlertAndStaysOnCandidateStep` 覆蓋此路徑，`OrderMergeCandidateSheet` 補 `.alert(...)` 呈現，新增字串已補進 `Localizable.xcstrings` 的 `en`。
- [x] 11.2 讓合併確認後寫入新訂單時走帶照片的專用寫入形式，把使用者勾選保留的照片顯式落地。驗證：新測試 `mergeWritesKeptPhotosExplicitly` 綠——合併後讀回新訂單的照片等於勾選集合

## 12. 遷移測試

- [x] 12.1 在 `SchemaMigrationTests` 新增以 V16 shadow 落 store 的 helper (因 top-level 型別已是 V17 形狀)，並把既有 `v16StoreReopensWithoutMigration` 改寫為使用該 helper。驗證：改寫後的既有測試綠
- [x] 12.2 新增 `v16StoreMigratesToV17PreservingOrdersAndPhotos`：以 V16 形狀落下含 2 筆帶照片訂單與 3 筆對帳狀態主檔的落地 store，用 V17 計畫開啟後斷言筆數、每個欄位值與照片位元組逐項相等。此即規格 Data preservation across retained migrations 的機器守門。驗證：該測試綠
- [x] 12.3 新增 `v15StoreMigratesThroughV16ToV17` (沿用既有 V15 落 store helper，驗證兩段 stage 串接後資料完整、floor 未被意外抬高) 與 `v17StoreReopensWithoutMigration` (V17 指紋守門)。驗證：兩條測試綠

  > QA 修正輪修正記錄 (2026-08-01)：QA 兩次 stage 變異中 `v17StoreReopensWithoutMigration` 都維持綠燈；原實作用同一個 `BuyLedgerSchemaV17` 建 store 又開 store，且沒有走 `PersistenceContainer.make`，宣稱的「V17 指紋即為容器建構時的指紋」沒被驗證到。已改寫為兩階段皆呼叫 `PersistenceContainer.makeBootstrapForTesting(storeURL:)` (與 App 啟動同一入口，`PaymentMethodPersistenceTests.swift`／`PersistenceRecoveryTests.swift` 既有測試已採此模式)，兩階段皆斷言 `bootstrap.outcome == .healthy` 才繼續。

## 13. 文件同步

- [x] 13.1 刪除 `apps/ios/README.md` 專案結構表中的 `Core/Sync/` 一列 (該列現況還寫著已失效的舊 schema 引用理由)。驗證：內容審視——結構表與 `apps/ios/BuyLedger/Core/` 實際目錄逐項相符
- [x] 13.2 更新 `apps/ios/CLAUDE.md` 的「SwiftData Schema 與 Migration」一節：floor 仍 V15、target 改 V17，並新增兩條硬規則——(a) 照片位元組不隨訂單列讀取，新增讀取整表的路徑不得觸碰照片欄位，否則排除載入的效果會失效；(b) 訂單記錄的套用路徑不寫入照片，照片一律走專用寫入。另記錄任務 1.1 與 1.2 的實測結論避免下次重提。驗證：內容審視——敘述與 `BuyLedgerSchema.swift`、`OrderRecord.swift`、`OrderPersistence.swift` 的實際實作一致

  > QA 修正輪修正記錄 (2026-08-01)：QA 指出兩處敘述失準。(a) 「`#Index` 不計入 schema 指紋」的舉證方式不成立：QA 加對照組反證，新增一個帶 default 的欄位 (指紋必然不同)、空 stages 照樣開得起來，可見「開得起來」只證明 SwiftData 會為未登記的改動自動推導輕量遷移，不能反推指紋未變；結論在操作面仍安全 (QA 另做生產情境模擬：store 建於無索引時期、floor 宣告後來才加索引，遷移成功)，但舉證與措辭需改。已改寫為「加索引不需凍 shadow、既有 store 仍可正常遷移 (已由生產情境測試驗證)」。(b) 「照片只能經 `updatePersistingPhotos(_:)` 或 `mergeOrders(...)` 這兩個入口落地」不準確：`create(_:)` 與 `update(_:)` 的插入分支同樣經 `OrderRecord.init(order:)` 寫入照片 (`insertingNewOrderPersistsItsPhotos` 即測此)。已改寫為列舉「插入」(`OrderRecord.init(order:)`，涵蓋 `create(_:)`／`update(_:)`／`updatePersistingPhotos(_:)` 的插入分支與 `mergeOrders` 新單插入) 與「顯式覆寫」(`updatePersistingPhotos(_:)` 一處) 兩類實際入口。

## 14. 建置與升級驗收

- [x] 14.1 先 `cd apps/ios && agvtool next-version -all` 遞增 build number，再以 xcodebuildmcp 序列跑 iPhone 與 iPad simulator build (共用 build.db 不可並行)，接著跑主 scheme 全部單元測試。驗證：兩平台 build 成功、主 scheme 測試全綠 (含 `SchemaMigrationTests`、`OrderPersistenceTests`、`OrderEditFeatureTests`、`OrderMergeFeatureTests`、`SnapshotTests`；跑 snapshot 前先把模擬器外觀鎖淺色)
- [x] 14.2 人工升級驗收：以本 change 改動前的 commit build 一份、寫入數筆帶照片訂單產生 V16 store，再安裝本次 build 覆蓋。驗證：訂單筆數、每筆照片張數與對帳狀態值皆不變，App 未進入記憶體內容器的退化路徑，且開啟訂單編輯器可看到既有照片

## 15. Coding Style 審查修正

- [x] 15.1 移除生產碼與測試碼中散佈的設計決策編號 (D1／D2／D3／D7／D8，約 50 處)：這些編號只存在於本 change 的 `design.md`，archive 後會移到 `openspec/changes/archive/`，屆時程式碼內的編號會變成無法解析的懸空引用。逐處改寫為編號所指涉的行為本身 (如「D1」改寫為「已隨清單讀取路徑退出常駐」、「D2」改寫為「`apply(_:)` 不寫入 `photos`」)，確保移除編號後每句話仍自足、讀者不需查 design.md。驗證：`grep -rn "\bD1\b\|\bD2\b\|\bD3\b\|\bD7\b\|\bD8\b" apps/ios/BuyLedger apps/ios/BuyLedgerTests` 零命中；587 tests 綠燈 (純註解改動，無行為變更)（`OrderPersistence.swift`、`OrderRecord.swift`、`OrderRepository.swift`、`OrderEditFeature.swift`、`OrderMergeFeature.swift`、`OrdersFeature.swift`、`OrderEditView.swift`、`OrderPersistenceTests.swift`、`OrdersFeatureTests.swift`、`OrderMergeFeatureTests.swift`、`OrderEditFeatureTests.swift`、`PaymentMethodPersistenceTests.swift`、`SnapshotTests.swift`）
- [x] 15.2 刪除測試註解中引用本案任務編號的前綴 (如「對應任務 8.1」)：任務編號只存在於本 change 的 `tasks.md`，同樣會隨 archive 移動；引用 spec 需求「…」的部分維持不動 (`openspec/specs/**` 不隨 archive 消失)。驗證：`grep -rn "任務 [0-9]" apps/ios/BuyLedger apps/ios/BuyLedgerTests` 零命中（`SchemaMigrationTests.swift`、`OrderPersistenceTests.swift`、`OrderEditFeatureTests.swift`）
- [x] 15.3 移除測試與本 `tasks.md` 中以「(見 change 回報)」「(紅燈原文見本輪回報)」等指標引用變異驗證的紅燈結果：這些指標指向的是本輪對話記錄，不是任何持久化文件。改為直接刪除括號 (斷言的意義已寫在同一句話內，不需額外指標)（`OrderPersistenceTests.swift`、`OrdersFeatureTests.swift`、本 `tasks.md`）；另把 `OrderMergeFeatureTests.swift` 內「對應 design.md 失敗模式」的引用改為直接陳述該失敗模式本身，理由相同 (design.md 同樣會隨 archive 移動)
- [x] 15.4 修正七張記錄檔 (`OrderRecord` + 六張小表) 的 `#Index` doc comment 交叉引用：原寫「見 `BuyLedgerSchema.swift` 檔頭」，但該檔 11-22 行的檔頭 doc 並無「加索引不需凍結 shadow」的內容，實際位置在 `BuyLedgerSchemaV17` 的 enum doc；後者原本又自我循環寫「見 `BuyLedgerSchema.swift` 檔頭與平台 CLAUDE.md」。七處改為「見平台 `CLAUDE.md`」，`BuyLedgerSchemaV17` 的 enum doc 拿掉自我循環的部分只留「見平台 `CLAUDE.md`」。驗證：`grep -rn "BuyLedgerSchema.swift.*檔頭" apps/ios/BuyLedger` 零命中
- [x] 15.5 更新 `.claude/skills/swiftdata-schema-migration/SKILL.md` 反映本案建立的 V17 與「丟棄 entity 改以凍結 shadow 保指紋」新模式：**歸屬澄清**——此檔先前已被 `spec-corpus-hygiene` change 的任務 3.2 改過一輪 (把已隨版本收斂而移除的 V7/V8/V9/V10 舉例換成現存的 V15/V16 舉例)，該次改動與本案無關、不動它；本案在「前置確認」新增第三類決策規則「丟棄整個 entity → 同樣 `.lightweight`，但每個仍引用該型別的保留版本都要各自凍結 shadow (不只前一版)」，以 V16→V17 移除 `SyncMeta`／`SyncQueueItem` 為例，並在「完成後核對」清單補一項對應檢查。驗證：內容審視——新增段落與 `BuyLedgerSchema.swift` 的實際 V15/V16/V17 shadow 安排一致
- [x] 15.6 修正 `apps/ios/README.md` 專案結構表：任務 13.1 的驗收句宣稱「結構表與 `Core/` 實際目錄逐項相符」，但磁碟上有 7 個子目錄、表內只列 6 個，缺 `Core/Diagnostics/` (`CrashDiagnosticsClient.swift`，來自另一未追蹤的變更，非本案產出)。缺的那列不是本案責任，但本案的驗收句據此宣稱「逐項相符」並不成立；選擇補上該列 (而非改寫驗收句)，理由是結構表本就該反映現況、補上後任務 13.1 的原始驗收句自然成立。驗證：`ls apps/ios/BuyLedger/Core/` 與結構表逐項核對一致
- [x] 15.7 風格瑣項修正：(a) `OrdersFeatureTests.swift` 的 `// MARK: D7 Photo Write Gating` 補 `- ` 前綴並拿掉 D 編號；`OrderEditFeatureTests.swift` 的 `// MARK: - Helper Method` 因成員全為 `static let` 改名 `Static Properties`，並依 MARK 排序表移到 `// MARK: - Nested Types` 之前 (區段 1 早於區段 5)。(b) 精簡 `OrderPersistence.swift` 兩個抽出純函式、`SchemaMigrationTests.swift` 與 `OrderPersistenceTests.swift` 各兩處重複的「為什麼抽出來才測得到」舉證段落，抽出理由各留一句。(c) 移除 `OrderPersistenceTests.swift:805` 附近一處註解結尾句號。(d) 統一 `Localizable.xcstrings` 的照片載入失敗文案：`照片載入失敗，請稍後再試` 改為 `照片載入失敗，請稍後再試。` (補句號)，英文由 `Failed to load photos. Please try again later.` 改為 `The photos could not be loaded. Try again later.`，與同族 (主檔／匯率／訂單／開團載入失敗) 既有句式一致；同步改 `OrderEditView.swift` 內對應字面值。(e) 清除本案新寫內容中的破折號「—」「——」(生產碼 7 處、測試 8 處、`apps/ios/CLAUDE.md` 1 處)，只改本案新寫的，既有已提交內容不回頭清。驗證：587 tests 綠燈；`Localizable.xcstrings` 為合法 JSON 且新 key 已生效
- [x] 15.8 順手清除 `OrderPersistence.swift:100` 附近一處 pre-existing 懸空註解「供跨裝置同步逐欄合併時取本機 baseline」：同步機制已在 archive 的 `remove-web-backend` 移除，此註解描述的機制已不存在；本案是同步收斂案且大幅改寫該檔，屬最適合清理的位置。`OrderEditFeature.swift:1006-1008` 的空 `extension` 同屬 pre-existing 但與本案無關，維持不動
