# customer-summary Specification

## Purpose

TBD - created by archiving change 'tca-view-store-refactor'. Update Purpose after archive.

## Requirements

### Requirement: Customers screen aggregates orders into per-customer summaries

The customers screen SHALL derive its rows entirely from the existing orders, grouping orders by customer name. For each customer the screen SHALL report the customer's order count, total spent (the sum of each member order's revenue), and the most-recent order date, and SHALL carry that customer's initials and tier. The list SHALL be sorted by total spent in descending order. The screen SHALL NOT hold any persisted customer state of its own; when the underlying orders change, the summaries SHALL recompute from the current orders.

#### Scenario: Aggregate orders by customer

- **WHEN** the customers screen is shown with existing orders
- **THEN** each row represents one customer with that customer's order count, total spent, and most-recent order date, and the rows are ordered by total spent descending

##### Example: three customers ranked by spend

- **GIVEN** orders: Amy(revenue=300, date=2026-03-01), Amy(revenue=200, date=2026-03-05), Bob(revenue=400, date=2026-03-02), Cara(revenue=100, date=2026-03-03)
- **WHEN** the customers screen aggregates them
- **THEN** the rows are: Amy(orderCount=2, totalSpent=500, lastOrderDate=2026-03-05), Bob(orderCount=1, totalSpent=400, lastOrderDate=2026-03-02), Cara(orderCount=1, totalSpent=100, lastOrderDate=2026-03-03), in that order

#### Scenario: Empty state when there are no orders

- **WHEN** there are no orders
- **THEN** the customers screen shows its empty state and no customer rows

<!-- @trace
source: tca-view-store-refactor
updated: 2026-07-12
code:
  - apps/ios/BuyLedgerTests/CustomersFeatureTests.swift
  - apps/ios/BuyLedgerTests/FxFeatureTests.swift
  - apps/ios/BuyLedger/Features/Customers/CustomersFeature.swift
  - apps/ios/BuyLedger/Features/Orders/OrderEditView.swift
  - apps/ios/BuyLedgerTests/OrdersFeatureTests.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsView.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersCompactView.swift
  - apps/ios/BuyLedgerTests/LookupManagementFeatureTests.swift
  - apps/ios/BuyLedger/Features/Orders/OrderEditFeature.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardStats.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsStats.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersView.swift
  - apps/ios/BuyLedgerTests/InsightsAttributionTests.swift
  - apps/ios/BuyLedger/Features/Quote/QuoteFeature.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests.swift
  - apps/ios/BuyLedger/Features/App/SidebarBadgeCounts.swift
  - apps/ios/BuyLedger/Features/App/RootFeature.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsView.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementView.swift
  - apps/ios/BuyLedger.xcodeproj/project.pbxproj
  - apps/ios/BuyLedger/Features/Campaigns/CampaignDetailView.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignFeature.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersFeature.swift
  - apps/ios/BuyLedgerTests/InsightsStatsTests.swift
  - apps/ios/BuyLedger/Features/Customers/CustomersView.swift
  - apps/ios/BuyLedgerTests/CampaignFeatureTests.swift
  - apps/ios/BuyLedgerTests/QuoteFeatureTests.swift
  - apps/ios/BuyLedgerTests/OrderEditFeatureTests.swift
  - apps/ios/BuyLedgerTests/SettingsFeatureTests.swift
  - apps/ios/BuyLedger/Features/FX/FxFeature.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift
  - apps/ios/BuyLedger/Features/FX/FxView.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsFeature.swift
  - apps/ios/BuyLedgerTests/DashboardStatsTests.swift
  - apps/ios/BuyLedger/Features/Orders/OrderDetailPath.swift
  - apps/ios/BuyLedger/Features/Quote/QuoteView.swift
  - apps/ios/BuyLedger/Features/App/RootSidebarLayout.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardView.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsDateRange.swift
-->
