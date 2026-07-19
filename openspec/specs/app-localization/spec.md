# app-localization Specification

## Purpose

TBD - created by archiving change 'add-app-language-switching'. Update Purpose after archive.

## Requirements

### Requirement: Supported App languages

The App SHALL localize all shipped static user-facing iOS and iPadOS interface text through a String Catalog for Traditional Chinese and English. The App SHALL use Traditional Chinese when no valid language preference has been stored.

#### Scenario: First launch uses Traditional Chinese

- **GIVEN** settings.language is absent or contains an unknown value
- **WHEN** the App launches
- **THEN** all shipped static interface text is presented in Traditional Chinese

#### Scenario: Both supported localizations are complete

- **WHEN** the Localizable String Catalog is validated
- **THEN** every shipped static user-facing key has a non-empty Traditional Chinese value and a non-empty English translation

##### Example: Dashboard title has both values

- **GIVEN** the shipped static key is `儀表板`
- **WHEN** its `zh-Hant` and `en` String Catalog entries are inspected
- **THEN** the values are `儀表板` and `Dashboard`, respectively

#### Scenario: English mode has no shipped static Chinese residue

- **GIVEN** the user selected English
- **WHEN** the user navigates through every reachable iPhone screen and the iPad sidebar layout
- **THEN** every shipped static navigation title, section, control, status, filter, empty state, error state, and locale-aware date or formatted value is presented in English
- **THEN** user-entered content, external data, brand names, and identifiers remain unchanged

##### Example: Dashboard and Orders use English consistently

- **GIVEN** English is selected and the current date is July 18, 2026
- **WHEN** the user visits Dashboard and Orders
- **THEN** `總覽`, `訂單`, and `全部` are displayed as `Overview`, `Orders`, and `All`
- **THEN** the date is formatted with the English locale rather than displayed as `7月18日星期六`

#### Scenario: Reported order-flow controls use English consistently

- **GIVEN** English is selected and the user opens More, its currency and AI-model selectors, and an order with editable data
- **WHEN** the user opens source-currency, default-currency, AI-model, order-source, category, and payment-method pickers, then opens order creation, editing, and detail screens
- **THEN** `更多`, `選擇來源幣別`, `選擇預設幣別`, `選擇 AI 模型`, `收款進度`, `到貨進度`, `待收款`, `已收款`, `到貨`, `收款`, `選擇來源`, `選擇類別`, `選擇訂單來源`, `選擇商品類別`, and `選擇付款方式` are presented in English
- **THEN** the add-source and add-category placeholders and helper text are presented in English
- **THEN** user-entered source, category, payment-method, product, and customer values remain unchanged


