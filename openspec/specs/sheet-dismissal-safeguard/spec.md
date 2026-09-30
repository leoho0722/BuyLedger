# sheet-dismissal-safeguard Specification

## Purpose

本規格涵蓋訂單編輯、活動編輯、付款方式編輯三個編輯 sheet 的未儲存變更防護，包括草稿是否變動的判斷 (dirty state)、滑動關閉的攔截、取消時的捨棄確認對話框。不涵蓋 `irreversible-action-safeguard` 所訂的其他暫存變更 sheet (如篩選 sheet) 的防護，以及非刪除類不可逆狀態轉換的確認。

## Requirements

### Requirement: Guard edit sheets against silent data loss on dismissal

Each sheet that holds user input which is not yet committed — the order editor, the campaign editor, the payment method editor, and the orders filter sheet — SHALL track whether that input differs from the values it was opened with (a dirty state). While the sheet is dirty, it SHALL prevent interactive swipe-to-dismiss so that uncommitted input cannot be lost silently. The dirty state SHALL be derived from all uncommitted fields of that sheet, not a partial subset.

For sheets bound to a feature store, the dirty state SHALL be derived from state held by that feature rather than from view-local state, so that it is observable and assertable outside the view layer.

Coverage of all uncommitted fields SHALL be guaranteed structurally rather than by maintaining a parallel list of fields. Where a sheet's uncommitted input is grouped into a single value, the dirty state SHALL be that value compared against the value captured when the sheet opened, so that adding a field cannot omit it from the comparison. A separate fingerprint enumerating the fields SHALL NOT be maintained, because it duplicates the field list and can silently fall out of step with it.

Values that are presentation state rather than user input — focus, navigation route within the sheet, and in-flight picker selections — SHALL NOT contribute to the dirty state.

#### Scenario: Dirty edit sheet resists swipe-to-dismiss

- **WHEN** the user has modified at least one draft field in the order, campaign, or payment method editor and then swipes down to dismiss the sheet
- **THEN** the sheet does not dismiss and the draft is preserved

#### Scenario: Clean edit sheet dismisses freely

- **WHEN** the user opens an editor and swipes down to dismiss without modifying any draft field
- **THEN** the sheet dismisses immediately without any confirmation

#### Scenario: Filter sheet with pending selections resists swipe-to-dismiss

- **WHEN** the user has changed at least one pending selection in the orders filter sheet and then swipes down to dismiss it
- **THEN** the sheet does not dismiss and the pending selections are preserved

#### Scenario: Dirty state is derived from feature state

- **WHEN** the dirty state of a store-bound sheet is inspected
- **THEN** it is computed from values held by that sheet's feature, so a test driving the feature can assert it without rendering the view

#### Scenario: A newly added draft field is covered without any further step

- **WHEN** a new field is added to a sheet's uncommitted input
- **THEN** modifying it makes the sheet dirty, because the dirty state compares the whole grouped value rather than an enumerated list of fields

#### Scenario: Presentation state does not make the sheet dirty

- **WHEN** the user only moves focus between fields, navigates within the sheet, or opens a picker without choosing a value
- **THEN** the sheet is not dirty and dismisses without a confirmation


