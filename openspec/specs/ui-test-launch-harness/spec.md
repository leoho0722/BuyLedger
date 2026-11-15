# ui-test-launch-harness Specification

## Purpose

TBD - created by archiving change 'uitest-foundation'. Update Purpose after archive.

## Requirements

### Requirement: UI test mode activation

The app SHALL enter UI test mode only when a dedicated launch argument is present, and the entire UI test harness SHALL be excluded from release builds through conditional compilation. Activation SHALL happen in the app's launch configurator before the root store or the model container is created, so that every dependency resolved afterwards observes the overridden values.

#### Scenario: Normal launch is unaffected

- **WHEN** the app launches without the UI test launch argument
- **THEN** it reads the on-disk SwiftData store, initialises telemetry, and resolves the live photo, calendar, and exchange rate dependencies exactly as before

#### Scenario: UI test launch activates the harness

- **WHEN** the app launches with the UI test launch argument
- **THEN** it uses an in-memory model container, skips telemetry initialisation, and resolves the UI test doubles for photo, calendar, and exchange rate dependencies

#### Scenario: Release build excludes the harness

- **WHEN** the app is built in the release configuration
- **THEN** the UI test harness symbols are absent from the product and the activation check is a compile-time constant that is always false


<!-- @trace
source: uitest-foundation
updated: 2026-07-24
code:
  - apps/ios/BuyLedgerUITests/Support/AppNavigator.swift
  - apps/ios/BuyLedgerUITests/Support/SheetInteraction.swift
  - apps/ios/BuyLedgerUITests/Support/TextInput.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignFeature.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoThumbnail.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignEditView.swift
  - apps/ios/BuyLedger/Core/Testing/BLUITestSeedData.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/States/BLLoadFailureView.swift
  - apps/ios/BuyLedgerUITests/Support/BLUITestCase.swift
  - apps/ios/BuyLedger/App/BuyLedgerApp.swift
  - apps/ios/BuyLedger/Core/Testing/BLUITestSeedProfile.swift
  - apps/ios/BuyLedger/Features/Orders/Components/MergePhotoPickerSheet.swift
  - apps/ios/BuyLedgerUITests/Screens/MergeFlowScreen.swift
  - apps/ios/BuyLedgerUITests/Screens/AISummaryScreen.swift
  - apps/ios/BuyLedgerUITests/Support/ValueParsing.swift
  - apps/ios/BuyLedgerUITests/Tests/Campaigns/CampaignDetailTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderMergeTests.swift
  - apps/ios/CLAUDE.md
  - apps/ios/BuyLedgerUITests.xctestplan
  - apps/ios/BuyLedgerTests/BLUITestConfigurationTests.swift
  - apps/ios/BuyLedgerUITests/KeyboardDismissTests.swift
  - apps/ios/BuyLedgerUITests/Screens/OrderDetailScreen.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignDetailView.swift
  - apps/ios/BuyLedgerUITests/Screens/Screen.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrdersListTests.swift
  - apps/ios/BuyLedger/Features/Customers/CustomersView.swift
  - apps/ios/BuyLedgerUITests/Tests/Tools/FxTests.swift
  - apps/ios/BuyLedger/Features/App/RootTabLayout.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderDetailView.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoViewer.swift
  - apps/ios/BuyLedgerUITests/Screens/CampaignEditScreen.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardView.swift
  - apps/ios/BuyLedgerUITests/Tests/Smoke/LaunchSmokeTests.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderRowView.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFilterSheet.swift
  - apps/ios/BuyLedgerUITests/Screens/QuoteScreen.swift
  - apps/ios/BuyLedgerUITests/Tests/Campaigns/CampaignListTests.swift
  - apps/ios/BuyLedger/Features/More/MoreView.swift
  - apps/ios/BuyLedger/Features/Orders/OrderEditView.swift
  - apps/ios/BuyLedger/Features/App/RootSidebarLayout.swift
  - apps/ios/BuyLedgerUITests/Tests/Smoke/HarnessSelfCheckTests.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersView.swift
  - apps/ios/BuyLedgerAccessibilityIDs/BLAccessibilityID.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderCreateTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Tools/QuoteTests.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersCompactView.swift
  - apps/ios/BuyLedger/Core/Testing/BLUITestHarness.swift
  - apps/ios/BuyLedger/Features/App/RootTab.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignListView.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsView.swift
  - apps/ios/BuyLedgerUITests/Tests/Insights/InsightsTests.swift
  - apps/ios/BuyLedgerUITests/Screens/CampaignsScreen.swift
  - apps/ios/BuyLedgerUITests/Screens/CampaignDetailScreen.swift
  - apps/ios/BuyLedgerUITests/Support/Diagnostics.swift
  - apps/ios/BuyLedgerUITests/Support/LaunchOptions.swift
  - apps/ios/BuyLedger/Core/Testing/BLUITestDependencyOverrides.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderMergeCandidateSheet.swift
  - apps/ios/BuyLedgerUITests/Screens/InsightsScreen.swift
  - apps/ios/BuyLedgerUITests/Screens/OrderEditScreen.swift
  - apps/ios/BuyLedgerUITests/Screens/PhotoViewerScreen.swift
  - apps/ios/BuyLedgerUITests/Support/MenuInteraction.swift
  - apps/ios/BuyLedgerUITests/BuyLedgerUITestsLaunchTests.swift
  - apps/ios/BuyLedgerUITests/Support/Assertions.swift
  - apps/ios/BuyLedgerUITests/Screens/DashboardScreen.swift
  - apps/ios/BuyLedgerUITests/Screens/FxScreen.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OptionPickerSheet.swift
  - apps/ios/BuyLedgerUITests/Screens/OrdersScreen.swift
  - apps/ios/BuyLedgerUITests/Screens/CustomersScreen.swift
  - apps/ios/BuyLedgerUITests/Screens/RootNavigationScreen.swift
  - apps/ios/BuyLedgerUITests/Screens/SettingsScreen.swift
  - apps/ios/BuyLedgerUITests/PhotoViewerPagingTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/AISummaryTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Performance/LaunchPerformanceTests.swift
  - apps/ios/BuyLedger/App/AppLaunchConfigurator.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsView.swift
  - apps/ios/BuyLedgerTests/BLAccessibilityIDTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderDetailTests.swift
  - apps/ios/BuyLedger.xcodeproj/xcshareddata/xcschemes/BuyLedgerUITests.xcscheme
  - apps/ios/BuyLedger/Features/AISummary/AISummaryView.swift
  - apps/ios/BuyLedgerUITests/Screens/OptionPickerScreen.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Chips/BLFilterChip.swift
  - apps/ios/BuyLedgerUITests/Tests/Customers/CustomersTests.swift
  - apps/ios/README.md
  - apps/ios/BuyLedger/Core/Testing/BLUITestConfiguration.swift
  - apps/ios/BuyLedger/Features/Quote/QuoteView.swift
  - apps/ios/BuyLedger.xcodeproj/project.pbxproj
  - apps/ios/BuyLedger/Features/App/RootFeature.swift
  - apps/ios/BuyLedger/Features/FX/FxView.swift
  - apps/ios/BuyLedgerUITests/Tests/Campaigns/CampaignCrudTests.swift
  - apps/ios/BuyLedgerUITests/Support/Waiting.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderEditDirtyTests.swift
  - apps/ios/BuyLedgerUITests-Performance.xctestplan
  - apps/ios/BuyLedgerUITests/Support/AlertInteraction.swift
  - apps/ios/BuyLedgerUITests/BuyLedgerUITests.swift
  - apps/ios/BuyLedgerUITests/Support/Scrolling.swift
-->

---
### Requirement: Deterministic data seeding by profile

The app SHALL accept a seed profile name as a launch argument and SHALL populate the in-memory store with the fixed data set that the profile declares. Every seeded date SHALL be derived from the injected reference time rather than from the system clock, so the same profile yields structurally identical data on any calendar day. An unknown or absent profile name SHALL be treated as the empty profile. Seeded master data names (order sources, categories, payment methods, reconciliation statuses) and the master data values that seeded orders reference SHALL be user data as a user would type it, and SHALL NOT be String Catalog keys.

#### Scenario: Empty profile yields empty states

- **WHEN** the app launches in UI test mode with the empty seed profile
- **THEN** the overview screen shows its onboarding empty state and the orders list shows its no-matching-orders empty state

#### Scenario: Populated profile yields content

- **WHEN** the app launches in UI test mode with a populated seed profile
- **THEN** the orders list shows exactly the number of orders the profile declares, and the overview screen shows content instead of the onboarding empty state

#### Scenario: Seeded dates follow the injected reference time

- **WHEN** the app launches in UI test mode with a populated seed profile and a given reference time
- **THEN** the order whose profile position is "today" is grouped under the relative today section, and the order whose profile position is "yesterday" is grouped under the relative yesterday section

#### Scenario: Unknown profile falls back to empty

- **WHEN** the app launches in UI test mode with a seed profile name that no profile declares
- **THEN** the store is left empty, a warning is logged, and the app continues launching without crashing

#### Scenario: Seeded master data names are user data

- **GIVEN** any declared seed profile
- **WHEN** the profile is seeded into an in-memory store
- **THEN** no seeded master data name and no order source, category, payment method or reconciliation status referenced by a seeded order has the dotted shape of a String Catalog key (three or four lowerCamelCase segments, the same format the String Catalog key test enforces)

##### Example: payment method names seeded with master data

| Seeded payment method name | Cardless | Bank transfer | Cash on delivery |
| --- | --- | --- | --- |
| 信用卡 | no | no | no |
| 銀行轉帳 | no | yes | no |
| 無卡 | yes | no | no |
| 貨到付款 | no | no | yes |
| LINE Pay | no | no | no |
| Apple Pay | no | no | no |

A value such as `orders.list.label.cashDelivery` in place of 貨到付款 violates this scenario.


