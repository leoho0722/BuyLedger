## Context

訂單 feature 現況 (本次重新量測，來源為 `apps/ios/BuyLedger/Features/Orders/OrdersFeature.swift`)：1,834 行、狀態 29 個儲存屬性搭 16 個計算屬性與 6 個查詢方法、action 54 個 case、reducer 的三個 switch 合計 65 條 case 標籤、相依注入 11 個。訂單編輯 feature (`OrderEditFeature.swift`) 1,160 行。

**reducer 本體已經是三段。** `body` 依序組出三個 `Reduce`，切分理由寫在原始碼註解：單一 switch 涵蓋全部 action case 會讓型別檢查逾時。三段各自窮舉，各自以一條列舉式清單把「由別段處理」的 case 交出去並回傳 `.none`，因此 65 條 case 標籤中 3 條是歸屬清單、62 條是實際處理分支。三段的實際處理分支分別為 30 條 (載入、主檔載入、篩選與選取、搜尋、編輯進場)、12 條 (編輯儲存、主檔新增、合併流程)、20 條 (單筆與批次狀態變更、收款、刪除、寫入失敗對話框、詳情堆疊、AI 總結)。

**檔案的區塊組成** (決定可搬與不可搬的邊界)：檔頭與 `OrderDateSection` 67 行、`State` 204 行、`Action` 189 行、相依宣告 34 行、reducer body 699 行、State 的巢狀型別 36 行、State 的查詢擴充 187 行、`WriteResult` 巢狀型別 20 行、`OrdersFeature` 的私有方法擴充 302 行、`LedgerOrder` 的私有擴充 87 行。其中 `State`／`Action`／相依宣告與檔頭共約 494 行依平台指引必須留在 reducer 主體內，是本檔行數的硬地板。

**草稿欄位清單抄了四遍。** 訂單編輯有 23 個 `draft` 開頭的儲存欄位，其中 22 個納入未儲存變更判斷 (`draftPhotos` 因非同步載入不納入，另以 `hasEditedPhotos` 追蹤)。這 22 個欄位的清單寫在四處：草稿欄位宣告、`DraftFingerprint` 的欄位、`draftFingerprint` 計算屬性的建構、`init` 內 `initialDraftFingerprint` 的建構。原始碼註解自己寫著「日後新增草稿欄位時須同步補進此型別，否則該欄位的變更不會被 `isDirty` 偵測」，等於把缺陷寫成使用說明。開團編輯 (`CampaignEditFeature.swift`，252 行) 是同一個形狀的縮小版：7 個草稿欄位、同名的 `DraftFingerprint`、同樣四處清單、同樣一句相同的註解。

**建構邏輯寫了兩遍。** `resolveWriteResult(_:existingOrders:)` 124 行，正規化規則已提到分支之前只寫一次，但編輯與新建兩條路徑各有一段 28 行、逐欄位手抄的 `LedgerOrder(...)`。檔尾另有 `withStatus(_:)` 與 `withPaymentReceiptStatus(_:)` 兩段各 28 行、只差一個欄位的 `LedgerOrder(...)` 重建。

**效能面。** iPad (regular) 在單次 body 更新內求值 `filteredOrders(referenceDate:calendar:)` 四次 (`OrdersView.swift:75`、`:159`、`:373` 經 `selectedOrder(referenceDate:calendar:)`、`OrdersToolbarContent.swift:79`)；iPhone (compact) 三次 (`OrdersCompactView.swift:38`、`:233` 經 `dateSections(...)`、以及同一處工具列)。篩選本身把七個判斷條件全部先算成區域常數再合併，狀態篩選早已排除的訂單仍會做日期判斷與開團的線性搜尋 (`campaignStatuses(for:)` 內對 `campaigns` 逐筆 `first`)。開團摘要在 `DashboardView.swift:141`、`CampaignListView.swift:233`、`InsightsStats.swift:156` 三處各有一次以開團數乘訂單數為量級的聚合，其中開團列表在每一列各建一次 (`CampaignDetailView.swift:119` 是單團建構，不在此列)。

**「選取第一筆篩選結果」逐字重複 12 處**：`OrdersFeature.swift` 9 處、`RootFeature.swift` 3 處。

**測試現況。** `OrdersFeatureTests.swift` 2,721 行、69 個測項，其中關閉窮舉檢查僅 2 處 (`:29`、`:1026`)；測試 target 全域 9 處，恰好等於 `TestSuiteIntegrityTests.exhaustivityRelaxationsDoNotExceedTheRecordedBound` 的上限，代表本案不得在任何地方新增關閉窮舉的設定。僅存的 2 處理由都是「並行或延遲效果的完成時序由 runtime 決定」，與子域是否混在同一個 reducer 無關，任何拆分方式都不會讓它們消失。`__Snapshots__` 目前 14 張基準圖。`OrdersFeaturePerformanceTests.swift` 有 4 個量測，其中 3 個量測 `filteredOrders`。

