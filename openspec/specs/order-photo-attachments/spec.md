# order-photo-attachments Specification

## Purpose

管理訂單編輯表單中訂單所附加的照片：透過原生照片選擇器最多挑選 5 張影像、儲存前正規化、以全螢幕滑動瀏覽檢視、刪除個別照片，並將照片與訂單記錄一同保存於 SwiftData，使其能撐過 App 重啟與 schema 遷移。

## Requirements

### Requirement: Attach photos to an order via the native photo picker

The order edit form SHALL provide an order-photos section that opens the system PhotosPicker in multiple-selection mode filtered to images. An order SHALL hold at most 5 photos. The picker SHALL limit selection to the remaining capacity (5 minus the photos already attached), and the reducer SHALL enforce the cap by truncating any imported batch that would exceed 5, regardless of what the picker returns.

#### Scenario: Adding photos within capacity

- **WHEN** the user picks 3 photos while the draft has 0 photos
- **THEN** the draft contains 3 photos, appended in selection order

#### Scenario: Cap is enforced at 5 photos

- **WHEN** an import would push the photo count past 5
- **THEN** photos are appended in order only up to the cap and the excess is discarded

##### Example: boundary cases for the photo cap

| Existing photos | Imported batch | Resulting photos | Notes |
| --------------- | -------------- | ---------------- | ----- |
| 0 | 5 | 5 | full batch accepted |
| 3 | 4 | 5 (3 existing + first 2 imported) | excess discarded |
| 5 | 1 | 5 (unchanged) | already full |

#### Scenario: Add control unavailable when full

- **WHEN** the draft already has 5 photos
- **THEN** the add-photos control is not available until a photo is deleted


<!-- @trace
source: add-order-photos
updated: 2026-06-06
code:
  - apps/apple/BuyLedger/Core/Dependencies/PhotoClient.swift
  - apps/apple/BuyLedger/Features/App/RootFeature.swift
  - apps/apple/BuyLedgerTests/CampaignIntegrationTests.swift
  - apps/apple/BuyLedger/Features/Orders/OrderEditView.swift
  - apps/apple/BuyLedgerTests/OrderEditFeatureTests.swift
  - apps/apple/BuyLedgerTests/OrderPersistenceTests.swift
  - apps/apple/BuyLedger/Features/Orders/OrderEditFeature.swift
  - apps/apple/BuyLedger/Features/Orders/OrdersFeature.swift
  - apps/apple/BuyLedgerTests/OrderCalculationTests.swift
  - apps/apple/BuyLedgerTests/RootFeatureTests.swift
  - apps/apple/BuyLedgerTests/SchemaMigrationTests.swift
  - apps/apple/BuyLedgerTests/OrdersFeaturePerformanceTests.swift
  - apps/apple/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoViewer.swift
  - apps/apple/BuyLedger/Core/Domain/LedgerOrder+Samples.swift
  - apps/apple/BuyLedger/Shared/Media/PhotoDataProcessor.swift
  - apps/apple/BuyLedger/Core/Persistence/OrderRecord.swift
  - apps/apple/BuyLedger/Core/Persistence/BuyLedgerSchema.swift
  - apps/apple/BuyLedgerTests/PhotoDataProcessorTests.swift
  - apps/apple/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoThumbnail.swift
  - apps/apple/BuyLedger/Core/Persistence/PersistenceContainer.swift
  - apps/apple/BuyLedgerTests/CampaignSummaryTests.swift
  - apps/apple/BuyLedger/Shared/DesignSystem/Foundations/Image+PhotoData.swift
  - apps/apple/BuyLedgerTests/OrdersFeatureTests.swift
  - apps/apple/BuyLedger/Core/Domain/LedgerOrder.swift
  - apps/apple/BuyLedger/Core/Domain/Campaign+Samples.swift
  - apps/apple/BuyLedgerTests/SnapshotTests.swift
  - CLAUDE.md
-->

---
### Requirement: Imported photos are normalized before storage

Each successfully loaded photo SHALL be downscaled so that its longest edge is at most 1600 pixels and re-encoded as JPEG before entering the draft. A picker item whose data fails to load or decode SHALL be skipped without aborting the import of the remaining items and without surfacing an error alert.

#### Scenario: Oversized photo is downscaled

- **WHEN** the user picks a 4032x3024 photo
- **THEN** the stored photo data is a JPEG whose longest edge is at most 1600 pixels

#### Scenario: Failed item is skipped silently

- **WHEN** the user picks 3 photos and one of them fails to load
- **THEN** the 2 successfully loaded photos are appended and no error alert is shown


<!-- @trace
source: add-order-photos
updated: 2026-06-06
code:
  - apps/apple/BuyLedger/Core/Dependencies/PhotoClient.swift
  - apps/apple/BuyLedger/Features/App/RootFeature.swift
  - apps/apple/BuyLedgerTests/CampaignIntegrationTests.swift
  - apps/apple/BuyLedger/Features/Orders/OrderEditView.swift
  - apps/apple/BuyLedgerTests/OrderEditFeatureTests.swift
  - apps/apple/BuyLedgerTests/OrderPersistenceTests.swift
  - apps/apple/BuyLedger/Features/Orders/OrderEditFeature.swift
  - apps/apple/BuyLedger/Features/Orders/OrdersFeature.swift
  - apps/apple/BuyLedgerTests/OrderCalculationTests.swift
  - apps/apple/BuyLedgerTests/RootFeatureTests.swift
  - apps/apple/BuyLedgerTests/SchemaMigrationTests.swift
  - apps/apple/BuyLedgerTests/OrdersFeaturePerformanceTests.swift
  - apps/apple/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoViewer.swift
  - apps/apple/BuyLedger/Core/Domain/LedgerOrder+Samples.swift
  - apps/apple/BuyLedger/Shared/Media/PhotoDataProcessor.swift
  - apps/apple/BuyLedger/Core/Persistence/OrderRecord.swift
  - apps/apple/BuyLedger/Core/Persistence/BuyLedgerSchema.swift
  - apps/apple/BuyLedgerTests/PhotoDataProcessorTests.swift
  - apps/apple/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoThumbnail.swift
  - apps/apple/BuyLedger/Core/Persistence/PersistenceContainer.swift
  - apps/apple/BuyLedgerTests/CampaignSummaryTests.swift
  - apps/apple/BuyLedger/Shared/DesignSystem/Foundations/Image+PhotoData.swift
  - apps/apple/BuyLedgerTests/OrdersFeatureTests.swift
  - apps/apple/BuyLedger/Core/Domain/LedgerOrder.swift
  - apps/apple/BuyLedger/Core/Domain/Campaign+Samples.swift
  - apps/apple/BuyLedgerTests/SnapshotTests.swift
  - CLAUDE.md
-->

---
### Requirement: Delete an attached photo

Each attached photo SHALL be rendered as a thumbnail with a delete control that removes exactly that photo from the draft. The removal SHALL take effect in persistence when the order is saved.

#### Scenario: Deleting the middle photo preserves the order of the rest

- **GIVEN** the draft photos are [A, B, C]
- **WHEN** the user taps delete on B
- **THEN** the draft photos are [A, C] in that order


<!-- @trace
source: add-order-photos
updated: 2026-06-06
code:
  - apps/apple/BuyLedger/Core/Dependencies/PhotoClient.swift
  - apps/apple/BuyLedger/Features/App/RootFeature.swift
  - apps/apple/BuyLedgerTests/CampaignIntegrationTests.swift
  - apps/apple/BuyLedger/Features/Orders/OrderEditView.swift
  - apps/apple/BuyLedgerTests/OrderEditFeatureTests.swift
  - apps/apple/BuyLedgerTests/OrderPersistenceTests.swift
  - apps/apple/BuyLedger/Features/Orders/OrderEditFeature.swift
  - apps/apple/BuyLedger/Features/Orders/OrdersFeature.swift
  - apps/apple/BuyLedgerTests/OrderCalculationTests.swift
  - apps/apple/BuyLedgerTests/RootFeatureTests.swift
  - apps/apple/BuyLedgerTests/SchemaMigrationTests.swift
  - apps/apple/BuyLedgerTests/OrdersFeaturePerformanceTests.swift
  - apps/apple/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoViewer.swift
  - apps/apple/BuyLedger/Core/Domain/LedgerOrder+Samples.swift
  - apps/apple/BuyLedger/Shared/Media/PhotoDataProcessor.swift
  - apps/apple/BuyLedger/Core/Persistence/OrderRecord.swift
  - apps/apple/BuyLedger/Core/Persistence/BuyLedgerSchema.swift
  - apps/apple/BuyLedgerTests/PhotoDataProcessorTests.swift
  - apps/apple/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoThumbnail.swift
  - apps/apple/BuyLedger/Core/Persistence/PersistenceContainer.swift
  - apps/apple/BuyLedgerTests/CampaignSummaryTests.swift
  - apps/apple/BuyLedger/Shared/DesignSystem/Foundations/Image+PhotoData.swift
  - apps/apple/BuyLedgerTests/OrdersFeatureTests.swift
  - apps/apple/BuyLedger/Core/Domain/LedgerOrder.swift
  - apps/apple/BuyLedger/Core/Domain/Campaign+Samples.swift
  - apps/apple/BuyLedgerTests/SnapshotTests.swift
  - CLAUDE.md
-->

---
### Requirement: Photos persist with the order

Order photos SHALL share the order's lifecycle: deleting the order removes its photos, and reopening the edit form for a persisted order SHALL show its stored photos. Saving an order SHALL persist the current draft photos only when the draft has been loaded and the user has changed it; otherwise the save SHALL leave the stored photos untouched. Rebuilding an order during master-data cascade renames SHALL leave the stored photos unchanged.

The edit form SHALL load a persisted order's photos on demand rather than receiving them with the order. Until that load succeeds, the form SHALL show the load state and SHALL disable the controls that add or remove photos, so that a failed or pending load cannot be mistaken for the user emptying the set.

#### Scenario: Photos survive app relaunch

- **WHEN** the user saves an order with 2 photos, terminates the app, relaunches, and reopens the edit form for that order
- **THEN** the form shows the same 2 photos

#### Scenario: Master-data rename keeps photos

- **WHEN** an order source, category, payment method, reconciliation status, or campaign referenced by an order with photos is renamed
- **THEN** the order still has the identical photo data

#### Scenario: Saving before the photo load completes keeps stored photos

- **WHEN** the user opens an order with photos and saves it before the photo load completes
- **THEN** the stored photos are unchanged, and no empty photo list is written

#### Scenario: A failed photo load is visible and non-destructive

- **WHEN** loading a persisted order's photos fails
- **THEN** the edit form shows the failure, the add and remove controls are disabled, and saving the order leaves the stored photos unchanged

#### Scenario: Editing photos writes the edited set

- **WHEN** the photo load completes and the user adds or removes a photo before saving
- **THEN** the stored photos match the edited draft


