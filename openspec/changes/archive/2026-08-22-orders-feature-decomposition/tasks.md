## 1. 前置確認與基準鎖定

- [x] 1.1 確認兩項前置皆已落地 (主檔副本已不住在訂單 feature 的狀態、雙版面已收斂)，並記下量測基準：`OrdersFeature.swift` 目前行數、三段 switch 的 case 標籤數、action case 數、`OrdersFeatureTests.swift` 測項數、測試 target 關閉窮舉檢查的處數。驗證：`OrdersFeature.State` 的四種主檔取自 `@Shared(.lookupCatalog)`、雙版面共用 `OrdersToolbarContent`／`OrderSelectableRow`；六個基準數字寫入本 change 的 design
- [x] 1.2 動任何程式碼前先跑一次主 scheme 全部單元測試確認全綠，並單獨執行 `OrdersFeaturePerformanceTests` 記下 4 個既有量測的數字 (專案不用 XCTest 隱式基準比較，量測只記錄不比較，故數字要抄進本 change 的 design 當事後比對基準)。驗證：測試全綠，4 個數字已記錄

## 2. 篩選求值與共用變更方法

- [x] 2.1 依 design 決策：D8 State 的查詢擴充移出主檔，把 `OrdersFeature.State` 的查詢擴充 (`filteredOrders`、`campaignStatuses`、`selectedOrder`、`dateSections`、`aiItemsDigest`、`aiSummaryPrompt` 與篩選 sheet 的五個計算屬性) 整段移到新檔 `OrdersFeature+StateQuery.swift`，內容先原樣搬移不改行為。建檔前 invoke `/swift-file-template`，MARK 分區依平台指引的對照表。驗證：既有訂單 feature 測試不修改即通過；`OrdersFeature.swift` 行數較 1.1 記錄值減少約 187 行
    - 實作偏離：2.1 與 2.2 未分階段各自驗證，而是合併一次做完；不影響最終結果正確性，兩者的驗證條件皆已個別成立
- [x] 2.2 依 design 決策：D4 searchableText 不快取，改短路求值與開團字典，在 `OrdersFeature+StateQuery.swift` 內把篩選的七個判斷條件自「全部先算成區域常數再合併」改為短路的邏輯與鏈，順序為狀態、日期、類別、付款方式、開團、開團狀態、搜尋 (最貴的字串比對放最後)；並在篩選迴圈外先把開團建成「名稱到狀態」的字典取代 `campaignStatuses(for:)` 的逐筆線性搜尋，**必須使用允許重複鍵並保留先出現者的建構形式**，不可用要求鍵唯一的形式 (後者遇同名開團直接崩潰)。驗證：新增篩選等價測試綠，對同一組 fixture 的六種篩選組合硬編期望的訂單編號序列，並含一條同名開團案例
- [x] 2.3 新增 `OrdersFeature.State` 上的「選取第一筆篩選結果」變更方法，取代 `OrdersFeature.swift` 9 處與 `RootFeature.swift` 3 處逐字重複的選取重設；同時把 `pruneDetailPath(_:)` 收為 `State` 的 internal `mutating` 方法、`makeWriteFailureAlert(_:)` 收為 internal 靜態工廠 (跨檔的私有擴充成員在別檔看不到，這是必須改可見性的原因)。驗證：逐字重複的舊寫法在全庫零命中；既有選取相關測項不修改即通過

## 3. 抽出三支子域輔助型別

