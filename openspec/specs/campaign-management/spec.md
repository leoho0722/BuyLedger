# campaign-management Specification

## Purpose

TBD - created by archiving change 'add-campaign-management'. Update Purpose after archive.

## Requirements

### Requirement: Campaign entity with two-state lifecycle

The system SHALL provide a Campaign entity with a name, an open date, an optional close date, a lifecycle status, an optional settled date, and notes. The status SHALL be exactly one of two values: ongoing ("開團中") and closed ("已收單"). A newly created campaign SHALL have status ongoing and no settled date.

A campaign name SHALL be unique among campaigns. Because orders relate to campaigns by name rather than by identifier, a duplicate name would let one set of orders count toward two campaigns, would let a rename affect the wrong campaign's orders, and would make name-based navigation reach only one of them. Saving SHALL therefore reject a name that already belongs to another campaign, compared after trimming surrounding whitespace and excluding the campaign being edited. The rejection SHALL happen before any write occurs and SHALL state the reason on the form.

Campaigns that already carry duplicate names from before this rule SHALL remain readable and editable. This capability does not detect, merge, or rename existing duplicates, so the aggregation and navigation consequences described above remain possible for pre-existing data. That is a known limitation, not a closed risk.

#### Scenario: Create a campaign

- **WHEN** the user creates a campaign with a name and an open date
- **THEN** the campaign is persisted with status ongoing and no settled date

#### Scenario: Duplicate name is rejected before any write

- **WHEN** the user saves a campaign whose trimmed name already belongs to another campaign
- **THEN** the save is rejected, the reason is shown on the form, and the stored campaign count is unchanged

#### Scenario: Editing a campaign keeps its own name

- **WHEN** the user edits an existing campaign without changing its name and saves
- **THEN** the save succeeds, because the uniqueness comparison excludes the campaign being edited

#### Scenario: Pre-existing duplicates remain usable

- **WHEN** two campaigns sharing a name existed before this rule and the user opens and saves either one without renaming it
- **THEN** the save succeeds


