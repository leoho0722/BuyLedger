# app-settings Specification

## Purpose

Defines how the app's persisted preferences (interface language, default order currency, monthly net profit goal, AI summary toggle and model) are read, defaulted, made available at launch, and written. App lock behavior is specified separately in app-lock and is not covered here.

## Requirements

### Requirement: A setting that was never written reads as its documented default

When a preference has never been written, reading it SHALL yield the default documented for that preference, not the storage layer's zero value. A value the user has written SHALL be read back as written, including a value that equals the storage layer's zero value.

#### Scenario: A fresh install reads the documented monthly goal

- **WHEN** the monthly net profit goal has never been written and the settings are read
- **THEN** the goal is the documented default, so the dashboard shows its goal progress

##### Example: monthly goal reads

| Stored monthly goal | Read value | Notes |
| ------------------- | ---------- | ----- |
| never written | 80,000 | documented default |
| 0 | 0 | user chose no goal |
| 120,000 | 120,000 | user value |

#### Scenario: A deliberately cleared goal stays cleared

- **WHEN** the user has set the monthly net profit goal to zero and the settings are read
- **THEN** the goal is zero, and the dashboard shows no goal progress


<!-- @trace
source: small-features-style-compliance
updated: 2026-09-24
code:
  - apps/ios/BuyLedgerTests/BLFormattersTests.swift
  - apps/ios/BuyLedger/Features/Quote/Components/QuoteInputsCard.swift
  - apps/ios/BuyLedger/Features/FX/Components/FxStatusBanner.swift
  - apps/ios/BuyLedger/Features/Orders/OrderDateSection.swift
  - apps/ios/BuyLedger/Features/Quote/QuoteView.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/fxViewBaseline.1.png
  - apps/ios/BuyLedger/Features/FX/Components/FxRatesList.swift
  - apps/ios/BuyLedger/Features/AISummary/OllamaDTO.swift
  - apps/ios/BuyLedgerTests/ActionGroupingScanTests+Scanner.swift
  - apps/ios/BuyLedgerTests/ActionGroupingScanTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLFormatters.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsSnapshot.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsStore.swift
  - apps/ios/BuyLedgerTests/SnapshotTests.swift
  - apps/ios/BuyLedger/Core/Networking/OllamaChatRequest.swift
  - apps/ios/BuyLedgerTests/SettingsFeatureTests.swift
  - apps/ios/BuyLedger/Features/Customers/CustomersView.swift
  - apps/ios/BuyLedger/App/BuyLedgerApp.swift
  - apps/ios/BuyLedger/Features/Quote/QuoteRateFeature.swift
  - apps/ios/BuyLedgerTests/FxFeatureTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/fxViewRateFailureBaseline.1.png
  - apps/ios/BuyLedger/Shared/Extensions/Bundle+Extensions.swift
  - apps/ios/BuyLedger/Features/Customers/CustomerRankBadgeStyle.swift
  - apps/ios/BuyLedgerTests/ActionGroupingScanTests+Scenarios.swift
  - apps/ios/BuyLedgerTests/AISummaryFeatureTests.swift
  - apps/ios/BuyLedger/Core/Networking/OllamaClient.swift
  - apps/ios/BuyLedger/Features/Customers/Components/CustomerTopCard.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsFeature.swift
  - apps/ios/BuyLedgerTests/LedgerOrder+Fixture.swift
  - apps/ios/BuyLedger/Features/Customers/CustomerRow.swift
  - apps/ios/CLAUDE.md
  - apps/ios/BuyLedger/Features/Settings/AISummaryModelCatalog.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsView.swift
  - apps/ios/BuyLedger/Features/FX/FxView.swift
  - apps/ios/BuyLedger/Features/Customers/CustomersFeature.swift
  - apps/ios/BuyLedgerTests/SettingsStoreTests.swift
  - apps/ios/BuyLedger/Features/FX/FxFormatters.swift
  - apps/ios/BuyLedger/Features/Quote/Components/QuoteBreakdownCard.swift
  - apps/ios/BuyLedger/Features/AISummary/AISummaryView.swift
  - apps/ios/BuyLedger/Features/AISummary/AISummaryFeature.swift
  - apps/ios/BuyLedgerTests/FxRateSnapshotTests.swift
  - apps/ios/BuyLedger/Features/App/RootFeature.swift
  - apps/ios/BuyLedger/Features/More/MoreView.swift
  - apps/ios/BuyLedgerTests/CustomersFeatureTests.swift
  - apps/ios/BuyLedgerTests/OllamaClientTests.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests.swift
  - apps/ios/BuyLedgerTests/AppLanguageTests.swift
  - apps/ios/BuyLedger/Features/Quote/Components/QuoteStatusBanner.swift
  - apps/ios/README.md
  - apps/ios/BuyLedgerTests/CustomerRowTests.swift
  - apps/ios/BuyLedger/Core/Networking/OllamaChatResponse.swift
  - apps/ios/BuyLedger/Features/Quote/QuoteFeature.swift
  - apps/ios/BuyLedger/Core/Domain/FxRateSnapshot.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersFeature+StateQuery.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFormatters.swift
  - apps/ios/BuyLedger/Features/FX/FxFeature.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsStorage.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestDependencyOverrides.swift
  - apps/ios/BuyLedger/Features/Customers/Components/CustomerListRow.swift
  - apps/ios/BuyLedger.xcodeproj/project.pbxproj
  - apps/ios/BuyLedger/Features/Orders/OrdersFeature.swift
  - apps/ios/BuyLedgerTests/QuoteFeatureTests.swift
  - apps/ios/BuyLedger/Features/AISummary/OllamaClient.swift
  - apps/ios/BuyLedgerTests/OrdersFeatureTests.swift