<!-- @trace
source: orders-feature-decomposition
updated: 2026-08-22
code:
  - apps/ios/BuyLedger/Core/Dependencies/BiometricAuthClient.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OptionPickerSheet.swift
  - apps/ios/BuyLedgerUITests/Screens/PhotoViewerScreen.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignEditView.swift
  - apps/ios/BuyLedger/Core/Persistence/NameLookupPersistence.swift
  - apps/ios/BuyLedger/Features/App/RootTabLayout.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewBaseline.1.png
  - apps/ios/BuyLedger/Core/Dependencies/CampaignReminderRepository.swift
  - apps/ios/BuyLedger/Core/Persistence/NameLookupRecord.swift
  - apps/ios/BuyLedgerUITests/Screens/OrderDetailScreen.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardStats.swift
  - apps/ios/BuyLedgerTests/LookupManagementFeatureTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewLongContentBaseline.1.png
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Tags/BLTagPill.swift
  - apps/ios/BuyLedgerUITests/Support/Diagnostics.swift
  - apps/ios/BuyLedgerTests/BLPhotoViewerTests.swift
  - apps/ios/BuyLedgerTests/CampaignSummaryTests.swift
  - apps/ios/BuyLedgerTests/ContrastComplianceTests.swift
  - apps/ios/BuyLedger/Features/Customers/CustomersFeature.swift
  - apps/ios/BuyLedgerUITests/Support/SheetInteraction.swift
  - apps/ios/BuyLedgerTests/ExchangeRateClientTests.swift
  - apps/ios/BuyLedgerTests/PersistenceRecoveryTests.swift
  - apps/ios/BuyLedgerTests/DashboardFeatureTests.swift
  - apps/ios/BuyLedgerTests/CampaignFeatureTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Chips/BLFilterChip.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderStatus+Presentation.swift
  - apps/ios/BuyLedger/Features/Orders/OrderEditFeature.swift
  - shared/data-model/fixtures/expected/swift/SampleQuote.generated.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/AISummaryTests.swift
  - apps/ios/BuyLedger/Core/Networking/ExchangeRateDTO.swift
  - apps/ios/BuyLedger/Features/Quote/QuoteFeature.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLHeatmapDepth.swift
  - apps/ios/BuyLedgerTests/LocalizationCatalogTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoThumbnail.swift
  - apps/ios/BuyLedger/Features/FX/ExchangeRateDTO.swift
  - apps/ios/BuyLedger/Resources/PrivacyInfo.xcprivacy
  - apps/ios/BuyLedger/Shared/Media/PhotoDataProcessor.swift
  - apps/ios/BuyLedger/Resources/InfoPlist.xcstrings
  - apps/ios/BuyLedger/Core/Dependencies/NameLookupOperations.swift
  - apps/ios/BuyLedger/Core/Persistence/PaymentMethodRecord.swift
  - apps/ios/BuyLedgerTests/InsightsAttributionTests.swift
  - apps/ios/BuyLedger/Core/Domain/OrderSummary.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsFeature.swift
  - apps/ios/BuyLedger/Features/App/PersistenceFailureFeature.swift
  - apps/ios/BuyLedgerTests/CurrencyMetadataCacheTests.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersMergeFlowOperations.swift
  - apps/ios/BuyLedgerUITests/Support/Waiting.swift
  - apps/ios/BuyLedgerTests/FxFeatureTests.swift
  - apps/ios/BuyLedgerTests/NumericInputGroupingScanTests.swift
  - apps/ios/BuyLedger/Resources/Localizable.xcstrings
  - apps/ios/BuyLedgerTests/OrderMergeTests.swift
  - apps/ios/BuyLedgerUITests/Screens/Screen.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoViewer.swift
  - apps/ios/BuyLedger/Core/Dependencies/PaymentMethodRepository.swift
  - apps/ios/BuyLedger/Features/App/AppScenePhaseCoordinator.swift
  - apps/ios/BuyLedgerUITests/Screens/QuoteScreen.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrdersToolbarContent.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLSparkline.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/quoteViewRateUnavailable.1.png
  - apps/ios/BuyLedger/Core/Dependencies/CategoryRepository.swift
  - apps/ios/BuyLedgerTests/PhotoDataProcessorTests.swift
  - apps/ios/BuyLedger/Core/Persistence/CampaignReminderRecord.swift
  - apps/ios/BuyLedgerTests/OrderDraftTests.swift
  - shared/data-model/fixtures/expected/typescript/SamplePreference.ts
  - apps/ios/BuyLedger/Features/Orders/OrderEditView.swift
  - apps/ios/BuyLedger/Features/Settings/AppLanguage.swift
  - apps/ios/BuyLedgerTests/AppScenePhaseCoordinatorTests.swift
  - apps/ios/BuyLedger/Core/Persistence/OrderSourceRecord.swift
  - apps/ios/BuyLedger/Core/Domain/FxRates.swift
  - apps/ios/BuyLedger/Features/Orders/LedgerOrder+OrderMutation.swift
  - apps/ios/BuyLedger/Features/App/RootFeature.swift
  - apps/ios/BuyLedger.xctestplan
  - apps/ios/BuyLedgerTests/OrdersFeatureTests.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/CustomerTier.generated.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests.swift
  - apps/ios/BuyLedger/Features/FX/FxRates.swift
  - apps/ios/BuyLedger/Features/Settings/AISummaryModelCatalog.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestDependencyOverrides.swift
  - apps/ios/BuyLedgerUITests/Screens/InsightsScreen.swift
  - apps/ios/BuyLedger/Core/Domain/Campaign+Samples.swift
  - apps/ios/BuyLedgerUITests/Screens/MergeFlowScreen.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsView.swift
  - apps/ios/BuyLedgerUITests.xctestplan
  - apps/ios/BuyLedgerUITests/Screens/AISummaryScreen.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/PaymentMethodInfo.generated.swift
  - apps/ios/BuyLedger/Core/Networking/APIError.swift
  - apps/ios/BuyLedgerUITests/Screens/OrderEditScreen.swift
  - apps/ios/BuyLedgerUITests/Screens/CustomersScreen.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignDetailView.swift
  - apps/ios/BuyLedgerTests/HTTPClientTests.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderSelectableRow.swift
  - shared/data-model/fixtures/expected/swift/SamplePreference.generated.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsView.swift
  - apps/ios/BuyLedger/Core/Domain/FxRateSnapshot.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderCreateTests.swift
  - apps/ios/BuyLedgerUITests/Screens/OptionPickerScreen.swift
  - apps/ios/BuyLedger/App/AppLaunchConfigurator.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLFormatters.swift
  - shared/data-model/schema/Campaign.yaml
  - apps/ios/BuyLedger/Features/AISummary/AISummaryFeature.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewMultiSelectBaseline.1.png
  - shared/data-model/fixtures/expected/swift/SampleProfile.generated.swift
  - apps/ios/BuyLedgerUITests/Support/ValueParsing.swift
  - apps/ios/BuyLedger/Core/Persistence/CurrencyMetadataPersistence.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignSummary.swift
  - apps/ios/BuyLedgerUITests/KeyboardDismissTests.swift
  - shared/data-model/schema/LedgerOrderItem.yaml
  - apps/ios/BuyLedgerUITests/Tests/Smoke/HarnessSelfCheckTests.swift
  - apps/ios/CLAUDE.md
  - apps/ios/BuyLedgerUITests/Tests/Campaigns/CampaignDetailTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Smoke/AppLockTests.swift
  - shared/data-model/fixtures/expected/kotlin/SampleReceipt.kt
  - shared/data-model/schema/OrderStatus.yaml
  - apps/ios/BuyLedger/Core/Testing/BLUITestSeedData.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsSnapshot.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Badges/BLBadge.swift
  - apps/ios/BuyLedgerTests/OrderStatusTests.swift
  - apps/ios/BuyLedger/Core/Testing/BLUITestDependencyOverrides.swift
  - apps/ios/BuyLedger/Core/Networking/HTTPClient.swift
  - apps/ios/BuyLedgerUITests/Screens/AppLockScreen.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLPalette.swift
  - apps/ios/BuyLedgerTests/BLFormattersTests.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementView.swift
  - apps/ios/BuyLedger/Core/Domain/LedgerOrder+Samples.swift
  - apps/ios/BuyLedger/App/BuyLedgerApp.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersFeature.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Progress/BLProgressBar.swift
  - apps/ios/BuyLedgerUITests/Screens/CampaignDetailScreen.swift
  - apps/ios/BuyLedger/Core/Networking/HTTPMethod.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift
  - apps/ios/BuyLedger/Core/Persistence/ReconciliationStatusRecord.swift
  - apps/ios/BuyLedger/Features/App/RootSidebarLayout.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFilterSheet.swift
  - apps/ios/BuyLedgerTests/AppConfigurationTests.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/PaymentReceiptStatus.generated.swift
  - shared/data-model/fixtures/expected/typescript/SampleQuote.ts
  - apps/ios/BuyLedger/Core/Persistence/OrderRecord.swift
  - apps/ios/BuyLedgerUITests/Support/LaunchOptions.swift
  - apps/ios/BuyLedgerTests/NameLookupPersistenceTests.swift
  - apps/ios/BuyLedger.xcodeproj/xcshareddata/xcschemes/BuyLedger.xcscheme
  - apps/ios/BuyLedger/App/Testing/BLUITestSeedProfile.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersFilterOperations.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Cards/BLCard.swift
  - apps/ios/BuyLedgerTests/LookupCatalogTests.swift
  - AGENTS.md
  - apps/ios/BuyLedger/Core/Domain/Generated/LedgerOrderItem.generated.swift
  - shared/data-model/fixtures/schema/sample-orders.yaml
  - apps/ios/BuyLedger/Features/FX/FxView.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLStatusHue.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/States/BLLoadFailureView.swift
  - apps/ios/BuyLedger/Core/Testing/BLUITestHarness.swift
  - apps/ios/BuyLedgerUITests/Tests/Tools/QuoteTests.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsStats.swift
  - apps/ios/BuyLedger/Core/Networking/URLRequestBuilder.swift
  - apps/ios/BuyLedgerTests/CampaignReminderFailureTests.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/LedgerOrder.generated.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewBaseline.1.png
  - shared/data-model/fixtures/expected/kotlin/SampleStatus.kt
  - apps/ios/BuyLedger/Features/Orders/OrderDatePeriod.swift
  - apps/ios/BuyLedger/Features/Orders/Components/MergePhotoPickerSheet.swift
  - apps/ios/BuyLedgerTests/DashboardStatsTests.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFormatters.swift
  - apps/ios/BuyLedgerTests/APIErrorMappingTests.swift
  - apps/ios/BuyLedger/Core/Sync/SyncQueueItem.swift
  - apps/ios/BuyLedgerUITests/Tests/Campaigns/CampaignListTests.swift
  - shared/data-model/fixtures/expected/kotlin/SampleProfile.kt
  - apps/ios/BuyLedgerTests/OrderPersistenceTests.swift
  - apps/ios/BuyLedger/Shared/Extensions/Color+Extensions.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestHarness.swift
  - apps/ios/BuyLedgerTests/InsightsFeatureTests.swift
  - shared/data-model/generator/src/datamodel-gen.ts
  - apps/ios/BuyLedger/Core/Persistence/PaymentMethodPersistence.swift
  - apps/ios/BuyLedgerTests/SchemaMigrationTests.swift
  - apps/ios/BuyLedger/Core/Domain/Campaign.swift
  - apps/ios/BuyLedger/Features/Orders/OrderDetailPath.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersFeature+StateQuery.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupCatalog.swift
  - apps/ios/BuyLedger/App/AppDelegate.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderMergeCandidateSheet.swift
  - apps/ios/BuyLedgerTests/LayerBoundaryTests.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardView.swift
  - apps/ios/BuyLedgerUITests/Screens/FxScreen.swift
  - apps/ios/BuyLedger/Features/Customers/CustomerRankBadgeStyle.swift
  - apps/ios/BuyLedgerTests/AppLockFeatureTests.swift
  - apps/ios/BuyLedgerUITests/Support/AppNavigator.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderEditDirtyTests.swift
  - apps/ios/BuyLedger/Core/Dependencies/CurrencyMetadataRepository.swift
  - apps/ios/BuyLedger.xcodeproj/project.pbxproj
  - apps/ios/BuyLedger/Features/Orders/Components/OrderRowView.swift
  - apps/ios/BuyLedger/Core/Dependencies/CalendarReminderClient.swift
  - apps/ios/BuyLedger/Resources/GoogleService-Info.example.plist
  - shared/data-model/fixtures/expected/kotlin/SampleSequence.kt
  - apps/ios/BuyLedger/Core/Persistence/OrderPersistence.swift
  - shared/data-model/schema/FxRateSnapshot.yaml
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/ViewModifiers/BLTypographyModifier.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/FxRateSnapshot.generated.swift
  - apps/ios/BuyLedger/Shared/Extensions/Image+Extensions.swift
  - apps/ios/BuyLedger/Core/Dependencies/OrderRepository.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignListView.swift
  - apps/ios/BuyLedger/Core/Persistence/CampaignReminderPersistence.swift
  - apps/ios/BuyLedger/Core/Domain/OrderStatus.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/quoteViewBaseline.1.png
  - apps/ios/BuyLedger/Features/Orders/OrderMergeFeature.swift
  - apps/ios/BuyLedgerUITests/Support/MenuInteraction.swift
  - apps/ios/BuyLedger/Core/Persistence/PersistenceError.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestSeedData.swift
  - apps/ios/BuyLedger/Core/Domain/OrderMerge.swift
  - apps/ios/BuyLedger/Core/Sync/SyncMeta.swift
  - apps/ios/BuyLedgerUITests/Tests/Smoke/LaunchSmokeTests.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignEditFeature.swift
  - apps/ios/BuyLedgerTests/CampaignEditFeatureTests.swift
  - apps/ios/BuyLedgerUITests/Support/AlertInteraction.swift
  - apps/ios/BuyLedger/Core/Dependencies/OrderSourceRepository.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/persistenceFailureViewBaseline.1.png
  - shared/data-model/schema/PaymentReceiptStatus.yaml
  - apps/ios/BuyLedgerTests/BiometricAuthClientTests.swift
  - apps/ios/BuyLedgerTests/ColorContrast.swift
  - apps/ios/BuyLedgerUITests/Screens/RootNavigationScreen.swift
  - shared/data-model/fixtures/expected/swift/SampleSequence.generated.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/States/BLDelayedProgressView.swift
  - apps/ios/BuyLedgerTests/AccessibilityConventionScanTests.swift
  - apps/ios/BuyLedgerUITests/Support/TextInput.swift
  - apps/ios/BuyLedger/Shared/Extensions/Bundle+Extensions.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderDetailTests.swift
  - apps/ios/BuyLedger/Core/Domain/CurrencyCode.swift
  - shared/data-model/fixtures/expected/swift/SampleGrade.generated.swift
  - apps/ios/BuyLedger/Features/Orders/OrderStatusFilter.swift
  - apps/ios/BuyLedgerTests/OrderEditFeatureTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLTypography.swift
  - apps/ios/BuyLedgerTests/CustomersFeatureTests.swift
  - apps/ios/BuyLedgerUITests/Screens/OrdersScreen.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderDetailView.swift
  - apps/ios/BuyLedger/Core/Dependencies/CampaignRepository.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Pickers/OptionPickerSheet.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Avatar/BLAvatar.swift
  - shared/data-model/schema/LedgerCustomer.yaml
  - apps/ios/BuyLedger/Features/Lookups/LookupNameEditorSheet.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLDonutChart.swift
  - apps/ios/BuyLedgerTests/ColorContrastTests.swift
  - apps/ios/BuyLedgerUITests/Screens/CampaignsScreen.swift
  - apps/ios/BuyLedger/Features/More/MoreView.swift
  - apps/ios/BuyLedger/Core/Persistence/ReconciliationStatusPersistence.swift
  - README.md
  - shared/data-model/fixtures/expected/kotlin/SampleQuote.kt
  - apps/ios/BuyLedger/Features/Campaigns/CampaignFeature.swift
  - apps/ios/BuyLedger/Features/FX/ExchangeRateClient.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLDonutSegment.swift
  - apps/ios/BuyLedgerTests/InsightsStatsTests.swift
  - apps/ios/BuyLedger/Shared/Localization/AppLanguage.swift
  - apps/ios/BuyLedger/Core/Persistence/CategoryPersistence.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/ViewModifiers/BLHeroCardBackground.swift
  - apps/ios/BuyLedger/Core/Dependencies/PhotoClient.swift
  - apps/ios/BuyLedgerTests/CampaignPersistenceTests.swift
  - apps/ios/BuyLedgerTests/OrderMergeFeatureTests.swift
  - apps/ios/BuyLedger/Features/AISummary/AISummaryView.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLTone.swift
  - apps/ios/BuyLedgerTests/OrdersFeaturePerformanceTests.swift
  - apps/ios/BuyLedgerTests/BLAccessibilityIDTests.swift
  - shared/data-model/fixtures/expected/typescript/SampleProfile.ts
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderMergeTests.swift
  - apps/ios/BuyLedger/Features/App/RootView.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLMetrics.swift
  - shared/data-model/fixtures/expected/typescript/SampleGrade.ts
  - apps/ios/BuyLedger/Features/Orders/OrdersBatchOperations.swift
  - apps/ios/BuyLedgerTests/AISummaryFeatureTests.swift
  - apps/ios/BuyLedger/Features/AISummary/OllamaClient.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsFeature.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Buttons/BLButtonStyle.swift
  - shared/data-model/fixtures/expected/swift/SampleReceipt.generated.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/States/DelayedProgressView.swift
  - apps/ios/BuyLedger/Features/Quote/QuoteView.swift
  - apps/ios/BuyLedgerUITests/Screens/DashboardScreen.swift
  - apps/ios/BuyLedgerUITests/Support/BLUITestCase.swift
  - .github/workflows/ci.yml
  - shared/data-model/fixtures/schema/sample-enums.yaml
  - apps/ios/BuyLedger/Features/App/RootTab.swift
  - apps/ios/BuyLedgerTests/TestDependencies.swift
  - apps/ios/BuyLedger/Core/Dependencies/ReconciliationStatusRepository.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersView.swift
  - apps/ios/BuyLedger/Core/Persistence/PersistenceStoreQuarantine.swift
  - apps/ios/BuyLedger/Core/Persistence/PersistenceContainer.swift
  - apps/ios/BuyLedger/Core/Testing/BLUITestSeedProfile.swift
  - apps/ios/BuyLedgerUITests/Tests/Customers/CustomersTests.swift
  - apps/ios/README.md
  - apps/ios/BuyLedger/Core/Persistence/OrderSourcePersistence.swift
  - apps/ios/BuyLedger/Core/Persistence/PersistenceStoreQuarantineClient.swift
  - apps/ios/BuyLedgerTests/TestSuiteIntegrityTests.swift
  - apps/ios/BuyLedgerUITests/Screens/SettingsScreen.swift
  - apps/ios/BuyLedger/Core/Diagnostics/CrashDiagnosticsClient.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementDestination.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/ViewModifiers/BLCardShadow.swift
  - apps/ios/BuyLedger/Core/Persistence/CategoryRecord.swift
  - apps/ios/BuyLedgerUITests/Tests/Insights/InsightsTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Status/BLStatusPill.swift
  - apps/ios/BuyLedgerUITests-Performance.xctestplan
  - apps/ios/BuyLedger/Core/Domain/Generated/LedgerCustomer.generated.swift
  - apps/ios/BuyLedger/Resources/Info.plist
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLBarChart.swift
  - apps/ios/BuyLedgerTests/CalendarReminderTests.swift
  - apps/ios/BuyLedger/Features/Orders/OrderDraft.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestConfiguration.swift
  - shared/data-model/schema/LedgerOrder.yaml
  - apps/ios/BuyLedger/Features/Customers/CustomersView.swift
  - shared/data-model/fixtures/expected/typescript/SampleStatus.ts
  - apps/ios/BuyLedgerTests/OllamaClientTests.swift
  - apps/ios/BuyLedgerTests/SettingsFeatureTests.swift
  - apps/ios/BuyLedgerTests/OrdersLoadStateTests.swift
  - apps/ios/BuyLedger/Features/App/AppLockView.swift
  - apps/ios/BuyLedger/Features/App/SidebarBadgeCounts.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupKind.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Forms/PaymentMethodEditorSheet.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/CampaignStatus.generated.swift
  - apps/ios/BuyLedger/Features/App/PersistenceFailureView.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewLongIdentifierBaseline.1.png
  - apps/ios/BuyLedger/Core/Persistence/CampaignRecord.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignFormatters.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/CurrencyCode.generated.swift
  - apps/ios/BuyLedger/Core/Domain/LedgerOrderItem.swift
  - apps/ios/BuyLedgerTests/OrdersSearchCancellationTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrdersListTests.swift
  - apps/ios/BuyLedger/Features/App/AppLockFeature.swift
  - apps/ios/BuyLedgerTests/OrderEditFocusTests.swift
  - shared/data-model/fixtures/expected/typescript/SampleReceipt.ts
  - shared/data-model/fixtures/expected/swift/SampleStatus.generated.swift
  - shared/data-model/schema/CurrencyCode.yaml
  - apps/ios/BuyLedger/Shared/Extensions/Decimal+Extensions.swift
  - apps/ios/BuyLedgerTests/CampaignIntegrationTests.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/OrderStatus.generated.swift
  - apps/ios/BuyLedgerTests/PersistenceFailureFeatureTests.swift
  - apps/ios/BuyLedgerTests/PrivacyManifestTests.swift
  - apps/ios/BuyLedgerTests/OrdersBatchOperationsTests.swift
  - apps/ios/BuyLedger/Core/Persistence/CampaignPersistence.swift
  - apps/ios/BuyLedgerUITests/Tests/Campaigns/CampaignCrudTests.swift
  - apps/ios/BuyLedgerTests/PersistenceErrorContractTests.swift
  - shared/data-model/README.md
  - apps/ios/BuyLedger/Core/Domain/Generated/Campaign.generated.swift
  - apps/ios/BuyLedgerTests/SnapshotTests.swift
  - shared/data-model/fixtures/expected/typescript/SampleSequence.ts
  - apps/ios/BuyLedger/Core/Networking/ExchangeRateClient.swift
  - apps/ios/BuyLedgerUITests/Support/Scrolling.swift
  - apps/ios/BuyLedgerTests/OrderCalculationTests.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/Money.generated.swift
  - apps/ios/BuyLedger/Core/Domain/LedgerOrder.swift
  - apps/ios/BuyLedgerUITests/PhotoViewerPagingTests.swift
  - shared/data-model/schema/CampaignStatus.yaml
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/dashboardViewBaseline.1.png
  - apps/ios/BuyLedgerTests/ProjectionWriteBoundaryTests.swift
  - apps/ios/BuyLedger/Core/Dependencies/OpenSettingsClient.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersRegularViewMultiSelectBaseline.1.png
  - apps/ios/BuyLedger/Core/Dependencies/TelemetryClient.swift
  - shared/data-model/fixtures/expected/kotlin/SamplePreference.kt
  - apps/ios/BuyLedgerTests/DesignSystemSourceScanTests.swift
  - apps/ios/BuyLedgerUITests/Support/Assertions.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsStorage.swift
  - shared/data-model/schema/CustomerTier.yaml
  - apps/ios/BuyLedger/Core/Networking/AppConfiguration.swift
  - apps/ios/BuyLedgerTests/BLUITestConfigurationTests.swift
  - shared/data-model/schema/PaymentMethodInfo.yaml
  - apps/ios/BuyLedger/Features/AISummary/OllamaDTO.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLBarChartValue.swift
  - apps/ios/BuyLedger.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewMergeContextBaseline.1.png
  - apps/ios/BuyLedger/Features/Orders/Components/PaymentMethodEditorSheet.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersCompactView.swift
  - apps/ios/BuyLedgerUITests/Tests/Tools/FxTests.swift
  - shared/data-model/fixtures/schema/sample-trait-matrix.yaml
  - apps/ios/BuyLedger/Core/Testing/BLUITestConfiguration.swift
  - shared/data-model/schema/Money.yaml
  - apps/ios/BuyLedger/Features/Dashboard/DashboardFeature.swift
  - apps/ios/BuyLedger/Features/FX/FxFeature.swift
  - apps/ios/BuyLedgerUITests/Tests/Performance/LaunchPerformanceTests.swift
  - apps/ios/BuyLedgerUITests/Screens/CampaignEditScreen.swift
  - apps/ios/BuyLedgerTests/QuoteFeatureTests.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsDateRange.swift
  - apps/ios/BuyLedgerTests/OrdersFilterOperationsTests.swift
  - apps/ios/BuyLedger/Core/Persistence/CurrencyMetadataRecord.swift
  - apps/ios/BuyLedgerAccessibilityIDs/BLAccessibilityID.swift
  - CLAUDE.md
  - shared/data-model/fixtures/expected/kotlin/SampleGrade.kt
  - apps/ios/BuyLedgerTests/PaymentMethodPersistenceTests.swift
  - apps/ios/BuyLedger/Core/Persistence/BuyLedgerSchema.swift
