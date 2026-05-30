# order-campaign-filter Specification

## Purpose

TBD - created by archiving change 'add-campaign-management'. Update Purpose after archive.

## Requirements

### Requirement: Filter orders by campaign status

The system SHALL let the orders list filter by campaign status with three options: all, ongoing, and closed. Selecting all SHALL apply no campaign-status restriction. The ongoing and closed options SHALL match an order through the status of the campaign it is assigned to.

#### Scenario: Filter to ongoing campaigns

- **WHEN** the user selects the ongoing campaign-status filter
- **THEN** only orders assigned to a campaign whose status is ongoing are shown

##### Example: campaign-status filter

| Selected filter | Order's campaign status | Order shown |
| --------------- | ----------------------- | ----------- |
| all             | ongoing                 | yes         |
| all             | unassigned              | yes         |
| ongoing         | ongoing                 | yes         |
| ongoing         | closed                  | no          |
| closed          | closed                  | yes         |
| closed          | ongoing                 | no          |


<!-- @trace
source: add-campaign-management
updated: 2026-05-30
code:
  - BuyLedger/BuyLedgerTests/OrdersFeatureTests.swift
  - BuyLedger/BuyLedger/Features/Campaigns/CampaignEditView.swift
  - BuyLedger/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewBaseline.1.png
  - BuyLedger/BuyLedgerTests/__Snapshots__/SnapshotTests/blBarChartThirtyDaysBaseline.2.png
  - BuyLedger/BuyLedger/Features/Insights/InsightsView.swift
  - BuyLedger/BuyLedgerTests/SnapshotTests.swift
  - BuyLedger/BuyLedger/Features/App/RootFeature.swift
  - BuyLedger/BuyLedger/Core/Persistence/CampaignPersistence.swift
  - BuyLedger/BuyLedger/Features/Campaigns/CampaignListView.swift
  - BuyLedger/BuyLedger/Features/Campaigns/CampaignFormatters.swift
  - BuyLedger/BuyLedger/Features/Dashboard/DashboardView.swift
  - BuyLedger/BuyLedger/Core/Domain/LedgerOrder+Samples.swift
  - BuyLedger/BuyLedger/Features/Campaigns/CampaignEditFeature.swift
  - BuyLedger/BuyLedgerTests/CampaignFeatureTests.swift
  - BuyLedger/BuyLedgerTests/__Snapshots__/SnapshotTests/insightsViewBaseline.2.png
  - BuyLedger/BuyLedgerTests/OrdersFeaturePerformanceTests.swift
  - BuyLedger/BuyLedger/Core/Dependencies/CampaignRepository.swift
  - BuyLedger/BuyLedgerTests/__Snapshots__/SnapshotTests/dashboardViewBaseline.2.png
  - BuyLedger/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewBaseline.2.png
  - BuyLedger/BuyLedgerTests/OrderCalculationTests.swift
  - BuyLedger/BuyLedgerTests/OrderPersistenceTests.swift
  - BuyLedger/BuyLedger/Features/Orders/OrderEditFeature.swift
  - BuyLedger/BuyLedger/Features/Orders/OrderEditView.swift
  - BuyLedger/BuyLedger/Features/Orders/OrdersFeature.swift
  - BuyLedger/BuyLedger/Features/Campaigns/CampaignDetailView.swift
  - BuyLedger/BuyLedger/Features/Campaigns/CampaignSummary.swift
  - BuyLedger/BuyLedger/Features/App/RootTab.swift
  - BuyLedger/BuyLedger/Core/Domain/LedgerOrder.swift
  - BuyLedger/BuyLedgerTests/CampaignIntegrationTests.swift
  - BuyLedger/BuyLedger/Core/Persistence/OrderRecord.swift
  - BuyLedger/BuyLedger/Core/Domain/Campaign+Samples.swift
  - BuyLedger/BuyLedgerTests/CampaignSummaryTests.swift
  - BuyLedger/BuyLedgerTests/OrderEditFeatureTests.swift
  - BuyLedger/BuyLedgerTests/__Snapshots__/SnapshotTests/orderDetailCostBreakdownBaseline.2.png
  - BuyLedger/BuyLedger/Core/Domain/PaymentReceiptStatus.swift
  - BuyLedger/BuyLedger/Core/Persistence/OrderPersistence.swift
  - BuyLedger/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewBaseline.2.png
  - BuyLedger/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewLongContentBaseline.2.png
  - BuyLedger/BuyLedger/Core/Persistence/PersistenceContainer.swift
  - BuyLedger/BuyLedger/Core/Domain/CampaignStatus.swift
  - BuyLedger/BuyLedgerTests/CampaignPersistenceTests.swift
  - BuyLedger/BuyLedger/Core/Persistence/BuyLedgerSchema.swift
  - BuyLedger/BuyLedgerTests/RootFeatureTests.swift
  - BuyLedger/BuyLedger/Core/Dependencies/OrderRepository.swift
  - BuyLedger/BuyLedger/Features/App/RootSidebarLayout.swift
  - BuyLedger/BuyLedger/Core/Persistence/CampaignRecord.swift
  - BuyLedger/BuyLedger/Features/App/RootTabLayout.swift
  - BuyLedger/BuyLedger/Core/Domain/Campaign.swift
  - BuyLedger/BuyLedger/Features/Campaigns/CampaignFeature.swift