<!-- @trace
source: campaign-identity-and-close-date
updated: 2026-08-15
code:
  - apps/ios/BuyLedger/Features/Campaigns/CampaignSummary.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderRowView.swift
  - apps/ios/BuyLedger/Features/AISummary/OllamaDTO.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLFormatters.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementDestination.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewBaseline.1.png
  - apps/ios/BuyLedgerTests/CurrencyMetadataCacheTests.swift
  - shared/data-model/fixtures/expected/typescript/SampleQuote.ts
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/quoteViewBaseline.1.png
  - apps/ios/BuyLedger/Features/Orders/Components/OptionPickerSheet.swift
  - apps/ios/BuyLedger/Core/Dependencies/PhotoClient.swift
  - shared/data-model/fixtures/expected/typescript/SampleGrade.ts
  - apps/ios/BuyLedgerTests/PrivacyManifestTests.swift
  - apps/ios/BuyLedgerUITests/Support/Waiting.swift
  - apps/ios/BuyLedger/Features/Orders/Components/MergePhotoPickerSheet.swift
  - apps/ios/BuyLedger/Core/Domain/LedgerOrder.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrdersToolbarContent.swift
  - apps/ios/BuyLedgerTests/LocalizationCatalogTests.swift
  - apps/ios/BuyLedgerUITests/Support/MenuInteraction.swift
  - apps/ios/BuyLedger/Features/Orders/OrderDatePeriod.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsDateRange.swift
  - apps/ios/BuyLedger/Core/Domain/Campaign.swift
  - apps/ios/BuyLedgerTests/PersistenceRecoveryTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderCreateTests.swift
  - apps/ios/BuyLedger/Core/Networking/HTTPClient.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/Money.generated.swift
  - apps/ios/BuyLedger/Features/FX/FxRates.swift
  - apps/ios/BuyLedger/Core/Persistence/CampaignReminderPersistence.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/quoteViewRateUnavailable.1.png
  - apps/ios/BuyLedger/Core/Testing/BLUITestSeedData.swift
  - apps/ios/BuyLedger/Core/Networking/ExchangeRateDTO.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardView.swift
  - apps/ios/BuyLedgerTests/InsightsStatsTests.swift
  - shared/data-model/schema/FxRateSnapshot.yaml
  - apps/ios/BuyLedgerTests/InsightsAttributionTests.swift
  - apps/ios/BuyLedgerTests/NumericInputGroupingScanTests.swift
  - apps/ios/BuyLedger/Core/Persistence/BuyLedgerSchema.swift
  - AGENTS.md
  - apps/ios/BuyLedger.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
  - apps/ios/BuyLedger/Resources/InfoPlist.xcstrings
  - apps/ios/BuyLedger/Features/Campaigns/CampaignEditView.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/ViewModifiers/BLHeroCardBackground.swift
  - apps/ios/BuyLedger/Core/Dependencies/TelemetryClient.swift
  - apps/ios/BuyLedger/Features/App/AppLockView.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/ViewModifiers/BLTypographyModifier.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementView.swift
  - apps/ios/BuyLedger/Core/Dependencies/BiometricAuthClient.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderStatus+Presentation.swift
  - apps/ios/BuyLedger/Features/App/RootFeature.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/States/BLDelayedProgressView.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/LedgerOrderItem.generated.swift
  - apps/ios/BuyLedger/Core/Sync/SyncQueueItem.swift
  - apps/ios/BuyLedger/Features/FX/ExchangeRateDTO.swift
  - shared/data-model/fixtures/expected/swift/SamplePreference.generated.swift
  - shared/data-model/fixtures/expected/typescript/SampleProfile.ts
  - shared/data-model/schema/CustomerTier.yaml
  - apps/ios/BuyLedgerTests/LookupManagementFeatureTests.swift
  - apps/ios/BuyLedgerUITests/Screens/DashboardScreen.swift
  - apps/ios/BuyLedger/Features/Settings/AISummaryModelCatalog.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignEditFeature.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/CustomerTier.generated.swift
  - apps/ios/BuyLedger/Features/Quote/QuoteView.swift
  - apps/ios/BuyLedgerTests/ExchangeRateClientTests.swift
  - apps/ios/BuyLedgerTests/OrdersFeaturePerformanceTests.swift
  - shared/data-model/fixtures/expected/typescript/SampleStatus.ts
  - apps/ios/BuyLedger/Core/Dependencies/CategoryRepository.swift
  - apps/ios/BuyLedgerTests/OrdersLoadStateTests.swift
  - apps/ios/BuyLedger/Core/Networking/HTTPMethod.swift
  - shared/data-model/fixtures/expected/typescript/SampleReceipt.ts
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLMetrics.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Avatar/BLAvatar.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/FxRateSnapshot.generated.swift
  - apps/ios/BuyLedgerTests/HTTPClientTests.swift
  - apps/ios/BuyLedger/Features/Orders/LedgerOrder+OrderMutation.swift
  - apps/ios/BuyLedger/Core/Dependencies/ReconciliationStatusRepository.swift
  - apps/ios/BuyLedger/Core/Networking/ExchangeRateClient.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLTypography.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersRegularViewMultiSelectBaseline.1.png
  - README.md
  - apps/ios/BuyLedger/Core/Persistence/PersistenceStoreQuarantine.swift
  - apps/ios/BuyLedgerUITests/Screens/Screen.swift
  - apps/ios/BuyLedger/Features/App/RootView.swift
  - apps/ios/BuyLedgerUITests/Screens/AISummaryScreen.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/dashboardViewBaseline.1.png
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Progress/BLProgressBar.swift
  - apps/ios/BuyLedger/Core/Networking/URLRequestBuilder.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignFormatters.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLBarChart.swift
  - apps/ios/BuyLedger/Features/Settings/AppLanguage.swift
  - apps/ios/BuyLedger/Shared/Extensions/Color+Extensions.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/States/BLLoadFailureView.swift
  - apps/ios/BuyLedgerTests/CampaignPersistenceTests.swift
  - apps/ios/BuyLedger/Core/Persistence/CampaignReminderRecord.swift
  - apps/ios/BuyLedger/Core/Dependencies/OrderSourceRepository.swift
  - apps/ios/BuyLedger/Core/Persistence/PaymentMethodRecord.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersFilterOperations.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/CampaignStatus.generated.swift
  - apps/ios/BuyLedgerUITests/Tests/Smoke/LaunchSmokeTests.swift
  - apps/ios/BuyLedger/Resources/GoogleService-Info.example.plist
  - shared/data-model/schema/OrderStatus.yaml
  - apps/ios/BuyLedger/Features/Campaigns/CampaignFeature.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsFeature.swift
  - apps/ios/BuyLedger/Core/Persistence/PersistenceError.swift
  - apps/ios/BuyLedger/Shared/Extensions/Bundle+Extensions.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLDonutChart.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewLongIdentifierBaseline.1.png
  - apps/ios/BuyLedgerTests/OrdersFilterOperationsTests.swift
  - apps/ios/BuyLedger/Features/Customers/CustomersView.swift
  - apps/ios/BuyLedgerUITests/Screens/CampaignsScreen.swift
  - apps/ios/BuyLedgerTests/PhotoDataProcessorTests.swift
  - apps/ios/BuyLedgerUITests/Screens/QuoteScreen.swift
  - shared/data-model/generator/src/datamodel-gen.ts
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Buttons/BLButtonStyle.swift
  - apps/ios/BuyLedgerUITests/Support/Assertions.swift
  - shared/data-model/fixtures/expected/swift/SampleReceipt.generated.swift
  - apps/ios/BuyLedger/Core/Domain/Campaign+Samples.swift
  - apps/ios/BuyLedger/Core/Persistence/ReconciliationStatusRecord.swift
  - apps/ios/BuyLedgerTests/AppConfigurationTests.swift
  - apps/ios/BuyLedger/Core/Persistence/CurrencyMetadataPersistence.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardStats.swift
  - apps/ios/BuyLedger/Core/Dependencies/OrderRepository.swift
  - shared/data-model/fixtures/schema/sample-trait-matrix.yaml
  - apps/ios/BuyLedger/Features/Orders/OrderDetailPath.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignListView.swift
  - apps/ios/BuyLedgerTests/DesignSystemSourceScanTests.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFormatters.swift
  - apps/ios/BuyLedgerTests/OllamaClientTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Insights/InsightsTests.swift
  - apps/ios/BuyLedgerUITests/Support/Scrolling.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsView.swift
  - apps/ios/BuyLedgerTests/OrderMergeTests.swift
  - apps/ios/BuyLedgerUITests/Screens/AppLockScreen.swift
  - apps/ios/BuyLedgerTests/TestDependencies.swift
  - .github/workflows/ci.yml
  - apps/ios/BuyLedger/Resources/Info.plist
  - apps/ios/BuyLedger/Features/App/AppScenePhaseCoordinator.swift
  - shared/data-model/fixtures/expected/swift/SampleProfile.generated.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/CurrencyCode.generated.swift
  - apps/ios/BuyLedger/Core/Persistence/CategoryRecord.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Forms/PaymentMethodEditorSheet.swift
  - shared/data-model/fixtures/expected/kotlin/SampleGrade.kt
  - shared/data-model/schema/Campaign.yaml
  - apps/ios/BuyLedger/Core/Domain/Generated/LedgerCustomer.generated.swift
  - apps/ios/BuyLedger/Features/App/RootTab.swift
  - apps/ios/BuyLedger/Features/Customers/CustomersFeature.swift
  - apps/ios/BuyLedgerUITests/Screens/SettingsScreen.swift
  - apps/ios/BuyLedgerTests/CampaignEditFeatureTests.swift
  - apps/ios/BuyLedger.xcodeproj/project.pbxproj
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Pickers/OptionPickerSheet.swift
  - apps/ios/BuyLedgerTests/CalendarReminderTests.swift
  - shared/data-model/fixtures/expected/typescript/SamplePreference.ts
  - apps/ios/BuyLedger/Core/Dependencies/CampaignRepository.swift
  - apps/ios/BuyLedger/Core/Dependencies/CurrencyMetadataRepository.swift
  - apps/ios/BuyLedger/Features/More/MoreView.swift
  - apps/ios/BuyLedger/Core/Domain/LedgerOrder+Samples.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Badges/BLBadge.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Cards/BLCard.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/Campaign.generated.swift
  - apps/ios/BuyLedger/Core/Testing/BLUITestHarness.swift
  - apps/ios/BuyLedgerUITests/Support/ValueParsing.swift
  - apps/ios/BuyLedgerUITests.xctestplan
  - apps/ios/BuyLedger/Core/Persistence/NameLookupRecord.swift
  - apps/ios/BuyLedger/Features/FX/FxView.swift
  - apps/ios/BuyLedger/Core/Networking/AppConfiguration.swift
  - apps/ios/BuyLedger/Features/AISummary/OllamaClient.swift
  - apps/ios/BuyLedgerUITests/Screens/PhotoViewerScreen.swift
  - apps/ios/BuyLedgerUITests/Support/AlertInteraction.swift
  - apps/ios/BuyLedger/Features/App/PersistenceFailureFeature.swift
  - apps/ios/BuyLedgerTests/DashboardFeatureTests.swift
  - shared/data-model/fixtures/expected/kotlin/SampleStatus.kt
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewLongContentBaseline.1.png
  - apps/ios/BuyLedger/Features/Campaigns/CampaignDetailView.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupNameEditorSheet.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderSelectableRow.swift
  - apps/ios/BuyLedgerUITests/Tests/Campaigns/CampaignCrudTests.swift
  - apps/ios/BuyLedger/Core/Diagnostics/CrashDiagnosticsClient.swift
  - apps/ios/BuyLedger/Core/Testing/BLUITestDependencyOverrides.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardFeature.swift
  - apps/ios/BuyLedgerTests/TestSuiteIntegrityTests.swift
  - shared/data-model/schema/PaymentReceiptStatus.yaml
  - apps/ios/BuyLedger/Features/AISummary/AISummaryFeature.swift
  - apps/ios/BuyLedger/Features/FX/FxFeature.swift
  - shared/data-model/schema/LedgerCustomer.yaml
  - apps/ios/BuyLedgerAccessibilityIDs/BLAccessibilityID.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsSnapshot.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/persistenceFailureViewBaseline.1.png
  - apps/ios/BuyLedger/Core/Sync/SyncMeta.swift
  - apps/ios/BuyLedgerUITests/Support/BLUITestCase.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Chips/BLFilterChip.swift
  - apps/ios/BuyLedgerUITests/Support/AppNavigator.swift
  - apps/ios/BuyLedger/Core/Persistence/PersistenceContainer.swift
  - apps/ios/BuyLedger/Core/Persistence/OrderPersistence.swift
  - apps/ios/BuyLedger/Features/App/RootTabLayout.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLDonutSegment.swift
  - apps/ios/BuyLedgerTests/ContrastComplianceTests.swift
  - apps/ios/BuyLedgerTests/OrderDraftTests.swift
  - apps/ios/README.md
  - CLAUDE.md
  - apps/ios/BuyLedgerTests/APIErrorMappingTests.swift
  - apps/ios/BuyLedgerUITests/Screens/OrderEditScreen.swift
  - apps/ios/BuyLedgerTests/OrderPersistenceTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderDetailTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLBarChartValue.swift
  - apps/ios/BuyLedgerTests/OrdersFeatureTests.swift
  - apps/ios/BuyLedgerTests/FxFeatureTests.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/PaymentReceiptStatus.generated.swift
  - apps/ios/BuyLedgerTests/InsightsFeatureTests.swift
  - apps/ios/BuyLedger/Core/Persistence/ReconciliationStatusPersistence.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupCatalog.swift
  - apps/ios/BuyLedgerTests/PaymentMethodPersistenceTests.swift
  - apps/ios/BuyLedger/Core/Dependencies/NameLookupOperations.swift
  - apps/ios/BuyLedger/Core/Networking/APIError.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Tags/BLTagPill.swift
  - apps/ios/BuyLedgerUITests/Tests/Tools/FxTests.swift
  - apps/ios/BuyLedger/Features/Orders/OrderDraft.swift
  - shared/data-model/schema/LedgerOrderItem.yaml
  - apps/ios/BuyLedger/Core/Testing/BLUITestSeedProfile.swift
  - apps/ios/BuyLedger/Features/App/RootSidebarLayout.swift
  - apps/ios/BuyLedgerTests/OrderCalculationTests.swift
  - apps/ios/BuyLedger/Features/Quote/QuoteFeature.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests.swift
  - apps/ios/BuyLedgerTests/AISummaryFeatureTests.swift
  - shared/data-model/fixtures/expected/kotlin/SampleQuote.kt
  - apps/ios/BuyLedger/Core/Domain/Generated/OrderStatus.generated.swift
  - apps/ios/BuyLedgerTests/PersistenceErrorContractTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Smoke/AppLockTests.swift
  - apps/ios/BuyLedgerUITests/Support/TextInput.swift
  - apps/ios/BuyLedgerTests/NameLookupPersistenceTests.swift
  - apps/ios/BuyLedger/Core/Persistence/PaymentMethodPersistence.swift
  - apps/ios/BuyLedgerUITests/Screens/OrdersScreen.swift
  - apps/ios/BuyLedgerTests/ProjectionWriteBoundaryTests.swift
  - apps/ios/BuyLedger/Core/Persistence/OrderSourcePersistence.swift
  - apps/ios/BuyLedgerUITests/Tests/Campaigns/CampaignListTests.swift
  - apps/ios/BuyLedgerTests/ColorContrastTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Campaigns/CampaignDetailTests.swift
  - apps/ios/BuyLedger/App/AppLaunchConfigurator.swift
  - apps/ios/BuyLedgerTests/LookupCatalogTests.swift
  - shared/data-model/schema/Money.yaml
  - apps/ios/BuyLedgerTests/PersistenceFailureFeatureTests.swift
  - apps/ios/BuyLedger/Resources/Localizable.xcstrings
  - apps/ios/BuyLedgerUITests/Screens/FxScreen.swift
  - shared/data-model/fixtures/expected/typescript/SampleSequence.ts
  - apps/ios/BuyLedger/Features/Orders/OrderEditFeature.swift
  - apps/ios/BuyLedger/Core/Dependencies/OpenSettingsClient.swift
  - apps/ios/BuyLedger/App/BuyLedgerApp.swift
  - shared/data-model/schema/CampaignStatus.yaml
  - apps/ios/BuyLedger/Features/AISummary/AISummaryView.swift
  - apps/ios/BuyLedger/Core/Dependencies/CalendarReminderClient.swift
  - apps/ios/BuyLedgerTests/CustomersFeatureTests.swift
  - apps/ios/BuyLedgerTests/SnapshotTests.swift
  - apps/ios/BuyLedgerTests/OrderEditFeatureTests.swift
  - apps/ios/BuyLedgerUITests/Screens/OptionPickerScreen.swift
  - apps/ios/BuyLedgerUITests/Support/LaunchOptions.swift
  - apps/ios/BuyLedger/Features/Orders/OrderStatusFilter.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLTone.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestConfiguration.swift
  - apps/ios/BuyLedgerUITests/Screens/InsightsScreen.swift
  - apps/ios/BuyLedger/Shared/Localization/AppLanguage.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLHeatmapDepth.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersView.swift
  - apps/ios/BuyLedgerTests/OrderStatusTests.swift
  - shared/data-model/fixtures/expected/kotlin/SampleProfile.kt
  - apps/ios/BuyLedger/Core/Persistence/CategoryPersistence.swift
  - shared/data-model/fixtures/expected/kotlin/SampleReceipt.kt
  - apps/ios/BuyLedger/App/Testing/BLUITestDependencyOverrides.swift
  - shared/data-model/schema/PaymentMethodInfo.yaml
  - apps/ios/BuyLedger/Core/Persistence/PersistenceStoreQuarantineClient.swift
  - apps/ios/BuyLedger/Features/App/PersistenceFailureView.swift
  - apps/ios/BuyLedger/Core/Domain/OrderStatus.swift
  - shared/data-model/fixtures/expected/swift/SampleGrade.generated.swift
  - apps/ios/BuyLedgerTests/DashboardStatsTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Smoke/HarnessSelfCheckTests.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderMergeCandidateSheet.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderMergeTests.swift
  - shared/data-model/fixtures/schema/sample-enums.yaml
  - apps/ios/BuyLedgerUITests/Screens/CampaignEditScreen.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewMultiSelectBaseline.1.png
  - apps/ios/BuyLedger/Features/Orders/Components/OrderDetailView.swift
  - apps/ios/BuyLedgerTests/OrderEditFocusTests.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsStorage.swift
  - apps/ios/BuyLedger/Features/FX/ExchangeRateClient.swift
  - apps/ios/BuyLedger/Core/Domain/CurrencyCode.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoViewer.swift
  - apps/ios/BuyLedger.xctestplan
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersFeature+StateQuery.swift
  - apps/ios/BuyLedgerUITests/Screens/RootNavigationScreen.swift
  - apps/ios/BuyLedgerUITests-Performance.xctestplan
  - apps/ios/BuyLedgerTests/AppScenePhaseCoordinatorTests.swift
  - apps/ios/BuyLedgerTests/OrderMergeFeatureTests.swift
  - apps/ios/BuyLedger/Features/Orders/OrderEditView.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLStatusHue.swift
  - apps/ios/BuyLedger/Shared/Extensions/Decimal+Extensions.swift
  - apps/ios/BuyLedgerTests/OrdersSearchCancellationTests.swift
  - apps/ios/BuyLedgerUITests/PhotoViewerPagingTests.swift
  - apps/ios/BuyLedger/Shared/Media/PhotoDataProcessor.swift
  - apps/ios/BuyLedgerTests/SettingsFeatureTests.swift
  - shared/data-model/fixtures/expected/swift/SampleQuote.generated.swift
  - apps/ios/BuyLedger/Core/Persistence/CurrencyMetadataRecord.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersFeature.swift
  - apps/ios/BuyLedgerUITests/Tests/Tools/QuoteTests.swift
  - apps/ios/BuyLedgerTests/OrdersBatchOperationsTests.swift
  - apps/ios/BuyLedgerTests/LayerBoundaryTests.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersBatchOperations.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLSparkline.swift
  - shared/data-model/schema/CurrencyCode.yaml
  - apps/ios/BuyLedgerTests/CampaignSummaryTests.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestSeedData.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsView.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersCompactView.swift
  - apps/ios/BuyLedger/Core/Persistence/OrderRecord.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/States/DelayedProgressView.swift
  - apps/ios/CLAUDE.md
  - shared/data-model/schema/LedgerOrder.yaml
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/ViewModifiers/BLCardShadow.swift
  - apps/ios/BuyLedger/Features/Customers/CustomerRankBadgeStyle.swift
  - shared/data-model/fixtures/expected/kotlin/SampleSequence.kt
  - apps/ios/BuyLedger/Core/Domain/FxRates.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersMergeFlowOperations.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsFeature.swift
  - apps/ios/BuyLedger/Core/Domain/OrderMerge.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewBaseline.1.png
  - apps/ios/BuyLedger/Features/App/SidebarBadgeCounts.swift
  - apps/ios/BuyLedgerTests/ColorContrast.swift
  - apps/ios/BuyLedger/Features/Orders/Components/PaymentMethodEditorSheet.swift
  - apps/ios/BuyLedger.xcodeproj/xcshareddata/xcschemes/BuyLedger.xcscheme
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoThumbnail.swift
  - apps/ios/BuyLedgerUITests/Tests/Performance/LaunchPerformanceTests.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsStats.swift
  - apps/ios/BuyLedgerUITests/Tests/Customers/CustomersTests.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupKind.swift
  - apps/ios/BuyLedgerTests/AccessibilityConventionScanTests.swift
  - apps/ios/BuyLedger/Core/Dependencies/PaymentMethodRepository.swift
  - apps/ios/BuyLedgerTests/BLAccessibilityIDTests.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestSeedProfile.swift
  - shared/data-model/fixtures/schema/sample-orders.yaml
  - apps/ios/BuyLedger/Core/Testing/BLUITestConfiguration.swift
  - apps/ios/BuyLedger/App/AppDelegate.swift
  - apps/ios/BuyLedgerTests/BLUITestConfigurationTests.swift
  - apps/ios/BuyLedger/Core/Persistence/NameLookupPersistence.swift
  - apps/ios/BuyLedgerTests/QuoteFeatureTests.swift
  - apps/ios/BuyLedgerUITests/Screens/OrderDetailScreen.swift
  - apps/ios/BuyLedger/Features/Orders/OrderMergeFeature.swift
  - apps/ios/BuyLedgerTests/BiometricAuthClientTests.swift
  - apps/ios/BuyLedgerTests/CampaignFeatureTests.swift
  - apps/ios/BuyLedgerTests/BLFormattersTests.swift
  - apps/ios/BuyLedgerUITests/Support/SheetInteraction.swift
  - apps/ios/BuyLedger/Shared/Extensions/Image+Extensions.swift
  - shared/data-model/README.md
  - shared/data-model/fixtures/expected/swift/SampleSequence.generated.swift
  - apps/ios/BuyLedgerUITests/KeyboardDismissTests.swift
  - apps/ios/BuyLedger/Core/Persistence/OrderSourceRecord.swift
  - apps/ios/BuyLedgerUITests/Screens/CustomersScreen.swift
  - apps/ios/BuyLedgerTests/AppLockFeatureTests.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFilterSheet.swift
  - shared/data-model/fixtures/expected/swift/SampleStatus.generated.swift
  - apps/ios/BuyLedgerUITests/Screens/CampaignDetailScreen.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/AISummaryTests.swift
  - apps/ios/BuyLedgerUITests/Support/Diagnostics.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestHarness.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderEditDirtyTests.swift
  - apps/ios/BuyLedger/Resources/PrivacyInfo.xcprivacy
  - apps/ios/BuyLedger/Core/Domain/LedgerOrderItem.swift
  - shared/data-model/fixtures/expected/kotlin/SamplePreference.kt
  - apps/ios/BuyLedgerTests/CampaignReminderFailureTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrdersListTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Status/BLStatusPill.swift
  - apps/ios/BuyLedgerTests/CampaignIntegrationTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLPalette.swift
  - apps/ios/BuyLedger/Core/Domain/OrderSummary.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/PaymentMethodInfo.generated.swift
  - apps/ios/BuyLedger/Core/Dependencies/CampaignReminderRepository.swift
  - apps/ios/BuyLedger/Features/App/AppLockFeature.swift
  - apps/ios/BuyLedger/Core/Domain/FxRateSnapshot.swift
  - apps/ios/BuyLedger/Core/Persistence/CampaignRecord.swift
  - apps/ios/BuyLedger/Core/Persistence/CampaignPersistence.swift
  - apps/ios/BuyLedgerTests/BLPhotoViewerTests.swift
  - apps/ios/BuyLedgerTests/SchemaMigrationTests.swift
  - apps/ios/BuyLedgerUITests/Screens/MergeFlowScreen.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/LedgerOrder.generated.swift
