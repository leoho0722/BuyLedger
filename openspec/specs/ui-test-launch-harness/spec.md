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

The app SHALL accept a seed profile name as a launch argument and SHALL populate the in-memory store with the fixed data set that the profile declares. Every seeded date SHALL be derived from the injected reference time rather than from the system clock, so the same profile yields structurally identical data on any calendar day. An unknown or absent profile name SHALL be treated as the empty profile.

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

In UI test mode the app SHALL replace the photo import, calendar reminder, and exchange rate dependencies with doubles that never present system UI and never perform network requests. The calendar double's authorisation outcome SHALL be selectable through a launch argument.

#### Scenario: Photo import does not present the system picker

- **WHEN** the user taps the add-photos control in UI test mode
- **THEN** the built-in test images are attached directly and no out-of-process picker appears

#### Scenario: Calendar reminder does not prompt for permission

- **WHEN** the user saves a campaign with a reminder in UI test mode
- **THEN** no system permission dialog appears and no event is written to the device calendar

#### Scenario: Calendar authorisation denial is selectable

- **WHEN** the app launches in UI test mode with the calendar denial argument and the user saves a campaign with a reminder
- **THEN** the app shows its permission-denied handling without presenting a system dialog

#### Scenario: Exchange rates are fixed and offline

- **WHEN** the exchange rate screen loads in UI test mode
- **THEN** it displays the fixed rate snapshot declared by the double and performs no network request


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
### Requirement: Load failure injection

The app SHALL accept a launch argument that makes the declared repository read fail, so that the load failure view and its retry control can be exercised. When the argument is absent, reads SHALL succeed normally.

#### Scenario: Injected failure surfaces the failure view

- **WHEN** the app launches in UI test mode with the load failure argument for the orders repository
- **THEN** the orders screen shows the load failure view together with its retry control

#### Scenario: Retry after injected failure

- **WHEN** the load failure argument declares that only the first read fails and the user taps retry
- **THEN** the orders screen loads the seeded orders successfully

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