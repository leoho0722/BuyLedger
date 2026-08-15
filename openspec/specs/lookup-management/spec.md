# lookup-management Specification

## Purpose

TBD - created by archiving change 'lookup-management-macos-card-style'. Update Purpose after archive.

## Requirements

### Requirement: Platform-adaptive lookup management presentation

The lookup management screen (used for order source, category, and payment method) SHALL render a system List on iOS and iPadOS. The presentation MUST NOT change the available operations or the underlying data.

#### Scenario: iOS and iPadOS keep the system List

- **WHEN** the order source, category, or payment method management screen is shown on iOS or iPadOS
- **THEN** the screen presents the system List with a section header, trailing swipe actions for delete and rename, and the existing footer, unchanged from before this change

---
### Requirement: Lookup item management operations are preserved across platforms

The screen SHALL allow the user to add, rename, and delete lookup items on iOS and iPadOS. The add, rename, and delete operations and their validation SHALL behave identically on both, and SHALL write through the same management feature as before this change.

Each operation SHALL take effect for every consumer of that lookup kind as part of the same state update, rather than through separate synchronization performed by the root feature. Persistence behavior is unchanged: the operation is written to the store, and the destructive path continues to update state only after the write succeeds.

When a lookup management screen cannot be resolved for a requested kind, the screen SHALL present the existing load-failure view rather than rendering blank, so that a resolution failure is visible rather than silent.

#### Scenario: Add a lookup item

- **WHEN** the user activates the toolbar add control and confirms a non-empty, trimmed name
- **THEN** the item is added through the management feature and appears in the list

#### Scenario: Rename a lookup item

- **WHEN** the user triggers rename on an item and confirms a non-empty name different from the original
- **THEN** the item is renamed through the management feature and orders referencing the old name are updated

#### Scenario: Delete a lookup item

- **WHEN** the user triggers delete on an item
- **THEN** the item is removed through the management feature

#### Scenario: iOS swipe-to-delete is retained

- **WHEN** the user swipes an item row on iOS or iPadOS
- **THEN** the swipe actions for delete and rename are available, unchanged from before this change

#### Scenario: An unresolvable management screen is visibly failed, not blank

- **WHEN** the management screen for a requested lookup kind cannot be resolved
- **THEN** the load-failure view is shown instead of an empty screen


