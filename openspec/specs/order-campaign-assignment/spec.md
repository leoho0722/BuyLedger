# order-campaign-assignment Specification

## Purpose

TBD - created by archiving change 'add-campaign-management'. Update Purpose after archive.

## Requirements

### Requirement: The order editor selects from existing campaigns only

The system SHALL let the order editor choose among existing campaigns only, and SHALL NOT create a new campaign from within the order editor. In merge contexts — a merge confirmation draft, or editing an order whose merged-source list is non-empty — the editor SHALL offer a multi-select campaign picker: tapping a row toggles its selection without dismissing the sheet, and the sheet provides an explicit done action. For every other order, the editor SHALL keep the existing single-select campaign selector with an unassigned option, and the selection SHALL be stored as a one-element campaign list (unassigned as an empty list). An empty selection SHALL be valid and displayed as unassigned (未歸團) on the campaign trigger row; a non-empty multi-selection SHALL be displayed joined by "、".

#### Scenario: Merge confirmation form offers existing campaigns as toggles

- **WHEN** the user opens the campaign selector inside a merge confirmation form
- **THEN** the selector lists the existing campaigns as toggleable rows, with no create-campaign action

#### Scenario: Regular orders keep single selection

- **WHEN** the user edits an order that was not produced by a merge and opens the campaign selector
- **THEN** the selector behaves as the existing single-select control with an unassigned option, and choosing "May-JP" stores the campaign list ["May-JP"]

#### Scenario: Empty selection means unassigned

- **WHEN** the user deselects every campaign in a merge confirmation form and confirms
- **THEN** the order's campaign list is empty and the trigger row displays 未歸團


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
### Requirement: Renaming a campaign cascades to its orders

The system SHALL replace every occurrence of the old campaign name inside each order's campaign list when a campaign is renamed, keeping persisted orders and the in-memory order copies consistent in a single update.

#### Scenario: Cascade rename

- **WHEN** a campaign named "三月日本團" is renamed to "三月日本團 (補)"
- **THEN** every order whose campaign list previously contained "三月日本團" now contains "三月日本團 (補)" in its place, in both persistence and the in-memory order list, with other list elements unchanged


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
### Requirement: An order can be assigned to multiple campaigns

The system SHALL store an order's campaign assignment as an ordered list of campaign names without duplicates. An order whose campaign list is empty SHALL be treated as unassigned and SHALL NOT belong to any campaign. Multiple campaigns arise only through the merge flow; the regular editor keeps single selection.

#### Scenario: Merge produces a multi-campaign order

- **WHEN** the user confirms a merge whose source orders carry the campaigns "May-JP" and "June-KR"
- **THEN** the merged order records both campaign names in union order

#### Scenario: Unassigned order

- **WHEN** an order has an empty campaign list
- **THEN** the order is excluded from every campaign's distribution and settlement

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