<!-- @trace
source: order-editor-close-and-seed-names
updated: 2026-10-17
code:
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderEditDateRowTests.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignEditView.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrderEdit/orderEditView_合併訂單情境_符合基準圖.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrderEditSections/orderEditOriginalSection_長訂單識別碼_顯示短識別碼.1.png
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Pickers/OptionPickerAddSection.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Pickers/OptionPickerSheet+Configuration.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderEditAddOptionTests.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderEditBasicSection.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrderEditSections/orderEditCostSection_一般既有訂單_符合基準圖.1.png
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderCreateTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderEditDirtyTests.swift
  - apps/ios/BuyLedger/Features/Campaigns/Components/CampaignEditNotesSection.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestSeedData+Analytics.swift
  - apps/ios/BuyLedger/Features/Quote/QuoteView.swift
  - apps/ios/BuyLedgerUITests/Screens/CampaignEditScreen.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestSeedData+Campaigns.swift
  - apps/ios/BuyLedger/Features/Lookups/Components/LookupItemList.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrderEditSections/orderEditPaymentSection_一般既有訂單_符合基準圖.1.png
  - apps/ios/BuyLedgerAccessibilityIDs/BLAccessibilityID+Orders.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestSeedData+Builders.swift
  - apps/ios/BuyLedger.xcodeproj/project.pbxproj
  - apps/ios/BuyLedgerTests/OrderEditDraftOperationsTests.swift
  - apps/ios/BuyLedger/Features/FX/FxView.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrderEditSections/orderEditFeesSection_一般既有訂單_符合基準圖.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrderEditSections/orderEditPhotosSection_一般既有訂單_符合基準圖.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+CampaignDetail/campaignEditView_編輯既有開團_符合基準圖.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrderEdit/orderEditView_一般既有訂單_符合基準圖.1.png
  - apps/ios/BuyLedgerTests/SnapshotTests+OrderEditSections.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestSeedData.swift
  - apps/ios/BuyLedgerUITests/Support/AlertInteraction.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrderEditSections/orderEditNotesSection_一般既有訂單_符合基準圖.1.png
  - apps/ios/BuyLedger/App/Testing/BLUITestSeedData+Orders.swift
  - apps/ios/BuyLedger/Features/Orders/OrderEditView.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+CampaignDetail/campaignEditNotesSection_編輯既有開團_符合基準圖.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrderEditSections/orderEditItemsSection_一般既有訂單_符合基準圖.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrderEditSections/orderEditOriginalSection_一般既有訂單_符合基準圖.1.png
  - apps/ios/BuyLedger/Features/Orders/OrdersView.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrderEditSections/orderEditCampaignSection_一般既有訂單_符合基準圖.1.png
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Forms/PaymentMethodEditorSheet.swift
  - apps/ios/BuyLedgerUITests/Screens/OrderEditScreen.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementView.swift
  - apps/ios/BuyLedgerTests/SnapshotTests+CampaignDetail.swift
  - apps/ios/BuyLedgerUITests/Screens/PaymentMethodEditorScreen.swift
  - apps/ios/BuyLedgerUITests/Tests/Campaigns/CampaignEditDateRowTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Pickers/OptionPickerList.swift
  - apps/ios/BuyLedgerUITests/Screens/OptionPickerScreen.swift
  - apps/ios/BuyLedgerTests/SnapshotSectionView.swift
  - apps/ios/BuyLedgerAccessibilityIDs/BLAccessibilityID+Campaigns.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Pickers/OptionPickerSheet.swift
  - apps/ios/BuyLedgerTests/SnapshotTests+OrderEdit.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrderEdit/orderEditView_長訂單識別碼_顯示短識別碼.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrderEditSections/orderEditCampaignSection_合併訂單情境_以頓號串接開團.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrderEditSections/orderEditStatusSection_一般既有訂單_符合基準圖.1.png
  - apps/ios/BuyLedger/Features/Orders/Components/OrderEditPickerDestination.swift
  - apps/ios/BuyLedgerTests/BLUITestSeedDataTests.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFilterPreviewFixtures.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsView.swift
  - apps/ios/BuyLedger/Shared/Localization/CurrencyDisplayName.swift
-->

---
### Requirement: Test isolation between launches

Each UI test mode launch SHALL start from a clean state. The app SHALL NOT read or write the on-disk SwiftData store in UI test mode, and SHALL clear its persisted settings values before applying the settings declared by the launch arguments.

#### Scenario: Data created in one launch does not survive

- **WHEN** a test creates an order in UI test mode and the app is relaunched with the same launch arguments
- **THEN** the orders list contains only the orders declared by the seed profile, and the created order is absent

#### Scenario: Settings do not leak between launches

- **WHEN** a test switches the app language to English and the app is relaunched without a language launch argument
- **THEN** the app displays its default language


<!-- @trace
source: uitest-foundation
updated: 2026-07-24
code:
  - apps/ios/BuyLedgerUITests/Support/AppNavigator.swift
  - apps/ios/BuyLedgerUITests/Support/SheetInteraction.swift
  - apps/ios/BuyLedgerUITests/Support/TextInput.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignFeature.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoThumbnail.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignEditView.swift
  - apps/ios/BuyLedger/Core/Testing/BLUITestSeedData.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/States/BLLoadFailureView.swift
  - apps/ios/BuyLedgerUITests/Support/BLUITestCase.swift
  - apps/ios/BuyLedger/App/BuyLedgerApp.swift
  - apps/ios/BuyLedger/Core/Testing/BLUITestSeedProfile.swift
  - apps/ios/BuyLedger/Features/Orders/Components/MergePhotoPickerSheet.swift
  - apps/ios/BuyLedgerUITests/Screens/MergeFlowScreen.swift
  - apps/ios/BuyLedgerUITests/Screens/AISummaryScreen.swift
  - apps/ios/BuyLedgerUITests/Support/ValueParsing.swift
  - apps/ios/BuyLedgerUITests/Tests/Campaigns/CampaignDetailTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderMergeTests.swift
  - apps/ios/CLAUDE.md
  - apps/ios/BuyLedgerUITests.xctestplan
  - apps/ios/BuyLedgerTests/BLUITestConfigurationTests.swift
  - apps/ios/BuyLedgerUITests/KeyboardDismissTests.swift
  - apps/ios/BuyLedgerUITests/Screens/OrderDetailScreen.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignDetailView.swift
  - apps/ios/BuyLedgerUITests/Screens/Screen.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrdersListTests.swift
  - apps/ios/BuyLedger/Features/Customers/CustomersView.swift
  - apps/ios/BuyLedgerUITests/Tests/Tools/FxTests.swift
  - apps/ios/BuyLedger/Features/App/RootTabLayout.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderDetailView.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoViewer.swift
  - apps/ios/BuyLedgerUITests/Screens/CampaignEditScreen.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardView.swift
  - apps/ios/BuyLedgerUITests/Tests/Smoke/LaunchSmokeTests.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderRowView.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFilterSheet.swift
  - apps/ios/BuyLedgerUITests/Screens/QuoteScreen.swift
  - apps/ios/BuyLedgerUITests/Tests/Campaigns/CampaignListTests.swift
  - apps/ios/BuyLedger/Features/More/MoreView.swift
  - apps/ios/BuyLedger/Features/Orders/OrderEditView.swift
  - apps/ios/BuyLedger/Features/App/RootSidebarLayout.swift
  - apps/ios/BuyLedgerUITests/Tests/Smoke/HarnessSelfCheckTests.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersView.swift
  - apps/ios/BuyLedgerAccessibilityIDs/BLAccessibilityID.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderCreateTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Tools/QuoteTests.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersCompactView.swift
  - apps/ios/BuyLedger/Core/Testing/BLUITestHarness.swift
  - apps/ios/BuyLedger/Features/App/RootTab.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignListView.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsView.swift
  - apps/ios/BuyLedgerUITests/Tests/Insights/InsightsTests.swift
  - apps/ios/BuyLedgerUITests/Screens/CampaignsScreen.swift
  - apps/ios/BuyLedgerUITests/Screens/CampaignDetailScreen.swift
  - apps/ios/BuyLedgerUITests/Support/Diagnostics.swift
  - apps/ios/BuyLedgerUITests/Support/LaunchOptions.swift
  - apps/ios/BuyLedger/Core/Testing/BLUITestDependencyOverrides.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderMergeCandidateSheet.swift
  - apps/ios/BuyLedgerUITests/Screens/InsightsScreen.swift
  - apps/ios/BuyLedgerUITests/Screens/OrderEditScreen.swift
  - apps/ios/BuyLedgerUITests/Screens/PhotoViewerScreen.swift
  - apps/ios/BuyLedgerUITests/Support/MenuInteraction.swift
  - apps/ios/BuyLedgerUITests/BuyLedgerUITestsLaunchTests.swift
  - apps/ios/BuyLedgerUITests/Support/Assertions.swift
  - apps/ios/BuyLedgerUITests/Screens/DashboardScreen.swift
  - apps/ios/BuyLedgerUITests/Screens/FxScreen.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OptionPickerSheet.swift
  - apps/ios/BuyLedgerUITests/Screens/OrdersScreen.swift
  - apps/ios/BuyLedgerUITests/Screens/CustomersScreen.swift
  - apps/ios/BuyLedgerUITests/Screens/RootNavigationScreen.swift
  - apps/ios/BuyLedgerUITests/Screens/SettingsScreen.swift
  - apps/ios/BuyLedgerUITests/PhotoViewerPagingTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/AISummaryTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Performance/LaunchPerformanceTests.swift
  - apps/ios/BuyLedger/App/AppLaunchConfigurator.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsView.swift
  - apps/ios/BuyLedgerTests/BLAccessibilityIDTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderDetailTests.swift
  - apps/ios/BuyLedger.xcodeproj/xcshareddata/xcschemes/BuyLedgerUITests.xcscheme
  - apps/ios/BuyLedger/Features/AISummary/AISummaryView.swift
  - apps/ios/BuyLedgerUITests/Screens/OptionPickerScreen.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Chips/BLFilterChip.swift
  - apps/ios/BuyLedgerUITests/Tests/Customers/CustomersTests.swift
  - apps/ios/README.md
  - apps/ios/BuyLedger/Core/Testing/BLUITestConfiguration.swift
  - apps/ios/BuyLedger/Features/Quote/QuoteView.swift
  - apps/ios/BuyLedger.xcodeproj/project.pbxproj
  - apps/ios/BuyLedger/Features/App/RootFeature.swift
  - apps/ios/BuyLedger/Features/FX/FxView.swift
  - apps/ios/BuyLedgerUITests/Tests/Campaigns/CampaignCrudTests.swift
  - apps/ios/BuyLedgerUITests/Support/Waiting.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderEditDirtyTests.swift
  - apps/ios/BuyLedgerUITests-Performance.xctestplan
  - apps/ios/BuyLedgerUITests/Support/AlertInteraction.swift
  - apps/ios/BuyLedgerUITests/BuyLedgerUITests.swift
  - apps/ios/BuyLedgerUITests/Support/Scrolling.swift