tests:
  - shared/data-model/generator/test/datamodel-gen.test.ts
-->

---
### Requirement: Settling records a date without changing status

The system SHALL provide a settle action that records a settled date on the campaign. Settling SHALL NOT change the campaign status and SHALL NOT lock the campaign's orders from editing.

#### Scenario: Settle a closed campaign

- **WHEN** the user taps settle on a campaign whose status is closed
- **THEN** the campaign records a settled date AND its status remains closed AND its member orders remain editable


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
### Requirement: Automatic transition from ongoing to closed at the close date

The system SHALL automatically transition a campaign from ongoing to closed once the close date's day has passed. The comparison SHALL be made at day granularity using an injected calendar: a campaign whose close date falls on the current day SHALL remain ongoing, and SHALL transition only from the following day onward. Timestamp-level comparison SHALL NOT be used, because the close date is chosen as a date while the stored value carries the time of creation, which would close a campaign within minutes of being created with today's date.

The evaluation SHALL run when the app launches and when the campaign list or orders list is opened, using an injected current date rather than reading the system clock directly. A campaign without a close date SHALL remain ongoing until changed manually. The transition SHALL apply only to campaigns whose status is ongoing.

A campaign that was already transitioned to closed under the previous timestamp-level comparison SHALL NOT automatically revert to ongoing under this day-granularity comparison, because the transition only evaluates campaigns whose status is currently ongoing. Reopening such a campaign requires a manual status change. That is a known limitation, not a closed risk.

#### Scenario: Close date today stays ongoing

- **WHEN** the system evaluates an ongoing campaign whose close date falls on the current day
- **THEN** the campaign status remains ongoing

#### Scenario: Past close date transitions to closed

- **WHEN** the system evaluates an ongoing campaign whose close date fell on an earlier day
- **THEN** the campaign status becomes closed and the change is persisted

#### Scenario: Missing close date stays ongoing

- **WHEN** the system evaluates an ongoing campaign that has no close date
- **THEN** the campaign status remains ongoing

#### Scenario: Previously mis-closed campaign does not auto-revert

- **WHEN** a campaign was already transitioned to closed under the previous timestamp-level comparison, even though its close date falls on the current day under this day-granularity rule
- **THEN** the campaign status remains closed until the user manually changes it

##### Example: transition evaluation at day granularity

| Status before | Close date relative to current day | Status after |
| ------------- | ---------------------------------- | ------------ |
| ongoing       | an earlier day                     | closed       |
| ongoing       | the current day, earlier time      | ongoing      |
| ongoing       | the current day, later time        | ongoing      |
| ongoing       | a later day                        | ongoing      |
| ongoing       | none                               | ongoing      |
| closed        | an earlier day                     | closed       |