<!-- @trace
source: add-app-language-switching
updated: 2026-07-19
code:
  - apps/ios/BuyLedger/Features/More/MoreView.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/LedgerOrder.generated.swift
  - apps/ios/BuyLedger/Features/App/RootView.swift
  - apps/ios/BuyLedger/Core/Domain/OrderMerge.swift
  - apps/ios/BuyLedger/Features/Customers/CustomersView.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/SegmentedControls/BLSegmentedControl.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewBaseline.1.png
  - apps/ios/BuyLedger/Core/Dependencies/ReconciliationStatusRepository.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsStats.swift
  - apps/ios/BuyLedgerTests/CampaignIntegrationTests.swift
  - apps/ios/BuyLedger/Core/Dependencies/OrderRepository.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignEditView.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardView.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift
  - apps/ios/BuyLedger/Features/Orders/Components/PaymentMethodEditorSheet.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsFeature.swift
  - apps/ios/BuyLedger/Features/App/RootSidebarLayout.swift
  - apps/ios/BuyLedgerTests/LookupManagementFeatureTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/insightsViewBaseline.2.png
  - apps/ios/BuyLedger/Features/Settings/SettingsSnapshot.swift
  - apps/ios/BuyLedger/Features/App/RootFeature.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLDonutChart.swift
  - apps/ios/BuyLedgerTests/SchemaMigrationTests.swift
  - apps/ios/BuyLedgerTests/OrdersFeatureTests.swift
  - apps/ios/BuyLedgerTests/InsightsStatsTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderDetailCostBreakdownBaseline.2.png
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Status/BLStatusPill.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsView.swift
  - apps/ios/BuyLedger/Resources/InfoPlist.xcstrings
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFilterSheet.swift
  - apps/ios/BuyLedger/Features/FX/FxView.swift
  - apps/ios/BuyLedger/Core/Persistence/PersistenceContainer.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignFeature.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersFeature.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewLongContentBaseline.1.png
  - apps/ios/BuyLedgerTests/OrderCalculationTests.swift
  - apps/ios/BuyLedger.xcodeproj/project.pbxproj
  - apps/ios/BuyLedger/Core/Domain/CurrencyCode.swift
  - apps/ios/BuyLedger/Features/Orders/Components/LookupItemEditorSheet.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests.swift
  - shared/data-model/schema/LedgerOrder.yaml
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementView.swift
  - apps/ios/BuyLedgerTests/CampaignSummaryTests.swift
  - apps/ios/BuyLedger/Features/App/RootTabLayout.swift
  - apps/ios/BuyLedger/Core/Persistence/BuyLedgerSchema.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderMergeCandidateSheet.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/TextFields/BLAmountField.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewMergeContextBaseline.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewBaseline.2.png
  - apps/ios/BuyLedger/Features/Orders/OrdersCompactView.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewBaseline.2.png
  - apps/ios/BuyLedgerTests/LocalizationCatalogTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/insightsViewBaseline.1.png
  - apps/ios/BuyLedger/Core/Domain/LedgerOrder+Samples.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Badges/BLBadge.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderDetailCostBreakdownBaseline.1.png
  - apps/ios/BuyLedger/Features/Campaigns/CampaignEditFeature.swift
  - apps/ios/BuyLedger/Core/Persistence/ReconciliationStatusRecord.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/TextFields/BLSearchField.swift
  - apps/ios/BuyLedgerTests/DashboardStatsTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewMergeContextBaseline.2.png
  - apps/ios/BuyLedger/Core/Persistence/VerificationStatusPersistence.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoViewer.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignDetailView.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OptionPickerSheet.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Progress/BLProgressBar.swift
  - apps/ios/BuyLedger/Core/Persistence/VerificationStatusRecord.swift
  - apps/ios/BuyLedger/Resources/Localizable.xcstrings
  - apps/ios/BuyLedgerTests/OrderMergeTests.swift
  - apps/ios/BuyLedgerTests/OrderPersistenceTests.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFormatters.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignFormatters.swift
  - apps/ios/BuyLedgerTests/SnapshotTests.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsView.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignListView.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersView.swift
  - apps/ios/BuyLedger/Features/Orders/OrderEditView.swift
  - apps/ios/BuyLedger/Core/Persistence/OrderPersistence.swift
  - apps/ios/BuyLedgerTests/OrdersFeaturePerformanceTests.swift
  - apps/ios/BuyLedger/Features/Quote/QuoteView.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupKind.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsStorage.swift
  - apps/ios/CLAUDE.md
  - apps/ios/BuyLedger/Shared/Extensions/Locale+Extensions.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderDetailView.swift
  - apps/ios/BuyLedger/Features/Orders/OrderMergeFeature.swift
  - apps/ios/BuyLedgerTests/OrderEditFeatureTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewBaseline.1.png
  - apps/ios/BuyLedger/Features/FX/FxFeature.swift
  - apps/ios/BuyLedgerTests/SettingsFeatureTests.swift
  - apps/ios/BuyLedgerTests/CampaignEditFeatureTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/blBarChartThirtyDaysBaseline.2.png
  - apps/ios/BuyLedgerTests/OrderMergeFeatureTests.swift
  - apps/ios/BuyLedger/Features/Settings/AppLanguage.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderRowView.swift
  - apps/ios/BuyLedger/Core/Dependencies/VerificationStatusRepository.swift
  - apps/ios/README.md
  - apps/ios/BuyLedgerTests/CampaignFeatureTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewLongContentBaseline.2.png
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Lists/BLListRow.swift
  - apps/ios/BuyLedger/Features/AISummary/AISummaryView.swift
  - apps/ios/BuyLedgerTests/InsightsAttributionTests.swift
  - apps/ios/BuyLedger/Features/Orders/OrderEditFeature.swift
  - apps/ios/BuyLedger/Core/Persistence/OrderRecord.swift
  - apps/ios/BuyLedger/Features/Quote/QuoteFeature.swift
  - apps/ios/BuyLedgerTests/CustomersFeatureTests.swift
  - apps/ios/BuyLedger/Core/Persistence/ReconciliationStatusPersistence.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/dashboardViewBaseline.2.png
  - apps/ios/BuyLedger/Features/AISummary/AISummaryFeature.swift
-->

---
### Requirement: Root navigation titles follow the selected App language

The App SHALL present the Dashboard, Orders, Campaigns, Insights, and More root navigation titles using the selected App language. The title presentation path SHALL resolve the String Catalog through the selected App language's localization bundle so it remains correct after an in-app language change.

#### Scenario: Root titles update in both directions

- **GIVEN** the user is on each root tab in turn
- **WHEN** the user selects English
- **THEN** the navigation titles are `Overview`, `Orders`, `Campaigns`, `Insights`, and `More`
- **WHEN** the user selects Traditional Chinese
- **THEN** the navigation titles are `總覽`, `訂單`, `開團`, `分析`, and `更多`