-->

---
### Requirement: Filter orders by a specific campaign

The system SHALL let the orders list filter by a specific campaign name. The campaign-status filter and the specific-campaign filter SHALL compose with the existing search, order-status, date-period, category, and payment-method filters so that all active filters apply together.

#### Scenario: Filter by a specific campaign

- **WHEN** the user selects a specific campaign in the orders filter
- **THEN** only orders assigned to that campaign are shown

#### Scenario: Campaign filter composes with category filter

- **WHEN** the user selects a specific campaign and a specific category
- **THEN** only orders assigned to that campaign and belonging to that category are shown

<!-- @trace
source: add-campaign-management
updated: 2026-05-30
code:
  - BuyLedger/BuyLedgerTests/OrdersFeatureTests.swift
  - BuyLedger/BuyLedger/Features/Campaigns/CampaignEditView.swift
  - BuyLedger/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewBaseline.1.png
  - BuyLedger/BuyLedgerTests/__Snapshots__/SnapshotTests/blBarChartThirtyDaysBaseline.2.png
  - BuyLedger/BuyLedger/Features/Insights/InsightsView.swift
  - BuyLedger/BuyLedgerTests/SnapshotTests.swift
  - BuyLedger/BuyLedger/Features/App/RootFeature.swift
  - BuyLedger/BuyLedger/Core/Persistence/CampaignPersistence.swift
  - BuyLedger/BuyLedger/Features/Campaigns/CampaignListView.swift
  - BuyLedger/BuyLedger/Features/Campaigns/CampaignFormatters.swift
  - BuyLedger/BuyLedger/Features/Dashboard/DashboardView.swift
  - BuyLedger/BuyLedger/Core/Domain/LedgerOrder+Samples.swift
  - BuyLedger/BuyLedger/Features/Campaigns/CampaignEditFeature.swift
  - BuyLedger/BuyLedgerTests/CampaignFeatureTests.swift
  - BuyLedger/BuyLedgerTests/__Snapshots__/SnapshotTests/insightsViewBaseline.2.png
  - BuyLedger/BuyLedgerTests/OrdersFeaturePerformanceTests.swift
  - BuyLedger/BuyLedger/Core/Dependencies/CampaignRepository.swift
  - BuyLedger/BuyLedgerTests/__Snapshots__/SnapshotTests/dashboardViewBaseline.2.png
  - BuyLedger/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewBaseline.2.png
  - BuyLedger/BuyLedgerTests/OrderCalculationTests.swift
  - BuyLedger/BuyLedgerTests/OrderPersistenceTests.swift
  - BuyLedger/BuyLedger/Features/Orders/OrderEditFeature.swift
  - BuyLedger/BuyLedger/Features/Orders/OrderEditView.swift
  - BuyLedger/BuyLedger/Features/Orders/OrdersFeature.swift
  - BuyLedger/BuyLedger/Features/Campaigns/CampaignDetailView.swift
  - BuyLedger/BuyLedger/Features/Campaigns/CampaignSummary.swift
  - BuyLedger/BuyLedger/Features/App/RootTab.swift
  - BuyLedger/BuyLedger/Core/Domain/LedgerOrder.swift
  - BuyLedger/BuyLedgerTests/CampaignIntegrationTests.swift
  - BuyLedger/BuyLedger/Core/Persistence/OrderRecord.swift
  - BuyLedger/BuyLedger/Core/Domain/Campaign+Samples.swift
  - BuyLedger/BuyLedgerTests/CampaignSummaryTests.swift
  - BuyLedger/BuyLedgerTests/OrderEditFeatureTests.swift
  - BuyLedger/BuyLedgerTests/__Snapshots__/SnapshotTests/orderDetailCostBreakdownBaseline.2.png
  - BuyLedger/BuyLedger/Core/Domain/PaymentReceiptStatus.swift
  - BuyLedger/BuyLedger/Core/Persistence/OrderPersistence.swift
  - BuyLedger/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewBaseline.2.png
  - BuyLedger/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewLongContentBaseline.2.png
  - BuyLedger/BuyLedger/Core/Persistence/PersistenceContainer.swift
  - BuyLedger/BuyLedger/Core/Domain/CampaignStatus.swift
  - BuyLedger/BuyLedgerTests/CampaignPersistenceTests.swift
  - BuyLedger/BuyLedger/Core/Persistence/BuyLedgerSchema.swift
  - BuyLedger/BuyLedgerTests/RootFeatureTests.swift
  - BuyLedger/BuyLedger/Core/Dependencies/OrderRepository.swift
  - BuyLedger/BuyLedger/Features/App/RootSidebarLayout.swift
  - BuyLedger/BuyLedger/Core/Persistence/CampaignRecord.swift
  - BuyLedger/BuyLedger/Features/App/RootTabLayout.swift
  - BuyLedger/BuyLedger/Core/Domain/Campaign.swift
  - BuyLedger/BuyLedger/Features/Campaigns/CampaignFeature.swift
-->