<!-- @trace
source: campaign-identity-and-close-date
updated: 2026-08-15
code:
  - apps/ios/BuyLedger/Features/Campaigns/CampaignSummary.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderRowView.swift
  - apps/ios/BuyLedger/Features/AISummary/OllamaDTO.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLFormatters.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementDestination.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewBaseline.1.png
  - apps/ios/BuyLedgerTests/CurrencyMetadataCacheTests.swift
  - shared/data-model/fixtures/expected/typescript/SampleQuote.ts
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/quoteViewBaseline.1.png
  - apps/ios/BuyLedger/Features/Orders/Components/OptionPickerSheet.swift
  - apps/ios/BuyLedger/Core/Dependencies/PhotoClient.swift
  - shared/data-model/fixtures/expected/typescript/SampleGrade.ts
  - apps/ios/BuyLedgerTests/PrivacyManifestTests.swift
  - apps/ios/BuyLedgerUITests/Support/Waiting.swift
  - apps/ios/BuyLedger/Features/Orders/Components/MergePhotoPickerSheet.swift
  - apps/ios/BuyLedger/Core/Domain/LedgerOrder.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrdersToolbarContent.swift
  - apps/ios/BuyLedgerTests/LocalizationCatalogTests.swift
  - apps/ios/BuyLedgerUITests/Support/MenuInteraction.swift
  - apps/ios/BuyLedger/Features/Orders/OrderDatePeriod.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsDateRange.swift
  - apps/ios/BuyLedger/Core/Domain/Campaign.swift
  - apps/ios/BuyLedgerTests/PersistenceRecoveryTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderCreateTests.swift
  - apps/ios/BuyLedger/Core/Networking/HTTPClient.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/Money.generated.swift
  - apps/ios/BuyLedger/Features/FX/FxRates.swift
  - apps/ios/BuyLedger/Core/Persistence/CampaignReminderPersistence.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/quoteViewRateUnavailable.1.png
  - apps/ios/BuyLedger/Core/Testing/BLUITestSeedData.swift
  - apps/ios/BuyLedger/Core/Networking/ExchangeRateDTO.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardView.swift
  - apps/ios/BuyLedgerTests/InsightsStatsTests.swift
  - shared/data-model/schema/FxRateSnapshot.yaml
  - apps/ios/BuyLedgerTests/InsightsAttributionTests.swift
  - apps/ios/BuyLedgerTests/NumericInputGroupingScanTests.swift
  - apps/ios/BuyLedger/Core/Persistence/BuyLedgerSchema.swift
  - AGENTS.md
  - apps/ios/BuyLedger.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
  - apps/ios/BuyLedger/Resources/InfoPlist.xcstrings
  - apps/ios/BuyLedger/Features/Campaigns/CampaignEditView.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/ViewModifiers/BLHeroCardBackground.swift
  - apps/ios/BuyLedger/Core/Dependencies/TelemetryClient.swift
  - apps/ios/BuyLedger/Features/App/AppLockView.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/ViewModifiers/BLTypographyModifier.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementView.swift
  - apps/ios/BuyLedger/Core/Dependencies/BiometricAuthClient.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderStatus+Presentation.swift
  - apps/ios/BuyLedger/Features/App/RootFeature.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/States/BLDelayedProgressView.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/LedgerOrderItem.generated.swift
  - apps/ios/BuyLedger/Core/Sync/SyncQueueItem.swift
  - apps/ios/BuyLedger/Features/FX/ExchangeRateDTO.swift
  - shared/data-model/fixtures/expected/swift/SamplePreference.generated.swift
  - shared/data-model/fixtures/expected/typescript/SampleProfile.ts
  - shared/data-model/schema/CustomerTier.yaml
  - apps/ios/BuyLedgerTests/LookupManagementFeatureTests.swift
  - apps/ios/BuyLedgerUITests/Screens/DashboardScreen.swift
  - apps/ios/BuyLedger/Features/Settings/AISummaryModelCatalog.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignEditFeature.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/CustomerTier.generated.swift
  - apps/ios/BuyLedger/Features/Quote/QuoteView.swift
  - apps/ios/BuyLedgerTests/ExchangeRateClientTests.swift
  - apps/ios/BuyLedgerTests/OrdersFeaturePerformanceTests.swift
  - shared/data-model/fixtures/expected/typescript/SampleStatus.ts
  - apps/ios/BuyLedger/Core/Dependencies/CategoryRepository.swift
  - apps/ios/BuyLedgerTests/OrdersLoadStateTests.swift
  - apps/ios/BuyLedger/Core/Networking/HTTPMethod.swift
  - shared/data-model/fixtures/expected/typescript/SampleReceipt.ts
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLMetrics.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Avatar/BLAvatar.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/FxRateSnapshot.generated.swift
  - apps/ios/BuyLedgerTests/HTTPClientTests.swift
  - apps/ios/BuyLedger/Features/Orders/LedgerOrder+OrderMutation.swift
  - apps/ios/BuyLedger/Core/Dependencies/ReconciliationStatusRepository.swift
  - apps/ios/BuyLedger/Core/Networking/ExchangeRateClient.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLTypography.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersRegularViewMultiSelectBaseline.1.png
  - README.md
  - apps/ios/BuyLedger/Core/Persistence/PersistenceStoreQuarantine.swift
  - apps/ios/BuyLedgerUITests/Screens/Screen.swift
  - apps/ios/BuyLedger/Features/App/RootView.swift
  - apps/ios/BuyLedgerUITests/Screens/AISummaryScreen.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/dashboardViewBaseline.1.png
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Progress/BLProgressBar.swift
  - apps/ios/BuyLedger/Core/Networking/URLRequestBuilder.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignFormatters.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLBarChart.swift
  - apps/ios/BuyLedger/Features/Settings/AppLanguage.swift
  - apps/ios/BuyLedger/Shared/Extensions/Color+Extensions.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/States/BLLoadFailureView.swift
  - apps/ios/BuyLedgerTests/CampaignPersistenceTests.swift
  - apps/ios/BuyLedger/Core/Persistence/CampaignReminderRecord.swift
  - apps/ios/BuyLedger/Core/Dependencies/OrderSourceRepository.swift
  - apps/ios/BuyLedger/Core/Persistence/PaymentMethodRecord.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersFilterOperations.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/CampaignStatus.generated.swift
  - apps/ios/BuyLedgerUITests/Tests/Smoke/LaunchSmokeTests.swift
  - apps/ios/BuyLedger/Resources/GoogleService-Info.example.plist
  - shared/data-model/schema/OrderStatus.yaml
  - apps/ios/BuyLedger/Features/Campaigns/CampaignFeature.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsFeature.swift
  - apps/ios/BuyLedger/Core/Persistence/PersistenceError.swift
  - apps/ios/BuyLedger/Shared/Extensions/Bundle+Extensions.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLDonutChart.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewLongIdentifierBaseline.1.png
  - apps/ios/BuyLedgerTests/OrdersFilterOperationsTests.swift
  - apps/ios/BuyLedger/Features/Customers/CustomersView.swift
  - apps/ios/BuyLedgerUITests/Screens/CampaignsScreen.swift
  - apps/ios/BuyLedgerTests/PhotoDataProcessorTests.swift
  - apps/ios/BuyLedgerUITests/Screens/QuoteScreen.swift
  - shared/data-model/generator/src/datamodel-gen.ts
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Buttons/BLButtonStyle.swift
  - apps/ios/BuyLedgerUITests/Support/Assertions.swift
  - shared/data-model/fixtures/expected/swift/SampleReceipt.generated.swift
  - apps/ios/BuyLedger/Core/Domain/Campaign+Samples.swift
  - apps/ios/BuyLedger/Core/Persistence/ReconciliationStatusRecord.swift
  - apps/ios/BuyLedgerTests/AppConfigurationTests.swift
  - apps/ios/BuyLedger/Core/Persistence/CurrencyMetadataPersistence.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardStats.swift
  - apps/ios/BuyLedger/Core/Dependencies/OrderRepository.swift
  - shared/data-model/fixtures/schema/sample-trait-matrix.yaml
  - apps/ios/BuyLedger/Features/Orders/OrderDetailPath.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignListView.swift
  - apps/ios/BuyLedgerTests/DesignSystemSourceScanTests.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFormatters.swift
  - apps/ios/BuyLedgerTests/OllamaClientTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Insights/InsightsTests.swift
  - apps/ios/BuyLedgerUITests/Support/Scrolling.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsView.swift
  - apps/ios/BuyLedgerTests/OrderMergeTests.swift
  - apps/ios/BuyLedgerUITests/Screens/AppLockScreen.swift
  - apps/ios/BuyLedgerTests/TestDependencies.swift
  - .github/workflows/ci.yml
  - apps/ios/BuyLedger/Resources/Info.plist
  - apps/ios/BuyLedger/Features/App/AppScenePhaseCoordinator.swift
  - shared/data-model/fixtures/expected/swift/SampleProfile.generated.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/CurrencyCode.generated.swift
  - apps/ios/BuyLedger/Core/Persistence/CategoryRecord.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Forms/PaymentMethodEditorSheet.swift
  - shared/data-model/fixtures/expected/kotlin/SampleGrade.kt
  - shared/data-model/schema/Campaign.yaml
  - apps/ios/BuyLedger/Core/Domain/Generated/LedgerCustomer.generated.swift
  - apps/ios/BuyLedger/Features/App/RootTab.swift
  - apps/ios/BuyLedger/Features/Customers/CustomersFeature.swift
  - apps/ios/BuyLedgerUITests/Screens/SettingsScreen.swift
  - apps/ios/BuyLedgerTests/CampaignEditFeatureTests.swift
  - apps/ios/BuyLedger.xcodeproj/project.pbxproj
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Pickers/OptionPickerSheet.swift
  - apps/ios/BuyLedgerTests/CalendarReminderTests.swift
  - shared/data-model/fixtures/expected/typescript/SamplePreference.ts
  - apps/ios/BuyLedger/Core/Dependencies/CampaignRepository.swift
  - apps/ios/BuyLedger/Core/Dependencies/CurrencyMetadataRepository.swift
  - apps/ios/BuyLedger/Features/More/MoreView.swift
  - apps/ios/BuyLedger/Core/Domain/LedgerOrder+Samples.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Badges/BLBadge.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Cards/BLCard.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/Campaign.generated.swift
  - apps/ios/BuyLedger/Core/Testing/BLUITestHarness.swift
  - apps/ios/BuyLedgerUITests/Support/ValueParsing.swift
  - apps/ios/BuyLedgerUITests.xctestplan
  - apps/ios/BuyLedger/Core/Persistence/NameLookupRecord.swift
  - apps/ios/BuyLedger/Features/FX/FxView.swift
  - apps/ios/BuyLedger/Core/Networking/AppConfiguration.swift
  - apps/ios/BuyLedger/Features/AISummary/OllamaClient.swift
  - apps/ios/BuyLedgerUITests/Screens/PhotoViewerScreen.swift
  - apps/ios/BuyLedgerUITests/Support/AlertInteraction.swift
  - apps/ios/BuyLedger/Features/App/PersistenceFailureFeature.swift
  - apps/ios/BuyLedgerTests/DashboardFeatureTests.swift
  - shared/data-model/fixtures/expected/kotlin/SampleStatus.kt
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewLongContentBaseline.1.png
  - apps/ios/BuyLedger/Features/Campaigns/CampaignDetailView.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupNameEditorSheet.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderSelectableRow.swift
  - apps/ios/BuyLedgerUITests/Tests/Campaigns/CampaignCrudTests.swift
  - apps/ios/BuyLedger/Core/Diagnostics/CrashDiagnosticsClient.swift
  - apps/ios/BuyLedger/Core/Testing/BLUITestDependencyOverrides.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardFeature.swift
  - apps/ios/BuyLedgerTests/TestSuiteIntegrityTests.swift
  - shared/data-model/schema/PaymentReceiptStatus.yaml
  - apps/ios/BuyLedger/Features/AISummary/AISummaryFeature.swift
  - apps/ios/BuyLedger/Features/FX/FxFeature.swift
  - shared/data-model/schema/LedgerCustomer.yaml
  - apps/ios/BuyLedgerAccessibilityIDs/BLAccessibilityID.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsSnapshot.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/persistenceFailureViewBaseline.1.png
  - apps/ios/BuyLedger/Core/Sync/SyncMeta.swift
  - apps/ios/BuyLedgerUITests/Support/BLUITestCase.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Chips/BLFilterChip.swift
  - apps/ios/BuyLedgerUITests/Support/AppNavigator.swift
  - apps/ios/BuyLedger/Core/Persistence/PersistenceContainer.swift
  - apps/ios/BuyLedger/Core/Persistence/OrderPersistence.swift
  - apps/ios/BuyLedger/Features/App/RootTabLayout.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLDonutSegment.swift
  - apps/ios/BuyLedgerTests/ContrastComplianceTests.swift
  - apps/ios/BuyLedgerTests/OrderDraftTests.swift
  - apps/ios/README.md
  - CLAUDE.md
  - apps/ios/BuyLedgerTests/APIErrorMappingTests.swift
  - apps/ios/BuyLedgerUITests/Screens/OrderEditScreen.swift
  - apps/ios/BuyLedgerTests/OrderPersistenceTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderDetailTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLBarChartValue.swift
  - apps/ios/BuyLedgerTests/OrdersFeatureTests.swift
  - apps/ios/BuyLedgerTests/FxFeatureTests.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/PaymentReceiptStatus.generated.swift
  - apps/ios/BuyLedgerTests/InsightsFeatureTests.swift
  - apps/ios/BuyLedger/Core/Persistence/ReconciliationStatusPersistence.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupCatalog.swift
  - apps/ios/BuyLedgerTests/PaymentMethodPersistenceTests.swift
  - apps/ios/BuyLedger/Core/Dependencies/NameLookupOperations.swift
  - apps/ios/BuyLedger/Core/Networking/APIError.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Tags/BLTagPill.swift
  - apps/ios/BuyLedgerUITests/Tests/Tools/FxTests.swift
  - apps/ios/BuyLedger/Features/Orders/OrderDraft.swift
  - shared/data-model/schema/LedgerOrderItem.yaml
  - apps/ios/BuyLedger/Core/Testing/BLUITestSeedProfile.swift
  - apps/ios/BuyLedger/Features/App/RootSidebarLayout.swift
  - apps/ios/BuyLedgerTests/OrderCalculationTests.swift
  - apps/ios/BuyLedger/Features/Quote/QuoteFeature.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests.swift
  - apps/ios/BuyLedgerTests/AISummaryFeatureTests.swift
  - shared/data-model/fixtures/expected/kotlin/SampleQuote.kt
  - apps/ios/BuyLedger/Core/Domain/Generated/OrderStatus.generated.swift
  - apps/ios/BuyLedgerTests/PersistenceErrorContractTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Smoke/AppLockTests.swift
  - apps/ios/BuyLedgerUITests/Support/TextInput.swift
  - apps/ios/BuyLedgerTests/NameLookupPersistenceTests.swift
  - apps/ios/BuyLedger/Core/Persistence/PaymentMethodPersistence.swift
  - apps/ios/BuyLedgerUITests/Screens/OrdersScreen.swift
  - apps/ios/BuyLedgerTests/ProjectionWriteBoundaryTests.swift
  - apps/ios/BuyLedger/Core/Persistence/OrderSourcePersistence.swift
  - apps/ios/BuyLedgerUITests/Tests/Campaigns/CampaignListTests.swift
  - apps/ios/BuyLedgerTests/ColorContrastTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Campaigns/CampaignDetailTests.swift
  - apps/ios/BuyLedger/App/AppLaunchConfigurator.swift
  - apps/ios/BuyLedgerTests/LookupCatalogTests.swift
  - shared/data-model/schema/Money.yaml
  - apps/ios/BuyLedgerTests/PersistenceFailureFeatureTests.swift
  - apps/ios/BuyLedger/Resources/Localizable.xcstrings
  - apps/ios/BuyLedgerUITests/Screens/FxScreen.swift
  - shared/data-model/fixtures/expected/typescript/SampleSequence.ts
  - apps/ios/BuyLedger/Features/Orders/OrderEditFeature.swift
  - apps/ios/BuyLedger/Core/Dependencies/OpenSettingsClient.swift
  - apps/ios/BuyLedger/App/BuyLedgerApp.swift
  - shared/data-model/schema/CampaignStatus.yaml
  - apps/ios/BuyLedger/Features/AISummary/AISummaryView.swift
  - apps/ios/BuyLedger/Core/Dependencies/CalendarReminderClient.swift
  - apps/ios/BuyLedgerTests/CustomersFeatureTests.swift
  - apps/ios/BuyLedgerTests/SnapshotTests.swift
  - apps/ios/BuyLedgerTests/OrderEditFeatureTests.swift
  - apps/ios/BuyLedgerUITests/Screens/OptionPickerScreen.swift
  - apps/ios/BuyLedgerUITests/Support/LaunchOptions.swift
  - apps/ios/BuyLedger/Features/Orders/OrderStatusFilter.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLTone.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestConfiguration.swift
  - apps/ios/BuyLedgerUITests/Screens/InsightsScreen.swift
  - apps/ios/BuyLedger/Shared/Localization/AppLanguage.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLHeatmapDepth.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersView.swift
  - apps/ios/BuyLedgerTests/OrderStatusTests.swift
  - shared/data-model/fixtures/expected/kotlin/SampleProfile.kt
  - apps/ios/BuyLedger/Core/Persistence/CategoryPersistence.swift
  - shared/data-model/fixtures/expected/kotlin/SampleReceipt.kt
  - apps/ios/BuyLedger/App/Testing/BLUITestDependencyOverrides.swift
  - shared/data-model/schema/PaymentMethodInfo.yaml
  - apps/ios/BuyLedger/Core/Persistence/PersistenceStoreQuarantineClient.swift
  - apps/ios/BuyLedger/Features/App/PersistenceFailureView.swift
  - apps/ios/BuyLedger/Core/Domain/OrderStatus.swift
  - shared/data-model/fixtures/expected/swift/SampleGrade.generated.swift
  - apps/ios/BuyLedgerTests/DashboardStatsTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Smoke/HarnessSelfCheckTests.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderMergeCandidateSheet.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderMergeTests.swift
  - shared/data-model/fixtures/schema/sample-enums.yaml
  - apps/ios/BuyLedgerUITests/Screens/CampaignEditScreen.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewMultiSelectBaseline.1.png
  - apps/ios/BuyLedger/Features/Orders/Components/OrderDetailView.swift
  - apps/ios/BuyLedgerTests/OrderEditFocusTests.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsStorage.swift
  - apps/ios/BuyLedger/Features/FX/ExchangeRateClient.swift
  - apps/ios/BuyLedger/Core/Domain/CurrencyCode.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoViewer.swift
  - apps/ios/BuyLedger.xctestplan
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersFeature+StateQuery.swift
  - apps/ios/BuyLedgerUITests/Screens/RootNavigationScreen.swift
  - apps/ios/BuyLedgerUITests-Performance.xctestplan
  - apps/ios/BuyLedgerTests/AppScenePhaseCoordinatorTests.swift
  - apps/ios/BuyLedgerTests/OrderMergeFeatureTests.swift
  - apps/ios/BuyLedger/Features/Orders/OrderEditView.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLStatusHue.swift
  - apps/ios/BuyLedger/Shared/Extensions/Decimal+Extensions.swift
  - apps/ios/BuyLedgerTests/OrdersSearchCancellationTests.swift
  - apps/ios/BuyLedgerUITests/PhotoViewerPagingTests.swift
  - apps/ios/BuyLedger/Shared/Media/PhotoDataProcessor.swift
  - apps/ios/BuyLedgerTests/SettingsFeatureTests.swift
  - shared/data-model/fixtures/expected/swift/SampleQuote.generated.swift
  - apps/ios/BuyLedger/Core/Persistence/CurrencyMetadataRecord.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersFeature.swift
  - apps/ios/BuyLedgerUITests/Tests/Tools/QuoteTests.swift
  - apps/ios/BuyLedgerTests/OrdersBatchOperationsTests.swift
  - apps/ios/BuyLedgerTests/LayerBoundaryTests.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersBatchOperations.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLSparkline.swift
  - shared/data-model/schema/CurrencyCode.yaml
  - apps/ios/BuyLedgerTests/CampaignSummaryTests.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestSeedData.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsView.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersCompactView.swift
  - apps/ios/BuyLedger/Core/Persistence/OrderRecord.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/States/DelayedProgressView.swift
  - apps/ios/CLAUDE.md
  - shared/data-model/schema/LedgerOrder.yaml
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/ViewModifiers/BLCardShadow.swift
  - apps/ios/BuyLedger/Features/Customers/CustomerRankBadgeStyle.swift
  - shared/data-model/fixtures/expected/kotlin/SampleSequence.kt
  - apps/ios/BuyLedger/Core/Domain/FxRates.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersMergeFlowOperations.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsFeature.swift
  - apps/ios/BuyLedger/Core/Domain/OrderMerge.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewBaseline.1.png
  - apps/ios/BuyLedger/Features/App/SidebarBadgeCounts.swift
  - apps/ios/BuyLedgerTests/ColorContrast.swift
  - apps/ios/BuyLedger/Features/Orders/Components/PaymentMethodEditorSheet.swift
  - apps/ios/BuyLedger.xcodeproj/xcshareddata/xcschemes/BuyLedger.xcscheme
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoThumbnail.swift
  - apps/ios/BuyLedgerUITests/Tests/Performance/LaunchPerformanceTests.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsStats.swift
  - apps/ios/BuyLedgerUITests/Tests/Customers/CustomersTests.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupKind.swift
  - apps/ios/BuyLedgerTests/AccessibilityConventionScanTests.swift
  - apps/ios/BuyLedger/Core/Dependencies/PaymentMethodRepository.swift
  - apps/ios/BuyLedgerTests/BLAccessibilityIDTests.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestSeedProfile.swift
  - shared/data-model/fixtures/schema/sample-orders.yaml
  - apps/ios/BuyLedger/Core/Testing/BLUITestConfiguration.swift
  - apps/ios/BuyLedger/App/AppDelegate.swift
  - apps/ios/BuyLedgerTests/BLUITestConfigurationTests.swift
  - apps/ios/BuyLedger/Core/Persistence/NameLookupPersistence.swift
  - apps/ios/BuyLedgerTests/QuoteFeatureTests.swift
  - apps/ios/BuyLedgerUITests/Screens/OrderDetailScreen.swift
  - apps/ios/BuyLedger/Features/Orders/OrderMergeFeature.swift
  - apps/ios/BuyLedgerTests/BiometricAuthClientTests.swift
  - apps/ios/BuyLedgerTests/CampaignFeatureTests.swift
  - apps/ios/BuyLedgerTests/BLFormattersTests.swift
  - apps/ios/BuyLedgerUITests/Support/SheetInteraction.swift
  - apps/ios/BuyLedger/Shared/Extensions/Image+Extensions.swift
  - shared/data-model/README.md
  - shared/data-model/fixtures/expected/swift/SampleSequence.generated.swift
  - apps/ios/BuyLedgerUITests/KeyboardDismissTests.swift
  - apps/ios/BuyLedger/Core/Persistence/OrderSourceRecord.swift
  - apps/ios/BuyLedgerUITests/Screens/CustomersScreen.swift
  - apps/ios/BuyLedgerTests/AppLockFeatureTests.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFilterSheet.swift
  - shared/data-model/fixtures/expected/swift/SampleStatus.generated.swift
  - apps/ios/BuyLedgerUITests/Screens/CampaignDetailScreen.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/AISummaryTests.swift
  - apps/ios/BuyLedgerUITests/Support/Diagnostics.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestHarness.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderEditDirtyTests.swift
  - apps/ios/BuyLedger/Resources/PrivacyInfo.xcprivacy
  - apps/ios/BuyLedger/Core/Domain/LedgerOrderItem.swift
  - shared/data-model/fixtures/expected/kotlin/SamplePreference.kt
  - apps/ios/BuyLedgerTests/CampaignReminderFailureTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrdersListTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Status/BLStatusPill.swift
  - apps/ios/BuyLedgerTests/CampaignIntegrationTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLPalette.swift
  - apps/ios/BuyLedger/Core/Domain/OrderSummary.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/PaymentMethodInfo.generated.swift
  - apps/ios/BuyLedger/Core/Dependencies/CampaignReminderRepository.swift
  - apps/ios/BuyLedger/Features/App/AppLockFeature.swift
  - apps/ios/BuyLedger/Core/Domain/FxRateSnapshot.swift
  - apps/ios/BuyLedger/Core/Persistence/CampaignRecord.swift
  - apps/ios/BuyLedger/Core/Persistence/CampaignPersistence.swift
  - apps/ios/BuyLedgerTests/BLPhotoViewerTests.swift
  - apps/ios/BuyLedgerTests/SchemaMigrationTests.swift
  - apps/ios/BuyLedgerUITests/Screens/MergeFlowScreen.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/LedgerOrder.generated.swift