<!-- @trace
source: schema-v17-storage-cleanup
updated: 2026-08-15
code:
  - apps/ios/BuyLedger/Core/Persistence/PersistenceError.swift
  - apps/ios/BuyLedger/Features/Customers/CustomerRankBadgeStyle.swift
  - apps/ios/BuyLedger/Core/Persistence/CurrencyMetadataRecord.swift
  - apps/ios/BuyLedger/Core/Persistence/NameLookupRecord.swift
  - apps/ios/BuyLedgerTests/OrdersFeatureTests.swift
  - apps/ios/BuyLedgerTests/OrdersFeaturePerformanceTests.swift
  - apps/ios/BuyLedger/Core/Persistence/CampaignPersistence.swift
  - apps/ios/BuyLedger.xctestplan
  - apps/ios/BuyLedgerUITests/Tests/Tools/QuoteTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLBarChartValue.swift
  - shared/data-model/fixtures/expected/swift/SampleStatus.generated.swift
  - shared/data-model/fixtures/expected/kotlin/SamplePreference.kt
  - apps/ios/BuyLedger/Features/AISummary/OllamaDTO.swift
  - shared/data-model/fixtures/expected/swift/SampleReceipt.generated.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/States/BLLoadFailureView.swift
  - apps/ios/BuyLedgerUITests/Screens/InsightsScreen.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewBaseline.1.png
  - apps/ios/BuyLedger/Features/Customers/CustomersView.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoViewer.swift
  - apps/ios/BuyLedgerTests/PersistenceFailureFeatureTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLDonutSegment.swift
  - apps/ios/BuyLedgerTests/PhotoDataProcessorTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Tools/FxTests.swift
  - apps/ios/BuyLedger/Core/Networking/URLRequestBuilder.swift
  - shared/data-model/schema/OrderStatus.yaml
  - apps/ios/BuyLedgerTests/BLAccessibilityIDTests.swift
  - apps/ios/BuyLedgerTests/OrderEditFeatureTests.swift
  - shared/data-model/schema/CurrencyCode.yaml
  - apps/ios/BuyLedgerTests/DashboardFeatureTests.swift
  - apps/ios/BuyLedger/App/AppLaunchConfigurator.swift
  - apps/ios/BuyLedgerUITests/Support/LaunchOptions.swift
  - apps/ios/BuyLedger/Features/AISummary/AISummaryFeature.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersRegularViewMultiSelectBaseline.1.png
  - apps/ios/BuyLedgerUITests/Screens/CampaignsScreen.swift
  - shared/data-model/schema/PaymentMethodInfo.yaml
  - apps/ios/BuyLedger/Core/Persistence/CampaignRecord.swift
  - apps/ios/BuyLedger/Resources/Info.plist
  - apps/ios/BuyLedgerUITests/Support/BLUITestCase.swift
  - apps/ios/BuyLedgerTests/NumericInputGroupingScanTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Insights/InsightsTests.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderMergeCandidateSheet.swift
  - apps/ios/BuyLedgerAccessibilityIDs/BLAccessibilityID.swift
  - apps/ios/BuyLedgerTests/AISummaryFeatureTests.swift
  - apps/ios/BuyLedgerUITests.xctestplan
  - shared/data-model/schema/LedgerOrderItem.yaml
  - apps/ios/BuyLedgerTests/OrderMergeTests.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestSeedProfile.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementDestination.swift
  - apps/ios/BuyLedger/Resources/InfoPlist.xcstrings
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Tags/BLTagPill.swift
  - apps/ios/BuyLedgerUITests-Performance.xctestplan
  - apps/ios/BuyLedger/Core/Domain/Generated/Campaign.generated.swift
  - apps/ios/BuyLedgerTests/ColorContrast.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLTypography.swift
  - apps/ios/BuyLedger/Core/Domain/FxRateSnapshot.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/LedgerCustomer.generated.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/LedgerOrder.generated.swift
  - apps/ios/BuyLedgerTests/TestSuiteIntegrityTests.swift
  - apps/ios/BuyLedger/Features/Quote/QuoteView.swift
  - apps/ios/BuyLedger/Core/Dependencies/TelemetryClient.swift
  - apps/ios/BuyLedgerTests/OrdersFilterOperationsTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Smoke/AppLockTests.swift
  - apps/ios/BuyLedger/Core/Persistence/OrderRecord.swift
  - apps/ios/BuyLedgerUITests/Tests/Campaigns/CampaignDetailTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/quoteViewBaseline.1.png
  - apps/ios/BuyLedgerUITests/Screens/AppLockScreen.swift
  - apps/ios/BuyLedger/Core/Dependencies/BiometricAuthClient.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/States/DelayedProgressView.swift
  - apps/ios/BuyLedgerTests/PersistenceRecoveryTests.swift
  - apps/ios/BuyLedger/Core/Dependencies/OrderRepository.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/CustomerTier.generated.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestConfiguration.swift
  - apps/ios/BuyLedgerUITests/Screens/PhotoViewerScreen.swift
  - apps/ios/BuyLedger/Shared/Localization/AppLanguage.swift
  - apps/ios/BuyLedger/Features/App/RootFeature.swift
  - apps/ios/BuyLedgerUITests/Screens/CustomersScreen.swift
  - apps/ios/BuyLedgerTests/LookupCatalogTests.swift
  - shared/data-model/fixtures/expected/swift/SamplePreference.generated.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Chips/BLFilterChip.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsView.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLMetrics.swift
  - apps/ios/BuyLedger/Core/Networking/APIError.swift
  - apps/ios/BuyLedger/Core/Persistence/OrderPersistence.swift
  - apps/ios/BuyLedger/Core/Sync/SyncMeta.swift
  - apps/ios/BuyLedger/Shared/Extensions/Bundle+Extensions.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignEditFeature.swift
  - apps/ios/BuyLedger/Core/Persistence/PaymentMethodRecord.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignDetailView.swift
  - apps/ios/BuyLedger/Core/Domain/OrderSummary.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoThumbnail.swift
  - apps/ios/BuyLedger/Core/Dependencies/CalendarReminderClient.swift
  - apps/ios/BuyLedgerTests/OrdersSearchCancellationTests.swift
  - shared/data-model/README.md
  - shared/data-model/fixtures/expected/typescript/SampleReceipt.ts
  - apps/ios/BuyLedger/Features/Lookups/LookupCatalog.swift
  - apps/ios/BuyLedgerTests/AppConfigurationTests.swift
  - apps/ios/BuyLedger/Shared/Extensions/Color+Extensions.swift
  - shared/data-model/fixtures/expected/typescript/SampleProfile.ts
  - shared/data-model/fixtures/expected/kotlin/SampleQuote.kt
  - apps/ios/BuyLedgerTests/SettingsFeatureTests.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardView.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersView.swift
  - shared/data-model/fixtures/expected/swift/SampleSequence.generated.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsSnapshot.swift
  - apps/ios/BuyLedgerTests/PrivacyManifestTests.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderDetailView.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderSelectableRow.swift
  - apps/ios/BuyLedgerTests/OrderPersistenceTests.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardStats.swift
  - apps/ios/BuyLedger/Core/Domain/LedgerOrderItem.swift
  - apps/ios/BuyLedgerTests/ExchangeRateClientTests.swift
  - apps/ios/BuyLedger/Features/More/MoreView.swift
  - apps/ios/CLAUDE.md
  - shared/data-model/fixtures/expected/swift/SampleProfile.generated.swift
  - apps/ios/BuyLedger/App/AppDelegate.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLTone.swift
  - apps/ios/BuyLedgerUITests/Screens/OptionPickerScreen.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLBarChart.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLFormatters.swift
  - apps/ios/BuyLedgerTests/BLUITestConfigurationTests.swift
  - apps/ios/BuyLedger/Features/App/SidebarBadgeCounts.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrdersListTests.swift
  - apps/ios/BuyLedgerTests/TestDependencies.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/ViewModifiers/BLHeroCardBackground.swift
  - apps/ios/BuyLedger/Core/Testing/BLUITestSeedData.swift
  - apps/ios/BuyLedger/Core/Domain/OrderStatus.swift
  - apps/ios/BuyLedgerTests/OllamaClientTests.swift
  - apps/ios/BuyLedgerUITests/Screens/OrdersScreen.swift
  - apps/ios/BuyLedger/Core/Networking/ExchangeRateDTO.swift
  - apps/ios/BuyLedgerUITests/Screens/CampaignEditScreen.swift
  - apps/ios/BuyLedgerTests/QuoteFeatureTests.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrdersToolbarContent.swift
  - apps/ios/BuyLedgerTests/OrderStatusTests.swift
  - apps/ios/BuyLedgerTests/AppLockFeatureTests.swift
  - apps/ios/BuyLedger/Core/Dependencies/CampaignRepository.swift
  - apps/ios/BuyLedger/Core/Testing/BLUITestConfiguration.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Progress/BLProgressBar.swift
  - shared/data-model/fixtures/expected/kotlin/SampleSequence.kt
  - apps/ios/BuyLedgerTests/LocalizationCatalogTests.swift
  - apps/ios/BuyLedgerTests/SchemaMigrationTests.swift
  - shared/data-model/fixtures/expected/kotlin/SampleStatus.kt
  - apps/ios/BuyLedger/Features/Settings/AppLanguage.swift
  - apps/ios/BuyLedgerTests/BLPhotoViewerTests.swift
  - apps/ios/BuyLedger/Core/Persistence/ReconciliationStatusPersistence.swift
  - apps/ios/BuyLedger/Core/Networking/HTTPMethod.swift
  - apps/ios/BuyLedger/Core/Domain/FxRates.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementView.swift
  - apps/ios/BuyLedgerUITests/Tests/Smoke/HarnessSelfCheckTests.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/CampaignStatus.generated.swift
  - apps/ios/BuyLedger/Shared/Extensions/Decimal+Extensions.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFilterSheet.swift
  - apps/ios/BuyLedgerUITests/Screens/RootNavigationScreen.swift
  - apps/ios/BuyLedger/Core/Persistence/BuyLedgerSchema.swift
  - apps/ios/BuyLedgerTests/InsightsFeatureTests.swift
  - apps/ios/BuyLedger/Features/Orders/OrderDetailPath.swift
  - apps/ios/BuyLedger/Features/App/AppLockView.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignSummary.swift
  - apps/ios/BuyLedger/Features/FX/FxView.swift
  - apps/ios/BuyLedgerUITests/Support/AlertInteraction.swift
  - apps/ios/BuyLedgerUITests/Support/Diagnostics.swift
  - apps/ios/BuyLedgerTests/OrdersBatchOperationsTests.swift
  - apps/ios/BuyLedger/Features/Quote/QuoteFeature.swift
  - apps/ios/BuyLedger/Features/App/AppLockFeature.swift
  - apps/ios/BuyLedgerTests/OrderMergeFeatureTests.swift
  - apps/ios/BuyLedgerUITests/Support/MenuInteraction.swift
  - apps/ios/README.md
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderMergeTests.swift
  - apps/ios/BuyLedgerTests/BiometricAuthClientTests.swift
  - apps/ios/BuyLedger/Features/Orders/OrderDatePeriod.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLPalette.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Status/BLStatusPill.swift
  - apps/ios/BuyLedger/Features/Orders/LedgerOrder+OrderMutation.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/LedgerOrderItem.generated.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignFeature.swift
  - apps/ios/BuyLedger/Features/App/RootTabLayout.swift
  - shared/data-model/fixtures/schema/sample-orders.yaml
  - apps/ios/BuyLedger/App/BuyLedgerApp.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/OrderStatus.generated.swift
  - apps/ios/BuyLedger/Features/FX/ExchangeRateDTO.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/CurrencyCode.generated.swift
  - apps/ios/BuyLedgerUITests/Screens/QuoteScreen.swift
  - shared/data-model/fixtures/expected/kotlin/SampleReceipt.kt
  - apps/ios/BuyLedgerTests/OrdersLoadStateTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewLongIdentifierBaseline.1.png
  - apps/ios/BuyLedgerUITests/KeyboardDismissTests.swift
  - apps/ios/BuyLedgerUITests/Screens/SettingsScreen.swift
  - apps/ios/BuyLedgerTests/OrderEditFocusTests.swift
  - apps/ios/BuyLedgerTests/ProjectionWriteBoundaryTests.swift
  - apps/ios/BuyLedger/Features/AISummary/OllamaClient.swift
  - apps/ios/BuyLedger/Features/Orders/OrderEditView.swift
  - apps/ios/BuyLedgerTests/PersistenceErrorContractTests.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersCompactView.swift
  - apps/ios/BuyLedgerUITests/Screens/DashboardScreen.swift
  - apps/ios/BuyLedger/Core/Persistence/CategoryPersistence.swift
  - apps/ios/BuyLedger/Core/Domain/OrderMerge.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardFeature.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Buttons/BLButtonStyle.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Cards/BLCard.swift
  - apps/ios/BuyLedgerUITests/Support/TextInput.swift
  - apps/ios/BuyLedger/Core/Dependencies/PhotoClient.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/quoteViewRateUnavailable.1.png
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFormatters.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignListView.swift
  - apps/ios/BuyLedgerTests/AppScenePhaseCoordinatorTests.swift
  - apps/ios/BuyLedgerUITests/Screens/MergeFlowScreen.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderCreateTests.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsStats.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestHarness.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestDependencyOverrides.swift
  - shared/data-model/fixtures/expected/typescript/SampleSequence.ts
  - apps/ios/BuyLedgerUITests/PhotoViewerPagingTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Campaigns/CampaignCrudTests.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersFilterOperations.swift
  - apps/ios/BuyLedger/Shared/Media/PhotoDataProcessor.swift
  - apps/ios/BuyLedgerUITests/Screens/OrderEditScreen.swift
  - shared/data-model/schema/PaymentReceiptStatus.yaml
  - shared/data-model/schema/LedgerOrder.yaml
  - apps/ios/BuyLedgerUITests/Support/Waiting.swift
  - apps/ios/BuyLedger/Resources/GoogleService-Info.example.plist
  - apps/ios/BuyLedger/Core/Testing/BLUITestHarness.swift
  - apps/ios/BuyLedger/Core/Persistence/CurrencyMetadataPersistence.swift
  - apps/ios/BuyLedger/Core/Networking/AppConfiguration.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersMergeFlowOperations.swift
  - apps/ios/BuyLedger/Shared/Extensions/Image+Extensions.swift
  - shared/data-model/fixtures/expected/swift/SampleGrade.generated.swift
  - apps/ios/BuyLedger/Core/Dependencies/NameLookupOperations.swift
  - apps/ios/BuyLedgerUITests/Screens/Screen.swift
  - shared/data-model/fixtures/expected/kotlin/SampleGrade.kt
  - apps/ios/BuyLedger.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
  - apps/ios/BuyLedgerTests/CampaignPersistenceTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderEditDirtyTests.swift
  - apps/ios/BuyLedgerTests/CurrencyMetadataCacheTests.swift
  - apps/ios/BuyLedgerTests/InsightsStatsTests.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsDateRange.swift
  - apps/ios/BuyLedgerUITests/Tests/Customers/CustomersTests.swift
  - .github/workflows/ci.yml
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/persistenceFailureViewBaseline.1.png
  - apps/ios/BuyLedgerTests/CampaignFeatureTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Avatar/BLAvatar.swift
  - AGENTS.md
  - apps/ios/BuyLedger/Features/Orders/Components/OptionPickerSheet.swift
  - apps/ios/BuyLedger/Features/Orders/OrderEditFeature.swift
  - apps/ios/BuyLedgerUITests/Tests/Performance/LaunchPerformanceTests.swift
  - apps/ios/BuyLedger/Features/Orders/OrderMergeFeature.swift
  - apps/ios/BuyLedgerTests/CampaignSummaryTests.swift
  - apps/ios/BuyLedger/Core/Diagnostics/CrashDiagnosticsClient.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupNameEditorSheet.swift
  - apps/ios/BuyLedger/Core/Dependencies/PaymentMethodRepository.swift
  - shared/data-model/fixtures/expected/typescript/SamplePreference.ts
  - apps/ios/BuyLedger.xcodeproj/project.pbxproj
  - apps/ios/BuyLedgerTests/LookupManagementFeatureTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewBaseline.1.png
  - apps/ios/BuyLedger/Features/FX/FxRates.swift
  - apps/ios/BuyLedgerTests/ContrastComplianceTests.swift
  - apps/ios/BuyLedger/Core/Persistence/ReconciliationStatusRecord.swift
  - apps/ios/BuyLedger/Features/Settings/AISummaryModelCatalog.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewMultiSelectBaseline.1.png
  - apps/ios/BuyLedger/Features/Insights/InsightsView.swift
  - apps/ios/BuyLedger/Core/Dependencies/CurrencyMetadataRepository.swift
  - apps/ios/BuyLedgerTests/BLFormattersTests.swift
  - apps/ios/BuyLedger/Core/Persistence/PersistenceStoreQuarantine.swift
  - apps/ios/BuyLedger/Core/Domain/Campaign.swift
  - apps/ios/BuyLedger/Core/Persistence/CampaignReminderRecord.swift
  - apps/ios/BuyLedger/Features/App/AppScenePhaseCoordinator.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignFormatters.swift
  - apps/ios/BuyLedger/Core/Domain/LedgerOrder.swift
  - shared/data-model/fixtures/expected/typescript/SampleGrade.ts
  - shared/data-model/fixtures/schema/sample-trait-matrix.yaml
  - apps/ios/BuyLedger/Core/Testing/BLUITestDependencyOverrides.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLDonutChart.swift
  - apps/ios/BuyLedger/Core/Dependencies/CategoryRepository.swift
  - apps/ios/BuyLedger/Core/Persistence/CategoryRecord.swift
  - apps/ios/BuyLedger/Core/Persistence/CampaignReminderPersistence.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestSeedData.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Pickers/OptionPickerSheet.swift
  - apps/ios/BuyLedger/Features/App/PersistenceFailureView.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/ViewModifiers/BLCardShadow.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/States/BLDelayedProgressView.swift
  - shared/data-model/fixtures/schema/sample-enums.yaml
  - shared/data-model/generator/src/datamodel-gen.ts
  - apps/ios/BuyLedger/Features/Insights/InsightsFeature.swift
  - apps/ios/BuyLedger/Core/Persistence/PersistenceStoreQuarantineClient.swift
  - apps/ios/BuyLedger/Core/Persistence/NameLookupPersistence.swift
  - apps/ios/BuyLedger/Core/Domain/CurrencyCode.swift
  - apps/ios/BuyLedger/Core/Testing/BLUITestSeedProfile.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderDetailTests.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/PaymentMethodInfo.generated.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLStatusHue.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersFeature.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLHeatmapDepth.swift
  - apps/ios/BuyLedger/Features/App/RootSidebarLayout.swift
  - apps/ios/BuyLedger/Features/Customers/CustomersFeature.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/Money.generated.swift
  - shared/data-model/fixtures/expected/swift/SampleQuote.generated.swift
  - shared/data-model/schema/CustomerTier.yaml
  - apps/ios/BuyLedgerUITests/Tests/Smoke/LaunchSmokeTests.swift
  - shared/data-model/schema/Campaign.yaml
  - apps/ios/BuyLedgerUITests/Screens/CampaignDetailScreen.swift
  - apps/ios/BuyLedgerTests/CampaignEditFeatureTests.swift
  - apps/ios/BuyLedger/Core/Dependencies/OpenSettingsClient.swift
  - apps/ios/BuyLedger/Resources/Localizable.xcstrings
  - apps/ios/BuyLedger/Features/Settings/SettingsStorage.swift
  - apps/ios/BuyLedger/Features/AISummary/AISummaryView.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/PaymentReceiptStatus.generated.swift
  - apps/ios/BuyLedger/Features/Orders/Components/PaymentMethodEditorSheet.swift
  - shared/data-model/schema/Money.yaml
  - apps/ios/BuyLedgerTests/SnapshotTests.swift
  - apps/ios/BuyLedger.xcodeproj/xcshareddata/xcschemes/BuyLedger.xcscheme
  - apps/ios/BuyLedger/Features/Orders/Components/MergePhotoPickerSheet.swift
  - apps/ios/BuyLedger/Features/App/RootTab.swift
  - apps/ios/BuyLedgerTests/CampaignIntegrationTests.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsFeature.swift
  - apps/ios/BuyLedgerTests/DashboardStatsTests.swift
  - apps/ios/BuyLedgerUITests/Support/Assertions.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupKind.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLSparkline.swift
  - apps/ios/BuyLedgerTests/OrderCalculationTests.swift
  - shared/data-model/fixtures/expected/typescript/SampleStatus.ts
  - README.md
  - apps/ios/BuyLedgerTests/PaymentMethodPersistenceTests.swift
  - apps/ios/BuyLedger/Features/App/PersistenceFailureFeature.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Badges/BLBadge.swift
  - shared/data-model/schema/FxRateSnapshot.yaml
  - apps/ios/BuyLedgerTests/CampaignReminderFailureTests.swift
  - apps/ios/BuyLedger/Core/Dependencies/ReconciliationStatusRepository.swift
  - apps/ios/BuyLedgerUITests/Support/AppNavigator.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderStatus+Presentation.swift
  - apps/ios/BuyLedger/Features/FX/FxFeature.swift
  - apps/ios/BuyLedger/Features/Orders/OrderDraft.swift
  - apps/ios/BuyLedgerTests/LayerBoundaryTests.swift
  - apps/ios/BuyLedgerTests/FxFeatureTests.swift
  - apps/ios/BuyLedger/Core/Sync/SyncQueueItem.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/FxRateSnapshot.generated.swift
  - apps/ios/BuyLedger/Core/Dependencies/CampaignReminderRepository.swift
  - apps/ios/BuyLedger/Features/Orders/OrderStatusFilter.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/AISummaryTests.swift
  - apps/ios/BuyLedgerUITests/Support/SheetInteraction.swift
  - apps/ios/BuyLedgerUITests/Support/ValueParsing.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/ViewModifiers/BLTypographyModifier.swift
  - apps/ios/BuyLedger/Features/App/RootView.swift
  - shared/data-model/schema/LedgerCustomer.yaml
  - apps/ios/BuyLedger/Core/Persistence/OrderSourcePersistence.swift
  - apps/ios/BuyLedger/Core/Persistence/PersistenceContainer.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderRowView.swift
  - apps/ios/BuyLedger/Core/Domain/LedgerOrder+Samples.swift
  - shared/data-model/schema/CampaignStatus.yaml
  - apps/ios/BuyLedgerTests/InsightsAttributionTests.swift
  - apps/ios/BuyLedgerUITests/Screens/AISummaryScreen.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/dashboardViewBaseline.1.png
  - apps/ios/BuyLedgerTests/OrderDraftTests.swift
  - apps/ios/BuyLedger/Core/Networking/ExchangeRateClient.swift
  - apps/ios/BuyLedger/Core/Domain/Campaign+Samples.swift
  - shared/data-model/fixtures/expected/kotlin/SampleProfile.kt
  - apps/ios/BuyLedger/Core/Persistence/OrderSourceRecord.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignEditView.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersBatchOperations.swift
  - apps/ios/BuyLedgerTests/ColorContrastTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Forms/PaymentMethodEditorSheet.swift
  - apps/ios/BuyLedger/Core/Persistence/PaymentMethodPersistence.swift
  - apps/ios/BuyLedger/Features/FX/ExchangeRateClient.swift
  - apps/ios/BuyLedger/Resources/PrivacyInfo.xcprivacy
  - apps/ios/BuyLedgerUITests/Support/Scrolling.swift
  - apps/ios/BuyLedger/Core/Networking/HTTPClient.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewLongContentBaseline.1.png
  - apps/ios/BuyLedgerTests/HTTPClientTests.swift
  - CLAUDE.md
  - apps/ios/BuyLedgerUITests/Screens/OrderDetailScreen.swift
  - apps/ios/BuyLedger/Core/Dependencies/OrderSourceRepository.swift
  - apps/ios/BuyLedgerTests/NameLookupPersistenceTests.swift
  - apps/ios/BuyLedgerUITests/Screens/FxScreen.swift
  - apps/ios/BuyLedgerTests/AccessibilityConventionScanTests.swift
  - apps/ios/BuyLedgerTests/APIErrorMappingTests.swift
  - shared/data-model/fixtures/expected/typescript/SampleQuote.ts
  - apps/ios/BuyLedgerTests/DesignSystemSourceScanTests.swift
  - apps/ios/BuyLedgerTests/CustomersFeatureTests.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersFeature+StateQuery.swift
  - apps/ios/BuyLedgerUITests/Tests/Campaigns/CampaignListTests.swift
  - apps/ios/BuyLedgerTests/CalendarReminderTests.swift
