# ui-test-element-identity Specification

## Purpose

TBD - created by archiving change 'uitest-foundation'. Update Purpose after archive.

## Requirements

### Requirement: Accessibility identifier is the sole locator for UI tests

UI tests SHALL locate elements exclusively by accessibility identifier. UI tests SHALL NOT locate elements by displayed text, by accessibility label, or by positional index within a query result. Every element that a UI test interacts with or asserts on SHALL carry an accessibility identifier.

Where the platform provides no way to attach an identifier to a control, a positional lookup is permitted only under all of the following conditions: the lookup lives in a single shared helper rather than in test files, the ordering it relies on is fixed by an enumeration in application code, and the helper confirms the outcome by waiting for an identifier that only the intended result exposes.

#### Scenario: Locating by identifier survives a language switch

- **WHEN** the same UI test runs with the app language set to Traditional Chinese and again with the app language set to English
- **THEN** every element lookup resolves in both runs and the test passes in both runs

#### Scenario: Positional lookups are rejected

- **WHEN** a UI test needs a specific text field among several on one screen
- **THEN** it resolves that field by its own identifier rather than by its position in the text field query

#### Scenario: Tab bar items have no attachable identifier

- **WHEN** the shared navigation helper switches to a tab on the compact layout, where the platform's tab bar buttons expose no identifier
- **THEN** it selects the button by the position declared in the tab enumeration and then waits for that tab's destination root identifier, so a change in tab order fails the test instead of silently selecting the wrong tab


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
### Requirement: Identifier naming scheme

Fixed identifiers and the fixed prefixes of composed identifiers SHALL consist of two to four lower camel case ASCII segments separated by dots, in the form `feature.element` or `feature.screen.element`, optionally followed by one qualifier segment; the screen segment is omitted when the feature segment already names a single screen. The fixed parts of identifiers SHALL use only ASCII characters and SHALL NOT be localised; business keys appended to user-data rows keep their original form as specified for dynamic collections. The feature segment SHALL equal the lower camel case form of the name of the nested type that sits directly under the shared identifier namespace and contains the declaration, directly or through deeper nested types. The lower camel case form lowercases the first letter of the type name; when the name starts with several capital letters followed by a lowercase letter, all of those capitals except the last are lowercased, so `AISummary` becomes `aiSummary` and `Fx` becomes `fx`; when the name consists only of capital letters, all of them are lowercased, so `AI` becomes `ai`. The element segment SHALL name the semantic role rather than the visual appearance. Identifiers SHALL NOT encode transient state that a test can read from the element itself, such as enabled or selected.

#### Scenario: Static control identifier

- **WHEN** the orders list exposes its add-order control
- **THEN** its identifier is composed of the orders feature segment, the list screen segment, and an element segment naming the add action

#### Scenario: Disabled state is read from the element

- **WHEN** a UI test asserts that the save control is unavailable
- **THEN** it reads the element's enabled state rather than looking up a different identifier

#### Scenario: Feature segment follows the declaring nested type

- **GIVEN** an identifier is declared inside the nested type `AISummary` of the shared identifier namespace
- **WHEN** its value is checked against the naming scheme
- **THEN** its first segment is `aiSummary`

#### Scenario: Segment shape is checked for fixed values and fixed prefixes

- **WHEN** a fixed identifier or the fixed prefix of a composed identifier is checked against the naming scheme
- **THEN** it passes only if it has two to four dot-separated segments, each starting with a lowercase letter followed by letters or digits, and its first segment matches the declaring nested type

##### Example: shapes of fixed values and fixed prefixes

Each value below is a string literal written in the shared namespace; identifiers composed at run time by `row` keep their colon and business key and are not checked against this table.

