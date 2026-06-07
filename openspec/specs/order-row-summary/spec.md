# order-row-summary Specification

## Purpose

TBD - created by archiving change 'order-row-e-layout'. Update Purpose after archive.

## Requirements

### Requirement: Row first line shows customer and order date

The order list row SHALL display, on its first line, the customer name followed by the localized short order date (month/day), separated by a middle dot, with the order status pill positioned immediately to the right of the date. The first line SHALL NOT display the order number suffix.

#### Scenario: First line composition

- **WHEN** the order list renders a row for an order
- **THEN** the first line displays the customer name, a middle dot, and the order's short date
- **AND** the order status pill appears to the right of the date
- **AND** the row SHALL NOT display the order number or any order number suffix


<!-- @trace
source: order-row-e-layout
updated: 2026-05-26
code:
  - apps/apple/BuyLedger/Shared/DesignSystem/Components/Tags/BLTagPill.swift
  - apps/apple/BuyLedger/Features/Orders/OrdersView.swift
  - apps/apple/BuyLedgerTests/__Snapshots__/SnapshotTests/blBarChartThirtyDaysBaseline.2.png
  - apps/apple/BuyLedger/Features/Orders/OrdersCompactView.swift
  - apps/apple/BuyLedger/Features/Orders/Components/OrderRowView.swift
  - apps/apple/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewBaseline.2.png
  - apps/apple/BuyLedger/Features/Dashboard/DashboardView.swift
  - apps/apple/BuyLedger/Features/Orders/OrdersMacView.swift
  - apps/apple/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewBaseline.1.png
  - apps/apple/BuyLedgerTests/__Snapshots__/SnapshotTests/dashboardViewBaseline.1.png
  - apps/apple/BuyLedgerTests/__Snapshots__/SnapshotTests/orderDetailCostBreakdownBaseline.2.png
  - apps/apple/BuyLedger.xcodeproj/project.pbxproj
  - apps/apple/BuyLedgerTests/__Snapshots__/SnapshotTests/dashboardViewBaseline.2.png
  - apps/apple/BuyLedgerTests/__Snapshots__/SnapshotTests/insightsViewBaseline.2.png
  - apps/apple/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewBaseline.2.png
-->

---
### Requirement: Row second line shows item details

The order list row SHALL display the order's item summary on its second line, listing each item name.

#### Scenario: Item summary rendering

- **WHEN** the order list renders a row for an order with one or more items
- **THEN** the second line displays the item names


<!-- @trace
source: order-row-e-layout
updated: 2026-05-26
code:
  - apps/apple/BuyLedger/Shared/DesignSystem/Components/Tags/BLTagPill.swift
  - apps/apple/BuyLedger/Features/Orders/OrdersView.swift
  - apps/apple/BuyLedgerTests/__Snapshots__/SnapshotTests/blBarChartThirtyDaysBaseline.2.png
  - apps/apple/BuyLedger/Features/Orders/OrdersCompactView.swift
  - apps/apple/BuyLedger/Features/Orders/Components/OrderRowView.swift
  - apps/apple/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewBaseline.2.png
  - apps/apple/BuyLedger/Features/Dashboard/DashboardView.swift
  - apps/apple/BuyLedger/Features/Orders/OrdersMacView.swift
  - apps/apple/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewBaseline.1.png
  - apps/apple/BuyLedgerTests/__Snapshots__/SnapshotTests/dashboardViewBaseline.1.png
  - apps/apple/BuyLedgerTests/__Snapshots__/SnapshotTests/orderDetailCostBreakdownBaseline.2.png
  - apps/apple/BuyLedger.xcodeproj/project.pbxproj
  - apps/apple/BuyLedgerTests/__Snapshots__/SnapshotTests/dashboardViewBaseline.2.png
  - apps/apple/BuyLedgerTests/__Snapshots__/SnapshotTests/insightsViewBaseline.2.png
  - apps/apple/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewBaseline.2.png
-->

---
### Requirement: Row third line shows product category as a tag