**前置狀態。** 主檔副本已不住在訂單 feature 的狀態 (State 以 `@Shared(.lookupCatalog)` 取得四種主檔)，雙版面的工具列與可勾選列已收斂為 `OrdersToolbarContent`／`OrderSelectableRow`。兩項前置皆已落地，本案可直接動工。

**約束。** 對外 action 語意不得改變 (既有 69 個測項的斷言值須一字不改仍全綠)；不得改動任何財務計算；不得動跨平台 data model；`apps/ios/BuyLedger` 內 `default: return .none` 必須維持 0 處。

## Goals / Non-Goals

**Goals:**

- `OrdersFeature.swift` 降到 1,300 行以內 (推導見 D8)，三個子域的分支主體移出主檔且各自可獨立單元測試
- 訂單編輯與開團編輯的草稿欄位各自收成單一型別，兩支指紋型別皆消失，「加欄位忘了加進未儲存變更判斷」從結構上不可能發生
- 訂單建構收成單一路徑，正規化規則只寫一次；狀態與收款狀態的兩段重建共用同一個變更擴充
- 清單兩個版面各自單次更新只做一次篩選求值；開團摘要改為單次掃描的批次投影
- 全程對外行為與 action 語意零變更

**Non-Goals:**

- 不改任何使用者可見行為
- 不動對外 action 語意
- 不拆成子 reducer，也不合併現有的三個 `Reduce`
- 不改任何財務計算
- 不改跨平台 data model
- 不順手修訂單編號取值範圍與主檔多來源
- 不拆 build target

## Decisions

### D1 抽輔助型別而非子 reducer

三個子域 (篩選與選取、批次操作、合併流程) 各以一支無 case 的列舉型別承接分支主體，放在獨立檔案：`OrdersFilterOperations`、`OrdersBatchOperations`、`OrdersMergeFlowOperations`。命名刻意避開 `Reducer`／`Action`／`Handler` 三個詞：它們不是 reducer、不是 action 型別、也不是回呼；它們是「該子域每條分支所做的事」。

**不用子 reducer 的兩個理由**：其一，並列子 reducer 唯一勝過輔助型別的地方是讓子域能在窮舉模式下獨立受測，而該動機已消失 (見 Context 的測試現況)；其二，並列子 reducer 必須以預設分支涵蓋不屬於自己的 action，直接違反 D2 的硬邊界。

**兩種簽章形狀**，依該分支是否需要副作用決定：

- **形狀 A (純狀態變更)**：`static func xxx(_ 參數..., to state: inout OrdersFeature.State, referenceDate: Date, calendar: Calendar)`，無回傳值。主 reducer 的分支寫成「呼叫」加 `return .none` 兩行。
- **形狀 B (需要副作用)**：`static func xxx(_ 參數..., state: inout OrdersFeature.State, ...) -> T`，回傳「該落盤或該送出的資料」。主 reducer 的分支拿回傳值餵給既有的私有 effect 工廠 (`batchStatusChangeEffect` 等)，三行內完成。

**相依一律留在 reducer**：輔助型別不宣告 `@Dependency`，也不呼叫 `Date()`／`UUID()`／`Calendar.current`；需要「現在」時間、行事曆、新識別碼時一律由主 reducer 解析後以參數傳入。這與 `OrdersFeature.State` 既有的 `filteredOrders(referenceDate:calendar:)` 是同一條規則，也讓輔助方法在測試中可完全決定性地驅動。

**跨檔可見性**：跨檔的私有擴充成員在別檔看不到，因此 `pruneDetailPath(_:)` 收為 `OrdersFeature.State` 的 internal `mutating` 方法、`makeWriteFailureAlert(_:)` 收為 internal 的靜態工廠，`LedgerOrder` 的 `withStatus`／`withPaymentReceiptStatus`／`searchableText` 私有擴充移到獨立檔並改為內部可見。這是必須改可見性的原因，不是順手放寬。

**子域案件歸屬** (依實測的 case 標籤逐條盤點)：