| Fixed value or fixed prefix | Declared in | Result | Notes |
| --------------------------- | ----------- | ------ | ----- |
| fixed `fx.root` | `Fx` | passes | feature and element |
| fixed `orders.list.addButton` | `Orders` | passes | feature, screen, element |
| fixed `orders.list.paymentMethodMenu.all` | `Orders` | passes | qualifier segment |
| `option` prefix `orders.list.paymentMethodMenu.option` | `Orders` | passes | the appended key is not counted |
| fixed `orders` | `Orders` | fails | one segment |
| fixed `orders.list.a.b.c` | `Orders` | fails | five segments |
| fixed `orders.list.row:ORD-1` | `Orders` | fails | a colon is only produced by `row` at run time |
| fixed `Orders.listRoot` | `Orders` | fails | segment starts with a capital letter and differs from the declaring type |
| fixed `order.list.root` | `Orders` | fails | first segment differs from the declaring type |
| fixed `BackButton` | `Common` | fails | a platform-assigned identifier does not belong in the shared namespace |


<!-- @trace
source: accessibility-identifier-scan-guard
updated: 2026-11-13
code:
  - apps/ios/BuyLedgerTests/Guards/AccessibilityIdentifier/AccessibilityIdentifierRules.swift
  - apps/ios/BuyLedgerTests/Guards/AccessibilityIdentifier/AccessibilityIdentifierScanTests.swift
  - apps/ios/BuyLedgerUITests/Screens/Campaigns/CampaignDetailScreen.swift
  - apps/ios/BuyLedgerTests/AccessibilityIDs/BLAccessibilityIDTests.swift
  - apps/ios/BuyLedgerUITests/Tests/More/MoreNavigationSmokeTests.swift
  - apps/ios/BuyLedgerTests/Guards/AccessibilityIdentifier/AccessibilityIdentifierScanCases.swift
  - apps/ios/BuyLedgerTests/Guards/AccessibilityIdentifier/AccessibilityIdentifierLocationChecker.swift
  - apps/ios/BuyLedgerTests/Guards/AccessibilityIdentifier/AccessibilityIdentifierDeclarationParser.swift
  - apps/ios/BuyLedgerUITests/Screens/Orders/PhotoViewerScreen.swift
  - apps/ios/BuyLedgerUITests/Screens/Shared/OptionPickerScreen.swift
  - apps/ios/README.md
  - apps/ios/BuyLedgerTests/Guards/AccessibilityIdentifier/AccessibilityIdentifierScanner.swift
  - apps/ios/BuyLedgerUITests/Support/XCUIApplication+NavigationBackInteraction.swift
  - apps/ios/BuyLedgerUITests/Support/XCUIApplication+TextInput.swift
  - apps/ios/BuyLedgerTests/Guards/AccessibilityIdentifier/AccessibilityIdentifierSystemLiteralChecker.swift
  - apps/ios/BuyLedgerUITests/Tests/Navigation/NavigationScenarioUITests.swift
  - apps/ios/BuyLedgerTests/Guards/AccessibilityIdentifier/AccessibilityIdentifierDeclaration.swift
  - apps/ios/BuyLedgerAccessibilityIDs/BLAccessibilityID+More.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/Regular/OrderRegularColumnScopeTests.swift
  - apps/ios/BuyLedgerAccessibilityIDs/BLAccessibilityID+Common.swift
  - apps/ios/BuyLedgerTests/Guards/AccessibilityIdentifier/AccessibilityIdentifierSourceModel.swift
  - apps/ios/BuyLedgerUITests/Screens/More/SettingsScreen.swift
  - apps/ios/BuyLedgerUITests/Support/SystemAccessibilityID.swift
  - apps/ios/BuyLedgerUITests/Support/AppNavigator.swift
-->

---
### Requirement: Identifiers for dynamic collections

Rows and cells produced from collections SHALL carry identifiers built from a stable key rather than from displayed text or from an unstable position. Enumeration-backed collections SHALL use the case's raw value. Rows backed by user data SHALL append the business key to a fixed prefix, separated by a colon, with the business key kept in its original unlocalised form. Purely ordinal collections SHALL append the zero-based position to a fixed prefix.

#### Scenario: Enumeration-backed chip

- **WHEN** the orders list renders the status filter chip for the shipping status
- **THEN** the chip's identifier ends with the shipping case's raw value

