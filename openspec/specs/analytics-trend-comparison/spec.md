# analytics-trend-comparison Specification

## Purpose

TBD - created by archiving change 'revenue-attribution-single-source'. Update Purpose after archive.

## Requirements

### Requirement: Trend comparison expresses improvement consistently

The Dashboard KPI deltas and the Insights trend card SHALL derive their percentage magnitude and direction from the same current-versus-previous-period comparison. When the previous period is non-zero, the percentage denominator SHALL be the absolute value of the previous period. This absolute denominator is observable in Dashboard KPI deltas because the signed Decimal delta is presented directly. In the Insights trend card, the displayed magnitude uses `abs(ratio)`, so changing only the denominator's sign does not change its rendered percentage. A higher current profit SHALL be presented as improvement and a lower current profit as deterioration, including when both values are losses. When the previous period is zero or has no orders, Dashboard KPI deltas and the Insights trend card SHALL continue to show no comparison.

#### Scenario: Loss turns into profit

- **WHEN** the previous period profit is -100 and the current period profit is 50
- **THEN** the trend card presents improvement as `↑ 150.0%`

#### Scenario: Loss narrows

- **WHEN** the previous period profit is -100 and the current period profit is -50
- **THEN** the trend card presents improvement as `↑ 50.0%`

#### Scenario: Loss grows

- **WHEN** the previous period profit is -100 and the current period profit is -200
- **THEN** the trend card presents deterioration as `↓ 100.0%`

#### Scenario: Dashboard profit delta keeps direction when previous profit is negative

- **WHEN** the previous period profit is -100 and the current period profit is -50
- **THEN** the dashboard profit delta is the signed Decimal `0.5`, indicating improvement because current profit is greater than or equal to previous profit

#### Scenario: No prior comparison

- **WHEN** the previous period has zero profit or no orders
- **THEN** Dashboard KPI deltas and the trend card present no comparison