<!-- @trace
source: lookup-single-source-of-truth
updated: 2026-08-15
code:
  - apps/ios/BuyLedgerUITests/Support/LaunchOptions.swift
  - shared/data-model/fixtures/expected/typescript/SampleProfile.ts
  - apps/ios/BuyLedgerUITests/Screens/OrderDetailScreen.swift
  - apps/ios/BuyLedger/Resources/Info.plist
  - apps/ios/BuyLedgerUITests/Screens/CustomersScreen.swift
  - apps/ios/BuyLedger/Core/Dependencies/CampaignRepository.swift
  - shared/data-model/schema/OrderStatus.yaml
  - apps/ios/BuyLedger/Features/AISummary/AISummaryFeature.swift
  - apps/ios/BuyLedger/Features/Customers/CustomersFeature.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/CurrencyCode.generated.swift
  - apps/ios/BuyLedger/Features/More/MoreView.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLDonutSegment.swift
  - apps/ios/BuyLedger/Features/App/SidebarBadgeCounts.swift
  - apps/ios/BuyLedgerTests/OrderMergeTests.swift
  - apps/ios/BuyLedgerTests/ExchangeRateClientTests.swift
  - apps/ios/BuyLedgerUITests/PhotoViewerPagingTests.swift
  - apps/ios/BuyLedger/Shared/Extensions/Color+Extensions.swift
  - apps/ios/BuyLedger/Core/Testing/BLUITestDependencyOverrides.swift
  - apps/ios/BuyLedger/Features/FX/FxFeature.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersFeature.swift
  - apps/ios/BuyLedgerUITests/Screens/OrdersScreen.swift
  - apps/ios/BuyLedger/Core/Testing/BLUITestSeedProfile.swift
  - apps/ios/BuyLedgerTests/BLPhotoViewerTests.swift
  - apps/ios/BuyLedger/Core/Dependencies/TelemetryClient.swift
  - apps/ios/BuyLedgerTests/BLFormattersTests.swift
  - apps/ios/BuyLedgerUITests/Screens/AppLockScreen.swift
  - apps/ios/BuyLedger/Features/Quote/QuoteFeature.swift
  - apps/ios/BuyLedgerUITests/Support/TextInput.swift
  - apps/ios/BuyLedger/Core/Persistence/NameLookupPersistence.swift
  - apps/ios/BuyLedger/Core/Dependencies/CampaignReminderRepository.swift
  - apps/ios/BuyLedgerTests/DashboardStatsTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderCreateTests.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignSummary.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/States/BLDelayedProgressView.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsSnapshot.swift
  - apps/ios/BuyLedger/Core/Persistence/PersistenceContainer.swift
  - apps/ios/BuyLedgerTests/AppScenePhaseCoordinatorTests.swift
  - apps/ios/BuyLedgerUITests/Support/Scrolling.swift
  - apps/ios/BuyLedger/Core/Persistence/PaymentMethodRecord.swift
  - apps/ios/BuyLedger/Resources/InfoPlist.xcstrings
  - apps/ios/BuyLedgerUITests/Tests/Orders/AISummaryTests.swift
  - apps/ios/BuyLedgerTests/ColorContrast.swift
  - shared/data-model/schema/CustomerTier.yaml
  - apps/ios/BuyLedgerUITests/Screens/Screen.swift
  - apps/ios/BuyLedger.xcodeproj/xcshareddata/xcschemes/BuyLedger.xcscheme
  - apps/ios/BuyLedgerUITests/Support/AppNavigator.swift
  - apps/ios/BuyLedger/Core/Dependencies/ReconciliationStatusRepository.swift
  - apps/ios/BuyLedger/Core/Domain/LedgerOrder.swift
  - apps/ios/BuyLedger/Features/Customers/CustomerRankBadgeStyle.swift
  - apps/ios/BuyLedger/Core/Dependencies/OrderSourceRepository.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsFeature.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderStatus+Presentation.swift
  - apps/ios/BuyLedger/Core/Persistence/OrderRecord.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardView.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Cards/BLCard.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestConfiguration.swift
  - apps/ios/BuyLedger/Features/AISummary/AISummaryView.swift
  - apps/ios/BuyLedger/App/AppDelegate.swift
  - apps/ios/BuyLedgerTests/CurrencyMetadataCacheTests.swift
  - apps/ios/BuyLedger/Shared/Localization/AppLanguage.swift
  - shared/data-model/schema/PaymentReceiptStatus.yaml
  - apps/ios/BuyLedger/Features/FX/ExchangeRateDTO.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderMergeCandidateSheet.swift
  - shared/data-model/fixtures/expected/typescript/SampleGrade.ts
  - apps/ios/BuyLedgerUITests/Tests/Smoke/HarnessSelfCheckTests.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/FxRateSnapshot.generated.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLSparkline.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/LedgerCustomer.generated.swift
  - apps/ios/BuyLedgerTests/OllamaClientTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/ViewModifiers/BLTypographyModifier.swift
  - shared/data-model/fixtures/expected/kotlin/SamplePreference.kt
  - apps/ios/BuyLedger/Features/App/RootTab.swift
  - apps/ios/BuyLedger/Core/Dependencies/OrderRepository.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLBarChart.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersFeature+StateQuery.swift
  - apps/ios/BuyLedgerTests/CalendarReminderTests.swift
  - apps/ios/BuyLedgerUITests/Screens/QuoteScreen.swift
  - apps/ios/BuyLedgerTests/PersistenceFailureFeatureTests.swift
  - shared/data-model/fixtures/expected/swift/SampleQuote.generated.swift
  - apps/ios/BuyLedgerTests/InsightsAttributionTests.swift
  - apps/ios/BuyLedgerUITests/Screens/SettingsScreen.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestDependencyOverrides.swift
  - apps/ios/BuyLedger/Core/Domain/OrderSummary.swift
  - apps/ios/BuyLedgerTests/BLUITestConfigurationTests.swift
  - apps/ios/BuyLedger/Core/Dependencies/NameLookupOperations.swift
  - apps/ios/BuyLedgerTests/LookupCatalogTests.swift
  - apps/ios/BuyLedgerTests/InsightsStatsTests.swift
  - apps/ios/BuyLedgerTests/OrderStatusTests.swift
  - apps/ios/BuyLedger.xctestplan
  - shared/data-model/fixtures/expected/swift/SampleGrade.generated.swift
  - apps/ios/BuyLedger/Core/Sync/SyncMeta.swift
  - apps/ios/BuyLedger/Core/Domain/FxRateSnapshot.swift
  - apps/ios/BuyLedger/Features/App/RootView.swift
  - shared/data-model/fixtures/expected/swift/SampleStatus.generated.swift
  - apps/ios/BuyLedger/Shared/Extensions/Bundle+Extensions.swift
  - apps/ios/BuyLedger/Core/Persistence/OrderPersistence.swift
  - apps/ios/BuyLedgerTests/TestDependencies.swift
  - shared/data-model/schema/LedgerOrderItem.yaml
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementDestination.swift
  - apps/ios/BuyLedgerUITests/Support/Waiting.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrdersListTests.swift
  - apps/ios/BuyLedgerUITests/Screens/InsightsScreen.swift
  - apps/ios/BuyLedgerUITests/Screens/CampaignEditScreen.swift
  - apps/ios/BuyLedger/Resources/Localizable.xcstrings
  - apps/ios/BuyLedger/Features/Orders/Components/PaymentMethodEditorSheet.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/Money.generated.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderDetailView.swift
  - apps/ios/BuyLedger/Core/Persistence/CurrencyMetadataPersistence.swift
  - apps/ios/BuyLedgerUITests/Support/Assertions.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestSeedProfile.swift
  - apps/ios/BuyLedger/Features/FX/FxView.swift
  - apps/ios/BuyLedgerTests/CampaignSummaryTests.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLMetrics.swift
  - apps/ios/BuyLedgerTests/OrderEditFeatureTests.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupKind.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/quoteViewBaseline.1.png
  - apps/ios/BuyLedger/Shared/Media/PhotoDataProcessor.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderSelectableRow.swift
  - apps/ios/BuyLedger/Core/Dependencies/OpenSettingsClient.swift
  - apps/ios/BuyLedgerUITests/Tests/Campaigns/CampaignCrudTests.swift
  - apps/ios/BuyLedgerTests/AppLockFeatureTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/ViewModifiers/BLHeroCardBackground.swift
  - apps/ios/BuyLedgerTests/AISummaryFeatureTests.swift
  - apps/ios/BuyLedger/Features/Quote/QuoteView.swift
  - apps/ios/BuyLedger/Core/Domain/LedgerOrderItem.swift
  - apps/ios/BuyLedger/Features/App/AppScenePhaseCoordinator.swift
  - apps/ios/BuyLedger/Core/Networking/HTTPMethod.swift
  - apps/ios/BuyLedgerTests/CampaignEditFeatureTests.swift
  - apps/ios/BuyLedgerUITests/Screens/MergeFlowScreen.swift
  - AGENTS.md
  - apps/ios/BuyLedgerUITests/Screens/PhotoViewerScreen.swift
  - apps/ios/BuyLedgerTests/InsightsFeatureTests.swift
  - shared/data-model/fixtures/expected/typescript/SampleStatus.ts
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLTone.swift
  - apps/ios/BuyLedger/Features/Orders/OrderDetailPath.swift
  - apps/ios/BuyLedger/Core/Persistence/CurrencyMetadataRecord.swift
  - apps/ios/BuyLedger/Core/Persistence/PaymentMethodPersistence.swift
  - shared/data-model/fixtures/expected/kotlin/SampleProfile.kt
  - apps/ios/BuyLedgerTests/CampaignIntegrationTests.swift
  - apps/ios/BuyLedgerTests/OrderDraftTests.swift
  - apps/ios/BuyLedger/Resources/GoogleService-Info.example.plist
  - shared/data-model/schema/LedgerCustomer.yaml
  - apps/ios/BuyLedger/Features/Orders/LedgerOrder+OrderMutation.swift
  - apps/ios/BuyLedgerTests/CampaignPersistenceTests.swift
  - apps/ios/BuyLedgerUITests/Support/BLUITestCase.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/CampaignStatus.generated.swift
  - apps/ios/BuyLedger/Features/FX/ExchangeRateClient.swift
  - apps/ios/BuyLedgerTests/AccessibilityConventionScanTests.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersMergeFlowOperations.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsFeature.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLBarChartValue.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLStatusHue.swift
  - apps/ios/BuyLedger/Core/Domain/Campaign+Samples.swift
  - apps/ios/BuyLedgerTests/ProjectionWriteBoundaryTests.swift
  - shared/data-model/fixtures/expected/typescript/SamplePreference.ts
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/dashboardViewBaseline.1.png
  - apps/ios/BuyLedger/Core/Persistence/BuyLedgerSchema.swift
  - apps/ios/BuyLedger/Features/Orders/OrderMergeFeature.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/OrderStatus.generated.swift
  - apps/ios/BuyLedgerTests/ContrastComplianceTests.swift
  - shared/data-model/fixtures/expected/kotlin/SampleSequence.kt
  - apps/ios/BuyLedger/Core/Persistence/OrderSourcePersistence.swift
  - apps/ios/BuyLedger/Resources/PrivacyInfo.xcprivacy
  - shared/data-model/schema/Money.yaml
  - apps/ios/BuyLedgerTests/OrderCalculationTests.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestSeedData.swift
  - apps/ios/BuyLedgerTests/OrderPersistenceTests.swift
  - apps/ios/BuyLedger/Features/App/RootTabLayout.swift
  - apps/ios/BuyLedger/Core/Networking/URLRequestBuilder.swift
  - apps/ios/BuyLedger/Features/App/RootFeature.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersView.swift
  - apps/ios/BuyLedger/Features/Customers/CustomersView.swift
  - apps/ios/BuyLedgerUITests/KeyboardDismissTests.swift
  - apps/ios/BuyLedgerTests/BiometricAuthClientTests.swift
  - apps/ios/BuyLedger/Core/Domain/OrderStatus.swift
  - apps/ios/BuyLedger/Core/Persistence/ReconciliationStatusPersistence.swift
  - apps/ios/BuyLedger/Core/Dependencies/PhotoClient.swift
  - apps/ios/BuyLedger/Shared/Extensions/Image+Extensions.swift
  - apps/ios/BuyLedger/Core/Dependencies/CurrencyMetadataRepository.swift
  - apps/ios/BuyLedgerUITests/Support/ValueParsing.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderEditDirtyTests.swift
  - apps/ios/BuyLedger/Features/Settings/AISummaryModelCatalog.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Avatar/BLAvatar.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderRowView.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersRegularViewMultiSelectBaseline.1.png
  - apps/ios/BuyLedger/Core/Persistence/OrderSourceRecord.swift
  - apps/ios/BuyLedgerUITests/Tests/Smoke/LaunchSmokeTests.swift
  - apps/ios/BuyLedger/Features/AISummary/OllamaClient.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrdersToolbarContent.swift
  - apps/ios/BuyLedgerUITests/Screens/OrderEditScreen.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoThumbnail.swift
  - apps/ios/BuyLedgerTests/NameLookupPersistenceTests.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsStats.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestHarness.swift
  - apps/ios/BuyLedgerTests/OrdersFilterOperationsTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewBaseline.1.png
  - apps/ios/BuyLedgerUITests/Support/Diagnostics.swift
  - apps/ios/BuyLedger/Core/Networking/AppConfiguration.swift
  - shared/data-model/fixtures/expected/kotlin/SampleReceipt.kt
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewMultiSelectBaseline.1.png
  - shared/data-model/schema/LedgerOrder.yaml
  - apps/ios/BuyLedgerUITests/Support/AlertInteraction.swift
  - apps/ios/BuyLedger/Core/Networking/APIError.swift
  - apps/ios/BuyLedger/Core/Networking/HTTPClient.swift
  - shared/data-model/fixtures/expected/typescript/SampleSequence.ts
  - apps/ios/BuyLedger/Features/App/RootSidebarLayout.swift
  - CLAUDE.md
  - apps/ios/BuyLedger/Features/Orders/OrdersCompactView.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignDetailView.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardFeature.swift
  - apps/ios/BuyLedger/Features/App/AppLockFeature.swift
  - apps/ios/BuyLedgerTests/OrderMergeFeatureTests.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignFormatters.swift
  - apps/ios/BuyLedgerTests/FxFeatureTests.swift
  - apps/ios/BuyLedgerTests/PersistenceErrorContractTests.swift
  - apps/ios/BuyLedgerUITests-Performance.xctestplan
  - apps/ios/BuyLedger/Core/Testing/BLUITestHarness.swift
  - apps/ios/BuyLedger/Features/AISummary/OllamaDTO.swift
  - apps/ios/BuyLedger/Core/Persistence/ReconciliationStatusRecord.swift
  - shared/data-model/fixtures/expected/kotlin/SampleStatus.kt
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLFormatters.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewBaseline.1.png
  - apps/ios/BuyLedgerUITests.xctestplan
  - apps/ios/BuyLedger/Features/Orders/OrderEditFeature.swift
  - apps/ios/BuyLedgerTests/CustomersFeatureTests.swift
  - apps/ios/BuyLedgerTests/PhotoDataProcessorTests.swift
  - apps/ios/BuyLedger/Core/Domain/OrderMerge.swift
  - apps/ios/BuyLedgerTests/PersistenceRecoveryTests.swift
  - shared/data-model/fixtures/expected/kotlin/SampleQuote.kt
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/States/DelayedProgressView.swift
  - apps/ios/BuyLedger/Core/Sync/SyncQueueItem.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersFilterOperations.swift
  - shared/data-model/fixtures/schema/sample-trait-matrix.yaml
  - apps/ios/BuyLedger/Core/Domain/Generated/Campaign.generated.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderDetailTests.swift
  - shared/data-model/schema/FxRateSnapshot.yaml
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/persistenceFailureViewBaseline.1.png
  - shared/data-model/fixtures/schema/sample-enums.yaml
  - shared/data-model/fixtures/expected/swift/SampleProfile.generated.swift
  - apps/ios/BuyLedgerTests/SchemaMigrationTests.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersBatchOperations.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFormatters.swift
  - apps/ios/BuyLedgerTests/CampaignReminderFailureTests.swift
  - apps/ios/BuyLedger.xcodeproj/project.pbxproj
  - apps/ios/BuyLedger/Features/App/PersistenceFailureView.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsView.swift
  - apps/ios/BuyLedgerTests/AppConfigurationTests.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFilterSheet.swift
  - apps/ios/BuyLedgerUITests/Support/MenuInteraction.swift
  - shared/data-model/README.md
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/ViewModifiers/BLCardShadow.swift
  - apps/ios/BuyLedgerTests/OrdersLoadStateTests.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OptionPickerSheet.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Badges/BLBadge.swift
  - apps/ios/BuyLedger/Shared/Extensions/Decimal+Extensions.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignListView.swift
  - apps/ios/BuyLedgerTests/OrdersFeaturePerformanceTests.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/LedgerOrder.generated.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupNameEditorSheet.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests.swift
  - apps/ios/BuyLedgerTests/OrdersFeatureTests.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/LedgerOrderItem.generated.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewLongContentBaseline.1.png
  - apps/ios/BuyLedgerTests/BLAccessibilityIDTests.swift
  - apps/ios/BuyLedger/Core/Domain/LedgerOrder+Samples.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLPalette.swift
  - apps/ios/BuyLedgerTests/LookupManagementFeatureTests.swift
  - shared/data-model/fixtures/expected/swift/SampleSequence.generated.swift
  - shared/data-model/fixtures/expected/typescript/SampleQuote.ts
  - apps/ios/BuyLedger/Core/Dependencies/CategoryRepository.swift
  - shared/data-model/fixtures/expected/typescript/SampleReceipt.ts
  - apps/ios/BuyLedger/Core/Persistence/CampaignReminderPersistence.swift
  - apps/ios/CLAUDE.md
  - apps/ios/BuyLedger/Features/Orders/OrderEditView.swift
  - apps/ios/BuyLedgerUITests/Tests/Tools/QuoteTests.swift
  - apps/ios/BuyLedgerUITests/Screens/DashboardScreen.swift
  - apps/ios/BuyLedger/Core/Networking/ExchangeRateClient.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLDonutChart.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignEditView.swift
  - apps/ios/BuyLedgerUITests/Screens/OptionPickerScreen.swift
  - shared/data-model/schema/CurrencyCode.yaml
  - apps/ios/BuyLedger/Features/Orders/OrderDraft.swift
  - apps/ios/BuyLedger/Core/Persistence/CategoryPersistence.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Progress/BLProgressBar.swift
  - apps/ios/BuyLedgerUITests/Tests/Tools/FxTests.swift
  - apps/ios/BuyLedgerUITests/Screens/CampaignsScreen.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupCatalog.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/States/BLLoadFailureView.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementView.swift
  - apps/ios/BuyLedgerTests/HTTPClientTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Chips/BLFilterChip.swift
  - apps/ios/BuyLedgerTests/DashboardFeatureTests.swift
  - apps/ios/BuyLedgerTests/OrdersSearchCancellationTests.swift
  - apps/ios/BuyLedger/Features/App/AppLockView.swift
  - apps/ios/BuyLedgerUITests/Tests/Campaigns/CampaignDetailTests.swift
  - apps/ios/BuyLedger/Core/Testing/BLUITestSeedData.swift
  - apps/ios/BuyLedger/Core/Persistence/CampaignReminderRecord.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsDateRange.swift
  - apps/ios/BuyLedger/Core/Dependencies/CalendarReminderClient.swift
  - .github/workflows/ci.yml
  - apps/ios/BuyLedger/Core/Persistence/NameLookupRecord.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLHeatmapDepth.swift
  - apps/ios/BuyLedger/Core/Diagnostics/CrashDiagnosticsClient.swift
  - apps/ios/BuyLedgerTests/LayerBoundaryTests.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignFeature.swift
  - apps/ios/BuyLedgerTests/SnapshotTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Insights/InsightsTests.swift
  - apps/ios/BuyLedger/App/BuyLedgerApp.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsView.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/CustomerTier.generated.swift
  - apps/ios/BuyLedger/Core/Domain/CurrencyCode.swift
  - apps/ios/BuyLedgerTests/PrivacyManifestTests.swift
  - apps/ios/BuyLedgerTests/PaymentMethodPersistenceTests.swift
  - README.md
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Pickers/OptionPickerSheet.swift
  - apps/ios/BuyLedger/Core/Persistence/CampaignPersistence.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Tags/BLTagPill.swift
  - apps/ios/BuyLedgerUITests/Tests/Smoke/AppLockTests.swift
  - apps/ios/BuyLedgerTests/SettingsFeatureTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Campaigns/CampaignListTests.swift
  - apps/ios/BuyLedger/Features/Settings/AppLanguage.swift
  - shared/data-model/fixtures/expected/swift/SamplePreference.generated.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Status/BLStatusPill.swift
  - apps/ios/BuyLedger/Core/Dependencies/BiometricAuthClient.swift
  - apps/ios/BuyLedgerTests/CampaignFeatureTests.swift
  - apps/ios/BuyLedger/Core/Persistence/PersistenceStoreQuarantineClient.swift
  - apps/ios/BuyLedger/Features/Orders/Components/MergePhotoPickerSheet.swift
  - apps/ios/BuyLedger/Core/Domain/Campaign.swift
  - apps/ios/BuyLedger/Core/Persistence/PersistenceStoreQuarantine.swift
  - apps/ios/BuyLedger/Core/Networking/ExchangeRateDTO.swift
  - apps/ios/BuyLedger.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
  - apps/ios/BuyLedger/Core/Persistence/CategoryRecord.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLTypography.swift
  - apps/ios/BuyLedgerUITests/Screens/RootNavigationScreen.swift
  - apps/ios/BuyLedger/Features/FX/FxRates.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsStorage.swift
  - shared/data-model/fixtures/schema/sample-orders.yaml
  - apps/ios/BuyLedger/Features/App/PersistenceFailureFeature.swift
  - apps/ios/BuyLedger/Core/Persistence/PersistenceError.swift
  - apps/ios/BuyLedgerTests/OrdersBatchOperationsTests.swift
  - apps/ios/BuyLedgerAccessibilityIDs/BLAccessibilityID.swift
  - apps/ios/BuyLedgerUITests/Tests/Customers/CustomersTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Buttons/BLButtonStyle.swift
  - apps/ios/BuyLedgerTests/OrderEditFocusTests.swift
  - apps/ios/BuyLedgerTests/QuoteFeatureTests.swift
  - apps/ios/BuyLedgerTests/TestSuiteIntegrityTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Performance/LaunchPerformanceTests.swift
  - shared/data-model/schema/Campaign.yaml
  - apps/ios/BuyLedger/Core/Domain/FxRates.swift
  - apps/ios/BuyLedger/Core/Dependencies/PaymentMethodRepository.swift
  - apps/ios/BuyLedger/Core/Testing/BLUITestConfiguration.swift
  - apps/ios/BuyLedgerTests/DesignSystemSourceScanTests.swift
  - apps/ios/BuyLedgerTests/ColorContrastTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoViewer.swift
  - apps/ios/README.md
  - apps/ios/BuyLedger/Features/Orders/OrderStatusFilter.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/PaymentReceiptStatus.generated.swift
  - apps/ios/BuyLedgerTests/LocalizationCatalogTests.swift
  - apps/ios/BuyLedgerUITests/Screens/AISummaryScreen.swift
  - apps/ios/BuyLedgerUITests/Screens/CampaignDetailScreen.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardStats.swift
  - apps/ios/BuyLedger/Features/Orders/OrderDatePeriod.swift
  - apps/ios/BuyLedgerTests/APIErrorMappingTests.swift
  - apps/ios/BuyLedger/App/AppLaunchConfigurator.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderMergeTests.swift
  - apps/ios/BuyLedgerTests/NumericInputGroupingScanTests.swift
  - apps/ios/BuyLedger/Core/Persistence/CampaignRecord.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/quoteViewRateUnavailable.1.png
  - apps/ios/BuyLedgerUITests/Screens/FxScreen.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Forms/PaymentMethodEditorSheet.swift
  - shared/data-model/generator/src/datamodel-gen.ts
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewLongIdentifierBaseline.1.png
  - shared/data-model/fixtures/expected/kotlin/SampleGrade.kt
  - shared/data-model/schema/PaymentMethodInfo.yaml
  - apps/ios/BuyLedger/Core/Domain/Generated/PaymentMethodInfo.generated.swift
  - shared/data-model/schema/CampaignStatus.yaml
  - apps/ios/BuyLedgerUITests/Support/SheetInteraction.swift
  - shared/data-model/fixtures/expected/swift/SampleReceipt.generated.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignEditFeature.swift