<!-- @trace
source: add-app-language-switching
updated: 2026-07-19
code:
  - apps/ios/BuyLedger/Features/More/MoreView.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/LedgerOrder.generated.swift
  - apps/ios/BuyLedger/Features/App/RootView.swift
  - apps/ios/BuyLedger/Core/Domain/OrderMerge.swift
  - apps/ios/BuyLedger/Features/Customers/CustomersView.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/SegmentedControls/BLSegmentedControl.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewBaseline.1.png
  - apps/ios/BuyLedger/Core/Dependencies/ReconciliationStatusRepository.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsStats.swift
  - apps/ios/BuyLedgerTests/CampaignIntegrationTests.swift
  - apps/ios/BuyLedger/Core/Dependencies/OrderRepository.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignEditView.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardView.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift
  - apps/ios/BuyLedger/Features/Orders/Components/PaymentMethodEditorSheet.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsFeature.swift
  - apps/ios/BuyLedger/Features/App/RootSidebarLayout.swift
  - apps/ios/BuyLedgerTests/LookupManagementFeatureTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/insightsViewBaseline.2.png
  - apps/ios/BuyLedger/Features/Settings/SettingsSnapshot.swift
  - apps/ios/BuyLedger/Features/App/RootFeature.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLDonutChart.swift
  - apps/ios/BuyLedgerTests/SchemaMigrationTests.swift
  - apps/ios/BuyLedgerTests/OrdersFeatureTests.swift
  - apps/ios/BuyLedgerTests/InsightsStatsTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderDetailCostBreakdownBaseline.2.png
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Status/BLStatusPill.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsView.swift
  - apps/ios/BuyLedger/Resources/InfoPlist.xcstrings
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFilterSheet.swift
  - apps/ios/BuyLedger/Features/FX/FxView.swift
  - apps/ios/BuyLedger/Core/Persistence/PersistenceContainer.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignFeature.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersFeature.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewLongContentBaseline.1.png
  - apps/ios/BuyLedgerTests/OrderCalculationTests.swift
  - apps/ios/BuyLedger.xcodeproj/project.pbxproj
  - apps/ios/BuyLedger/Core/Domain/CurrencyCode.swift
  - apps/ios/BuyLedger/Features/Orders/Components/LookupItemEditorSheet.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests.swift
  - shared/data-model/schema/LedgerOrder.yaml
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementView.swift
  - apps/ios/BuyLedgerTests/CampaignSummaryTests.swift
  - apps/ios/BuyLedger/Features/App/RootTabLayout.swift
  - apps/ios/BuyLedger/Core/Persistence/BuyLedgerSchema.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderMergeCandidateSheet.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/TextFields/BLAmountField.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewMergeContextBaseline.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewBaseline.2.png
  - apps/ios/BuyLedger/Features/Orders/OrdersCompactView.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewBaseline.2.png
  - apps/ios/BuyLedgerTests/LocalizationCatalogTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/insightsViewBaseline.1.png
  - apps/ios/BuyLedger/Core/Domain/LedgerOrder+Samples.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Badges/BLBadge.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderDetailCostBreakdownBaseline.1.png
  - apps/ios/BuyLedger/Features/Campaigns/CampaignEditFeature.swift
  - apps/ios/BuyLedger/Core/Persistence/ReconciliationStatusRecord.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/TextFields/BLSearchField.swift
  - apps/ios/BuyLedgerTests/DashboardStatsTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewMergeContextBaseline.2.png
  - apps/ios/BuyLedger/Core/Persistence/VerificationStatusPersistence.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoViewer.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignDetailView.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OptionPickerSheet.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Progress/BLProgressBar.swift
  - apps/ios/BuyLedger/Core/Persistence/VerificationStatusRecord.swift
  - apps/ios/BuyLedger/Resources/Localizable.xcstrings
  - apps/ios/BuyLedgerTests/OrderMergeTests.swift
  - apps/ios/BuyLedgerTests/OrderPersistenceTests.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFormatters.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignFormatters.swift
  - apps/ios/BuyLedgerTests/SnapshotTests.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsView.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignListView.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersView.swift
  - apps/ios/BuyLedger/Features/Orders/OrderEditView.swift
  - apps/ios/BuyLedger/Core/Persistence/OrderPersistence.swift
  - apps/ios/BuyLedgerTests/OrdersFeaturePerformanceTests.swift
  - apps/ios/BuyLedger/Features/Quote/QuoteView.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupKind.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsStorage.swift
  - apps/ios/CLAUDE.md
  - apps/ios/BuyLedger/Shared/Extensions/Locale+Extensions.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderDetailView.swift
  - apps/ios/BuyLedger/Features/Orders/OrderMergeFeature.swift
  - apps/ios/BuyLedgerTests/OrderEditFeatureTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewBaseline.1.png
  - apps/ios/BuyLedger/Features/FX/FxFeature.swift
  - apps/ios/BuyLedgerTests/SettingsFeatureTests.swift
  - apps/ios/BuyLedgerTests/CampaignEditFeatureTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/blBarChartThirtyDaysBaseline.2.png
  - apps/ios/BuyLedgerTests/OrderMergeFeatureTests.swift
  - apps/ios/BuyLedger/Features/Settings/AppLanguage.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderRowView.swift
  - apps/ios/BuyLedger/Core/Dependencies/VerificationStatusRepository.swift
  - apps/ios/README.md
  - apps/ios/BuyLedgerTests/CampaignFeatureTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewLongContentBaseline.2.png
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Lists/BLListRow.swift
  - apps/ios/BuyLedger/Features/AISummary/AISummaryView.swift
  - apps/ios/BuyLedgerTests/InsightsAttributionTests.swift
  - apps/ios/BuyLedger/Features/Orders/OrderEditFeature.swift
  - apps/ios/BuyLedger/Core/Persistence/OrderRecord.swift
  - apps/ios/BuyLedger/Features/Quote/QuoteFeature.swift
  - apps/ios/BuyLedgerTests/CustomersFeatureTests.swift
  - apps/ios/BuyLedger/Core/Persistence/ReconciliationStatusPersistence.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/dashboardViewBaseline.2.png
  - apps/ios/BuyLedger/Features/AISummary/AISummaryFeature.swift
-->

---
### Requirement: Language selection in Settings

The Settings screen SHALL provide an App language Picker with Traditional Chinese and English options. Its interaction and visual structure SHALL match the existing appearance mode Picker.

#### Scenario: User selects English

