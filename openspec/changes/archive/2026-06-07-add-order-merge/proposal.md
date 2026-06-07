## Why

當同一位客人有兩筆訂單的商品在相近時間到貨時，賣家希望整合為一筆訂單出貨，避免客人重複支付運費。目前 App 沒有任何合併機制，賣家只能手動建新單、逐欄抄寫加總、再刪除舊單，費時且容易抄錯金額；舊單刪除後也失去歷史紀錄。

此外，現有資料模型限制「一筆訂單只能屬於一個商品類別與一個開團」，合併後的訂單天生橫跨兩筆來源的類別與開團，因此資料模型必須先升級為多選，合併功能才能成立。

## What Changes

- **商品狀態新增「已合併」**：`OrderStatus` 新增 `merged` case。被合併的兩筆舊訂單狀態改為「已合併」並保留於資料庫 (不刪除)；「已合併」不屬於已實現統計狀態，Insights 與 Dashboard 的收益計算自動排除，避免與合併後新訂單重複計算。
- **商品類別資料模型改為陣列** (**BREAKING**)：domain 欄位由單一字串改為字串陣列 (至少一個，必填維持不變)。多選編輯僅在合併情境開放 (合併確認表單與編輯合併產生的訂單)；一般訂單編輯維持現行單選體驗，儲存為單元素陣列。篩選、列表 tag 顯示、Insights 類別收益彙總、cascade rename 一併調整。
- **開團項目資料模型改為陣列** (**BREAKING**)：domain 欄位由單一開團名稱改為開團名稱陣列 (空陣列 = 未歸團)。多選編輯同樣僅在合併情境開放，一般訂單編輯維持單選。開團篩選、開團統計與 cascade rename 一併調整。
- **SwiftData schema 升版 V10 → V11** (**BREAKING**)：類別與開團兩欄位型別改變 (String → [String])，並新增合併來源訂單 ID 欄位 (預設空陣列)；依專案 migration 政策走 `.custom` dump-and-restore stage，V10 凍結為 shadow 版本。
- **多類別／多開團的統計歸屬 (採合併前收益)**：類別收益與開團統計改以「葉端訂單」(非由合併產生的訂單，狀態屬已實現或已合併) 為計算來源——合併產生的新訂單不參與類別/開團分組，其收益由合併前的舊訂單以各自原始的類別、開團、金額與日期入帳；整體總收益維持現行 realized 規則 (採合併後新訂單)。因多選僅在合併情境開放，葉端訂單必為單類別/單開團，分類歸屬即為精確值。為支援此語意與鏈式合併，合併產生的新訂單持久化記錄來源訂單 ID。
- **合併相關訂單的金額與明細欄位維持可編輯** (2026-06-07 實機驗收後的需求變更，取消原「鎖定」決策)：合併確認表單預填合併計算結果後，收款金額、成本、手續費、商品明細四個 section 與一般訂單一樣可編輯；合併產生的訂單與被合併的舊訂單日後編輯亦不鎖定。已知後果：合併後調整金額時，類別/開團統計 (採合併前舊單數字) 與新單總額可能產生落差，屬已知且接受的語意。
- **詳情頁操作列收斂為「更新狀態 + 更多」兩個控制項** (2026-06-07 視覺回饋的需求變更)：合併入口加入後，三平台訂單詳情操作列 (iPhone push 頁系統 toolbar、iPad regular 自繪標題列、macOS inspector 自繪標題列) 並排四個操作 (更新狀態、合併訂單、編輯、刪除) 視覺擁擠。功能性質相近的「合併訂單、編輯、刪除」收進單一「更多」Menu (ellipsis 圖示)，「更新狀態」維持獨立；Menu 內依序為合併訂單 (沿用狀態非已合併/已取消才顯示的條件)、編輯、分隔線、刪除 (destructive)。三個動作觸發的 `OrdersFeature` action 不變，僅呈現容器改變。
- **訂單合併流程**：
  - 入口 (雙入口)：(1) 訂單列 context menu 新增「合併訂單」(與現有「刪除」同層)；(2) 訂單詳情頁 toolbar 新增「合併訂單」動作。兩個入口共用同一個候選選擇 sheet，發起合併的那筆訂單即「主訂單」。
  - 候選選擇：sheet 列出可合併的其他訂單 (限同幣別、排除「已合併」與「已取消」)，顯示客戶名稱、訂購日期、商品明細與客戶實付，支援搜尋；僅列與主訂單同客戶名稱的訂單 (不支援跨客戶合併)。商品明細以 `itemSummary` 呈現 (每項商品一行、同訂單列表 row 樣式)，取代原本不易閱讀的訂單編號 (2026-06-07 視覺回饋的需求變更)。候選列進一步直接重用 `OrderRowView` 的版面 (2026-06-07 同日第二次調整)：左欄 (頭像、客戶名稱、商品明細、類別 tag) 與訂單頁完全一致，右欄以參數化變體顯示「客戶實付」(取代訂單頁的狀態膠囊與損益)，訂單頁與 Dashboard 的既有外觀不變。候選清單並比照訂單頁以「訂購日」分組 (2026-06-07 同日第三次調整)：日期作為 section 標題 (今天/昨天/格式化日期，同訂單頁標題字串)、段落新到舊排序，列內不再重複顯示日期。
  - 照片超量：兩筆照片合計超過上限 (5 張) 時，先跳出照片選擇頁面挑選保留的照片。
  - 預填確認：開啟「新訂單」編輯表單，預填合併後資料供使用者確認與調整 (含金額與明細，全部欄位可編輯)；按儲存才真正建立新訂單，並把兩筆舊訂單狀態改為「已合併」；取消則不留任何變更。
  - 合併規則：類別與開團取聯集；訂購日期為合併當下；客戶實付與成本各 row 個別加總；手續費三項百分比以客戶實付為權重做加權平均 (金額守恆，兩筆實付皆為 0 時沿用主訂單值)；商品明細串接；備註以一行 dash line 分隔串接；狀態、客戶名稱、訂單來源等單選欄位預填主訂單值；付款方式兩筆不同且其中恰有一筆屬無卡類時以無卡為主 (保住折抵/補款加總不被非無卡的歸零規則清掉)，否則取主訂單值，對帳狀態與是否貨到付款隨付款方式來源那筆訂單。