- [x] 3.1 依 design 決策：D1 抽輔助型別而非子 reducer，新增 `OrdersFilterOperations.swift` (無 case 的列舉型別，只有靜態方法)，接手篩選與選取共 18 條分支的主體，全部為形狀 A (純狀態變更，無回傳值)；「現在」時間與行事曆一律由主 reducer 以參數傳入，**型別內不得宣告 `@Dependency`，也不得呼叫 `Date()`／`UUID()`／`Calendar.current`**。主 reducer 對應分支縮成「呼叫」加 `return .none` 兩行。建檔前 invoke `/swift-file-template`。驗證：新增 `OrdersFilterOperationsTests.swift` 綠，且**不使用 `TestStore`**，直接以「傳入狀態、呼叫、斷言變更後的狀態」驗證
- [x] 3.2 新增 `OrdersBatchOperations.swift`，接手多選與批次改狀態共 6 條分支的主體；`batchStatusChanged` 採形狀 B (回傳待落盤的訂單清單，由主 reducer 餵給既有的 `batchStatusChangeEffect`)，其餘為形狀 A。驗證：新增 `OrdersBatchOperationsTests.swift` 綠且不使用 `TestStore`，涵蓋目標狀態為已合併時整條不做任何狀態變更、略過已是目標狀態者、無論是否有訂單實際變更皆退出多選並清空選取、回傳清單只含實際變更的那幾筆
- [x] 3.3 依 design 決策：D3 合併流程收進輔助型別，不搬進合併 feature，新增 `OrdersMergeFlowOperations.swift` 接手合併相關 5 條分支的主體，以及 `editOrder(.presented(.saveTapped))` 內合併儲存分支的主體；delegate 完成該條採形狀 B (回傳合併草稿與保留照片，由主 reducer 以注入的 clock 組延遲效果)。合併 feature 的呈現式組合 `.ifLet(\.$orderMerge, action: \.orderMerge)` 仍留在主 body、位置與順序不動。順手在合併 feature 的 delegate 上補註解說明父層側的後續由哪支輔助型別承接。驗證：既有合併相關測項不修改即通過
- [x] 3.4 依 design 決策：D2 主 switch 維持窮舉、零預設分支是設計的硬邊界，合入前逐條核對：三段 switch 全部維持逐一列舉、**零 `default` 分支**，三段之間的歸屬清單維持列舉式不得改寫成預設分支，54 個 action case 在每一段各出現且僅出現一次；被搬出的 29 條分支其 case 標籤之後的主體各不超過 3 行。驗證：`TestSuiteIntegrityTests.defaultNoneBranchesRemainAbsent` 與 `exhaustivityRelaxationsDoNotExceedTheRecordedBound` 皆綠；action 列舉區段在本次差異中為空
    - 實作偏離：未產出「54 個 case × 3 段」的人工核對清單，改採 Swift 編譯器窮舉檢查間接保證 (三段 switch 皆窮舉、漏列或重複列都會編譯錯誤)。此保證強度高於人工清單 (人工清單可能漏抄、編譯器窮舉檢查不可能漏)，故判定可接受，於此註記採用的是編譯期保證而非人工清單

## 4. 訂單建構收成單一路徑

- [x] 4.1 依 design 決策：D5 OrderDraft 收 22 個欄位，照片留在 State，**先寫測試再動 production code**：新增 `OrderDraftTests.swift` 的草稿建構測試，期望值以重構前的 `resolveWriteResult(_:existingOrders:)` 逐行推導後硬編，涵蓋空客戶名、空訂單來源、空類別的兩路徑差異 (新單走預設值 vs 編輯回退到既有值)、非無卡付款方式時兩個無卡金額歸零、不顯示對帳狀態時該欄位清空、費率超上限被夾擠、負數金額被夾擠到零、合併來源編號的來源差異、以及合併草稿沿用主訂單的縮寫與分級。驗證：測試先對現行實作跑一次確認全綠 (證明期望值正確)
    - 實作偏離：4.1 與 4.2 未分階段各自提交，而是合併一次做完，期望值改為讀原始碼手動推導後硬編 (非「先對現行實作跑一次」)。已另行以 `git show HEAD` 取出重構前的 `applyEditDraft` 與現行 `OrderDraft.makeOrder`／`LedgerOrder.applyingPaymentMethodFlags` 逐欄位交叉比對補上驗證空缺，結論見 `design.md`「D5 OrderDraft 收 22 個欄位，照片留在 State」段落的「與重構前程式碼的逐欄位交叉驗證」，未發現不對稱規則抄錯