- **GIVEN** the App is displaying Traditional Chinese
- **WHEN** the user opens More, navigates to Settings, and selects English
- **THEN** the current interface updates to English without restarting or resetting the navigation stack

#### Scenario: User selects Traditional Chinese

- **GIVEN** the App is displaying English
- **WHEN** the user selects Traditional Chinese in the App language Picker
- **THEN** the current interface updates to Traditional Chinese without restarting or resetting the navigation stack


<!-- @trace
source: add-app-language-switching
updated: 2026-07-19
code:
  - apps/ios/BuyLedger/Features/More/MoreView.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/LedgerOrder.generated.swift
  - apps/ios/BuyLedger/Features/App/RootView.swift
  - apps/ios/BuyLedger/Core/Domain/OrderMerge.swift
  - apps/ios/BuyLedger/Features/Customers/CustomersView.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/SegmentedControls/BLSegmentedControl.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewBaseline.1.png
  - apps/ios/BuyLedger/Core/Dependencies/ReconciliationStatusRepository.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsStats.swift
  - apps/ios/BuyLedgerTests/CampaignIntegrationTests.swift
  - apps/ios/BuyLedger/Core/Dependencies/OrderRepository.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignEditView.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardView.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift
  - apps/ios/BuyLedger/Features/Orders/Components/PaymentMethodEditorSheet.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsFeature.swift
  - apps/ios/BuyLedger/Features/App/RootSidebarLayout.swift
  - apps/ios/BuyLedgerTests/LookupManagementFeatureTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/insightsViewBaseline.2.png
  - apps/ios/BuyLedger/Features/Settings/SettingsSnapshot.swift
  - apps/ios/BuyLedger/Features/App/RootFeature.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLDonutChart.swift
  - apps/ios/BuyLedgerTests/SchemaMigrationTests.swift
  - apps/ios/BuyLedgerTests/OrdersFeatureTests.swift
  - apps/ios/BuyLedgerTests/InsightsStatsTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderDetailCostBreakdownBaseline.2.png
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Status/BLStatusPill.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsView.swift
  - apps/ios/BuyLedger/Resources/InfoPlist.xcstrings
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFilterSheet.swift
  - apps/ios/BuyLedger/Features/FX/FxView.swift
  - apps/ios/BuyLedger/Core/Persistence/PersistenceContainer.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignFeature.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersFeature.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewLongContentBaseline.1.png
  - apps/ios/BuyLedgerTests/OrderCalculationTests.swift
  - apps/ios/BuyLedger.xcodeproj/project.pbxproj
  - apps/ios/BuyLedger/Core/Domain/CurrencyCode.swift
  - apps/ios/BuyLedger/Features/Orders/Components/LookupItemEditorSheet.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests.swift
  - shared/data-model/schema/LedgerOrder.yaml
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementView.swift
  - apps/ios/BuyLedgerTests/CampaignSummaryTests.swift
  - apps/ios/BuyLedger/Features/App/RootTabLayout.swift
  - apps/ios/BuyLedger/Core/Persistence/BuyLedgerSchema.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderMergeCandidateSheet.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/TextFields/BLAmountField.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewMergeContextBaseline.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewBaseline.2.png
  - apps/ios/BuyLedger/Features/Orders/OrdersCompactView.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewBaseline.2.png
  - apps/ios/BuyLedgerTests/LocalizationCatalogTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/insightsViewBaseline.1.png
  - apps/ios/BuyLedger/Core/Domain/LedgerOrder+Samples.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Badges/BLBadge.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderDetailCostBreakdownBaseline.1.png
  - apps/ios/BuyLedger/Features/Campaigns/CampaignEditFeature.swift
  - apps/ios/BuyLedger/Core/Persistence/ReconciliationStatusRecord.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/TextFields/BLSearchField.swift
  - apps/ios/BuyLedgerTests/DashboardStatsTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewMergeContextBaseline.2.png
  - apps/ios/BuyLedger/Core/Persistence/VerificationStatusPersistence.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoViewer.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignDetailView.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OptionPickerSheet.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Progress/BLProgressBar.swift
  - apps/ios/BuyLedger/Core/Persistence/VerificationStatusRecord.swift
  - apps/ios/BuyLedger/Resources/Localizable.xcstrings
  - apps/ios/BuyLedgerTests/OrderMergeTests.swift
  - apps/ios/BuyLedgerTests/OrderPersistenceTests.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFormatters.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignFormatters.swift
  - apps/ios/BuyLedgerTests/SnapshotTests.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsView.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignListView.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersView.swift
  - apps/ios/BuyLedger/Features/Orders/OrderEditView.swift
  - apps/ios/BuyLedger/Core/Persistence/OrderPersistence.swift
  - apps/ios/BuyLedgerTests/OrdersFeaturePerformanceTests.swift
  - apps/ios/BuyLedger/Features/Quote/QuoteView.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupKind.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsStorage.swift
  - apps/ios/CLAUDE.md
  - apps/ios/BuyLedger/Shared/Extensions/Locale+Extensions.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderDetailView.swift
  - apps/ios/BuyLedger/Features/Orders/OrderMergeFeature.swift
  - apps/ios/BuyLedgerTests/OrderEditFeatureTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewBaseline.1.png
  - apps/ios/BuyLedger/Features/FX/FxFeature.swift
  - apps/ios/BuyLedgerTests/SettingsFeatureTests.swift
  - apps/ios/BuyLedgerTests/CampaignEditFeatureTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/blBarChartThirtyDaysBaseline.2.png
  - apps/ios/BuyLedgerTests/OrderMergeFeatureTests.swift
  - apps/ios/BuyLedger/Features/Settings/AppLanguage.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderRowView.swift
  - apps/ios/BuyLedger/Core/Dependencies/VerificationStatusRepository.swift
  - apps/ios/README.md
  - apps/ios/BuyLedgerTests/CampaignFeatureTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewLongContentBaseline.2.png
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Lists/BLListRow.swift
  - apps/ios/BuyLedger/Features/AISummary/AISummaryView.swift
  - apps/ios/BuyLedgerTests/InsightsAttributionTests.swift
  - apps/ios/BuyLedger/Features/Orders/OrderEditFeature.swift
  - apps/ios/BuyLedger/Core/Persistence/OrderRecord.swift
  - apps/ios/BuyLedger/Features/Quote/QuoteFeature.swift
  - apps/ios/BuyLedgerTests/CustomersFeatureTests.swift
  - apps/ios/BuyLedger/Core/Persistence/ReconciliationStatusPersistence.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/dashboardViewBaseline.2.png
  - apps/ios/BuyLedger/Features/AISummary/AISummaryFeature.swift