tests:
  - shared/data-model/generator/test/datamodel-gen.test.ts
-->

---
### Requirement: Existing stores migrate with empty photo lists

The schema SHALL advance to a new version that adds the photos attribute with an empty-array default, bridged from the previous version by a lightweight migration stage. Opening a store persisted at any retained earlier version SHALL preserve every order and its field values, with each migrated order having zero photos.

#### Scenario: Pre-photos store opens at the new target

- **GIVEN** an on-disk store at the previous schema version containing 3 orders
- **WHEN** the store is opened with the migration plan targeting the new version
- **THEN** all 3 orders are present with their field values intact and each has an empty photo list


<!-- @trace
source: add-order-photos
updated: 2026-06-06
code:
  - apps/apple/BuyLedger/Core/Dependencies/PhotoClient.swift
  - apps/apple/BuyLedger/Features/App/RootFeature.swift
  - apps/apple/BuyLedgerTests/CampaignIntegrationTests.swift
  - apps/apple/BuyLedger/Features/Orders/OrderEditView.swift
  - apps/apple/BuyLedgerTests/OrderEditFeatureTests.swift
  - apps/apple/BuyLedgerTests/OrderPersistenceTests.swift
  - apps/apple/BuyLedger/Features/Orders/OrderEditFeature.swift
  - apps/apple/BuyLedger/Features/Orders/OrdersFeature.swift
  - apps/apple/BuyLedgerTests/OrderCalculationTests.swift
  - apps/apple/BuyLedgerTests/RootFeatureTests.swift
  - apps/apple/BuyLedgerTests/SchemaMigrationTests.swift
  - apps/apple/BuyLedgerTests/OrdersFeaturePerformanceTests.swift
  - apps/apple/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoViewer.swift
  - apps/apple/BuyLedger/Core/Domain/LedgerOrder+Samples.swift
  - apps/apple/BuyLedger/Shared/Media/PhotoDataProcessor.swift
  - apps/apple/BuyLedger/Core/Persistence/OrderRecord.swift
  - apps/apple/BuyLedger/Core/Persistence/BuyLedgerSchema.swift
  - apps/apple/BuyLedgerTests/PhotoDataProcessorTests.swift
  - apps/apple/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoThumbnail.swift
  - apps/apple/BuyLedger/Core/Persistence/PersistenceContainer.swift
  - apps/apple/BuyLedgerTests/CampaignSummaryTests.swift
  - apps/apple/BuyLedger/Shared/DesignSystem/Foundations/Image+PhotoData.swift
  - apps/apple/BuyLedgerTests/OrdersFeatureTests.swift
  - apps/apple/BuyLedger/Core/Domain/LedgerOrder.swift
  - apps/apple/BuyLedger/Core/Domain/Campaign+Samples.swift
  - apps/apple/BuyLedgerTests/SnapshotTests.swift
  - CLAUDE.md
-->

---
### Requirement: View attached photos full screen

Tapping a photo thumbnail outside its delete control SHALL present a photo viewer as a sheet on all platforms, showing that photo scaled to fit with rounded corners against the system background, which SHALL adapt to light and dark appearance. The sheet's navigation bar SHALL show the position indicator (x/n) as its centered title and a close button as its trailing toolbar item. The photo area SHALL lie strictly below the navigation bar and SHALL NOT extend behind it, with a uniform margin separating the photo area from the bar and the sheet edges. The viewer SHALL support horizontal swiping to navigate between all photos attached to the draft, in their stored order, stopping at the first and the last photo. The viewer SHALL show a position indicator and a close control; closing SHALL return to the edit form without altering the draft. Tapping a thumbnail's delete control SHALL NOT open the viewer.

#### Scenario: Tapping a thumbnail opens the viewer at that photo

- **GIVEN** the draft photos are [A, B, C]
- **WHEN** the user taps the thumbnail of B
- **THEN** the viewer opens full screen showing B with indicator 2/3

#### Scenario: Swiping navigates between photos in stored order

- **GIVEN** the viewer is showing B of [A, B, C]
- **WHEN** the user swipes left
- **THEN** the viewer shows C

##### Example: swipe boundaries

| Current photo | Swipe direction | Result | Notes |
| ------------- | --------------- | ------ | ----- |
| B of [A, B, C] | left | C | next photo |
| B of [A, B, C] | right | A | previous photo |
| A of [A, B, C] | right | A | stops at first |
| C of [A, B, C] | left | C | stops at last |

#### Scenario: Closing the viewer preserves the draft

- **WHEN** the user taps the close control in the viewer
- **THEN** the edit form reappears with the draft photos unchanged

#### Scenario: Delete control does not open the viewer

- **WHEN** the user taps the delete control on a thumbnail
- **THEN** that photo is removed from the draft and no viewer is presented

<!-- @trace
source: add-order-photos
updated: 2026-06-06
code:
  - apps/apple/BuyLedger/Core/Dependencies/PhotoClient.swift
  - apps/apple/BuyLedger/Features/App/RootFeature.swift
  - apps/apple/BuyLedgerTests/CampaignIntegrationTests.swift
  - apps/apple/BuyLedger/Features/Orders/OrderEditView.swift
  - apps/apple/BuyLedgerTests/OrderEditFeatureTests.swift
  - apps/apple/BuyLedgerTests/OrderPersistenceTests.swift
  - apps/apple/BuyLedger/Features/Orders/OrderEditFeature.swift
  - apps/apple/BuyLedger/Features/Orders/OrdersFeature.swift
  - apps/apple/BuyLedgerTests/OrderCalculationTests.swift
  - apps/apple/BuyLedgerTests/RootFeatureTests.swift
  - apps/apple/BuyLedgerTests/SchemaMigrationTests.swift
  - apps/apple/BuyLedgerTests/OrdersFeaturePerformanceTests.swift
  - apps/apple/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoViewer.swift
  - apps/apple/BuyLedger/Core/Domain/LedgerOrder+Samples.swift
  - apps/apple/BuyLedger/Shared/Media/PhotoDataProcessor.swift
  - apps/apple/BuyLedger/Core/Persistence/OrderRecord.swift
  - apps/apple/BuyLedger/Core/Persistence/BuyLedgerSchema.swift
  - apps/apple/BuyLedgerTests/PhotoDataProcessorTests.swift
  - apps/apple/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoThumbnail.swift
  - apps/apple/BuyLedger/Core/Persistence/PersistenceContainer.swift
  - apps/apple/BuyLedgerTests/CampaignSummaryTests.swift
  - apps/apple/BuyLedger/Shared/DesignSystem/Foundations/Image+PhotoData.swift
  - apps/apple/BuyLedgerTests/OrdersFeatureTests.swift
  - apps/apple/BuyLedger/Core/Domain/LedgerOrder.swift
  - apps/apple/BuyLedger/Core/Domain/Campaign+Samples.swift
  - apps/apple/BuyLedgerTests/SnapshotTests.swift
  - CLAUDE.md
-->

---
### Requirement: Order photo bytes live outside the order row

Order photos SHALL be persisted as binary payloads stored adjacent to the order record rather than inline in it, so that reading an order without reading its photos does not load the payloads. Where the persistence framework does not honour this for the stored shape, the read paths SHALL still exclude the photo attribute explicitly, and the observable contract of the remaining requirements SHALL hold regardless.

#### Scenario: Reading an order without its photos loads no payloads

- **WHEN** order records are read through a path that does not request the photo attribute
- **THEN** the photo payloads are not loaded into memory

#### Scenario: Payload relocation is transparent to callers

- **WHEN** an order with photos is saved and read back through the photo-loading path
- **THEN** the returned photos are byte-for-byte identical to what was saved