tests:
  - shared/data-model/generator/test/datamodel-gen.test.ts
-->

---
### Requirement: Campaign management lives in a dedicated tab

The system SHALL present campaigns in a dedicated top-level tab. Creating, editing, renaming, deleting, and settling campaigns SHALL be performed within this tab and SHALL NOT appear in the lookup management surfaces used for product categories, order sources, payment methods, and reconciliation statuses.

#### Scenario: Open the campaign tab

- **WHEN** the user selects the campaign tab
- **THEN** the campaign list is shown with access to create a campaign


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
### Requirement: Campaign list shows progress derived from member orders

The system SHALL show, for each campaign, its status, order count, total charged amount, received amount, and delivery progress, all derived from its member orders. When there are no campaigns, the system SHALL show an empty state and SHALL NOT render placeholder data.

#### Scenario: List row shows derived progress

- **WHEN** the campaign list is displayed and a campaign has member orders
- **THEN** that campaign row shows its status, order count, total charged amount, received amount, and delivery progress

#### Scenario: No campaigns shows an empty state

- **WHEN** there are no campaigns
- **THEN** the campaign list shows an empty state


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
### Requirement: Campaign list groups campaigns by open date with selectable granularity

The campaign list SHALL group campaigns into sections by their open date, and SHALL let the user switch the grouping granularity among day, month, and year. When grouping by month, each month section SHALL be sub-grouped by day; when grouping by year, each year section SHALL be sub-grouped by month and each campaign row SHALL additionally display its open date. Within any group, campaigns SHALL be ordered by open date from newest to oldest, and campaigns with exactly the same open date SHALL be ordered by name.