-->

---
### Requirement: Language preference persistence

The App SHALL persist the selected App language in SettingsStorage and SHALL restore it during App startup before the user visits Settings.

#### Scenario: Relaunch restores English

- **GIVEN** the user selected English and terminated the App
- **WHEN** the App is launched again
- **THEN** the root interface restores English without requiring navigation to Settings

#### Scenario: Invalid persisted preference falls back safely

- **GIVEN** SettingsStorage contains an unsupported language raw value
- **WHEN** settings are loaded
- **THEN** the language state becomes Traditional Chinese and all other stored settings retain their stored values


<!-- @trace
source: add-app-language-switching
updated: 2026-07-19
code:
  - apps/ios/BuyLedger/Features/More/MoreView.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/LedgerOrder.generated.swift
  - apps/ios/BuyLedger/Features/App/RootView.swift
  - apps/ios/BuyLedger/Core/Domain/OrderMerge.swift
  - apps/ios/BuyLedger/Features/Customers/CustomersView.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/SegmentedControls/BLSegmentedControl.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewBaseline.1.png
  - apps/ios/BuyLedger/Core/Dependencies/ReconciliationStatusRepository.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsStats.swift
  - apps/ios/BuyLedgerTests/CampaignIntegrationTests.swift
  - apps/ios/BuyLedger/Core/Dependencies/OrderRepository.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignEditView.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardView.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift
  - apps/ios/BuyLedger/Features/Orders/Components/PaymentMethodEditorSheet.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsFeature.swift
  - apps/ios/BuyLedger/Features/App/RootSidebarLayout.swift
  - apps/ios/BuyLedgerTests/LookupManagementFeatureTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/insightsViewBaseline.2.png
  - apps/ios/BuyLedger/Features/Settings/SettingsSnapshot.swift
  - apps/ios/BuyLedger/Features/App/RootFeature.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLDonutChart.swift
  - apps/ios/BuyLedgerTests/SchemaMigrationTests.swift
  - apps/ios/BuyLedgerTests/OrdersFeatureTests.swift
  - apps/ios/BuyLedgerTests/InsightsStatsTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderDetailCostBreakdownBaseline.2.png
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Status/BLStatusPill.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsView.swift
  - apps/ios/BuyLedger/Resources/InfoPlist.xcstrings
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFilterSheet.swift
  - apps/ios/BuyLedger/Features/FX/FxView.swift
  - apps/ios/BuyLedger/Core/Persistence/PersistenceContainer.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignFeature.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersFeature.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewLongContentBaseline.1.png
  - apps/ios/BuyLedgerTests/OrderCalculationTests.swift
  - apps/ios/BuyLedger.xcodeproj/project.pbxproj
  - apps/ios/BuyLedger/Core/Domain/CurrencyCode.swift
  - apps/ios/BuyLedger/Features/Orders/Components/LookupItemEditorSheet.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests.swift
  - shared/data-model/schema/LedgerOrder.yaml
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementView.swift
  - apps/ios/BuyLedgerTests/CampaignSummaryTests.swift
  - apps/ios/BuyLedger/Features/App/RootTabLayout.swift
  - apps/ios/BuyLedger/Core/Persistence/BuyLedgerSchema.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderMergeCandidateSheet.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/TextFields/BLAmountField.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewMergeContextBaseline.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewBaseline.2.png
  - apps/ios/BuyLedger/Features/Orders/OrdersCompactView.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewBaseline.2.png
  - apps/ios/BuyLedgerTests/LocalizationCatalogTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/insightsViewBaseline.1.png
  - apps/ios/BuyLedger/Core/Domain/LedgerOrder+Samples.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Badges/BLBadge.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderDetailCostBreakdownBaseline.1.png
  - apps/ios/BuyLedger/Features/Campaigns/CampaignEditFeature.swift
  - apps/ios/BuyLedger/Core/Persistence/ReconciliationStatusRecord.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/TextFields/BLSearchField.swift
  - apps/ios/BuyLedgerTests/DashboardStatsTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewMergeContextBaseline.2.png
  - apps/ios/BuyLedger/Core/Persistence/VerificationStatusPersistence.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoViewer.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignDetailView.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OptionPickerSheet.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Progress/BLProgressBar.swift
  - apps/ios/BuyLedger/Core/Persistence/VerificationStatusRecord.swift
  - apps/ios/BuyLedger/Resources/Localizable.xcstrings
  - apps/ios/BuyLedgerTests/OrderMergeTests.swift
  - apps/ios/BuyLedgerTests/OrderPersistenceTests.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFormatters.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignFormatters.swift
  - apps/ios/BuyLedgerTests/SnapshotTests.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsView.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignListView.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersView.swift
  - apps/ios/BuyLedger/Features/Orders/OrderEditView.swift
  - apps/ios/BuyLedger/Core/Persistence/OrderPersistence.swift
  - apps/ios/BuyLedgerTests/OrdersFeaturePerformanceTests.swift
  - apps/ios/BuyLedger/Features/Quote/QuoteView.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupKind.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsStorage.swift
  - apps/ios/CLAUDE.md
  - apps/ios/BuyLedger/Shared/Extensions/Locale+Extensions.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderDetailView.swift
  - apps/ios/BuyLedger/Features/Orders/OrderMergeFeature.swift
  - apps/ios/BuyLedgerTests/OrderEditFeatureTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewBaseline.1.png
  - apps/ios/BuyLedger/Features/FX/FxFeature.swift
  - apps/ios/BuyLedgerTests/SettingsFeatureTests.swift
  - apps/ios/BuyLedgerTests/CampaignEditFeatureTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/blBarChartThirtyDaysBaseline.2.png
  - apps/ios/BuyLedgerTests/OrderMergeFeatureTests.swift
  - apps/ios/BuyLedger/Features/Settings/AppLanguage.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderRowView.swift
  - apps/ios/BuyLedger/Core/Dependencies/VerificationStatusRepository.swift
  - apps/ios/README.md
  - apps/ios/BuyLedgerTests/CampaignFeatureTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewLongContentBaseline.2.png
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Lists/BLListRow.swift
  - apps/ios/BuyLedger/Features/AISummary/AISummaryView.swift
  - apps/ios/BuyLedgerTests/InsightsAttributionTests.swift
  - apps/ios/BuyLedger/Features/Orders/OrderEditFeature.swift
  - apps/ios/BuyLedger/Core/Persistence/OrderRecord.swift
  - apps/ios/BuyLedger/Features/Quote/QuoteFeature.swift
  - apps/ios/BuyLedgerTests/CustomersFeatureTests.swift
  - apps/ios/BuyLedger/Core/Persistence/ReconciliationStatusPersistence.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/dashboardViewBaseline.2.png
  - apps/ios/BuyLedger/Features/AISummary/AISummaryFeature.swift
