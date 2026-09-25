## Why

目前六處條件判斷把多個 &&／||、重複查詢與否定運算直接堆在呼叫點，降低 review、測試與後續修改時的可讀性；其中付款旗標比較與合併候選資格還可能因欄位增減而漏改。現在集中整理這些條件，可在不改變既有行為的前提下建立可命名、可單獨測試的規則入口。

## What Changes

- 將付款方式旗標變更判斷改為比較具名的旗標快照或等價值物件，移除重複 dictionary lookup 與長串 ||。
- 將訂單合併候選資格抽成可命名的 predicate／helper，保留排除自身、排除 merged/cancelled、幣別相同與客戶相同等既有規則。
- 將付款方式編輯畫面的 dirty 判斷改為比較草稿與初始快照，避免逐欄串接多個 ||。
- 將到貨狀態集合集中到 OrderStatus 的具名集合或 computed property，取代三個狀態的 ||。
- 將整合篩選的啟用判斷移至 PendingFilterSelection 或 OrdersFeature.State 的具名 computed property。
- 將 localization 測試的禁止 pattern 集合化，使用集合查詢取代多個 &&。
- 為重構後的規則補上對應單元測試，驗證邊界條件與結果不變。

## Non-Goals

- 不改變合併、付款旗標、到貨統計或篩選的產品行為。
- 不進行全專案格式化，也不順便重構只有一至兩個簡單運算子的條件。
- 不修改既有公開 API、SwiftData schema、持久化格式或 UI 文案。
- 不新增與本次條件可讀性無關的功能。

## Capabilities

### New Capabilities

- condition-readability: Multi-clause business and test predicates remain behaviorally equivalent while using named, reviewable rule boundaries.

### Modified Capabilities

(none; no existing product requirement changes)

## Impact

- Affected specs: condition-readability (maintenance contract only; no user-facing behavior change).
- Affected code:
  - Modified:
    - apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift
    - apps/ios/BuyLedger/Features/Orders/OrderMergeFeature.swift
    - apps/ios/BuyLedger/Core/Domain/OrderStatus.swift
    - apps/ios/BuyLedger/Shared/DesignSystem/Components/Forms/PaymentMethodEditorSheet.swift
    - apps/ios/BuyLedger/Features/Campaigns/CampaignSummary.swift
    - apps/ios/BuyLedger/Features/Orders/OrdersFeature.swift
    - apps/ios/BuyLedger/Features/Orders/OrdersCompactView.swift
    - apps/ios/BuyLedgerTests/LocalizationCatalogTests.swift
  - Tests to extend or add:
    - apps/ios/BuyLedgerTests/LookupManagementFeatureTests.swift
    - apps/ios/BuyLedgerTests/OrderMergeFeatureTests.swift
    - apps/ios/BuyLedgerTests/CampaignSummaryTests.swift
    - apps/ios/BuyLedgerTests/OrdersFilterOperationsTests.swift
    - apps/ios/BuyLedgerTests/LocalizationCatalogTests.swift
    - apps/ios/BuyLedgerUITests/Tests/Orders/OrderEditDirtyTests.swift
  - New: none
  - Removed: none