##### Example: identifier shapes by collection kind

| Collection kind | Element | Identifier shape |
| --------------- | ------- | ---------------- |
| Enumeration-backed | Status filter chip for shipping | `orders.list.statusChip.shipping` |
| User-data row | Order row for order `ORD-2026-0007` | `orders.list.row:ORD-2026-0007` |
| Ordinal collection | Third photo thumbnail in the edit form | `orderEdit.photo.thumbnail.index.2` |

#### Scenario: User-data row keeps its key unlocalised

- **WHEN** the app language is switched to English and the orders list re-renders
- **THEN** each order row's identifier is unchanged because the business key is not translated

#### Scenario: Ordinal collection uses position

- **WHEN** the order edit form renders three photo thumbnails
- **THEN** their identifiers end with positions zero, one, and two respectively


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
### Requirement: Identifier coverage categories

The following categories SHALL carry identifiers: controls without visible text, screen root containers, sheet root containers, alerts together with each of their buttons, empty-state containers, loading containers, load-failure containers together with their retry control, filter chips, rows that merge their children into a single accessibility element, and chart containers together with their primary value element. Navigation bars SHALL NOT be given identifiers, because a SwiftUI navigation bar is not the container the identifier modifier applies to; UI tests SHALL reach a navigation bar through the navigation bar query and confirm the screen through its root identifier instead.

#### Scenario: Icon-only control is reachable

- **WHEN** a toolbar exposes a control whose label is only a symbol
- **THEN** that control carries an identifier and a UI test can activate it without referring to any text

#### Scenario: Merged row exposes its key value

- **WHEN** a list row merges its children into one accessibility element
- **THEN** the row container carries an identifier and also exposes its primary value as that element's accessibility value, so the value can be asserted without splitting the row into separate elements

#### Scenario: Merging is not weakened for testability

- **WHEN** a row already merges its children into a single spoken unit
- **THEN** that merging is preserved, and the row is made testable by adding an identifier and an accessibility value rather than by un-merging its children

#### Scenario: Alert buttons are addressable

- **WHEN** a destructive confirmation alert is presented
- **THEN** the alert container, its confirming button, and its cancelling button each carry an identifier


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
### Requirement: Single source of identifier constants

Identifiers that the app assigns SHALL be declared exactly once in a shared constant namespace that both the app target and the UI test target compile. Identifiers that the platform assigns and the app cannot rename SHALL NOT be declared in that shared namespace; they SHALL be declared exactly once in the UI test support layer. Application code and test code SHALL reference the constants and SHALL NOT write identifier string literals inline.

#### Scenario: Both targets reference the same declaration

- **WHEN** an identifier constant's value is changed
- **THEN** the application code that sets it and the test code that queries it both observe the new value without any other edit

#### Scenario: Inline literals are rejected

- **WHEN** a screen needs a new identifier
- **THEN** the identifier is added to the shared namespace first and both sides reference it by name

#### Scenario: Platform-assigned identifiers stay on the test side

- **WHEN** a UI test needs the identifier that the platform gives the navigation back button, a sidebar toggle, or a popover dismiss region
- **THEN** it references the single declaration in the UI test support layer, and the shared namespace contains no declaration of that value

##### Example: platform-assigned identifier written inline

- **GIVEN** the UI test support file declares `static let backButton = "BackButton"`, and another UI test file writes `app.buttons["BackButton"]`
- **WHEN** the guard runs
- **THEN** it reports that file and line, naming `SystemAccessibilityID.backButton`; a comment or a longer message string that merely mentions `BackButton` is not reported