The sections SHALL be derived from the campaign list feature's state rather than computed by the list view. Relative day titles ("今天", "昨天") SHALL be computed against the current date and calendar recorded in the campaign list feature's state from the injected date and calendar dependencies; the list view SHALL NOT read the current date itself. The recorded date SHALL be refreshed each time the list screen's appearance task runs, each time the app returns to the foreground, and each time the system reports a significant time change, such as the day changing while the app stays in the foreground, so that the titles follow the new day without the user leaving the list. Between these events the titles SHALL NOT change. Returning to the list from a campaign's detail is not guaranteed to run the appearance task.

#### Scenario: Switch grouping to month

- **WHEN** the user selects month grouping
- **THEN** the list shows top-level sections titled by month (for example "2026年5月"), each sub-grouped by day

#### Scenario: Year grouping keeps the open date visible

- **WHEN** the user selects year grouping
- **THEN** the list shows year sections sub-grouped by month AND each campaign row still shows its open date

#### Scenario: Relative day titles follow the recorded date

- **WHEN** the campaign list feature has recorded the current date
- **THEN** day sections whose date equals the recorded date are titled "今天", the previous day is titled "昨天", and older days in the same year show the month, day, and abbreviated weekday

##### Example: titles against a recorded date

- **GIVEN** day grouping, a recorded date of 2026-05-12 10:00 in a calendar fixed to UTC, the zh-Hant locale, and campaigns opened on 2026-05-12, 2026-05-11, and 2026-05-08 (a Friday)
- **WHEN** the list renders its sections
- **THEN** the section titles are "今天", "昨天", and the zh-Hant month-day-weekday form of 2026-05-08 (for example "5月8日週五") in that order

#### Scenario: Titles refresh when the app returns to the foreground

- **WHEN** the list has recorded a date, the app moves to the background, the day changes, and the app returns to the foreground
- **THEN** the recorded date is replaced with the current date when the app becomes active, without the list's appearance task running again

##### Example: returning after midnight

- **GIVEN** day grouping in a calendar fixed to UTC, a recorded date of 2026-05-12 10:00, and campaigns opened on 2026-05-12 and 2026-05-11
- **WHEN** the app goes to the background and returns to the foreground at 2026-05-13 00:30
- **THEN** the section for 2026-05-12 is titled "昨天" and the section for 2026-05-11 shows its zh-Hant month-day-weekday form (2026-05-11 is a Monday)

#### Scenario: Titles refresh when the day changes while the app stays in the foreground

- **WHEN** the list screen stays on screen in the foreground and the system reports a significant time change, such as passing midnight
- **THEN** the recorded date is replaced with the current date without the list's appearance task running again and without the app leaving the foreground

##### Example: midnight passes with the list on screen

- **GIVEN** day grouping in a calendar fixed to UTC, a recorded date of 2026-05-12 23:50, and a campaign opened on 2026-05-12
- **WHEN** the system reports a significant time change at 2026-05-13 00:00 while the list is on screen
- **THEN** the section for 2026-05-12 is titled "昨天"


