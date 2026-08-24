## Context

六個目標點分布在付款方式編輯、訂單合併、到貨統計、訂單篩選、付款方式編輯表單與 localization 靜態測試。它們目前都能產生正確結果，但把規則直接寫在呼叫點：付款旗標重複查詢三個 dictionary、合併候選資格連續比較五個欄位、表單 dirty state 逐欄比較，以及多個狀態或 pattern 直接用 AND／OR 串接。

這是 implementation-only refactor。既有 reducer action、View 呈現、持久化資料、錯誤處理與測試對外行為都必須維持不變。

## Goals / Non-Goals

**Goals:**

- 讓六個條件在呼叫點以具名規則或具名狀態呈現。
- 讓每個重構後的規則可以透過單元測試驗證正向、反向與邊界案例。
- 保留既有輸入順序、預設值、狀態集合與 localization 掃描涵蓋範圍。
- 讓後續新增付款旗標、合併資格或篩選欄位時有單一修改入口。

**Non-Goals:**

- 不變更任何產品規則、SwiftData schema、公開 repository API、TCA action 介面或 UI 文案。
- 不把所有只有一至兩個運算子的簡單條件全面抽象化。
- 不將 Shared UI 元件依賴 Features 層的型別；表單 snapshot 只在表單內使用。
- 不進行全專案 formatter 或 trailing whitespace 清理。

## Decisions

### Decision: 以 Equatable 旗標快照取代付款旗標長串比較

在 LookupManagementFeature 內建立只包含 isCardless、isBankTransfer、isCashOnDelivery 的 Equatable 旗標快照。由既有 dictionary 讀取原始快照，將 action payload 建立成新快照，再以值相等性判斷 flagsChanged。缺少 dictionary 值仍以 false 作為原始值。

PaymentMethodEditorSheet 使用自己的輕量 Equatable editor snapshot，包含名稱與三個旗標，直接比較 draft snapshot 與 initial snapshot。兩個 snapshot 不放入共用 generated model，避免 Shared UI 元件反向依賴 Feature，也不改變資料模型。

替代方案是保留逐欄比較，或直接比較三個 dictionary；前者延續可讀性問題，後者會把儲存結構洩漏到 UI／流程判斷，因此不採用。

### Decision: 將合併候選資格集中為具名 predicate

OrderMergeFeature 保留單一候選資格 helper，明確處理四組規則：不得是 primary、自身狀態不得為 merged 或 cancelled、幣別必須相同、客戶名稱必須相同。外層只負責依輸入順序過濾，helper 不改變排序、不建立副作用。

替代方案是只把條件排版成多行，雖能改善水平長度，但規則仍無法被單獨命名與測試，因此不採用。

### Decision: 以 OrderStatus 具名集合表達到貨狀態

在 OrderStatus 增加 deliveryStatuses，內容固定為 arrived、delivered、pickedUp。CampaignSummary 以集合 membership 計算 arrivedCount，並保留 activeCount 排除 cancelled 與 merged 的既有規則。

替代方案是把三個狀態留在 CampaignSummary 內，會使同一領域概念無法集中維護，因此不採用。

### Decision: 讓 PendingFilterSelection 提供啟用狀態

在 PendingFilterSelection 增加 isActive computed property，定義 datePeriod 不是 all、category 有值或 paymentMethod 有值時為 true。OrdersCompactView 只讀取該具名 property，不重複理解三欄篩選的空值規則。

替代方案是讓 View 保留 inline OR，或以反射／字串集合判斷，前者無法改善規則分散，後者會降低型別安全，因此不採用。

### Decision: 將 localization 禁止 pattern 集合化

LocalizationCatalogTests 將三個禁止的 navigationTitle pattern 集中成常數陣列，使用 contains(where:) 判斷 source 是否命中任一 pattern。保留目前三種 pattern 與錯誤訊息，不改掃描範圍。

替代方案是增加更多 AND 判斷或使用正規表示式；正規表示式會降低失敗原因可讀性，因此不採用。