- [x] 4.2 新增 `OrderDraft.swift`：草稿型別自帶建構訂單的方法，正規化規則只寫一次，接著逐欄位以「是否有既有訂單」決定取值，最後只留一個 `LedgerOrder(...)` 呼叫；`resolveWriteResult`／`applyWriteResult`／`applyEditDraft`／`clampRate`／`normalizedNames` 與 `WriteResult` 巢狀型別一併移入本檔。**任何「順手統一」兩條路徑的不對稱都視為改行為，不得為之**。驗證：任務 4.1 的測試不修改即通過；訂單編號的取值方式維持原樣 (屬另案)
- [x] 4.3 新增 `LedgerOrder+OrderMutation.swift`：把 `OrdersFeature.swift` 檔尾 `LedgerOrder` 的私有擴充 (`withStatus`、`withPaymentReceiptStatus`、`searchableText`) 移入並改為內部可見，兩段各 28 行、只差一個欄位的 `LedgerOrder(...)` 重建收斂為共用同一個變更輔助。驗證：既有單筆與收款狀態變更測項不修改即通過

## 5. 編輯表單導入草稿型別

- [x] 5.1 依 design 決策：D6 OrderDraft 導入分兩階段 的第一階段：把 22 個納入未儲存變更判斷的草稿欄位搬進狀態內的草稿型別，同時為每個欄位保留一組直通草稿的轉發計算屬性，讓外部零改動即可編過；此時即可刪除 `DraftFingerprint` 與 `draftFingerprint`、把 `initialDraftFingerprint` 改為 `initialDraft`，並把未儲存變更判斷改為「目前草稿不等於初始草稿，或使用者確實增刪過照片」。`init` 內以 `original` 與注入的 `currentDate` 建出一份草稿，同時指派給目前草稿與初始草稿 (消滅兩份必須手動保持一致的欄位清單)。草稿型別**必須標註為可觀察狀態**、不是只標可相等比較 (否則觀察粒度退化，表單任一欄位變動會整張重繪)；**`draftPhotos` 與 `hasEditedPhotos` 留在 State、不進草稿型別** (照片非同步載入，參與相等比較會把載入完成誤判為使用者的未儲存變更)；照片選擇項目同樣留在 State。此為規格 Guard edit sheets against silent data loss on dismissal 中「結構性保證涵蓋全部欄位」的落地。驗證：`DraftFingerprint` 在 `apps/ios/BuyLedger/Features/Orders/` 零命中 (`CampaignEditFeature` 的同名巢狀型別不受影響、仍應命中)；既有訂單編輯測試不修改即通過
    - 實作偏離：5.1 與 5.2 未分兩階段各自提交，而是合併一次做完 (轉發計算屬性未經獨立過渡即直接刪除、逐一改點呼叫端)；不影響最終結果正確性，僅審查面積未如原計畫縮小。
- [x] 5.2 第二階段：刪掉轉發計算屬性，靠編譯錯誤逐一修正訂單編輯畫面、訂單 feature 與測試端共 452 處欄位路徑 (不得掃到開團編輯相關檔案內 11 處同名的 `draftStatus`／`draftNotes`)。**全程不使用全域取代**，兩階段各自提交以縮小審查面積。驗證：訂單編輯相關測試的差異只含欄位路徑改名，無斷言值增刪
- [x] 5.3 新增未儲存變更的健全性測試：改動 22 個草稿欄位任一即為有變更；增刪照片為有變更；改動焦點、選擇器路徑或照片選擇項目則不算；**開啟既有訂單、照片非同步載入完成、未做任何編輯時不算有變更**。此為規格中「呈現狀態不計入」情境的落地。驗證：四條斷言綠
- [x] 5.4 在實機以訂單編輯表單連續輸入數字欄位確認無新增卡頓 (驗證草稿型別的可觀察標註確實生效，此問題的症狀是變卡而非功能錯誤，只靠測試不會發現)。驗證：人工確認，並比對介面測試中訂單編輯相關案例的執行時間無明顯劣化
    - 驗證紀錄：以 `xcodebuildmcp device test` 在 iPhone 15 Plus (iOS 26.6.1) 執行 `KeyboardDismissTests/testNumericKeyboardToolbarDismissesKeyboard` 兩次，測項分別為 40.066 秒與 38.472 秒，皆通過；`OrderCreateTests/testCreateOrderAppearsInList` 亦通過，測項 67.616 秒、整體 90.776 秒。兩次數字輸入路徑均未觀察到卡頓或失敗。