<!-- @trace
source: schema-v17-storage-cleanup
updated: 2026-08-15
code:
  - apps/ios/BuyLedger/Core/Persistence/PersistenceError.swift
  - apps/ios/BuyLedger/Features/Customers/CustomerRankBadgeStyle.swift
  - apps/ios/BuyLedger/Core/Persistence/CurrencyMetadataRecord.swift
  - apps/ios/BuyLedger/Core/Persistence/NameLookupRecord.swift
  - apps/ios/BuyLedgerTests/OrdersFeatureTests.swift
  - apps/ios/BuyLedgerTests/OrdersFeaturePerformanceTests.swift
  - apps/ios/BuyLedger/Core/Persistence/CampaignPersistence.swift
  - apps/ios/BuyLedger.xctestplan
  - apps/ios/BuyLedgerUITests/Tests/Tools/QuoteTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLBarChartValue.swift
  - shared/data-model/fixtures/expected/swift/SampleStatus.generated.swift
  - shared/data-model/fixtures/expected/kotlin/SamplePreference.kt
  - apps/ios/BuyLedger/Features/AISummary/OllamaDTO.swift
  - shared/data-model/fixtures/expected/swift/SampleReceipt.generated.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/States/BLLoadFailureView.swift
  - apps/ios/BuyLedgerUITests/Screens/InsightsScreen.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewBaseline.1.png
  - apps/ios/BuyLedger/Features/Customers/CustomersView.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoViewer.swift
  - apps/ios/BuyLedgerTests/PersistenceFailureFeatureTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLDonutSegment.swift
  - apps/ios/BuyLedgerTests/PhotoDataProcessorTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Tools/FxTests.swift
  - apps/ios/BuyLedger/Core/Networking/URLRequestBuilder.swift
  - shared/data-model/schema/OrderStatus.yaml
  - apps/ios/BuyLedgerTests/BLAccessibilityIDTests.swift
  - apps/ios/BuyLedgerTests/OrderEditFeatureTests.swift
  - shared/data-model/schema/CurrencyCode.yaml
  - apps/ios/BuyLedgerTests/DashboardFeatureTests.swift
  - apps/ios/BuyLedger/App/AppLaunchConfigurator.swift
  - apps/ios/BuyLedgerUITests/Support/LaunchOptions.swift
  - apps/ios/BuyLedger/Features/AISummary/AISummaryFeature.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersRegularViewMultiSelectBaseline.1.png
  - apps/ios/BuyLedgerUITests/Screens/CampaignsScreen.swift
  - shared/data-model/schema/PaymentMethodInfo.yaml
  - apps/ios/BuyLedger/Core/Persistence/CampaignRecord.swift
  - apps/ios/BuyLedger/Resources/Info.plist
  - apps/ios/BuyLedgerUITests/Support/BLUITestCase.swift
  - apps/ios/BuyLedgerTests/NumericInputGroupingScanTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Insights/InsightsTests.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderMergeCandidateSheet.swift
  - apps/ios/BuyLedgerAccessibilityIDs/BLAccessibilityID.swift
  - apps/ios/BuyLedgerTests/AISummaryFeatureTests.swift
  - apps/ios/BuyLedgerUITests.xctestplan
  - shared/data-model/schema/LedgerOrderItem.yaml
  - apps/ios/BuyLedgerTests/OrderMergeTests.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestSeedProfile.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementDestination.swift
  - apps/ios/BuyLedger/Resources/InfoPlist.xcstrings
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Tags/BLTagPill.swift
  - apps/ios/BuyLedgerUITests-Performance.xctestplan
  - apps/ios/BuyLedger/Core/Domain/Generated/Campaign.generated.swift
  - apps/ios/BuyLedgerTests/ColorContrast.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLTypography.swift
  - apps/ios/BuyLedger/Core/Domain/FxRateSnapshot.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/LedgerCustomer.generated.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/LedgerOrder.generated.swift
  - apps/ios/BuyLedgerTests/TestSuiteIntegrityTests.swift
  - apps/ios/BuyLedger/Features/Quote/QuoteView.swift
  - apps/ios/BuyLedger/Core/Dependencies/TelemetryClient.swift
  - apps/ios/BuyLedgerTests/OrdersFilterOperationsTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Smoke/AppLockTests.swift
  - apps/ios/BuyLedger/Core/Persistence/OrderRecord.swift
  - apps/ios/BuyLedgerUITests/Tests/Campaigns/CampaignDetailTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/quoteViewBaseline.1.png
  - apps/ios/BuyLedgerUITests/Screens/AppLockScreen.swift
  - apps/ios/BuyLedger/Core/Dependencies/BiometricAuthClient.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/States/DelayedProgressView.swift
  - apps/ios/BuyLedgerTests/PersistenceRecoveryTests.swift
  - apps/ios/BuyLedger/Core/Dependencies/OrderRepository.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/CustomerTier.generated.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestConfiguration.swift
  - apps/ios/BuyLedgerUITests/Screens/PhotoViewerScreen.swift
  - apps/ios/BuyLedger/Shared/Localization/AppLanguage.swift
  - apps/ios/BuyLedger/Features/App/RootFeature.swift
  - apps/ios/BuyLedgerUITests/Screens/CustomersScreen.swift
  - apps/ios/BuyLedgerTests/LookupCatalogTests.swift
  - shared/data-model/fixtures/expected/swift/SamplePreference.generated.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Chips/BLFilterChip.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsView.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLMetrics.swift
  - apps/ios/BuyLedger/Core/Networking/APIError.swift
  - apps/ios/BuyLedger/Core/Persistence/OrderPersistence.swift
  - apps/ios/BuyLedger/Core/Sync/SyncMeta.swift
  - apps/ios/BuyLedger/Shared/Extensions/Bundle+Extensions.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignEditFeature.swift
  - apps/ios/BuyLedger/Core/Persistence/PaymentMethodRecord.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignDetailView.swift
  - apps/ios/BuyLedger/Core/Domain/OrderSummary.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoThumbnail.swift
  - apps/ios/BuyLedger/Core/Dependencies/CalendarReminderClient.swift
  - apps/ios/BuyLedgerTests/OrdersSearchCancellationTests.swift
  - shared/data-model/README.md
  - shared/data-model/fixtures/expected/typescript/SampleReceipt.ts
  - apps/ios/BuyLedger/Features/Lookups/LookupCatalog.swift
  - apps/ios/BuyLedgerTests/AppConfigurationTests.swift
  - apps/ios/BuyLedger/Shared/Extensions/Color+Extensions.swift
  - shared/data-model/fixtures/expected/typescript/SampleProfile.ts
  - shared/data-model/fixtures/expected/kotlin/SampleQuote.kt
  - apps/ios/BuyLedgerTests/SettingsFeatureTests.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardView.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersView.swift
  - shared/data-model/fixtures/expected/swift/SampleSequence.generated.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsSnapshot.swift
  - apps/ios/BuyLedgerTests/PrivacyManifestTests.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderDetailView.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderSelectableRow.swift
  - apps/ios/BuyLedgerTests/OrderPersistenceTests.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardStats.swift
  - apps/ios/BuyLedger/Core/Domain/LedgerOrderItem.swift
  - apps/ios/BuyLedgerTests/ExchangeRateClientTests.swift
  - apps/ios/BuyLedger/Features/More/MoreView.swift
  - apps/ios/CLAUDE.md
  - shared/data-model/fixtures/expected/swift/SampleProfile.generated.swift
  - apps/ios/BuyLedger/App/AppDelegate.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLTone.swift
  - apps/ios/BuyLedgerUITests/Screens/OptionPickerScreen.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLBarChart.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLFormatters.swift
  - apps/ios/BuyLedgerTests/BLUITestConfigurationTests.swift
  - apps/ios/BuyLedger/Features/App/SidebarBadgeCounts.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrdersListTests.swift
  - apps/ios/BuyLedgerTests/TestDependencies.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/ViewModifiers/BLHeroCardBackground.swift
  - apps/ios/BuyLedger/Core/Testing/BLUITestSeedData.swift
  - apps/ios/BuyLedger/Core/Domain/OrderStatus.swift
  - apps/ios/BuyLedgerTests/OllamaClientTests.swift
  - apps/ios/BuyLedgerUITests/Screens/OrdersScreen.swift
  - apps/ios/BuyLedger/Core/Networking/ExchangeRateDTO.swift
  - apps/ios/BuyLedgerUITests/Screens/CampaignEditScreen.swift
  - apps/ios/BuyLedgerTests/QuoteFeatureTests.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrdersToolbarContent.swift
  - apps/ios/BuyLedgerTests/OrderStatusTests.swift
  - apps/ios/BuyLedgerTests/AppLockFeatureTests.swift
  - apps/ios/BuyLedger/Core/Dependencies/CampaignRepository.swift
  - apps/ios/BuyLedger/Core/Testing/BLUITestConfiguration.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Progress/BLProgressBar.swift
  - shared/data-model/fixtures/expected/kotlin/SampleSequence.kt
  - apps/ios/BuyLedgerTests/LocalizationCatalogTests.swift
  - apps/ios/BuyLedgerTests/SchemaMigrationTests.swift
  - shared/data-model/fixtures/expected/kotlin/SampleStatus.kt
  - apps/ios/BuyLedger/Features/Settings/AppLanguage.swift
  - apps/ios/BuyLedgerTests/BLPhotoViewerTests.swift
  - apps/ios/BuyLedger/Core/Persistence/ReconciliationStatusPersistence.swift
  - apps/ios/BuyLedger/Core/Networking/HTTPMethod.swift
  - apps/ios/BuyLedger/Core/Domain/FxRates.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementView.swift
  - apps/ios/BuyLedgerUITests/Tests/Smoke/HarnessSelfCheckTests.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/CampaignStatus.generated.swift
  - apps/ios/BuyLedger/Shared/Extensions/Decimal+Extensions.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFilterSheet.swift
  - apps/ios/BuyLedgerUITests/Screens/RootNavigationScreen.swift
  - apps/ios/BuyLedger/Core/Persistence/BuyLedgerSchema.swift
  - apps/ios/BuyLedgerTests/InsightsFeatureTests.swift
  - apps/ios/BuyLedger/Features/Orders/OrderDetailPath.swift
  - apps/ios/BuyLedger/Features/App/AppLockView.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignSummary.swift
  - apps/ios/BuyLedger/Features/FX/FxView.swift
  - apps/ios/BuyLedgerUITests/Support/AlertInteraction.swift
  - apps/ios/BuyLedgerUITests/Support/Diagnostics.swift
  - apps/ios/BuyLedgerTests/OrdersBatchOperationsTests.swift
  - apps/ios/BuyLedger/Features/Quote/QuoteFeature.swift
  - apps/ios/BuyLedger/Features/App/AppLockFeature.swift
  - apps/ios/BuyLedgerTests/OrderMergeFeatureTests.swift
  - apps/ios/BuyLedgerUITests/Support/MenuInteraction.swift
  - apps/ios/README.md
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderMergeTests.swift
  - apps/ios/BuyLedgerTests/BiometricAuthClientTests.swift
  - apps/ios/BuyLedger/Features/Orders/OrderDatePeriod.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLPalette.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Status/BLStatusPill.swift
  - apps/ios/BuyLedger/Features/Orders/LedgerOrder+OrderMutation.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/LedgerOrderItem.generated.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignFeature.swift
  - apps/ios/BuyLedger/Features/App/RootTabLayout.swift
  - shared/data-model/fixtures/schema/sample-orders.yaml
  - apps/ios/BuyLedger/App/BuyLedgerApp.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/OrderStatus.generated.swift
  - apps/ios/BuyLedger/Features/FX/ExchangeRateDTO.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/CurrencyCode.generated.swift
  - apps/ios/BuyLedgerUITests/Screens/QuoteScreen.swift
  - shared/data-model/fixtures/expected/kotlin/SampleReceipt.kt
  - apps/ios/BuyLedgerTests/OrdersLoadStateTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewLongIdentifierBaseline.1.png
  - apps/ios/BuyLedgerUITests/KeyboardDismissTests.swift
  - apps/ios/BuyLedgerUITests/Screens/SettingsScreen.swift
  - apps/ios/BuyLedgerTests/OrderEditFocusTests.swift
  - apps/ios/BuyLedgerTests/ProjectionWriteBoundaryTests.swift
  - apps/ios/BuyLedger/Features/AISummary/OllamaClient.swift
  - apps/ios/BuyLedger/Features/Orders/OrderEditView.swift
  - apps/ios/BuyLedgerTests/PersistenceErrorContractTests.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersCompactView.swift
  - apps/ios/BuyLedgerUITests/Screens/DashboardScreen.swift
  - apps/ios/BuyLedger/Core/Persistence/CategoryPersistence.swift
  - apps/ios/BuyLedger/Core/Domain/OrderMerge.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardFeature.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Buttons/BLButtonStyle.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Cards/BLCard.swift
  - apps/ios/BuyLedgerUITests/Support/TextInput.swift
  - apps/ios/BuyLedger/Core/Dependencies/PhotoClient.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/quoteViewRateUnavailable.1.png
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFormatters.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignListView.swift
  - apps/ios/BuyLedgerTests/AppScenePhaseCoordinatorTests.swift
  - apps/ios/BuyLedgerUITests/Screens/MergeFlowScreen.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderCreateTests.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsStats.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestHarness.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestDependencyOverrides.swift
  - shared/data-model/fixtures/expected/typescript/SampleSequence.ts
  - apps/ios/BuyLedgerUITests/PhotoViewerPagingTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Campaigns/CampaignCrudTests.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersFilterOperations.swift
  - apps/ios/BuyLedger/Shared/Media/PhotoDataProcessor.swift
  - apps/ios/BuyLedgerUITests/Screens/OrderEditScreen.swift
  - shared/data-model/schema/PaymentReceiptStatus.yaml
  - shared/data-model/schema/LedgerOrder.yaml
  - apps/ios/BuyLedgerUITests/Support/Waiting.swift
  - apps/ios/BuyLedger/Resources/GoogleService-Info.example.plist
  - apps/ios/BuyLedger/Core/Testing/BLUITestHarness.swift
  - apps/ios/BuyLedger/Core/Persistence/CurrencyMetadataPersistence.swift
  - apps/ios/BuyLedger/Core/Networking/AppConfiguration.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersMergeFlowOperations.swift
  - apps/ios/BuyLedger/Shared/Extensions/Image+Extensions.swift
  - shared/data-model/fixtures/expected/swift/SampleGrade.generated.swift
  - apps/ios/BuyLedger/Core/Dependencies/NameLookupOperations.swift
  - apps/ios/BuyLedgerUITests/Screens/Screen.swift
  - shared/data-model/fixtures/expected/kotlin/SampleGrade.kt
  - apps/ios/BuyLedger.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
  - apps/ios/BuyLedgerTests/CampaignPersistenceTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderEditDirtyTests.swift
  - apps/ios/BuyLedgerTests/CurrencyMetadataCacheTests.swift
  - apps/ios/BuyLedgerTests/InsightsStatsTests.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsDateRange.swift
  - apps/ios/BuyLedgerUITests/Tests/Customers/CustomersTests.swift
  - .github/workflows/ci.yml
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/persistenceFailureViewBaseline.1.png
  - apps/ios/BuyLedgerTests/CampaignFeatureTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Avatar/BLAvatar.swift
  - AGENTS.md
  - apps/ios/BuyLedger/Features/Orders/Components/OptionPickerSheet.swift
  - apps/ios/BuyLedger/Features/Orders/OrderEditFeature.swift
  - apps/ios/BuyLedgerUITests/Tests/Performance/LaunchPerformanceTests.swift
  - apps/ios/BuyLedger/Features/Orders/OrderMergeFeature.swift
  - apps/ios/BuyLedgerTests/CampaignSummaryTests.swift
  - apps/ios/BuyLedger/Core/Diagnostics/CrashDiagnosticsClient.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupNameEditorSheet.swift
  - apps/ios/BuyLedger/Core/Dependencies/PaymentMethodRepository.swift
  - shared/data-model/fixtures/expected/typescript/SamplePreference.ts
  - apps/ios/BuyLedger.xcodeproj/project.pbxproj
  - apps/ios/BuyLedgerTests/LookupManagementFeatureTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewBaseline.1.png
  - apps/ios/BuyLedger/Features/FX/FxRates.swift
  - apps/ios/BuyLedgerTests/ContrastComplianceTests.swift
  - apps/ios/BuyLedger/Core/Persistence/ReconciliationStatusRecord.swift
  - apps/ios/BuyLedger/Features/Settings/AISummaryModelCatalog.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewMultiSelectBaseline.1.png
  - apps/ios/BuyLedger/Features/Insights/InsightsView.swift
  - apps/ios/BuyLedger/Core/Dependencies/CurrencyMetadataRepository.swift
  - apps/ios/BuyLedgerTests/BLFormattersTests.swift
  - apps/ios/BuyLedger/Core/Persistence/PersistenceStoreQuarantine.swift
  - apps/ios/BuyLedger/Core/Domain/Campaign.swift
  - apps/ios/BuyLedger/Core/Persistence/CampaignReminderRecord.swift
  - apps/ios/BuyLedger/Features/App/AppScenePhaseCoordinator.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignFormatters.swift
  - apps/ios/BuyLedger/Core/Domain/LedgerOrder.swift
  - shared/data-model/fixtures/expected/typescript/SampleGrade.ts
  - shared/data-model/fixtures/schema/sample-trait-matrix.yaml
  - apps/ios/BuyLedger/Core/Testing/BLUITestDependencyOverrides.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLDonutChart.swift
  - apps/ios/BuyLedger/Core/Dependencies/CategoryRepository.swift
  - apps/ios/BuyLedger/Core/Persistence/CategoryRecord.swift
  - apps/ios/BuyLedger/Core/Persistence/CampaignReminderPersistence.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestSeedData.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Pickers/OptionPickerSheet.swift
  - apps/ios/BuyLedger/Features/App/PersistenceFailureView.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/ViewModifiers/BLCardShadow.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/States/BLDelayedProgressView.swift
  - shared/data-model/fixtures/schema/sample-enums.yaml
  - shared/data-model/generator/src/datamodel-gen.ts
  - apps/ios/BuyLedger/Features/Insights/InsightsFeature.swift
  - apps/ios/BuyLedger/Core/Persistence/PersistenceStoreQuarantineClient.swift
  - apps/ios/BuyLedger/Core/Persistence/NameLookupPersistence.swift
  - apps/ios/BuyLedger/Core/Domain/CurrencyCode.swift
  - apps/ios/BuyLedger/Core/Testing/BLUITestSeedProfile.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderDetailTests.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/PaymentMethodInfo.generated.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLStatusHue.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersFeature.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLHeatmapDepth.swift
  - apps/ios/BuyLedger/Features/App/RootSidebarLayout.swift
  - apps/ios/BuyLedger/Features/Customers/CustomersFeature.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/Money.generated.swift
  - shared/data-model/fixtures/expected/swift/SampleQuote.generated.swift
  - shared/data-model/schema/CustomerTier.yaml
  - apps/ios/BuyLedgerUITests/Tests/Smoke/LaunchSmokeTests.swift
  - shared/data-model/schema/Campaign.yaml
  - apps/ios/BuyLedgerUITests/Screens/CampaignDetailScreen.swift
  - apps/ios/BuyLedgerTests/CampaignEditFeatureTests.swift
  - apps/ios/BuyLedger/Core/Dependencies/OpenSettingsClient.swift
  - apps/ios/BuyLedger/Resources/Localizable.xcstrings
  - apps/ios/BuyLedger/Features/Settings/SettingsStorage.swift
  - apps/ios/BuyLedger/Features/AISummary/AISummaryView.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/PaymentReceiptStatus.generated.swift
  - apps/ios/BuyLedger/Features/Orders/Components/PaymentMethodEditorSheet.swift
  - shared/data-model/schema/Money.yaml
  - apps/ios/BuyLedgerTests/SnapshotTests.swift
  - apps/ios/BuyLedger.xcodeproj/xcshareddata/xcschemes/BuyLedger.xcscheme
  - apps/ios/BuyLedger/Features/Orders/Components/MergePhotoPickerSheet.swift
  - apps/ios/BuyLedger/Features/App/RootTab.swift
  - apps/ios/BuyLedgerTests/CampaignIntegrationTests.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsFeature.swift
  - apps/ios/BuyLedgerTests/DashboardStatsTests.swift
  - apps/ios/BuyLedgerUITests/Support/Assertions.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupKind.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLSparkline.swift
  - apps/ios/BuyLedgerTests/OrderCalculationTests.swift
  - shared/data-model/fixtures/expected/typescript/SampleStatus.ts
  - README.md
  - apps/ios/BuyLedgerTests/PaymentMethodPersistenceTests.swift
  - apps/ios/BuyLedger/Features/App/PersistenceFailureFeature.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Badges/BLBadge.swift
  - shared/data-model/schema/FxRateSnapshot.yaml
  - apps/ios/BuyLedgerTests/CampaignReminderFailureTests.swift
  - apps/ios/BuyLedger/Core/Dependencies/ReconciliationStatusRepository.swift
  - apps/ios/BuyLedgerUITests/Support/AppNavigator.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderStatus+Presentation.swift
  - apps/ios/BuyLedger/Features/FX/FxFeature.swift
  - apps/ios/BuyLedger/Features/Orders/OrderDraft.swift
  - apps/ios/BuyLedgerTests/LayerBoundaryTests.swift
  - apps/ios/BuyLedgerTests/FxFeatureTests.swift
  - apps/ios/BuyLedger/Core/Sync/SyncQueueItem.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/FxRateSnapshot.generated.swift
  - apps/ios/BuyLedger/Core/Dependencies/CampaignReminderRepository.swift
  - apps/ios/BuyLedger/Features/Orders/OrderStatusFilter.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/AISummaryTests.swift
  - apps/ios/BuyLedgerUITests/Support/SheetInteraction.swift
  - apps/ios/BuyLedgerUITests/Support/ValueParsing.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/ViewModifiers/BLTypographyModifier.swift
  - apps/ios/BuyLedger/Features/App/RootView.swift
  - shared/data-model/schema/LedgerCustomer.yaml
  - apps/ios/BuyLedger/Core/Persistence/OrderSourcePersistence.swift
  - apps/ios/BuyLedger/Core/Persistence/PersistenceContainer.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderRowView.swift
  - apps/ios/BuyLedger/Core/Domain/LedgerOrder+Samples.swift
  - shared/data-model/schema/CampaignStatus.yaml
  - apps/ios/BuyLedgerTests/InsightsAttributionTests.swift
  - apps/ios/BuyLedgerUITests/Screens/AISummaryScreen.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/dashboardViewBaseline.1.png
  - apps/ios/BuyLedgerTests/OrderDraftTests.swift
  - apps/ios/BuyLedger/Core/Networking/ExchangeRateClient.swift
  - apps/ios/BuyLedger/Core/Domain/Campaign+Samples.swift
  - shared/data-model/fixtures/expected/kotlin/SampleProfile.kt
  - apps/ios/BuyLedger/Core/Persistence/OrderSourceRecord.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignEditView.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersBatchOperations.swift
  - apps/ios/BuyLedgerTests/ColorContrastTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Forms/PaymentMethodEditorSheet.swift
  - apps/ios/BuyLedger/Core/Persistence/PaymentMethodPersistence.swift
  - apps/ios/BuyLedger/Features/FX/ExchangeRateClient.swift
  - apps/ios/BuyLedger/Resources/PrivacyInfo.xcprivacy
  - apps/ios/BuyLedgerUITests/Support/Scrolling.swift
  - apps/ios/BuyLedger/Core/Networking/HTTPClient.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewLongContentBaseline.1.png
  - apps/ios/BuyLedgerTests/HTTPClientTests.swift
  - CLAUDE.md
  - apps/ios/BuyLedgerUITests/Screens/OrderDetailScreen.swift
  - apps/ios/BuyLedger/Core/Dependencies/OrderSourceRepository.swift
  - apps/ios/BuyLedgerTests/NameLookupPersistenceTests.swift
  - apps/ios/BuyLedgerUITests/Screens/FxScreen.swift
  - apps/ios/BuyLedgerTests/AccessibilityConventionScanTests.swift
  - apps/ios/BuyLedgerTests/APIErrorMappingTests.swift
  - shared/data-model/fixtures/expected/typescript/SampleQuote.ts
  - apps/ios/BuyLedgerTests/DesignSystemSourceScanTests.swift
  - apps/ios/BuyLedgerTests/CustomersFeatureTests.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersFeature+StateQuery.swift
  - apps/ios/BuyLedgerUITests/Tests/Campaigns/CampaignListTests.swift
  - apps/ios/BuyLedgerTests/CalendarReminderTests.swift