- 篩選與選取 18 條：`statusFilterSelected`、`datePeriodSelected`、`categoryFilterSelected`、`paymentMethodFilterSelected`、`campaignFilterSelected`、`campaignStatusFilterSelected`、`categoryPickerTapped`、`paymentMethodPickerTapped`、`filterSheetTapped`、`filterPendingDatePeriodSelected`、`filterPendingCategorySelected`、`filterPendingPaymentMethodSelected`、`filterApplyTapped`、`filterCancelTapped`、`filterDiscardConfirmation(.presented(.discard))`、`filterDiscardConfirmation` (兜底)、`searchTextChanged`、`orderSelected`。全部為形狀 A。
- 批次操作 6 條：`selectionModeToggled`、`orderSelectionToggled`、`selectAllTapped`、`clearSelectionTapped`、`batchStatusChanged`、`batchStatusChangePersisted`。其中 `batchStatusChanged` 為形狀 B (回傳待落盤的訂單清單)，其餘為形狀 A。
- 合併流程 5 條：`mergeOrderTapped`、`orderMerge(.presented(.delegate(.completed)))`、`orderMerge` (兜底)、`mergeConfirmationReady`、`mergePersistenceFailed`。其中 delegate 完成該條為形狀 B (回傳合併草稿與保留照片，由 reducer 以注入的 clock 組延遲效果)，其餘為形狀 A。另外 `editOrder(.presented(.saveTapped))` 內的合併儲存分支主體 (約 25 行) 一併搬入本型別，該分支的非合併路徑仍留在主 reducer。

合計移出 29 條分支的主體。原提案記的 11／5／5 是舊版程式碼的數字，本次依現況逐條重新盤點得出 18／6／5；差額主要來自 iPhone 整合篩選 sheet 的未套用流程 (`filterSheetTapped` 起共 7 條) 已列入篩選子域。

### D2 主 switch 維持窮舉、零預設分支是設計的硬邊界

三個 `Reduce` 的 switch 全部維持逐一列舉、**不得出現任何 `default` 分支**。這不是風格偏好，是機器守門：`TestSuiteIntegrityTests.defaultNoneBranchesRemainAbsent` (`apps/ios/BuyLedgerTests/TestSuiteIntegrityTests.swift`) 掃描 `apps/ios/BuyLedger` 並斷言 `default: return .none` 恆為 0 處，新增一處即轉紅。

因此本方案**不需要**任何「主分支維持窮舉以補償子 reducer 失去窮舉」的補償設計：分支本來就窮舉，本來就沒有預設分支，抽出主體不改變這件事。日後若有人為了縮短某段而「順手」補一個預設分支，守門會擋下，這條邊界不靠人記得。

三段之間的歸屬清單一律維持列舉式，禁止改寫成預設分支。合入前以三段的歸屬清單與各段實際處理的 case 逐一對照，54 個 action case 必須在每一段各出現且僅出現一次。

同理，**現有的三段切分不得合併**：切分理由是型別檢查逾時，與本次改動無關；抽走分支主體會讓每段變短，但那是讓逾時風險下降，不是讓合併變安全。

### D3 合併流程收進輔助型別，不搬進合併 feature

合併 feature 的狀態是呈現式的：delegate 送出後 sheet 隨即收合，之後的「確認就緒」與需要回寫訂單快照的「持久化失敗」在子 feature 裡沒有狀態可住。它的 delegate 邊界本來就乾淨，該收斂的是父層那 5 條分支的主體。

呈現式綁定 (`.ifLet(\.$orderMerge, action: \.orderMerge)`) 必須留在持有該狀態的 reducer 上，因此合併 feature 的組合仍留在主 body，位置與順序不動。

### D4 searchableText 不快取，改短路求值與開團字典

把七個判斷條件改成短路的邏輯與鏈，順序為狀態、日期、類別、付款方式、開團、開團狀態、搜尋，把最貴的字串比對放最後；並在篩選迴圈外先把開團建成「名稱到狀態」的字典，取代 `campaignStatuses(for:)` 目前對 `campaigns` 的逐筆線性搜尋。

**字典建構必須使用允許重複鍵的形式並保留先出現者**，不可用要求鍵唯一的形式：後者遇重複鍵會直接崩潰，而同名開團的問題尚未修復。保留先出現者與現行的線性搜尋語意一致。

替代方案有二，皆否決：把搜尋文字改成跨平台型別的持久化欄位，等於動跨平台 schema 加一次 schema 版本升級，成本與風險遠超收益；在狀態內存正規化索引，則要在載入、套用草稿、刪除、批次、合併回滾等七條路徑維持同步，而批次改狀態的逐列賦值會讓重建退化成平方複雜度。空查詢是最常見路徑，短路求值就已消掉大部分成本。

### D5 OrderDraft 收 22 個欄位，照片留在 State

納入未儲存變更判斷的 22 個欄位收進單一草稿型別 `OrderDraft`，而非再往下分成金額、費率、主檔選擇、呈現四個巢狀群組。一層就已完全達成目的：`DraftFingerprint` 可整個刪除，是否有未儲存變更變成結構性正確。再分一層不會多刪任何重複，卻讓 `OrderEditView.swift` 的 46 處草稿欄位引用再深一層，且「呈現」這一組的邊界主觀。

**`draftPhotos` 與 `hasEditedPhotos` 刻意留在 `State`、不進 `OrderDraft`**。理由是現行程式碼已記載的行為：編輯既有訂單時照片草稿非同步載入，若照片參與相等比較，`photosLoaded(_:)` 把空陣列填成實際位元組會被誤判為使用者的未儲存變更。因此未儲存變更判斷寫成「目前草稿不等於初始草稿，或使用者確實增刪過照片」。