-->

---
### Requirement: Environment injection for time, locale, and identifiers

In UI test mode the app SHALL resolve the current date, calendar, time zone, and generated identifiers from injected deterministic values rather than from the system. The reference time SHALL be configurable through a launch argument and SHALL fall back to a fixed default when absent or unparsable.

#### Scenario: Date-dependent grouping is stable

- **WHEN** the same UI test runs on two different calendar days with the same reference time argument
- **THEN** the date section titles, the date range filter results, and the trend chart buckets are identical in both runs

#### Scenario: Unparsable reference time falls back

- **WHEN** the app launches in UI test mode with a reference time argument that is not a valid timestamp
- **THEN** the app uses the fixed default reference time, logs a warning, and continues launching


<!-- @trace
source: uitest-foundation
updated: 2026-07-24
code:
  - apps/ios/BuyLedgerUITests/Support/AppNavigator.swift
  - apps/ios/BuyLedgerUITests/Support/SheetInteraction.swift
  - apps/ios/BuyLedgerUITests/Support/TextInput.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignFeature.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoThumbnail.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignEditView.swift
  - apps/ios/BuyLedger/Core/Testing/BLUITestSeedData.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/States/BLLoadFailureView.swift
  - apps/ios/BuyLedgerUITests/Support/BLUITestCase.swift
  - apps/ios/BuyLedger/App/BuyLedgerApp.swift
  - apps/ios/BuyLedger/Core/Testing/BLUITestSeedProfile.swift
  - apps/ios/BuyLedger/Features/Orders/Components/MergePhotoPickerSheet.swift
  - apps/ios/BuyLedgerUITests/Screens/MergeFlowScreen.swift
  - apps/ios/BuyLedgerUITests/Screens/AISummaryScreen.swift
  - apps/ios/BuyLedgerUITests/Support/ValueParsing.swift
  - apps/ios/BuyLedgerUITests/Tests/Campaigns/CampaignDetailTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderMergeTests.swift
  - apps/ios/CLAUDE.md
  - apps/ios/BuyLedgerUITests.xctestplan
  - apps/ios/BuyLedgerTests/BLUITestConfigurationTests.swift
  - apps/ios/BuyLedgerUITests/KeyboardDismissTests.swift
  - apps/ios/BuyLedgerUITests/Screens/OrderDetailScreen.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignDetailView.swift
  - apps/ios/BuyLedgerUITests/Screens/Screen.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrdersListTests.swift
  - apps/ios/BuyLedger/Features/Customers/CustomersView.swift
  - apps/ios/BuyLedgerUITests/Tests/Tools/FxTests.swift
  - apps/ios/BuyLedger/Features/App/RootTabLayout.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderDetailView.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoViewer.swift
  - apps/ios/BuyLedgerUITests/Screens/CampaignEditScreen.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardView.swift
  - apps/ios/BuyLedgerUITests/Tests/Smoke/LaunchSmokeTests.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderRowView.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFilterSheet.swift
  - apps/ios/BuyLedgerUITests/Screens/QuoteScreen.swift
  - apps/ios/BuyLedgerUITests/Tests/Campaigns/CampaignListTests.swift
  - apps/ios/BuyLedger/Features/More/MoreView.swift
  - apps/ios/BuyLedger/Features/Orders/OrderEditView.swift
  - apps/ios/BuyLedger/Features/App/RootSidebarLayout.swift
  - apps/ios/BuyLedgerUITests/Tests/Smoke/HarnessSelfCheckTests.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersView.swift
  - apps/ios/BuyLedgerAccessibilityIDs/BLAccessibilityID.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderCreateTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Tools/QuoteTests.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersCompactView.swift
  - apps/ios/BuyLedger/Core/Testing/BLUITestHarness.swift
  - apps/ios/BuyLedger/Features/App/RootTab.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignListView.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsView.swift
  - apps/ios/BuyLedgerUITests/Tests/Insights/InsightsTests.swift
  - apps/ios/BuyLedgerUITests/Screens/CampaignsScreen.swift
  - apps/ios/BuyLedgerUITests/Screens/CampaignDetailScreen.swift
  - apps/ios/BuyLedgerUITests/Support/Diagnostics.swift
  - apps/ios/BuyLedgerUITests/Support/LaunchOptions.swift
  - apps/ios/BuyLedger/Core/Testing/BLUITestDependencyOverrides.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderMergeCandidateSheet.swift
  - apps/ios/BuyLedgerUITests/Screens/InsightsScreen.swift
  - apps/ios/BuyLedgerUITests/Screens/OrderEditScreen.swift
  - apps/ios/BuyLedgerUITests/Screens/PhotoViewerScreen.swift
  - apps/ios/BuyLedgerUITests/Support/MenuInteraction.swift
  - apps/ios/BuyLedgerUITests/BuyLedgerUITestsLaunchTests.swift
  - apps/ios/BuyLedgerUITests/Support/Assertions.swift
  - apps/ios/BuyLedgerUITests/Screens/DashboardScreen.swift
  - apps/ios/BuyLedgerUITests/Screens/FxScreen.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OptionPickerSheet.swift
  - apps/ios/BuyLedgerUITests/Screens/OrdersScreen.swift
  - apps/ios/BuyLedgerUITests/Screens/CustomersScreen.swift
  - apps/ios/BuyLedgerUITests/Screens/RootNavigationScreen.swift
  - apps/ios/BuyLedgerUITests/Screens/SettingsScreen.swift
  - apps/ios/BuyLedgerUITests/PhotoViewerPagingTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/AISummaryTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Performance/LaunchPerformanceTests.swift
  - apps/ios/BuyLedger/App/AppLaunchConfigurator.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsView.swift
  - apps/ios/BuyLedgerTests/BLAccessibilityIDTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderDetailTests.swift
  - apps/ios/BuyLedger.xcodeproj/xcshareddata/xcschemes/BuyLedgerUITests.xcscheme
  - apps/ios/BuyLedger/Features/AISummary/AISummaryView.swift
  - apps/ios/BuyLedgerUITests/Screens/OptionPickerScreen.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Chips/BLFilterChip.swift
  - apps/ios/BuyLedgerUITests/Tests/Customers/CustomersTests.swift
  - apps/ios/README.md
  - apps/ios/BuyLedger/Core/Testing/BLUITestConfiguration.swift
  - apps/ios/BuyLedger/Features/Quote/QuoteView.swift
  - apps/ios/BuyLedger.xcodeproj/project.pbxproj
  - apps/ios/BuyLedger/Features/App/RootFeature.swift
  - apps/ios/BuyLedger/Features/FX/FxView.swift
  - apps/ios/BuyLedgerUITests/Tests/Campaigns/CampaignCrudTests.swift
  - apps/ios/BuyLedgerUITests/Support/Waiting.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderEditDirtyTests.swift
  - apps/ios/BuyLedgerUITests-Performance.xctestplan
  - apps/ios/BuyLedgerUITests/Support/AlertInteraction.swift
  - apps/ios/BuyLedgerUITests/BuyLedgerUITests.swift
  - apps/ios/BuyLedgerUITests/Support/Scrolling.swift
-->

---
### Requirement: External dependency doubles in UI test mode

In UI test mode the app SHALL replace the photo import, calendar reminder, exchange rate, and local authentication dependencies with doubles that never present system UI and never perform network requests. The calendar double's authorisation outcome SHALL be selectable through a launch argument.

The local authentication double SHALL never present a system biometric prompt, and its outcome SHALL be selectable through a launch argument so that both the success and the failure paths of ledger protection can be exercised. Whether protection starts enabled SHALL likewise be selectable, so that the locked launch state can be reached without first driving the settings screen.

#### Scenario: Photo import does not present the system picker

- **WHEN** the user taps the add-photos control in UI test mode
- **THEN** the built-in test images are attached directly and no out-of-process picker appears

#### Scenario: Calendar reminder does not prompt for permission

- **WHEN** the user saves a campaign with a reminder in UI test mode
- **THEN** no system permission dialog appears and no event is written to the device calendar

#### Scenario: Calendar authorisation denial is selectable

- **WHEN** the app launches in UI test mode with the calendar denial argument and the user saves a campaign with a reminder
- **THEN** the app shows its permission-denied handling without presenting a system dialog

#### Scenario: Authentication never prompts and its outcome is selectable

- **WHEN** the app launches in UI test mode with an authentication outcome argument and protection is engaged
- **THEN** no system biometric prompt appears and the app follows the selected outcome

#### Scenario: The locked launch state is reachable directly

- **WHEN** the app launches in UI test mode with protection preset to enabled
- **THEN** the app starts in its locked state without the test having to enable protection through the settings screen