<!-- @trace
source: revenue-attribution-single-source
updated: 2026-08-22
code:
  - apps/ios/BuyLedger/Core/Domain/Generated/OrderStatus.generated.swift
  - apps/ios/BuyLedger/Features/App/AppLockFeature.swift
  - apps/ios/BuyLedger/Features/AISummary/AISummaryFeature.swift
  - apps/ios/BuyLedgerTests/AccessibilityConventionScanTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Tags/BLTagPill.swift
  - apps/ios/BuyLedger/Features/Orders/OrderStatusFilter.swift
  - apps/ios/BuyLedger/Core/Dependencies/ReconciliationStatusRepository.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersView.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignDetailView.swift
  - apps/ios/BuyLedgerTests/OrdersBatchOperationsTests.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardView.swift
  - apps/ios/BuyLedgerUITests/Tests/Insights/InsightsTests.swift
  - apps/ios/BuyLedgerUITests/KeyboardDismissTests.swift
  - apps/ios/BuyLedger/Core/Sync/SyncMeta.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/quoteViewRateUnavailable.1.png
  - apps/ios/BuyLedger/Core/Networking/URLRequestBuilder.swift
  - apps/ios/BuyLedgerTests/AppConfigurationTests.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/FxRateSnapshot.generated.swift
  - apps/ios/BuyLedgerTests/PrivacyManifestTests.swift
  - apps/ios/BuyLedgerUITests/Screens/QuoteScreen.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsFeature.swift
  - shared/data-model/fixtures/expected/kotlin/SampleReceipt.kt
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementDestination.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderMergeCandidateSheet.swift
  - apps/ios/BuyLedgerTests/CurrencyMetadataCacheTests.swift
  - apps/ios/BuyLedger/Core/Persistence/OrderPersistence.swift
  - apps/ios/BuyLedger/Features/Quote/QuoteFeature.swift
  - apps/ios/BuyLedger/Shared/Media/PhotoDataProcessor.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/ViewModifiers/BLTypographyModifier.swift
  - apps/ios/BuyLedgerTests/BLFormattersTests.swift
  - apps/ios/BuyLedger/Features/AISummary/OllamaClient.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsSnapshot.swift
  - apps/ios/BuyLedgerUITests/Screens/AISummaryScreen.swift
  - apps/ios/BuyLedger/Features/App/RootTab.swift
  - apps/ios/BuyLedgerTests/AppScenePhaseCoordinatorTests.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersFilterOperations.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/LedgerCustomer.generated.swift
  - shared/data-model/fixtures/expected/typescript/SampleStatus.ts
  - apps/ios/BuyLedgerTests/OrderDraftTests.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/CurrencyCode.generated.swift
  - apps/ios/BuyLedger/Core/Domain/LedgerOrder+Samples.swift
  - apps/ios/BuyLedger/Core/Dependencies/TelemetryClient.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests.swift
  - apps/ios/BuyLedgerTests/PhotoDataProcessorTests.swift
  - apps/ios/BuyLedger/Core/Persistence/OrderSourceRecord.swift
  - apps/ios/BuyLedger/Core/Persistence/PersistenceStoreQuarantine.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestSeedData.swift
  - shared/data-model/fixtures/schema/sample-orders.yaml
  - apps/ios/BuyLedgerTests/OrdersFilterOperationsTests.swift
  - apps/ios/BuyLedgerTests/OrdersLoadStateTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Avatar/BLAvatar.swift
  - apps/ios/BuyLedger/Core/Dependencies/CampaignRepository.swift
  - apps/ios/BuyLedger/Features/AISummary/AISummaryView.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignFeature.swift
  - CLAUDE.md
  - apps/ios/BuyLedgerUITests/Screens/OrdersScreen.swift
  - apps/ios/BuyLedger/App/AppDelegate.swift
  - apps/ios/BuyLedger/Core/Testing/BLUITestConfiguration.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLBarChart.swift
  - apps/ios/BuyLedgerUITests/Screens/OrderEditScreen.swift
  - apps/ios/BuyLedger/Core/Dependencies/OrderSourceRepository.swift
  - apps/ios/BuyLedgerTests/LayerBoundaryTests.swift
  - apps/ios/BuyLedgerTests/TestDependencies.swift
  - apps/ios/BuyLedger/Core/Persistence/CategoryRecord.swift
  - shared/data-model/fixtures/expected/kotlin/SampleStatus.kt
  - apps/ios/BuyLedger/Features/Insights/InsightsFeature.swift
  - apps/ios/BuyLedger/Core/Dependencies/NameLookupOperations.swift
  - apps/ios/BuyLedgerTests/OrderMergeFeatureTests.swift
  - apps/ios/BuyLedgerUITests/Support/AppNavigator.swift
  - apps/ios/BuyLedgerUITests/Tests/Tools/QuoteTests.swift
  - apps/ios/BuyLedger.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
  - apps/ios/BuyLedgerTests/PersistenceFailureFeatureTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/States/BLLoadFailureView.swift
  - shared/data-model/fixtures/expected/typescript/SampleProfile.ts
  - apps/ios/BuyLedger/Core/Persistence/CurrencyMetadataRecord.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsStorage.swift
  - apps/ios/BuyLedgerUITests/Tests/Smoke/HarnessSelfCheckTests.swift
  - apps/ios/BuyLedgerTests/CampaignReminderFailureTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/quoteViewBaseline.1.png
  - apps/ios/BuyLedger/Features/AISummary/OllamaDTO.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Buttons/BLButtonStyle.swift
  - apps/ios/BuyLedgerUITests/Tests/Campaigns/CampaignListTests.swift
  - apps/ios/BuyLedger/Core/Networking/ExchangeRateClient.swift
  - apps/ios/BuyLedgerUITests/Tests/Smoke/LaunchSmokeTests.swift
  - shared/data-model/schema/PaymentReceiptStatus.yaml
  - apps/ios/BuyLedger/Core/Dependencies/CampaignReminderRepository.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsDateRange.swift
  - apps/ios/BuyLedger/Core/Persistence/BuyLedgerSchema.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewLongContentBaseline.1.png
  - apps/ios/BuyLedger/Core/Dependencies/OpenSettingsClient.swift
  - apps/ios/BuyLedger/Features/Orders/Components/MergePhotoPickerSheet.swift
  - apps/ios/BuyLedger/Core/Persistence/CampaignRecord.swift
  - apps/ios/BuyLedger/Features/Orders/Components/PaymentMethodEditorSheet.swift
  - apps/ios/BuyLedger/Features/App/RootFeature.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Cards/BLCard.swift
  - apps/ios/BuyLedger/Features/App/AppLockView.swift
  - shared/data-model/fixtures/expected/typescript/SampleGrade.ts
  - apps/ios/BuyLedgerUITests-Performance.xctestplan
  - shared/data-model/schema/Campaign.yaml
  - shared/data-model/schema/OrderStatus.yaml
  - apps/ios/BuyLedger.xcodeproj/xcshareddata/xcschemes/BuyLedger.xcscheme
  - shared/data-model/schema/LedgerOrder.yaml
  - apps/ios/BuyLedger/Features/Orders/OrdersFeature.swift
  - shared/data-model/schema/Money.yaml
  - apps/ios/README.md
  - apps/ios/BuyLedger/Resources/GoogleService-Info.example.plist
  - apps/ios/BuyLedger/Core/Persistence/PaymentMethodRecord.swift
  - apps/ios/BuyLedger/Core/Sync/SyncQueueItem.swift
  - apps/ios/BuyLedger/Features/Orders/OrderDatePeriod.swift
  - shared/data-model/generator/src/datamodel-gen.ts
  - apps/ios/BuyLedger/Core/Testing/BLUITestHarness.swift
  - apps/ios/BuyLedgerTests/ColorContrast.swift
  - shared/data-model/schema/PaymentMethodInfo.yaml
  - apps/ios/BuyLedgerTests/AISummaryFeatureTests.swift
  - apps/ios/BuyLedgerUITests/Support/Waiting.swift
  - shared/data-model/README.md
  - apps/ios/BuyLedger/Features/Settings/AppLanguage.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsView.swift
  - apps/ios/BuyLedger/Resources/Info.plist
  - apps/ios/BuyLedger/Features/FX/ExchangeRateDTO.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLHeatmapDepth.swift
  - apps/ios/BuyLedgerTests/TestSuiteIntegrityTests.swift
  - shared/data-model/fixtures/expected/swift/SampleStatus.generated.swift
  - apps/ios/BuyLedger/Features/App/RootSidebarLayout.swift
  - apps/ios/BuyLedger.xcodeproj/project.pbxproj
  - apps/ios/BuyLedger/Core/Persistence/CampaignReminderPersistence.swift
  - apps/ios/BuyLedgerTests/OrderCalculationTests.swift
  - apps/ios/BuyLedger/Features/Customers/CustomerRankBadgeStyle.swift
  - apps/ios/BuyLedgerUITests/Tests/Performance/LaunchPerformanceTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLFormatters.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignListView.swift
  - apps/ios/BuyLedgerTests/BiometricAuthClientTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrdersListTests.swift
  - apps/ios/BuyLedgerTests/OrdersSearchCancellationTests.swift
  - apps/ios/BuyLedgerUITests/Screens/CampaignDetailScreen.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersMergeFlowOperations.swift
  - shared/data-model/fixtures/expected/typescript/SamplePreference.ts
  - apps/ios/BuyLedgerUITests.xctestplan
  - apps/ios/BuyLedgerTests/CampaignPersistenceTests.swift
  - apps/ios/BuyLedger/Core/Persistence/NameLookupRecord.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsStats.swift
  - shared/data-model/schema/FxRateSnapshot.yaml
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderCreateTests.swift
  - apps/ios/BuyLedger/Core/Networking/APIError.swift
  - apps/ios/BuyLedgerUITests/Support/ValueParsing.swift
  - apps/ios/BuyLedgerTests/CampaignFeatureTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Badges/BLBadge.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Progress/BLProgressBar.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewBaseline.1.png
  - apps/ios/BuyLedger/App/Testing/BLUITestHarness.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestSeedProfile.swift
  - apps/ios/BuyLedger/Core/Persistence/NameLookupPersistence.swift
  - apps/ios/BuyLedger/Core/Persistence/ReconciliationStatusPersistence.swift
  - shared/data-model/fixtures/expected/typescript/SampleQuote.ts
  - shared/data-model/fixtures/expected/typescript/SampleSequence.ts
  - apps/ios/BuyLedgerTests/OllamaClientTests.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderDetailView.swift
  - shared/data-model/fixtures/expected/kotlin/SampleSequence.kt
  - apps/ios/BuyLedger/Features/Orders/Components/OrderRowView.swift
  - apps/ios/BuyLedger/Features/Customers/CustomersView.swift
  - apps/ios/BuyLedger/Core/Domain/FxRates.swift
  - apps/ios/BuyLedgerTests/InsightsAttributionTests.swift
  - apps/ios/BuyLedgerTests/OrderStatusTests.swift
  - apps/ios/BuyLedgerUITests/Screens/AppLockScreen.swift
  - apps/ios/BuyLedger/Core/Networking/AppConfiguration.swift
  - apps/ios/BuyLedger/Features/FX/FxView.swift
  - apps/ios/CLAUDE.md
  - apps/ios/BuyLedgerUITests/PhotoViewerPagingTests.swift
  - apps/ios/BuyLedger/Core/Dependencies/BiometricAuthClient.swift
  - apps/ios/BuyLedger/Core/Persistence/PersistenceError.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestConfiguration.swift
  - apps/ios/BuyLedger/Core/Dependencies/OrderRepository.swift
  - apps/ios/BuyLedger/Core/Persistence/PaymentMethodPersistence.swift
  - apps/ios/BuyLedgerTests/APIErrorMappingTests.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupCatalog.swift
  - apps/ios/BuyLedgerTests/SettingsFeatureTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLBarChartValue.swift
  - apps/ios/BuyLedger/Features/App/RootView.swift
  - apps/ios/BuyLedger/Core/Persistence/CurrencyMetadataPersistence.swift
  - apps/ios/BuyLedger/Features/App/PersistenceFailureFeature.swift
  - apps/ios/BuyLedger/Features/Orders/OrderMergeFeature.swift
  - apps/ios/BuyLedger/Core/Domain/Campaign+Samples.swift
  - apps/ios/BuyLedger/Resources/PrivacyInfo.xcprivacy
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoThumbnail.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Chips/BLFilterChip.swift
  - apps/ios/BuyLedgerUITests/Support/TextInput.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewLongIdentifierBaseline.1.png
  - shared/data-model/fixtures/expected/kotlin/SampleQuote.kt
  - shared/data-model/fixtures/schema/sample-enums.yaml
  - apps/ios/BuyLedgerUITests/Screens/CustomersScreen.swift
  - apps/ios/BuyLedgerTests/OrdersFeatureTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/ViewModifiers/BLCardShadow.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/PaymentMethodInfo.generated.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/CustomerTier.generated.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupNameEditorSheet.swift
  - .github/workflows/ci.yml
  - apps/ios/BuyLedger/Features/Orders/Components/OrdersToolbarContent.swift
  - apps/ios/BuyLedger/Shared/Extensions/Bundle+Extensions.swift
  - apps/ios/BuyLedgerUITests/Support/AlertInteraction.swift
  - apps/ios/BuyLedger/Features/App/PersistenceFailureView.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersCompactView.swift
  - apps/ios/BuyLedgerUITests/Support/BLUITestCase.swift
  - apps/ios/BuyLedgerUITests/Support/Diagnostics.swift
  - apps/ios/BuyLedger/Core/Persistence/OrderRecord.swift
  - apps/ios/BuyLedger/Features/FX/FxRates.swift
  - apps/ios/BuyLedger/Resources/Localizable.xcstrings
  - apps/ios/BuyLedgerTests/ProjectionWriteBoundaryTests.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersFeature+StateQuery.swift
  - apps/ios/BuyLedgerUITests/Screens/PhotoViewerScreen.swift
  - apps/ios/BuyLedger.xctestplan
  - apps/ios/BuyLedger/Features/Orders/Components/OrderSelectableRow.swift
  - shared/data-model/fixtures/expected/swift/SampleGrade.generated.swift
  - apps/ios/BuyLedger/Core/Persistence/OrderSourcePersistence.swift
  - apps/ios/BuyLedger/Features/FX/ExchangeRateClient.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/States/DelayedProgressView.swift
  - apps/ios/BuyLedger/Core/Dependencies/PhotoClient.swift
  - apps/ios/BuyLedgerAccessibilityIDs/BLAccessibilityID.swift
  - apps/ios/BuyLedger/Core/Dependencies/CalendarReminderClient.swift
  - apps/ios/BuyLedgerUITests/Support/SheetInteraction.swift
  - apps/ios/BuyLedgerTests/OrderEditFocusTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/persistenceFailureViewBaseline.1.png
  - apps/ios/BuyLedgerUITests/Support/MenuInteraction.swift
  - apps/ios/BuyLedgerTests/BLAccessibilityIDTests.swift
  - apps/ios/BuyLedger/Shared/Extensions/Color+Extensions.swift
  - apps/ios/BuyLedgerTests/PersistenceErrorContractTests.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignFormatters.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupKind.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoViewer.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardStats.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLDonutChart.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OptionPickerSheet.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFormatters.swift
  - apps/ios/BuyLedgerTests/InsightsStatsTests.swift
  - apps/ios/BuyLedger/Features/Orders/OrderDraft.swift
  - apps/ios/BuyLedgerTests/DesignSystemSourceScanTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewMergeContextBaseline.1.png
  - apps/ios/BuyLedger/Core/Diagnostics/CrashDiagnosticsClient.swift
  - apps/ios/BuyLedger/Core/Networking/ExchangeRateDTO.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/CampaignStatus.generated.swift
  - apps/ios/BuyLedger/Features/More/MoreView.swift
  - apps/ios/BuyLedgerTests/DashboardFeatureTests.swift
  - apps/ios/BuyLedgerTests/ContrastComplianceTests.swift
  - apps/ios/BuyLedgerTests/NameLookupPersistenceTests.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersBatchOperations.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLDonutSegment.swift
  - apps/ios/BuyLedgerTests/CampaignIntegrationTests.swift
  - shared/data-model/schema/CurrencyCode.yaml
  - apps/ios/BuyLedger/Core/Domain/LedgerOrder.swift
  - apps/ios/BuyLedger/Features/Orders/OrderEditView.swift
  - apps/ios/BuyLedger/Core/Domain/OrderSummary.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift
  - apps/ios/BuyLedger/Resources/InfoPlist.xcstrings
  - apps/ios/BuyLedger/Core/Dependencies/PaymentMethodRepository.swift
  - apps/ios/BuyLedgerUITests/Screens/CampaignsScreen.swift
  - apps/ios/BuyLedgerUITests/Screens/OptionPickerScreen.swift
  - apps/ios/BuyLedger/Features/Orders/LedgerOrder+OrderMutation.swift
  - apps/ios/BuyLedger/Features/Quote/QuoteView.swift
  - apps/ios/BuyLedger/App/AppLaunchConfigurator.swift
  - apps/ios/BuyLedger/Core/Persistence/PersistenceContainer.swift
  - apps/ios/BuyLedgerUITests/Screens/OrderDetailScreen.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/dashboardViewBaseline.1.png
  - apps/ios/BuyLedgerTests/LookupCatalogTests.swift
  - apps/ios/BuyLedger/Features/Settings/AISummaryModelCatalog.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersRegularViewMultiSelectBaseline.1.png
  - apps/ios/BuyLedger/Core/Networking/HTTPMethod.swift
  - apps/ios/BuyLedgerTests/AppLockFeatureTests.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/Campaign.generated.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewBaseline.1.png
  - apps/ios/BuyLedger/Features/Customers/CustomersFeature.swift
  - apps/ios/BuyLedgerTests/BLUITestConfigurationTests.swift
  - apps/ios/BuyLedgerUITests/Screens/MergeFlowScreen.swift
  - shared/data-model/fixtures/expected/swift/SamplePreference.generated.swift
  - apps/ios/BuyLedgerUITests/Tests/Tools/FxTests.swift
  - apps/ios/BuyLedgerTests/LocalizationCatalogTests.swift
  - apps/ios/BuyLedger/Shared/Localization/AppLanguage.swift
  - shared/data-model/schema/CustomerTier.yaml
  - apps/ios/BuyLedger/Core/Domain/Campaign.swift
  - apps/ios/BuyLedgerTests/LookupManagementFeatureTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Campaigns/CampaignCrudTests.swift
  - shared/data-model/fixtures/expected/swift/SampleReceipt.generated.swift
  - apps/ios/BuyLedgerTests/ExchangeRateClientTests.swift
  - README.md
  - shared/data-model/fixtures/expected/kotlin/SampleGrade.kt
  - apps/ios/BuyLedgerTests/OrderEditFeatureTests.swift
  - apps/ios/BuyLedgerTests/InsightsFeatureTests.swift
  - apps/ios/BuyLedger/Core/Domain/CurrencyCode.swift
  - apps/ios/BuyLedger/Core/Persistence/PersistenceStoreQuarantineClient.swift
  - apps/ios/BuyLedgerTests/CalendarReminderTests.swift
  - apps/ios/BuyLedger/Core/Persistence/CampaignReminderRecord.swift
  - apps/ios/BuyLedgerTests/PaymentMethodPersistenceTests.swift
  - shared/data-model/schema/LedgerOrderItem.yaml
  - apps/ios/BuyLedger/Core/Testing/BLUITestDependencyOverrides.swift
  - apps/ios/BuyLedger/Features/FX/FxFeature.swift
  - shared/data-model/fixtures/expected/kotlin/SampleProfile.kt
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Pickers/OptionPickerSheet.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/PaymentReceiptStatus.generated.swift
  - apps/ios/BuyLedger/Core/Domain/FxRateSnapshot.swift
  - apps/ios/BuyLedgerUITests/Support/Scrolling.swift
  - shared/data-model/fixtures/expected/swift/SampleQuote.generated.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignEditFeature.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/Money.generated.swift
  - AGENTS.md
  - apps/ios/BuyLedgerTests/NumericInputGroupingScanTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewMultiSelectBaseline.1.png
  - apps/ios/BuyLedger/Shared/Extensions/Image+Extensions.swift
  - apps/ios/BuyLedger/Core/Dependencies/CategoryRepository.swift
  - apps/ios/BuyLedger/Features/Orders/OrderDetailPath.swift
  - apps/ios/BuyLedger/Features/App/RootTabLayout.swift
  - apps/ios/BuyLedger/Core/Persistence/CategoryPersistence.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/LedgerOrderItem.generated.swift
  - apps/ios/BuyLedgerTests/OrderPersistenceTests.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestDependencyOverrides.swift
  - apps/ios/BuyLedger/Core/Persistence/CampaignPersistence.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsView.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignEditView.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderMergeTests.swift
  - shared/data-model/fixtures/expected/swift/SampleProfile.generated.swift
  - shared/data-model/fixtures/expected/kotlin/SamplePreference.kt
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLTone.swift
  - apps/ios/BuyLedger/Core/Domain/OrderMerge.swift
  - apps/ios/BuyLedgerTests/OrdersFeaturePerformanceTests.swift
  - apps/ios/BuyLedger/Core/Persistence/ReconciliationStatusRecord.swift
  - apps/ios/BuyLedgerUITests/Screens/CampaignEditScreen.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/AISummaryTests.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFilterSheet.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLPalette.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLStatusHue.swift
  - apps/ios/BuyLedgerUITests/Screens/DashboardScreen.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Status/BLStatusPill.swift
  - apps/ios/BuyLedger/Core/Dependencies/CurrencyMetadataRepository.swift
  - apps/ios/BuyLedgerUITests/Screens/SettingsScreen.swift
  - apps/ios/BuyLedgerTests/DashboardStatsTests.swift
  - apps/ios/BuyLedger/App/BuyLedgerApp.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLSparkline.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLTypography.swift
  - apps/ios/BuyLedger/Features/App/SidebarBadgeCounts.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/ViewModifiers/BLHeroCardBackground.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Forms/PaymentMethodEditorSheet.swift
  - apps/ios/BuyLedgerTests/OrderMergeTests.swift
  - apps/ios/BuyLedgerUITests/Screens/InsightsScreen.swift
  - apps/ios/BuyLedger/Core/Testing/BLUITestSeedData.swift
  - apps/ios/BuyLedgerUITests/Tests/Customers/CustomersTests.swift
  - apps/ios/BuyLedgerUITests/Screens/RootNavigationScreen.swift
  - apps/ios/BuyLedgerTests/CustomersFeatureTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLMetrics.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/LedgerOrder.generated.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignSummary.swift
  - apps/ios/BuyLedgerTests/BLPhotoViewerTests.swift
  - apps/ios/BuyLedgerTests/SnapshotTests.swift
  - apps/ios/BuyLedgerUITests/Screens/FxScreen.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderDetailTests.swift
  - shared/data-model/schema/CampaignStatus.yaml
  - apps/ios/BuyLedger/Core/Networking/HTTPClient.swift
  - apps/ios/BuyLedgerTests/SchemaMigrationTests.swift
  - apps/ios/BuyLedger/Core/Testing/BLUITestSeedProfile.swift
  - apps/ios/BuyLedgerUITests/Support/Assertions.swift
  - apps/ios/BuyLedgerTests/FxFeatureTests.swift
  - apps/ios/BuyLedger/Core/Domain/OrderStatus.swift
  - apps/ios/BuyLedgerUITests/Screens/Screen.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementView.swift
  - shared/data-model/schema/LedgerCustomer.yaml
  - apps/ios/BuyLedger/Shared/Extensions/Decimal+Extensions.swift
  - apps/ios/BuyLedgerTests/HTTPClientTests.swift
  - apps/ios/BuyLedgerTests/CampaignEditFeatureTests.swift
  - apps/ios/BuyLedgerTests/ColorContrastTests.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardFeature.swift
  - shared/data-model/fixtures/schema/sample-trait-matrix.yaml
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderEditDirtyTests.swift
  - apps/ios/BuyLedgerUITests/Support/LaunchOptions.swift
  - apps/ios/BuyLedgerTests/CampaignSummaryTests.swift
  - shared/data-model/fixtures/expected/swift/SampleSequence.generated.swift
  - apps/ios/BuyLedger/Features/Orders/OrderEditFeature.swift
  - apps/ios/BuyLedgerTests/QuoteFeatureTests.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderStatus+Presentation.swift
  - apps/ios/BuyLedger/Features/App/AppScenePhaseCoordinator.swift
  - apps/ios/BuyLedger/Core/Domain/LedgerOrderItem.swift
  - apps/ios/BuyLedgerUITests/Tests/Campaigns/CampaignDetailTests.swift
  - shared/data-model/fixtures/expected/typescript/SampleReceipt.ts
  - apps/ios/BuyLedgerTests/PersistenceRecoveryTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Smoke/AppLockTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/States/BLDelayedProgressView.swift