這仍然滿足「結構性保證涵蓋全部欄位」：新增草稿欄位只需加進 `OrderDraft`，比較自動涵蓋，不存在需要同步維護的第二份欄位清單；照片是唯一且有明確技術理由的例外，由一個布林旗標表達，而非另一份欄位列舉。

**草稿型別必須標註為可觀察狀態**，只標可相等比較不夠：否則觀察粒度退化，表單任一欄位變動會讓整張表單重繪。

**草稿型別本身必須遵循 `Sendable`**：`OrderEditFeature.State` 帶顯式 `Sendable` 遵循，平台指引記載那是刻意的編譯期契約、不得移除。把欄位收進一個非 `Sendable` 的巢狀型別會讓該遵循編不過，屆時不可用「拿掉 State 的 `Sendable`」解決。現有 22 個欄位的型別皆已具備該遵循，故此為宣告義務而非改型別。

**初始草稿與目前草稿共用同一個建構子**：`init` 內以 `original` 與注入的 `currentDate` 建出一份 `OrderDraft`，同時指派給 `draft` 與 `initialDraft`。現行程式碼的 22 行草稿初始賦值與 22 行 `initialDraftFingerprint` 建構是兩份必須手動保持一致的清單 (原始碼註解明寫「各欄位運算式須與上方 draftX 的初始賦值保持一致」)，收成單一建構子後這條人工義務消失。無卡折抵金額仍取收斂後的值 (而非原始值)，讓「開啟即修正」不被誤判為未儲存變更。

**與重構前程式碼的逐欄位交叉驗證** (task 4.1 的驗證空缺補正)：任務 4.1 與 4.2 合併一次做完後，`OrderDraftTests.swift` 的期望值已無法照原計畫「先對現行實作跑一次」驗證 (`resolveWriteResult(_:existingOrders:)` 於同一次改動內已搬入並收斂進 `OrderDraft`)，改以 `git show HEAD` 取出本次改動前的 `OrdersFeature.applyEditDraft` 與現行 `OrderDraft.makeOrder`／`LedgerOrder.applyingPaymentMethodFlags` 逐欄位交叉比對：客戶名稱／訂單來源／類別／付款方式在草稿為空時「編輯回退既有值、新建改用預設值」的不對稱規則、非無卡付款方式時兩個無卡金額歸零、不顯示對帳狀態時該欄位清空、費率夾擠至 `[0, 1]`、金額夾擠至非負、合併來源編號僅新建列路徑寫入、合併草稿沿用主訂單客戶縮寫與分級，逐一核對後確認與重構前實作一致，未發現不對稱規則抄錯或遺漏。

開團編輯的同型收斂見 D9。

### D6 OrderDraft 導入分兩階段

一次改完 452 處草稿欄位引用 (production 243 處：`OrderEditFeature.swift` 138、`OrderEditView.swift` 46、`OrdersFeature.swift` 59；測試 209 處：`OrderEditFeatureTests.swift` 115、`OrdersFeatureTests.swift` 93、`RootFeatureTests.swift` 1) 難以審查，因此分兩階段。另有 11 處同名命中落在開團編輯相關檔案 (`draftStatus`／`draftNotes`)，那是該 feature 自己的草稿欄位、與本案無關，改動時不得一併掃到：

第一階段把 22 個欄位搬進草稿型別，同時為每個欄位保留一組直通草稿的轉發計算屬性，讓外部零改動即可編過；此時即可刪除 `DraftFingerprint` 與 `draftFingerprint`、把未儲存變更判斷改為草稿比對。第二階段刪掉轉發屬性，靠編譯錯誤逐一修正呼叫端。

全程不使用全域取代，兩階段各自提交以縮小審查面積。

### D7 CampaignSummary 批次投影套用三處

開團摘要新增批次投影 API：先以單次掃描把訂單依開團名稱分派 (仍排除合併來源)，再逐團以既有規則建構。`DashboardView.swift:141`、`CampaignListView.swift:233`、`InsightsStats.swift:156` 三個逐團建構的呼叫點全部改用，而非只改其中一處：這三處是同一個缺陷的三個實例，只修一處正是「規範只套在示範點上」的模式。三處都有既有測試作為安全網。`CampaignDetailView.swift:119` 是單一開團的建構，維持原樣。

### D8 State 的查詢擴充移出主檔

`OrdersFeature.State` 的查詢擴充 (`filteredOrders`、`campaignStatuses`、`selectedOrder`、`dateSections`、`aiItemsDigest`、`aiSummaryPrompt`，以及篩選 sheet 的五個計算屬性) 共 187 行，移到 `OrdersFeature+StateQuery.swift`。這是原提案未列的一項，加入的理由有二：它是 D4 短路求值與開團字典化的落點，改動集中在同一支檔比散在主檔可讀；而且不移它就達不到有意義的行數目標。

