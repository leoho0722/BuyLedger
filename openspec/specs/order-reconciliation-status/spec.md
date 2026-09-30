# order-reconciliation-status Specification

## Purpose

TBD - created by archiving change 'order-reconciliation-status'. Update Purpose after archive.

## Requirements

### Requirement: Payment method bank-transfer classification

The system SHALL allow a payment method to be flagged as "bank transfer" (`isBankTransfer`), independent of the existing "cardless" (`isCardless`) flag. The new-payment-method editor SHALL collect both flags via separate toggles. The bank-transfer flag SHALL default to false and SHALL persist across app launches. The two flags SHALL be independent — a payment method MAY have neither, either, or both set.

#### Scenario: Add a payment method flagged as bank transfer

- **WHEN** the user adds a payment method and enables the "bank transfer" toggle
- **THEN** the payment method is stored with `isBankTransfer` set to true and `isCardless` reflecting its own toggle

#### Scenario: Bank-transfer flag defaults to false

- **WHEN** the user adds a payment method without enabling the "bank transfer" toggle
- **THEN** the payment method is stored with `isBankTransfer` set to false

#### Scenario: Bank-transfer flag persists across launches

- **WHEN** a payment method flagged as bank transfer is read back after an app relaunch
- **THEN** its `isBankTransfer` flag is still true


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
### Requirement: Conditional reconciliation status row in order editing

WHEN the payment method currently selected in the order edit form is flagged cardless OR bank-transfer, the form SHALL display a "reconciliation status" (對帳狀態) row directly below the payment method row. WHEN the selected payment method is neither cardless nor bank-transfer, the form SHALL NOT display the reconciliation status row. The visibility SHALL update immediately when the selected payment method changes.

#### Scenario: Cardless payment method reveals the row

- **WHEN** the selected payment method is flagged cardless
- **THEN** the order edit form displays the reconciliation status row below the payment method row

#### Scenario: Bank-transfer payment method reveals the row

- **WHEN** the selected payment method is flagged bank transfer
- **THEN** the order edit form displays the reconciliation status row below the payment method row

#### Scenario: Other payment method hides the row

- **WHEN** the selected payment method is neither cardless nor bank transfer
- **THEN** the order edit form does not display the reconciliation status row


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
### Requirement: Selecting and adding a reconciliation status during order editing

The reconciliation status row SHALL open a picker listing the reconciliation status master data and SHALL let the user select one. The picker SHALL provide an add control that presents a medium-height sheet collecting a single name. Confirming the add SHALL add the name to the reconciliation status master data and apply it to the current order. When the master data is empty, the picker SHALL show the configured empty state and the row SHALL show a placeholder rather than a value.

#### Scenario: Select an existing reconciliation status

- **WHEN** the user opens the picker and taps a reconciliation status row
- **THEN** that status becomes the order's draft reconciliation status and the picker dismisses

#### Scenario: Add a reconciliation status via the medium sheet

- **WHEN** the user taps the add control, enters a non-empty trimmed name in the medium-height sheet, and confirms
- **THEN** the name is added to the reconciliation status master data and applied to the current order

#### Scenario: Empty master data shows an empty state

- **WHEN** the picker is presented and no reconciliation statuses exist
- **THEN** the picker shows the configured empty title and description and the row shows a placeholder


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
### Requirement: Reconciliation status persistence and clearing rule

An order's reconciliation status SHALL be persisted only while its payment method is classified as cardless or bank transfer. When the order's payment method changes to one that is neither, the stored reconciliation status SHALL be cleared, so that an order does not retain a status that no longer applies to it.

The same clearing SHALL apply when the payment method itself stops being classified as cardless or bank transfer, rather than only when the order's payment method changes. A flag corrected on the lookup governs every order using that payment method, so leaving those orders with a reconciliation status that no longer applies would preserve exactly the stale state the correction was meant to remove.

#### Scenario: Changing an order to an unclassified payment method clears the status

- **WHEN** an order carrying a reconciliation status is edited to use a payment method that is neither cardless nor bank transfer, and saved
- **THEN** the stored reconciliation status is cleared

#### Scenario: Clearing the flags on the lookup clears the status on existing orders

- **WHEN** a payment method's cardless and bank-transfer flags are both cleared on the lookup and the recomputation is confirmed
- **THEN** every order using that payment method has its reconciliation status cleared

#### Scenario: A still-classified payment method keeps the status