tests:
  - shared/data-model/generator/test/datamodel-gen.test.ts
-->

---
### Requirement: Payment method cardless indicator

For the payment method kind, the screen SHALL display a "cardless" badge on each item flagged as cardless and SHALL display an explanatory note describing the cardless behavior. The badge and note SHALL be present on all platforms.

#### Scenario: Cardless payment method shows badge and note

- **WHEN** the payment method management screen is shown and at least one method is flagged cardless
- **THEN** each cardless method row displays the "無卡" badge and the screen displays the explanatory note about the cardless discount and top-up fields


<!-- @trace
source: lookup-management-macos-card-style
updated: 2026-05-24
code:
  - .agents/skills/spectra-discuss/SKILL.md
  - .agents/skills/spectra-drift/SKILL.md
  - .agents/skills/spectra-ingest/SKILL.md
  - .agents/skills/spectra-apply/SKILL.md
  - .agents/skills/spectra-propose/SKILL.md
  - apps/apple/BuyLedger/Features/Lookups/LookupManagementView.swift
-->

---
### Requirement: Lookup item count and empty state

The screen SHALL display the count of created items, and SHALL display an empty state with the kind-specific title and description when no items exist.

#### Scenario: Count is displayed

- **WHEN** the management screen is shown with one or more items
- **THEN** the screen displays the number of created items

#### Scenario: Empty state when no items exist

- **WHEN** the management screen is shown with no items
- **THEN** the screen displays the kind-specific empty title and description

<!-- @trace
source: lookup-management-macos-card-style
updated: 2026-05-24
code:
  - .agents/skills/spectra-discuss/SKILL.md
  - .agents/skills/spectra-drift/SKILL.md
  - .agents/skills/spectra-ingest/SKILL.md
  - .agents/skills/spectra-apply/SKILL.md
  - .agents/skills/spectra-propose/SKILL.md
  - apps/apple/BuyLedger/Features/Lookups/LookupManagementView.swift
-->

---
### Requirement: Reconciliation status is a managed lookup kind

The lookup management screen SHALL support reconciliation status as a managed kind, with the same add, rename, and delete operations and the same presentation (system List on iOS and iPadOS) as the existing order source, category, and payment method kinds. Adding a reconciliation status SHALL use a medium-height name editor sheet (matching the add-payment-method interaction), not a plain alert. Renaming a reconciliation status SHALL update orders that reference the old value.

#### Scenario: Add a reconciliation status via the medium sheet

- **WHEN** the user activates the add control on the reconciliation status management screen and confirms a non-empty, trimmed name in the medium-height sheet
- **THEN** the status is added through the management feature and appears in the list

#### Scenario: Rename a reconciliation status cascades to orders

- **WHEN** the user renames a reconciliation status to a non-empty name different from the original
- **THEN** the status is renamed through the management feature and orders referencing the old status value are updated to the new value

#### Scenario: Delete a reconciliation status

- **WHEN** the user triggers delete on a reconciliation status
- **THEN** the status is removed through the management feature

#### Scenario: Empty state when no reconciliation statuses exist

- **WHEN** the reconciliation status management screen is shown with no items
- **THEN** the screen displays the reconciliation-status empty title and description

---
### Requirement: Payment method bank-transfer indicator

For the payment method kind, the screen SHALL display a "bank transfer" (銀行匯款) badge on each item flagged as bank transfer, in addition to the existing cardless badge. A payment method flagged as both cardless and bank transfer SHALL display both badges. The badges SHALL be present on all platforms.

#### Scenario: Bank-transfer payment method shows the badge

- **WHEN** the payment method management screen is shown and at least one method is flagged bank transfer
- **THEN** each bank-transfer method row displays the "銀行匯款" badge

#### Scenario: A method flagged both cardless and bank transfer shows both badges

- **WHEN** a payment method is flagged both cardless and bank transfer
- **THEN** its row displays both the "無卡" and "銀行匯款" badges


<!-- @trace
source: order-reconciliation-status
updated: 2026-05-29
code:
  - apps/apple/BuyLedger/Features/Lookups/LookupManagementFeature.swift
  - apps/apple/BuyLedger/Core/Persistence/PaymentMethodPersistence.swift
  - apps/apple/BuyLedger/Features/Orders/Components/OptionPickerSheet.swift
  - apps/apple/BuyLedger/Core/Dependencies/OrderRepository.swift
  - apps/apple/BuyLedger/Features/More/MoreView.swift
  - apps/apple/BuyLedger/Features/Orders/Components/PaymentMethodEditorSheet.swift
  - apps/apple/BuyLedger/Features/Orders/OrdersFeature.swift
  - apps/apple/BuyLedger/Core/Dependencies/PaymentMethodRepository.swift
  - apps/apple/BuyLedger/Core/Persistence/PaymentMethodRecord.swift
  - apps/apple/BuyLedger/Features/Lookups/LookupKind.swift
  - apps/apple/BuyLedger/Core/Persistence/OrderRecord.swift
  - apps/apple/BuyLedger/Core/Domain/LedgerOrder+Samples.swift
  - apps/apple/BuyLedgerTests/PaymentMethodPersistenceTests.swift
  - apps/apple/BuyLedger/Core/Domain/PaymentMethodInfo.swift
  - apps/apple/BuyLedger/Core/Persistence/BuyLedgerSchema.swift
  - apps/apple/BuyLedger/Features/Lookups/LookupManagementView.swift
  - apps/apple/BuyLedger/Core/Persistence/PersistenceContainer.swift
  - apps/apple/BuyLedger/Core/Domain/LedgerOrder.swift
  - apps/apple/BuyLedger/Features/Orders/Components/LookupItemEditorSheet.swift
  - apps/apple/BuyLedgerTests/OrderEditFeatureTests.swift
  - apps/apple/BuyLedger/Features/Orders/OrderEditView.swift
  - apps/apple/BuyLedgerTests/RootFeatureTests.swift
  - apps/apple/BuyLedgerTests/SnapshotTests.swift
  - apps/apple/BuyLedger/Features/Orders/OrderEditFeature.swift
  - apps/apple/BuyLedgerTests/OrderPersistenceTests.swift
  - apps/apple/BuyLedger/Core/Persistence/OrderPersistence.swift
  - apps/apple/BuyLedgerTests/OrderCalculationTests.swift
  - apps/apple/BuyLedger/Core/Dependencies/VerificationStatusRepository.swift
  - apps/apple/BuyLedgerTests/OrdersFeaturePerformanceTests.swift
  - apps/apple/BuyLedger/Features/App/RootFeature.swift
  - apps/apple/BuyLedgerTests/LookupManagementFeatureTests.swift
  - apps/apple/BuyLedger/Core/Persistence/VerificationStatusRecord.swift
  - apps/apple/BuyLedgerTests/OrdersFeatureTests.swift
  - apps/apple/BuyLedger/Core/Persistence/VerificationStatusPersistence.swift