tests:
  - shared/data-model/generator/test/datamodel-gen.test.ts
-->

---
### Requirement: Overview and insights figures follow a recorded current date

The overview's month figures (revenue, cost, profit, margin, order count, goal progress, the twelve-month profit trend and their month-over-month deltas), the overview's date subtitle (formatted with the recorded calendar and its time zone), and the insights trend bars, period comparison and order heatmap SHALL be computed against a current date and calendar recorded in the overview feature's state and the insights feature's state respectively. Each feature's reducer SHALL record the date and calendar from the injected date and calendar dependencies. The overview and insights views SHALL NOT read the current date, the calendar, or the time zone themselves, and no production source SHALL read the device's current calendar.

The recorded date SHALL be refreshed each time the screen's appearance task runs, each time the user retries after a load failure, each time the app returns to the foreground, and each time the system reports a significant time change, such as passing midnight while the app stays in the foreground. Each of these events SHALL replace the recorded date even when one has already been recorded. Between these events the recorded date SHALL NOT change. Whenever the orders, the campaigns, the monthly goal, or the selected insights range change, the figures SHALL be recomputed immediately against the recorded date, without waiting for one of these events. A retry SHALL record the new date before it requests the orders again.

A load failure SHALL be shown as the failure view with its retry button whether or not a date has been recorded. Otherwise, while no date has been recorded, each screen SHALL show its loading placeholder. It SHALL NOT show the onboarding, the empty state, or figures computed from any other date.