## Capabilities

### New Capabilities

- `order-merge`: 兩筆訂單合併為一筆新訂單的完整流程——入口、候選選擇、照片超量挑選、預填確認表單、儲存後舊單轉「已合併」且新訂單記錄合併來源。
- `order-category-assignment`: 訂單可同時歸屬多個商品類別——資料模型、合併情境的多選編輯 (一般編輯維持單選)、Insights 類別收益的葉端訂單歸屬語意 (採合併前收益)、類別 cascade rename 於陣列內生效。

### Modified Capabilities

- `order-campaign-assignment`: 「一筆訂單只能歸屬單一開團」改為可歸屬多個開團；合併情境開放多選編輯 (一般編輯維持單選)；開團 cascade rename 於陣列內生效。
- `order-category-filter`: 篩選比對由「等於」改為「訂單類別陣列包含所選類別」。
- `order-campaign-filter`: 指定開團與開團狀態篩選比對改為「訂單開團陣列包含所選開團」。
- `campaign-analytics-surfaces`: 每團統計改以葉端訂單為計算來源 (採合併前收益)；手動多開團的葉端訂單全額計入其每一團。
- `order-row-summary`: 訂單列第三行類別 tag 改為呈現多個類別。
- `option-picker`: 元件新增多選模式 (保留現有單選行為不變)。
- `schema-migration-plan`: migration 鏈延伸 V10 → V11，新增首個 `.custom` stage (欄位型別改變 + 新增合併來源欄位)，V10 凍結為 shadow。

## Impact