<!-- @trace
source: accessibility-identifier-scan-guard
updated: 2026-11-13
code:
  - apps/ios/BuyLedgerTests/Guards/AccessibilityIdentifier/AccessibilityIdentifierRules.swift
  - apps/ios/BuyLedgerTests/Guards/AccessibilityIdentifier/AccessibilityIdentifierScanTests.swift
  - apps/ios/BuyLedgerUITests/Screens/Campaigns/CampaignDetailScreen.swift
  - apps/ios/BuyLedgerTests/AccessibilityIDs/BLAccessibilityIDTests.swift
  - apps/ios/BuyLedgerUITests/Tests/More/MoreNavigationSmokeTests.swift
  - apps/ios/BuyLedgerTests/Guards/AccessibilityIdentifier/AccessibilityIdentifierScanCases.swift
  - apps/ios/BuyLedgerTests/Guards/AccessibilityIdentifier/AccessibilityIdentifierLocationChecker.swift
  - apps/ios/BuyLedgerTests/Guards/AccessibilityIdentifier/AccessibilityIdentifierDeclarationParser.swift
  - apps/ios/BuyLedgerUITests/Screens/Orders/PhotoViewerScreen.swift
  - apps/ios/BuyLedgerUITests/Screens/Shared/OptionPickerScreen.swift
  - apps/ios/README.md
  - apps/ios/BuyLedgerTests/Guards/AccessibilityIdentifier/AccessibilityIdentifierScanner.swift
  - apps/ios/BuyLedgerUITests/Support/XCUIApplication+NavigationBackInteraction.swift
  - apps/ios/BuyLedgerUITests/Support/XCUIApplication+TextInput.swift
  - apps/ios/BuyLedgerTests/Guards/AccessibilityIdentifier/AccessibilityIdentifierSystemLiteralChecker.swift
  - apps/ios/BuyLedgerUITests/Tests/Navigation/NavigationScenarioUITests.swift
  - apps/ios/BuyLedgerTests/Guards/AccessibilityIdentifier/AccessibilityIdentifierDeclaration.swift
  - apps/ios/BuyLedgerAccessibilityIDs/BLAccessibilityID+More.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/Regular/OrderRegularColumnScopeTests.swift
  - apps/ios/BuyLedgerAccessibilityIDs/BLAccessibilityID+Common.swift
  - apps/ios/BuyLedgerTests/Guards/AccessibilityIdentifier/AccessibilityIdentifierSourceModel.swift
  - apps/ios/BuyLedgerUITests/Screens/More/SettingsScreen.swift
  - apps/ios/BuyLedgerUITests/Support/SystemAccessibilityID.swift
  - apps/ios/BuyLedgerUITests/Support/AppNavigator.swift
-->

---
### Requirement: Selection state is exposed to assistive technology

Controls whose selected state is conveyed only by colour SHALL additionally expose the selected accessibility trait, so that UI tests can assert selection without inspecting appearance.

#### Scenario: Selected filter chip is detectable

- **WHEN** the user selects a status filter chip
- **THEN** that chip reports the selected trait and the previously selected chip does not

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
### Requirement: Identifier definitions are verified by a source scan

A guard SHALL scan the source files of the shared identifier namespace and SHALL derive the identifiers it checks from that scan rather than from a hand-maintained list, so that an identifier added later is checked without editing the guard. The query prefix of a composed identifier is its fixed prefix followed by the separator that its composing helper (`option`, `row`, or `indexed`) inserts before the variable segment; UI tests obtain the same value when they call the identifier function with an empty key. The guard SHALL fail and name the offending declaration when any of the following holds:

- A declaration in the namespace is not one of the accepted forms: a constant whose value is exactly one complete string literal without interpolation; a function that returns `String` and whose body is exactly one call to a composing helper, with a string literal prefix and a variable segment that contains no string literal, where, when the call is unqualified, neither the function's parameters nor the declaring nested type (including deeper nested types and its extensions) declare a name equal to the called helper; one of the three composing helpers, each declared once, returning `String`, whose body is exactly its single-line composing template; or a nested enumeration that conforms to nothing other than `String` and `Sendable` and whose cases assign no raw value. A nested type named like the shared namespace is rejected. Any other declaration, and any string literal in any other position, is rejected.
- The app target or the UI test target, outside the namespace directory, declares an enumeration, structure, class, actor, protocol, or type alias named like the shared namespace, or names the shared namespace in an extension header (up to its opening brace) or on the right-hand side of a type alias declaration; a right-hand side continues onto a following line only inside brackets or across a `.`. Other forms of indirection are not detected by this guard and are left to review.
- A source file of the app target or the UI test target, other than the UI test support file that declares the platform-assigned identifiers, contains a string literal equal to one of those identifiers; the guard derives the identifiers from that support file.
- A fixed identifier or a fixed prefix violates the naming scheme.
- A fixed identifier or a fixed prefix contains a non-ASCII character.
- Two fixed identifiers have the same value, or two fixed prefixes have the same value regardless of which composing helper they are passed to.
- A fixed identifier begins with a query prefix, or one query prefix begins with another.
- The scan finds no source file, no fixed identifier, or no composed prefix; a scanned directory outside the namespace yields no source file; or the support file of platform-assigned identifiers is missing or declares none.