The heatmap's weekday labels SHALL be taken from the recorded calendar localized to the app language, ordered from Monday to Sunday.

#### Scenario: Overview month figures follow the recorded date

- **WHEN** the overview feature has recorded a date
- **THEN** its month figures count only the orders inside the recorded date's month, and the previous-month comparison uses the month before it

##### Example: one order in each month

- **GIVEN** a recorded date of 2026-05-12 10:00 in a calendar fixed to UTC, and two revenue-attributed orders: one on 2026-05-03 with revenue 1000, one on 2026-04-20 with revenue 800
- **WHEN** the overview computes its figures
- **THEN** this month's revenue is 1000, this month's order count is 1, and the revenue delta is the Decimal 0.25

#### Scenario: Figures follow data changes without changing the recorded date

- **WHEN** the orders, the campaigns, the monthly goal, or the insights range change while a date is recorded
- **THEN** the figures are recomputed against the same recorded date

##### Example: a new order in the current month

- **GIVEN** a recorded date of 2026-05-12 10:00 in a calendar fixed to UTC and one revenue-attributed order on 2026-05-03 with revenue 1000
- **WHEN** an order on 2026-05-10 with revenue 500 is added to the overview's orders
- **THEN** this month's revenue is 1500 and the recorded date is still 2026-05-12 10:00