tests:
  - shared/data-model/generator/test/datamodel-gen.test.ts
-->

---
### Requirement: Order collection reads exclude photo bytes

The read path that returns all orders SHALL return each order with an empty photo list and SHALL declare the attributes it fetches so that the photo attribute is excluded. Photo bytes SHALL be obtainable only through a separate read addressed by order identifier. Consequently an empty photo list on an order obtained from a collection read SHALL NOT be interpreted as the order having no photos.

#### Scenario: Collection read carries no photo bytes

- **WHEN** all orders are read and one of them has stored photos
- **THEN** that order is returned with an empty photo list

#### Scenario: Photos are retrievable by order identifier

- **WHEN** the photos of a stored order are requested by its identifier
- **THEN** the stored photos are returned in their persisted order

#### Scenario: Requesting photos for an unknown order is not an error

- **WHEN** photos are requested for an identifier that matches no stored order
- **THEN** an empty list is returned rather than an error being raised


<!-- @trace
source: schema-v17-storage-cleanup
updated: 2026-08-15
code:
  - apps/ios/BuyLedger/Core/Persistence/PersistenceError.swift
  - apps/ios/BuyLedger/Features/Customers/CustomerRankBadgeStyle.swift
  - apps/ios/BuyLedger/Core/Persistence/CurrencyMetadataRecord.swift
  - apps/ios/BuyLedger/Core/Persistence/NameLookupRecord.swift
  - apps/ios/BuyLedgerTests/OrdersFeatureTests.swift
  - apps/ios/BuyLedgerTests/OrdersFeaturePerformanceTests.swift
  - apps/ios/BuyLedger/Core/Persistence/CampaignPersistence.swift
  - apps/ios/BuyLedger.xctestplan
  - apps/ios/BuyLedgerUITests/Tests/Tools/QuoteTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLBarChartValue.swift
  - shared/data-model/fixtures/expected/swift/SampleStatus.generated.swift
  - shared/data-model/fixtures/expected/kotlin/SamplePreference.kt
  - apps/ios/BuyLedger/Features/AISummary/OllamaDTO.swift
  - shared/data-model/fixtures/expected/swift/SampleReceipt.generated.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/States/BLLoadFailureView.swift
  - apps/ios/BuyLedgerUITests/Screens/InsightsScreen.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewBaseline.1.png
  - apps/ios/BuyLedger/Features/Customers/CustomersView.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoViewer.swift
  - apps/ios/BuyLedgerTests/PersistenceFailureFeatureTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLDonutSegment.swift
  - apps/ios/BuyLedgerTests/PhotoDataProcessorTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Tools/FxTests.swift
  - apps/ios/BuyLedger/Core/Networking/URLRequestBuilder.swift
  - shared/data-model/schema/OrderStatus.yaml
  - apps/ios/BuyLedgerTests/BLAccessibilityIDTests.swift
  - apps/ios/BuyLedgerTests/OrderEditFeatureTests.swift
  - shared/data-model/schema/CurrencyCode.yaml
  - apps/ios/BuyLedgerTests/DashboardFeatureTests.swift
  - apps/ios/BuyLedger/App/AppLaunchConfigurator.swift
  - apps/ios/BuyLedgerUITests/Support/LaunchOptions.swift
  - apps/ios/BuyLedger/Features/AISummary/AISummaryFeature.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersRegularViewMultiSelectBaseline.1.png
  - apps/ios/BuyLedgerUITests/Screens/CampaignsScreen.swift
  - shared/data-model/schema/PaymentMethodInfo.yaml
  - apps/ios/BuyLedger/Core/Persistence/CampaignRecord.swift
  - apps/ios/BuyLedger/Resources/Info.plist
  - apps/ios/BuyLedgerUITests/Support/BLUITestCase.swift
  - apps/ios/BuyLedgerTests/NumericInputGroupingScanTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Insights/InsightsTests.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderMergeCandidateSheet.swift
  - apps/ios/BuyLedgerAccessibilityIDs/BLAccessibilityID.swift
  - apps/ios/BuyLedgerTests/AISummaryFeatureTests.swift
  - apps/ios/BuyLedgerUITests.xctestplan
  - shared/data-model/schema/LedgerOrderItem.yaml
  - apps/ios/BuyLedgerTests/OrderMergeTests.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestSeedProfile.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementDestination.swift
  - apps/ios/BuyLedger/Resources/InfoPlist.xcstrings
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Tags/BLTagPill.swift
  - apps/ios/BuyLedgerUITests-Performance.xctestplan
  - apps/ios/BuyLedger/Core/Domain/Generated/Campaign.generated.swift
  - apps/ios/BuyLedgerTests/ColorContrast.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLTypography.swift
  - apps/ios/BuyLedger/Core/Domain/FxRateSnapshot.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/LedgerCustomer.generated.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/LedgerOrder.generated.swift
  - apps/ios/BuyLedgerTests/TestSuiteIntegrityTests.swift
  - apps/ios/BuyLedger/Features/Quote/QuoteView.swift
  - apps/ios/BuyLedger/Core/Dependencies/TelemetryClient.swift
  - apps/ios/BuyLedgerTests/OrdersFilterOperationsTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Smoke/AppLockTests.swift
  - apps/ios/BuyLedger/Core/Persistence/OrderRecord.swift
  - apps/ios/BuyLedgerUITests/Tests/Campaigns/CampaignDetailTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/quoteViewBaseline.1.png
  - apps/ios/BuyLedgerUITests/Screens/AppLockScreen.swift
  - apps/ios/BuyLedger/Core/Dependencies/BiometricAuthClient.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/States/DelayedProgressView.swift
  - apps/ios/BuyLedgerTests/PersistenceRecoveryTests.swift
  - apps/ios/BuyLedger/Core/Dependencies/OrderRepository.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/CustomerTier.generated.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestConfiguration.swift
  - apps/ios/BuyLedgerUITests/Screens/PhotoViewerScreen.swift
  - apps/ios/BuyLedger/Shared/Localization/AppLanguage.swift
  - apps/ios/BuyLedger/Features/App/RootFeature.swift
  - apps/ios/BuyLedgerUITests/Screens/CustomersScreen.swift
  - apps/ios/BuyLedgerTests/LookupCatalogTests.swift
  - shared/data-model/fixtures/expected/swift/SamplePreference.generated.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Chips/BLFilterChip.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsView.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLMetrics.swift
  - apps/ios/BuyLedger/Core/Networking/APIError.swift
  - apps/ios/BuyLedger/Core/Persistence/OrderPersistence.swift
  - apps/ios/BuyLedger/Core/Sync/SyncMeta.swift
  - apps/ios/BuyLedger/Shared/Extensions/Bundle+Extensions.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignEditFeature.swift
  - apps/ios/BuyLedger/Core/Persistence/PaymentMethodRecord.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignDetailView.swift
  - apps/ios/BuyLedger/Core/Domain/OrderSummary.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoThumbnail.swift
  - apps/ios/BuyLedger/Core/Dependencies/CalendarReminderClient.swift
  - apps/ios/BuyLedgerTests/OrdersSearchCancellationTests.swift
  - shared/data-model/README.md
  - shared/data-model/fixtures/expected/typescript/SampleReceipt.ts
  - apps/ios/BuyLedger/Features/Lookups/LookupCatalog.swift
  - apps/ios/BuyLedgerTests/AppConfigurationTests.swift
  - apps/ios/BuyLedger/Shared/Extensions/Color+Extensions.swift
  - shared/data-model/fixtures/expected/typescript/SampleProfile.ts
  - shared/data-model/fixtures/expected/kotlin/SampleQuote.kt
  - apps/ios/BuyLedgerTests/SettingsFeatureTests.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardView.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersView.swift
  - shared/data-model/fixtures/expected/swift/SampleSequence.generated.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsSnapshot.swift
  - apps/ios/BuyLedgerTests/PrivacyManifestTests.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderDetailView.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderSelectableRow.swift
  - apps/ios/BuyLedgerTests/OrderPersistenceTests.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardStats.swift
  - apps/ios/BuyLedger/Core/Domain/LedgerOrderItem.swift
  - apps/ios/BuyLedgerTests/ExchangeRateClientTests.swift
  - apps/ios/BuyLedger/Features/More/MoreView.swift
  - apps/ios/CLAUDE.md
  - shared/data-model/fixtures/expected/swift/SampleProfile.generated.swift
  - apps/ios/BuyLedger/App/AppDelegate.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLTone.swift
  - apps/ios/BuyLedgerUITests/Screens/OptionPickerScreen.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLBarChart.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLFormatters.swift
  - apps/ios/BuyLedgerTests/BLUITestConfigurationTests.swift
  - apps/ios/BuyLedger/Features/App/SidebarBadgeCounts.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrdersListTests.swift
  - apps/ios/BuyLedgerTests/TestDependencies.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/ViewModifiers/BLHeroCardBackground.swift
  - apps/ios/BuyLedger/Core/Testing/BLUITestSeedData.swift
  - apps/ios/BuyLedger/Core/Domain/OrderStatus.swift
  - apps/ios/BuyLedgerTests/OllamaClientTests.swift
  - apps/ios/BuyLedgerUITests/Screens/OrdersScreen.swift
  - apps/ios/BuyLedger/Core/Networking/ExchangeRateDTO.swift
  - apps/ios/BuyLedgerUITests/Screens/CampaignEditScreen.swift
  - apps/ios/BuyLedgerTests/QuoteFeatureTests.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrdersToolbarContent.swift
  - apps/ios/BuyLedgerTests/OrderStatusTests.swift
  - apps/ios/BuyLedgerTests/AppLockFeatureTests.swift
  - apps/ios/BuyLedger/Core/Dependencies/CampaignRepository.swift
  - apps/ios/BuyLedger/Core/Testing/BLUITestConfiguration.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Progress/BLProgressBar.swift
  - shared/data-model/fixtures/expected/kotlin/SampleSequence.kt
  - apps/ios/BuyLedgerTests/LocalizationCatalogTests.swift
  - apps/ios/BuyLedgerTests/SchemaMigrationTests.swift
  - shared/data-model/fixtures/expected/kotlin/SampleStatus.kt
  - apps/ios/BuyLedger/Features/Settings/AppLanguage.swift
  - apps/ios/BuyLedgerTests/BLPhotoViewerTests.swift
  - apps/ios/BuyLedger/Core/Persistence/ReconciliationStatusPersistence.swift
  - apps/ios/BuyLedger/Core/Networking/HTTPMethod.swift
  - apps/ios/BuyLedger/Core/Domain/FxRates.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementView.swift
  - apps/ios/BuyLedgerUITests/Tests/Smoke/HarnessSelfCheckTests.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/CampaignStatus.generated.swift
  - apps/ios/BuyLedger/Shared/Extensions/Decimal+Extensions.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFilterSheet.swift
  - apps/ios/BuyLedgerUITests/Screens/RootNavigationScreen.swift
  - apps/ios/BuyLedger/Core/Persistence/BuyLedgerSchema.swift
  - apps/ios/BuyLedgerTests/InsightsFeatureTests.swift
  - apps/ios/BuyLedger/Features/Orders/OrderDetailPath.swift
  - apps/ios/BuyLedger/Features/App/AppLockView.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignSummary.swift
  - apps/ios/BuyLedger/Features/FX/FxView.swift
  - apps/ios/BuyLedgerUITests/Support/AlertInteraction.swift
  - apps/ios/BuyLedgerUITests/Support/Diagnostics.swift
  - apps/ios/BuyLedgerTests/OrdersBatchOperationsTests.swift
  - apps/ios/BuyLedger/Features/Quote/QuoteFeature.swift
  - apps/ios/BuyLedger/Features/App/AppLockFeature.swift
  - apps/ios/BuyLedgerTests/OrderMergeFeatureTests.swift
  - apps/ios/BuyLedgerUITests/Support/MenuInteraction.swift
  - apps/ios/README.md
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderMergeTests.swift
  - apps/ios/BuyLedgerTests/BiometricAuthClientTests.swift
  - apps/ios/BuyLedger/Features/Orders/OrderDatePeriod.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLPalette.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Status/BLStatusPill.swift
  - apps/ios/BuyLedger/Features/Orders/LedgerOrder+OrderMutation.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/LedgerOrderItem.generated.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignFeature.swift
  - apps/ios/BuyLedger/Features/App/RootTabLayout.swift
  - shared/data-model/fixtures/schema/sample-orders.yaml
  - apps/ios/BuyLedger/App/BuyLedgerApp.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/OrderStatus.generated.swift
  - apps/ios/BuyLedger/Features/FX/ExchangeRateDTO.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/CurrencyCode.generated.swift
  - apps/ios/BuyLedgerUITests/Screens/QuoteScreen.swift
  - shared/data-model/fixtures/expected/kotlin/SampleReceipt.kt
  - apps/ios/BuyLedgerTests/OrdersLoadStateTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewLongIdentifierBaseline.1.png
  - apps/ios/BuyLedgerUITests/KeyboardDismissTests.swift
  - apps/ios/BuyLedgerUITests/Screens/SettingsScreen.swift
  - apps/ios/BuyLedgerTests/OrderEditFocusTests.swift
  - apps/ios/BuyLedgerTests/ProjectionWriteBoundaryTests.swift
  - apps/ios/BuyLedger/Features/AISummary/OllamaClient.swift
  - apps/ios/BuyLedger/Features/Orders/OrderEditView.swift
  - apps/ios/BuyLedgerTests/PersistenceErrorContractTests.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersCompactView.swift
  - apps/ios/BuyLedgerUITests/Screens/DashboardScreen.swift
  - apps/ios/BuyLedger/Core/Persistence/CategoryPersistence.swift
  - apps/ios/BuyLedger/Core/Domain/OrderMerge.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardFeature.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Buttons/BLButtonStyle.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Cards/BLCard.swift
  - apps/ios/BuyLedgerUITests/Support/TextInput.swift
  - apps/ios/BuyLedger/Core/Dependencies/PhotoClient.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/quoteViewRateUnavailable.1.png
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFormatters.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignListView.swift
  - apps/ios/BuyLedgerTests/AppScenePhaseCoordinatorTests.swift
  - apps/ios/BuyLedgerUITests/Screens/MergeFlowScreen.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderCreateTests.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsStats.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestHarness.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestDependencyOverrides.swift
  - shared/data-model/fixtures/expected/typescript/SampleSequence.ts
  - apps/ios/BuyLedgerUITests/PhotoViewerPagingTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Campaigns/CampaignCrudTests.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersFilterOperations.swift
  - apps/ios/BuyLedger/Shared/Media/PhotoDataProcessor.swift
  - apps/ios/BuyLedgerUITests/Screens/OrderEditScreen.swift
  - shared/data-model/schema/PaymentReceiptStatus.yaml
  - shared/data-model/schema/LedgerOrder.yaml
  - apps/ios/BuyLedgerUITests/Support/Waiting.swift
  - apps/ios/BuyLedger/Resources/GoogleService-Info.example.plist
  - apps/ios/BuyLedger/Core/Testing/BLUITestHarness.swift
  - apps/ios/BuyLedger/Core/Persistence/CurrencyMetadataPersistence.swift
  - apps/ios/BuyLedger/Core/Networking/AppConfiguration.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersMergeFlowOperations.swift
  - apps/ios/BuyLedger/Shared/Extensions/Image+Extensions.swift
  - shared/data-model/fixtures/expected/swift/SampleGrade.generated.swift
  - apps/ios/BuyLedger/Core/Dependencies/NameLookupOperations.swift
  - apps/ios/BuyLedgerUITests/Screens/Screen.swift
  - shared/data-model/fixtures/expected/kotlin/SampleGrade.kt
  - apps/ios/BuyLedger.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
  - apps/ios/BuyLedgerTests/CampaignPersistenceTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderEditDirtyTests.swift
  - apps/ios/BuyLedgerTests/CurrencyMetadataCacheTests.swift
  - apps/ios/BuyLedgerTests/InsightsStatsTests.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsDateRange.swift
  - apps/ios/BuyLedgerUITests/Tests/Customers/CustomersTests.swift
  - .github/workflows/ci.yml
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/persistenceFailureViewBaseline.1.png
  - apps/ios/BuyLedgerTests/CampaignFeatureTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Avatar/BLAvatar.swift
  - AGENTS.md
  - apps/ios/BuyLedger/Features/Orders/Components/OptionPickerSheet.swift
  - apps/ios/BuyLedger/Features/Orders/OrderEditFeature.swift
  - apps/ios/BuyLedgerUITests/Tests/Performance/LaunchPerformanceTests.swift
  - apps/ios/BuyLedger/Features/Orders/OrderMergeFeature.swift
  - apps/ios/BuyLedgerTests/CampaignSummaryTests.swift
  - apps/ios/BuyLedger/Core/Diagnostics/CrashDiagnosticsClient.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupNameEditorSheet.swift
  - apps/ios/BuyLedger/Core/Dependencies/PaymentMethodRepository.swift
  - shared/data-model/fixtures/expected/typescript/SamplePreference.ts
  - apps/ios/BuyLedger.xcodeproj/project.pbxproj
  - apps/ios/BuyLedgerTests/LookupManagementFeatureTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewBaseline.1.png
  - apps/ios/BuyLedger/Features/FX/FxRates.swift
  - apps/ios/BuyLedgerTests/ContrastComplianceTests.swift
  - apps/ios/BuyLedger/Core/Persistence/ReconciliationStatusRecord.swift
  - apps/ios/BuyLedger/Features/Settings/AISummaryModelCatalog.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewMultiSelectBaseline.1.png
  - apps/ios/BuyLedger/Features/Insights/InsightsView.swift
  - apps/ios/BuyLedger/Core/Dependencies/CurrencyMetadataRepository.swift
  - apps/ios/BuyLedgerTests/BLFormattersTests.swift
  - apps/ios/BuyLedger/Core/Persistence/PersistenceStoreQuarantine.swift
  - apps/ios/BuyLedger/Core/Domain/Campaign.swift
  - apps/ios/BuyLedger/Core/Persistence/CampaignReminderRecord.swift
  - apps/ios/BuyLedger/Features/App/AppScenePhaseCoordinator.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignFormatters.swift
  - apps/ios/BuyLedger/Core/Domain/LedgerOrder.swift
  - shared/data-model/fixtures/expected/typescript/SampleGrade.ts
  - shared/data-model/fixtures/schema/sample-trait-matrix.yaml
  - apps/ios/BuyLedger/Core/Testing/BLUITestDependencyOverrides.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLDonutChart.swift
  - apps/ios/BuyLedger/Core/Dependencies/CategoryRepository.swift
  - apps/ios/BuyLedger/Core/Persistence/CategoryRecord.swift
  - apps/ios/BuyLedger/Core/Persistence/CampaignReminderPersistence.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestSeedData.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Pickers/OptionPickerSheet.swift
  - apps/ios/BuyLedger/Features/App/PersistenceFailureView.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/ViewModifiers/BLCardShadow.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/States/BLDelayedProgressView.swift
  - shared/data-model/fixtures/schema/sample-enums.yaml
  - shared/data-model/generator/src/datamodel-gen.ts
  - apps/ios/BuyLedger/Features/Insights/InsightsFeature.swift
  - apps/ios/BuyLedger/Core/Persistence/PersistenceStoreQuarantineClient.swift
  - apps/ios/BuyLedger/Core/Persistence/NameLookupPersistence.swift
  - apps/ios/BuyLedger/Core/Domain/CurrencyCode.swift
  - apps/ios/BuyLedger/Core/Testing/BLUITestSeedProfile.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderDetailTests.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/PaymentMethodInfo.generated.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLStatusHue.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersFeature.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLHeatmapDepth.swift
  - apps/ios/BuyLedger/Features/App/RootSidebarLayout.swift
  - apps/ios/BuyLedger/Features/Customers/CustomersFeature.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/Money.generated.swift
  - shared/data-model/fixtures/expected/swift/SampleQuote.generated.swift
  - shared/data-model/schema/CustomerTier.yaml
  - apps/ios/BuyLedgerUITests/Tests/Smoke/LaunchSmokeTests.swift
  - shared/data-model/schema/Campaign.yaml
  - apps/ios/BuyLedgerUITests/Screens/CampaignDetailScreen.swift
  - apps/ios/BuyLedgerTests/CampaignEditFeatureTests.swift
  - apps/ios/BuyLedger/Core/Dependencies/OpenSettingsClient.swift
  - apps/ios/BuyLedger/Resources/Localizable.xcstrings
  - apps/ios/BuyLedger/Features/Settings/SettingsStorage.swift
  - apps/ios/BuyLedger/Features/AISummary/AISummaryView.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/PaymentReceiptStatus.generated.swift
  - apps/ios/BuyLedger/Features/Orders/Components/PaymentMethodEditorSheet.swift
  - shared/data-model/schema/Money.yaml
  - apps/ios/BuyLedgerTests/SnapshotTests.swift
  - apps/ios/BuyLedger.xcodeproj/xcshareddata/xcschemes/BuyLedger.xcscheme
  - apps/ios/BuyLedger/Features/Orders/Components/MergePhotoPickerSheet.swift
  - apps/ios/BuyLedger/Features/App/RootTab.swift
  - apps/ios/BuyLedgerTests/CampaignIntegrationTests.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsFeature.swift
  - apps/ios/BuyLedgerTests/DashboardStatsTests.swift
  - apps/ios/BuyLedgerUITests/Support/Assertions.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupKind.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLSparkline.swift
  - apps/ios/BuyLedgerTests/OrderCalculationTests.swift
  - shared/data-model/fixtures/expected/typescript/SampleStatus.ts
  - README.md
  - apps/ios/BuyLedgerTests/PaymentMethodPersistenceTests.swift
  - apps/ios/BuyLedger/Features/App/PersistenceFailureFeature.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Badges/BLBadge.swift
  - shared/data-model/schema/FxRateSnapshot.yaml
  - apps/ios/BuyLedgerTests/CampaignReminderFailureTests.swift
  - apps/ios/BuyLedger/Core/Dependencies/ReconciliationStatusRepository.swift
  - apps/ios/BuyLedgerUITests/Support/AppNavigator.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderStatus+Presentation.swift
  - apps/ios/BuyLedger/Features/FX/FxFeature.swift
  - apps/ios/BuyLedger/Features/Orders/OrderDraft.swift
  - apps/ios/BuyLedgerTests/LayerBoundaryTests.swift
  - apps/ios/BuyLedgerTests/FxFeatureTests.swift
  - apps/ios/BuyLedger/Core/Sync/SyncQueueItem.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/FxRateSnapshot.generated.swift
  - apps/ios/BuyLedger/Core/Dependencies/CampaignReminderRepository.swift
  - apps/ios/BuyLedger/Features/Orders/OrderStatusFilter.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/AISummaryTests.swift
  - apps/ios/BuyLedgerUITests/Support/SheetInteraction.swift
  - apps/ios/BuyLedgerUITests/Support/ValueParsing.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/ViewModifiers/BLTypographyModifier.swift
  - apps/ios/BuyLedger/Features/App/RootView.swift
  - shared/data-model/schema/LedgerCustomer.yaml
  - apps/ios/BuyLedger/Core/Persistence/OrderSourcePersistence.swift
  - apps/ios/BuyLedger/Core/Persistence/PersistenceContainer.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderRowView.swift
  - apps/ios/BuyLedger/Core/Domain/LedgerOrder+Samples.swift
  - shared/data-model/schema/CampaignStatus.yaml
  - apps/ios/BuyLedgerTests/InsightsAttributionTests.swift
  - apps/ios/BuyLedgerUITests/Screens/AISummaryScreen.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/dashboardViewBaseline.1.png
  - apps/ios/BuyLedgerTests/OrderDraftTests.swift
  - apps/ios/BuyLedger/Core/Networking/ExchangeRateClient.swift
  - apps/ios/BuyLedger/Core/Domain/Campaign+Samples.swift
  - shared/data-model/fixtures/expected/kotlin/SampleProfile.kt
  - apps/ios/BuyLedger/Core/Persistence/OrderSourceRecord.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignEditView.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersBatchOperations.swift
  - apps/ios/BuyLedgerTests/ColorContrastTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Forms/PaymentMethodEditorSheet.swift
  - apps/ios/BuyLedger/Core/Persistence/PaymentMethodPersistence.swift
  - apps/ios/BuyLedger/Features/FX/ExchangeRateClient.swift
  - apps/ios/BuyLedger/Resources/PrivacyInfo.xcprivacy
  - apps/ios/BuyLedgerUITests/Support/Scrolling.swift
  - apps/ios/BuyLedger/Core/Networking/HTTPClient.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewLongContentBaseline.1.png
  - apps/ios/BuyLedgerTests/HTTPClientTests.swift
  - CLAUDE.md
  - apps/ios/BuyLedgerUITests/Screens/OrderDetailScreen.swift
  - apps/ios/BuyLedger/Core/Dependencies/OrderSourceRepository.swift
  - apps/ios/BuyLedgerTests/NameLookupPersistenceTests.swift
  - apps/ios/BuyLedgerUITests/Screens/FxScreen.swift
  - apps/ios/BuyLedgerTests/AccessibilityConventionScanTests.swift
  - apps/ios/BuyLedgerTests/APIErrorMappingTests.swift
  - shared/data-model/fixtures/expected/typescript/SampleQuote.ts
  - apps/ios/BuyLedgerTests/DesignSystemSourceScanTests.swift
  - apps/ios/BuyLedgerTests/CustomersFeatureTests.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersFeature+StateQuery.swift
  - apps/ios/BuyLedgerUITests/Tests/Campaigns/CampaignListTests.swift
  - apps/ios/BuyLedgerTests/CalendarReminderTests.swift