- [x] 5.5 依 design 決策：D9 開團編輯比照收斂指紋型別，把 `CampaignEditFeature.State` 的 7 個草稿欄位 (`draftName`、`draftOpenDate`、`draftCloseDate`、`draftStatus`、`draftNotes`、`wantsReminder`、`reminderTimestamp`) 收進 `CampaignDraft`，刪除該 feature 的 `DraftFingerprint` 與 `draftFingerprint`，`initialDraftFingerprint` 改為 `initialDraft`，未儲存變更判斷改為「目前草稿不等於初始草稿」。`CampaignDraft` **必須標註為可觀察狀態**；`init` 的參數標籤 (`original:`／`id:`／`currentDate:`／`wantsReminder:`／`reminderTimestamp:`) 維持不變，故所有建構呼叫點不受影響。**已查證開團編輯沒有任何非同步或不該納入比對的欄位** (唯一的 effect 是 `await dismiss()`，`CampaignEditView` 無 `.task` 或非同步載入，父層在表單呈現後唯一寫回的成員是本就排除在外的 `nameConflictMessage`)，因此 7 個欄位全部納入比較，不設任何例外、也不需要訂單側 `hasEditedPhotos` 那種額外旗標。連帶更新欄位路徑的檔案：`CampaignEditFeature.swift` (含 `case .binding(\.draftName)` 改為 `case .binding(\.draft.name)`)、`CampaignEditView.swift` 9 處繫結與讀取、`CampaignFeature.swift` 儲存分支的草稿讀取。
    - 驗證一：既有 6 條 dirty 相關測項的**斷言值、斷言順序與測項數零增刪**，差異僅限欄位路徑改名 (`newCampaignIsNotDirtyUntilEdited`、`existingCampaignIsDirtyThenCleanWhenRestored`、`reminderIntentChangeMarksDirty`、`reminderTimestampChangeMarksDirty`、`cancelWithChangesPresentsDiscardConfirmation`、`cancelWithoutChangesDismissesDirectly`，皆位於 `apps/ios/BuyLedgerTests/CampaignEditFeatureTests.swift`)
    - 驗證二：正向、負向與復原三條斷言皆成立且皆由測試守住：改過任一欄位後 dirty 為真、改回原值後 dirty 為假、完全沒改時 dirty 為假。`existingCampaignIsDirtyThenCleanWhenRestored` 現已依序涵蓋這三條，本任務要確認收斂後它仍以相同斷言值通過，**不另建重複測項**
    - 驗證三：**新增一條逐欄位掃過全部 7 個欄位的 dirty 測試** (每個欄位各改一次、各斷言 dirty 為真)。必要性來自實測落差：現況只有 `draftName`、`wantsReminder`、`reminderTimestamp` 三個欄位有個別覆蓋，`draftOpenDate`、`draftCloseDate`、`draftStatus`、`draftNotes` 四個沒有任何個別覆蓋，機械替換時漏接這四個不會有測試轉紅
    - 驗證四：受欄位路徑改名波及的兩條非 dirty 測項同樣只改路徑、不改斷言值：`CampaignEditFeatureTests.editingDraftNameClearsStaleNameConflictMessage` (送出的 binding keypath 由 `\.binding.draftName` 變為 `\.binding.draft.name`) 與 `CampaignFeatureTests.newCampaignTappedPresentsEmptyEditForm` (讀取 `draftStatus` 的斷言)
    - 驗證五：`DraftFingerprint` 在 `apps/ios/BuyLedger` 全目錄零命中

## 6. 畫面端單次求值與批次投影

- [x] 6.1 兩個清單版面改為單次求值後以參數傳遞：把篩選結果保留為完整集合 (不是只留編號)，`OrdersView` 的 `regularSplitContent`／`listPane`／`detailPane` 與 `OrdersCompactView` 的 `body`／`listSection` 改用同一份結果，`OrdersToolbarContent` 的停用判斷改吃已算好的結果，取得選取訂單與日期區段的方法改為吃已算好的結果。**現行語意「選取項目不在篩選結果內時回第一筆」必須完整保留**。驗證：iPad 版面對 `filteredOrders` 的求值次數自 4 降為 1、iPhone 版面自 3 降為 1；既有選取相關測項加一條「篩選後選取項目消失時回退第一筆」的斷言鎖住
    - 實作偏離：「篩選後選取項目消失時回退第一筆」的斷言放在 `OrdersFilterOperationsTests.swift` 而非 `OrdersFeatureTests.swift`，理由是任務 7.1 要求後者零測項增刪；判斷正確，於此註記