#### Scenario: Figures move to the new month when the app returns to the foreground

- **WHEN** the overview has recorded a date, the app moves to the background, the month changes, and the app returns to the foreground
- **THEN** the previously recorded date is replaced with the current date when the app becomes active, without the overview's appearance task running again

##### Example: returning after the month ends

- **GIVEN** a recorded date of 2026-05-31 23:50 in a calendar fixed to UTC, and one revenue-attributed order on 2026-05-31 with revenue 1000
- **WHEN** the app goes to the background and returns to the foreground at 2026-06-01 00:30
- **THEN** this month's revenue is 0 and this month's order count is 0, and the 2026-05-31 order counts toward the previous month

#### Scenario: Insights follow a significant time change while on screen

- **WHEN** the insights screen stays on screen in the foreground and the system reports a significant time change
- **THEN** the recorded date is replaced with the current date without the insights appearance task running again

##### Example: midnight passes on the thirty-day range

- **GIVEN** the thirty-day range, a recorded date of 2026-05-12 23:50 in a calendar fixed to UTC
- **WHEN** the system reports a significant time change at 2026-05-13 00:00
- **THEN** the last trend bar is labelled "05/13" instead of "05/12"

#### Scenario: A retry records the date before reloading

- **WHEN** the overview or the insights screen shows a load failure and the user taps retry
- **THEN** the feature records the current date and then asks the root feature to load the orders again

