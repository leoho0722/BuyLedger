## Summary

把 1,834 行的訂單 feature 依三個子域把分支主體抽成獨立檔案的輔助型別，主 reducer 的 switch 維持窮舉、零預設分支；同時把訂單編輯與開團編輯的草稿欄位各自收成單一草稿型別以消滅兩支指紋型別，並修掉清單畫面每次更新重複求值篩選的浪費。全程對外行為與 action 語意完全不變。

## Motivation

**訂單 feature 已超過單檔可維護的規模。** `apps/ios/BuyLedger/Features/Orders/OrdersFeature.swift` 1,834 行，狀態 29 個儲存屬性搭 16 個計算屬性與 6 個查詢方法，action 54 個 case，reducer 的三個 switch 合計 65 條 case 標籤，相依注入 11 個。它與訂單編輯 feature (`OrderEditFeature.swift`，1,160 行) 是變動最頻繁的區域，越晚拆，每次改動的審查面積與合併衝突風險越大。

**這個檔已經因為體積撞上編譯器上限。** reducer 本體不是一個 switch，而是被切成三個循序執行的 `Reduce`，切分理由寫在原始碼註解裡：單一 switch 涵蓋全部 action case 會讓型別檢查逾時 (`unable to type-check this expression in reasonable time`)。三段各自窮舉、各自以一條列舉式的歸屬清單把「由別段處理」的 case 交出去，因此目前 65 條 case 標籤中有 3 條是歸屬清單、62 條是實際處理分支。分支主體越長，離下一次逾時越近。

**草稿欄位清單被抄了四遍。** 訂單編輯有 23 個 `draft` 開頭的儲存欄位，其中 22 個納入未儲存變更判斷 (`draftPhotos` 因非同步載入另以 `hasEditedPhotos` 追蹤)。這 22 個欄位的清單目前寫在四個地方：草稿欄位宣告、`DraftFingerprint` 型別的欄位、`draftFingerprint` 計算屬性的建構、以及 `init` 內 `initialDraftFingerprint` 的建構。「加欄位忘了加進指紋」因此是一個結構性存在的缺陷，而它的症狀是未儲存變更防護失效。開團編輯 (`CampaignEditFeature.swift`) 有完全同型的問題，7 個草稿欄位的清單同樣寫在四處，本案範圍一併涵蓋它：兩處都收斂後，未儲存變更防護才是全面的結構性保證，而不是只在被點名的那一處成立。

**同一個建構邏輯寫了兩遍。** `resolveWriteResult(_:existingOrders:)` 共 124 行，內含兩段各 28 行、僅差少數欄位的 `LedgerOrder(...)` 建構 (編輯既有訂單一段、新建訂單一段)，正規化規則雖已提到分支之前只寫一次，兩段的欄位取值仍是逐欄位手抄。同一支檔案尾端的 `withStatus(_:)` 與 `withPaymentReceiptStatus(_:)` 另有兩段各 28 行、只差一個欄位的 `LedgerOrder(...)` 重建。

**清單畫面每次更新重複求值篩選。** iPad (regular) 版面在單次 body 更新內求值 `filteredOrders(referenceDate:calendar:)` 四次 (`OrdersView.swift:75` 的 `filteredIDs`、`:159` 的 `listPane`、`:373` 經 `selectedOrder(referenceDate:calendar:)`、以及 `OrdersToolbarContent.swift:79` 的停用判斷)；iPhone (compact) 版面三次 (`OrdersCompactView.swift:38`、`:233` 經 `dateSections(...)`、以及同一處工具列)。而篩選本身把七個判斷條件全部先算成區域常數再合併，狀態篩選早已排除的訂單仍會做日期判斷與開團的線性搜尋。開團摘要在總覽、開團列表與分析統計三處各有一次以開團數乘訂單數為量級的聚合，其中開團列表在每一列各建一次。

**「選取第一筆篩選結果」的寫法逐字重複 12 處。** `OrdersFeature.swift` 9 處、`RootFeature.swift` 3 處，都是同一行 `selectedOrderID = ...filteredOrders(...).first?.id`。

### 已作廢的動機：子域無法在窮舉模式下受測

本提案初版列有「訂單 feature 測試有 30 處關閉窮舉檢查」這條動機，主張唯有拆出子 reducer 才能讓子域在窮舉模式下受測。**這條動機已不成立，本次改寫予以刪除。**