tests:
  - shared/data-model/generator/test/datamodel-gen.test.ts
-->

---
### Requirement: Writes that do not carry photos leave stored photos intact

Applying a domain order onto an existing order record SHALL NOT write the photo attribute. Photos SHALL be written only through a distinct write that requires the caller to supply the photo list explicitly. Creating a new order record SHALL persist the photos supplied with it. As a result, any write path that does not explicitly carry photos SHALL leave the stored photos unchanged rather than clearing them.

#### Scenario: Batch status change preserves photos

- **WHEN** several orders including one with photos have their status changed in a batch write that carries no photos
- **THEN** the stored photos of that order are unchanged

#### Scenario: Master-data rename preserves photos

- **WHEN** an order source, category, payment method, reconciliation status, or campaign referenced by an order with photos is renamed and the order is rebuilt and written back without photos
- **THEN** the stored photos of that order are unchanged

#### Scenario: A newly created order keeps the photos it was created with

- **WHEN** an order that does not yet exist is written with a non-empty photo list
- **THEN** the photos are persisted with the new record

#### Scenario: Explicit photo write replaces the stored set

- **WHEN** an existing order is written through the photo-carrying write with a different photo list
- **THEN** the stored photos are replaced by the supplied list

<!-- @trace
source: schema-v17-storage-cleanup
updated: 2026-08-15
code:
  - apps/ios/BuyLedger/Core/Persistence/PersistenceError.swift
  - apps/ios/BuyLedger/Features/Customers/CustomerRankBadgeStyle.swift
  - apps/ios/BuyLedger/Core/Persistence/CurrencyMetadataRecord.swift
  - apps/ios/BuyLedger/Core/Persistence/NameLookupRecord.swift
  - apps/ios/BuyLedgerTests/OrdersFeatureTests.swift
  - apps/ios/BuyLedgerTests/OrdersFeaturePerformanceTests.swift
  - apps/ios/BuyLedger/Core/Persistence/CampaignPersistence.swift
  - apps/ios/BuyLedger.xctestplan
  - apps/ios/BuyLedgerUITests/Tests/Tools/QuoteTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLBarChartValue.swift
  - shared/data-model/fixtures/expected/swift/SampleStatus.generated.swift
  - shared/data-model/fixtures/expected/kotlin/SamplePreference.kt
  - apps/ios/BuyLedger/Features/AISummary/OllamaDTO.swift
  - shared/data-model/fixtures/expected/swift/SampleReceipt.generated.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/States/BLLoadFailureView.swift
  - apps/ios/BuyLedgerUITests/Screens/InsightsScreen.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewBaseline.1.png
  - apps/ios/BuyLedger/Features/Customers/CustomersView.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoViewer.swift
  - apps/ios/BuyLedgerTests/PersistenceFailureFeatureTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLDonutSegment.swift
  - apps/ios/BuyLedgerTests/PhotoDataProcessorTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Tools/FxTests.swift
  - apps/ios/BuyLedger/Core/Networking/URLRequestBuilder.swift
  - shared/data-model/schema/OrderStatus.yaml
  - apps/ios/BuyLedgerTests/BLAccessibilityIDTests.swift
  - apps/ios/BuyLedgerTests/OrderEditFeatureTests.swift
  - shared/data-model/schema/CurrencyCode.yaml
  - apps/ios/BuyLedgerTests/DashboardFeatureTests.swift
  - apps/ios/BuyLedger/App/AppLaunchConfigurator.swift
  - apps/ios/BuyLedgerUITests/Support/LaunchOptions.swift
  - apps/ios/BuyLedger/Features/AISummary/AISummaryFeature.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersRegularViewMultiSelectBaseline.1.png
  - apps/ios/BuyLedgerUITests/Screens/CampaignsScreen.swift
  - shared/data-model/schema/PaymentMethodInfo.yaml
  - apps/ios/BuyLedger/Core/Persistence/CampaignRecord.swift
  - apps/ios/BuyLedger/Resources/Info.plist
  - apps/ios/BuyLedgerUITests/Support/BLUITestCase.swift
  - apps/ios/BuyLedgerTests/NumericInputGroupingScanTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Insights/InsightsTests.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderMergeCandidateSheet.swift
  - apps/ios/BuyLedgerAccessibilityIDs/BLAccessibilityID.swift
  - apps/ios/BuyLedgerTests/AISummaryFeatureTests.swift
  - apps/ios/BuyLedgerUITests.xctestplan
  - shared/data-model/schema/LedgerOrderItem.yaml
  - apps/ios/BuyLedgerTests/OrderMergeTests.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestSeedProfile.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementDestination.swift
  - apps/ios/BuyLedger/Resources/InfoPlist.xcstrings
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Tags/BLTagPill.swift
  - apps/ios/BuyLedgerUITests-Performance.xctestplan
  - apps/ios/BuyLedger/Core/Domain/Generated/Campaign.generated.swift
  - apps/ios/BuyLedgerTests/ColorContrast.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLTypography.swift
  - apps/ios/BuyLedger/Core/Domain/FxRateSnapshot.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/LedgerCustomer.generated.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/LedgerOrder.generated.swift
  - apps/ios/BuyLedgerTests/TestSuiteIntegrityTests.swift
  - apps/ios/BuyLedger/Features/Quote/QuoteView.swift
  - apps/ios/BuyLedger/Core/Dependencies/TelemetryClient.swift
  - apps/ios/BuyLedgerTests/OrdersFilterOperationsTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Smoke/AppLockTests.swift
  - apps/ios/BuyLedger/Core/Persistence/OrderRecord.swift
  - apps/ios/BuyLedgerUITests/Tests/Campaigns/CampaignDetailTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/quoteViewBaseline.1.png
  - apps/ios/BuyLedgerUITests/Screens/AppLockScreen.swift
  - apps/ios/BuyLedger/Core/Dependencies/BiometricAuthClient.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/States/DelayedProgressView.swift
  - apps/ios/BuyLedgerTests/PersistenceRecoveryTests.swift
  - apps/ios/BuyLedger/Core/Dependencies/OrderRepository.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/CustomerTier.generated.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestConfiguration.swift
  - apps/ios/BuyLedgerUITests/Screens/PhotoViewerScreen.swift
  - apps/ios/BuyLedger/Shared/Localization/AppLanguage.swift
  - apps/ios/BuyLedger/Features/App/RootFeature.swift
  - apps/ios/BuyLedgerUITests/Screens/CustomersScreen.swift
  - apps/ios/BuyLedgerTests/LookupCatalogTests.swift
  - shared/data-model/fixtures/expected/swift/SamplePreference.generated.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Chips/BLFilterChip.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsView.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLMetrics.swift
  - apps/ios/BuyLedger/Core/Networking/APIError.swift
  - apps/ios/BuyLedger/Core/Persistence/OrderPersistence.swift
  - apps/ios/BuyLedger/Core/Sync/SyncMeta.swift
  - apps/ios/BuyLedger/Shared/Extensions/Bundle+Extensions.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignEditFeature.swift
  - apps/ios/BuyLedger/Core/Persistence/PaymentMethodRecord.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignDetailView.swift
  - apps/ios/BuyLedger/Core/Domain/OrderSummary.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoThumbnail.swift
  - apps/ios/BuyLedger/Core/Dependencies/CalendarReminderClient.swift
  - apps/ios/BuyLedgerTests/OrdersSearchCancellationTests.swift
  - shared/data-model/README.md
  - shared/data-model/fixtures/expected/typescript/SampleReceipt.ts
  - apps/ios/BuyLedger/Features/Lookups/LookupCatalog.swift
  - apps/ios/BuyLedgerTests/AppConfigurationTests.swift
  - apps/ios/BuyLedger/Shared/Extensions/Color+Extensions.swift
  - shared/data-model/fixtures/expected/typescript/SampleProfile.ts
  - shared/data-model/fixtures/expected/kotlin/SampleQuote.kt
  - apps/ios/BuyLedgerTests/SettingsFeatureTests.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardView.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersView.swift
  - shared/data-model/fixtures/expected/swift/SampleSequence.generated.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsSnapshot.swift
  - apps/ios/BuyLedgerTests/PrivacyManifestTests.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderDetailView.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderSelectableRow.swift
  - apps/ios/BuyLedgerTests/OrderPersistenceTests.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardStats.swift
  - apps/ios/BuyLedger/Core/Domain/LedgerOrderItem.swift
  - apps/ios/BuyLedgerTests/ExchangeRateClientTests.swift
  - apps/ios/BuyLedger/Features/More/MoreView.swift
  - apps/ios/CLAUDE.md
  - shared/data-model/fixtures/expected/swift/SampleProfile.generated.swift
  - apps/ios/BuyLedger/App/AppDelegate.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLTone.swift
  - apps/ios/BuyLedgerUITests/Screens/OptionPickerScreen.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLBarChart.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLFormatters.swift
  - apps/ios/BuyLedgerTests/BLUITestConfigurationTests.swift
  - apps/ios/BuyLedger/Features/App/SidebarBadgeCounts.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrdersListTests.swift
  - apps/ios/BuyLedgerTests/TestDependencies.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/ViewModifiers/BLHeroCardBackground.swift
  - apps/ios/BuyLedger/Core/Testing/BLUITestSeedData.swift
  - apps/ios/BuyLedger/Core/Domain/OrderStatus.swift
  - apps/ios/BuyLedgerTests/OllamaClientTests.swift
  - apps/ios/BuyLedgerUITests/Screens/OrdersScreen.swift
  - apps/ios/BuyLedger/Core/Networking/ExchangeRateDTO.swift
  - apps/ios/BuyLedgerUITests/Screens/CampaignEditScreen.swift
  - apps/ios/BuyLedgerTests/QuoteFeatureTests.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrdersToolbarContent.swift
  - apps/ios/BuyLedgerTests/OrderStatusTests.swift
  - apps/ios/BuyLedgerTests/AppLockFeatureTests.swift
  - apps/ios/BuyLedger/Core/Dependencies/CampaignRepository.swift
  - apps/ios/BuyLedger/Core/Testing/BLUITestConfiguration.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Progress/BLProgressBar.swift
  - shared/data-model/fixtures/expected/kotlin/SampleSequence.kt
  - apps/ios/BuyLedgerTests/LocalizationCatalogTests.swift
  - apps/ios/BuyLedgerTests/SchemaMigrationTests.swift
  - shared/data-model/fixtures/expected/kotlin/SampleStatus.kt
  - apps/ios/BuyLedger/Features/Settings/AppLanguage.swift
  - apps/ios/BuyLedgerTests/BLPhotoViewerTests.swift
  - apps/ios/BuyLedger/Core/Persistence/ReconciliationStatusPersistence.swift
  - apps/ios/BuyLedger/Core/Networking/HTTPMethod.swift
  - apps/ios/BuyLedger/Core/Domain/FxRates.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementView.swift
  - apps/ios/BuyLedgerUITests/Tests/Smoke/HarnessSelfCheckTests.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/CampaignStatus.generated.swift
  - apps/ios/BuyLedger/Shared/Extensions/Decimal+Extensions.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFilterSheet.swift
  - apps/ios/BuyLedgerUITests/Screens/RootNavigationScreen.swift
  - apps/ios/BuyLedger/Core/Persistence/BuyLedgerSchema.swift
  - apps/ios/BuyLedgerTests/InsightsFeatureTests.swift
  - apps/ios/BuyLedger/Features/Orders/OrderDetailPath.swift
  - apps/ios/BuyLedger/Features/App/AppLockView.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignSummary.swift
  - apps/ios/BuyLedger/Features/FX/FxView.swift
  - apps/ios/BuyLedgerUITests/Support/AlertInteraction.swift
  - apps/ios/BuyLedgerUITests/Support/Diagnostics.swift
  - apps/ios/BuyLedgerTests/OrdersBatchOperationsTests.swift
  - apps/ios/BuyLedger/Features/Quote/QuoteFeature.swift
  - apps/ios/BuyLedger/Features/App/AppLockFeature.swift
  - apps/ios/BuyLedgerTests/OrderMergeFeatureTests.swift
  - apps/ios/BuyLedgerUITests/Support/MenuInteraction.swift
  - apps/ios/README.md
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderMergeTests.swift
  - apps/ios/BuyLedgerTests/BiometricAuthClientTests.swift
  - apps/ios/BuyLedger/Features/Orders/OrderDatePeriod.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLPalette.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Status/BLStatusPill.swift
  - apps/ios/BuyLedger/Features/Orders/LedgerOrder+OrderMutation.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/LedgerOrderItem.generated.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignFeature.swift
  - apps/ios/BuyLedger/Features/App/RootTabLayout.swift
  - shared/data-model/fixtures/schema/sample-orders.yaml
  - apps/ios/BuyLedger/App/BuyLedgerApp.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/OrderStatus.generated.swift
  - apps/ios/BuyLedger/Features/FX/ExchangeRateDTO.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/CurrencyCode.generated.swift
  - apps/ios/BuyLedgerUITests/Screens/QuoteScreen.swift
  - shared/data-model/fixtures/expected/kotlin/SampleReceipt.kt
  - apps/ios/BuyLedgerTests/OrdersLoadStateTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewLongIdentifierBaseline.1.png
  - apps/ios/BuyLedgerUITests/KeyboardDismissTests.swift
  - apps/ios/BuyLedgerUITests/Screens/SettingsScreen.swift
  - apps/ios/BuyLedgerTests/OrderEditFocusTests.swift
  - apps/ios/BuyLedgerTests/ProjectionWriteBoundaryTests.swift
  - apps/ios/BuyLedger/Features/AISummary/OllamaClient.swift
  - apps/ios/BuyLedger/Features/Orders/OrderEditView.swift
  - apps/ios/BuyLedgerTests/PersistenceErrorContractTests.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersCompactView.swift
  - apps/ios/BuyLedgerUITests/Screens/DashboardScreen.swift
  - apps/ios/BuyLedger/Core/Persistence/CategoryPersistence.swift
  - apps/ios/BuyLedger/Core/Domain/OrderMerge.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardFeature.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Buttons/BLButtonStyle.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Cards/BLCard.swift
  - apps/ios/BuyLedgerUITests/Support/TextInput.swift
  - apps/ios/BuyLedger/Core/Dependencies/PhotoClient.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/quoteViewRateUnavailable.1.png
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFormatters.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignListView.swift
  - apps/ios/BuyLedgerTests/AppScenePhaseCoordinatorTests.swift
  - apps/ios/BuyLedgerUITests/Screens/MergeFlowScreen.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderCreateTests.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsStats.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestHarness.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestDependencyOverrides.swift
  - shared/data-model/fixtures/expected/typescript/SampleSequence.ts
  - apps/ios/BuyLedgerUITests/PhotoViewerPagingTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Campaigns/CampaignCrudTests.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersFilterOperations.swift
  - apps/ios/BuyLedger/Shared/Media/PhotoDataProcessor.swift
  - apps/ios/BuyLedgerUITests/Screens/OrderEditScreen.swift
  - shared/data-model/schema/PaymentReceiptStatus.yaml
  - shared/data-model/schema/LedgerOrder.yaml
  - apps/ios/BuyLedgerUITests/Support/Waiting.swift
  - apps/ios/BuyLedger/Resources/GoogleService-Info.example.plist
  - apps/ios/BuyLedger/Core/Testing/BLUITestHarness.swift
  - apps/ios/BuyLedger/Core/Persistence/CurrencyMetadataPersistence.swift
  - apps/ios/BuyLedger/Core/Networking/AppConfiguration.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersMergeFlowOperations.swift
  - apps/ios/BuyLedger/Shared/Extensions/Image+Extensions.swift
  - shared/data-model/fixtures/expected/swift/SampleGrade.generated.swift
  - apps/ios/BuyLedger/Core/Dependencies/NameLookupOperations.swift
  - apps/ios/BuyLedgerUITests/Screens/Screen.swift
  - shared/data-model/fixtures/expected/kotlin/SampleGrade.kt
  - apps/ios/BuyLedger.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
  - apps/ios/BuyLedgerTests/CampaignPersistenceTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderEditDirtyTests.swift
  - apps/ios/BuyLedgerTests/CurrencyMetadataCacheTests.swift
  - apps/ios/BuyLedgerTests/InsightsStatsTests.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsDateRange.swift
  - apps/ios/BuyLedgerUITests/Tests/Customers/CustomersTests.swift
  - .github/workflows/ci.yml
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/persistenceFailureViewBaseline.1.png
  - apps/ios/BuyLedgerTests/CampaignFeatureTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Avatar/BLAvatar.swift
  - AGENTS.md
  - apps/ios/BuyLedger/Features/Orders/Components/OptionPickerSheet.swift
  - apps/ios/BuyLedger/Features/Orders/OrderEditFeature.swift
  - apps/ios/BuyLedgerUITests/Tests/Performance/LaunchPerformanceTests.swift
  - apps/ios/BuyLedger/Features/Orders/OrderMergeFeature.swift
  - apps/ios/BuyLedgerTests/CampaignSummaryTests.swift
  - apps/ios/BuyLedger/Core/Diagnostics/CrashDiagnosticsClient.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupNameEditorSheet.swift
  - apps/ios/BuyLedger/Core/Dependencies/PaymentMethodRepository.swift
  - shared/data-model/fixtures/expected/typescript/SamplePreference.ts
  - apps/ios/BuyLedger.xcodeproj/project.pbxproj
  - apps/ios/BuyLedgerTests/LookupManagementFeatureTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewBaseline.1.png
  - apps/ios/BuyLedger/Features/FX/FxRates.swift
  - apps/ios/BuyLedgerTests/ContrastComplianceTests.swift
  - apps/ios/BuyLedger/Core/Persistence/ReconciliationStatusRecord.swift
  - apps/ios/BuyLedger/Features/Settings/AISummaryModelCatalog.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewMultiSelectBaseline.1.png
  - apps/ios/BuyLedger/Features/Insights/InsightsView.swift
  - apps/ios/BuyLedger/Core/Dependencies/CurrencyMetadataRepository.swift
  - apps/ios/BuyLedgerTests/BLFormattersTests.swift
  - apps/ios/BuyLedger/Core/Persistence/PersistenceStoreQuarantine.swift
  - apps/ios/BuyLedger/Core/Domain/Campaign.swift
  - apps/ios/BuyLedger/Core/Persistence/CampaignReminderRecord.swift
  - apps/ios/BuyLedger/Features/App/AppScenePhaseCoordinator.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignFormatters.swift
  - apps/ios/BuyLedger/Core/Domain/LedgerOrder.swift
  - shared/data-model/fixtures/expected/typescript/SampleGrade.ts
  - shared/data-model/fixtures/schema/sample-trait-matrix.yaml
  - apps/ios/BuyLedger/Core/Testing/BLUITestDependencyOverrides.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLDonutChart.swift
  - apps/ios/BuyLedger/Core/Dependencies/CategoryRepository.swift
  - apps/ios/BuyLedger/Core/Persistence/CategoryRecord.swift
  - apps/ios/BuyLedger/Core/Persistence/CampaignReminderPersistence.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestSeedData.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Pickers/OptionPickerSheet.swift
  - apps/ios/BuyLedger/Features/App/PersistenceFailureView.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/ViewModifiers/BLCardShadow.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/States/BLDelayedProgressView.swift
  - shared/data-model/fixtures/schema/sample-enums.yaml
  - shared/data-model/generator/src/datamodel-gen.ts
  - apps/ios/BuyLedger/Features/Insights/InsightsFeature.swift
  - apps/ios/BuyLedger/Core/Persistence/PersistenceStoreQuarantineClient.swift
  - apps/ios/BuyLedger/Core/Persistence/NameLookupPersistence.swift
  - apps/ios/BuyLedger/Core/Domain/CurrencyCode.swift
  - apps/ios/BuyLedger/Core/Testing/BLUITestSeedProfile.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderDetailTests.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/PaymentMethodInfo.generated.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLStatusHue.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersFeature.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLHeatmapDepth.swift
  - apps/ios/BuyLedger/Features/App/RootSidebarLayout.swift
  - apps/ios/BuyLedger/Features/Customers/CustomersFeature.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/Money.generated.swift
  - shared/data-model/fixtures/expected/swift/SampleQuote.generated.swift
  - shared/data-model/schema/CustomerTier.yaml
  - apps/ios/BuyLedgerUITests/Tests/Smoke/LaunchSmokeTests.swift
  - shared/data-model/schema/Campaign.yaml
  - apps/ios/BuyLedgerUITests/Screens/CampaignDetailScreen.swift
  - apps/ios/BuyLedgerTests/CampaignEditFeatureTests.swift
  - apps/ios/BuyLedger/Core/Dependencies/OpenSettingsClient.swift
  - apps/ios/BuyLedger/Resources/Localizable.xcstrings
  - apps/ios/BuyLedger/Features/Settings/SettingsStorage.swift
  - apps/ios/BuyLedger/Features/AISummary/AISummaryView.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/PaymentReceiptStatus.generated.swift
  - apps/ios/BuyLedger/Features/Orders/Components/PaymentMethodEditorSheet.swift
  - shared/data-model/schema/Money.yaml
  - apps/ios/BuyLedgerTests/SnapshotTests.swift
  - apps/ios/BuyLedger.xcodeproj/xcshareddata/xcschemes/BuyLedger.xcscheme
  - apps/ios/BuyLedger/Features/Orders/Components/MergePhotoPickerSheet.swift
  - apps/ios/BuyLedger/Features/App/RootTab.swift
  - apps/ios/BuyLedgerTests/CampaignIntegrationTests.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsFeature.swift
  - apps/ios/BuyLedgerTests/DashboardStatsTests.swift
  - apps/ios/BuyLedgerUITests/Support/Assertions.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupKind.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLSparkline.swift
  - apps/ios/BuyLedgerTests/OrderCalculationTests.swift
  - shared/data-model/fixtures/expected/typescript/SampleStatus.ts
  - README.md
  - apps/ios/BuyLedgerTests/PaymentMethodPersistenceTests.swift
  - apps/ios/BuyLedger/Features/App/PersistenceFailureFeature.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Badges/BLBadge.swift
  - shared/data-model/schema/FxRateSnapshot.yaml
  - apps/ios/BuyLedgerTests/CampaignReminderFailureTests.swift
  - apps/ios/BuyLedger/Core/Dependencies/ReconciliationStatusRepository.swift
  - apps/ios/BuyLedgerUITests/Support/AppNavigator.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderStatus+Presentation.swift
  - apps/ios/BuyLedger/Features/FX/FxFeature.swift
  - apps/ios/BuyLedger/Features/Orders/OrderDraft.swift
  - apps/ios/BuyLedgerTests/LayerBoundaryTests.swift
  - apps/ios/BuyLedgerTests/FxFeatureTests.swift
  - apps/ios/BuyLedger/Core/Sync/SyncQueueItem.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/FxRateSnapshot.generated.swift
  - apps/ios/BuyLedger/Core/Dependencies/CampaignReminderRepository.swift
  - apps/ios/BuyLedger/Features/Orders/OrderStatusFilter.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/AISummaryTests.swift
  - apps/ios/BuyLedgerUITests/Support/SheetInteraction.swift
  - apps/ios/BuyLedgerUITests/Support/ValueParsing.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/ViewModifiers/BLTypographyModifier.swift
  - apps/ios/BuyLedger/Features/App/RootView.swift
  - shared/data-model/schema/LedgerCustomer.yaml
  - apps/ios/BuyLedger/Core/Persistence/OrderSourcePersistence.swift
  - apps/ios/BuyLedger/Core/Persistence/PersistenceContainer.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderRowView.swift
  - apps/ios/BuyLedger/Core/Domain/LedgerOrder+Samples.swift
  - shared/data-model/schema/CampaignStatus.yaml
  - apps/ios/BuyLedgerTests/InsightsAttributionTests.swift
  - apps/ios/BuyLedgerUITests/Screens/AISummaryScreen.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/dashboardViewBaseline.1.png
  - apps/ios/BuyLedgerTests/OrderDraftTests.swift
  - apps/ios/BuyLedger/Core/Networking/ExchangeRateClient.swift
  - apps/ios/BuyLedger/Core/Domain/Campaign+Samples.swift
  - shared/data-model/fixtures/expected/kotlin/SampleProfile.kt
  - apps/ios/BuyLedger/Core/Persistence/OrderSourceRecord.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignEditView.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersBatchOperations.swift
  - apps/ios/BuyLedgerTests/ColorContrastTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Forms/PaymentMethodEditorSheet.swift
  - apps/ios/BuyLedger/Core/Persistence/PaymentMethodPersistence.swift
  - apps/ios/BuyLedger/Features/FX/ExchangeRateClient.swift
  - apps/ios/BuyLedger/Resources/PrivacyInfo.xcprivacy
  - apps/ios/BuyLedgerUITests/Support/Scrolling.swift
  - apps/ios/BuyLedger/Core/Networking/HTTPClient.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewLongContentBaseline.1.png
  - apps/ios/BuyLedgerTests/HTTPClientTests.swift
  - CLAUDE.md
  - apps/ios/BuyLedgerUITests/Screens/OrderDetailScreen.swift
  - apps/ios/BuyLedger/Core/Dependencies/OrderSourceRepository.swift
  - apps/ios/BuyLedgerTests/NameLookupPersistenceTests.swift
  - apps/ios/BuyLedgerUITests/Screens/FxScreen.swift
  - apps/ios/BuyLedgerTests/AccessibilityConventionScanTests.swift
  - apps/ios/BuyLedgerTests/APIErrorMappingTests.swift
  - shared/data-model/fixtures/expected/typescript/SampleQuote.ts
  - apps/ios/BuyLedgerTests/DesignSystemSourceScanTests.swift
  - apps/ios/BuyLedgerTests/CustomersFeatureTests.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersFeature+StateQuery.swift
  - apps/ios/BuyLedgerUITests/Tests/Campaigns/CampaignListTests.swift
  - apps/ios/BuyLedgerTests/CalendarReminderTests.swift
tests:
  - shared/data-model/generator/test/datamodel-gen.test.ts
-->