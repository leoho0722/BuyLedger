# ui-test-element-identity Specification

## Purpose

TBD - created by archiving change 'uitest-foundation'. Update Purpose after archive.

## Requirements

### Requirement: Accessibility identifier is the sole locator for UI tests

UI tests SHALL locate app content exclusively by accessibility identifier. UI tests SHALL NOT locate app content or system controls by displayed text, by accessibility label, or by positional index within a query result. Checking whether a system container (alert, keyboard, window, tab bar, status bar, navigation bar) is present and reading its frame do not locate app content and are permitted in test files; reading a navigation bar's title still goes through the shared helper. Every element that a UI test interacts with or asserts on SHALL carry an accessibility identifier, and a control that the app itself can tag, including a button inside a custom alert, SHALL be tagged and located by its identifier. Locating an element and comparing its content are separate: once an element is located by identifier, a test SHALL compare its content against a literal written for the plan's locked language. Where the app exposes the state under test as the accessibility value of a row whose children are combined into one accessibility element, the test SHALL read that value rather than search the row's label for a substring.

Where no identifier can be attached, a lookup by text, label or position is permitted only as one of the following controlled exceptions, and each exception SHALL live in a single shared helper of the support layer or a page object rather than in test files:

- An interacting lookup of system or framework UI that carries no identifier, such as root tab buttons that expose none of the root tab identifiers, segmented control options, options of an inline picker inside a menu, alert buttons built by the reducer's alert state, a text field inside a custom alert, the search field and its built-in clear button, the search field's system end button, system keyboard keys and candidates, and the sheet grabber. When the lookup is positional, the ordering it relies on SHALL be fixed by an enumeration in application code. The helper SHALL confirm the outcome by waiting for an identifier that only the intended result exposes, by the disappearance of the system control it activated, or by reading back the state the action changed through an element located by identifier (its value or frame).
- A read-only lookup that does not interact, such as the title of a navigation bar, the message text of an alert built by the reducer's alert state, whether a system keyboard key or an interactive search field is present, and sampling elements by position to measure frames. The helper SHALL NOT tap or type through such a lookup.
- A row whose identifier is keyed by a value generated at run time, located by the identifier prefix together with user-entered text the row displays, because user-entered text does not change with the app language.

#### Scenario: Locating by identifier survives a language switch

- **WHEN** the same UI test runs with the app language set to Traditional Chinese and again with the app language set to English
- **THEN** every lookup by identifier resolves in both runs; lookups made through a controlled exception are not covered by this scenario

#### Scenario: Positional lookups are rejected

- **WHEN** a UI test needs a specific text field among several on one screen
- **THEN** it resolves that field by its own identifier rather than by its position in the text field query

#### Scenario: Tab bar items have no attachable identifier

- **WHEN** the shared navigation helper switches to a tab on a layout where the platform's tab bar buttons expose none of the root tab identifiers
- **THEN** it selects the button by the position declared in the tab enumeration and then waits for that tab's destination root identifier, so a change in tab order fails the test instead of silently selecting the wrong tab

#### Scenario: The currency of a new order is read from the row's value

- **GIVEN** a new order whose default currency is Japanese yen
- **WHEN** a test checks the currency row of the order editor
- **THEN** the row located by its identifier exposes the ISO currency code `JPY` as its accessibility value, and the test compares that value

#### Scenario: A payment method category is read from the row's value

- **GIVEN** a payment method row in the lookup management list whose cash on delivery category was just enabled
- **WHEN** a test checks that the category badge is shown
- **THEN** the row located by its identifier exposes the enabled category names as its accessibility value, and the test compares the whole value instead of searching the row label for the badge text

#### Scenario: The order shown in the detail is read from the detail root

- **WHEN** a test checks which order the order detail shows
- **THEN** it reads the order identifier that the detail root exposes as its accessibility value, rather than searching the detail's texts for the order number

#### Scenario: A custom alert button is located by its identifier

- **GIVEN** the discard confirmation that the lookup name editor presents through a custom alert
- **WHEN** a test chooses to keep editing or to discard the changes
- **THEN** it activates the button by the identifier the app attached to it, not by its title

#### Scenario: A navigation bar title is read through a shared helper

- **WHEN** a test checks that the regular orders list column shows its fixed title, or that a navigation bar shows a dynamic title such as the selection count
- **THEN** it reads the title through a shared helper that looks up the navigation bar title without interacting with it, and no navigation bar title lookup appears in the test file

#### Scenario: A system container check stays in the test

- **WHEN** a test checks that the keyboard is shown, that an alert is presented, or measures the window frame
- **THEN** it queries the system container directly or through an existing support helper, and this does not count as locating app content


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