-->

---
### Requirement: Payment method editing via the editor sheet

For the payment method kind, the per-item edit action SHALL be labeled "編輯" and SHALL present the payment method editor pre-filled with the item's current name, cardless flag, and bank-transfer flag. Confirming SHALL apply the edited name and flags authoritatively: changing the name SHALL rename the item and cascade to orders referencing the old name, and the cardless and bank-transfer flags SHALL be set to exactly the user's selection — including clearing a previously-set flag. The edit action SHALL be available from every per-item entry point that previously offered rename (iOS swipe, iOS context menu). Other lookup kinds (order source, category, reconciliation status) SHALL retain the rename-only action labeled "重新命名".

#### Scenario: Edit a payment method's name and flags

- **WHEN** the user activates "編輯" on a payment method, changes its name, and confirms
- **THEN** the payment method is renamed, orders referencing the old name are updated, and its cardless and bank-transfer flags reflect the user's selection

#### Scenario: Clearing a flag during edit persists

- **GIVEN** a payment method currently flagged as bank transfer
- **WHEN** the user edits it, unchecks the bank-transfer flag, and confirms (with or without also changing the name)
- **THEN** the payment method's bank-transfer flag becomes false and is not restored by the rename merge

#### Scenario: Non-payment kinds keep the rename-only action

- **WHEN** the user triggers the per-item edit action on an order source, category, or reconciliation status
- **THEN** the action is labeled "重新命名" and presents a name-only rename flow without flag toggles

---
### Requirement: Lookup data has a single source shared by every consumer

The four lookup kinds — order source, category, payment method, and reconciliation status — SHALL be held in one store shared by every consumer, rather than copied into each feature that reads them. A consumer SHALL derive its view of a lookup kind from that store rather than maintaining its own collection.

Adding, renaming, or deleting a lookup item SHALL become visible to every consumer within the same state update, without requiring a separate action to propagate it and without depending on a root-level interception for each operation.

Consistency SHALL NOT depend on hand-written synchronization between copies. Where a lookup change must also rewrite stored orders, that rewrite SHALL happen in the same update as the lookup change, so that a derived list that unions lookup values with values used by orders can never briefly show the old name.

#### Scenario: Renaming reaches every consumer in one update

- **WHEN** a lookup item of any kind is renamed
- **THEN** the management list, the order editor's selectable values for that kind, and the orders referencing the old value are all updated in the same state update, with no further action sent

#### Scenario: A rename never leaves the old name reachable

- **WHEN** a lookup item is renamed and a selectable list unions lookup values with values already used by orders
- **THEN** that list does not contain the old name at any point after the update

#### Scenario: Adding inside the order editor is visible in management

- **WHEN** the user adds a lookup item from within the order editor
- **THEN** the item appears on that kind's management screen without relaunching the app

#### Scenario: Deleting removes the value from every consumer

- **WHEN** a lookup item is deleted
- **THEN** the order editor no longer offers it as a selectable value