-->

---
### Requirement: Stored preference keys survive code renames

The key under which each preference is stored SHALL remain unchanged when the code identifiers that hold the preference are renamed. A value written by an earlier version SHALL be read by a later version without migration.

#### Scenario: Values written under the existing keys are read after a rename

- **WHEN** every preference is written under the keys used before the identifier renames and the settings are read by the renamed code
- **THEN** every preference reads back the written value

##### Example: the stored keys that stay fixed

| Preference | Stored key |
| ---------- | ---------- |
| interface language | `settings.language` |
| default order currency | `settings.defaultCurrency` |
| monthly net profit goal | `settings.monthlyProfitGoalTwd` |
| AI summary toggle | `settings.useAiSummary` |
| AI summary model | `settings.aiSummaryModel` |
| app lock toggle | `settings.isBiometricUnlockEnabled` |


<!-- @trace
source: small-features-style-compliance
updated: 2026-09-24
code:
  - apps/ios/BuyLedgerTests/BLFormattersTests.swift
  - apps/ios/BuyLedger/Features/Quote/Components/QuoteInputsCard.swift
  - apps/ios/BuyLedger/Features/FX/Components/FxStatusBanner.swift
  - apps/ios/BuyLedger/Features/Orders/OrderDateSection.swift
  - apps/ios/BuyLedger/Features/Quote/QuoteView.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/fxViewBaseline.1.png
  - apps/ios/BuyLedger/Features/FX/Components/FxRatesList.swift
  - apps/ios/BuyLedger/Features/AISummary/OllamaDTO.swift
  - apps/ios/BuyLedgerTests/ActionGroupingScanTests+Scanner.swift
  - apps/ios/BuyLedgerTests/ActionGroupingScanTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLFormatters.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsSnapshot.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsStore.swift
  - apps/ios/BuyLedgerTests/SnapshotTests.swift
  - apps/ios/BuyLedger/Core/Networking/OllamaChatRequest.swift
  - apps/ios/BuyLedgerTests/SettingsFeatureTests.swift
  - apps/ios/BuyLedger/Features/Customers/CustomersView.swift
  - apps/ios/BuyLedger/App/BuyLedgerApp.swift
  - apps/ios/BuyLedger/Features/Quote/QuoteRateFeature.swift
  - apps/ios/BuyLedgerTests/FxFeatureTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/fxViewRateFailureBaseline.1.png
  - apps/ios/BuyLedger/Shared/Extensions/Bundle+Extensions.swift
  - apps/ios/BuyLedger/Features/Customers/CustomerRankBadgeStyle.swift
  - apps/ios/BuyLedgerTests/ActionGroupingScanTests+Scenarios.swift
  - apps/ios/BuyLedgerTests/AISummaryFeatureTests.swift
  - apps/ios/BuyLedger/Core/Networking/OllamaClient.swift
  - apps/ios/BuyLedger/Features/Customers/Components/CustomerTopCard.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsFeature.swift
  - apps/ios/BuyLedgerTests/LedgerOrder+Fixture.swift
  - apps/ios/BuyLedger/Features/Customers/CustomerRow.swift
  - apps/ios/CLAUDE.md
  - apps/ios/BuyLedger/Features/Settings/AISummaryModelCatalog.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsView.swift
  - apps/ios/BuyLedger/Features/FX/FxView.swift
  - apps/ios/BuyLedger/Features/Customers/CustomersFeature.swift
  - apps/ios/BuyLedgerTests/SettingsStoreTests.swift
  - apps/ios/BuyLedger/Features/FX/FxFormatters.swift
  - apps/ios/BuyLedger/Features/Quote/Components/QuoteBreakdownCard.swift
  - apps/ios/BuyLedger/Features/AISummary/AISummaryView.swift
  - apps/ios/BuyLedger/Features/AISummary/AISummaryFeature.swift
  - apps/ios/BuyLedgerTests/FxRateSnapshotTests.swift
  - apps/ios/BuyLedger/Features/App/RootFeature.swift
  - apps/ios/BuyLedger/Features/More/MoreView.swift
  - apps/ios/BuyLedgerTests/CustomersFeatureTests.swift
  - apps/ios/BuyLedgerTests/OllamaClientTests.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests.swift
  - apps/ios/BuyLedgerTests/AppLanguageTests.swift
  - apps/ios/BuyLedger/Features/Quote/Components/QuoteStatusBanner.swift
  - apps/ios/README.md
  - apps/ios/BuyLedgerTests/CustomerRowTests.swift
  - apps/ios/BuyLedger/Core/Networking/OllamaChatResponse.swift
  - apps/ios/BuyLedger/Features/Quote/QuoteFeature.swift
  - apps/ios/BuyLedger/Core/Domain/FxRateSnapshot.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersFeature+StateQuery.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFormatters.swift
  - apps/ios/BuyLedger/Features/FX/FxFeature.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsStorage.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestDependencyOverrides.swift
  - apps/ios/BuyLedger/Features/Customers/Components/CustomerListRow.swift
  - apps/ios/BuyLedger.xcodeproj/project.pbxproj
  - apps/ios/BuyLedger/Features/Orders/OrdersFeature.swift
  - apps/ios/BuyLedgerTests/QuoteFeatureTests.swift
  - apps/ios/BuyLedger/Features/AISummary/OllamaClient.swift
  - apps/ios/BuyLedgerTests/OrdersFeatureTests.swift