- Affected specs: 見上方 Capabilities (新增 2、修改 7)。
- Affected code:
  - New:
    - BuyLedger/BuyLedger/Core/Domain/OrderMerge.swift (純函式合併邏輯，供單元測試)
    - BuyLedger/BuyLedger/Features/Orders/OrderMergeFeature.swift (合併流程兩步驟 reducer)
    - BuyLedger/BuyLedger/Features/Orders/Components/OrderMergeCandidateSheet.swift (候選訂單選擇 sheet)
    - BuyLedger/BuyLedger/Features/Orders/Components/MergePhotoPickerSheet.swift (照片超量挑選頁)
    - BuyLedger/BuyLedgerTests/OrderMergeTests.swift (合併規則單元測試)
  - Modified:
    - BuyLedger/BuyLedger/Core/Domain/OrderStatus.swift (+merged case)
    - BuyLedger/BuyLedger/Core/Domain/LedgerOrder.swift、BuyLedger/BuyLedger/Core/Domain/LedgerOrder+Samples.swift (欄位改陣列)
    - BuyLedger/BuyLedger/Core/Persistence/BuyLedgerSchema.swift、BuyLedger/BuyLedger/Core/Persistence/OrderRecord.swift (V11 + custom migration)
    - BuyLedger/BuyLedger/Core/Persistence/OrderPersistence.swift、BuyLedger/BuyLedger/Core/Dependencies/OrderRepository.swift (陣列 cascade rename、合併寫入)
    - BuyLedger/BuyLedger/Features/Orders/OrdersFeature.swift、BuyLedger/BuyLedger/Features/Orders/OrdersView.swift、BuyLedger/BuyLedger/Features/Orders/OrdersCompactView.swift、BuyLedger/BuyLedger/Features/Orders/OrdersMacView.swift (篩選、context menu 入口、sheet 掛載、詳情操作列收斂為「更新狀態 + 更多選單」)
    - BuyLedger/BuyLedger/Features/Orders/OrderEditFeature.swift、BuyLedger/BuyLedger/Features/Orders/OrderEditView.swift (多選草稿與 picker)
    - BuyLedger/BuyLedger/Features/Orders/Components/OptionPickerSheet.swift (多選模式)
    - BuyLedger/BuyLedger/Features/Orders/Components/OrderRowView.swift、BuyLedger/BuyLedger/Features/Orders/Components/OrderFilterSheet.swift、BuyLedger/BuyLedger/Features/Orders/Components/OrderDetailView.swift (多類別/多開團呈現；詳情頁合併入口；OrderRowView 另增右欄 trailing 變體供合併候選列重用)
    - BuyLedger/BuyLedger/Features/App/RootFeature.swift (cascade rename 與 rebuildOrder 改陣列)
    - BuyLedger/BuyLedger/Features/Insights/InsightsView.swift、BuyLedger/BuyLedger/Features/Dashboard/DashboardView.swift (多類別/多開團統計歸屬)
    - BuyLedger/BuyLedger/Features/Campaigns/CampaignSummary.swift、BuyLedger/BuyLedger/Features/Campaigns/CampaignFeature.swift、BuyLedger/BuyLedger/Features/Campaigns/CampaignDetailView.swift、BuyLedger/BuyLedger/Features/Campaigns/CampaignListView.swift (每團統計與訂單關聯)
    - BuyLedger/BuyLedgerTests/OrdersFeatureTests.swift、BuyLedger/BuyLedgerTests/OrderEditFeatureTests.swift、BuyLedger/BuyLedgerTests/OrderPersistenceTests.swift、BuyLedger/BuyLedgerTests/SchemaMigrationTests.swift、BuyLedger/BuyLedgerTests/CampaignSummaryTests.swift、BuyLedger/BuyLedgerTests/CampaignIntegrationTests.swift、BuyLedger/BuyLedgerTests/RootFeatureTests.swift、BuyLedger/BuyLedgerTests/OrderCalculationTests.swift、BuyLedger/BuyLedgerTests/OrdersFeaturePerformanceTests.swift、BuyLedger/BuyLedgerTests/SnapshotTests.swift (既有測試隨欄位型別更新；snapshot baseline 視 UI 變動重錄)
  - Removed: 無。
