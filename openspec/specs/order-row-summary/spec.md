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
  - BuyLedger/BuyLedger/Shared/DesignSystem/Components/Tags/BLTagPill.swift
  - BuyLedger/BuyLedger/Features/Orders/OrdersView.swift
  - BuyLedger/BuyLedgerTests/__Snapshots__/SnapshotTests/blBarChartThirtyDaysBaseline.2.png
  - BuyLedger/BuyLedger/Features/Orders/OrdersCompactView.swift
  - BuyLedger/BuyLedger/Features/Orders/Components/OrderRowView.swift
  - BuyLedger/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewBaseline.2.png
  - BuyLedger/BuyLedger/Features/Dashboard/DashboardView.swift
  - BuyLedger/BuyLedger/Features/Orders/OrdersMacView.swift
  - BuyLedger/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewBaseline.1.png
  - BuyLedger/BuyLedgerTests/__Snapshots__/SnapshotTests/dashboardViewBaseline.1.png
  - BuyLedger/BuyLedgerTests/__Snapshots__/SnapshotTests/orderDetailCostBreakdownBaseline.2.png
  - BuyLedger/BuyLedger.xcodeproj/project.pbxproj
  - BuyLedger/BuyLedgerTests/__Snapshots__/SnapshotTests/dashboardViewBaseline.2.png
  - BuyLedger/BuyLedgerTests/__Snapshots__/SnapshotTests/insightsViewBaseline.2.png
  - BuyLedger/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewBaseline.2.png
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
  - BuyLedger/BuyLedger/Shared/DesignSystem/Components/Tags/BLTagPill.swift
  - BuyLedger/BuyLedger/Features/Orders/OrdersView.swift
  - BuyLedger/BuyLedgerTests/__Snapshots__/SnapshotTests/blBarChartThirtyDaysBaseline.2.png
  - BuyLedger/BuyLedger/Features/Orders/OrdersCompactView.swift
  - BuyLedger/BuyLedger/Features/Orders/Components/OrderRowView.swift
  - BuyLedger/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewBaseline.2.png
  - BuyLedger/BuyLedger/Features/Dashboard/DashboardView.swift
  - BuyLedger/BuyLedger/Features/Orders/OrdersMacView.swift
  - BuyLedger/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewBaseline.1.png
  - BuyLedger/BuyLedgerTests/__Snapshots__/SnapshotTests/dashboardViewBaseline.1.png
  - BuyLedger/BuyLedgerTests/__Snapshots__/SnapshotTests/orderDetailCostBreakdownBaseline.2.png
  - BuyLedger/BuyLedger.xcodeproj/project.pbxproj
  - BuyLedger/BuyLedgerTests/__Snapshots__/SnapshotTests/dashboardViewBaseline.2.png
  - BuyLedger/BuyLedgerTests/__Snapshots__/SnapshotTests/insightsViewBaseline.2.png
  - BuyLedger/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewBaseline.2.png
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
  - BuyLedger/BuyLedger/Features/Orders/Components/OptionPickerSheet.swift
  - BuyLedger/BuyLedger/Features/Orders/OrdersFeature.swift
  - BuyLedger/BuyLedgerTests/__Snapshots__/SnapshotTests/dashboardViewBaseline.2.png
  - BuyLedger/BuyLedgerTests/OrderEditFeatureTests.swift
  - BuyLedger/BuyLedgerTests/OrdersFeaturePerformanceTests.swift
  - BuyLedger/BuyLedger/Features/Orders/OrdersView.swift
  - BuyLedger/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewBaseline.2.png
  - BuyLedger/BuyLedger/Features/Campaigns/CampaignFeature.swift
  - BuyLedger/BuyLedgerTests/__Snapshots__/SnapshotTests/insightsViewBaseline.1.png
  - BuyLedger/BuyLedgerTests/SnapshotTests.swift
  - BuyLedger/BuyLedgerTests/InsightsAttributionTests.swift
  - BuyLedger/BuyLedgerTests/CampaignSummaryTests.swift
  - BuyLedger/BuyLedger/Features/Insights/InsightsView.swift
  - BuyLedger/BuyLedger/Features/Orders/Components/OrderMergeCandidateSheet.swift
  - BuyLedger/BuyLedgerTests/OrdersFeatureTests.swift
  - BuyLedger/BuyLedgerTests/SchemaMigrationTests.swift
  - BuyLedger/BuyLedger/Core/Persistence/OrderPersistence.swift
  - BuyLedger/BuyLedger/Features/Orders/OrderEditFeature.swift
  - BuyLedger/BuyLedger/Core/Persistence/BuyLedgerSchema.swift
  - BuyLedger/BuyLedger/Core/Persistence/OrderRecord.swift
  - BuyLedger/BuyLedger/Features/Orders/OrderMergeFeature.swift
  - BuyLedger/BuyLedgerTests/OrderStatusTests.swift
  - BuyLedger/BuyLedger/Core/Domain/LedgerOrder.swift
  - BuyLedger/BuyLedger/Features/Orders/OrderEditView.swift
  - BuyLedger/BuyLedgerTests/OrderMergeTests.swift
  - BuyLedger/BuyLedger/Core/Domain/Campaign+Samples.swift
  - BuyLedger/BuyLedgerTests/RootFeatureTests.swift
  - BuyLedger/BuyLedger/Features/Orders/Components/MergePhotoPickerSheet.swift
  - BuyLedger/BuyLedgerTests/__Snapshots__/SnapshotTests/dashboardViewBaseline.1.png
  - BuyLedger/BuyLedger/Core/Domain/LedgerOrder+Samples.swift
  - BuyLedger/BuyLedgerTests/__Snapshots__/SnapshotTests/blBarChartThirtyDaysBaseline.2.png
  - BuyLedger/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewBaseline.2.png
  - BuyLedger/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewLongContentBaseline.2.png
  - BuyLedger/BuyLedger/Features/Campaigns/CampaignSummary.swift
  - BuyLedger/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewMergeContextBaseline.2.png
  - BuyLedger/BuyLedger/Features/Orders/Components/OrderRowView.swift
  - BuyLedger/BuyLedger/Features/Orders/Components/OrderStatus+Presentation.swift
  - BuyLedger/BuyLedger/Features/Dashboard/DashboardView.swift
  - BuyLedger/BuyLedgerTests/CampaignIntegrationTests.swift
  - BuyLedger/BuyLedger/Features/Orders/OrdersCompactView.swift
  - BuyLedger/BuyLedger/Core/Domain/Campaign.swift
  - BuyLedger/BuyLedgerTests/__Snapshots__/SnapshotTests/orderDetailCostBreakdownBaseline.2.png
  - BuyLedger/BuyLedgerTests/OrderPersistenceTests.swift
  - BuyLedger/BuyLedger/Core/Domain/OrderMerge.swift
  - BuyLedger/BuyLedgerTests/__Snapshots__/SnapshotTests/insightsViewBaseline.2.png
  - BuyLedger/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewBaseline.1.png
  - BuyLedger/BuyLedgerTests/OrderMergeFeatureTests.swift
  - BuyLedger/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewMergeContextBaseline.1.png
  - BuyLedger/BuyLedger/Core/Dependencies/OrderRepository.swift
  - BuyLedger/BuyLedger/Features/Orders/OrdersMacView.swift
  - BuyLedger/BuyLedgerTests/__Snapshots__/SnapshotTests/orderDetailCostBreakdownBaseline.1.png
  - BuyLedger/BuyLedgerTests/OrderCalculationTests.swift
  - BuyLedger/BuyLedger/Core/Persistence/PersistenceContainer.swift
  - BuyLedger/BuyLedger/Core/Domain/OrderStatus.swift
  - BuyLedger/BuyLedger/Features/Orders/Components/OrderDetailView.swift
  - BuyLedger/BuyLedger/Features/App/RootFeature.swift
  - BuyLedger/BuyLedger/Features/Orders/OrderStatusFilter.swift
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
  - BuyLedger/BuyLedger/Shared/DesignSystem/Components/Tags/BLTagPill.swift
  - BuyLedger/BuyLedger/Features/Orders/OrdersView.swift
  - BuyLedger/BuyLedgerTests/__Snapshots__/SnapshotTests/blBarChartThirtyDaysBaseline.2.png
  - BuyLedger/BuyLedger/Features/Orders/OrdersCompactView.swift
  - BuyLedger/BuyLedger/Features/Orders/Components/OrderRowView.swift
  - BuyLedger/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewBaseline.2.png
  - BuyLedger/BuyLedger/Features/Dashboard/DashboardView.swift
  - BuyLedger/BuyLedger/Features/Orders/OrdersMacView.swift
  - BuyLedger/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewBaseline.1.png
  - BuyLedger/BuyLedgerTests/__Snapshots__/SnapshotTests/dashboardViewBaseline.1.png
  - BuyLedger/BuyLedgerTests/__Snapshots__/SnapshotTests/orderDetailCostBreakdownBaseline.2.png
  - BuyLedger/BuyLedger.xcodeproj/project.pbxproj
  - BuyLedger/BuyLedgerTests/__Snapshots__/SnapshotTests/dashboardViewBaseline.2.png
  - BuyLedger/BuyLedgerTests/__Snapshots__/SnapshotTests/insightsViewBaseline.2.png
  - BuyLedger/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewBaseline.2.png
-->