行數推導 (以現況 1,834 行為基準，各項為實測行段)：

- 移出 29 條分支的主體：目前佔約 270 行 (篩選與選取 115 行、批次 53 行、合併 76 行、`saveTapped` 內的合併儲存分支 26 行)，換成 29 條各「case 標籤加 3 行內主體」的呼叫式分支約 149 行，減約 121 行
- 移出 State 查詢擴充：減 187 行
- `resolveWriteResult` 與其周邊建構方法 (`applyEditDraft`／`applyWriteResult`／`clampRate`／`normalizedNames`) 連同 `WriteResult` 巢狀型別移入 `OrderDraft.swift`：減約 194 行
- `LedgerOrder` 私有擴充移出：減 87 行

合計減約 589 行，落點約 1,245 行。驗收門檻取 **1,300 行**，留約 4% 餘裕給新增的呼叫式分支與各檔的文件註解；門檻是上限而非目標，實作若落在 1,245 附近屬預期。

**這個目標受一個硬地板限制**：`State` 204 行、`Action` 189 行、相依宣告 34 行、檔頭與 `OrderDateSection` 67 行共約 494 行必須留在原處。平台指引明訂 `State`／`Action`／`CancelID` 屬 TCA 架構元素，寫在 reducer 型別主體內、不外移 extension。原提案「降到 700 行以內」的目標在此地板下不可達，本次改為可推導的 1,300 行。

### D9 開團編輯比照收斂指紋型別

`CampaignEditFeature.State` 有完全同型的問題：7 個草稿欄位 (`draftName`、`draftOpenDate`、`draftCloseDate`、`draftStatus`、`draftNotes`、`wantsReminder`、`reminderTimestamp`) 的清單同樣寫在四處 (欄位宣告、`DraftFingerprint` 的欄位、`draftFingerprint` 計算屬性的建構、`init` 內 `initialDraftFingerprint` 的建構)，原始碼註解同樣寫著「日後新增草稿欄位時須同步補進此型別，否則該欄位的變更不會被 `isDirty` 偵測」。本案一併收斂為 `CampaignDraft`，`DraftFingerprint` 與 `draftFingerprint` 刪除，未儲存變更判斷改為「目前草稿不等於初始草稿」。

**為什麼不留到另一個 change**：本案的規格變更要求未儲存變更防護以結構性保證涵蓋全部欄位、不得維護另一份欄位清單，而該要求的適用對象明文包含開團編輯。只收斂訂單側，本案落地當下就會產生一份程式碼當場違反的規格。替代作法是縮小規格措辭去遷就未收斂的程式碼，那是拿規則遷就實作，方向相反。7 個欄位與訂單側是同一個機械轉換，邊際成本遠低於留下一個已知違規。

**已查證：開團編輯沒有任何需要排除在比較之外的非同步欄位。** 訂單側之所以把 `draftPhotos` 排除，是因為照片在表單開啟後才非同步載入、載入完成會被誤判為使用者編輯。開團編輯不存在同類欄位：`CampaignEditFeature` 內唯一的 effect 是 `await dismiss()`，`CampaignEditView` 沒有任何 `.task` 或非同步載入，7 個欄位全部在 `init` 當下由 `original` 與 caller 傳入的參數決定；父層 `CampaignFeature` 在表單呈現後唯一會寫回子狀態的成員是 `nameConflictMessage`，而它本來就不在比較範圍內 (原始碼註解已標明「非草稿指紋成員：這是儲存結果的呈現狀態」)。因此 `CampaignDraft` 涵蓋全部 7 個欄位，沒有例外，也不需要照片那種額外的布林旗標。

**風險**：開團編輯的未儲存變更防護 (`CampaignEditView.swift:114` 的 `.interactiveDismissDisabled(store.isDirty)`、`cancelTapped` 於 dirty 時彈「捨棄變更／繼續編輯」確認) 完全依賴 `isDirty`。機械替換若弄壞它，症狀是使用者的未儲存編輯被靜默丟棄，畫面上不會有任何錯誤跡象，也不會有任何測試以外的訊號。

**緩解**：先確認既有 6 條 dirty 相關測試在改動後仍以相同斷言值通過，再補一條逐欄位掃過全部 7 個欄位的測試。補測試的必要性來自實測落差：現況只有 `draftName`、`wantsReminder`、`reminderTimestamp` 三個欄位有各自的 dirty 測試，`draftOpenDate`、`draftCloseDate`、`draftStatus`、`draftNotes` 四個沒有任何個別覆蓋，機械替換時漏接這四個不會有測試轉紅。