-->

---
### Requirement: Settings are available from the first frame

The persisted preferences SHALL be read once at launch and held by the root state from launch, so that the first rendered frame already reflects them, including the overview's monthly goal. They SHALL be supplied to the settings state when the settings screen is pushed rather than loaded by an action afterwards. The settings feature SHALL be the only writer of the persisted preferences, and after each write it SHALL report the written preferences so that the root state's copy and every value derived from it stay current; refreshing another screen SHALL NOT re-read them from storage.

#### Scenario: The first frame uses the persisted language

- **WHEN** the app launches with English stored as the interface language
- **THEN** the first frame is rendered in English, without first rendering the default language

##### Example: state at construction

- **GIVEN** stored settings of English, USD, and a monthly goal of 120,000
- **WHEN** the root state is constructed at launch, before any action is processed
- **THEN** the root state's preferences already hold English, USD, and 120,000, and a settings state built from them when the settings screen is pushed holds the same values

#### Scenario: The overview goal uses the stored goal from the first frame

- **WHEN** the app launches with a stored monthly net profit goal that differs from the documented default
- **THEN** the overview's goal progress uses the stored goal from the first frame, without waiting for the settings screen to be opened

##### Example: stored goal of 50,000

- **GIVEN** the stored monthly net profit goal is 50,000
- **WHEN** the root state is constructed at launch, before any action is processed
- **THEN** the overview state's monthly goal is 50,000, not the default 80,000

#### Scenario: A settings write updates the root's preferences

- **WHEN** the user changes a preference on the settings screen
- **THEN** the value is written to storage once, and the root state's preferences and the values derived from them hold the new value once the change has been handled

##### Example: changing the monthly goal

- **GIVEN** the root state's preferences hold a monthly goal of 80,000 and the settings screen is pushed
- **WHEN** the user enters 120,000 in the monthly goal field
- **THEN** storage holds 120,000, the root state's preferences hold 120,000, and the overview state's monthly goal is 120,000

#### Scenario: A dashboard refresh does not re-read settings

- **WHEN** the user pulls to refresh the dashboard
- **THEN** orders are reloaded and the in-memory settings are left as they are

##### Example: storage reads during a refresh

- **GIVEN** the settings storage records every read
- **WHEN** the dashboard refresh is handled
- **THEN** the only action forwarded is the orders load, and the storage read count stays at 0


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
### Requirement: Settings writes preserve the order of edits

Each edit to a persisted preference SHALL be written before the next edit is processed, so that the last value the user entered is the value that remains stored.

#### Scenario: Rapid edits keep the last value

- **WHEN** the user types a new monthly goal one digit at a time
- **THEN** the stored goal after the last keystroke equals the value shown in the field

##### Example: three keystrokes

- **GIVEN** the stored monthly goal is 0
- **WHEN** the field receives 1, 12, and 120 in that order
- **THEN** three writes happen in that order and the stored goal is 120