### Decision: 先補規則測試，再以解析與測試驗證重構

每個具名規則先有涵蓋邊界的測試：旗標缺省與單欄變更、合併資格各排除條件、dirty snapshot 的每個欄位、到貨狀態集合、篩選預設與非預設值、三種 localization pattern。完成後執行受影響 Unit Tests、Swift parse 與 diff 檢查；不以 UI test 取代可直接驗證的 domain／feature unit test。

## Implementation Contract

### Observable behavior

- 付款旗標原始值缺少 dictionary entry 時視為 false；flagsChanged 只有在三個旗標任一不同時為 true。
- 合併候選結果保留原始 orders 順序，且只有同時符合既有五個資格條件的候選會被保留。
- PaymentMethodEditorSheet 的 isDirty 只有在名稱或三個旗標任一不同時為 true。
- CampaignSummary 的 arrivedCount 只計入 arrived、delivered、pickedUp；activeCount 與 deliveryRatio 的既有零分母行為不變。
- 預設 PendingFilterSelection 的 isActive 為 false；日期、類別或付款方式任一非預設時為 true。
- localization scanner 對三個既有禁止 pattern 的命中結果與目前相同。

### Interface and data shape

- 新增的快照與 helper 優先維持 private 或 feature-local scope，不改變 repository、dependency、TCA action、SwiftData model 或序列化格式。
- OrderStatus.deliveryStatuses 是唯讀的 domain-level Set<OrderStatus>。
- PendingFilterSelection.isActive 與合併資格 helper 都是同步、無副作用的純查詢。

### Failure modes

- 本重構不新增錯誤型別、錯誤提示、fallback 或 persistence 操作。
- 若測試 fixtures 缺欄位或沒有涵蓋邊界，測試必須失敗，而不是以寬鬆預設掩蓋規則；runtime 對既有缺少付款旗標的 dictionary entry 仍使用 false。

### Acceptance criteria

- 受影響的 Unit Tests 通過，並新增或調整測試以覆蓋上述每一項 observable behavior。
- Swift source parse 通過，且 diff check 不產生本次新增的 whitespace error。
- 對六個目標條件的 review 可從呼叫點讀出具名規則，不再直接看到原本的長串付款旗標、合併資格、dirty、到貨狀態、篩選啟用或禁止 pattern 條件。
- Git diff 顯示沒有 SwiftData schema、公開 API、TCA action、UI 文案或非本 change 範圍的變更。

### Scope boundaries

- In scope: 六個目標條件、其必要的 local/domain helper、直接對應的 Unit Tests 與 localization scanner 測試。
- Out of scope: 先前列為次要的 duplicated merged-status filter、OrderEditFeature.isMergeContext、其他只有一至兩個運算子的條件，以及任何與可讀性無關的行為修正。

## Risks / Trade-offs

- [Risk] 旗標快照可能意外把名稱納入比較。→ [Mitigation] 快照型別只包含三個旗標；測試明確驗證只改名稱不會將 flagsChanged 設為 true。
- [Risk] 合併資格 helper 可能漏掉某一個排除條件。→ [Mitigation] 每個條件各有一個失敗案例，並保留輸入順序測試。
- [Risk] 新增 domain status set 可能改變 arrivedCount。→ [Mitigation] 用既有三個狀態建立具體 fixture，驗證其他狀態不計入。
- [Risk] View 端篩選啟用狀態與 sheet 的 pending state 混用。→ [Mitigation] 只在 committed selection 的呼叫點使用 isActive，並保留 pending/committed 等值比較測試。
- [Risk] localization pattern 集合化時漏掉 pattern。→ [Mitigation] 三個 pattern 都以明確測試案例保留，並測試非命中 source。

## Migration Plan

不涉及資料或 API migration。實作時先建立純規則 helper 與測試，再逐一替換六個呼叫點；若任一測試顯示行為差異，回退該 helper 的替換，不需回復資料或 schema。

## Open Questions

無。六個條件的既有語意與不變性已由目前程式碼及測試範圍確定。