##### Example: retrying the next morning

- **GIVEN** the overview recorded 2026-05-12 10:00 in a calendar fixed to UTC and then showed a load failure
- **WHEN** the user taps retry at 2026-05-13 09:00
- **THEN** the recorded date becomes 2026-05-13 09:00 before the refresh request is sent, and the month figures use May 2026

#### Scenario: No figures are shown before a date is recorded

- **WHEN** the orders have finished loading but the overview or the insights feature has not recorded a date
- **THEN** the screen shows its loading placeholder instead of the onboarding, the empty state, or any figure, while a load failure is still shown as the failure view

##### Example: loaded orders without a recorded date

| Load state | Orders | Recorded date | Overview shows | Insights shows |
| ---------- | ------ | ------------- | -------------- | -------------- |
| failed | 0 | none | failure view with retry | failure view with retry |
| loading | 0 | 2026-05-12 10:00 | loading placeholder | loading placeholder |
| loaded | 3 | none | loading placeholder | loading placeholder |
| loaded | 0 | none | loading placeholder | loading placeholder |
| loaded | 0 | 2026-05-12 10:00 | onboarding | empty state |
| loaded | 3 | 2026-05-12 10:00 | overview figures | analytics |

#### Scenario: Heatmap weekday labels follow the app language

- **WHEN** the insights heatmap renders its weekday labels
- **THEN** the labels come from the recorded calendar localized to the app language, starting on Monday

##### Example: labels per app language

| App language | Weekday labels from Monday to Sunday |
| ------------ | ------------------------------------ |
| Traditional Chinese | 一, 二, 三, 四, 五, 六, 日 |
| English | M, T, W, T, F, S, S |

#### Scenario: Views do not read the current date

- **WHEN** the production sources are scanned
- **THEN** no view type declares an injected dependency, and no source reads the device's current calendar

