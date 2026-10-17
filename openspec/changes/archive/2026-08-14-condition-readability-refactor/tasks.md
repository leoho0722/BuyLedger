## 1. 建立行為基準

- [x] 1.1 Confirm the Targeted multi-clause conditions use named rule boundaries scope by recording the six existing rules, their current outputs, and their direct verification tests; verify the inventory against the proposal, design, and condition-readability specification before editing Swift.
- [x] 1.2 Establish the Refactoring preserves existing behavior baseline by running the existing lookup-management, order-merge, campaign-summary, order-filter, localization, and order-edit-dirty tests; verify that the baseline test results are recorded for comparison after the refactor.

## 2. 收斂付款旗標與表單 dirty 判斷

- [x] 2.1 Apply the Decision: 以 Equatable 旗標快照取代付款旗標長串比較 by comparing one flag snapshot in LookupManagementFeature; missing stored entries SHALL remain false and flagsChanged SHALL be true exactly when one of the three flags differs. Verify with editWithUnchangedFlagsRenamesWithoutRetroactiveConfirmation, editWithNoAffectedOrdersAppliesFlagsWithoutConfirmation, and new assertions covering each changed flag and a missing entry in apps/ios/BuyLedgerTests/LookupManagementFeatureTests.swift.
- [x] 2.2 Apply the Decision: 以 Equatable 旗標快照取代付款旗標長串比較 to PaymentMethodEditorSheet by comparing draft and initial snapshots; isDirty SHALL remain true for any name or flag change and false for equal snapshots. Verify with testCancelWithChangesThenContinueEditingStaysOnForm and testCancelWithChangesThenDiscardLeavesForm in apps/ios/BuyLedgerUITests/Tests/Orders/OrderEditDirtyTests.swift, plus Swift parsing of the changed source.
- [x] 2.3 Apply the Decision: 先補規則測試，再以解析與測試驗證重構 to cover the payment snapshot truth table without changing reducer actions, persistence writes, or confirmation behavior; verify the affected LookupManagementFeatureTests and OrderEditDirtyTests pass unchanged apart from the added assertions.

## 3. 抽出訂單合併資格規則

- [x] 3.1 Apply the Decision: 將合併候選資格集中為具名 predicate by moving the primary-order, merged/cancelled-status, currency, and customer checks into one side-effect-free eligibility rule while preserving input order. Verify eligibleCandidatesFilterMatrix and add explicit cases for each rejected candidate in apps/ios/BuyLedgerTests/OrderMergeFeatureTests.swift.
- [x] 3.2 Apply the Decision: 先補規則測試，再以解析與測試驗證重構 for merge eligibility by confirming valid candidates remain identical and invalid candidates never enter the candidate sheet; verify the existing OrderMergeFeatureTests flow tests continue to pass.

## 4. 集中到貨狀態規則

- [x] 4.1 Apply the Decision: 以 OrderStatus 具名集合表達到貨狀態 by defining one domain-level delivery status set and using membership for CampaignSummary.arrivedCount; arrived, delivered, and pickedUp SHALL count, while partiallyArrived, cancelled, and merged SHALL not count in the numerator. Verify arrivedCountsTowardDeliveryProgress and partiallyArrivedCountsInDenominatorButNotNumerator in apps/ios/BuyLedgerTests/CampaignSummaryTests.swift.
- [x] 4.2 Apply the Decision: 先補規則測試，再以解析與測試驗證重構 for delivery aggregation by preserving activeCount exclusion and zero-denominator deliveryRatio behavior; verify deliveryRatioExcludesCancelledFromDenominator and deliveryRatioExcludesMergedFromDenominator.

## 5. 命名整合篩選啟用狀態

- [x] 5.1 Apply the Decision: 讓 PendingFilterSelection 提供啟用狀態 by adding a typed isActive query and making OrdersCompactView consume it; the default datePeriod, nil category, and nil payment method SHALL report inactive, and any one non-default value SHALL report active. Verify new truth-table assertions in apps/ios/BuyLedgerTests/OrdersFilterOperationsTests.swift.
- [x] 5.2 Apply the Decision: 先補規則測試，再以解析與測試驗證重構 for filter presentation by confirming filter sheet pending/committed behavior and the selected filter summary remain unchanged; verify filterSheetTappedSeedsPendingSelectionAndClearsSearch, filterApplyTappedCommitsChangesAndRecomputesSelection, and filterCancelTappedWithUnappliedChangesPresentsDiscardConfirmation.

## 6. 將 localization 禁止條件資料化

- [x] 6.1 Apply the Decision: 將 localization 禁止 pattern 集合化 by replacing the three navigationTitle substring checks with one named pattern collection and a data-driven membership query; the scanner SHALL report the same three forbidden forms and ignore sources containing none. Verify rootNavigationTitlesUseTheExplicitLanguageModifier in apps/ios/BuyLedgerTests/LocalizationCatalogTests.swift with one positive case per pattern and one clean source case.

## 7. 整體驗收與範圍檢查

- [x] 7.1 Verify the Refactoring preserves existing behavior by running all affected Unit Tests and the two OrderEditDirtyTests UI scenarios; confirm unchanged candidate ordering, flagsChanged decisions, isDirty transitions, arrivedCount/deliveryRatio values, filter activation, and localization violations.
- [x] 7.2 Verify the Targeted multi-clause conditions use named rule boundaries by reviewing the diff and scanning the six call sites for removal of the original long boolean chains; run Swift source parsing and git diff --check, and confirm the diff contains no SwiftData schema, public API, TCA action, UI copy, or out-of-scope condition changes.
- [x] 7.3 Verify the Implementation Contract's observable behavior, interface and data shape, failure modes, acceptance criteria, and scope boundaries by reviewing the final diff against design.md and condition-readability/spec.md; record any mismatch as a blocking review finding before implementation begins.