**收斂會改動欄位存取路徑，這點不可迴避**：`state.draftName` 變成 `state.draft.name`，`case .binding(\.draftName)` 變成 `case .binding(\.draft.name)`，`$store.draftName` 變成 `$store.draft.name`。因此驗收要求是「斷言值、斷言順序與測項數零增刪，差異僅限欄位路徑改名」，不是「一字不改」。`CampaignDraft` 同樣必須標註為可觀察狀態，否則 `$store.draft.name` 這類繫結的觀察粒度會退化，表單任一欄位變動會整張重繪。

`init` 的參數標籤 (`original:`、`id:`、`currentDate:`、`wantsReminder:`、`reminderTimestamp:`) 維持不變，因此所有建構呼叫點 (含測試的 fixture 建構) 不受影響。

**`CampaignDraft` 不另立檔案，就地取代 `CampaignEditFeature.swift` 內既有的 `DraftFingerprint` 巢狀型別。** 這與訂單側 `OrderDraft` 另立檔案的差別是刻意的：`OrderDraft.swift` 之所以獨立成檔，是因為它同時承接約 194 行自 `OrdersFeature.swift` 移出的訂單建構邏輯；`CampaignDraft` 只有 7 個欄位、不承接任何建構邏輯 (開團的建構留在 `CampaignFeature` 的儲存分支)，獨立成檔只會多一支十幾行的檔案。

**`CampaignDraft` 同樣必須遵循 `Sendable`**，理由與 D5 相同：`CampaignEditFeature.State` 帶顯式 `Sendable` 遵循，該遵循是不得移除的編譯期契約。現有 7 個欄位的型別 (`String`／`Date`／`CampaignStatus`／`Bool`) 皆已具備該遵循。

## Implementation Contract

**行為**

- 使用者可見行為零變更：清單、篩選、批次、合併、編輯、開團摘要的行為與改動前完全相同
- 未儲存變更防護的行為不變：改動 22 個草稿欄位任一即為有變更，增刪照片亦為有變更；改動焦點、選擇器路徑或照片選擇項目則不算；照片非同步載入完成不算
- 篩選結果與現行完全一致，包含同名開團時保留先出現者的語意
- 批次改狀態的既有語意不變：目標狀態為已合併時整條分支不做任何狀態變更；其餘情形無論是否有訂單實際變更，皆退出多選並清空選取

**介面與資料形狀**

- 新增：`OrdersFilterOperations` (18 條)、`OrdersBatchOperations` (6 條)、`OrdersMergeFlowOperations` (5 條加合併儲存分支主體)，三者皆為無 case 的列舉型別，只有靜態方法，不宣告任何相依
- 新增：`OrderDraft` (22 個欄位加建構訂單的方法，以既有訂單是否存在決定各欄位取值)；`LedgerOrder+OrderMutation.swift` (內部可見，因為跨檔的私有擴充成員在別檔看不到)；`OrdersFeature+StateQuery.swift`
- 修改：主 reducer 三段的 29 條分支主體改為呼叫輔助方法；`pruneDetailPath` 收為 `State` 的 internal mutating 方法、`makeWriteFailureAlert` 收為 internal 靜態工廠；狀態新增「選取第一筆篩選結果」的變更方法取代 12 處逐字重複
- 修改：訂單編輯狀態的 22 個欄位改為草稿型別，`DraftFingerprint` 與 `draftFingerprint` 刪除，`initialDraftFingerprint` 改為 `initialDraft`
- 修改：開團編輯狀態的 7 個欄位改為 `CampaignDraft` (就地定義於 `CampaignEditFeature.swift`，不另立檔案)，其 `DraftFingerprint` 與 `draftFingerprint` 刪除，`initialDraftFingerprint` 改為 `initialDraft`；`init` 參數標籤不變
- 修改：清單兩個版面改為單次求值後以參數傳遞；`OrdersToolbarContent` 改吃已算好的結果；開團摘要新增批次投影並套用三處
- **不變**：action 列舉的 54 個 case 名稱與載荷型別；三個 `Reduce` 的數量、順序與各自的 `.ifLet`／`.forEach` 組合

**失敗模式**

- 分支主體搬出時漏搬或搬錯歸屬：以「三段歸屬清單對照 54 個 case」與既有 69 個測項為守門
- 輔助方法自行取用系統時間或行事曆，會讓測試在不同機器跑出不同結果；一律以參數傳入
- 開團字典若使用要求鍵唯一的形式，遇同名開團會直接崩潰
- 草稿型別未標可觀察狀態時，症狀是表單輸入變卡而非功能錯誤，只靠測試不會發現
- 照片若被放進 `OrderDraft` 參與相等比較，症狀是開啟既有訂單、什麼都沒改就被判定為有未儲存變更
- 開團編輯收斂時漏接某個欄位，症狀是該欄位的編輯不再被視為未儲存變更，取消時直接關閉、使用者的編輯被靜默丟棄

**驗收條件**