The order list row SHALL display the order's categories on its third line as a neutral-tone capsule containing the category names joined by "、", preceded by a tag icon placed outside the capsule and vertically centered against the capsule. The capsule text SHALL remain on a single line. When the category list is empty, or every element trims to whitespace, the row SHALL NOT render the third line.

#### Scenario: Category present

- **WHEN** the order's category list contains at least one non-whitespace name
- **THEN** the third line displays a tag icon followed by a neutral-tone capsule containing the category names joined by "、"

#### Scenario: Category absent

- **WHEN** the order's category list is empty or every element is whitespace after trimming
- **THEN** the row SHALL NOT render the third line, and SHALL NOT render an empty capsule or a standalone tag icon

##### Example: category rendering by value

| order.categories     | Third line rendered          |
| -------------------- | ---------------------------- |
| ["服飾"]              | tag icon + capsule "服飾"     |
| ["服飾", "美妝"]      | tag icon + capsule "服飾、美妝" |
| []                   | not rendered                 |
| ["   "]              | not rendered                 |


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
### Requirement: Row uses symmetric vertical spacing

The order list row SHALL use uniform vertical spacing between its content lines and between the row content and the row separator, so the category tag has equal spacing above and below it and the separator is equidistant from the content of adjacent rows.

#### Scenario: Symmetric spacing around the category tag

- **WHEN** the order list renders a row whose category tag is the last content line
- **THEN** the spacing above the category tag equals the spacing below it down to the row separator

##### Example: spacing values

- **GIVEN** the row content lines are customer/date, item details, and the category tag
- **WHEN** the row renders on iOS
- **THEN** the spacing between each content line is 8 points
- **AND** the spacing from the category tag to the separator is 8 points

<!-- @trace
source: order-row-e-layout
updated: 2026-05-26
code:
  - apps/apple/BuyLedger/Shared/DesignSystem/Components/Tags/BLTagPill.swift
  - apps/apple/BuyLedger/Features/Orders/OrdersView.swift
  - apps/apple/BuyLedgerTests/__Snapshots__/SnapshotTests/blBarChartThirtyDaysBaseline.2.png
  - apps/apple/BuyLedger/Features/Orders/OrdersCompactView.swift
  - apps/apple/BuyLedger/Features/Orders/Components/OrderRowView.swift
  - apps/apple/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewBaseline.2.png
  - apps/apple/BuyLedger/Features/Dashboard/DashboardView.swift
  - apps/apple/BuyLedger/Features/Orders/OrdersMacView.swift
  - apps/apple/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewBaseline.1.png
  - apps/apple/BuyLedgerTests/__Snapshots__/SnapshotTests/dashboardViewBaseline.1.png
  - apps/apple/BuyLedgerTests/__Snapshots__/SnapshotTests/orderDetailCostBreakdownBaseline.2.png
  - apps/apple/BuyLedger.xcodeproj/project.pbxproj
  - apps/apple/BuyLedgerTests/__Snapshots__/SnapshotTests/dashboardViewBaseline.2.png
  - apps/apple/BuyLedgerTests/__Snapshots__/SnapshotTests/insightsViewBaseline.2.png
  - apps/apple/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewBaseline.2.png
-->

---
### Requirement: Optional charged-amount trailing variant

The order row component SHALL offer an optional trailing-column variant for hosting contexts that need the charged amount: in this variant the trailing column SHALL display the order's charged amount with a charged-amount caption label, replacing the status pill, revenue, and profit. The leading column (avatar, customer name, date, item summary, category tag) SHALL render identically to the default variant. The default variant SHALL remain the status pill with revenue and profit, and call sites that do not specify a variant SHALL be unaffected.

#### Scenario: Charged-amount variant

- **WHEN** a host renders the order row with the charged-amount trailing variant
- **THEN** the trailing column shows the order's charged amount and the charged-amount label, and the leading column renders identically to the default variant

#### Scenario: Default variant unchanged

- **WHEN** a host renders the order row without specifying a trailing variant
- **THEN** the row renders the status pill, revenue, and profit exactly as before the variant was introduced


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