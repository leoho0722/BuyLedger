# order-category-assignment Specification

## Purpose

TBD - created by archiving change 'add-order-merge'. Update Purpose after archive.

## Requirements

### Requirement: An order can be assigned to multiple categories

The system SHALL store an order's product categories as an ordered list of category names without duplicates. The order editor SHALL require at least one category before the order can be saved. Multiple categories arise only through the merge flow; the regular editor keeps single selection.

#### Scenario: Merge produces a multi-category order

- **WHEN** the user confirms a merge whose source orders carry the categories "beauty" and "snacks"
- **THEN** the merged order records both category names in union order

#### Scenario: At least one category is required

- **WHEN** the order editor's category selection is empty
- **THEN** the editor's save action is disabled, consistent with the existing required-field handling


<!-- @trace
source: add-order-merge
updated: 2026-06-07
code:
  - apps/apple/BuyLedger/Features/Orders/OrdersView.swift
  - apps/apple/BuyLedger/Features/Orders/OrdersCompactView.swift
  - apps/apple/BuyLedger/Features/Orders/OrdersMacView.swift
  - apps/apple/BuyLedgerTests/OrderMergeFeatureTests.swift
  - apps/apple/BuyLedger/Features/Orders/OrdersFeature.swift
  - apps/apple/BuyLedger/Features/Orders/Components/OrderRowView.swift
  - apps/apple/BuyLedger/Features/Orders/Components/OrderMergeCandidateSheet.swift
  - apps/apple/BuyLedger/Features/Orders/OrderMergeFeature.swift
-->

---
### Requirement: Category multi-selection is offered only in merge contexts

The order editor SHALL open a multi-select category picker only when the draft is a merge confirmation draft or the edited order was produced by a merge (its merged-source list is non-empty). In the multi-select picker, tapping a row SHALL toggle its selection without dismissing the sheet, the sheet SHALL provide an explicit done action, and the existing add-new-category flow SHALL remain available. The category trigger row SHALL display the selected categories joined by "、". For every other order, the editor SHALL keep the existing single-select category picker, and the selection SHALL be stored as a one-element category list.

#### Scenario: Merge confirmation form offers multi-select

- **WHEN** the user opens the category picker inside a merge confirmation form and taps "beauty" then "snacks"
- **THEN** both rows show a selected indicator and the sheet stays open until the user confirms with the done action

#### Scenario: Trigger row shows the joined selection

- **WHEN** a merge confirmation draft has categories ["beauty", "snacks"]
- **THEN** the category trigger row in the editor displays "beauty、snacks"

#### Scenario: Regular orders keep single selection

- **WHEN** the user edits an order that was not produced by a merge and opens the category picker
- **THEN** the picker behaves as the existing single-select sheet, and choosing "beauty" stores the category list ["beauty"]


<!-- @trace
source: add-order-merge
updated: 2026-06-07
code:
  - apps/apple/BuyLedger/Features/Orders/OrdersView.swift
  - apps/apple/BuyLedger/Features/Orders/OrdersCompactView.swift
  - apps/apple/BuyLedger/Features/Orders/OrdersMacView.swift
  - apps/apple/BuyLedgerTests/OrderMergeFeatureTests.swift
  - apps/apple/BuyLedger/Features/Orders/OrdersFeature.swift
  - apps/apple/BuyLedger/Features/Orders/Components/OrderRowView.swift
  - apps/apple/BuyLedger/Features/Orders/Components/OrderMergeCandidateSheet.swift
  - apps/apple/BuyLedger/Features/Orders/OrderMergeFeature.swift
-->

---
### Requirement: Category revenue attributes pre-merge amounts from leaf orders

The Insights category revenue breakdown SHALL aggregate "leaf" orders — orders whose merged-source list is empty — whose status is in the realized allowlist or is merged. Orders produced by a merge SHALL NOT contribute to the category breakdown; their revenue enters through their pre-merge source orders, each with its own original categories, amounts, and order date. Because multi-selection is offered only in merge contexts, leaf orders carry exactly one category and the attribution is exact; as a defensive rule, a leaf order that nevertheless carries multiple categories SHALL contribute its full amounts to each of them. A leaf order whose category list is empty SHALL NOT appear in any category bucket.

#### Scenario: Merged order's revenue enters through its sources

- **WHEN** leaf orders A (categories ["beauty"], profit 1000) and B (categories ["snacks"], profit 2000) have been merged into order M
- **THEN** the category breakdown shows beauty +1000 and snacks +2000, and M contributes nothing to the breakdown

##### Example: attribution matrix

| Order | Leaf | Status    | Categories            | Profit | beauty | snacks |
| ----- | ---- | --------- | --------------------- | ------ | ------ | ------ |
| A     | yes  | merged    | ["beauty"]            | 1000   | +1000  | —      |
| B     | yes  | merged    | ["snacks"]            | 2000   | —      | +2000  |
| M     | no   | purchased | ["beauty", "snacks"]  | 3000   | —      | —      |
| D     | yes  | quoting   | ["beauty"]            | 400    | —      | —      |


<!-- @trace
source: add-order-merge
updated: 2026-06-07
code:
  - apps/apple/BuyLedger/Features/Orders/OrdersView.swift
  - apps/apple/BuyLedger/Features/Orders/OrdersCompactView.swift
  - apps/apple/BuyLedger/Features/Orders/OrdersMacView.swift
  - apps/apple/BuyLedgerTests/OrderMergeFeatureTests.swift
  - apps/apple/BuyLedger/Features/Orders/OrdersFeature.swift
  - apps/apple/BuyLedger/Features/Orders/Components/OrderRowView.swift
  - apps/apple/BuyLedger/Features/Orders/Components/OrderMergeCandidateSheet.swift
  - apps/apple/BuyLedger/Features/Orders/OrderMergeFeature.swift
-->

---
### Requirement: Renaming a category cascades into order category lists

When a category is renamed, the system SHALL replace every occurrence of the old name inside each order's category list, in persistence and in the in-memory order copies, within a single update.

#### Scenario: Cascade rename inside a multi-category order

- **WHEN** the category "beauty" is renamed to "cosmetics" and an order has categories ["beauty", "snacks"]
- **THEN** that order's categories become ["cosmetics", "snacks"] in both persistence and the in-memory list

<!-- @trace
source: add-order-merge
updated: 2026-06-07
code:
  - apps/apple/BuyLedger/Features/Orders/OrdersView.swift
  - apps/apple/BuyLedger/Features/Orders/OrdersCompactView.swift
  - apps/apple/BuyLedger/Features/Orders/OrdersMacView.swift
  - apps/apple/BuyLedgerTests/OrderMergeFeatureTests.swift
  - apps/apple/BuyLedger/Features/Orders/OrdersFeature.swift
  - apps/apple/BuyLedger/Features/Orders/Components/OrderRowView.swift
  - apps/apple/BuyLedger/Features/Orders/Components/OrderMergeCandidateSheet.swift
  - apps/apple/BuyLedger/Features/Orders/OrderMergeFeature.swift
-->