<!-- @trace
source: lookup-single-source-of-truth
updated: 2026-08-15
code:
  - apps/ios/BuyLedgerUITests/Support/LaunchOptions.swift
  - shared/data-model/fixtures/expected/typescript/SampleProfile.ts
  - apps/ios/BuyLedgerUITests/Screens/OrderDetailScreen.swift
  - apps/ios/BuyLedger/Resources/Info.plist
  - apps/ios/BuyLedgerUITests/Screens/CustomersScreen.swift
  - apps/ios/BuyLedger/Core/Dependencies/CampaignRepository.swift
  - shared/data-model/schema/OrderStatus.yaml
  - apps/ios/BuyLedger/Features/AISummary/AISummaryFeature.swift
  - apps/ios/BuyLedger/Features/Customers/CustomersFeature.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/CurrencyCode.generated.swift
  - apps/ios/BuyLedger/Features/More/MoreView.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLDonutSegment.swift
  - apps/ios/BuyLedger/Features/App/SidebarBadgeCounts.swift
  - apps/ios/BuyLedgerTests/OrderMergeTests.swift
  - apps/ios/BuyLedgerTests/ExchangeRateClientTests.swift
  - apps/ios/BuyLedgerUITests/PhotoViewerPagingTests.swift
  - apps/ios/BuyLedger/Shared/Extensions/Color+Extensions.swift
  - apps/ios/BuyLedger/Core/Testing/BLUITestDependencyOverrides.swift
  - apps/ios/BuyLedger/Features/FX/FxFeature.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersFeature.swift
  - apps/ios/BuyLedgerUITests/Screens/OrdersScreen.swift
  - apps/ios/BuyLedger/Core/Testing/BLUITestSeedProfile.swift
  - apps/ios/BuyLedgerTests/BLPhotoViewerTests.swift
  - apps/ios/BuyLedger/Core/Dependencies/TelemetryClient.swift
  - apps/ios/BuyLedgerTests/BLFormattersTests.swift
  - apps/ios/BuyLedgerUITests/Screens/AppLockScreen.swift
  - apps/ios/BuyLedger/Features/Quote/QuoteFeature.swift
  - apps/ios/BuyLedgerUITests/Support/TextInput.swift
  - apps/ios/BuyLedger/Core/Persistence/NameLookupPersistence.swift
  - apps/ios/BuyLedger/Core/Dependencies/CampaignReminderRepository.swift
  - apps/ios/BuyLedgerTests/DashboardStatsTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderCreateTests.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignSummary.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/States/BLDelayedProgressView.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsSnapshot.swift
  - apps/ios/BuyLedger/Core/Persistence/PersistenceContainer.swift
  - apps/ios/BuyLedgerTests/AppScenePhaseCoordinatorTests.swift
  - apps/ios/BuyLedgerUITests/Support/Scrolling.swift
  - apps/ios/BuyLedger/Core/Persistence/PaymentMethodRecord.swift
  - apps/ios/BuyLedger/Resources/InfoPlist.xcstrings
  - apps/ios/BuyLedgerUITests/Tests/Orders/AISummaryTests.swift
  - apps/ios/BuyLedgerTests/ColorContrast.swift
  - shared/data-model/schema/CustomerTier.yaml
  - apps/ios/BuyLedgerUITests/Screens/Screen.swift
  - apps/ios/BuyLedger.xcodeproj/xcshareddata/xcschemes/BuyLedger.xcscheme
  - apps/ios/BuyLedgerUITests/Support/AppNavigator.swift
  - apps/ios/BuyLedger/Core/Dependencies/ReconciliationStatusRepository.swift
  - apps/ios/BuyLedger/Core/Domain/LedgerOrder.swift
  - apps/ios/BuyLedger/Features/Customers/CustomerRankBadgeStyle.swift
  - apps/ios/BuyLedger/Core/Dependencies/OrderSourceRepository.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsFeature.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderStatus+Presentation.swift
  - apps/ios/BuyLedger/Core/Persistence/OrderRecord.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardView.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Cards/BLCard.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestConfiguration.swift
  - apps/ios/BuyLedger/Features/AISummary/AISummaryView.swift
  - apps/ios/BuyLedger/App/AppDelegate.swift
  - apps/ios/BuyLedgerTests/CurrencyMetadataCacheTests.swift
  - apps/ios/BuyLedger/Shared/Localization/AppLanguage.swift
  - shared/data-model/schema/PaymentReceiptStatus.yaml
  - apps/ios/BuyLedger/Features/FX/ExchangeRateDTO.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderMergeCandidateSheet.swift
  - shared/data-model/fixtures/expected/typescript/SampleGrade.ts
  - apps/ios/BuyLedgerUITests/Tests/Smoke/HarnessSelfCheckTests.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/FxRateSnapshot.generated.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLSparkline.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/LedgerCustomer.generated.swift
  - apps/ios/BuyLedgerTests/OllamaClientTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/ViewModifiers/BLTypographyModifier.swift
  - shared/data-model/fixtures/expected/kotlin/SamplePreference.kt
  - apps/ios/BuyLedger/Features/App/RootTab.swift
  - apps/ios/BuyLedger/Core/Dependencies/OrderRepository.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLBarChart.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersFeature+StateQuery.swift
  - apps/ios/BuyLedgerTests/CalendarReminderTests.swift
  - apps/ios/BuyLedgerUITests/Screens/QuoteScreen.swift
  - apps/ios/BuyLedgerTests/PersistenceFailureFeatureTests.swift
  - shared/data-model/fixtures/expected/swift/SampleQuote.generated.swift
  - apps/ios/BuyLedgerTests/InsightsAttributionTests.swift
  - apps/ios/BuyLedgerUITests/Screens/SettingsScreen.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestDependencyOverrides.swift
  - apps/ios/BuyLedger/Core/Domain/OrderSummary.swift
  - apps/ios/BuyLedgerTests/BLUITestConfigurationTests.swift
  - apps/ios/BuyLedger/Core/Dependencies/NameLookupOperations.swift
  - apps/ios/BuyLedgerTests/LookupCatalogTests.swift
  - apps/ios/BuyLedgerTests/InsightsStatsTests.swift
  - apps/ios/BuyLedgerTests/OrderStatusTests.swift
  - apps/ios/BuyLedger.xctestplan
  - shared/data-model/fixtures/expected/swift/SampleGrade.generated.swift
  - apps/ios/BuyLedger/Core/Sync/SyncMeta.swift
  - apps/ios/BuyLedger/Core/Domain/FxRateSnapshot.swift
  - apps/ios/BuyLedger/Features/App/RootView.swift
  - shared/data-model/fixtures/expected/swift/SampleStatus.generated.swift
  - apps/ios/BuyLedger/Shared/Extensions/Bundle+Extensions.swift
  - apps/ios/BuyLedger/Core/Persistence/OrderPersistence.swift
  - apps/ios/BuyLedgerTests/TestDependencies.swift
  - shared/data-model/schema/LedgerOrderItem.yaml
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementDestination.swift
  - apps/ios/BuyLedgerUITests/Support/Waiting.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrdersListTests.swift
  - apps/ios/BuyLedgerUITests/Screens/InsightsScreen.swift
  - apps/ios/BuyLedgerUITests/Screens/CampaignEditScreen.swift
  - apps/ios/BuyLedger/Resources/Localizable.xcstrings
  - apps/ios/BuyLedger/Features/Orders/Components/PaymentMethodEditorSheet.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/Money.generated.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderDetailView.swift
  - apps/ios/BuyLedger/Core/Persistence/CurrencyMetadataPersistence.swift
  - apps/ios/BuyLedgerUITests/Support/Assertions.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestSeedProfile.swift
  - apps/ios/BuyLedger/Features/FX/FxView.swift
  - apps/ios/BuyLedgerTests/CampaignSummaryTests.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLMetrics.swift
  - apps/ios/BuyLedgerTests/OrderEditFeatureTests.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupKind.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/quoteViewBaseline.1.png
  - apps/ios/BuyLedger/Shared/Media/PhotoDataProcessor.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderSelectableRow.swift
  - apps/ios/BuyLedger/Core/Dependencies/OpenSettingsClient.swift
  - apps/ios/BuyLedgerUITests/Tests/Campaigns/CampaignCrudTests.swift
  - apps/ios/BuyLedgerTests/AppLockFeatureTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/ViewModifiers/BLHeroCardBackground.swift
  - apps/ios/BuyLedgerTests/AISummaryFeatureTests.swift
  - apps/ios/BuyLedger/Features/Quote/QuoteView.swift
  - apps/ios/BuyLedger/Core/Domain/LedgerOrderItem.swift
  - apps/ios/BuyLedger/Features/App/AppScenePhaseCoordinator.swift
  - apps/ios/BuyLedger/Core/Networking/HTTPMethod.swift
  - apps/ios/BuyLedgerTests/CampaignEditFeatureTests.swift
  - apps/ios/BuyLedgerUITests/Screens/MergeFlowScreen.swift
  - AGENTS.md
  - apps/ios/BuyLedgerUITests/Screens/PhotoViewerScreen.swift
  - apps/ios/BuyLedgerTests/InsightsFeatureTests.swift
  - shared/data-model/fixtures/expected/typescript/SampleStatus.ts
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLTone.swift
  - apps/ios/BuyLedger/Features/Orders/OrderDetailPath.swift
  - apps/ios/BuyLedger/Core/Persistence/CurrencyMetadataRecord.swift
  - apps/ios/BuyLedger/Core/Persistence/PaymentMethodPersistence.swift
  - shared/data-model/fixtures/expected/kotlin/SampleProfile.kt
  - apps/ios/BuyLedgerTests/CampaignIntegrationTests.swift
  - apps/ios/BuyLedgerTests/OrderDraftTests.swift
  - apps/ios/BuyLedger/Resources/GoogleService-Info.example.plist
  - shared/data-model/schema/LedgerCustomer.yaml
  - apps/ios/BuyLedger/Features/Orders/LedgerOrder+OrderMutation.swift
  - apps/ios/BuyLedgerTests/CampaignPersistenceTests.swift
  - apps/ios/BuyLedgerUITests/Support/BLUITestCase.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/CampaignStatus.generated.swift
  - apps/ios/BuyLedger/Features/FX/ExchangeRateClient.swift
  - apps/ios/BuyLedgerTests/AccessibilityConventionScanTests.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersMergeFlowOperations.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsFeature.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLBarChartValue.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLStatusHue.swift
  - apps/ios/BuyLedger/Core/Domain/Campaign+Samples.swift
  - apps/ios/BuyLedgerTests/ProjectionWriteBoundaryTests.swift
  - shared/data-model/fixtures/expected/typescript/SamplePreference.ts
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/dashboardViewBaseline.1.png
  - apps/ios/BuyLedger/Core/Persistence/BuyLedgerSchema.swift
  - apps/ios/BuyLedger/Features/Orders/OrderMergeFeature.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/OrderStatus.generated.swift
  - apps/ios/BuyLedgerTests/ContrastComplianceTests.swift
  - shared/data-model/fixtures/expected/kotlin/SampleSequence.kt
  - apps/ios/BuyLedger/Core/Persistence/OrderSourcePersistence.swift
  - apps/ios/BuyLedger/Resources/PrivacyInfo.xcprivacy
  - shared/data-model/schema/Money.yaml
  - apps/ios/BuyLedgerTests/OrderCalculationTests.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestSeedData.swift
  - apps/ios/BuyLedgerTests/OrderPersistenceTests.swift
  - apps/ios/BuyLedger/Features/App/RootTabLayout.swift
  - apps/ios/BuyLedger/Core/Networking/URLRequestBuilder.swift
  - apps/ios/BuyLedger/Features/App/RootFeature.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersView.swift
  - apps/ios/BuyLedger/Features/Customers/CustomersView.swift
  - apps/ios/BuyLedgerUITests/KeyboardDismissTests.swift
  - apps/ios/BuyLedgerTests/BiometricAuthClientTests.swift
  - apps/ios/BuyLedger/Core/Domain/OrderStatus.swift
  - apps/ios/BuyLedger/Core/Persistence/ReconciliationStatusPersistence.swift
  - apps/ios/BuyLedger/Core/Dependencies/PhotoClient.swift
  - apps/ios/BuyLedger/Shared/Extensions/Image+Extensions.swift
  - apps/ios/BuyLedger/Core/Dependencies/CurrencyMetadataRepository.swift
  - apps/ios/BuyLedgerUITests/Support/ValueParsing.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderEditDirtyTests.swift
  - apps/ios/BuyLedger/Features/Settings/AISummaryModelCatalog.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Avatar/BLAvatar.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderRowView.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersRegularViewMultiSelectBaseline.1.png
  - apps/ios/BuyLedger/Core/Persistence/OrderSourceRecord.swift
  - apps/ios/BuyLedgerUITests/Tests/Smoke/LaunchSmokeTests.swift
  - apps/ios/BuyLedger/Features/AISummary/OllamaClient.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrdersToolbarContent.swift
  - apps/ios/BuyLedgerUITests/Screens/OrderEditScreen.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoThumbnail.swift
  - apps/ios/BuyLedgerTests/NameLookupPersistenceTests.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsStats.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestHarness.swift
  - apps/ios/BuyLedgerTests/OrdersFilterOperationsTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewBaseline.1.png
  - apps/ios/BuyLedgerUITests/Support/Diagnostics.swift
  - apps/ios/BuyLedger/Core/Networking/AppConfiguration.swift
  - shared/data-model/fixtures/expected/kotlin/SampleReceipt.kt
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewMultiSelectBaseline.1.png
  - shared/data-model/schema/LedgerOrder.yaml
  - apps/ios/BuyLedgerUITests/Support/AlertInteraction.swift
  - apps/ios/BuyLedger/Core/Networking/APIError.swift
  - apps/ios/BuyLedger/Core/Networking/HTTPClient.swift
  - shared/data-model/fixtures/expected/typescript/SampleSequence.ts
  - apps/ios/BuyLedger/Features/App/RootSidebarLayout.swift
  - CLAUDE.md
  - apps/ios/BuyLedger/Features/Orders/OrdersCompactView.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignDetailView.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardFeature.swift
  - apps/ios/BuyLedger/Features/App/AppLockFeature.swift
  - apps/ios/BuyLedgerTests/OrderMergeFeatureTests.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignFormatters.swift
  - apps/ios/BuyLedgerTests/FxFeatureTests.swift
  - apps/ios/BuyLedgerTests/PersistenceErrorContractTests.swift
  - apps/ios/BuyLedgerUITests-Performance.xctestplan
  - apps/ios/BuyLedger/Core/Testing/BLUITestHarness.swift
  - apps/ios/BuyLedger/Features/AISummary/OllamaDTO.swift
  - apps/ios/BuyLedger/Core/Persistence/ReconciliationStatusRecord.swift
  - shared/data-model/fixtures/expected/kotlin/SampleStatus.kt
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLFormatters.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewBaseline.1.png
  - apps/ios/BuyLedgerUITests.xctestplan
  - apps/ios/BuyLedger/Features/Orders/OrderEditFeature.swift
  - apps/ios/BuyLedgerTests/CustomersFeatureTests.swift
  - apps/ios/BuyLedgerTests/PhotoDataProcessorTests.swift
  - apps/ios/BuyLedger/Core/Domain/OrderMerge.swift
  - apps/ios/BuyLedgerTests/PersistenceRecoveryTests.swift
  - shared/data-model/fixtures/expected/kotlin/SampleQuote.kt
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/States/DelayedProgressView.swift
  - apps/ios/BuyLedger/Core/Sync/SyncQueueItem.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersFilterOperations.swift
  - shared/data-model/fixtures/schema/sample-trait-matrix.yaml
  - apps/ios/BuyLedger/Core/Domain/Generated/Campaign.generated.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderDetailTests.swift
  - shared/data-model/schema/FxRateSnapshot.yaml
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/persistenceFailureViewBaseline.1.png
  - shared/data-model/fixtures/schema/sample-enums.yaml
  - shared/data-model/fixtures/expected/swift/SampleProfile.generated.swift
  - apps/ios/BuyLedgerTests/SchemaMigrationTests.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersBatchOperations.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFormatters.swift
  - apps/ios/BuyLedgerTests/CampaignReminderFailureTests.swift
  - apps/ios/BuyLedger.xcodeproj/project.pbxproj
  - apps/ios/BuyLedger/Features/App/PersistenceFailureView.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsView.swift
  - apps/ios/BuyLedgerTests/AppConfigurationTests.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFilterSheet.swift
  - apps/ios/BuyLedgerUITests/Support/MenuInteraction.swift
  - shared/data-model/README.md
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/ViewModifiers/BLCardShadow.swift
  - apps/ios/BuyLedgerTests/OrdersLoadStateTests.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OptionPickerSheet.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Badges/BLBadge.swift
  - apps/ios/BuyLedger/Shared/Extensions/Decimal+Extensions.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignListView.swift
  - apps/ios/BuyLedgerTests/OrdersFeaturePerformanceTests.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/LedgerOrder.generated.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupNameEditorSheet.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests.swift
  - apps/ios/BuyLedgerTests/OrdersFeatureTests.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/LedgerOrderItem.generated.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewLongContentBaseline.1.png
  - apps/ios/BuyLedgerTests/BLAccessibilityIDTests.swift
  - apps/ios/BuyLedger/Core/Domain/LedgerOrder+Samples.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLPalette.swift
  - apps/ios/BuyLedgerTests/LookupManagementFeatureTests.swift
  - shared/data-model/fixtures/expected/swift/SampleSequence.generated.swift
  - shared/data-model/fixtures/expected/typescript/SampleQuote.ts
  - apps/ios/BuyLedger/Core/Dependencies/CategoryRepository.swift
  - shared/data-model/fixtures/expected/typescript/SampleReceipt.ts
  - apps/ios/BuyLedger/Core/Persistence/CampaignReminderPersistence.swift
  - apps/ios/CLAUDE.md
  - apps/ios/BuyLedger/Features/Orders/OrderEditView.swift
  - apps/ios/BuyLedgerUITests/Tests/Tools/QuoteTests.swift
  - apps/ios/BuyLedgerUITests/Screens/DashboardScreen.swift
  - apps/ios/BuyLedger/Core/Networking/ExchangeRateClient.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLDonutChart.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignEditView.swift
  - apps/ios/BuyLedgerUITests/Screens/OptionPickerScreen.swift
  - shared/data-model/schema/CurrencyCode.yaml
  - apps/ios/BuyLedger/Features/Orders/OrderDraft.swift
  - apps/ios/BuyLedger/Core/Persistence/CategoryPersistence.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Progress/BLProgressBar.swift
  - apps/ios/BuyLedgerUITests/Tests/Tools/FxTests.swift
  - apps/ios/BuyLedgerUITests/Screens/CampaignsScreen.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupCatalog.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/States/BLLoadFailureView.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementView.swift
  - apps/ios/BuyLedgerTests/HTTPClientTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Chips/BLFilterChip.swift
  - apps/ios/BuyLedgerTests/DashboardFeatureTests.swift
  - apps/ios/BuyLedgerTests/OrdersSearchCancellationTests.swift
  - apps/ios/BuyLedger/Features/App/AppLockView.swift
  - apps/ios/BuyLedgerUITests/Tests/Campaigns/CampaignDetailTests.swift
  - apps/ios/BuyLedger/Core/Testing/BLUITestSeedData.swift
  - apps/ios/BuyLedger/Core/Persistence/CampaignReminderRecord.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsDateRange.swift
  - apps/ios/BuyLedger/Core/Dependencies/CalendarReminderClient.swift
  - .github/workflows/ci.yml
  - apps/ios/BuyLedger/Core/Persistence/NameLookupRecord.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLHeatmapDepth.swift
  - apps/ios/BuyLedger/Core/Diagnostics/CrashDiagnosticsClient.swift
  - apps/ios/BuyLedgerTests/LayerBoundaryTests.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignFeature.swift
  - apps/ios/BuyLedgerTests/SnapshotTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Insights/InsightsTests.swift
  - apps/ios/BuyLedger/App/BuyLedgerApp.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsView.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/CustomerTier.generated.swift
  - apps/ios/BuyLedger/Core/Domain/CurrencyCode.swift
  - apps/ios/BuyLedgerTests/PrivacyManifestTests.swift
  - apps/ios/BuyLedgerTests/PaymentMethodPersistenceTests.swift
  - README.md
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Pickers/OptionPickerSheet.swift
  - apps/ios/BuyLedger/Core/Persistence/CampaignPersistence.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Tags/BLTagPill.swift
  - apps/ios/BuyLedgerUITests/Tests/Smoke/AppLockTests.swift
  - apps/ios/BuyLedgerTests/SettingsFeatureTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Campaigns/CampaignListTests.swift
  - apps/ios/BuyLedger/Features/Settings/AppLanguage.swift
  - shared/data-model/fixtures/expected/swift/SamplePreference.generated.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Status/BLStatusPill.swift
  - apps/ios/BuyLedger/Core/Dependencies/BiometricAuthClient.swift
  - apps/ios/BuyLedgerTests/CampaignFeatureTests.swift
  - apps/ios/BuyLedger/Core/Persistence/PersistenceStoreQuarantineClient.swift
  - apps/ios/BuyLedger/Features/Orders/Components/MergePhotoPickerSheet.swift
  - apps/ios/BuyLedger/Core/Domain/Campaign.swift
  - apps/ios/BuyLedger/Core/Persistence/PersistenceStoreQuarantine.swift
  - apps/ios/BuyLedger/Core/Networking/ExchangeRateDTO.swift
  - apps/ios/BuyLedger.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
  - apps/ios/BuyLedger/Core/Persistence/CategoryRecord.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLTypography.swift
  - apps/ios/BuyLedgerUITests/Screens/RootNavigationScreen.swift
  - apps/ios/BuyLedger/Features/FX/FxRates.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsStorage.swift
  - shared/data-model/fixtures/schema/sample-orders.yaml
  - apps/ios/BuyLedger/Features/App/PersistenceFailureFeature.swift
  - apps/ios/BuyLedger/Core/Persistence/PersistenceError.swift
  - apps/ios/BuyLedgerTests/OrdersBatchOperationsTests.swift
  - apps/ios/BuyLedgerAccessibilityIDs/BLAccessibilityID.swift
  - apps/ios/BuyLedgerUITests/Tests/Customers/CustomersTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Buttons/BLButtonStyle.swift
  - apps/ios/BuyLedgerTests/OrderEditFocusTests.swift
  - apps/ios/BuyLedgerTests/QuoteFeatureTests.swift
  - apps/ios/BuyLedgerTests/TestSuiteIntegrityTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Performance/LaunchPerformanceTests.swift
  - shared/data-model/schema/Campaign.yaml
  - apps/ios/BuyLedger/Core/Domain/FxRates.swift
  - apps/ios/BuyLedger/Core/Dependencies/PaymentMethodRepository.swift
  - apps/ios/BuyLedger/Core/Testing/BLUITestConfiguration.swift
  - apps/ios/BuyLedgerTests/DesignSystemSourceScanTests.swift
  - apps/ios/BuyLedgerTests/ColorContrastTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoViewer.swift
  - apps/ios/README.md
  - apps/ios/BuyLedger/Features/Orders/OrderStatusFilter.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/PaymentReceiptStatus.generated.swift
  - apps/ios/BuyLedgerTests/LocalizationCatalogTests.swift
  - apps/ios/BuyLedgerUITests/Screens/AISummaryScreen.swift
  - apps/ios/BuyLedgerUITests/Screens/CampaignDetailScreen.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardStats.swift
  - apps/ios/BuyLedger/Features/Orders/OrderDatePeriod.swift
  - apps/ios/BuyLedgerTests/APIErrorMappingTests.swift
  - apps/ios/BuyLedger/App/AppLaunchConfigurator.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderMergeTests.swift
  - apps/ios/BuyLedgerTests/NumericInputGroupingScanTests.swift
  - apps/ios/BuyLedger/Core/Persistence/CampaignRecord.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/quoteViewRateUnavailable.1.png
  - apps/ios/BuyLedgerUITests/Screens/FxScreen.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Forms/PaymentMethodEditorSheet.swift
  - shared/data-model/generator/src/datamodel-gen.ts
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewLongIdentifierBaseline.1.png
  - shared/data-model/fixtures/expected/kotlin/SampleGrade.kt
  - shared/data-model/schema/PaymentMethodInfo.yaml
  - apps/ios/BuyLedger/Core/Domain/Generated/PaymentMethodInfo.generated.swift
  - shared/data-model/schema/CampaignStatus.yaml
  - apps/ios/BuyLedgerUITests/Support/SheetInteraction.swift
  - shared/data-model/fixtures/expected/swift/SampleReceipt.generated.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignEditFeature.swift