-->

---
### Requirement: Locale-aware presentation follows App language

The App SHALL apply the selected language locale at the SwiftUI root and SHALL use that locale for locale-aware user-facing formatting. The App MUST NOT bypass the selected locale by reading the system preferred language in a presentation path.

#### Scenario: Locale changes with language

- **GIVEN** a screen shows localized static text and a locale-aware currency name or formatted value
- **WHEN** the user switches from Traditional Chinese to English
- **THEN** both the static text and locale-aware presentation update using the English locale


<!-- @trace
source: add-app-language-switching
updated: 2026-07-19
code:
  - apps/ios/BuyLedger/Features/More/MoreView.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/LedgerOrder.generated.swift
  - apps/ios/BuyLedger/Features/App/RootView.swift
  - apps/ios/BuyLedger/Core/Domain/OrderMerge.swift
  - apps/ios/BuyLedger/Features/Customers/CustomersView.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/SegmentedControls/BLSegmentedControl.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewBaseline.1.png
  - apps/ios/BuyLedger/Core/Dependencies/ReconciliationStatusRepository.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsStats.swift
  - apps/ios/BuyLedgerTests/CampaignIntegrationTests.swift
  - apps/ios/BuyLedger/Core/Dependencies/OrderRepository.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignEditView.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardView.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift
  - apps/ios/BuyLedger/Features/Orders/Components/PaymentMethodEditorSheet.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsFeature.swift
  - apps/ios/BuyLedger/Features/App/RootSidebarLayout.swift
  - apps/ios/BuyLedgerTests/LookupManagementFeatureTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/insightsViewBaseline.2.png
  - apps/ios/BuyLedger/Features/Settings/SettingsSnapshot.swift
  - apps/ios/BuyLedger/Features/App/RootFeature.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLDonutChart.swift
  - apps/ios/BuyLedgerTests/SchemaMigrationTests.swift
  - apps/ios/BuyLedgerTests/OrdersFeatureTests.swift
  - apps/ios/BuyLedgerTests/InsightsStatsTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderDetailCostBreakdownBaseline.2.png
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Status/BLStatusPill.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsView.swift
  - apps/ios/BuyLedger/Resources/InfoPlist.xcstrings
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFilterSheet.swift
  - apps/ios/BuyLedger/Features/FX/FxView.swift
  - apps/ios/BuyLedger/Core/Persistence/PersistenceContainer.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignFeature.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersFeature.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewLongContentBaseline.1.png
  - apps/ios/BuyLedgerTests/OrderCalculationTests.swift
  - apps/ios/BuyLedger.xcodeproj/project.pbxproj
  - apps/ios/BuyLedger/Core/Domain/CurrencyCode.swift
  - apps/ios/BuyLedger/Features/Orders/Components/LookupItemEditorSheet.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests.swift
  - shared/data-model/schema/LedgerOrder.yaml
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementView.swift
  - apps/ios/BuyLedgerTests/CampaignSummaryTests.swift
  - apps/ios/BuyLedger/Features/App/RootTabLayout.swift
  - apps/ios/BuyLedger/Core/Persistence/BuyLedgerSchema.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderMergeCandidateSheet.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/TextFields/BLAmountField.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewMergeContextBaseline.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewBaseline.2.png
  - apps/ios/BuyLedger/Features/Orders/OrdersCompactView.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewBaseline.2.png
  - apps/ios/BuyLedgerTests/LocalizationCatalogTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/insightsViewBaseline.1.png
  - apps/ios/BuyLedger/Core/Domain/LedgerOrder+Samples.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Badges/BLBadge.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderDetailCostBreakdownBaseline.1.png
  - apps/ios/BuyLedger/Features/Campaigns/CampaignEditFeature.swift
  - apps/ios/BuyLedger/Core/Persistence/ReconciliationStatusRecord.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/TextFields/BLSearchField.swift
  - apps/ios/BuyLedgerTests/DashboardStatsTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewMergeContextBaseline.2.png
  - apps/ios/BuyLedger/Core/Persistence/VerificationStatusPersistence.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoViewer.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignDetailView.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OptionPickerSheet.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Progress/BLProgressBar.swift
  - apps/ios/BuyLedger/Core/Persistence/VerificationStatusRecord.swift
  - apps/ios/BuyLedger/Resources/Localizable.xcstrings
  - apps/ios/BuyLedgerTests/OrderMergeTests.swift
  - apps/ios/BuyLedgerTests/OrderPersistenceTests.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFormatters.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignFormatters.swift
  - apps/ios/BuyLedgerTests/SnapshotTests.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsView.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignListView.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersView.swift
  - apps/ios/BuyLedger/Features/Orders/OrderEditView.swift
  - apps/ios/BuyLedger/Core/Persistence/OrderPersistence.swift
  - apps/ios/BuyLedgerTests/OrdersFeaturePerformanceTests.swift
  - apps/ios/BuyLedger/Features/Quote/QuoteView.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupKind.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsStorage.swift
  - apps/ios/CLAUDE.md
  - apps/ios/BuyLedger/Shared/Extensions/Locale+Extensions.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderDetailView.swift
  - apps/ios/BuyLedger/Features/Orders/OrderMergeFeature.swift
  - apps/ios/BuyLedgerTests/OrderEditFeatureTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewBaseline.1.png
  - apps/ios/BuyLedger/Features/FX/FxFeature.swift
  - apps/ios/BuyLedgerTests/SettingsFeatureTests.swift
  - apps/ios/BuyLedgerTests/CampaignEditFeatureTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/blBarChartThirtyDaysBaseline.2.png
  - apps/ios/BuyLedgerTests/OrderMergeFeatureTests.swift
  - apps/ios/BuyLedger/Features/Settings/AppLanguage.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderRowView.swift
  - apps/ios/BuyLedger/Core/Dependencies/VerificationStatusRepository.swift
  - apps/ios/README.md
  - apps/ios/BuyLedgerTests/CampaignFeatureTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewLongContentBaseline.2.png
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Lists/BLListRow.swift
  - apps/ios/BuyLedger/Features/AISummary/AISummaryView.swift
  - apps/ios/BuyLedgerTests/InsightsAttributionTests.swift
  - apps/ios/BuyLedger/Features/Orders/OrderEditFeature.swift
  - apps/ios/BuyLedger/Core/Persistence/OrderRecord.swift
  - apps/ios/BuyLedger/Features/Quote/QuoteFeature.swift
  - apps/ios/BuyLedgerTests/CustomersFeatureTests.swift
  - apps/ios/BuyLedger/Core/Persistence/ReconciliationStatusPersistence.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/dashboardViewBaseline.2.png
  - apps/ios/BuyLedger/Features/AISummary/AISummaryFeature.swift