<!-- @trace
source: campaigns-style-compliance
updated: 2026-10-04
code:
  - apps/ios/BuyLedger/App/Testing/BLUITestDependencyOverrides.swift
  - apps/ios/BuyLedger/Features/App/Data/SignificantTimeChangeService.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+CampaignDetail/campaignDetailView_只看未收款_符合基準圖.1.png
  - apps/ios/BuyLedgerTests/BLUITestConfigurationTests+InvalidValues.swift
  - apps/ios/BuyLedgerTests/HTTPClientTests.swift
  - apps/ios/BuyLedger/Features/App/SidebarBadgeCounts.swift
  - apps/ios/BuyLedgerAccessibilityIDs/BLAccessibilityID+Dashboard.swift
  - apps/ios/BuyLedgerTests/PaymentMethodServiceTests.swift
  - apps/ios/BuyLedgerUITests/Screens/CampaignDetailScreen+Toolbar.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderMergeTests.swift
  - apps/ios/BuyLedgerTests/SettingsFeatureTests.swift
  - apps/ios/BuyLedgerTests/CampaignReminderFeatureTests+Fixtures.swift
  - apps/ios/BuyLedgerTests/CampaignPresentationQueueTests.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+DeepLinks.swift
  - apps/ios/BuyLedgerUITests/Tests/Tools/FxTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderEditDirtyTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Lookups/moreViewMissingLookupManagementShowsUnavailableBaseline.1.png
  - apps/ios/BuyLedgerTests/RootFeatureTests+Campaigns.swift
  - apps/ios/BuyLedgerTests/ProjectionWriteBoundaryTests+Patterns.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignFormatters.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignWritesFeature.swift
  - apps/ios/BuyLedgerTests/CampaignReminderFeatureTests+Rebuild.swift
  - apps/ios/BuyLedgerTests/CampaignSavePlanTests+Conflicts.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+LookupSync.swift
  - apps/ios/BuyLedgerTests/FxRateSnapshotTests.swift
  - apps/ios/BuyLedgerTests/LocalizationCatalogTests.swift
  - apps/ios/BuyLedgerUITests/PhotoViewerPagingTests.swift
  - apps/ios/BuyLedgerTests/LocalizationCatalogTests+SourceGuards.swift
  - apps/ios/BuyLedgerTests/OrderServiceTests.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestLanguage.swift
  - apps/ios/BuyLedgerTests/BLAccessibilityIDTests.swift
  - apps/ios/BuyLedgerTests/CampaignReminderFeatureTests+Removal.swift
  - apps/ios/BuyLedgerTests/LayerBoundaryTests+SourceStripping.swift
  - apps/ios/BuyLedgerTests/LocalizationCatalogTests+LiteralScan.swift
  - apps/ios/BuyLedgerTests/PaymentMethodServiceTests+ApplyEdit.swift
  - apps/ios/BuyLedgerTests/PersistenceFailureFeatureTests.swift
  - apps/ios/BuyLedgerTests/TestSuiteIntegrityTests.swift
  - apps/ios/BuyLedgerTests/OrderSourceServiceTests.swift
  - apps/ios/BuyLedgerTests/AISummaryServiceTests+Transport.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignStatusStyle.swift
  - apps/ios/BuyLedgerTests/OrdersBatchOperationsTests.swift
  - apps/ios/BuyLedgerTests/ProjectionWriteBoundaryTests+RootProjections.swift
  - apps/ios/BuyLedger/Core/Domain/CampaignDistributionRow.swift
  - apps/ios/BuyLedgerTests/CampaignFeatureTests+ReminderRename.swift
  - apps/ios/BuyLedgerTests/DashboardStatsTests.swift
  - apps/ios/BuyLedger/Features/App/RootNavigationOperations.swift
  - apps/ios/BuyLedgerTests/AppScenePhaseCoordinatorTests.swift
  - apps/ios/BuyLedgerTests/CampaignReminderFeatureTests.swift
  - apps/ios/BuyLedger/Features/Campaigns/Components/CampaignDetailSettlementSection.swift
  - apps/ios/BuyLedgerTests/BLUITestConfigurationTests.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignPresentationQueue.swift
  - apps/ios/BuyLedgerTests/CampaignFeatureTests+ReloadDelete.swift
  - apps/ios/BuyLedgerTests/InsightsAttributionTests.swift
  - apps/ios/BuyLedgerTests/CampaignEditFeatureTests.swift
  - apps/ios/BuyLedgerTests/InsightsStatsTests.swift
  - apps/ios/BuyLedgerTests/MoreFeatureTests.swift
  - apps/ios/BuyLedgerTests/MoreFeatureTests+Relays.swift
  - apps/ios/BuyLedgerTests/CampaignListFeatureTests+AutoClose.swift
  - apps/ios/BuyLedgerTests/CampaignWritesFeatureTests+Rename.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignFeature+Destination.swift
  - apps/ios/BuyLedgerTests/PrivacyManifestTests.swift
  - AGENTS.md
  - apps/ios/BuyLedger/Features/Campaigns/Components/CampaignDetailInfoSection.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+AppShell.swift
  - apps/ios/BuyLedgerUITests/Tests/Campaigns/CampaignCrudTests.swift
  - apps/ios/BuyLedgerTests/PhotoDataProcessorTests.swift
  - apps/ios/BuyLedgerAccessibilityIDs/BLAccessibilityID+Common.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+PaymentMethodCorrection.swift
  - apps/ios/BuyLedgerTests/BuyLedgerDatabaseTests+Quarantine.swift
  - apps/ios/BuyLedgerTests/SchemaMigrationTests.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+Fixtures.swift
  - apps/ios/BuyLedgerTests/CampaignListFeatureTests+Loading.swift
  - apps/ios/BuyLedgerTests/FxRatesTests.swift
  - apps/ios/BuyLedgerTests/OrderServiceTests+MergeFailureMapping.swift
  - apps/ios/BuyLedgerTests/FxFeatureTests.swift
  - apps/ios/BuyLedgerTests/CampaignIntegrationTests+Navigation.swift
  - apps/ios/BuyLedgerTests/CampaignFeatureTests+Editing.swift
  - apps/ios/BuyLedgerTests/CampaignServiceTests+SaveFailure.swift
  - apps/ios/BuyLedgerTests/SnapshotTests+CampaignDetail.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestHarness.swift
  - apps/ios/BuyLedgerTests/CampaignFeatureTests+ReloadFixtures.swift
  - apps/ios/BuyLedgerTests/CampaignEditFeatureTests+Binding.swift
  - apps/ios/BuyLedgerTests/AISummaryFeatureTests.swift
  - apps/ios/BuyLedgerTests/CampaignListFeatureTests+Interactions.swift
  - apps/ios/BuyLedgerTests/CampaignServiceTests.swift
  - apps/ios/BuyLedgerTests/OrdersFeatureTests.swift
  - apps/ios/BuyLedger/Resources/Localizable.xcstrings
  - apps/ios/BuyLedgerTests/CampaignServiceTests+DeleteFailure.swift
  - apps/ios/BuyLedgerTests/OrderMergeTests.swift
  - apps/ios/BuyLedger/Features/App/PersistenceFailureView.swift
  - apps/ios/BuyLedgerTests/SignificantTimeChangeServiceTests.swift
  - apps/ios/BuyLedger/Features/App/Data/BiometricAuthService+Dependency.swift
  - apps/ios/BuyLedgerUITests/Tests/Tools/QuoteTests.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignView.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignReminderFeature.swift
  - apps/ios/BuyLedgerTests/CurrencyMetadataServiceTests+SaveFailure.swift
  - apps/ios/BuyLedger/Features/Campaigns/Data/CampaignService+Dependency.swift
  - apps/ios/BuyLedgerTests/CampaignWritesFeatureTests+Save.swift
  - apps/ios/BuyLedgerTests/CurrencyDisplayNameTests.swift
  - apps/ios/BuyLedgerTests/ReconciliationStatusServiceTests.swift
  - apps/ios/BuyLedgerTests/OrderStatusTests.swift
  - apps/ios/BuyLedgerTests/CampaignDetailContentTests.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignReminderRequest.swift
  - apps/ios/BuyLedgerTests/CampaignFeatureTests+Fixtures.swift
  - apps/ios/BuyLedgerTests/BuyLedgerDatabaseTests.swift
  - apps/ios/BuyLedgerTests/LookupCatalogTests.swift
  - apps/ios/BuyLedger/Core/Dependencies/CampaignService.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignListFeature.swift
  - apps/ios/BuyLedgerTests/PersistenceErrorTests.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestLoadFailure.swift
  - apps/ios/BuyLedgerTests/AccessibilityConventionScanTests.swift
  - apps/ios/BuyLedgerTests/LookupManagementFeatureTests+Failures.swift
  - apps/ios/BuyLedgerTests/CampaignWritesFeatureTests+Status.swift
  - apps/ios/BuyLedgerTests/SnapshotTests+CampaignFixtures.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsView.swift
  - apps/ios/BuyLedger/Features/App/Data/BiometricAuthService.swift
  - apps/ios/BuyLedgerTests/OrderServiceTests+BatchWrites.swift
  - apps/ios/BuyLedger/Features/More/MoreFeature.swift
  - apps/ios/BuyLedger/Features/App/SidebarSmartGroup.swift
  - apps/ios/BuyLedgerTests/LookupManagementFeatureTests+AlertTiming.swift
  - apps/ios/BuyLedger/Features/Campaigns/Components/CampaignSectionList.swift
  - apps/ios/BuyLedger/Features/Campaigns/Data/CampaignService+Preview.swift
  - apps/ios/BuyLedgerTests/OrderServiceTests+Reads.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+CampaignDetail/campaignEditView_編輯既有開團_符合基準圖.1.png
  - apps/ios/BuyLedgerTests/CampaignFeatureTests+NameConflict.swift
  - apps/ios/BuyLedger/Core/Dependencies/BiometricAuthService+Dependency.swift
  - apps/ios/BuyLedgerTests/BLPhotoViewerTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Smoke/AppLockTests.swift
  - apps/ios/BuyLedgerTests/CampaignReminderServiceTests.swift
  - apps/ios/BuyLedgerTests/LayerBoundaryTests+FileScan.swift
  - apps/ios/BuyLedgerTests/CampaignFeatureTests+UnchangedName.swift
  - apps/ios/BuyLedger/Features/App/RootTab.swift
  - apps/ios/BuyLedgerTests/ProjectionWriteBoundaryTests+SourceStripping.swift
  - apps/ios/BuyLedgerUITests/Screens/CampaignDetailScreen.swift
  - apps/ios/BuyLedgerTests/DependencyConventionScanTests.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsFeature+Destination.swift
  - apps/ios/BuyLedgerUITests/Tests/Campaigns/CampaignListTests.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignSectionTitle.swift
  - apps/ios/BuyLedgerTests/OrderServiceTests+Renames.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Campaigns/campaignListView_載入失敗_符合基準圖.1.png
  - apps/ios/BuyLedgerTests/ActionGroupingScanTests.swift
  - apps/ios/BuyLedger/App/Testing/DependencyValues+BLUITestOverrides.swift
  - apps/ios/BuyLedgerTests/PaymentMethodCorrectionFeatureTests.swift
  - apps/ios/BuyLedger/Features/App/AppScenePhaseCoordinator.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Campaigns/campaignListView_英文月分組_符合基準圖.1.png
  - apps/ios/BuyLedger/App/Testing/BLUITestConfiguration.swift
  - apps/ios/BuyLedger/Features/App/AppScenePhase.swift
  - apps/ios/BuyLedgerTests/OrderServiceResidueTests.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignDetailFeature.swift
  - apps/ios/BuyLedgerTests/AppConfigurationStoreTests.swift
  - apps/ios/BuyLedgerTests/QuoteFeatureTests.swift
  - apps/ios/BuyLedgerUITests/Screens/CampaignDetailScreen+Content.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderCreateTests.swift
  - apps/ios/BuyLedgerTests/CampaignSummaryTests.swift
  - apps/ios/BuyLedgerTests/DashboardFeatureTests.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestPersistenceMode.swift
  - apps/ios/BuyLedgerTests/CampaignDateSectionBuilderTests+Ordering.swift
  - apps/ios/BuyLedgerTests/OrderServiceTests+WriteFailures.swift
  - apps/ios/BuyLedgerTests/CategoryServiceTests.swift
  - apps/ios/BuyLedgerTests/OrderEditFeatureTests.swift
  - apps/ios/BuyLedgerTests/ActionGroupingScanTests+Scanner.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignSubgroup.swift
  - apps/ios/BuyLedger/Features/Campaigns/Data/CampaignService.swift
  - apps/ios/BuyLedgerTests/OrdersSearchCancellationTests.swift
  - apps/ios/BuyLedgerTests/SnapshotTests+Campaigns.swift
  - apps/ios/BuyLedgerTests/ActionGroupingScanTests+Scenarios.swift
  - apps/ios/BuyLedgerTests/CampaignIntegrationTests+Delete.swift
  - apps/ios/BuyLedgerAccessibilityIDs/BLAccessibilityID.swift
  - apps/ios/BuyLedgerTests/ContrastComplianceTests.swift
  - apps/ios/BuyLedgerTests/CampaignIntegrationTests.swift
  - apps/ios/BuyLedgerTests/SnapshotTests+Lookups.swift
  - apps/ios/BuyLedger/Features/App/RootSidebarLayout.swift
  - apps/ios/BuyLedgerTests/SourceTextScannerTests.swift
  - apps/ios/BuyLedgerAccessibilityIDs/BLAccessibilityID+Orders.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/AISummaryTests.swift
  - apps/ios/BuyLedgerTests/BLFormattersTests.swift
  - apps/ios/BuyLedgerTests/OrderMergeFeatureTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Smoke/HarnessSelfCheckTests.swift
  - apps/ios/BuyLedgerTests/TestDependencies+Calendar.swift
  - apps/ios/BuyLedgerTests/StorageFailureWrappingTests.swift
  - apps/ios/BuyLedgerTests/Campaign+Fixture.swift
  - apps/ios/BuyLedgerTests/CampaignDetailFeatureTests.swift
  - apps/ios/BuyLedgerTests/CampaignReminderRequestTests.swift
  - apps/ios/BuyLedgerTests/RuntimeEnvironmentTests.swift
  - apps/ios/BuyLedgerTests/CampaignEditFeatureTests+Init.swift
  - apps/ios/BuyLedgerTests/CampaignReminderFeatureTests+Failures.swift
  - apps/ios/README.md
  - apps/ios/BuyLedgerTests/SnapshotTests.swift
  - apps/ios/BuyLedger/Features/App/AppLockFeature.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignReminderReconcile.swift
  - apps/ios/BuyLedgerTests/CampaignDateSectionBuilderTests.swift
  - apps/ios/BuyLedgerTests/CustomersFeatureTests.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignDraft.swift
  - apps/ios/BuyLedgerTests/CampaignReminderFailureTests.swift
  - apps/ios/BuyLedgerTests/CampaignSummaryTests+Delivery.swift
  - apps/ios/BuyLedgerTests/OrderServiceTests+Writes.swift
  - apps/ios/BuyLedgerUITests/KeyboardDismissTests.swift
  - apps/ios/BuyLedger/Features/App/RootTabLayout.swift
  - apps/ios/BuyLedgerAccessibilityIDs/BLAccessibilityID+App.swift
  - apps/ios/BuyLedgerTests/OrdersFeatureTests+AIDisabledAlert.swift
  - apps/ios/BuyLedger/Features/More/MoreView.swift
  - apps/ios/BuyLedgerUITests/Tests/Customers/CustomersTests.swift
  - apps/ios/BuyLedgerTests/LayerBoundaryTests.swift
  - apps/ios/BuyLedgerTests/CalendarReminderTests.swift
  - apps/ios/BuyLedger/Features/App/PersistenceFailureFeature.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignEditFeature.swift
  - apps/ios/BuyLedgerTests/CampaignFeatureTests.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignDateContext.swift
  - apps/ios/BuyLedgerTests/OrderServiceTests+Concurrency.swift
  - apps/ios/BuyLedgerTests/APIErrorMappingTests.swift
  - .github/workflows/ci.yml
  - apps/ios/BuyLedgerTests/OrdersFilterOperationsTests.swift
  - apps/ios/BuyLedgerTests/LookupManagementFeatureTests+PaymentMethodCorrection.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignEditView.swift
  - apps/ios/BuyLedgerTests/CampaignFeatureTests+Writes.swift
  - apps/ios/BuyLedger.xcodeproj/project.pbxproj
  - apps/ios/BuyLedger/Core/Dependencies/CampaignService+Dependency.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestBiometricScenario.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignDateSection.swift
  - apps/ios/BuyLedgerTests/CurrencyMetadataServiceTests.swift
  - apps/ios/BuyLedgerTests/String+SourceLiteralScan.swift
  - apps/ios/BuyLedgerUITests/Tests/Smoke/LaunchSmokeTests.swift
  - apps/ios/BuyLedger/Core/Dependencies/BiometricAuthService.swift
  - apps/ios/BuyLedger/Core/Domain/CampaignSummary.swift
  - apps/ios/BuyLedgerTests/LookupManagementFeatureTests+Forms.swift
  - apps/ios/BuyLedgerTests/OrderEditFocusTests.swift
  - apps/ios/BuyLedgerTests/ColorContrastTests.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignListView.swift
  - apps/ios/BuyLedger/Features/App/AppLockFormatters.swift
  - apps/ios/BuyLedgerTests/AppLockFeatureTests+Formatters.swift
  - apps/ios/BuyLedger/Features/App/Data/BiometricAuthService+Preview.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignDateSectionBuilder.swift
  - apps/ios/BuyLedger/Features/App/RootCascadeOperations.swift
  - apps/ios/BuyLedger/Features/App/Data/SignificantTimeChangeService+Dependency.swift
  - apps/ios/BuyLedgerTests/CampaignSummaryTests+Membership.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+OrderFilters.swift
  - apps/ios/BuyLedgerTests/BiometricAuthServiceTests.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+Sidebar.swift
  - apps/ios/BuyLedger/Features/App/RootView.swift
  - apps/ios/BuyLedgerTests/AISummaryServiceTests.swift
  - apps/ios/BuyLedgerTests/SourceTextScanner.swift
  - apps/ios/BuyLedgerTests/BuyLedgerDatabaseTests+Preview.swift
  - apps/ios/BuyLedgerTests/CampaignListFeatureTests.swift
  - apps/ios/BuyLedgerTests/CurrencyMetadataServiceTests+Refresh.swift
  - apps/ios/BuyLedgerTests/CustomerRowTests.swift
  - apps/ios/BuyLedger/App/BuyLedgerApp.swift
  - apps/ios/BuyLedgerTests/AppLockFeatureTests.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignFeature.swift
  - apps/ios/BuyLedgerTests/NumericInputGroupingScanTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Campaigns/campaignListView_依月分組_符合基準圖.1.png
  - apps/ios/BuyLedger/Features/Campaigns/CampaignRequest.swift
  - apps/ios/BuyLedgerTests/CampaignFeatureTests+DeletionReminder.swift
  - apps/ios/BuyLedgerTests/PersistenceRecoveryServiceTests.swift
  - apps/ios/BuyLedgerTests/CampaignFeatureTests+Navigation.swift
  - apps/ios/BuyLedgerTests/OrderCalculationTests.swift
  - apps/ios/BuyLedgerTests/PersistenceRecoveryTests.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersFeature.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsFeature.swift
  - apps/ios/BuyLedgerTests/CampaignFeatureTests+ReminderIntegration.swift
  - apps/ios/BuyLedgerTests/CampaignIntegrationTests+Receipt.swift
  - apps/ios/BuyLedgerTests/ProjectionWriteBoundaryTests.swift
  - apps/ios/BuyLedgerTests/UserDefaultsStoreTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Campaigns/CampaignDetailTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrdersListTests.swift
  - apps/ios/BuyLedgerTests/CampaignServiceTests+Decoding.swift
  - apps/ios/BuyLedgerTests/CampaignIntegrationTests+Fixtures.swift
  - apps/ios/BuyLedger/Features/App/Data/SignificantTimeChangeService+Preview.swift
  - apps/ios/BuyLedger/Features/Customers/CustomersFeature.swift
  - apps/ios/BuyLedgerTests/CampaignIntegrationTests+Filters.swift
  - apps/ios/BuyLedgerTests/DesignSystemSourceScanTests.swift
  - apps/ios/BuyLedgerTests/CampaignWritesFeatureTests+Settle.swift
  - apps/ios/BuyLedger/Features/App/AppLockView.swift
  - apps/ios/BuyLedgerTests/ExchangeRateServiceTests.swift
  - apps/ios/BuyLedger/Features/Customers/CustomersView.swift
  - apps/ios/BuyLedgerTests/CampaignIntegrationTests+Rename.swift
  - apps/ios/BuyLedgerUITests/Support/LaunchOptions.swift
  - apps/ios/BuyLedgerTests/OrderServiceTests+Decoding.swift
  - apps/ios/BuyLedgerTests/LocalizationCatalogTests+AppLanguage.swift
  - apps/ios/BuyLedgerTests/InsightsFeatureTests.swift
  - apps/ios/BuyLedgerTests/CampaignFeatureTests+Presentation.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignDetailView.swift
  - apps/ios/BuyLedgerTests/OrderServiceTests+RenameNoOps.swift
  - apps/ios/BuyLedgerUITests/Screens/CampaignsScreen.swift
  - apps/ios/BuyLedgerTests/CampaignSavePlanTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Performance/LaunchPerformanceTests.swift
  - apps/ios/BuyLedgerTests/CampaignFeatureTests+Reload.swift
  - apps/ios/BuyLedgerTests/AppScenePhaseTests.swift
  - apps/ios/BuyLedger/Core/Dependencies/BiometricAuthService+Preview.swift
  - apps/ios/BuyLedger/Features/Campaigns/Components/CampaignRow.swift
  - apps/ios/BuyLedgerTests/CampaignFeatureTests+ReminderCancellation.swift
  - apps/ios/BuyLedgerAccessibilityIDs/BLAccessibilityID+More.swift
  - apps/ios/BuyLedgerAccessibilityIDs/BLAccessibilityID+Insights.swift
  - apps/ios/BuyLedgerTests/LayerBoundaryTests+Scanner.swift
  - apps/ios/BuyLedgerTests/OrdersLoadStateTests.swift
  - apps/ios/BuyLedgerTests/OrderServiceTests+RenameFailures.swift
  - apps/ios/BuyLedgerTests/CampaignWritesFeatureTests.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+LookupRename.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+CampaignDetail/campaignDetailView_一般開團含提醒_符合基準圖.1.png
  - apps/ios/BuyLedger/Features/Campaigns/CampaignFeature+Path.swift
  - apps/ios/BuyLedgerTests/CampaignFeatureTests+ReminderFixtures.swift
  - apps/ios/BuyLedgerTests/LayerBoundaryTests+Patterns.swift
  - apps/ios/BuyLedgerTests/CampaignListFeatureTests+DateContext.swift
  - apps/ios/BuyLedgerTests/OrdersFeaturePerformanceTests.swift
  - apps/ios/BuyLedgerTests/ServiceTestValueStrictnessTests.swift
  - apps/ios/BuyLedgerTests/CampaignFeatureTests+FailureTiming.swift
  - apps/ios/BuyLedgerTests/ProjectionWriteBoundaryTests+Scanner.swift
  - apps/ios/BuyLedger/Features/Campaigns/Components/CampaignDetailDistributionSection.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignDetailContent.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests.swift
  - apps/ios/BuyLedgerTests/CampaignReminderReconcileTests.swift
  - apps/ios/BuyLedgerTests/SettingsServiceTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderDetailTests.swift
  - apps/ios/BuyLedgerTests/CampaignFeatureTests+WriteFailures.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Campaigns/campaignListView_依日分組含今天與昨天_符合基準圖.1.png
  - apps/ios/BuyLedger/Features/Campaigns/CampaignSavePlan.swift
  - apps/ios/BuyLedgerTests/OrderServiceTests+Create.swift
  - apps/ios/BuyLedgerTests/LookupManagementFeatureTests.swift
  - apps/ios/BuyLedgerUITests/Screens/CampaignEditScreen.swift
  - apps/ios/BuyLedgerTests/CampaignServiceTests+Delete.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignSummary.swift
  - apps/ios/BuyLedgerUITests/Tests/More/LookupManagementTests.swift
  - apps/ios/BuyLedgerTests/OrderDraftTests.swift
  - apps/ios/BuyLedgerTests/SettingsFeatureTests+AppLock.swift
  - apps/ios/BuyLedgerTests/AppLanguageTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Tools/CurrencyPickerTests.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestCalendarAccess.swift
  - apps/ios/BuyLedgerAccessibilityIDs/BLAccessibilityID+Campaigns.swift
  - apps/ios/BuyLedgerTests/OrderServiceTests+Merge.swift
  - apps/ios/BuyLedgerUITests/Tests/Campaigns/CampaignFlowTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Campaigns/campaignListView_依年分組_符合基準圖.1.png
  - apps/ios/CLAUDE.md
  - apps/ios/BuyLedgerTests/CampaignDateSectionBuilderTests+SectionTitle.swift
  - apps/ios/BuyLedgerTests/CampaignWritesFeatureTests+Delete.swift
  - apps/ios/BuyLedgerUITests/Tests/Insights/InsightsTests.swift
  - apps/ios/BuyLedgerTests/BuyLedgerDatabaseTests+WriteFailures.swift
  - apps/ios/BuyLedger/Features/App/RootFeature.swift
  - apps/ios/BuyLedger/Core/Dependencies/CampaignService+Preview.swift