tests:
  - shared/data-model/generator/test/datamodel-gen.test.ts
-->

---
### Requirement: Adding a lookup kind is a compile-time obligation

The differences between lookup kinds — how an order references a value of that kind, and how an order is rewritten when that value is renamed — SHALL be expressed on the lookup-kind type itself as exhaustive mappings, so that introducing a new kind fails to compile until those differences are supplied.

Consumers SHALL NOT branch on lookup kind to perform these operations; they SHALL delegate to the kind. Introducing a new kind SHALL NOT require adding a parallel property, action case, or scope in the root feature.

#### Scenario: A new kind does not compile until its differences are supplied

- **WHEN** a new lookup kind is added to the lookup-kind type
- **THEN** compilation fails until that kind supplies how orders reference it and how orders are rewritten on rename

#### Scenario: Compilation errors are confined to the kind and the shared store

- **WHEN** a new lookup kind is added and the project is built
- **THEN** the errors appear only in the lookup-kind type and the shared lookup store, not in the root feature or the orders feature

#### Scenario: Cascade contains no per-kind branching at the call site

- **WHEN** the cascade that rewrites orders after a rename is inspected
- **THEN** it delegates to the lookup kind and contains no branch over the set of kinds

<!-- @trace
source: lookup-single-source-of-truth
updated: 2026-08-15
code:
  - apps/ios/BuyLedgerUITests/Support/LaunchOptions.swift
  - shared/data-model/fixtures/expected/typescript/SampleProfile.ts
  - apps/ios/BuyLedgerUITests/Screens/OrderDetailScreen.swift
  - apps/ios/BuyLedger/Resources/Info.plist
  - apps/ios/BuyLedgerUITests/Screens/CustomersScreen.swift
  - apps/ios/BuyLedger/Core/Dependencies/CampaignRepository.swift
  - shared/data-model/schema/OrderStatus.yaml
  - apps/ios/BuyLedger/Features/AISummary/AISummaryFeature.swift
  - apps/ios/BuyLedger/Features/Customers/CustomersFeature.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/CurrencyCode.generated.swift
  - apps/ios/BuyLedger/Features/More/MoreView.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLDonutSegment.swift
  - apps/ios/BuyLedger/Features/App/SidebarBadgeCounts.swift
  - apps/ios/BuyLedgerTests/OrderMergeTests.swift
  - apps/ios/BuyLedgerTests/ExchangeRateClientTests.swift
  - apps/ios/BuyLedgerUITests/PhotoViewerPagingTests.swift
  - apps/ios/BuyLedger/Shared/Extensions/Color+Extensions.swift
  - apps/ios/BuyLedger/Core/Testing/BLUITestDependencyOverrides.swift
  - apps/ios/BuyLedger/Features/FX/FxFeature.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersFeature.swift
  - apps/ios/BuyLedgerUITests/Screens/OrdersScreen.swift
  - apps/ios/BuyLedger/Core/Testing/BLUITestSeedProfile.swift
  - apps/ios/BuyLedgerTests/BLPhotoViewerTests.swift
  - apps/ios/BuyLedger/Core/Dependencies/TelemetryClient.swift
  - apps/ios/BuyLedgerTests/BLFormattersTests.swift
  - apps/ios/BuyLedgerUITests/Screens/AppLockScreen.swift
  - apps/ios/BuyLedger/Features/Quote/QuoteFeature.swift
  - apps/ios/BuyLedgerUITests/Support/TextInput.swift
  - apps/ios/BuyLedger/Core/Persistence/NameLookupPersistence.swift
  - apps/ios/BuyLedger/Core/Dependencies/CampaignReminderRepository.swift
  - apps/ios/BuyLedgerTests/DashboardStatsTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderCreateTests.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignSummary.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/States/BLDelayedProgressView.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsSnapshot.swift
  - apps/ios/BuyLedger/Core/Persistence/PersistenceContainer.swift
  - apps/ios/BuyLedgerTests/AppScenePhaseCoordinatorTests.swift
  - apps/ios/BuyLedgerUITests/Support/Scrolling.swift
  - apps/ios/BuyLedger/Core/Persistence/PaymentMethodRecord.swift
  - apps/ios/BuyLedger/Resources/InfoPlist.xcstrings
  - apps/ios/BuyLedgerUITests/Tests/Orders/AISummaryTests.swift
  - apps/ios/BuyLedgerTests/ColorContrast.swift
  - shared/data-model/schema/CustomerTier.yaml
  - apps/ios/BuyLedgerUITests/Screens/Screen.swift
  - apps/ios/BuyLedger.xcodeproj/xcshareddata/xcschemes/BuyLedger.xcscheme
  - apps/ios/BuyLedgerUITests/Support/AppNavigator.swift
  - apps/ios/BuyLedger/Core/Dependencies/ReconciliationStatusRepository.swift
  - apps/ios/BuyLedger/Core/Domain/LedgerOrder.swift
  - apps/ios/BuyLedger/Features/Customers/CustomerRankBadgeStyle.swift
  - apps/ios/BuyLedger/Core/Dependencies/OrderSourceRepository.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsFeature.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderStatus+Presentation.swift
  - apps/ios/BuyLedger/Core/Persistence/OrderRecord.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardView.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Cards/BLCard.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestConfiguration.swift
  - apps/ios/BuyLedger/Features/AISummary/AISummaryView.swift
  - apps/ios/BuyLedger/App/AppDelegate.swift
  - apps/ios/BuyLedgerTests/CurrencyMetadataCacheTests.swift
  - apps/ios/BuyLedger/Shared/Localization/AppLanguage.swift
  - shared/data-model/schema/PaymentReceiptStatus.yaml
  - apps/ios/BuyLedger/Features/FX/ExchangeRateDTO.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderMergeCandidateSheet.swift
  - shared/data-model/fixtures/expected/typescript/SampleGrade.ts
  - apps/ios/BuyLedgerUITests/Tests/Smoke/HarnessSelfCheckTests.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/FxRateSnapshot.generated.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLSparkline.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/LedgerCustomer.generated.swift
  - apps/ios/BuyLedgerTests/OllamaClientTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/ViewModifiers/BLTypographyModifier.swift
  - shared/data-model/fixtures/expected/kotlin/SamplePreference.kt
  - apps/ios/BuyLedger/Features/App/RootTab.swift
  - apps/ios/BuyLedger/Core/Dependencies/OrderRepository.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLBarChart.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersFeature+StateQuery.swift
  - apps/ios/BuyLedgerTests/CalendarReminderTests.swift
  - apps/ios/BuyLedgerUITests/Screens/QuoteScreen.swift
  - apps/ios/BuyLedgerTests/PersistenceFailureFeatureTests.swift
  - shared/data-model/fixtures/expected/swift/SampleQuote.generated.swift
  - apps/ios/BuyLedgerTests/InsightsAttributionTests.swift
  - apps/ios/BuyLedgerUITests/Screens/SettingsScreen.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestDependencyOverrides.swift
  - apps/ios/BuyLedger/Core/Domain/OrderSummary.swift
  - apps/ios/BuyLedgerTests/BLUITestConfigurationTests.swift
  - apps/ios/BuyLedger/Core/Dependencies/NameLookupOperations.swift
  - apps/ios/BuyLedgerTests/LookupCatalogTests.swift
  - apps/ios/BuyLedgerTests/InsightsStatsTests.swift
  - apps/ios/BuyLedgerTests/OrderStatusTests.swift
  - apps/ios/BuyLedger.xctestplan
  - shared/data-model/fixtures/expected/swift/SampleGrade.generated.swift
  - apps/ios/BuyLedger/Core/Sync/SyncMeta.swift
  - apps/ios/BuyLedger/Core/Domain/FxRateSnapshot.swift
  - apps/ios/BuyLedger/Features/App/RootView.swift
  - shared/data-model/fixtures/expected/swift/SampleStatus.generated.swift
  - apps/ios/BuyLedger/Shared/Extensions/Bundle+Extensions.swift
  - apps/ios/BuyLedger/Core/Persistence/OrderPersistence.swift
  - apps/ios/BuyLedgerTests/TestDependencies.swift
  - shared/data-model/schema/LedgerOrderItem.yaml
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementDestination.swift
  - apps/ios/BuyLedgerUITests/Support/Waiting.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrdersListTests.swift
  - apps/ios/BuyLedgerUITests/Screens/InsightsScreen.swift
  - apps/ios/BuyLedgerUITests/Screens/CampaignEditScreen.swift
  - apps/ios/BuyLedger/Resources/Localizable.xcstrings
  - apps/ios/BuyLedger/Features/Orders/Components/PaymentMethodEditorSheet.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/Money.generated.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderDetailView.swift
  - apps/ios/BuyLedger/Core/Persistence/CurrencyMetadataPersistence.swift
  - apps/ios/BuyLedgerUITests/Support/Assertions.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestSeedProfile.swift
  - apps/ios/BuyLedger/Features/FX/FxView.swift
  - apps/ios/BuyLedgerTests/CampaignSummaryTests.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLMetrics.swift
  - apps/ios/BuyLedgerTests/OrderEditFeatureTests.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupKind.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/quoteViewBaseline.1.png
  - apps/ios/BuyLedger/Shared/Media/PhotoDataProcessor.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderSelectableRow.swift
  - apps/ios/BuyLedger/Core/Dependencies/OpenSettingsClient.swift
  - apps/ios/BuyLedgerUITests/Tests/Campaigns/CampaignCrudTests.swift
  - apps/ios/BuyLedgerTests/AppLockFeatureTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/ViewModifiers/BLHeroCardBackground.swift
  - apps/ios/BuyLedgerTests/AISummaryFeatureTests.swift
  - apps/ios/BuyLedger/Features/Quote/QuoteView.swift
  - apps/ios/BuyLedger/Core/Domain/LedgerOrderItem.swift
  - apps/ios/BuyLedger/Features/App/AppScenePhaseCoordinator.swift
  - apps/ios/BuyLedger/Core/Networking/HTTPMethod.swift
  - apps/ios/BuyLedgerTests/CampaignEditFeatureTests.swift
  - apps/ios/BuyLedgerUITests/Screens/MergeFlowScreen.swift
  - AGENTS.md
  - apps/ios/BuyLedgerUITests/Screens/PhotoViewerScreen.swift
  - apps/ios/BuyLedgerTests/InsightsFeatureTests.swift
  - shared/data-model/fixtures/expected/typescript/SampleStatus.ts
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLTone.swift
  - apps/ios/BuyLedger/Features/Orders/OrderDetailPath.swift
  - apps/ios/BuyLedger/Core/Persistence/CurrencyMetadataRecord.swift
  - apps/ios/BuyLedger/Core/Persistence/PaymentMethodPersistence.swift
  - shared/data-model/fixtures/expected/kotlin/SampleProfile.kt
  - apps/ios/BuyLedgerTests/CampaignIntegrationTests.swift
  - apps/ios/BuyLedgerTests/OrderDraftTests.swift
  - apps/ios/BuyLedger/Resources/GoogleService-Info.example.plist
  - shared/data-model/schema/LedgerCustomer.yaml
  - apps/ios/BuyLedger/Features/Orders/LedgerOrder+OrderMutation.swift
  - apps/ios/BuyLedgerTests/CampaignPersistenceTests.swift
  - apps/ios/BuyLedgerUITests/Support/BLUITestCase.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/CampaignStatus.generated.swift
  - apps/ios/BuyLedger/Features/FX/ExchangeRateClient.swift
  - apps/ios/BuyLedgerTests/AccessibilityConventionScanTests.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersMergeFlowOperations.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsFeature.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLBarChartValue.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLStatusHue.swift
  - apps/ios/BuyLedger/Core/Domain/Campaign+Samples.swift
  - apps/ios/BuyLedgerTests/ProjectionWriteBoundaryTests.swift
  - shared/data-model/fixtures/expected/typescript/SamplePreference.ts
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/dashboardViewBaseline.1.png
  - apps/ios/BuyLedger/Core/Persistence/BuyLedgerSchema.swift
  - apps/ios/BuyLedger/Features/Orders/OrderMergeFeature.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/OrderStatus.generated.swift
  - apps/ios/BuyLedgerTests/ContrastComplianceTests.swift
  - shared/data-model/fixtures/expected/kotlin/SampleSequence.kt
  - apps/ios/BuyLedger/Core/Persistence/OrderSourcePersistence.swift
  - apps/ios/BuyLedger/Resources/PrivacyInfo.xcprivacy
  - shared/data-model/schema/Money.yaml
  - apps/ios/BuyLedgerTests/OrderCalculationTests.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestSeedData.swift
  - apps/ios/BuyLedgerTests/OrderPersistenceTests.swift
  - apps/ios/BuyLedger/Features/App/RootTabLayout.swift
  - apps/ios/BuyLedger/Core/Networking/URLRequestBuilder.swift
  - apps/ios/BuyLedger/Features/App/RootFeature.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersView.swift
  - apps/ios/BuyLedger/Features/Customers/CustomersView.swift
  - apps/ios/BuyLedgerUITests/KeyboardDismissTests.swift
  - apps/ios/BuyLedgerTests/BiometricAuthClientTests.swift
  - apps/ios/BuyLedger/Core/Domain/OrderStatus.swift
  - apps/ios/BuyLedger/Core/Persistence/ReconciliationStatusPersistence.swift
  - apps/ios/BuyLedger/Core/Dependencies/PhotoClient.swift
  - apps/ios/BuyLedger/Shared/Extensions/Image+Extensions.swift
  - apps/ios/BuyLedger/Core/Dependencies/CurrencyMetadataRepository.swift
  - apps/ios/BuyLedgerUITests/Support/ValueParsing.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderEditDirtyTests.swift
  - apps/ios/BuyLedger/Features/Settings/AISummaryModelCatalog.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Avatar/BLAvatar.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderRowView.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersRegularViewMultiSelectBaseline.1.png
  - apps/ios/BuyLedger/Core/Persistence/OrderSourceRecord.swift
  - apps/ios/BuyLedgerUITests/Tests/Smoke/LaunchSmokeTests.swift
  - apps/ios/BuyLedger/Features/AISummary/OllamaClient.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrdersToolbarContent.swift
  - apps/ios/BuyLedgerUITests/Screens/OrderEditScreen.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoThumbnail.swift
  - apps/ios/BuyLedgerTests/NameLookupPersistenceTests.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsStats.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestHarness.swift
  - apps/ios/BuyLedgerTests/OrdersFilterOperationsTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewBaseline.1.png
  - apps/ios/BuyLedgerUITests/Support/Diagnostics.swift
  - apps/ios/BuyLedger/Core/Networking/AppConfiguration.swift
  - shared/data-model/fixtures/expected/kotlin/SampleReceipt.kt
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewMultiSelectBaseline.1.png
  - shared/data-model/schema/LedgerOrder.yaml
  - apps/ios/BuyLedgerUITests/Support/AlertInteraction.swift
  - apps/ios/BuyLedger/Core/Networking/APIError.swift
  - apps/ios/BuyLedger/Core/Networking/HTTPClient.swift
  - shared/data-model/fixtures/expected/typescript/SampleSequence.ts
  - apps/ios/BuyLedger/Features/App/RootSidebarLayout.swift
  - CLAUDE.md
  - apps/ios/BuyLedger/Features/Orders/OrdersCompactView.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignDetailView.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardFeature.swift
  - apps/ios/BuyLedger/Features/App/AppLockFeature.swift
  - apps/ios/BuyLedgerTests/OrderMergeFeatureTests.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignFormatters.swift
  - apps/ios/BuyLedgerTests/FxFeatureTests.swift
  - apps/ios/BuyLedgerTests/PersistenceErrorContractTests.swift
  - apps/ios/BuyLedgerUITests-Performance.xctestplan
  - apps/ios/BuyLedger/Core/Testing/BLUITestHarness.swift
  - apps/ios/BuyLedger/Features/AISummary/OllamaDTO.swift
  - apps/ios/BuyLedger/Core/Persistence/ReconciliationStatusRecord.swift
  - shared/data-model/fixtures/expected/kotlin/SampleStatus.kt
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLFormatters.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewBaseline.1.png
  - apps/ios/BuyLedgerUITests.xctestplan
  - apps/ios/BuyLedger/Features/Orders/OrderEditFeature.swift
  - apps/ios/BuyLedgerTests/CustomersFeatureTests.swift
  - apps/ios/BuyLedgerTests/PhotoDataProcessorTests.swift
  - apps/ios/BuyLedger/Core/Domain/OrderMerge.swift
  - apps/ios/BuyLedgerTests/PersistenceRecoveryTests.swift
  - shared/data-model/fixtures/expected/kotlin/SampleQuote.kt
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/States/DelayedProgressView.swift
  - apps/ios/BuyLedger/Core/Sync/SyncQueueItem.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersFilterOperations.swift
  - shared/data-model/fixtures/schema/sample-trait-matrix.yaml
  - apps/ios/BuyLedger/Core/Domain/Generated/Campaign.generated.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderDetailTests.swift
  - shared/data-model/schema/FxRateSnapshot.yaml
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/persistenceFailureViewBaseline.1.png
  - shared/data-model/fixtures/schema/sample-enums.yaml
  - shared/data-model/fixtures/expected/swift/SampleProfile.generated.swift
  - apps/ios/BuyLedgerTests/SchemaMigrationTests.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersBatchOperations.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFormatters.swift
  - apps/ios/BuyLedgerTests/CampaignReminderFailureTests.swift
  - apps/ios/BuyLedger.xcodeproj/project.pbxproj
  - apps/ios/BuyLedger/Features/App/PersistenceFailureView.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsView.swift
  - apps/ios/BuyLedgerTests/AppConfigurationTests.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFilterSheet.swift
  - apps/ios/BuyLedgerUITests/Support/MenuInteraction.swift
  - shared/data-model/README.md
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/ViewModifiers/BLCardShadow.swift
  - apps/ios/BuyLedgerTests/OrdersLoadStateTests.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OptionPickerSheet.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Badges/BLBadge.swift
  - apps/ios/BuyLedger/Shared/Extensions/Decimal+Extensions.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignListView.swift
  - apps/ios/BuyLedgerTests/OrdersFeaturePerformanceTests.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/LedgerOrder.generated.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupNameEditorSheet.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests.swift
  - apps/ios/BuyLedgerTests/OrdersFeatureTests.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/LedgerOrderItem.generated.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewLongContentBaseline.1.png
  - apps/ios/BuyLedgerTests/BLAccessibilityIDTests.swift
  - apps/ios/BuyLedger/Core/Domain/LedgerOrder+Samples.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLPalette.swift
  - apps/ios/BuyLedgerTests/LookupManagementFeatureTests.swift
  - shared/data-model/fixtures/expected/swift/SampleSequence.generated.swift
  - shared/data-model/fixtures/expected/typescript/SampleQuote.ts
  - apps/ios/BuyLedger/Core/Dependencies/CategoryRepository.swift
  - shared/data-model/fixtures/expected/typescript/SampleReceipt.ts
  - apps/ios/BuyLedger/Core/Persistence/CampaignReminderPersistence.swift
  - apps/ios/CLAUDE.md
  - apps/ios/BuyLedger/Features/Orders/OrderEditView.swift
  - apps/ios/BuyLedgerUITests/Tests/Tools/QuoteTests.swift
  - apps/ios/BuyLedgerUITests/Screens/DashboardScreen.swift
  - apps/ios/BuyLedger/Core/Networking/ExchangeRateClient.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLDonutChart.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignEditView.swift
  - apps/ios/BuyLedgerUITests/Screens/OptionPickerScreen.swift
  - shared/data-model/schema/CurrencyCode.yaml
  - apps/ios/BuyLedger/Features/Orders/OrderDraft.swift
  - apps/ios/BuyLedger/Core/Persistence/CategoryPersistence.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Progress/BLProgressBar.swift
  - apps/ios/BuyLedgerUITests/Tests/Tools/FxTests.swift
  - apps/ios/BuyLedgerUITests/Screens/CampaignsScreen.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupCatalog.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/States/BLLoadFailureView.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementView.swift
  - apps/ios/BuyLedgerTests/HTTPClientTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Chips/BLFilterChip.swift
  - apps/ios/BuyLedgerTests/DashboardFeatureTests.swift
  - apps/ios/BuyLedgerTests/OrdersSearchCancellationTests.swift
  - apps/ios/BuyLedger/Features/App/AppLockView.swift
  - apps/ios/BuyLedgerUITests/Tests/Campaigns/CampaignDetailTests.swift
  - apps/ios/BuyLedger/Core/Testing/BLUITestSeedData.swift
  - apps/ios/BuyLedger/Core/Persistence/CampaignReminderRecord.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsDateRange.swift
  - apps/ios/BuyLedger/Core/Dependencies/CalendarReminderClient.swift
  - .github/workflows/ci.yml
  - apps/ios/BuyLedger/Core/Persistence/NameLookupRecord.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLHeatmapDepth.swift
  - apps/ios/BuyLedger/Core/Diagnostics/CrashDiagnosticsClient.swift
  - apps/ios/BuyLedgerTests/LayerBoundaryTests.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignFeature.swift
  - apps/ios/BuyLedgerTests/SnapshotTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Insights/InsightsTests.swift
  - apps/ios/BuyLedger/App/BuyLedgerApp.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsView.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/CustomerTier.generated.swift
  - apps/ios/BuyLedger/Core/Domain/CurrencyCode.swift
  - apps/ios/BuyLedgerTests/PrivacyManifestTests.swift
  - apps/ios/BuyLedgerTests/PaymentMethodPersistenceTests.swift
  - README.md
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Pickers/OptionPickerSheet.swift
  - apps/ios/BuyLedger/Core/Persistence/CampaignPersistence.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Tags/BLTagPill.swift
  - apps/ios/BuyLedgerUITests/Tests/Smoke/AppLockTests.swift
  - apps/ios/BuyLedgerTests/SettingsFeatureTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Campaigns/CampaignListTests.swift
  - apps/ios/BuyLedger/Features/Settings/AppLanguage.swift
  - shared/data-model/fixtures/expected/swift/SamplePreference.generated.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Status/BLStatusPill.swift
  - apps/ios/BuyLedger/Core/Dependencies/BiometricAuthClient.swift
  - apps/ios/BuyLedgerTests/CampaignFeatureTests.swift
  - apps/ios/BuyLedger/Core/Persistence/PersistenceStoreQuarantineClient.swift
  - apps/ios/BuyLedger/Features/Orders/Components/MergePhotoPickerSheet.swift
  - apps/ios/BuyLedger/Core/Domain/Campaign.swift
  - apps/ios/BuyLedger/Core/Persistence/PersistenceStoreQuarantine.swift
  - apps/ios/BuyLedger/Core/Networking/ExchangeRateDTO.swift
  - apps/ios/BuyLedger.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
  - apps/ios/BuyLedger/Core/Persistence/CategoryRecord.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLTypography.swift
  - apps/ios/BuyLedgerUITests/Screens/RootNavigationScreen.swift
  - apps/ios/BuyLedger/Features/FX/FxRates.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsStorage.swift
  - shared/data-model/fixtures/schema/sample-orders.yaml
  - apps/ios/BuyLedger/Features/App/PersistenceFailureFeature.swift
  - apps/ios/BuyLedger/Core/Persistence/PersistenceError.swift
  - apps/ios/BuyLedgerTests/OrdersBatchOperationsTests.swift
  - apps/ios/BuyLedgerAccessibilityIDs/BLAccessibilityID.swift
  - apps/ios/BuyLedgerUITests/Tests/Customers/CustomersTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Buttons/BLButtonStyle.swift
  - apps/ios/BuyLedgerTests/OrderEditFocusTests.swift
  - apps/ios/BuyLedgerTests/QuoteFeatureTests.swift
  - apps/ios/BuyLedgerTests/TestSuiteIntegrityTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Performance/LaunchPerformanceTests.swift
  - shared/data-model/schema/Campaign.yaml
  - apps/ios/BuyLedger/Core/Domain/FxRates.swift
  - apps/ios/BuyLedger/Core/Dependencies/PaymentMethodRepository.swift
  - apps/ios/BuyLedger/Core/Testing/BLUITestConfiguration.swift
  - apps/ios/BuyLedgerTests/DesignSystemSourceScanTests.swift
  - apps/ios/BuyLedgerTests/ColorContrastTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoViewer.swift
  - apps/ios/README.md
  - apps/ios/BuyLedger/Features/Orders/OrderStatusFilter.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/PaymentReceiptStatus.generated.swift
  - apps/ios/BuyLedgerTests/LocalizationCatalogTests.swift
  - apps/ios/BuyLedgerUITests/Screens/AISummaryScreen.swift
  - apps/ios/BuyLedgerUITests/Screens/CampaignDetailScreen.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardStats.swift
  - apps/ios/BuyLedger/Features/Orders/OrderDatePeriod.swift
  - apps/ios/BuyLedgerTests/APIErrorMappingTests.swift
  - apps/ios/BuyLedger/App/AppLaunchConfigurator.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderMergeTests.swift
  - apps/ios/BuyLedgerTests/NumericInputGroupingScanTests.swift
  - apps/ios/BuyLedger/Core/Persistence/CampaignRecord.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/quoteViewRateUnavailable.1.png
  - apps/ios/BuyLedgerUITests/Screens/FxScreen.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Forms/PaymentMethodEditorSheet.swift
  - shared/data-model/generator/src/datamodel-gen.ts
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewLongIdentifierBaseline.1.png
  - shared/data-model/fixtures/expected/kotlin/SampleGrade.kt
  - shared/data-model/schema/PaymentMethodInfo.yaml
  - apps/ios/BuyLedger/Core/Domain/Generated/PaymentMethodInfo.generated.swift
  - shared/data-model/schema/CampaignStatus.yaml
  - apps/ios/BuyLedgerUITests/Support/SheetInteraction.swift
  - shared/data-model/fixtures/expected/swift/SampleReceipt.generated.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignEditFeature.swift
tests:
  - shared/data-model/generator/test/datamodel-gen.test.ts
-->