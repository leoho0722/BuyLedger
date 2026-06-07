# order-payment-receipt-status Specification

## Purpose

TBD - created by archiving change 'add-campaign-management'. Update Purpose after archive.

## Requirements

### Requirement: Every order carries a payment receipt status

The system SHALL provide a payment receipt status on every order with exactly two values: pending ("待收款") and received ("已收款"). New orders and existing orders migrated from earlier schema versions SHALL default to pending.

#### Scenario: Default receipt status

- **WHEN** an order is created without an explicit receipt status
- **THEN** the order's receipt status is pending


<!-- @trace
source: add-campaign-management
updated: 2026-05-30
code:
  - apps/apple/BuyLedgerTests/OrdersFeatureTests.swift
  - apps/apple/BuyLedger/Features/Campaigns/CampaignEditView.swift
  - apps/apple/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewBaseline.1.png
  - apps/apple/BuyLedgerTests/__Snapshots__/SnapshotTests/blBarChartThirtyDaysBaseline.2.png
  - apps/apple/BuyLedger/Features/Insights/InsightsView.swift
  - apps/apple/BuyLedgerTests/SnapshotTests.swift
  - apps/apple/BuyLedger/Features/App/RootFeature.swift
  - apps/apple/BuyLedger/Core/Persistence/CampaignPersistence.swift
  - apps/apple/BuyLedger/Features/Campaigns/CampaignListView.swift
  - apps/apple/BuyLedger/Features/Campaigns/CampaignFormatters.swift
  - apps/apple/BuyLedger/Features/Dashboard/DashboardView.swift
  - apps/apple/BuyLedger/Core/Domain/LedgerOrder+Samples.swift
  - apps/apple/BuyLedger/Features/Campaigns/CampaignEditFeature.swift
  - apps/apple/BuyLedgerTests/CampaignFeatureTests.swift
  - apps/apple/BuyLedgerTests/__Snapshots__/SnapshotTests/insightsViewBaseline.2.png
  - apps/apple/BuyLedgerTests/OrdersFeaturePerformanceTests.swift
  - apps/apple/BuyLedger/Core/Dependencies/CampaignRepository.swift
  - apps/apple/BuyLedgerTests/__Snapshots__/SnapshotTests/dashboardViewBaseline.2.png
  - apps/apple/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewBaseline.2.png
  - apps/apple/BuyLedgerTests/OrderCalculationTests.swift
  - apps/apple/BuyLedgerTests/OrderPersistenceTests.swift
  - apps/apple/BuyLedger/Features/Orders/OrderEditFeature.swift
  - apps/apple/BuyLedger/Features/Orders/OrderEditView.swift
  - apps/apple/BuyLedger/Features/Orders/OrdersFeature.swift
  - apps/apple/BuyLedger/Features/Campaigns/CampaignDetailView.swift
  - apps/apple/BuyLedger/Features/Campaigns/CampaignSummary.swift
  - apps/apple/BuyLedger/Features/App/RootTab.swift
  - apps/apple/BuyLedger/Core/Domain/LedgerOrder.swift
  - apps/apple/BuyLedgerTests/CampaignIntegrationTests.swift
  - apps/apple/BuyLedger/Core/Persistence/OrderRecord.swift
  - apps/apple/BuyLedger/Core/Domain/Campaign+Samples.swift
  - apps/apple/BuyLedgerTests/CampaignSummaryTests.swift
  - apps/apple/BuyLedgerTests/OrderEditFeatureTests.swift
  - apps/apple/BuyLedgerTests/__Snapshots__/SnapshotTests/orderDetailCostBreakdownBaseline.2.png
  - apps/apple/BuyLedger/Core/Domain/PaymentReceiptStatus.swift
  - apps/apple/BuyLedger/Core/Persistence/OrderPersistence.swift
  - apps/apple/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewBaseline.2.png
  - apps/apple/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewLongContentBaseline.2.png
  - apps/apple/BuyLedger/Core/Persistence/PersistenceContainer.swift
  - apps/apple/BuyLedger/Core/Domain/CampaignStatus.swift
  - apps/apple/BuyLedgerTests/CampaignPersistenceTests.swift
  - apps/apple/BuyLedger/Core/Persistence/BuyLedgerSchema.swift
  - apps/apple/BuyLedgerTests/RootFeatureTests.swift
  - apps/apple/BuyLedger/Core/Dependencies/OrderRepository.swift
  - apps/apple/BuyLedger/Features/App/RootSidebarLayout.swift
  - apps/apple/BuyLedger/Core/Persistence/CampaignRecord.swift
  - apps/apple/BuyLedger/Features/App/RootTabLayout.swift
  - apps/apple/BuyLedger/Core/Domain/Campaign.swift
  - apps/apple/BuyLedger/Features/Campaigns/CampaignFeature.swift