-->

---
### Requirement: Campaign list filters by status

The campaign list SHALL provide a status filter with three options: all, ongoing, and closed. Selecting ongoing or closed SHALL show only campaigns whose status matches; selecting all SHALL show every campaign. When the active filter matches no campaign, the list SHALL show an empty state. The status filter SHALL compose with the date grouping so that filtered campaigns are still grouped by open date.

#### Scenario: Filter to ongoing campaigns

- **WHEN** the user selects the ongoing status filter
- **THEN** only campaigns whose status is ongoing are listed

#### Scenario: Filter matches no campaign

- **WHEN** the active status filter matches no campaign
- **THEN** the list shows an empty state


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
### Requirement: Settlement summary aggregates member orders

The system SHALL compute a campaign settlement from its member orders: receivables (sum of charged amounts), received (sum of charged amounts of orders marked received), outstanding (receivables minus received), and profitability figures (total cost, profit, margin) reusing the existing order summary aggregation. When receivables is zero, derived ratios SHALL be zero and the system SHALL NOT divide by zero.

#### Scenario: Settlement totals

- **WHEN** a campaign with member orders is settled or viewed
- **THEN** the settlement shows receivables, received, outstanding, total cost, profit, and margin

##### Example: settlement figures

- **GIVEN** a campaign with orders O1(charged=1000, received) and O2(charged=500, pending)
- **WHEN** the settlement is computed
- **THEN** receivables = 1500 AND received = 1000 AND outstanding = 500


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
### Requirement: Distribution groups member orders by customer

The system SHALL group a campaign's member orders by customer name, trimmed of surrounding whitespace, summing item quantities and charged amounts per customer. A customer SHALL be marked fully received only when all of that customer's orders in the campaign are marked received. The system SHALL support viewing only the customers that are not fully received.

#### Scenario: Group by customer

- **WHEN** the campaign distribution is computed
- **THEN** each row represents one customer with summed item quantity, summed charged amount, and a fully-received marker

##### Example: distribution grouping

- **GIVEN** orders A("小明", quantity=2, charged=600, received), B("小明", quantity=1, charged=300, pending), C("小華", quantity=1, charged=400, received)
- **WHEN** the distribution is computed
- **THEN** "小明" shows quantity 3, amount 900, not fully received AND "小華" shows quantity 1, amount 400, fully received

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
### Requirement: Campaign detail unpaid-only view filter persists across navigation

The campaign detail distribution's "unpaid only" view filter (which restricts the distribution list to customers that are not fully received) SHALL be owned by feature state rather than transient view-local state. While the app is running, its value SHALL persist when the user navigates away from a campaign detail and reopens a campaign detail, and SHALL NOT reset to showing all customers on return. Toggling the filter SHALL update feature state through a dedicated action.

#### Scenario: Unpaid-only filter persists across leaving and re-entering detail

- **WHEN** the user enables "unpaid only" on a campaign detail, navigates back to the campaign list, and reopens a campaign detail
- **THEN** the "unpaid only" filter is still enabled

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