Each failure condition SHALL be demonstrated by a test that runs the guard on synthetic source and observes that the guard reports it.

#### Scenario: A duplicate value is rejected

- **WHEN** two fixed identifiers, or two fixed prefixes, have the same value
- **THEN** the guard fails and names both declarations

##### Example: duplicate values

| First declaration | Second declaration | Result |
| ----------------- | ------------------ | ------ |
| fixed `orders.list.root` | fixed `orders.list.root` | fails |
| `option` prefix `orders.list.chip` | `row` prefix `orders.list.chip` | fails |
| fixed `orders.list.chip` | `option` prefix `orders.list.chip` | passes, because prefix queries use the query prefix `orders.list.chip.` |

#### Scenario: Overlapping query prefixes are rejected

- **WHEN** a fixed identifier begins with a query prefix, or one query prefix begins with another
- **THEN** the guard fails, because a prefix query issued by UI tests would also match those elements

##### Example: values checked against query prefixes

| Query prefix | Other value | Result |
| ------------ | ----------- | ------ |
| `orders.list.row:` from `row` | fixed `orders.list.row:summary` | fails |
| `orders.list.statusChip.` from `option` | fixed `orders.list.statusChip.all` | fails |
| `orderEdit.photoThumbnail.index.` from `indexed` | fixed `orderEdit.photoThumbnail.index.0` | fails |
| `orders.filter.category.` from `option` | query prefix `orders.filter.category.group.` from `option` | fails |
| `orderEdit.photoThumbnail.index.` from `indexed` | query prefix `orderEdit.photoThumbnail.index.` from `option` with prefix `orderEdit.photoThumbnail.index` | fails |
| `orders.filter.category.` from `option` | query prefix `orders.filter.categoryGroup.` from `option` | passes |
| `orders.list.row:` from `row` | fixed `orders.list.root` | passes |

#### Scenario: Declarations outside the accepted forms are rejected

- **WHEN** the namespace contains a declaration that is not one of the accepted forms
- **THEN** the guard fails and names that declaration

##### Example: declarations checked for definition form

| Declaration | Result |
| ----------- | ------ |
| `static let loading = "dashboard.loading"` | passes |
| `static let loading: String = "dashboard.loading"` | passes |
| `static let loading =` followed by `"dashboard.loading"` on the next line | passes |
| `static let loading = "dashboard.loading" // shown while loading` | passes |
| `static func row(orderID: String) -> String { BLAccessibilityID.row("orders.list.row", key: orderID) }` | passes |
| the same function with the call split so that each argument is on its own line | passes |
| `static let loading = "dashboard.\("loading")"` | fails |
| `static let loading = prefix + ".loading"` | fails |
| `static var legacyRoot: String { listRoot }` | fails |
| `static func chip(_ key: String) -> String { statusChip(key) }` | fails |
| `static func detailRow(_ id: String) -> String { detailRoot + id }` | fails |
| `static func chip(_ key: String) -> String { option(chipPrefix, key: key) }` | fails |
| `case shipping = "shipping"` inside a nested enumeration | fails |
| `enum Kind: String, CaseIterable` holding only plain cases | fails |
| `static func row(orderID: String) async throws -> String? { BLAccessibilityID.row("orders.list.row", key: orderID) }` | fails |
| inside `Orders`, `static func chip(_ key: String) -> String { option("orders.list.chip", key: key) }` while `Orders` also declares a function named `option` | fails |
| a composing helper whose body adds a second literal next to its template | fails |