實測現況：`apps/ios/BuyLedgerTests/OrdersFeatureTests.swift` 只有 2 處關閉窮舉檢查 (`:29`、`:1026`)，測試 target 全域為 9 處。這個收斂已在本案動工前完成，並立下機器守門：`TestSuiteIntegrityTests.exhaustivityRelaxationsDoNotExceedTheRecordedBound` (`apps/ios/BuyLedgerTests/TestSuiteIntegrityTests.swift`) 掃描測試目錄並斷言關閉處不超過 9，新增一處而未同時移除他處即轉紅。訂單 feature 的測試早已在窮舉模式下跑。

更進一步：僅存的 2 處關閉，原始碼註解都寫明理由是「並行或延遲效果的完成時序由 runtime 決定」(`.task` 同時啟動五條主檔載入效果；合併流程的 delegate 之後接一次 `continuousClock.sleep`)，與子域是否混在同一個 reducer 無關。**任何形式的子域拆分都不會讓這 2 處消失**，把它們當成拆分的理由是誤判。

## Proposed Solution

**一、把三個子域的分支主體抽成獨立檔案的輔助型別。** 篩選與選取、批次操作、合併流程各一支無 case 的列舉型別，收該子域全部分支的主體，以 `inout OrdersFeature.State` 與明確參數溝通。主 reducer 的對應分支縮成「呼叫輔助方法」加 `return .none`，或在需要副作用時以輔助方法回傳的值餵給既有的 effect 工廠。三個 `Reduce` 的切分與各自的窮舉 switch 原封不動保留，**不新增任何預設分支**。

**二、兩個編輯表單各導入單一草稿型別。** 訂單編輯納入未儲存變更判斷的 22 個欄位收進一個可觀察的草稿型別，`DraftFingerprint` 整個刪除，是否有未儲存變更改為「目前草稿不等於初始草稿」再或上照片編輯旗標；開團編輯的 7 個欄位比照收斂，其同名指紋型別一併刪除。兩處都收斂後，「加欄位忘了加進指紋」才從結構上消失。

**三、訂單建構收成單一路徑。** 草稿型別自帶建構訂單的方法：正規化規則只寫一次，接著逐欄位以「是否有既有訂單」決定取值，最後只留一個 `LedgerOrder(...)` 呼叫。`withStatus`／`withPaymentReceiptStatus` 兩段重建改為共用同一個變更輔助擴充，並移出 `OrdersFeature.swift`。

**四、效能三處。** 篩選改短路求值並把開團狀態先建成字典；清單兩個版面各自單次求值後傳遞；開團摘要新增批次投影 API 並套用到三個逐團建構的呼叫點。

## Non-Goals

- **不改任何使用者可見行為。** 這是驗收的唯一軸線。
- **不動對外的 action 語意。** 54 個 case 的名稱與載荷型別零變更，既有 69 個訂單 feature 測項的斷言值一字不改仍須全綠。
- **不拆成子 reducer。** 兩條理由：其一，唯一需要子 reducer 才能達成的目標 (讓子域在窮舉模式下受測) 已由既有的窮舉關閉上限守門達成，動機不存在；其二，共用同一份狀態與 action 的並列子 reducer 必須以預設分支涵蓋不屬於自己的 action，而 `TestSuiteIntegrityTests.defaultNoneBranchesRemainAbsent` (`apps/ios/BuyLedgerTests/TestSuiteIntegrityTests.swift`) 斷言 `apps/ios/BuyLedger` 內 `default: return .none` 恆為 0 處，照該作法實作會直接讓守門轉紅。
- **不合併現有的三個 `Reduce`。** 切分理由是型別檢查逾時，與本次改動無關，合併會把已解決的問題重新引入。
- **不改任何財務計算。** 金額下限、費率夾擠、無卡金額歸零、對帳狀態清空等規則一律逐欄位照抄，任何「順手統一」都視為改行為。
- **不改跨平台 data model。** 因此不把搜尋文字改成持久化欄位。
- **不順手修訂單編號取值範圍與主檔多來源。** 兩者各屬其他 change。
- **不拆 build target。**

## Alternatives Considered