<!-- @trace
source: small-features-style-compliance
updated: 2026-09-24
code:
  - apps/ios/BuyLedgerTests/BLFormattersTests.swift
  - apps/ios/BuyLedger/Features/Quote/Components/QuoteInputsCard.swift
  - apps/ios/BuyLedger/Features/FX/Components/FxStatusBanner.swift
  - apps/ios/BuyLedger/Features/Orders/OrderDateSection.swift
  - apps/ios/BuyLedger/Features/Quote/QuoteView.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/fxViewBaseline.1.png
  - apps/ios/BuyLedger/Features/FX/Components/FxRatesList.swift
  - apps/ios/BuyLedger/Features/AISummary/OllamaDTO.swift
  - apps/ios/BuyLedgerTests/ActionGroupingScanTests+Scanner.swift
  - apps/ios/BuyLedgerTests/ActionGroupingScanTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLFormatters.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsSnapshot.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsStore.swift
  - apps/ios/BuyLedgerTests/SnapshotTests.swift
  - apps/ios/BuyLedger/Core/Networking/OllamaChatRequest.swift
  - apps/ios/BuyLedgerTests/SettingsFeatureTests.swift
  - apps/ios/BuyLedger/Features/Customers/CustomersView.swift
  - apps/ios/BuyLedger/App/BuyLedgerApp.swift
  - apps/ios/BuyLedger/Features/Quote/QuoteRateFeature.swift
  - apps/ios/BuyLedgerTests/FxFeatureTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/fxViewRateFailureBaseline.1.png
  - apps/ios/BuyLedger/Shared/Extensions/Bundle+Extensions.swift
  - apps/ios/BuyLedger/Features/Customers/CustomerRankBadgeStyle.swift
  - apps/ios/BuyLedgerTests/ActionGroupingScanTests+Scenarios.swift
  - apps/ios/BuyLedgerTests/AISummaryFeatureTests.swift
  - apps/ios/BuyLedger/Core/Networking/OllamaClient.swift
  - apps/ios/BuyLedger/Features/Customers/Components/CustomerTopCard.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsFeature.swift
  - apps/ios/BuyLedgerTests/LedgerOrder+Fixture.swift
  - apps/ios/BuyLedger/Features/Customers/CustomerRow.swift
  - apps/ios/CLAUDE.md
  - apps/ios/BuyLedger/Features/Settings/AISummaryModelCatalog.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsView.swift
  - apps/ios/BuyLedger/Features/FX/FxView.swift
  - apps/ios/BuyLedger/Features/Customers/CustomersFeature.swift
  - apps/ios/BuyLedgerTests/SettingsStoreTests.swift
  - apps/ios/BuyLedger/Features/FX/FxFormatters.swift
  - apps/ios/BuyLedger/Features/Quote/Components/QuoteBreakdownCard.swift
  - apps/ios/BuyLedger/Features/AISummary/AISummaryView.swift
  - apps/ios/BuyLedger/Features/AISummary/AISummaryFeature.swift
  - apps/ios/BuyLedgerTests/FxRateSnapshotTests.swift
  - apps/ios/BuyLedger/Features/App/RootFeature.swift
  - apps/ios/BuyLedger/Features/More/MoreView.swift
  - apps/ios/BuyLedgerTests/CustomersFeatureTests.swift
  - apps/ios/BuyLedgerTests/OllamaClientTests.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests.swift
  - apps/ios/BuyLedgerTests/AppLanguageTests.swift
  - apps/ios/BuyLedger/Features/Quote/Components/QuoteStatusBanner.swift
  - apps/ios/README.md
  - apps/ios/BuyLedgerTests/CustomerRowTests.swift
  - apps/ios/BuyLedger/Core/Networking/OllamaChatResponse.swift
  - apps/ios/BuyLedger/Features/Quote/QuoteFeature.swift
  - apps/ios/BuyLedger/Core/Domain/FxRateSnapshot.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersFeature+StateQuery.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFormatters.swift
  - apps/ios/BuyLedger/Features/FX/FxFeature.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsStorage.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestDependencyOverrides.swift
  - apps/ios/BuyLedger/Features/Customers/Components/CustomerListRow.swift
  - apps/ios/BuyLedger.xcodeproj/project.pbxproj
  - apps/ios/BuyLedger/Features/Orders/OrdersFeature.swift
  - apps/ios/BuyLedgerTests/QuoteFeatureTests.swift
  - apps/ios/BuyLedger/Features/AISummary/OllamaClient.swift
  - apps/ios/BuyLedgerTests/OrdersFeatureTests.swift
-->