<!-- @trace
source: palette-analytics-style-compliance
updated: 2026-10-17
code:
  - apps/ios/BuyLedgerTests/CustomersFeatureTests.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFilterCategorySection.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsDateRange.swift
  - apps/ios/BuyLedgerTests/InsightsStatsTests+Fixtures.swift
  - apps/ios/BuyLedgerTests/DependencyConventionScanTests+Scanner.swift
  - apps/ios/BuyLedgerTests/DashboardStatsTests+Progress.swift
  - apps/ios/BuyLedgerTests/OrderPercentConversionTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrderMerge/orderMergeCandidateSheet_有可合併訂單_顯示候選清單.1.png
  - apps/ios/BuyLedger/Features/Insights/InsightsCostSegment.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderDetailCardlessView.swift
  - apps/ios/BuyLedgerTests/InsightsFeatureTests+ScreenState.swift
  - apps/ios/BuyLedgerTests/CampaignFormattersTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Customers/customersView_一般客戶資料_顯示名次徽章與排行卡.1.png
  - apps/ios/BuyLedger/Features/Customers/CustomerFormatters.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Customers/customersView_無客戶資料_顯示空狀態.1.png
  - apps/ios/BuyLedgerTests/InsightsFeatureTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLHitTarget.swift
  - apps/ios/BuyLedgerTests/SnapshotTests+Customers.swift
  - apps/ios/BuyLedger/Features/App/PersistenceFailureView.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardKPITile.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardOngoingCampaignsSection.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLTrend.swift
  - apps/ios/BuyLedger/Features/Quote/Components/QuoteInputsCard.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Insights/insightsView_已載入無訂單_顯示空狀態.1.png
  - apps/ios/BuyLedgerTests/DashboardStatsTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+More/settingsView_開啟AI摘要與生物辨識_顯示對應列.1.png
  - apps/ios/BuyLedger/Features/Orders/OrderPercentConversion.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardRecentOrdersSection.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrdersToolbarContent.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsHeatmapCard.swift
  - apps/ios/BuyLedgerTests/ColorContrast.swift
  - apps/ios/BuyLedgerTests/SnapshotTests+Dashboard.swift
  - apps/ios/BuyLedgerTests/InsightsFeatureTests+DateContext.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLDonutChart.swift
  - apps/ios/BuyLedgerTests/DependencyConventionScanScenario+ViewCases.swift
  - apps/ios/BuyLedgerTests/DesignSystemSourceScanTests.swift
  - apps/ios/BuyLedgerTests/FxFormattersTests.swift
  - apps/ios/BuyLedger/Features/Orders/Components/MergePhotoTile.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLMetrics.swift
  - apps/ios/BuyLedgerTests/InsightsFormattersTests.swift
  - apps/ios/BuyLedgerTests/DependencyConventionScanTests+Rules.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsFormatters.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/ViewModifiers/BLHeroCardBackground.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrderMerge/mergePhotoPickerSheet_七張照片只選部分_顯示未選取照片.1.png
  - apps/ios/BuyLedger/Features/FX/FxFormatters.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Insights/insightsView_載入中_顯示載入骨架.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Dashboard/dashboardView_載入中_顯示載入骨架.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrderMerge/mergePhotoPickerSheet_七張照片選滿上限_顯示已選與未選照片.1.png
  - apps/ios/BuyLedgerTests/DesignSystemSourceScanTests+Scanner.swift
  - apps/ios/BuyLedger/Features/Lookups/Components/LookupItemList.swift
  - apps/ios/BuyLedgerTests/DashboardFeatureTests+DateContext.swift
  - apps/ios/BuyLedger/Features/Customers/CustomersView.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderDetailNotesView.swift
  - apps/ios/BuyLedgerTests/ContrastComplianceTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/Color+Semantic.swift
  - apps/ios/BuyLedgerTests/DependencyConventionScanTests.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsFeature.swift
  - apps/ios/BuyLedger/Features/FX/FxView.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignFormatters.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsDateContext.swift
  - apps/ios/BuyLedger/Features/Quote/QuoteFormatters.swift
  - apps/ios/BuyLedger/Features/Customers/CustomerRankBadgeStyle.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoThumbnail.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignEditView.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderEditPaymentSection.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Tags/BLTagPill.swift
  - apps/ios/BuyLedger/Features/App/RootFeature.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+More/moreView_預設清單_顯示各入口.1.png
  - apps/ios/BuyLedgerTests/DesignSystemSourceScanTests+ScaledMetric.swift
  - apps/ios/BuyLedgerTests/DashboardFormattersTests.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardView.swift
  - apps/ios/BuyLedgerTests/CustomerFormattersTests.swift
  - apps/ios/BuyLedgerTests/CampaignListFeatureTests+DateContext.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardFormatters.swift
  - apps/ios/BuyLedgerTests/DashboardFeatureTests.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+DeepLinks.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupNameEditorSheet.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderEditFeesSection.swift
  - apps/ios/BuyLedgerTests/SnapshotTests+CampaignDetail.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+More/appLockView_生物辨識解鎖_顯示解鎖鈕.1.png
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLRadius.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLListMetrics.swift
  - apps/ios/BuyLedger/Features/Customers/CustomersFeature.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Buttons/BLButtonStyle.swift
  - apps/ios/BuyLedgerTests/FxFeatureTests+CurrencyCodes.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardStats.swift
  - apps/ios/BuyLedger/Features/Quote/Components/QuoteStatusBanner.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFilterPaymentMethodSection.swift
  - apps/ios/BuyLedgerTests/DependencyConventionScanScenario.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderDetailSummaryView.swift
  - apps/ios/BuyLedgerTests/CampaignListFeatureTests+VisibleSections.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoViewer.swift
  - apps/ios/BuyLedger/Resources/Localizable.xcstrings
  - apps/ios/BuyLedger/Features/AISummary/AISummaryView.swift
  - apps/ios/BuyLedger/Features/FX/FxFeature.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrderMerge/orderMergeCandidateSheet_無可合併訂單_顯示空狀態.1.png
  - apps/ios/BuyLedger/Features/FX/Components/FxRatesList.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderEditPercentField.swift
  - apps/ios/BuyLedger/Features/Campaigns/Components/CampaignSectionList.swift
  - apps/ios/BuyLedgerTests/InsightsAttributionTests.swift
  - apps/ios/BuyLedger/Features/Customers/Components/CustomerListRow.swift
  - apps/ios/BuyLedgerTests/BLTrendTests.swift
  - apps/ios/BuyLedgerTests/DependencyConventionScanTests+ViewRules.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementView.swift
  - apps/ios/BuyLedger/Features/Orders/Components/MergePhotoPickerSheet.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsCostStructureCard.swift
  - apps/ios/BuyLedger/Features/Orders/OrderEditPhotosSection.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderDetailContentView.swift
  - apps/ios/BuyLedgerTests/InsightsHeatmapTests.swift
  - apps/ios/BuyLedger/Features/Campaigns/Components/CampaignDetailSettlementSection.swift
  - apps/ios/BuyLedgerTests/DashboardStatsTests+Fixtures.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignEditFeature.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsCategoryCard.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Shared/paymentMethodEditorSheet_編輯既有付款方式_顯示三種旗標.1.png
  - apps/ios/BuyLedger/Features/Quote/QuoteRateFeature.swift
  - apps/ios/BuyLedgerTests/DependencyConventionScanTests+TestValueRules.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderRowView.swift
  - apps/ios/BuyLedgerTests/SnapshotTests+OrderMerge.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardSummarySection.swift
  - apps/ios/BuyLedger/Features/App/AppLockView.swift
  - apps/ios/BuyLedgerTests/CampaignFeatureTests+ReminderIntegration.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Progress/BLProgressView.swift
  - apps/ios/BuyLedger.xcodeproj/project.pbxproj
  - apps/ios/BuyLedgerTests/RootFeatureTests+Foreground.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardFeature.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsCampaignProfitCard.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsHeatmap.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsTrendBucket.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderEditSelectionRow.swift
  - apps/ios/BuyLedgerTests/DesignSystemSourceScanTests+Patterns.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+Fixtures.swift
  - apps/ios/BuyLedger/Features/Campaigns/Components/CampaignRow.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardDateContext.swift
  - apps/ios/BuyLedgerTests/CampaignFeatureTests+ReminderRename.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsView.swift
  - apps/ios/BuyLedgerTests/CampaignListFeatureTests+RowSummaries.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardHeroCard.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderDetailSourceView.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLBarChart.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Shared/aiSummaryView_總結完成_顯示摘要內容.1.png
  - apps/ios/BuyLedgerTests/DesignSystemSourceScanTests+ScaledMetricScanner.swift
  - apps/ios/BuyLedgerTests/SnapshotTests+Insights.swift
  - apps/ios/BuyLedgerTests/SnapshotTests+Shared.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsCategory.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderSelectableRow.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersCompactView.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderDetailItemsView.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignListFeature.swift
  - apps/ios/BuyLedger/Features/Quote/QuoteView.swift
  - apps/ios/BuyLedger/Features/Lookups/Components/LookupItemRow.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+More/appLockView_解鎖失敗_顯示失敗訊息與重試鈕.1.png
  - apps/ios/BuyLedger/Features/Orders/OrdersRegularDetailColumn.swift
  - apps/ios/BuyLedger/Features/Customers/CustomerRank.swift
  - apps/ios/BuyLedger/Features/FX/Components/FxStatusBanner.swift
  - apps/ios/BuyLedger/Features/Campaigns/Components/CampaignDetailDistributionSection.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderEditItemsSection.swift
  - apps/ios/BuyLedger/Shared/Extensions/Color+Extensions.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLSpacing.swift
  - apps/ios/BuyLedger/Features/Campaigns/Components/CampaignDetailInfoSection.swift
  - apps/ios/BuyLedgerTests/DashboardFormattersTests+Summary.swift
  - apps/ios/BuyLedgerTests/AISummaryFeatureTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Shared/paymentMethodEditorSheet_新增付款方式_顯示空白表單.1.png
  - apps/ios/CLAUDE.md
  - apps/ios/BuyLedgerTests/RootFeatureTests+LoadRequests.swift
  - apps/ios/BuyLedgerTests/CampaignEditFeatureTests.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsStats.swift
  - apps/ios/BuyLedgerTests/CampaignFeatureTests+FailureTimingFollowUp.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersRegularListColumn.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderEditCostSection.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsStats+Trend.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFilterDateSection.swift
  - apps/ios/BuyLedgerTests/CampaignFeatureTests+NameConflict.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersView.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLPalette.swift
  - apps/ios/BuyLedger/Features/Customers/Components/CustomerTopCard.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderDetailCostView.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+More/settingsView_預設偏好_顯示版本與偏好列.1.png
  - apps/ios/BuyLedgerTests/QuoteFormattersTests.swift
  - apps/ios/BuyLedgerTests/InsightsStatsTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Insights/insightsView_帶開團資料_顯示每團毛利排行卡.1.png
  - apps/ios/BuyLedger/Features/Dashboard/DashboardKPITiles.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignListView.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderEditBasicSection.swift
  - apps/ios/BuyLedgerTests/DashboardStatsTests+Comparison.swift
  - apps/ios/BuyLedger/Features/App/RootSidebarLayout.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Forms/PaymentMethodEditorSheet.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Shared/aiSummaryView_總結失敗_顯示重試鈕.1.png
  - apps/ios/BuyLedger/Features/Insights/CampaignProfitRank.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLSparkline.swift
  - apps/ios/BuyLedger/Features/Quote/Components/QuoteBreakdownCard.swift
  - apps/ios/BuyLedgerTests/InsightsStatsTests+Breakdown.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Dashboard/dashboardView_已載入無訂單_顯示首次使用畫面.1.png
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Progress/BLProgressViewStyle.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrdersCompactListView.swift
  - apps/ios/BuyLedger/Features/More/MoreView.swift
  - apps/ios/BuyLedger/Features/AISummary/AISummaryFeature.swift
  - apps/ios/BuyLedgerTests/CampaignEditFeatureTests+NavigationTitle.swift
  - apps/ios/BuyLedgerTests/SnapshotTests+More.swift
  - apps/ios/BuyLedgerTests/DashboardFeatureTests+ScreenState.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsTrendCard.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsView.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Cards/BLCard.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderMergeCandidateSheet.swift
  - apps/ios/BuyLedgerTests/QuoteFeatureTests+CurrencyCodes.swift
  - apps/ios/BuyLedgerTests/CampaignFeatureTests+Editing.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Chips/BLFilterChip.swift
  - apps/ios/BuyLedgerTests/ColorContrastTests.swift
-->