<!-- @trace
source: app-lock-and-privacy-shield
updated: 2026-08-15
code:
  - apps/ios/BuyLedger/Features/Campaigns/CampaignFormatters.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementDestination.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsDateRange.swift
  - apps/ios/BuyLedger/Features/Orders/OrderMergeFeature.swift
  - apps/ios/BuyLedgerTests/CurrencyMetadataCacheTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Customers/CustomersTests.swift
  - apps/ios/BuyLedgerTests/OrdersLoadStateTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewBaseline.1.png
  - apps/ios/BuyLedger/Core/Persistence/NameLookupRecord.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersBatchOperations.swift
  - apps/ios/BuyLedger/Core/Testing/BLUITestDependencyOverrides.swift
  - apps/ios/BuyLedger/Features/Orders/OrderDraft.swift
  - apps/ios/BuyLedger/Features/FX/FxRates.swift
  - apps/ios/BuyLedger/Features/App/SidebarBadgeCounts.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupNameEditorSheet.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoThumbnail.swift
  - apps/ios/BuyLedgerTests/AppConfigurationTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLSparkline.swift
  - apps/ios/BuyLedgerTests/PaymentMethodPersistenceTests.swift
  - apps/ios/BuyLedgerUITests/Screens/AppLockScreen.swift
  - apps/ios/BuyLedgerUITests/Tests/Tools/QuoteTests.swift
  - apps/ios/BuyLedger/Features/App/AppLockFeature.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsFeature.swift
  - apps/ios/BuyLedger/Core/Sync/SyncMeta.swift
  - apps/ios/BuyLedger/Core/Persistence/CampaignReminderPersistence.swift
  - apps/ios/BuyLedger/Features/FX/ExchangeRateClient.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderSelectableRow.swift
  - apps/ios/BuyLedger/Features/App/RootTab.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardStats.swift
  - shared/data-model/schema/OrderStatus.yaml
  - shared/data-model/schema/PaymentMethodInfo.yaml
  - shared/data-model/schema/FxRateSnapshot.yaml
  - apps/ios/BuyLedgerTests/AccessibilityConventionScanTests.swift
  - apps/ios/BuyLedger/Core/Networking/URLRequestBuilder.swift
  - apps/ios/BuyLedgerTests/TestDependencies.swift
  - apps/ios/BuyLedgerTests/PersistenceRecoveryTests.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignEditFeature.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLMetrics.swift
  - apps/ios/BuyLedgerUITests/Tests/Performance/LaunchPerformanceTests.swift
  - apps/ios/BuyLedger/Core/Domain/Campaign.swift
  - apps/ios/BuyLedgerUITests/Screens/DashboardScreen.swift
  - apps/ios/BuyLedger/Core/Domain/LedgerOrder.swift
  - apps/ios/BuyLedger/Core/Persistence/ReconciliationStatusPersistence.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Avatar/BLAvatar.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/LedgerCustomer.generated.swift
  - apps/ios/BuyLedgerTests/NumericInputGroupingScanTests.swift
  - shared/data-model/fixtures/expected/typescript/SampleProfile.ts
  - apps/ios/BuyLedger/Features/Insights/InsightsView.swift
  - apps/ios/BuyLedgerTests/ColorContrastTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Forms/PaymentMethodEditorSheet.swift
  - apps/ios/BuyLedgerTests/OrdersFeatureTests.swift
  - shared/data-model/fixtures/expected/typescript/SampleQuote.ts
  - apps/ios/BuyLedger/Core/Sync/SyncQueueItem.swift
  - apps/ios/BuyLedger/Core/Persistence/BuyLedgerSchema.swift
  - apps/ios/BuyLedgerUITests.xctestplan
  - shared/data-model/fixtures/expected/kotlin/SampleQuote.kt
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLFormatters.swift
  - apps/ios/BuyLedger/Shared/Extensions/Color+Extensions.swift
  - shared/data-model/fixtures/schema/sample-trait-matrix.yaml
  - apps/ios/BuyLedgerTests/OrderDraftTests.swift
  - apps/ios/BuyLedger/Core/Domain/OrderMerge.swift
  - apps/ios/BuyLedgerUITests/Screens/CampaignEditScreen.swift
  - apps/ios/BuyLedger/Core/Persistence/PersistenceContainer.swift
  - apps/ios/BuyLedger/Features/App/RootTabLayout.swift
  - shared/data-model/fixtures/schema/sample-enums.yaml
  - apps/ios/BuyLedgerTests/BLPhotoViewerTests.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Chips/BLFilterChip.swift
  - apps/ios/BuyLedger/Shared/Extensions/Decimal+Extensions.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/AISummaryTests.swift
  - apps/ios/BuyLedger/Core/Domain/LedgerOrder+Samples.swift
  - apps/ios/BuyLedger/Core/Dependencies/OpenSettingsClient.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignSummary.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewBaseline.1.png
  - apps/ios/BuyLedger/Features/Orders/OrdersFeature.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/persistenceFailureViewBaseline.1.png
  - shared/data-model/fixtures/expected/swift/SampleQuote.generated.swift
  - apps/ios/BuyLedger/App/AppLaunchConfigurator.swift
  - apps/ios/BuyLedger/Core/Domain/FxRateSnapshot.swift
  - apps/ios/BuyLedgerUITests/Tests/Tools/FxTests.swift
  - apps/ios/BuyLedgerTests/APIErrorMappingTests.swift
  - apps/ios/BuyLedgerTests/BiometricAuthClientTests.swift
  - shared/data-model/schema/CustomerTier.yaml
  - apps/ios/BuyLedgerTests/OrderPersistenceTests.swift
  - apps/ios/BuyLedger/Core/Persistence/CategoryPersistence.swift
  - apps/ios/BuyLedger/Core/Networking/HTTPClient.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderStatus+Presentation.swift
  - apps/ios/BuyLedger/Resources/Localizable.xcstrings
  - apps/ios/BuyLedger/Features/Settings/SettingsView.swift
  - apps/ios/BuyLedger/Shared/Localization/AppLanguage.swift
  - apps/ios/BuyLedger/Features/Customers/CustomersView.swift
  - apps/ios/BuyLedger/Features/AISummary/OllamaClient.swift
  - apps/ios/BuyLedgerUITests/Tests/Campaigns/CampaignListTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Cards/BLCard.swift
  - apps/ios/BuyLedgerTests/ProjectionWriteBoundaryTests.swift
  - apps/ios/BuyLedger/Features/App/RootView.swift
  - .github/workflows/ci.yml
  - apps/ios/BuyLedger/Core/Persistence/CurrencyMetadataRecord.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/LedgerOrderItem.generated.swift
  - apps/ios/BuyLedger/Core/Persistence/PaymentMethodPersistence.swift
  - apps/ios/BuyLedger/Core/Persistence/PaymentMethodRecord.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsSnapshot.swift
  - apps/ios/BuyLedger/Features/Quote/QuoteFeature.swift
  - apps/ios/BuyLedgerUITests/Screens/OrdersScreen.swift
  - apps/ios/BuyLedgerTests/CustomersFeatureTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Campaigns/CampaignCrudTests.swift
  - apps/ios/BuyLedgerTests/BLFormattersTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Buttons/BLButtonStyle.swift
  - apps/ios/BuyLedger/App/BuyLedgerApp.swift
  - apps/ios/BuyLedgerTests/ContrastComplianceTests.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardView.swift
  - apps/ios/BuyLedger/Core/Dependencies/PhotoClient.swift
  - apps/ios/BuyLedger/Core/Persistence/OrderSourceRecord.swift
  - apps/ios/BuyLedger/Features/Orders/OrderEditView.swift
  - apps/ios/BuyLedgerTests/OrdersBatchOperationsTests.swift
  - apps/ios/BuyLedgerUITests/Screens/OptionPickerScreen.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderEditDirtyTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Tags/BLTagPill.swift
  - apps/ios/BuyLedgerTests/AISummaryFeatureTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Pickers/OptionPickerSheet.swift
  - apps/ios/BuyLedgerTests/NameLookupPersistenceTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Progress/BLProgressBar.swift
  - apps/ios/BuyLedgerTests/OrderMergeFeatureTests.swift
  - apps/ios/BuyLedgerUITests/PhotoViewerPagingTests.swift
  - apps/ios/BuyLedgerTests/OrderEditFocusTests.swift
  - apps/ios/BuyLedgerUITests/KeyboardDismissTests.swift
  - apps/ios/BuyLedger/Core/Dependencies/CampaignRepository.swift
  - apps/ios/BuyLedgerTests/DesignSystemSourceScanTests.swift
  - apps/ios/BuyLedgerUITests/Screens/MergeFlowScreen.swift
  - apps/ios/BuyLedger/Core/Persistence/CategoryRecord.swift
  - apps/ios/BuyLedgerTests/LookupManagementFeatureTests.swift
  - shared/data-model/schema/LedgerOrderItem.yaml
  - shared/data-model/fixtures/expected/swift/SampleProfile.generated.swift
  - apps/ios/BuyLedger/Core/Persistence/CurrencyMetadataPersistence.swift
  - apps/ios/BuyLedger/Core/Domain/FxRates.swift
  - apps/ios/BuyLedgerTests/LayerBoundaryTests.swift
  - apps/ios/BuyLedger/Shared/Extensions/Image+Extensions.swift
  - apps/ios/BuyLedgerTests/QuoteFeatureTests.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignFeature.swift
  - apps/ios/BuyLedgerTests/AppLockFeatureTests.swift
  - apps/ios/BuyLedgerTests/CampaignReminderFailureTests.swift
  - shared/data-model/fixtures/expected/typescript/SampleGrade.ts
  - apps/ios/BuyLedger/Features/Orders/Components/OrderDetailView.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLDonutSegment.swift
  - apps/ios/BuyLedger/Shared/Media/PhotoDataProcessor.swift
  - shared/data-model/fixtures/expected/typescript/SampleStatus.ts
  - shared/data-model/fixtures/expected/kotlin/SamplePreference.kt
  - apps/ios/BuyLedger/Features/Settings/AISummaryModelCatalog.swift
  - apps/ios/BuyLedgerUITests/Screens/PhotoViewerScreen.swift
  - apps/ios/BuyLedgerTests/PersistenceFailureFeatureTests.swift
  - apps/ios/BuyLedger/Features/More/MoreView.swift
  - apps/ios/BuyLedgerUITests/Support/Waiting.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/States/DelayedProgressView.swift
  - shared/data-model/schema/Money.yaml
  - shared/data-model/fixtures/expected/typescript/SamplePreference.ts
  - apps/ios/BuyLedger/Core/Dependencies/CurrencyMetadataRepository.swift
  - apps/ios/BuyLedger/Core/Diagnostics/CrashDiagnosticsClient.swift
  - apps/ios/BuyLedger/Features/Orders/Components/MergePhotoPickerSheet.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersFeature+StateQuery.swift
  - apps/ios/BuyLedger/Core/Dependencies/OrderSourceRepository.swift
  - apps/ios/BuyLedgerTests/BLUITestConfigurationTests.swift
  - apps/ios/BuyLedgerUITests/Screens/CampaignsScreen.swift
  - apps/ios/BuyLedger/Features/Settings/AppLanguage.swift
  - apps/ios/BuyLedger/Features/AISummary/OllamaDTO.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsStats.swift
  - apps/ios/BuyLedgerUITests/Support/AppNavigator.swift
  - shared/data-model/fixtures/expected/swift/SampleReceipt.generated.swift
  - apps/ios/BuyLedgerUITests/Tests/Campaigns/CampaignDetailTests.swift
  - apps/ios/BuyLedgerTests/InsightsStatsTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/ViewModifiers/BLCardShadow.swift
  - apps/ios/README.md
  - apps/ios/BuyLedger/Core/Domain/Generated/OrderStatus.generated.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrdersToolbarContent.swift
  - shared/data-model/fixtures/expected/kotlin/SampleReceipt.kt
  - apps/ios/BuyLedgerUITests/Support/Diagnostics.swift
  - apps/ios/BuyLedger/Core/Dependencies/PaymentMethodRepository.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsStorage.swift
  - apps/ios/BuyLedger/Resources/Info.plist
  - apps/ios/BuyLedgerUITests/Support/BLUITestCase.swift
  - apps/ios/BuyLedger/Features/Orders/LedgerOrder+OrderMutation.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/ViewModifiers/BLHeroCardBackground.swift
  - shared/data-model/fixtures/expected/kotlin/SampleGrade.kt
  - apps/ios/BuyLedgerTests/AppScenePhaseCoordinatorTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewLongContentBaseline.1.png
  - apps/ios/BuyLedgerUITests/Screens/QuoteScreen.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLStatusHue.swift
  - apps/ios/BuyLedgerTests/ColorContrast.swift
  - apps/ios/BuyLedger/Core/Testing/BLUITestHarness.swift
  - apps/ios/BuyLedger/Core/Dependencies/CampaignReminderRepository.swift
  - apps/ios/BuyLedger/Features/AISummary/AISummaryFeature.swift
  - shared/data-model/fixtures/expected/swift/SampleStatus.generated.swift
  - apps/ios/BuyLedgerTests/HTTPClientTests.swift
  - shared/data-model/schema/CampaignStatus.yaml
  - apps/ios/BuyLedger.xctestplan
  - apps/ios/BuyLedger/Features/Quote/QuoteView.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLBarChart.swift
  - apps/ios/BuyLedgerTests/CampaignSummaryTests.swift
  - apps/ios/BuyLedger/Core/Persistence/ReconciliationStatusRecord.swift
  - apps/ios/BuyLedger/Features/App/AppScenePhaseCoordinator.swift
  - apps/ios/BuyLedgerUITests/Support/Scrolling.swift
  - apps/ios/BuyLedger/Core/Dependencies/BiometricAuthClient.swift
  - apps/ios/BuyLedger/Features/Orders/Components/PaymentMethodEditorSheet.swift
  - apps/ios/BuyLedger/Resources/InfoPlist.xcstrings
  - apps/ios/BuyLedger/Features/Customers/CustomerRankBadgeStyle.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OptionPickerSheet.swift
  - apps/ios/BuyLedgerTests/CampaignPersistenceTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLDonutChart.swift
  - apps/ios/BuyLedger/Core/Persistence/OrderSourcePersistence.swift
  - shared/data-model/fixtures/expected/typescript/SampleReceipt.ts
  - apps/ios/BuyLedgerTests/DashboardStatsTests.swift
  - shared/data-model/schema/CurrencyCode.yaml
  - apps/ios/BuyLedger/Core/Networking/HTTPMethod.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsFeature.swift
  - apps/ios/BuyLedgerTests/FxFeatureTests.swift
  - apps/ios/BuyLedger/Core/Persistence/OrderRecord.swift
  - apps/ios/BuyLedgerTests/SchemaMigrationTests.swift
  - apps/ios/BuyLedger/Core/Dependencies/CategoryRepository.swift
  - apps/ios/BuyLedgerTests/InsightsFeatureTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/quoteViewBaseline.1.png
  - shared/data-model/schema/PaymentReceiptStatus.yaml
  - apps/ios/BuyLedger/Features/FX/ExchangeRateDTO.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestDependencyOverrides.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLTone.swift
  - apps/ios/BuyLedger/Core/Persistence/CampaignReminderRecord.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestSeedProfile.swift
  - apps/ios/BuyLedger/Core/Domain/Campaign+Samples.swift
  - apps/ios/BuyLedger/Features/AISummary/AISummaryView.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFilterSheet.swift
  - apps/ios/BuyLedgerTests/LookupCatalogTests.swift
  - apps/ios/BuyLedgerTests/PhotoDataProcessorTests.swift
  - shared/data-model/fixtures/schema/sample-orders.yaml
  - apps/ios/BuyLedgerTests/OrderMergeTests.swift
  - apps/ios/BuyLedgerUITests/Screens/InsightsScreen.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersRegularViewMultiSelectBaseline.1.png
  - apps/ios/BuyLedger/Features/Lookups/LookupKind.swift
  - apps/ios/BuyLedger/Features/Customers/CustomersFeature.swift
  - apps/ios/BuyLedger/Features/FX/FxFeature.swift
  - apps/ios/BuyLedger/Shared/Extensions/Bundle+Extensions.swift
  - shared/data-model/generator/src/datamodel-gen.ts
  - shared/data-model/fixtures/expected/kotlin/SampleSequence.kt
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Badges/BLBadge.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupCatalog.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignDetailView.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersMergeFlowOperations.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLPalette.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderMergeTests.swift
  - apps/ios/BuyLedger/Core/Dependencies/NameLookupOperations.swift
  - apps/ios/BuyLedger/Features/Orders/OrderStatusFilter.swift
  - shared/data-model/fixtures/expected/swift/SampleGrade.generated.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/dashboardViewBaseline.1.png
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/ViewModifiers/BLTypographyModifier.swift
  - apps/ios/BuyLedgerTests/OrderStatusTests.swift
  - apps/ios/BuyLedgerAccessibilityIDs/BLAccessibilityID.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/CurrencyCode.generated.swift
  - apps/ios/BuyLedger/Core/Persistence/CampaignRecord.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignEditView.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/States/BLLoadFailureView.swift
  - apps/ios/BuyLedgerTests/CampaignEditFeatureTests.swift
  - apps/ios/BuyLedger/Resources/PrivacyInfo.xcprivacy
  - apps/ios/BuyLedgerTests/DashboardFeatureTests.swift
  - CLAUDE.md
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementView.swift
  - apps/ios/BuyLedgerUITests/Screens/RootNavigationScreen.swift
  - apps/ios/BuyLedgerTests/LocalizationCatalogTests.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersCompactView.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrdersListTests.swift
  - apps/ios/BuyLedgerUITests/Support/AlertInteraction.swift
  - shared/data-model/fixtures/expected/typescript/SampleSequence.ts
  - apps/ios/BuyLedgerUITests/Screens/Screen.swift
  - apps/ios/BuyLedgerTests/OrdersFeaturePerformanceTests.swift
  - apps/ios/BuyLedger/Core/Persistence/CampaignPersistence.swift
  - apps/ios/CLAUDE.md
  - apps/ios/BuyLedger/Features/App/PersistenceFailureView.swift
  - apps/ios/BuyLedgerTests/CalendarReminderTests.swift
  - apps/ios/BuyLedger/Core/Persistence/OrderPersistence.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLBarChartValue.swift
  - apps/ios/BuyLedgerTests/SnapshotTests.swift
  - apps/ios/BuyLedgerTests/OrdersSearchCancellationTests.swift
  - apps/ios/BuyLedger/Core/Dependencies/ReconciliationStatusRepository.swift
  - apps/ios/BuyLedgerTests/TestSuiteIntegrityTests.swift
  - shared/data-model/schema/Campaign.yaml
  - apps/ios/BuyLedger/Features/Orders/OrdersFilterOperations.swift
  - apps/ios/BuyLedger/Core/Networking/APIError.swift
  - apps/ios/BuyLedger/Core/Domain/OrderSummary.swift
  - apps/ios/BuyLedgerUITests/Screens/AISummaryScreen.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewMultiSelectBaseline.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewLongIdentifierBaseline.1.png
  - apps/ios/BuyLedger/Core/Domain/Generated/CampaignStatus.generated.swift
  - apps/ios/BuyLedgerUITests/Support/Assertions.swift
  - apps/ios/BuyLedgerUITests/Tests/Insights/InsightsTests.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/FxRateSnapshot.generated.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersView.swift
  - apps/ios/BuyLedgerTests/SettingsFeatureTests.swift
  - shared/data-model/README.md
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoViewer.swift
  - shared/data-model/fixtures/expected/kotlin/SampleProfile.kt
  - apps/ios/BuyLedger/Core/Domain/Generated/Campaign.generated.swift
  - shared/data-model/schema/LedgerCustomer.yaml
  - apps/ios/BuyLedger/Core/Domain/Generated/PaymentMethodInfo.generated.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLHeatmapDepth.swift
  - apps/ios/BuyLedger/Features/FX/FxView.swift
  - apps/ios/BuyLedgerUITests-Performance.xctestplan
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/quoteViewRateUnavailable.1.png
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Status/BLStatusPill.swift
  - apps/ios/BuyLedger/Core/Testing/BLUITestSeedProfile.swift
  - apps/ios/BuyLedgerUITests/Screens/OrderEditScreen.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignListView.swift
  - apps/ios/BuyLedgerTests/PersistenceErrorContractTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Smoke/AppLockTests.swift
  - apps/ios/BuyLedger/Core/Dependencies/TelemetryClient.swift
  - apps/ios/BuyLedger.xcodeproj/xcshareddata/xcschemes/BuyLedger.xcscheme
  - apps/ios/BuyLedgerUITests/Tests/Smoke/HarnessSelfCheckTests.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestHarness.swift
  - apps/ios/BuyLedgerTests/CampaignFeatureTests.swift
  - apps/ios/BuyLedger.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
  - apps/ios/BuyLedger/Core/Persistence/PersistenceStoreQuarantine.swift
  - apps/ios/BuyLedger/Features/App/PersistenceFailureFeature.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/States/BLDelayedProgressView.swift
  - apps/ios/BuyLedger/Core/Domain/OrderStatus.swift
  - apps/ios/BuyLedger/Features/App/RootSidebarLayout.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderRowView.swift
  - shared/data-model/schema/LedgerOrder.yaml
  - apps/ios/BuyLedgerTests/RootFeatureTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderDetailTests.swift
  - shared/data-model/fixtures/expected/swift/SampleSequence.generated.swift
  - apps/ios/BuyLedgerUITests/Screens/SettingsScreen.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/Money.generated.swift
  - README.md
  - apps/ios/BuyLedgerUITests/Screens/OrderDetailScreen.swift
  - apps/ios/BuyLedgerUITests/Tests/Smoke/LaunchSmokeTests.swift
  - apps/ios/BuyLedger/Core/Domain/CurrencyCode.swift
  - apps/ios/BuyLedger/Core/Persistence/NameLookupPersistence.swift
  - apps/ios/BuyLedger/Core/Testing/BLUITestConfiguration.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardFeature.swift
  - apps/ios/BuyLedgerUITests/Support/TextInput.swift
  - apps/ios/BuyLedger.xcodeproj/project.pbxproj
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFormatters.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderCreateTests.swift
  - apps/ios/BuyLedger/Features/Orders/OrderEditFeature.swift
  - apps/ios/BuyLedgerTests/InsightsAttributionTests.swift
  - apps/ios/BuyLedger/Core/Domain/LedgerOrderItem.swift
  - apps/ios/BuyLedgerTests/CampaignIntegrationTests.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestConfiguration.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestSeedData.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLTypography.swift
  - apps/ios/BuyLedgerTests/PrivacyManifestTests.swift
  - apps/ios/BuyLedger/Features/App/AppLockView.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/LedgerOrder.generated.swift
  - apps/ios/BuyLedgerUITests/Screens/FxScreen.swift
  - apps/ios/BuyLedgerUITests/Screens/CustomersScreen.swift
  - apps/ios/BuyLedgerUITests/Support/MenuInteraction.swift
  - apps/ios/BuyLedgerTests/OrdersFilterOperationsTests.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderMergeCandidateSheet.swift
  - apps/ios/BuyLedger/Core/Networking/ExchangeRateDTO.swift
  - apps/ios/BuyLedger/Features/Orders/OrderDatePeriod.swift
  - shared/data-model/fixtures/expected/swift/SamplePreference.generated.swift
  - apps/ios/BuyLedgerTests/BLAccessibilityIDTests.swift
  - apps/ios/BuyLedger/Core/Persistence/PersistenceStoreQuarantineClient.swift
  - AGENTS.md
  - apps/ios/BuyLedger/Core/Dependencies/OrderRepository.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/CustomerTier.generated.swift
  - apps/ios/BuyLedger/Core/Persistence/PersistenceError.swift
  - apps/ios/BuyLedgerTests/OllamaClientTests.swift
  - apps/ios/BuyLedgerUITests/Support/ValueParsing.swift
  - apps/ios/BuyLedgerUITests/Screens/CampaignDetailScreen.swift
  - apps/ios/BuyLedgerUITests/Support/LaunchOptions.swift
  - apps/ios/BuyLedger/App/AppDelegate.swift
  - apps/ios/BuyLedger/Core/Testing/BLUITestSeedData.swift
  - apps/ios/BuyLedgerTests/OrderCalculationTests.swift
  - apps/ios/BuyLedger/Core/Networking/AppConfiguration.swift
  - apps/ios/BuyLedger/Core/Networking/ExchangeRateClient.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/PaymentReceiptStatus.generated.swift
  - apps/ios/BuyLedger/Resources/GoogleService-Info.example.plist
  - apps/ios/BuyLedger/Features/Orders/OrderDetailPath.swift
  - apps/ios/BuyLedger/Core/Dependencies/CalendarReminderClient.swift
  - apps/ios/BuyLedgerTests/OrderEditFeatureTests.swift
  - apps/ios/BuyLedgerTests/ExchangeRateClientTests.swift
  - apps/ios/BuyLedgerUITests/Support/SheetInteraction.swift
  - shared/data-model/fixtures/expected/kotlin/SampleStatus.kt
  - apps/ios/BuyLedger/Features/App/RootFeature.swift