- `OrdersFeature.swift` 行數不超過 1,300
- 被搬出的 29 條分支，其 case 標籤之後的主體各不超過 3 行
- `apps/ios/BuyLedger` 內 `default: return .none` 仍為 0 處 (`TestSuiteIntegrityTests.defaultNoneBranchesRemainAbsent` 綠)
- 測試 target 內關閉窮舉檢查仍為 9 處、未新增任何一處 (`TestSuiteIntegrityTests.exhaustivityRelaxationsDoNotExceedTheRecordedBound` 綠)
- action 列舉區段在本次差異中為空 (54 個 case 名稱與載荷型別零變更)
- `OrdersFeatureTests.swift` 仍為 69 個測項，其差異只含草稿欄位路徑改名，無任何斷言值、fixture 或測項增刪
- `DraftFingerprint` 在 `apps/ios/BuyLedger` 全目錄零命中 (訂單編輯與開團編輯兩支同名巢狀型別皆已刪除)
- 既有 6 條開團編輯 dirty 相關測項的斷言值、斷言順序與測項數零增刪，差異僅限欄位路徑改名
- 新增一條逐欄位掃過開團編輯全部 7 個欄位的 dirty 測試
- 逐字重複的「選取第一筆篩選結果」寫法在全庫零命中，12 處全部改走新的變更方法
- iPad 版面對 `filteredOrders` 的求值次數自 4 降為 1，iPhone 版面自 3 降為 1
- 總覽、開團列表與分析統計三處不再逐團建構開團摘要
- 新增的草稿建構測試以**重構前程式碼推導並硬編**的期望值，驗證兩條路徑下每一個欄位皆與重構前相同
- 新增的篩選與批次輔助方法測試**不使用 `TestStore`**，直接以「傳入狀態、呼叫、斷言變更後的狀態」驗證
- 主 scheme 全部單元測試綠，且 14 張基準圖零重錄
- 介面自動化主回歸在兩個尺寸類別各一輪全綠
- 效能測試 5 個量測 (4 個既有加 1 個新增) 全部通過，既有 4 個的門檻不得放寬；5 個數字與開工前基準的前後對照寫進本 change
- 跨平台 data model 與 schema 檔在本次差異中為空 (證明未動 schema)

**範圍界線**

- 在範圍內：訂單 feature 三個子域的分支主體外移、State 查詢擴充外移、訂單編輯與開團編輯的草稿型別、訂單建構路徑收斂、篩選求值與開團字典、清單單次求值、開團摘要批次投影、對應測試與文件
- 不在範圍內：任何使用者可見行為、action 語意、三個 `Reduce` 的切分方式、財務計算、跨平台 data model、訂單編號取值範圍、主檔多來源、build target 拆分

## Risks / Trade-offs

- [分支主體搬出時漏搬、搬錯歸屬，或誤改分支的先後語意] → 一次搬一個子域、各自提交；每個子域搬完立刻跑既有訂單 feature 測試；合入前以三段歸屬清單對照 54 個 action case，每個 case 在每一段各出現且僅出現一次
- [`batchStatusChanged` 的三種結果 (目標為已合併、無訂單實際變更、有變更) 在改寫時被壓成同一條路徑] → 目標為已合併時整條不做任何狀態變更，另兩種都要退出多選並清空選取；三種情形各補一條斷言，先寫測試再改實作
- [草稿改名波及 452 處引用，一次改完難以審查] → 依 D6 分兩階段，第一階段留轉發屬性讓外部零改動即可編過並先刪指紋型別，第二階段刪轉發屬性靠編譯錯誤逐一修正；全程不使用全域取代，兩階段各自提交
- [合併兩段建構時誤改正規化語意，等於靜默改動財務數字] → 一律**先寫草稿建構測試**：期望值以重構前的程式碼逐行推導後硬編進測試，再動 production code。編輯路徑回退到既有值、新單路徑的預設值、以及合併來源編號的來源差異必須逐欄位保留，任何「順手統一」都視為改行為、須先確認
- [照片誤入草稿型別，讓開啟既有訂單就被判定為有未儲存變更] → `draftPhotos` 與 `hasEditedPhotos` 明確留在 `State`；補一條「開啟既有訂單、照片載入完成、未做任何編輯」的斷言，斷言此時不 dirty
- [開團字典遇同名開團時崩潰或改變命中結果] → 必須使用允許重複鍵並保留先出現者的建構形式，不可用要求鍵唯一的形式 (後者遇重複鍵直接崩潰)；保留先出現者與現行線性搜尋語意一致，並各補一條同名開團測試案例
- [開團編輯收斂指紋時弄壞 dirty 判斷，使用者的未儲存編輯被靜默丟棄且無任何畫面訊號] → 先確認既有 6 條 dirty 相關測項以相同斷言值通過，再補一條逐欄位掃過全部 7 個欄位的測試；四個目前無個別覆蓋的欄位 (`draftOpenDate`／`draftCloseDate`／`draftStatus`／`draftNotes`) 是這條測試存在的主要理由
- [草稿型別未標可觀察狀態，觀察粒度退化導致整張表單重繪] → 明確標註為可觀察狀態 (不是只標可相等比較)，並在實機以訂單編輯表單連續輸入數字欄位確認無新增卡頓；同時比對介面測試中訂單編輯相關案例的執行時間有無明顯劣化
- [清單改以參數傳遞篩選結果時，誤把選取項目的語意改掉] → 現行語意是「選取項目不在篩選結果內時回第一筆」，新的取值方法必須完整保留這條回退；以既有選取相關測項加一條「篩選後選取項目消失時回退第一筆」的斷言鎖住
- [輔助方法為了少傳參數而自行取用系統時間、行事曆或識別碼] → 輔助型別一律不宣告 `@Dependency`、不呼叫系統 API；審查時以「輔助檔內零 `Date()`／`UUID()`／`Calendar.current`／`@Dependency`」為機械檢查點

