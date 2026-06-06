# order-campaign-filter Specification

## Purpose

TBD - created by archiving change 'add-campaign-management'. Update Purpose after archive.

## Requirements

### Requirement: Filter orders by campaign status

The system SHALL let the orders list filter by campaign status with three options: all, ongoing, and closed. Selecting all SHALL apply no campaign-status restriction. The ongoing and closed options SHALL match an order when at least one campaign in the order's campaign list has the selected status.

#### Scenario: Filter to ongoing campaigns

- **WHEN** the user selects the ongoing campaign-status filter
- **THEN** only orders assigned to at least one campaign whose status is ongoing are shown

##### Example: campaign-status filter with multi-campaign orders

| Selected filter | Order's campaigns and their statuses    | Order shown |
| --------------- | --------------------------------------- | ----------- |
| all             | ["May-JP" (ongoing)]                    | yes         |
| all             | [] (unassigned)                         | yes         |
| ongoing         | ["May-JP" (ongoing)]                    | yes         |
| ongoing         | ["April-KR" (closed)]                   | no          |
| ongoing         | ["April-KR" (closed), "May-JP" (ongoing)] | yes       |
| closed          | ["April-KR" (closed)]                   | yes         |
| closed          | ["May-JP" (ongoing)]                    | no          |


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
### Requirement: Filter orders by a specific campaign

The system SHALL let the orders list filter by a specific campaign name. A specific-campaign constraint SHALL match an order only when the order's campaign list contains the selected campaign. The campaign-status filter and the specific-campaign filter SHALL compose with the existing search, order-status, date-period, category, and payment-method filters so that all active filters apply together.

#### Scenario: Filter by a specific campaign

- **WHEN** the user selects a specific campaign in the orders filter
- **THEN** only orders whose campaign list contains that campaign are shown

##### Example: specific-campaign filter with multi-campaign orders

- **GIVEN** orders: O1(campaigns=["May-JP"]), O2(campaigns=["May-JP", "June-KR"]), O3(campaigns=["June-KR"]), O4(campaigns=[])
- **WHEN** the specific-campaign filter is "May-JP"
- **THEN** the list shows exactly { O1, O2 }

#### Scenario: Campaign filter composes with category filter

- **WHEN** the user selects a specific campaign and a specific category
- **THEN** only orders whose campaign list contains that campaign and whose category list contains that category are shown

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