-->

---
### Requirement: Receipt status is editable for all orders

The system SHALL let the user set an order's payment receipt status in the order editor regardless of the order's payment method.

#### Scenario: Set an order to received

- **WHEN** the user sets an order's receipt status to received and saves
- **THEN** the order persists with receipt status received


<!-- @trace
source: add-campaign-management
updated: 2026-05-30
code:
  - apps/apple/BuyLedgerTests/OrdersFeatureTests.swift
  - apps/apple/BuyLedger/Features/Campaigns/CampaignEditView.swift
  - apps/apple/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewBaseline.1.png
  - apps/apple/BuyLedgerTests/__Snapshots__/SnapshotTests/blBarChartThirtyDaysBaseline.2.png
  - apps/apple/BuyLedger/Features/Insights/InsightsView.swift
  - apps/apple/BuyLedgerTests/SnapshotTests.swift
  - apps/apple/BuyLedger/Features/App/RootFeature.swift
  - apps/apple/BuyLedger/Core/Persistence/CampaignPersistence.swift
  - apps/apple/BuyLedger/Features/Campaigns/CampaignListView.swift
  - apps/apple/BuyLedger/Features/Campaigns/CampaignFormatters.swift
  - apps/apple/BuyLedger/Features/Dashboard/DashboardView.swift
  - apps/apple/BuyLedger/Core/Domain/LedgerOrder+Samples.swift
  - apps/apple/BuyLedger/Features/Campaigns/CampaignEditFeature.swift
  - apps/apple/BuyLedgerTests/CampaignFeatureTests.swift
  - apps/apple/BuyLedgerTests/__Snapshots__/SnapshotTests/insightsViewBaseline.2.png
  - apps/apple/BuyLedgerTests/OrdersFeaturePerformanceTests.swift
  - apps/apple/BuyLedger/Core/Dependencies/CampaignRepository.swift
  - apps/apple/BuyLedgerTests/__Snapshots__/SnapshotTests/dashboardViewBaseline.2.png
  - apps/apple/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewBaseline.2.png
  - apps/apple/BuyLedgerTests/OrderCalculationTests.swift
  - apps/apple/BuyLedgerTests/OrderPersistenceTests.swift
  - apps/apple/BuyLedger/Features/Orders/OrderEditFeature.swift
  - apps/apple/BuyLedger/Features/Orders/OrderEditView.swift
  - apps/apple/BuyLedger/Features/Orders/OrdersFeature.swift
  - apps/apple/BuyLedger/Features/Campaigns/CampaignDetailView.swift
  - apps/apple/BuyLedger/Features/Campaigns/CampaignSummary.swift
  - apps/apple/BuyLedger/Features/App/RootTab.swift
  - apps/apple/BuyLedger/Core/Domain/LedgerOrder.swift
  - apps/apple/BuyLedgerTests/CampaignIntegrationTests.swift
  - apps/apple/BuyLedger/Core/Persistence/OrderRecord.swift
  - apps/apple/BuyLedger/Core/Domain/Campaign+Samples.swift
  - apps/apple/BuyLedgerTests/CampaignSummaryTests.swift
  - apps/apple/BuyLedgerTests/OrderEditFeatureTests.swift
  - apps/apple/BuyLedgerTests/__Snapshots__/SnapshotTests/orderDetailCostBreakdownBaseline.2.png
  - apps/apple/BuyLedger/Core/Domain/PaymentReceiptStatus.swift
  - apps/apple/BuyLedger/Core/Persistence/OrderPersistence.swift
  - apps/apple/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewBaseline.2.png
  - apps/apple/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewLongContentBaseline.2.png
  - apps/apple/BuyLedger/Core/Persistence/PersistenceContainer.swift
  - apps/apple/BuyLedger/Core/Domain/CampaignStatus.swift
  - apps/apple/BuyLedgerTests/CampaignPersistenceTests.swift
  - apps/apple/BuyLedger/Core/Persistence/BuyLedgerSchema.swift
  - apps/apple/BuyLedgerTests/RootFeatureTests.swift
  - apps/apple/BuyLedger/Core/Dependencies/OrderRepository.swift
  - apps/apple/BuyLedger/Features/App/RootSidebarLayout.swift
  - apps/apple/BuyLedger/Core/Persistence/CampaignRecord.swift
  - apps/apple/BuyLedger/Features/App/RootTabLayout.swift
  - apps/apple/BuyLedger/Core/Domain/Campaign.swift
  - apps/apple/BuyLedger/Features/Campaigns/CampaignFeature.swift
-->

---
### Requirement: Receipt status is the source of truth for received amounts