## Migration Plan

不涉及持久化資料。本案全程不動 schema：不新增版本、不改任何持久化模型、migration floor 維持現狀。

這也是刻意的取捨：原始建議把搜尋文字改成跨平台型別的持久化欄位，而該型別由跨平台產生器產出，加欄位必須改 schema、重新產生、新增 schema 版本與遷移階段，屬於另一個量級的工作與風險；本案改以短路求值與字典化取得同等效益。

草稿型別是純記憶體的表單型別，不進持久層、不進編碼形狀，對既有使用者資料零影響。

驗收時以「跨平台 data model 目錄與 schema 檔在本次差異中為空」作為機器可驗的守門。

前置順序：主檔單一來源與雙版面收斂兩項皆已落地 (State 以 `@Shared(.lookupCatalog)` 取得四種主檔、雙版面共用 `OrdersToolbarContent`／`OrderSelectableRow`)，本案不再有前置阻擋。

部署即一般發版，回退即還原程式碼，無殘留狀態。

## Baseline Capture (task 1.1 / 1.2)

動工前於本機 (iPhone 17 `CA41FB26-16C6-46D0-8117-A7D4C084357D`) 量測並記錄：

- 主 scheme 全部單元測試：658 passed / 1 known-red (`orderEditViewMergeContextBaseline`)，與驗收基準一致
- `OrdersFeaturePerformanceTests` 4 個既有量測 (暫時停用 `BuyLedger.xctestplan` 的 `skippedTests` 排除以取得數字，量測後已還原)：
  - `testFilteredOrdersBaselineWithThousandOrders`：0.0229 秒
  - `testFilteredOrdersWithSearchHittingHalf`：0.0983 秒
  - `testFilteredOrdersWithAllFiltersActive`：0.1237 秒
  - `testDashboardStatsRevenueAttributionBaselineWithThousandOrders`：0.0908 秒
- 六個基準數字 (`OrdersFeature.swift` 行數、三段 switch case 標籤數、action case 數、`OrdersFeatureTests.swift` 測項數、測試 target 關閉窮舉檢查處數、`OrderEditFeature.swift` 行數) 已於本文件 Context 段落記錄，數字經本次動工前重新核對與現況一致 (1,834／65／54／69／9／1,160)

## Performance Measurement Comparison (task 7.2)

新增第五個量測 `testFilteredOrdersWithCampaignStatusFilterAndDozensOfCampaigns` (1,000 筆訂單搭配 40 個開團並啟用開團狀態篩選)，呈現 D4 開團字典化取代線性搜尋的收益。5 個量測的動工前後對照 (皆為 20 次迭代的總耗時，門檻 3 秒未變動)：

| 量測 | 動工前 | 動工後 | 備註 |
|---|---|---|---|
| `testFilteredOrdersBaselineWithThousandOrders` | 0.0229 秒 | 0.0225 秒 | 持平 |
| `testFilteredOrdersWithSearchHittingHalf` | 0.0983 秒 | 0.0990 秒 | 持平 (字串比對成本不變，仍排最後) |
| `testFilteredOrdersWithAllFiltersActive` | 0.1237 秒 | 0.0099 秒 | 短路求值讓狀態篩選提早排除大部分訂單，約 12 倍改善 |
| `testDashboardStatsRevenueAttributionBaselineWithThousandOrders` | 0.0908 秒 | 0.0889 秒 | 持平 (未受本案改動的路徑) |
| `testFilteredOrdersWithCampaignStatusFilterAndDozensOfCampaigns` (新增) | 無 (新測項) | 0.0283 秒 | 40 個開團下字典查找仍維持低成本，呈現字典化的量級優勢 |

5 個量測皆遠低於 3 秒門檻，既有 4 個量測的門檻未放寬。

## Open Questions

無。