- **拆成三支共用同一份狀態與 action 的並列子 reducer。** 已否決，理由見 Non-Goals：動機已消失，且與 `default: return .none` 恆為 0 的既有守門直接衝突。附帶一提，抽輔助型別在「子域可獨立受測」這一點上其實更強：純狀態變更的輔助方法可直接以「傳入狀態、呼叫、斷言變更後的狀態」測試，連 `TestStore` 都不需要，也就無從談窮舉開關。
- **放寬既有守門以容許子 reducer 的預設分支。** 已否決：`defaultNoneBranchesRemainAbsent` 是本專案自己立的機器守門，用途是讓「新增 action 卻沒人處理」不可能靜默通過。為了一個理由已經消失的機制去削弱它，是拿長期保護換一次性的實作方便。改寫 `default: return .none` 的字面形式以避開字串比對更糟：那是規避守門而非修改它，會讓守門的斷言與它宣稱保護的性質脫鉤。
- **用範圍組合 (Scope) 拆子 reducer。** 已否決：範圍組合需要子狀態與子 action，與「不動 action 語意」這條界線互斥。
- **合併流程搬進合併 feature。** 已否決：該 feature 的狀態是呈現式的，delegate 送出後 sheet 隨即收合，之後的確認就緒與需要回寫訂單快照的失敗處理在子 feature 裡沒有狀態可住。它的 delegate 邊界本來就乾淨，該收斂的是父層那 5 條分支的主體。
- **把搜尋文字快取成狀態內的索引，或改成跨平台型別的持久化欄位。** 已否決：後者要動跨平台 schema 與一次 schema 版本升級，成本與風險遠超收益；前者要在七條寫入路徑維持同步，而批次改狀態的逐列賦值會讓重建退化成平方複雜度。短路求值加開團字典已能在零過期風險下拿到絕大部分收益。
- **草稿型別再往下分成四個巢狀群組。** 已否決：一層就已完全達成目的 (指紋型別可整個刪除)，再分一層不會多刪任何重複，卻讓 `OrderEditView.swift` 的 46 處草稿欄位引用再深一層，且「呈現」這一組的邊界主觀。

## Impact

- Affected specs: `sheet-dismissal-safeguard` (未儲存變更防護改為結構性保證；對外行為與 action 語意不變)
- Affected code:
  - New:
    - apps/ios/BuyLedger/Features/Orders/OrdersFilterOperations.swift
    - apps/ios/BuyLedger/Features/Orders/OrdersBatchOperations.swift
    - apps/ios/BuyLedger/Features/Orders/OrdersMergeFlowOperations.swift
    - apps/ios/BuyLedger/Features/Orders/OrdersFeature+StateQuery.swift
    - apps/ios/BuyLedger/Features/Orders/OrderDraft.swift
    - apps/ios/BuyLedger/Features/Orders/LedgerOrder+OrderMutation.swift
    - apps/ios/BuyLedgerTests/OrderDraftTests.swift
    - apps/ios/BuyLedgerTests/OrdersFilterOperationsTests.swift
    - apps/ios/BuyLedgerTests/OrdersBatchOperationsTests.swift
  - Modified:
    - apps/ios/BuyLedger/Features/Orders/OrdersFeature.swift
    - apps/ios/BuyLedger/Features/Orders/OrderEditFeature.swift
    - apps/ios/BuyLedger/Features/Orders/OrderEditView.swift
    - apps/ios/BuyLedger/Features/Orders/OrdersView.swift
    - apps/ios/BuyLedger/Features/Orders/OrdersCompactView.swift
    - apps/ios/BuyLedger/Features/Orders/Components/OrdersToolbarContent.swift
    - apps/ios/BuyLedger/Features/Orders/OrderMergeFeature.swift
    - apps/ios/BuyLedger/Features/App/RootFeature.swift
    - apps/ios/BuyLedger/Features/Campaigns/CampaignEditFeature.swift
    - apps/ios/BuyLedger/Features/Campaigns/CampaignEditView.swift
    - apps/ios/BuyLedger/Features/Campaigns/CampaignFeature.swift
    - apps/ios/BuyLedger/Features/Campaigns/CampaignSummary.swift
    - apps/ios/BuyLedger/Features/Campaigns/CampaignListView.swift
    - apps/ios/BuyLedger/Features/Dashboard/DashboardView.swift
    - apps/ios/BuyLedger/Features/Insights/InsightsStats.swift
    - apps/ios/BuyLedgerTests/OrdersFeatureTests.swift
    - apps/ios/BuyLedgerTests/RootFeatureTests.swift
    - apps/ios/BuyLedgerTests/OrderEditFeatureTests.swift
    - apps/ios/BuyLedgerTests/OrderEditFocusTests.swift
    - apps/ios/BuyLedgerTests/CampaignEditFeatureTests.swift
    - apps/ios/BuyLedgerTests/CampaignFeatureTests.swift
    - apps/ios/BuyLedgerTests/CampaignSummaryTests.swift
    - apps/ios/BuyLedgerTests/OrdersFeaturePerformanceTests.swift
    - apps/ios/CLAUDE.md
    - apps/ios/README.md