The payment receipt status SHALL be the sole source of truth for the "received" determination in campaign distribution and settlement. An order's charged amount SHALL contribute to a campaign's received amount only when that order's receipt status is received.

#### Scenario: Received order contributes to received amount

- **WHEN** an order belonging to a campaign has receipt status received
- **THEN** its charged amount is included in that campaign's received amount

#### Scenario: Pending order does not contribute to received amount

- **WHEN** an order belonging to a campaign has receipt status pending
- **THEN** its charged amount is excluded from that campaign's received amount but included in receivables

<!-- @trace
source: add-campaign-management
updated: 2026-05-30
code:
  - apps/apple/BuyLedgerTests/OrdersFeatureTests.swift
  - apps/apple/BuyLedger/Features/Campaigns/CampaignEditView.swift
  - apps/apple/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewBaseline.1.png
  - apps/apple/BuyLedgerTests/__Snapshots__/SnapshotTests/blBarChartThirtyDaysBaseline.2.png
  - apps/apple/BuyLedger/Features/Insights/InsightsView.swift
  - apps/apple/BuyLedgerTests/SnapshotTests.swift
  - apps/apple/BuyLedger/Features/App/RootFeature.swift
  - apps/apple/BuyLedger/Core/Persistence/CampaignPersistence.swift
  - apps/apple/BuyLedger/Features/Campaigns/CampaignListView.swift
  - apps/apple/BuyLedger/Features/Campaigns/CampaignFormatters.swift
  - apps/apple/BuyLedger/Features/Dashboard/DashboardView.swift
  - apps/apple/BuyLedger/Core/Domain/LedgerOrder+Samples.swift
  - apps/apple/BuyLedger/Features/Campaigns/CampaignEditFeature.swift
  - apps/apple/BuyLedgerTests/CampaignFeatureTests.swift
  - apps/apple/BuyLedgerTests/__Snapshots__/SnapshotTests/insightsViewBaseline.2.png
  - apps/apple/BuyLedgerTests/OrdersFeaturePerformanceTests.swift
  - apps/apple/BuyLedger/Core/Dependencies/CampaignRepository.swift
  - apps/apple/BuyLedgerTests/__Snapshots__/SnapshotTests/dashboardViewBaseline.2.png
  - apps/apple/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewBaseline.2.png
  - apps/apple/BuyLedgerTests/OrderCalculationTests.swift
  - apps/apple/BuyLedgerTests/OrderPersistenceTests.swift
  - apps/apple/BuyLedger/Features/Orders/OrderEditFeature.swift
  - apps/apple/BuyLedger/Features/Orders/OrderEditView.swift
  - apps/apple/BuyLedger/Features/Orders/OrdersFeature.swift
  - apps/apple/BuyLedger/Features/Campaigns/CampaignDetailView.swift
  - apps/apple/BuyLedger/Features/Campaigns/CampaignSummary.swift
  - apps/apple/BuyLedger/Features/App/RootTab.swift
  - apps/apple/BuyLedger/Core/Domain/LedgerOrder.swift
  - apps/apple/BuyLedgerTests/CampaignIntegrationTests.swift
  - apps/apple/BuyLedger/Core/Persistence/OrderRecord.swift
  - apps/apple/BuyLedger/Core/Domain/Campaign+Samples.swift
  - apps/apple/BuyLedgerTests/CampaignSummaryTests.swift
  - apps/apple/BuyLedgerTests/OrderEditFeatureTests.swift
  - apps/apple/BuyLedgerTests/__Snapshots__/SnapshotTests/orderDetailCostBreakdownBaseline.2.png
  - apps/apple/BuyLedger/Core/Domain/PaymentReceiptStatus.swift
  - apps/apple/BuyLedger/Core/Persistence/OrderPersistence.swift
  - apps/apple/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewBaseline.2.png
  - apps/apple/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewLongContentBaseline.2.png
  - apps/apple/BuyLedger/Core/Persistence/PersistenceContainer.swift
  - apps/apple/BuyLedger/Core/Domain/CampaignStatus.swift
  - apps/apple/BuyLedgerTests/CampaignPersistenceTests.swift
  - apps/apple/BuyLedger/Core/Persistence/BuyLedgerSchema.swift
  - apps/apple/BuyLedgerTests/RootFeatureTests.swift
  - apps/apple/BuyLedger/Core/Dependencies/OrderRepository.swift
  - apps/apple/BuyLedger/Features/App/RootSidebarLayout.swift
  - apps/apple/BuyLedger/Core/Persistence/CampaignRecord.swift
  - apps/apple/BuyLedger/Features/App/RootTabLayout.swift
  - apps/apple/BuyLedger/Core/Domain/Campaign.swift
  - apps/apple/BuyLedger/Features/Campaigns/CampaignFeature.swift
-->