#### Scenario: A declaration outside the namespace directory is rejected

- **WHEN** a source file of the app target or the UI test target outside the namespace directory declares a type named `BLAccessibilityID`, or names it in an extension header or on the right-hand side of a type alias declaration
- **THEN** the guard fails and names that file, because identifiers added there would not be scanned

#### Scenario: A non-ASCII value is rejected

- **WHEN** a fixed identifier contains a non-ASCII character
- **THEN** the guard fails and names that declaration

##### Example: non-ASCII value

- **GIVEN** the nested type `Orders` declares `static let cafeRow = "orders.list.café"`
- **WHEN** the guard runs
- **THEN** it reports an ASCII violation for `Orders.cafeRow`

#### Scenario: An empty scan does not pass

- **WHEN** the scan finds no source file, or finds no fixed identifier, or finds no composed prefix
- **THEN** the guard fails instead of reporting that no violation was found

#### Scenario: Each rule is shown to fail

- **WHEN** the guard runs on synthetic source that breaks one failure condition
- **THEN** it reports that condition and names the declaration that breaks it

<!-- @trace
source: accessibility-identifier-scan-guard
updated: 2026-11-13
code:
  - apps/ios/BuyLedgerTests/Guards/AccessibilityIdentifier/AccessibilityIdentifierRules.swift
  - apps/ios/BuyLedgerTests/Guards/AccessibilityIdentifier/AccessibilityIdentifierScanTests.swift
  - apps/ios/BuyLedgerUITests/Screens/Campaigns/CampaignDetailScreen.swift
  - apps/ios/BuyLedgerTests/AccessibilityIDs/BLAccessibilityIDTests.swift
  - apps/ios/BuyLedgerUITests/Tests/More/MoreNavigationSmokeTests.swift
  - apps/ios/BuyLedgerTests/Guards/AccessibilityIdentifier/AccessibilityIdentifierScanCases.swift
  - apps/ios/BuyLedgerTests/Guards/AccessibilityIdentifier/AccessibilityIdentifierLocationChecker.swift
  - apps/ios/BuyLedgerTests/Guards/AccessibilityIdentifier/AccessibilityIdentifierDeclarationParser.swift
  - apps/ios/BuyLedgerUITests/Screens/Orders/PhotoViewerScreen.swift
  - apps/ios/BuyLedgerUITests/Screens/Shared/OptionPickerScreen.swift
  - apps/ios/README.md
  - apps/ios/BuyLedgerTests/Guards/AccessibilityIdentifier/AccessibilityIdentifierScanner.swift
  - apps/ios/BuyLedgerUITests/Support/XCUIApplication+NavigationBackInteraction.swift
  - apps/ios/BuyLedgerUITests/Support/XCUIApplication+TextInput.swift
  - apps/ios/BuyLedgerTests/Guards/AccessibilityIdentifier/AccessibilityIdentifierSystemLiteralChecker.swift
  - apps/ios/BuyLedgerUITests/Tests/Navigation/NavigationScenarioUITests.swift
  - apps/ios/BuyLedgerTests/Guards/AccessibilityIdentifier/AccessibilityIdentifierDeclaration.swift
  - apps/ios/BuyLedgerAccessibilityIDs/BLAccessibilityID+More.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/Regular/OrderRegularColumnScopeTests.swift
  - apps/ios/BuyLedgerAccessibilityIDs/BLAccessibilityID+Common.swift
  - apps/ios/BuyLedgerTests/Guards/AccessibilityIdentifier/AccessibilityIdentifierSourceModel.swift
  - apps/ios/BuyLedgerUITests/Screens/More/SettingsScreen.swift
  - apps/ios/BuyLedgerUITests/Support/SystemAccessibilityID.swift
  - apps/ios/BuyLedgerUITests/Support/AppNavigator.swift
-->