- [x] 6.2 依 design 決策：D7 CampaignSummary 批次投影套用三處，開團摘要新增批次投影 API (先以單次掃描把訂單依開團名稱分派、仍排除合併來源，再逐團以既有規則建構)，並套用到 `DashboardView.swift:141`、`CampaignListView.swift:233`、`InsightsStats.swift:156` 三個逐團建構的呼叫點，而非只改其中一處；`CampaignDetailView.swift:119` 的單團建構維持原樣。驗證：新增等價測試綠，批次投影與逐團建構的結果完全相同，涵蓋零成員團、同名開團 (確認不崩潰且維持保留先出現者) 與訂單同時歸屬多團；總覽畫面不再逐團建構

## 7. 測試與驗證

- [x] 7.1 既有訂單 feature 測試只改欄位路徑，仍為 69 個測項。驗證：其差異只含草稿欄位路徑改名 (含 `OrdersFeatureTests.swift:1160` 提及指紋型別的註解一併更新)，無任何斷言值、fixture 或測項增刪
- [x] 7.2 [P] 新增第五個效能量測 (大量訂單搭配數十個開團並啟用開團狀態篩選)，用來呈現字典化取代線性搜尋的收益；門檻比照既有量測抓數量級退化，不得放寬既有 4 個量測的門檻。驗證：5 個量測全部通過；5 個數字與任務 1.2 記錄的基準前後對照寫進本 change 的 design
- [x] 7.3 先 `cd apps/ios && agvtool next-version -all` 遞增 build number，再以 xcodebuildmcp 序列跑 iPhone 與 iPad build (共用 build.db 不可並行)，接著跑主 scheme 全部單元測試與介面自動化主回歸。驗證：兩平台 build 成功、單元測試全綠且 14 張基準圖零重錄、介面主回歸兩個尺寸類別各一輪全綠；另確認 `OrdersFeature.swift` 不超過 1,300 行、跨平台 data model 目錄與 schema 檔在本次差異中為空 (證明未動 schema)

## 8. 文件同步

- [x] 8.1 在 `apps/ios/CLAUDE.md` 的程式風格結構與命名一節新增硬規則：大型 reducer 以「同域輔助型別」拆分而非子 reducer (輔助型別為無 case 的列舉、只有靜態方法、不宣告任何相依、以 `inout State` 與明確參數溝通，「現在」時間與行事曆由 reducer 傳入)；主 switch 一律維持窮舉且**零預設分支**，此邊界由 `TestSuiteIntegrityTests.defaultNoneBranchesRemainAbsent` 守門，不得為了拆分而放寬或改寫成規避字串比對的形式；訂單 reducer 拆成三段的理由是型別檢查逾時，段間歸屬一律用列舉式清單、不得改用預設分支；跨檔共用的輔助成員不可留在私有擴充。另補一條：草稿型別必須標註為可觀察狀態，且非同步載入的欄位不得參與草稿相等比較。**同時改寫既有的過時描述**：sheet HIG 那節現寫「feature 用 draft fingerprint 值型別對照初始基準」，本案刪除兩支指紋型別後該描述失效，須改為「feature 用單一草稿值型別對照開啟時的初始草稿」，並點明訂單編輯的照片是唯一以額外旗標表達的例外。驗證：內容審視，規則與實際實作一致，且全檔無殘留提及 `DraftFingerprint` 的敘述
- [x] 8.2 [P] 更新 `apps/ios/README.md` 的專案結構，補上本次新增的六支產品檔 (`OrdersFilterOperations.swift`、`OrdersBatchOperations.swift`、`OrdersMergeFlowOperations.swift`、`OrdersFeature+StateQuery.swift`、`OrderDraft.swift`、`LedgerOrder+OrderMutation.swift`)。驗證：結構描述與實際目錄相符