-->

---
### Requirement: Device acceptance

The iOS App SHALL build, install, and launch on the user's connected iPhone 15 Plus through XcodeBuildMCP CLI.

#### Scenario: Build and run on iPhone 15 Plus

- **WHEN** the implementation is accepted
- **THEN** XcodeBuildMCP CLI reports a successful device build-and-run for the connected iPhone 15 Plus and the App is visible running on that device

<!-- @trace
source: add-app-language-switching
updated: 2026-07-19
code:
  - apps/ios/BuyLedger/Features/More/MoreView.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/LedgerOrder.generated.swift
  - apps/ios/BuyLedger/Features/App/RootView.swift
  - apps/ios/BuyLedger/Core/Domain/OrderMerge.swift
  - apps/ios/BuyLedger/Features/Customers/CustomersView.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/SegmentedControls/BLSegmentedControl.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewBaseline.1.png
  - apps/ios/BuyLedger/Core/Dependencies/ReconciliationStatusRepository.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsStats.swift
  - apps/ios/BuyLedgerTests/CampaignIntegrationTests.swift
  - apps/ios/BuyLedger/Core/Dependencies/OrderRepository.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignEditView.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardView.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift
  - apps/ios/BuyLedger/Features/Orders/Components/PaymentMethodEditorSheet.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsFeature.swift
  - apps/ios/BuyLedger/Features/App/RootSidebarLayout.swift
  - apps/ios/BuyLedgerTests/LookupManagementFeatureTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/insightsViewBaseline.2.png
  - apps/ios/BuyLedger/Features/Settings/SettingsSnapshot.swift
  - apps/ios/BuyLedger/Features/App/RootFeature.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLDonutChart.swift
  - apps/ios/BuyLedgerTests/SchemaMigrationTests.swift
  - apps/ios/BuyLedgerTests/OrdersFeatureTests.swift
  - apps/ios/BuyLedgerTests/InsightsStatsTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderDetailCostBreakdownBaseline.2.png
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Status/BLStatusPill.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsView.swift
  - apps/ios/BuyLedger/Resources/InfoPlist.xcstrings
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFilterSheet.swift
  - apps/ios/BuyLedger/Features/FX/FxView.swift
  - apps/ios/BuyLedger/Core/Persistence/PersistenceContainer.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignFeature.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersFeature.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewLongContentBaseline.1.png
  - apps/ios/BuyLedgerTests/OrderCalculationTests.swift
  - apps/ios/BuyLedger.xcodeproj/project.pbxproj
  - apps/ios/BuyLedger/Core/Domain/CurrencyCode.swift
  - apps/ios/BuyLedger/Features/Orders/Components/LookupItemEditorSheet.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests.swift
  - shared/data-model/schema/LedgerOrder.yaml
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementView.swift
  - apps/ios/BuyLedgerTests/CampaignSummaryTests.swift
  - apps/ios/BuyLedger/Features/App/RootTabLayout.swift
  - apps/ios/BuyLedger/Core/Persistence/BuyLedgerSchema.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderMergeCandidateSheet.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/TextFields/BLAmountField.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewMergeContextBaseline.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewBaseline.2.png
  - apps/ios/BuyLedger/Features/Orders/OrdersCompactView.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewBaseline.2.png
  - apps/ios/BuyLedgerTests/LocalizationCatalogTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/insightsViewBaseline.1.png
  - apps/ios/BuyLedger/Core/Domain/LedgerOrder+Samples.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Badges/BLBadge.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderDetailCostBreakdownBaseline.1.png
  - apps/ios/BuyLedger/Features/Campaigns/CampaignEditFeature.swift
  - apps/ios/BuyLedger/Core/Persistence/ReconciliationStatusRecord.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/TextFields/BLSearchField.swift
  - apps/ios/BuyLedgerTests/DashboardStatsTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewMergeContextBaseline.2.png
  - apps/ios/BuyLedger/Core/Persistence/VerificationStatusPersistence.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoViewer.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignDetailView.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OptionPickerSheet.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Progress/BLProgressBar.swift
  - apps/ios/BuyLedger/Core/Persistence/VerificationStatusRecord.swift
  - apps/ios/BuyLedger/Resources/Localizable.xcstrings
  - apps/ios/BuyLedgerTests/OrderMergeTests.swift
  - apps/ios/BuyLedgerTests/OrderPersistenceTests.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFormatters.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignFormatters.swift
  - apps/ios/BuyLedgerTests/SnapshotTests.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsView.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignListView.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersView.swift
  - apps/ios/BuyLedger/Features/Orders/OrderEditView.swift
  - apps/ios/BuyLedger/Core/Persistence/OrderPersistence.swift
  - apps/ios/BuyLedgerTests/OrdersFeaturePerformanceTests.swift
  - apps/ios/BuyLedger/Features/Quote/QuoteView.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupKind.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsStorage.swift
  - apps/ios/CLAUDE.md
  - apps/ios/BuyLedger/Shared/Extensions/Locale+Extensions.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderDetailView.swift
  - apps/ios/BuyLedger/Features/Orders/OrderMergeFeature.swift
  - apps/ios/BuyLedgerTests/OrderEditFeatureTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewBaseline.1.png
  - apps/ios/BuyLedger/Features/FX/FxFeature.swift
  - apps/ios/BuyLedgerTests/SettingsFeatureTests.swift
  - apps/ios/BuyLedgerTests/CampaignEditFeatureTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/blBarChartThirtyDaysBaseline.2.png
  - apps/ios/BuyLedgerTests/OrderMergeFeatureTests.swift
  - apps/ios/BuyLedger/Features/Settings/AppLanguage.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderRowView.swift
  - apps/ios/BuyLedger/Core/Dependencies/VerificationStatusRepository.swift
  - apps/ios/README.md
  - apps/ios/BuyLedgerTests/CampaignFeatureTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewLongContentBaseline.2.png
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Lists/BLListRow.swift
  - apps/ios/BuyLedger/Features/AISummary/AISummaryView.swift
  - apps/ios/BuyLedgerTests/InsightsAttributionTests.swift
  - apps/ios/BuyLedger/Features/Orders/OrderEditFeature.swift
  - apps/ios/BuyLedger/Core/Persistence/OrderRecord.swift
  - apps/ios/BuyLedger/Features/Quote/QuoteFeature.swift
  - apps/ios/BuyLedgerTests/CustomersFeatureTests.swift
  - apps/ios/BuyLedger/Core/Persistence/ReconciliationStatusPersistence.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/dashboardViewBaseline.2.png
  - apps/ios/BuyLedger/Features/AISummary/AISummaryFeature.swift
-->