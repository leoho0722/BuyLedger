# campaign-analytics-surfaces Specification

## Purpose

TBD - created by archiving change 'add-campaign-management'. Update Purpose after archive.

## Requirements

### Requirement: Dashboard shows an ongoing campaigns card

The dashboard SHALL show a card listing the ongoing campaigns, each with its derived progress and total amount. When there are no ongoing campaigns, the dashboard SHALL hide the card entirely rather than show an empty card.

#### Scenario: Card lists ongoing campaigns

- **WHEN** there is at least one ongoing campaign
- **THEN** the dashboard shows the ongoing campaigns card with each ongoing campaign's progress and amount

#### Scenario: Card hidden when none ongoing

- **WHEN** there are no ongoing campaigns
- **THEN** the dashboard does not render the ongoing campaigns card


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
### Requirement: Insights shows a per-campaign profit ranking

The insights view SHALL show a bar chart that ranks campaigns by profit, where each campaign's profit is computed by aggregating its member orders. Campaigns without member orders SHALL be excluded from the ranking.

#### Scenario: Profit ranking is shown

- **WHEN** at least one campaign has member orders
- **THEN** insights shows a bar chart of campaigns ranked by profit

##### Example: profit ranking order

- **GIVEN** campaigns with profits Camp-A=3000, Camp-B=1200, Camp-C=4500
- **WHEN** the ranking is computed
- **THEN** the bars appear in order Camp-C, Camp-A, Camp-B


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
### Requirement: Selecting a campaign navigates to its detail

The system SHALL provide a navigation action that switches to the campaign tab and opens the selected campaign's detail. Tapping a campaign in the dashboard ongoing campaigns card or in the insights profit ranking SHALL trigger this navigation.

#### Scenario: Navigate from the dashboard card

- **WHEN** the user taps a campaign in the dashboard ongoing campaigns card
- **THEN** the app switches to the campaign tab and opens that campaign's detail

#### Scenario: Navigate from the insights ranking

- **WHEN** the user taps a campaign bar in the insights profit ranking
- **THEN** the app switches to the campaign tab and opens that campaign's detail

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
### Requirement: Campaign analytics attribute pre-merge amounts from leaf orders

Every campaign analytics surface — the dashboard ongoing campaigns card, the insights per-campaign profit ranking, and the campaign detail summary (including the distribution list) — SHALL compute a campaign's member set from "leaf" orders: orders whose merged-source list is empty and whose campaign list contains the campaign name. Orders produced by a merge SHALL NOT be campaign members; their revenue enters through their pre-merge source orders, each with its own original campaigns, amounts, receipt status, and order date. Membership SHALL impose no additional status restriction beyond the pre-existing aggregation rules, so merged-away source orders keep contributing exactly as they did before the merge. The delivery-progress denominator SHALL exclude merged orders in the same way it already excludes cancelled orders, because a merged-away order no longer awaits delivery on its own. Because multi-selection is offered only in merge contexts, leaf orders carry at most one campaign and the attribution is exact; as a defensive rule, a leaf order that nevertheless carries multiple campaigns SHALL contribute its full amounts to each of them.

#### Scenario: Merged order's revenue enters campaign aggregates through its sources

- **WHEN** leaf orders A (campaigns ["May-JP"], profit 1000) and B (campaigns ["June-KR"], profit 2000) have been merged into order M
- **THEN** the profit ranking and campaign summaries show May-JP +1000 and June-KR +2000, and M contributes to neither campaign

##### Example: campaign attribution matrix

| Order | Leaf | Status    | Campaigns               | Profit | May-JP | June-KR |
| ----- | ---- | --------- | ----------------------- | ------ | ------ | ------- |
| A     | yes  | merged    | ["May-JP"]              | 1000   | +1000  | —       |
| B     | yes  | merged    | ["June-KR"]             | 2000   | —      | +2000   |
| M     | no   | shipping  | ["May-JP", "June-KR"]   | 3000   | —      | —       |
| C     | yes  | delivered | ["May-JP"]              | 500    | +500   | —       |

#### Scenario: Campaign membership uses list containment

- **WHEN** a campaign summary is computed for "May-JP"
- **THEN** its member orders are exactly the leaf orders whose campaign list contains "May-JP"

#### Scenario: Delivery progress ignores merged-away members

- **WHEN** a campaign has members with statuses delivered, merged, and shipping
- **THEN** the delivery-progress denominator counts only the delivered and shipping members, and the merged member is excluded like a cancelled one

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