tests:
  - shared/data-model/generator/test/datamodel-gen.test.ts
-->

---
### Requirement: Load failure injection

The app SHALL accept a launch argument that makes the declared repository read fail, so that the load failure view and its retry control can be exercised. When the argument is absent, reads SHALL succeed normally. When the declared failure delays each read before failing, the delay duration SHALL be supplied by the launch options as a launch argument and the app SHALL wait at least that duration before failing; the app SHALL NOT keep its own copy of the duration, so that the UI test that sets the duration and the timeouts derived from it share a single source.

#### Scenario: Injected failure surfaces the failure view

- **WHEN** the app launches in UI test mode with the load failure argument for the orders repository
- **THEN** the orders screen shows the load failure view together with its retry control

#### Scenario: Retry after injected failure

- **WHEN** the load failure argument declares that only the first read fails and the user taps retry
- **THEN** the orders screen loads the seeded orders successfully

#### Scenario: The read delay comes from the launch options

- **GIVEN** launch options that declare delayed failing reads for the exchange rates with a delay of 8 seconds
- **WHEN** the app launches in UI test mode and the rates screen starts a read
- **THEN** the read stays loading for at least 8 seconds before it fails, and the test's waiting timeouts are computed from the same 8-second value in the launch options

##### Example: launch arguments for a delayed read