tests:
  - shared/data-model/generator/test/datamodel-gen.test.ts
-->

---
### Requirement: Confirm discarding unsaved changes when cancelling

When an editing sheet is dirty and the user taps its cancel control, the sheet SHALL present a confirmation dialog offering a destructive "discard changes" choice and a non-destructive "keep editing" choice, rather than dismissing directly. Choosing discard SHALL dismiss the sheet without saving; choosing keep editing SHALL leave the sheet open with the draft intact. When the sheet is not dirty, the cancel control SHALL dismiss directly without a confirmation dialog.

#### Scenario: Cancel with unsaved changes asks for confirmation

- **WHEN** the user has modified a draft field and taps the cancel control
- **THEN** a confirmation dialog appears with "discard changes" (destructive) and "keep editing" options

#### Scenario: Discard confirmed dismisses without saving

- **WHEN** the confirmation dialog is showing and the user chooses "discard changes"
- **THEN** the sheet dismisses and no draft changes are persisted

#### Scenario: Keep editing returns to the form

- **WHEN** the confirmation dialog is showing and the user chooses "keep editing"
- **THEN** the confirmation dialog closes and the sheet stays open with the draft unchanged

#### Scenario: Cancel without changes dismisses directly

- **WHEN** the user taps the cancel control without having modified any draft field
- **THEN** the sheet dismisses immediately without a confirmation dialog

<!-- @trace
source: sheet-hig-compliance
updated: 2026-07-19
code:
  - apps/ios/BuyLedger.xcodeproj/project.pbxproj
  - apps/ios/BuyLedger/Features/Orders/OrderEditFeature.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignEditView.swift
  - apps/ios/BuyLedger/Features/Orders/Components/PaymentMethodEditorSheet.swift
  - apps/ios/BuyLedger/Features/Orders/OrderMergeFeature.swift
  - apps/ios/BuyLedger/Resources/InfoPlist.xcstrings
  - apps/ios/BuyLedgerTests/CampaignEditFeatureTests.swift
  - apps/ios/BuyLedgerTests/OrderMergeFeatureTests.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignEditFeature.swift
  - apps/ios/BuyLedgerTests/CampaignFeatureTests.swift
  - apps/ios/BuyLedgerTests/OrderEditFeatureTests.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderMergeCandidateSheet.swift
  - apps/ios/BuyLedger/Resources/Localizable.xcstrings
  - apps/ios/CLAUDE.md
  - apps/ios/BuyLedger/Features/Orders/Components/OptionPickerSheet.swift
  - apps/ios/BuyLedger/Features/Orders/OrderEditView.swift
-->