- **WHEN** a payment method's cardless flag is cleared but it remains flagged as bank transfer
- **THEN** orders using it keep their reconciliation status, because the status still applies

<!-- @trace
source: payment-flag-retroactive-correction
updated: 2026-08-22
code:
  - apps/ios/BuyLedger/Core/Dependencies/ReconciliationStatusRepository.swift
  - apps/ios/BuyLedgerUITests/Screens/PhotoViewerScreen.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementView.swift
  - apps/ios/BuyLedgerTests/OrderMergeTests.swift
  - apps/ios/BuyLedger/App/AppLaunchConfigurator.swift
  - apps/ios/BuyLedgerUITests/Screens/SettingsScreen.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/LedgerOrderItem.generated.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/ViewModifiers/BLTypographyModifier.swift
  - apps/ios/BuyLedgerTests/BLPhotoViewerTests.swift
  - apps/ios/BuyLedgerTests/NumericInputGroupingScanTests.swift
  - apps/ios/BuyLedger/Core/Persistence/OrderRecord.swift
  - apps/ios/BuyLedgerUITests/Screens/OrderDetailScreen.swift
  - apps/ios/BuyLedgerTests/AccessibilityConventionScanTests.swift
  - shared/data-model/fixtures/expected/swift/SampleStatus.generated.swift
  - shared/data-model/fixtures/expected/typescript/SampleSequence.ts
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewMultiSelectBaseline.1.png
  - apps/ios/BuyLedger/Core/Domain/Generated/FxRateSnapshot.generated.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupCatalog.swift
  - apps/ios/BuyLedger/Resources/Localizable.xcstrings
  - apps/ios/BuyLedger/Core/Domain/Generated/CurrencyCode.generated.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestDependencyOverrides.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLFormatters.swift
  - apps/ios/BuyLedger/Core/Domain/FxRateSnapshot.swift
  - apps/ios/BuyLedger/Features/Settings/AppLanguage.swift
  - apps/ios/BuyLedger/Features/App/SidebarBadgeCounts.swift
  - apps/ios/BuyLedgerUITests/Screens/OptionPickerScreen.swift
  - apps/ios/BuyLedgerTests/InsightsFeatureTests.swift
  - apps/ios/BuyLedger/Core/Persistence/ReconciliationStatusPersistence.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardView.swift
  - apps/ios/BuyLedgerUITests/Support/MenuInteraction.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderDetailView.swift
  - apps/ios/BuyLedgerUITests/Tests/Campaigns/CampaignCrudTests.swift
  - shared/data-model/fixtures/expected/kotlin/SampleProfile.kt
  - shared/data-model/fixtures/expected/typescript/SampleGrade.ts
  - apps/ios/BuyLedgerUITests/Support/AlertInteraction.swift
  - apps/ios/BuyLedger/Core/Domain/FxRates.swift
  - apps/ios/BuyLedger/Core/Domain/Campaign+Samples.swift
  - apps/ios/BuyLedger.xcodeproj/project.pbxproj
  - apps/ios/BuyLedgerUITests/Screens/FxScreen.swift
  - apps/ios/BuyLedger/Core/Dependencies/CategoryRepository.swift
  - apps/ios/BuyLedgerTests/OrderCalculationTests.swift
  - shared/data-model/fixtures/expected/swift/SampleQuote.generated.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewBaseline.1.png
  - apps/ios/BuyLedger/Core/Persistence/CampaignRecord.swift
  - apps/ios/BuyLedger/Features/AISummary/AISummaryFeature.swift
  - apps/ios/BuyLedgerTests/DesignSystemSourceScanTests.swift
  - shared/data-model/fixtures/expected/typescript/SamplePreference.ts
  - apps/ios/BuyLedger/Core/Domain/Generated/CampaignStatus.generated.swift
  - shared/data-model/schema/OrderStatus.yaml
  - apps/ios/BuyLedgerTests/TestSuiteIntegrityTests.swift
  - apps/ios/BuyLedger/Core/Persistence/CategoryPersistence.swift
  - apps/ios/BuyLedger/Shared/Media/PhotoDataProcessor.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersBatchOperations.swift
  - apps/ios/BuyLedger/Core/Persistence/OrderSourcePersistence.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestConfiguration.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLHeatmapDepth.swift
  - apps/ios/BuyLedger/Features/Customers/CustomersFeature.swift
  - apps/ios/BuyLedger/Core/Persistence/PersistenceStoreQuarantineClient.swift
  - apps/ios/BuyLedger/Features/App/RootTabLayout.swift
  - apps/ios/BuyLedger/Features/Orders/OrderEditView.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersFilterOperations.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests.swift
  - apps/ios/BuyLedgerTests/FxFeatureTests.swift
  - shared/data-model/fixtures/expected/kotlin/SampleQuote.kt
  - apps/ios/BuyLedgerTests/AppScenePhaseCoordinatorTests.swift
  - apps/ios/BuyLedger/Features/App/RootFeature.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Buttons/BLButtonStyle.swift
  - apps/ios/BuyLedgerTests/CalendarReminderTests.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignListView.swift
  - apps/ios/BuyLedgerUITests/Screens/AppLockScreen.swift
  - apps/ios/BuyLedger/Features/FX/FxView.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLSparkline.swift
  - shared/data-model/fixtures/expected/swift/SampleReceipt.generated.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestHarness.swift
  - apps/ios/BuyLedgerTests/CampaignReminderFailureTests.swift
  - shared/data-model/README.md
  - apps/ios/BuyLedger/Core/Dependencies/OrderRepository.swift
  - apps/ios/BuyLedger/Core/Persistence/BuyLedgerSchema.swift
  - apps/ios/BuyLedgerTests/AISummaryFeatureTests.swift
  - apps/ios/BuyLedgerTests/OrderStatusTests.swift
  - apps/ios/BuyLedgerTests/APIErrorMappingTests.swift
  - apps/ios/BuyLedgerTests/PersistenceRecoveryTests.swift
  - apps/ios/BuyLedgerTests/BLUITestConfigurationTests.swift
  - apps/ios/BuyLedger/Core/Domain/OrderSummary.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLTypography.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLMetrics.swift
  - apps/ios/BuyLedger/Core/Networking/ExchangeRateClient.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsStorage.swift
  - apps/ios/BuyLedger/Features/Orders/OrderEditFeature.swift
  - apps/ios/BuyLedgerTests/OrderEditFeatureTests.swift
  - shared/data-model/schema/CampaignStatus.yaml
  - apps/ios/BuyLedger/Core/Domain/Generated/PaymentReceiptStatus.generated.swift
  - apps/ios/BuyLedgerTests/InsightsStatsTests.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignEditFeature.swift
  - apps/ios/BuyLedgerTests/CampaignEditFeatureTests.swift
  - apps/ios/BuyLedger/Core/Persistence/PersistenceContainer.swift
  - apps/ios/BuyLedgerTests/BiometricAuthClientTests.swift
  - apps/ios/BuyLedger/Core/Dependencies/CampaignRepository.swift
  - apps/ios/BuyLedger/Features/App/RootView.swift
  - apps/ios/BuyLedger/Resources/PrivacyInfo.xcprivacy
  - apps/ios/BuyLedger/Core/Persistence/NameLookupRecord.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrdersListTests.swift
  - apps/ios/BuyLedgerTests/OrdersBatchOperationsTests.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsDateRange.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/States/DelayedProgressView.swift
  - apps/ios/BuyLedger/Core/Testing/BLUITestSeedData.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/States/BLDelayedProgressView.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLPalette.swift
  - apps/ios/BuyLedgerTests/LookupManagementFeatureTests.swift
  - apps/ios/CLAUDE.md
  - apps/ios/BuyLedgerUITests/KeyboardDismissTests.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsFeature.swift
  - apps/ios/BuyLedger/Core/Persistence/CampaignReminderPersistence.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsView.swift
  - apps/ios/BuyLedgerUITests/Screens/OrderEditScreen.swift
  - apps/ios/BuyLedger/Core/Persistence/CurrencyMetadataRecord.swift
  - apps/ios/BuyLedger/Core/Domain/OrderMerge.swift
  - apps/ios/BuyLedgerUITests/Support/BLUITestCase.swift
  - apps/ios/BuyLedger/Core/Persistence/CampaignReminderRecord.swift
  - apps/ios/BuyLedgerUITests/Screens/CampaignsScreen.swift
  - apps/ios/BuyLedgerUITests/Screens/CustomersScreen.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Badges/BLBadge.swift
  - apps/ios/BuyLedger/Core/Dependencies/CurrencyMetadataRepository.swift
  - shared/data-model/fixtures/expected/typescript/SampleReceipt.ts
  - apps/ios/BuyLedger/Features/Campaigns/CampaignFeature.swift
  - apps/ios/BuyLedger/Core/Persistence/PersistenceStoreQuarantine.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsFeature.swift
  - apps/ios/BuyLedger/Core/Persistence/ReconciliationStatusRecord.swift
  - apps/ios/BuyLedger/Core/Networking/APIError.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestSeedProfile.swift
  - apps/ios/BuyLedger/Core/Sync/SyncMeta.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignEditView.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OptionPickerSheet.swift
  - apps/ios/BuyLedger/Features/Orders/OrderMergeFeature.swift
  - apps/ios/BuyLedgerTests/SettingsFeatureTests.swift
  - apps/ios/BuyLedgerTests/CampaignSummaryTests.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderSelectableRow.swift
  - apps/ios/BuyLedger/Core/Domain/CurrencyCode.swift
  - apps/ios/BuyLedger/Core/Domain/LedgerOrder.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Chips/BLFilterChip.swift
  - apps/ios/BuyLedger/Features/Orders/Components/MergePhotoPickerSheet.swift
  - apps/ios/BuyLedger/Core/Testing/BLUITestDependencyOverrides.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/ViewModifiers/BLHeroCardBackground.swift
  - AGENTS.md
  - apps/ios/BuyLedgerTests/LookupCatalogTests.swift
  - apps/ios/BuyLedger/Features/App/RootTab.swift
  - apps/ios/BuyLedgerUITests/Support/ValueParsing.swift
  - apps/ios/BuyLedgerTests/QuoteFeatureTests.swift
  - apps/ios/BuyLedgerTests/PersistenceErrorContractTests.swift
  - apps/ios/BuyLedger/Features/Customers/CustomersView.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupKind.swift
  - apps/ios/BuyLedger/Features/Orders/OrderDatePeriod.swift
  - apps/ios/BuyLedgerTests/SnapshotTests.swift
  - apps/ios/BuyLedgerUITests/Support/SheetInteraction.swift
  - apps/ios/BuyLedger.xctestplan
  - apps/ios/BuyLedger/Core/Dependencies/PhotoClient.swift
  - apps/ios/BuyLedger/Core/Domain/Campaign.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrdersToolbarContent.swift
  - apps/ios/BuyLedgerTests/PersistenceFailureFeatureTests.swift
  - shared/data-model/fixtures/expected/swift/SampleProfile.generated.swift
  - apps/ios/BuyLedgerUITests/Tests/Performance/LaunchPerformanceTests.swift
  - apps/ios/BuyLedger/App/AppDelegate.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderDetailTests.swift
  - apps/ios/BuyLedger/Features/Quote/QuoteFeature.swift
  - shared/data-model/fixtures/expected/swift/SampleSequence.generated.swift
  - apps/ios/BuyLedgerTests/CampaignFeatureTests.swift
  - apps/ios/BuyLedgerTests/BLAccessibilityIDTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/ViewModifiers/BLCardShadow.swift
  - apps/ios/BuyLedger/Core/Persistence/PersistenceError.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/dashboardViewBaseline.1.png
  - apps/ios/BuyLedger/Core/Domain/Generated/LedgerOrder.generated.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift
  - apps/ios/BuyLedger/Features/Quote/QuoteView.swift
  - apps/ios/BuyLedgerTests/DashboardStatsTests.swift
  - apps/ios/BuyLedger/Features/Customers/CustomerRankBadgeStyle.swift
  - apps/ios/BuyLedgerUITests/Screens/CampaignDetailScreen.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/PaymentMethodInfo.generated.swift
  - apps/ios/BuyLedgerUITests/Screens/OrdersScreen.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersCompactView.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersFeature.swift
  - shared/data-model/fixtures/expected/kotlin/SamplePreference.kt
  - shared/data-model/schema/LedgerOrder.yaml
  - apps/ios/BuyLedger/Core/Persistence/PaymentMethodPersistence.swift
  - apps/ios/BuyLedgerTests/InsightsAttributionTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoThumbnail.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewBaseline.1.png
  - apps/ios/BuyLedgerUITests/Tests/Campaigns/CampaignListTests.swift
  - apps/ios/BuyLedger/Core/Domain/LedgerOrder+Samples.swift
  - apps/ios/BuyLedger/Resources/InfoPlist.xcstrings
  - apps/ios/BuyLedger/Features/AISummary/OllamaClient.swift
  - apps/ios/BuyLedgerUITests/Support/Scrolling.swift
  - apps/ios/BuyLedger/Features/Orders/Components/PaymentMethodEditorSheet.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignDetailView.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupNameEditorSheet.swift
  - apps/ios/BuyLedger/Features/App/RootSidebarLayout.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLBarChart.swift
  - apps/ios/BuyLedger/Core/Networking/URLRequestBuilder.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardFeature.swift
  - apps/ios/BuyLedgerTests/ContrastComplianceTests.swift
  - apps/ios/BuyLedgerTests/OrderMergeFeatureTests.swift
  - apps/ios/BuyLedger/Core/Persistence/CurrencyMetadataPersistence.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Status/BLStatusPill.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Pickers/OptionPickerSheet.swift
  - apps/ios/BuyLedger/Resources/Info.plist
  - apps/ios/BuyLedger.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
  - shared/data-model/schema/FxRateSnapshot.yaml
  - apps/ios/BuyLedger/Core/Dependencies/NameLookupOperations.swift
  - apps/ios/BuyLedger/Features/App/AppLockFeature.swift
  - apps/ios/BuyLedger/Features/Orders/LedgerOrder+OrderMutation.swift
  - shared/data-model/schema/CustomerTier.yaml
  - apps/ios/BuyLedger/Features/More/MoreView.swift
  - apps/ios/BuyLedgerUITests/Screens/AISummaryScreen.swift
  - shared/data-model/fixtures/schema/sample-trait-matrix.yaml
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewMergeContextBaseline.1.png
  - apps/ios/BuyLedger/Core/Dependencies/OrderSourceRepository.swift
  - apps/ios/BuyLedgerUITests/Support/TextInput.swift
  - shared/data-model/schema/PaymentMethodInfo.yaml
  - .github/workflows/ci.yml
  - apps/ios/BuyLedgerUITests/Screens/QuoteScreen.swift
  - apps/ios/BuyLedger/Features/FX/ExchangeRateClient.swift
  - apps/ios/BuyLedger/Features/App/AppScenePhaseCoordinator.swift
  - apps/ios/BuyLedger/App/BuyLedgerApp.swift
  - README.md
  - apps/ios/BuyLedger/Core/Dependencies/PaymentMethodRepository.swift
  - apps/ios/BuyLedger/Features/FX/FxRates.swift
  - apps/ios/BuyLedger/Core/Persistence/NameLookupPersistence.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsSnapshot.swift
  - apps/ios/BuyLedger/Core/Dependencies/OpenSettingsClient.swift
  - apps/ios/BuyLedgerTests/AppConfigurationTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersRegularViewMultiSelectBaseline.1.png
  - shared/data-model/schema/LedgerCustomer.yaml
  - apps/ios/BuyLedger/Shared/Extensions/Image+Extensions.swift
  - apps/ios/BuyLedgerTests/OrdersLoadStateTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Cards/BLCard.swift
  - apps/ios/BuyLedgerUITests/Screens/Screen.swift
  - shared/data-model/schema/Campaign.yaml
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Tags/BLTagPill.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewLongContentBaseline.1.png
  - apps/ios/BuyLedgerUITests/Tests/Customers/CustomersTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderMergeTests.swift
  - shared/data-model/fixtures/expected/kotlin/SampleGrade.kt
  - shared/data-model/schema/Money.yaml
  - apps/ios/BuyLedger/Core/Testing/BLUITestSeedProfile.swift
  - apps/ios/BuyLedger/Core/Persistence/PaymentMethodRecord.swift
  - apps/ios/BuyLedger/Features/App/AppLockView.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsView.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFormatters.swift
  - apps/ios/BuyLedgerAccessibilityIDs/BLAccessibilityID.swift
  - apps/ios/BuyLedger/Features/AISummary/OllamaDTO.swift
  - apps/ios/BuyLedger/Features/Orders/OrderDetailPath.swift
  - apps/ios/BuyLedgerTests/ProjectionWriteBoundaryTests.swift
  - apps/ios/BuyLedgerUITests-Performance.xctestplan
  - shared/data-model/fixtures/expected/typescript/SampleStatus.ts
  - apps/ios/BuyLedgerTests/OrderEditFocusTests.swift
  - apps/ios/BuyLedger/Core/Persistence/OrderSourceRecord.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestSeedData.swift
  - apps/ios/BuyLedger/Core/Persistence/CategoryRecord.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsStats.swift
  - apps/ios/BuyLedgerTests/OrderDraftTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/quoteViewBaseline.1.png
  - apps/ios/BuyLedgerTests/CampaignIntegrationTests.swift
  - apps/ios/BuyLedgerTests/NameLookupPersistenceTests.swift
  - apps/ios/BuyLedger/Features/Orders/OrderDraft.swift
  - apps/ios/BuyLedger/Core/Dependencies/CalendarReminderClient.swift
  - apps/ios/BuyLedgerTests/ColorContrastTests.swift
  - apps/ios/BuyLedgerTests/SchemaMigrationTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoViewer.swift
  - apps/ios/BuyLedger/Features/Orders/OrderStatusFilter.swift
  - apps/ios/BuyLedger/Shared/Extensions/Bundle+Extensions.swift
  - apps/ios/BuyLedgerTests/OrderPersistenceTests.swift
  - apps/ios/BuyLedgerTests/PrivacyManifestTests.swift
  - apps/ios/BuyLedger/Features/FX/FxFeature.swift
  - apps/ios/BuyLedgerUITests/Screens/InsightsScreen.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/CustomerTier.generated.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewLongIdentifierBaseline.1.png
  - apps/ios/BuyLedger/Features/Orders/Components/OrderStatus+Presentation.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderEditDirtyTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLDonutSegment.swift
  - apps/ios/BuyLedgerTests/DashboardFeatureTests.swift
  - apps/ios/BuyLedger/Features/App/PersistenceFailureView.swift
  - shared/data-model/fixtures/schema/sample-enums.yaml
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLDonutChart.swift
  - shared/data-model/fixtures/expected/typescript/SampleProfile.ts
  - apps/ios/BuyLedger/Core/Networking/ExchangeRateDTO.swift
  - apps/ios/BuyLedger/Shared/Extensions/Color+Extensions.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Forms/PaymentMethodEditorSheet.swift
  - shared/data-model/fixtures/schema/sample-orders.yaml
  - apps/ios/BuyLedger/Features/Orders/OrdersFeature+StateQuery.swift
  - apps/ios/BuyLedger/Core/Networking/AppConfiguration.swift
  - shared/data-model/generator/src/datamodel-gen.ts
  - apps/ios/BuyLedgerUITests/Support/LaunchOptions.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Progress/BLProgressBar.swift
  - apps/ios/BuyLedgerUITests/Support/Assertions.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLBarChartValue.swift
  - apps/ios/BuyLedger/Core/Dependencies/CampaignReminderRepository.swift
  - shared/data-model/fixtures/expected/swift/SamplePreference.generated.swift
  - apps/ios/BuyLedger/Core/Testing/BLUITestConfiguration.swift
  - apps/ios/BuyLedgerTests/OllamaClientTests.swift
  - apps/ios/BuyLedgerTests/OrdersSearchCancellationTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/persistenceFailureViewBaseline.1.png
  - apps/ios/BuyLedger/Core/Dependencies/TelemetryClient.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/LedgerCustomer.generated.swift
  - apps/ios/BuyLedgerUITests/Tests/Tools/FxTests.swift
  - apps/ios/BuyLedgerTests/BLFormattersTests.swift
  - apps/ios/BuyLedger/Core/Domain/LedgerOrderItem.swift
  - apps/ios/BuyLedgerUITests/PhotoViewerPagingTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Insights/InsightsTests.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementDestination.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderCreateTests.swift
  - apps/ios/BuyLedgerTests/AppLockFeatureTests.swift
  - apps/ios/README.md
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLStatusHue.swift
  - apps/ios/BuyLedgerTests/ExchangeRateClientTests.swift
  - apps/ios/BuyLedger/Features/FX/ExchangeRateDTO.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/AISummaryTests.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardStats.swift
  - apps/ios/BuyLedgerUITests/Tests/Smoke/HarnessSelfCheckTests.swift
  - shared/data-model/schema/PaymentReceiptStatus.yaml
  - apps/ios/BuyLedgerTests/PaymentMethodPersistenceTests.swift
  - apps/ios/BuyLedger/Core/Domain/OrderStatus.swift
  - apps/ios/BuyLedgerUITests/Screens/DashboardScreen.swift
  - apps/ios/BuyLedgerTests/CustomersFeatureTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/quoteViewRateUnavailable.1.png
  - apps/ios/BuyLedgerUITests/Support/AppNavigator.swift
  - apps/ios/BuyLedger/Core/Testing/BLUITestHarness.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Avatar/BLAvatar.swift
  - apps/ios/BuyLedger/Core/Persistence/OrderPersistence.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/Campaign.generated.swift
  - apps/ios/BuyLedgerUITests/Tests/Tools/QuoteTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Campaigns/CampaignDetailTests.swift
  - apps/ios/BuyLedgerTests/OrdersFilterOperationsTests.swift
  - apps/ios/BuyLedger/Shared/Extensions/Decimal+Extensions.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/States/BLLoadFailureView.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderMergeCandidateSheet.swift
  - shared/data-model/fixtures/expected/kotlin/SampleSequence.kt
  - apps/ios/BuyLedger/Resources/GoogleService-Info.example.plist
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFilterSheet.swift
  - apps/ios/BuyLedgerTests/CampaignPersistenceTests.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignSummary.swift
  - apps/ios/BuyLedgerUITests/Screens/CampaignEditScreen.swift
  - apps/ios/BuyLedger/Shared/Localization/AppLanguage.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersView.swift
  - apps/ios/BuyLedger.xcodeproj/xcshareddata/xcschemes/BuyLedger.xcscheme
  - apps/ios/BuyLedgerTests/CurrencyMetadataCacheTests.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/Money.generated.swift
  - CLAUDE.md
  - shared/data-model/fixtures/expected/typescript/SampleQuote.ts
  - apps/ios/BuyLedger/Core/Domain/Generated/OrderStatus.generated.swift
  - shared/data-model/schema/CurrencyCode.yaml
  - apps/ios/BuyLedgerTests/PhotoDataProcessorTests.swift
  - shared/data-model/schema/LedgerOrderItem.yaml
  - apps/ios/BuyLedgerUITests/Tests/Smoke/AppLockTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Smoke/LaunchSmokeTests.swift
  - apps/ios/BuyLedger/Features/Settings/AISummaryModelCatalog.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLTone.swift
  - shared/data-model/fixtures/expected/kotlin/SampleStatus.kt
  - apps/ios/BuyLedger/Features/Orders/OrdersMergeFlowOperations.swift
  - apps/ios/BuyLedger/Core/Networking/HTTPMethod.swift
  - apps/ios/BuyLedgerTests/OrdersFeaturePerformanceTests.swift
  - apps/ios/BuyLedgerUITests/Support/Diagnostics.swift
  - apps/ios/BuyLedgerTests/LayerBoundaryTests.swift
  - apps/ios/BuyLedgerUITests/Support/Waiting.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignFormatters.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderRowView.swift
  - shared/data-model/fixtures/expected/swift/SampleGrade.generated.swift
  - apps/ios/BuyLedger/Core/Networking/HTTPClient.swift
  - apps/ios/BuyLedger/Core/Persistence/CampaignPersistence.swift
  - apps/ios/BuyLedgerTests/LocalizationCatalogTests.swift
  - apps/ios/BuyLedgerTests/ColorContrast.swift
  - apps/ios/BuyLedger/Core/Sync/SyncQueueItem.swift
  - apps/ios/BuyLedgerUITests.xctestplan
  - apps/ios/BuyLedgerUITests/Screens/RootNavigationScreen.swift
  - apps/ios/BuyLedger/Features/App/PersistenceFailureFeature.swift
  - apps/ios/BuyLedgerTests/OrdersFeatureTests.swift
  - apps/ios/BuyLedgerTests/TestDependencies.swift
  - apps/ios/BuyLedgerUITests/Screens/MergeFlowScreen.swift
  - apps/ios/BuyLedger/Core/Dependencies/BiometricAuthClient.swift
  - apps/ios/BuyLedger/Features/AISummary/AISummaryView.swift
  - apps/ios/BuyLedger/Core/Diagnostics/CrashDiagnosticsClient.swift
  - apps/ios/BuyLedgerTests/HTTPClientTests.swift
  - shared/data-model/fixtures/expected/kotlin/SampleReceipt.kt
tests:
  - shared/data-model/generator/test/datamodel-gen.test.ts
-->