| Launch options | Arguments passed to the app | Delay applied by the app |
| -------------- | --------------------------- | ------------------------ |
| delayed failing orders reads, 8 seconds | `-BLUITestLoadFailure ordersDelayed -BLUITestReadDelaySeconds 8` | at least 8 seconds |
| delayed failing exchange rate reads, 12 seconds | `-BLUITestLoadFailure exchangeRatesDelayed -BLUITestReadDelaySeconds 12` | at least 12 seconds |
| no load failure | no delay argument | none |

#### Scenario: A delayed failure without a valid duration applies no built-in delay

- **GIVEN** a delayed failing read argument with the delay duration argument missing, or with a value that is not a positive whole number of seconds
- **WHEN** the UI test configuration parses the launch arguments
- **THEN** it prints a warning naming the delay argument, and the app applies no delay instead of a built-in duration

#### Scenario: A duration without a delayed failure is ignored

- **GIVEN** the delay duration argument while the load failure argument is absent or names a failure that does not delay
- **WHEN** the UI test configuration parses the launch arguments
- **THEN** it prints a warning that the duration has no delayed failure to apply to, and reads behave as the load failure argument alone declares


<!-- @trace
source: test-suite-convention-alignment
updated: 2026-11-15
code:
  - apps/ios/BuyLedgerTests/Features/Lookups/LookupAddFormFeatureTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Navigation/ReadableWidthUITests.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderListLoadFailureTests.swift
  - apps/ios/BuyLedgerUITests/Support/XCTestCase+Diagnostics.swift
  - apps/ios/BuyLedgerUITests/Tests/Navigation/RootNavigationScenarioUITests.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderEditRotationUITests.swift
  - apps/ios/BuyLedgerTests/Features/Lookups/LookupRenameFormFeatureTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/Edit/OrderEditAddOptionTests.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrderListFeatureCategoryPickerSyncTests.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrderPercentConversionTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Insights/InsightsLayoutUITests.swift
  - apps/ios/BuyLedgerUITests/Tests/Navigation/AdaptiveNavigationContinuityUITests.swift
  - apps/ios/BuyLedgerUITests/Support/XCTestCase+PlatformScope.swift
  - apps/ios/BuyLedgerUITests/Tests/Navigation/RootNavigationContinuityUITests.swift
  - apps/ios/BuyLedgerUITests/Tests/Smoke/RootNavigationOrientationUITests.swift
  - apps/ios/BuyLedgerUITests/Tests/Forms/SearchInputFocusUITests.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/Regular/OrdersRegularClearFiltersUITests.swift
  - apps/ios/BuyLedgerUITests/Tests/Forms/QuoteInputFocusUITests.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrderEditFeaturePhotosTests.swift
  - apps/ios/BuyLedgerUITests/Screens/Campaigns/CampaignDetailScreen.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/Edit/OrderEditDateRowTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/Filters/OrderFilterSheetLargeTests.swift
  - apps/ios/BuyLedgerUITests/Support/XCUIApplication+TextInput.swift
  - apps/ios/BuyLedgerUITests/Support/MoreDestinationIdentifiers.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrderCategoryPickerFeatureSearchTests.swift
  - apps/ios/BuyLedgerTests/Guards/UITestConvention/UITestConventionScenarios.swift
  - apps/ios/BuyLedgerUITests/Tests/Smoke/InsightsOrientationUITests.swift
  - apps/ios/BuyLedgerUITests/Tests/Smoke/DashboardOrientationUITests.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/Regular/OrdersRegularColumnWidthUITests.swift
  - apps/ios/BuyLedger/Features/Lookups/Presentation/Root/Views/LookupItemRow.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrdersLoadFailureUITests.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/Detail/OrderDetailMoreMenuUITests.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrdersNavigationUITests.swift
  - apps/ios/BuyLedgerTests/Guards/TestSuiteIntegrityTests.swift
  - apps/ios/BuyLedgerUITests/Tests/More/MoreNavigationSmokeTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/Regular/OrderRegularColumnScopeTests.swift
  - apps/ios/BuyLedgerUITests/Screens/Tools/QuoteScreen.swift
  - apps/ios/BuyLedgerUITests/Tests/Navigation/AppLockLoadFailureUITests.swift
  - apps/ios/BuyLedgerTests/App/Testing/BLUITestConfigurationInvalidValuesTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/Filters/OrderFilterSheetLargeUITests.swift
  - apps/ios/BuyLedgerUITests/Support/XCUIApplication+SheetInteraction.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrdersUITests.swift
  - apps/ios/BuyLedgerUITests/Tests/Smoke/BLUITestConfigurationUITestSupport.swift
  - apps/ios/BuyLedgerUITests/Support/CampaignSeedFixture.swift
  - apps/ios/BuyLedgerUITests/Support/XCUIApplication+MenuInteraction.swift
  - apps/ios/BuyLedgerUITests/Support/BLUITestCase.swift
  - apps/ios/BuyLedgerUITests/Support/CGRect+Validity.swift
  - apps/ios/BuyLedgerUITests/Tests/Campaigns/CampaignListTests.swift
  - apps/ios/BuyLedgerUITests/Screens/Insights/InsightsScreen.swift
  - apps/ios/BuyLedgerUITests/Tests/Forms/EditorTextInputFocusUITests.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/Edit/OrderEditDirtyUITests.swift
  - apps/ios/BuyLedgerUITests/Support/XCUIElement+TextInput.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/Edit/OrderCreateTests.swift
  - apps/ios/BuyLedgerUITests/Support/XCTestCase+Assertions.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/Regular/OrderRegularClearFiltersTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Navigation/NavigationScenarioUITests.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/Filters/OrderFilterSheetTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Navigation/SettingsLanguageUITests.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/Detail/AISummaryTests.swift
  - apps/ios/BuyLedgerUITests/Screens/Customers/CustomersScreen.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/Filters/OrderCategoryPickerLargeUITests.swift
  - apps/ios/BuyLedgerUITests/Tests/Tools/OptionPickerCurrencyUITests.swift
  - apps/ios/BuyLedgerUITests/Tests/Customers/CustomersLoadStateUITests.swift
  - apps/ios/BuyLedgerUITests/Tests/Customers/RootNavigationCustomerOrdersUITests.swift
  - apps/ios/BuyLedgerUITests/Support/XCUIElement+Waiting.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/Regular/OrdersRegularColumnScopeUITests.swift
  - apps/ios/BuyLedgerUITests/Support/OrdersSeedFixture.swift
  - apps/ios/BuyLedgerUITests/Support/LaunchOptions.swift
  - apps/ios/BuyLedgerUITests/Screens/ScreenProtocol.swift
  - apps/ios/BuyLedgerUITests/Support/XCTestCase+OrdersAssertions.swift
  - apps/ios/BuyLedgerUITests/Tests/Dashboard/DashboardLaunchLoadingTests.swift
  - apps/ios/BuyLedgerUITests/Support/XCUIApplication+SearchInteraction.swift
  - apps/ios/BuyLedgerUITests/Tests/Tools/CurrencyPickerTests.swift
  - apps/ios/BuyLedgerTests/Features/Settings/SettingsFeatureTests.swift
  - apps/ios/BuyLedgerUITests/Screens/Orders/AISummaryScreen.swift
  - apps/ios/BuyLedgerUITests/Tests/Customers/CustomersUITests.swift
  - apps/ios/BuyLedgerUITests/Support/XCTestCase+CampaignFlow.swift
  - apps/ios/BuyLedgerUITests/Tests/Insights/InsightsLayoutSmokeTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/Detail/MergeFlowUITests.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/SnapshotOrderFilterEmptyStatesTests.swift
  - apps/ios/BuyLedgerUITests/Support/UITestError.swift
  - apps/ios/BuyLedgerUITests/Tests/Campaigns/CampaignFlowTests.swift
  - apps/ios/BuyLedgerUITests/Screens/Orders/OrderCategoryPickerScreen.swift
  - apps/ios/BuyLedgerUITests/Tests/Campaigns/RootNavigationCampaignLoadFailureUITests.swift
  - apps/ios/BuyLedgerUITests/Tests/Tools/QuoteTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/Edit/OrderEditDirtyTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Navigation/OrderEditDraftRotationUITests.swift
  - apps/ios/BuyLedgerUITests/Screens/Orders/PhotoViewerScreen.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/Filters/OrderCategoryPickerUITests.swift
  - apps/ios/BuyLedgerUITests/Tests/Campaigns/CampaignsUITests.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/Regular/OrderRegularSearchBarTests.swift
  - apps/ios/CLAUDE.md
  - apps/ios/BuyLedgerUITests/Tests/Insights/InsightsLaunchLoadingTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/Detail/AISummaryUITests.swift
  - apps/ios/BuyLedgerUITests/Screens/Campaigns/CampaignsScreen.swift
  - apps/ios/BuyLedgerUITests/Tests/Forms/OrdersSearchInputFocusUITests.swift
  - apps/ios/BuyLedgerUITests/Tests/Tools/QuoteUITests.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/Detail/PhotoViewerUITests.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/Regular/OrdersRegularColumnScopeUITestSupport.swift
  - apps/ios/BuyLedgerUITests/Tests/Campaigns/CampaignEditDateRowUITests.swift
  - apps/ios/BuyLedgerTests/Features/Campaigns/CampaignEditFeatureBindingTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Navigation/LoadFailureReloadLoopTests.swift
  - apps/ios/BuyLedgerUITests/Support/XCUIElement+ValueParsing.swift
  - apps/ios/BuyLedgerUITests/Tests/Navigation/RootNavigationLoadFailureUITests.swift
  - apps/ios/BuyLedgerUITests/Tests/More/RootNavigationMoreUITests.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrdersListTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Tools/FxUITests.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/Edit/OrderEditDateRowUITests.swift
  - apps/ios/BuyLedgerUITests/Tests/Smoke/BLUITestConfigurationUITests.swift
  - apps/ios/BuyLedgerUITests/Screens/Campaigns/CampaignEditScreen.swift
  - apps/ios/BuyLedgerUITests/Screens/Orders/OrderEditScreen.swift
  - apps/ios/BuyLedgerUITests/Screens/Shared/PaymentMethodEditorScreen.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrdersNavigationSmokeTests.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrderListFeatureDestinationTests.swift
  - apps/ios/BuyLedgerTests/Guards/UITestConvention/UITestConventionScanner.swift
  - apps/ios/BuyLedgerUITests/Tests/Campaigns/CampaignEditDateRowTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Insights/InsightsUITests.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/Detail/OrderMergeTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Campaigns/CampaignEditUITests.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/Detail/PhotoViewerPagingTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Navigation/OrdersSelectionUITests.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/Edit/OrderEditAddOptionUITests.swift
  - apps/ios/BuyLedgerUITests/Tests/Insights/InsightsTests.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrderFilterFeatureQueriesTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Tools/FxTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/Edit/KeyboardDismissTests.swift
  - apps/ios/BuyLedgerUITests/Support/Polling.swift
  - apps/ios/BuyLedgerUITests/Tests/Smoke/HarnessSelfCheckTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Forms/OrderEditInputFocusUITests.swift
  - apps/ios/BuyLedgerUITests/Support/XCUIApplication+AlertInteraction.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/Detail/OrderDetailUITests.swift
  - apps/ios/BuyLedgerUITests/Tests/Smoke/OrdersOrientationUITests.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/Regular/OrderRegularColumnWidthTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Smoke/LaunchSmokeTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Tools/RootNavigationToolLoadUITests.swift
  - apps/ios/README.md
  - apps/ios/BuyLedgerUITests/Tests/Smoke/OrientationLayoutTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Tools/SettingsGoalInputUITests.swift
  - apps/ios/BuyLedgerUITests/Support/XCUIApplication+NavigationBackInteraction.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/Edit/OrderEditKeyboardDismissUITests.swift
  - apps/ios/BuyLedgerUITests/Tests/Forms/CampaignEditInputFocusUITests.swift
  - apps/ios/BuyLedgerUITests/Tests/More/OrderEditRenamedCategoryUITests.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersFeatureMergePrefillTests.swift
  - apps/ios/BuyLedgerTests/App/Testing/BLUITestConfigurationTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Smoke/AppLockTests.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/SnapshotCampaignDetailTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Forms/MergeFlowInputFocusUITests.swift
  - apps/ios/BuyLedgerUITests/Support/BoundsCheck.swift
  - apps/ios/BuyLedgerUITests/Tests/Customers/CustomersLoadStateTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Customers/CustomersTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Campaigns/CampaignCrudTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Tools/SettingsGoalInputTests.swift
  - apps/ios/BuyLedgerUITests/Support/XCUIApplication+Scrolling.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/Edit/OrderEditCreateUITests.swift
  - apps/ios/BuyLedgerUITests/Tests/Insights/InsightsLaunchLoadingUITests.swift
  - apps/ios/BuyLedgerUITests/Screens/Screen.swift
  - apps/ios/BuyLedgerUITests/Tests/Smoke/AppLockUITests.swift
  - apps/ios/BuyLedgerUITests/Tests/Tools/ToolLoadTabSwitchTests.swift
  - apps/ios/BuyLedger/Features/Lookups/Presentation/Root/Views/LookupNameEditorSheet.swift
  - apps/ios/BuyLedgerUITests/Support/XCTestCase+Orientation.swift
  - apps/ios/BuyLedgerUITests/Support/XCUIElement+CombinedText.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/SnapshotOrdersTests.swift
  - apps/ios/BuyLedgerUITests/Screens/Dashboard/DashboardScreen.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/OrderEdit/Views/Sections/OrderEditStatusSection.swift
  - apps/ios/BuyLedgerUITests/Support/XCTestCase+HorizontalBounds.swift
  - apps/ios/BuyLedgerUITests/Screens/App/RootNavigationScreen.swift
  - apps/ios/BuyLedgerUITests/Tests/Campaigns/CampaignDetailUITests.swift
  - apps/ios/BuyLedgerUITests/Support/XCUIElement+FocusTap.swift
  - apps/ios/BuyLedgerUITests/Support/XCUIApplication+NavigationBarTitle.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/Filters/OrderPaymentMethodMenuTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/Filters/OrdersPaymentMethodMenuUITests.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/Filters/OrderCategoryPickerLargeTests.swift
  - apps/ios/BuyLedger/App/Testing/Configuration/BLUITestConfiguration.swift
  - apps/ios/BuyLedgerUITests/Tests/More/LookupManagementTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/Detail/OrderDetailTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Smoke/RootNavigationOrientationUITestSupport.swift
  - apps/ios/BuyLedgerUITests/Screens/More/LookupManagementScreen.swift
  - apps/ios/BuyLedgerUITests/Screens/Orders/OrderFilterSheetScreen.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/Regular/RootNavigationRegularColumnsUITests.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/Regular/OrderRegularAccessibilitySizeTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/Filters/OrderCategoryPickerTests.swift
  - apps/ios/BuyLedgerUITests/Support/XCUIApplication+StableVisibleFrame.swift
  - apps/ios/BuyLedgerUITests/Tests/Forms/OptionPickerInputFocusUITests.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/Filters/OrderFilterSheetUITests.swift
  - apps/ios/BuyLedgerUITests/Support/XCUIApplication+Reveal.swift
  - apps/ios/BuyLedgerUITests/Screens/More/SettingsScreen.swift
  - apps/ios/BuyLedgerTests/Features/Lookups/PaymentMethodEditFormFeatureTests.swift
  - apps/ios/BuyLedgerTests/Guards/StoreConstructionSamples.swift
  - apps/ios/BuyLedgerUITests/Support/CategoryGridInteraction.swift
  - apps/ios/BuyLedgerUITests/Tests/Forms/FxInputFocusUITests.swift
  - apps/ios/BuyLedgerUITests/Tests/Navigation/OrdersAdaptiveLayoutUITests.swift
  - apps/ios/BuyLedgerUITests/Tests/Smoke/RootNavigationLaunchUITests.swift
  - apps/ios/BuyLedgerUITests/Support/AppNavigator.swift
  - apps/ios/BuyLedgerUITests/Tests/Forms/ToolsInputFocusUITests.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrderEditFeatureBindingTests.swift
  - apps/ios/BuyLedgerUITests/Screens/Shared/OptionPickerScreen.swift
  - apps/ios/BuyLedgerUITests/Screens/Tools/FxScreen.swift
  - apps/ios/BuyLedgerUITests/Support/XCTestCase+LoadStateSampling.swift
  - apps/ios/BuyLedgerUITests/Tests/More/LookupManagementUITests.swift
  - apps/ios/BuyLedgerTests/Features/Campaigns/CampaignEditFeatureTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Forms/SettingsInputFocusUITests.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/Detail/OrderDetailMenuTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/Regular/OrdersRegularSearchBarUITests.swift
  - apps/ios/BuyLedgerUITests/Tests/Dashboard/DashboardLayoutSmokeTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/Filters/OrdersUITestSupport.swift
  - apps/ios/BuyLedgerUITests/Tests/Navigation/RootNavigationReadableWidthUITests.swift
  - apps/ios/BuyLedgerUITests/Screens/Orders/OrderDetailScreen.swift
  - apps/ios/BuyLedgerUITests/Tests/Dashboard/DashboardLayoutUITests.swift
  - apps/ios/BuyLedgerUITests/Tests/Navigation/CampaignsAdaptiveLayoutUITests.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/Regular/OrdersRegularAccessibilitySizeUITests.swift
  - apps/ios/BuyLedgerUITests/Tests/Campaigns/CampaignListLoadFailureLoopTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Navigation/DashboardAdaptiveLayoutUITests.swift
  - apps/ios/BuyLedgerUITests/Tests/Dashboard/DashboardLaunchLoadingUITests.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrderEditFeatureMergeTests.swift
  - apps/ios/BuyLedgerUITests/Support/ValueParsing.swift
  - apps/ios/BuyLedgerUITests/Tests/Campaigns/CampaignDetailTests.swift
  - apps/ios/BuyLedgerUITests/Screens/App/AppLockScreen.swift
  - apps/ios/BuyLedgerUITests/Tests/Forms/LookupManagementInputFocusUITests.swift
  - apps/ios/BuyLedgerUITests/Support/XCUIApplication+Diagnostics.swift
  - apps/ios/BuyLedgerUITests/Support/XCTestCase+OrdersLayoutAssertions.swift
  - apps/ios/BuyLedgerTests/Guards/UITestConvention/UITestConventionScanTests.swift
  - apps/ios/BuyLedgerUITests/Screens/Orders/MergeFlowScreen.swift
  - apps/ios/BuyLedgerUITests/Tests/Campaigns/CampaignsProgressAccessibilityUITests.swift
  - apps/ios/BuyLedgerUITests/Screens/Orders/OrdersScreen.swift
  - apps/ios/BuyLedgerAccessibilityIDs/BLAccessibilityID+More.swift
  - apps/ios/BuyLedgerUITests/Tests/Campaigns/CampaignProgressAccessibilityTests.swift
  - apps/ios/BuyLedger/App/Testing/Overrides/DependencyValues+BLUITestOverrides.swift
-->

---
### Requirement: View animations are disabled in UI test mode

In UI test mode the app SHALL disable UIKit view animations during harness activation, before the first scene is created, unless the launch declares the keep-view-animations argument. Neither the app nor the harness SHALL re-enable view animations afterwards in that process, and the harness SHALL NOT offer any other way to re-enable them. Launches without the UI test launch argument SHALL leave view animations untouched. The guarantee covers UIKit view animations only; whether SwiftUI transitions, the keyboard or system presentations also stop is not part of it. The purpose is to keep XCUITest's wait for the app to become idle from stalling after interface changes such as rotation, while UI tests that guard presentation timing races keep the production animation path.

UI tests that verify an alert or a confirmation dialog being presented after a sheet, a confirmation dialog or an alert closes SHALL launch with the keep-view-animations argument, because those races only occur while the closing animation runs.

#### Scenario: UI test launch disables view animations

- **WHEN** the app launches with the UI test launch argument and without the keep-view-animations argument
- **THEN** view animations are disabled once, before the first scene is created, and nothing in the app turns them back on while the process runs

##### Example: UI test launch arguments

| Launch arguments | View animation switch | Notes |
| ---------------- | --------------------- | ----- |
| `-BLUITest` with any seed profile | turned off once | every UI test that does not ask to keep animations |
| `-BLUITest -BLUITestKeepViewAnimations` | not touched | presentation race tests |

#### Scenario: Launch without the UI test argument leaves view animations untouched

- **WHEN** the app launches without the UI test launch argument
- **THEN** the harness does not touch the view animation switch, including when the keep-view-animations argument appears on its own

##### Example: launches outside UI test mode

| Launch arguments | View animation switch | Notes |
| ---------------- | --------------------- | ----- |
| no launch arguments | not touched | normal use of a Debug build |
| `-BLUITestKeepViewAnimations` only | not touched | the argument has no effect outside UI test mode |
| launch from `LaunchPerformanceTests` | not touched | launch timing keeps the production animation path |

#### Scenario: Presentation race tests keep animations

- **WHEN** a UI test verifies that a failure notice appears after a confirmation dialog closes, and that the confirmation can be opened again after the notice closes
- **THEN** the test launches with the keep-view-animations argument, and it fails when the failure notice shares one presentation state with the confirmation dialog

##### Example: deletion failure followed by a second deletion

- **GIVEN** the lookup management screen launched with `-BLUITest`, `-BLUITestLookupWriteFailure` and `-BLUITestKeepViewAnimations`
- **WHEN** the user confirms deleting an item, closes the failure notice, and requests the deletion again
- **THEN** the failure notice appears after the first confirmation closes and the deletion confirmation appears again

<!-- @trace
source: ui-test-disable-view-animations
updated: 2026-11-14
code:
  - apps/ios/BuyLedgerUITests/Support/LaunchOptions.swift
  - apps/ios/BuyLedgerTests/Guards/ViewAnimationSwitchScanTests.swift
  - apps/ios/README.md
  - apps/ios/BuyLedgerTests/App/Testing/BLUITestHarnessViewAnimationTests.swift
  - apps/ios/BuyLedgerTests/App/Testing/BLUITestConfigurationTests.swift
  - apps/ios/BuyLedger/App/Testing/Configuration/BLUITestConfiguration.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestHarness.swift
  - apps/ios/BuyLedgerUITests/Tests/Campaigns/CampaignFlowTests.swift
  - apps/ios/BuyLedgerUITests/Tests/More/LookupManagementTests.swift
  - apps/ios/CLAUDE.md
-->