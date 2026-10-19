# order-filter-sheet Specification

## Purpose

TBD - created by archiving change 'orders-unified-filter-sheet'. Update Purpose after archive.

## Requirements

### Requirement: Unified filter sheet on iPhone Compact

On iPhone Compact size class, the orders list SHALL replace the separate date-period chip row and category filter trigger with a single unified filter trigger button. The trigger button SHALL open a unified filter sheet that hosts the date-period, payment-method, and category selections in one place. The status filter chip row SHALL remain unchanged above the trigger so that status selection retains its single-tap behavior.

The unified filter trigger button SHALL:
1. Render as a single capsule-shaped button that occupies the full available horizontal width of the orders filter area, with its left and right edges aligned to the search field above it.
2. Display a leading filter icon (the SF Symbol `line.3.horizontal.decrease` or an equivalent filter glyph).
3. Display a text label of the form `篩選：<summary>`, where `<summary>` joins, with ` · `, the committed date period when it is not "all time", the committed category part when at least one category is selected, and the committed payment method when one is selected; when none of them is active the summary is `全部`. The category part SHALL be the category name when exactly one category is selected, and `<N> 項類別` when N ≥ 2 categories are selected. The text segment SHALL support multi-line wrapping when the summary exceeds the available single-line width — the capsule SHALL grow vertically to fit the wrapped text rather than truncating it.
4. Display a trailing chevron-down indicator that communicates the control opens a sheet.
5. Apply a filled capsule background whose fill style indicates whether any non-default filter is currently applied. The active-selection style SHALL be applied when the date period is anything other than "all time", when at least one category is selected, or when a payment method is selected; the inactive-selection style SHALL be applied otherwise.

When the label wraps to multiple lines, the leading filter icon and the trailing chevron-down icon SHALL align to the first text baseline rather than the vertical center of the capsule.

The trigger SHALL be rendered regardless of whether the available categories list is empty — the trigger continues to expose the date and payment-method filters even when no categories exist.

#### Scenario: Trigger label summarizes the active filters

- **GIVEN** the orders list on iPhone Compact has at least one available category
- **WHEN** the trigger label is computed for the current filter state
- **THEN** the label reads `篩選：<summary>` where `<summary>` follows the rules below

##### Example: summary under different filter combinations

| Date period | Selected categories | Payment method | Summary | Capsule fill |
| --- | --- | --- | --- | --- |
| `.all` | none | none | `全部` | inactive |
| `.all` | {"美妝"} | none | `美妝` | active |
| `.thisMonth` | none | none | `本月` | active |
| `.thisMonth` | {"美妝"} | none | `本月 · 美妝` | active |
| `.thisMonth` | {"美妝", "書籍"} | none | `本月 · 2 項類別` | active |
| `.lastMonth` | {"3C"} | "信用卡" | `上月 · 3C · 信用卡` | active |
| `.all` | none | "現金" | `現金` | active |

#### Scenario: Tapping the trigger opens the unified filter sheet

- **WHEN** the user taps the unified filter trigger button on iPhone Compact
- **THEN** a sheet is presented with a navigation title `篩選`
- **AND** the sheet's medium detent is the default presentation size
- **AND** the sheet allows expansion to the large detent
- **AND** the sheet displays a drag indicator
- **AND** the sheet contains a leading cancellation control in its toolbar

#### Scenario: Trigger remains visible when no categories exist

- **GIVEN** the orders list on iPhone Compact has no available categories
- **WHEN** the orders list is displayed
- **THEN** the unified filter trigger button is still rendered
- **AND** the trigger label and capsule fill follow the same rules based on the active date period and payment method


<!-- @trace
source: order-filter-sheet-redesign
updated: 2026-10-19
code:
  - apps/ios/BuyLedgerTests/OrdersContainerPlanTests+Categories.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+ClearFilterPresentation.swift
  - apps/ios/BuyLedgerTests/OrdersFeaturePerformanceTests+FilterSheet.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+CategoryPickerRoot.swift
  - apps/ios/BuyLedgerTests/OrderCategoryPickerFeatureTests+Dismissal.swift
  - apps/ios/BuyLedgerTests/OrderCategoryPickerFeatureTests+Groups.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+DetailNavigation.swift
  - apps/ios/BuyLedgerUITests/Support/LaunchOptions.swift
  - apps/ios/CLAUDE.md
  - apps/ios/BuyLedgerTests/OrderCategoryGroupsTests+Expansion.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFilterPreviewFixtures.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrderFilterEmptyStates/orderCategoryPickerSheet_搜尋無符合類別_符合基準圖.1.png
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderFilterSheetTests+Assertions.swift
  - apps/ios/BuyLedgerTests/CampaignIntegrationTests.swift
  - apps/ios/BuyLedgerTests/OrderCategoryGridTests.swift
  - apps/ios/BuyLedgerTests/OrderEditFeatureTests+Campaigns.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+FilterLabels.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+FilterSummary.swift
  - apps/ios/BuyLedgerTests/BLUITestSeedDataTests+CategoryFilter.swift
  - apps/ios/BuyLedger/Features/Orders/OrderFilterSelection.swift
  - apps/ios/BuyLedgerTests/OrderFilterFeatureTests+Categories.swift
  - apps/ios/BuyLedgerTests/OrderFilterFeatureTests+Clear.swift
  - apps/ios/BuyLedgerUITests/Screens/OrdersScreen+CategoryPicker.swift
  - apps/ios/BuyLedgerTests/CampaignIntegrationTests+Fixtures.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFilterSheet.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+CategoryPicker.swift
  - apps/ios/BuyLedgerTests/ProjectionWriteBoundaryTests+Orders.swift
  - apps/ios/BuyLedgerTests/OrderCategoryPickerFeatureTests+Selection.swift
  - apps/ios/BuyLedgerUITests/Support/AppNavigator.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersView.swift
  - apps/ios/BuyLedgerTests/OrdersFilterOperationsTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderFilterSheetLargeTests.swift
  - apps/ios/BuyLedgerTests/SnapshotTests+OrderFilterEmptyStates.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFilterDateSection.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFilterPaymentMethodSection.swift
  - apps/ios/BuyLedger/Features/Orders/OrderCategoryGroups.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrderFilterEmptyStates/ordersView_寬版無付款方式與類別_符合基準圖.1.png
  - apps/ios/BuyLedger/Features/Orders/Components/OrderCategoryGrid.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderRegularClearFiltersTests.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+DeepLinks.swift
  - apps/ios/BuyLedgerUITests/Screens/OrdersScreen+FilterSheet.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersFeature.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestSeedProfile.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersListQuery.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+Selection.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Orders/ordersView_大尺寸iPhone橫向_顯示單欄清單與整合篩選鈕.1.png
  - apps/ios/BuyLedgerUITests/Screens/OrdersScreen+RegularFilters.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+OrderFilters.swift
  - apps/ios/BuyLedger/Features/Orders/OrderFilterFeature.swift
  - apps/ios/BuyLedger/Features/Orders/OrderFilterConfirmations.swift
  - apps/ios/BuyLedgerUITests/Screens/OrdersScreen+CategoryReveal.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrderCategoryGrid/orderCategoryGrid_長名稱同列等高_符合基準圖.1.png
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Chips/BLFilterChip.swift
  - apps/ios/BuyLedgerTests/OrderCategoryGroupsTests+Display.swift
  - apps/ios/BuyLedgerTests/OrderFilterFeatureTests+Queries.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+FilterPending.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Orders/ordersView_寬版多選模式_顯示選取列.1.png
  - apps/ios/BuyLedger/Features/App/RootFeature.swift
  - apps/ios/BuyLedgerTests/OrdersFeaturePerformanceTests.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+CategoryPickerSync.swift
  - apps/ios/BuyLedgerTests/ProjectionWriteBoundaryTests+Patterns.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestSeedData+CategoryFilter.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrderCategoryGrid/orderCategoryGrid_無障礙字級單欄_符合基準圖.1.png
  - apps/ios/BuyLedger/Resources/Localizable.xcstrings
  - apps/ios/BuyLedger/App/Testing/BLUITestSeedData+CategoryFilterLarge.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFormatters.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersRegularListColumn.swift
  - apps/ios/BuyLedgerTests/OrderEditCampaignOptionsTests.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+Campaigns.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestSeedData.swift
  - apps/ios/BuyLedgerTests/OrderFilterFeatureTests+Search.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersCompactView.swift
  - apps/ios/BuyLedger/Features/Orders/OrderListFeature.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrdersBaseline/ordersView_寬版選取含成本明細訂單_符合基準圖.1.png
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+Destination.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderCategoryPickerTests.swift
  - apps/ios/BuyLedger/Features/Orders/OrderListFeature+Destination.swift
  - apps/ios/BuyLedger.xcodeproj/project.pbxproj
  - apps/ios/BuyLedgerTests/OrderCategoryPickerFeatureTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Orders/ordersCompactView_一般訂單清單_符合基準圖.1.png
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderFilterSheetTests.swift
  - apps/ios/BuyLedgerTests/OrdersQueryTests.swift
  - apps/ios/BuyLedgerTests/OrderSummaryPromptTests.swift
  - apps/ios/BuyLedgerTests/OrdersFeatureTests.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+FilterSheet.swift
  - apps/ios/BuyLedgerTests/OrderListSnapshotSourceScanTests.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+Snapshot.swift
  - apps/ios/BuyLedgerTests/ProjectionWriteBoundaryTests+SharedCampaignScenarios.swift
  - apps/ios/BuyLedgerTests/OrderFilterFeatureTests.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderCategoryPickerSheet.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrdersBaseline/orderFilterSheet_已選日期類別付款方式_符合基準圖.1.png
  - apps/ios/BuyLedgerTests/OrderCategoryPickerFeatureTests+Search.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+FilterDelegates.swift
  - apps/ios/BuyLedger/Features/Orders/OrderListInteraction.swift
  - apps/ios/BuyLedgerTests/OrderCategoryGroupsTests.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+CategoryPickerApply.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderCategoryFilterRows.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+ClearFilterFixtures.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+NewOrderOptions.swift
  - apps/ios/BuyLedgerTests/SnapshotTests+OrderCategoryGrid.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderPaymentMethodMenuTests.swift
  - apps/ios/BuyLedger/Features/Orders/OrderSummaryPrompt.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+Filters.swift
  - apps/ios/BuyLedgerTests/ProjectionWriteBoundaryTests+Scanner.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+CampaignLoading.swift
  - apps/ios/BuyLedgerTests/SnapshotTests+OrdersBaseline.swift
  - apps/ios/BuyLedgerTests/OrdersFilterOperationsTests+FilterSheet.swift
  - apps/ios/BuyLedger/Features/Orders/OrderCategoryPickerFeature.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+Presentation.swift
  - apps/ios/BuyLedgerTests/OrdersSearchCancellationTests.swift
  - apps/ios/README.md
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Orders/ordersCompactView_多選模式_顯示勾選與工具列.1.png
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Chips/BLFilterChipLabel.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+Dates.swift
  - apps/ios/BuyLedgerTests/OrdersFilterOperationsTests+ClearFilters.swift
  - apps/ios/BuyLedger/Features/Orders/OrderListDestinationOperations.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFilterCategorySection.swift
  - apps/ios/BuyLedgerTests/ProjectionWriteBoundaryTests+SharedCampaigns.swift
  - apps/ios/BuyLedgerTests/OrdersQueryTests+Categories.swift
  - apps/ios/BuyLedger/Features/Orders/OrderEditFeature.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrdersBaseline/orderFilterSheet_已收單展開含長名稱_符合基準圖.1.png
  - apps/ios/BuyLedgerTests/CampaignIntegrationTests+Delete.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+ClearFilters.swift
  - apps/ios/BuyLedgerTests/OrdersFilterOperationsTests+FilteredOrders.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersFilterOperations.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Orders/ordersCompactView_長內容訂單清單_避免撐寬版面.1.png
  - apps/ios/BuyLedgerTests/OrdersFeatureTests+LoadAndSummary.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderCategoryPickerLargeTests.swift
  - apps/ios/BuyLedgerAccessibilityIDs/BLAccessibilityID+Orders.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrderCategoryGrid/orderCategoryGrid_單一類別保留一欄寬_符合基準圖.1.png
  - apps/ios/BuyLedger/Features/Orders/OrdersQuery.swift
  - apps/ios/BuyLedger/Features/Orders/OrderListSnapshot.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrderFilterEmptyStates/orderFilterSheet_搜尋無符合類別_符合基準圖.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrderCategoryGrid/orderCategoryGrid_欄數減一_符合基準圖.1.png
  - apps/ios/BuyLedgerUITests/Support/PlatformScope.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersContainerPlan+Requests.swift
  - apps/ios/BuyLedgerTests/OrderCategoryGroupsTests+EntryPoint.swift
  - apps/ios/BuyLedgerTests/CampaignIntegrationTests+Rename.swift
-->

---
### Requirement: Apply control commits pending changes and dismisses the sheet

The unified filter sheet SHALL present an apply control in the navigation bar (positioned as the primary confirmation action, typically the trailing edge on iOS). The apply control SHALL be labeled with text that clearly conveys "apply the selection" (for example, `套用`).

Tapping the apply control SHALL commit every pending selection whose value differs from the corresponding committed value, leave unchanged those whose pending value already equals the committed value, and then dismiss the sheet. The pending category selection is a set; it differs from the committed set when the two sets do not contain exactly the same names. When at least one filter value changed, the currently selected order SHALL be recomputed once against the newly filtered list rather than once per changed filter.

The sheet SHALL also continue to expose a cancel control in the navigation bar (positioned as the primary cancellation action, typically the leading edge on iOS). Cancelling SHALL never commit a pending selection. When pending selections differ from the committed values, cancelling SHALL first ask the user to confirm discarding them; see the "Guard edit sheets against silent data loss on dismissal" and "Confirm discarding unsaved changes when cancelling" requirements of the sheet-dismissal-safeguard capability.

Dismissal SHALL be driven by the orders feature rather than by the sheet view, so that every path that closes the sheet is observable outside the view layer.

#### Scenario: Apply commits both pending changes and dismisses

- **GIVEN** the unified filter sheet is open with the committed orders state being date period `.all` and no selected category, and the user has set the pending date period to `.thisMonth` and the pending categories to {`beauty`}
- **WHEN** the user taps the apply control
- **THEN** the committed date period becomes `.thisMonth` and the committed categories become {`beauty`}
- **AND** the sheet dismisses
- **AND** the trigger label reads `篩選：本月 · beauty`

#### Scenario: Apply commits all three pending selections

- **GIVEN** the unified filter sheet is open with committed date period `.all`, no committed category, and no committed payment method, and the user has set the pending date period to `.thisMonth`, the pending categories to {`beauty`}, and the pending payment method to `轉帳`
- **WHEN** the user taps the apply control
- **THEN** the committed date period becomes `.thisMonth`, the committed categories become {`beauty`}, and the committed payment method becomes `轉帳`
- **AND** the trigger label reads `篩選：本月 · beauty · 轉帳`

#### Scenario: Apply commits only the changed pending selection

- **GIVEN** the unified filter sheet is open with the committed orders state being date period `.thisMonth` and no selected category, and the user has set the pending categories to {`beauty`, `snacks`} without changing the pending date period (still `.thisMonth`)
- **WHEN** the user taps the apply control
- **THEN** the committed date period is left untouched (no change)
- **AND** the committed categories become {`beauty`, `snacks`}
- **AND** the sheet dismisses
- **AND** the trigger label reads `篩選：本月 · 2 項類別`

#### Scenario: Apply with no pending changes still dismisses and changes nothing

- **GIVEN** the unified filter sheet is open and the user has not changed any pending selection (or toggled a category on and off again so that the pending set equals the committed set)
- **WHEN** the user taps the apply control
- **THEN** no committed filter value changes and the currently selected order is unchanged
- **AND** the sheet dismisses

#### Scenario: Apply recomputes the selected order once

- **GIVEN** the unified filter sheet is open and the user has changed all three pending selections
- **WHEN** the user taps the apply control
- **THEN** the currently selected order becomes the first order of the list filtered by all three committed values
- **AND** that recomputation happens once, not once per changed filter

#### Scenario: Cancel discards pending changes without committing

- **GIVEN** the unified filter sheet is open with the committed orders state being date period `.all` and no selected category, and the user has set the pending date period to `.thisMonth` and the pending categories to {`beauty`}
- **WHEN** the user cancels and confirms discarding the pending changes
- **THEN** no committed filter value changes
- **AND** the pending selections are reset to the committed values
- **AND** the sheet dismisses
- **AND** the trigger label remains `篩選：全部`


<!-- @trace
source: order-filter-sheet-redesign
updated: 2026-10-19
code:
  - apps/ios/BuyLedgerTests/OrdersContainerPlanTests+Categories.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+ClearFilterPresentation.swift
  - apps/ios/BuyLedgerTests/OrdersFeaturePerformanceTests+FilterSheet.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+CategoryPickerRoot.swift
  - apps/ios/BuyLedgerTests/OrderCategoryPickerFeatureTests+Dismissal.swift
  - apps/ios/BuyLedgerTests/OrderCategoryPickerFeatureTests+Groups.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+DetailNavigation.swift
  - apps/ios/BuyLedgerUITests/Support/LaunchOptions.swift
  - apps/ios/CLAUDE.md
  - apps/ios/BuyLedgerTests/OrderCategoryGroupsTests+Expansion.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFilterPreviewFixtures.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrderFilterEmptyStates/orderCategoryPickerSheet_搜尋無符合類別_符合基準圖.1.png
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderFilterSheetTests+Assertions.swift
  - apps/ios/BuyLedgerTests/CampaignIntegrationTests.swift
  - apps/ios/BuyLedgerTests/OrderCategoryGridTests.swift
  - apps/ios/BuyLedgerTests/OrderEditFeatureTests+Campaigns.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+FilterLabels.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+FilterSummary.swift
  - apps/ios/BuyLedgerTests/BLUITestSeedDataTests+CategoryFilter.swift
  - apps/ios/BuyLedger/Features/Orders/OrderFilterSelection.swift
  - apps/ios/BuyLedgerTests/OrderFilterFeatureTests+Categories.swift
  - apps/ios/BuyLedgerTests/OrderFilterFeatureTests+Clear.swift
  - apps/ios/BuyLedgerUITests/Screens/OrdersScreen+CategoryPicker.swift
  - apps/ios/BuyLedgerTests/CampaignIntegrationTests+Fixtures.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFilterSheet.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+CategoryPicker.swift
  - apps/ios/BuyLedgerTests/ProjectionWriteBoundaryTests+Orders.swift
  - apps/ios/BuyLedgerTests/OrderCategoryPickerFeatureTests+Selection.swift
  - apps/ios/BuyLedgerUITests/Support/AppNavigator.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersView.swift
  - apps/ios/BuyLedgerTests/OrdersFilterOperationsTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderFilterSheetLargeTests.swift
  - apps/ios/BuyLedgerTests/SnapshotTests+OrderFilterEmptyStates.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFilterDateSection.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFilterPaymentMethodSection.swift
  - apps/ios/BuyLedger/Features/Orders/OrderCategoryGroups.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrderFilterEmptyStates/ordersView_寬版無付款方式與類別_符合基準圖.1.png
  - apps/ios/BuyLedger/Features/Orders/Components/OrderCategoryGrid.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderRegularClearFiltersTests.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+DeepLinks.swift
  - apps/ios/BuyLedgerUITests/Screens/OrdersScreen+FilterSheet.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersFeature.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestSeedProfile.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersListQuery.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+Selection.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Orders/ordersView_大尺寸iPhone橫向_顯示單欄清單與整合篩選鈕.1.png
  - apps/ios/BuyLedgerUITests/Screens/OrdersScreen+RegularFilters.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+OrderFilters.swift
  - apps/ios/BuyLedger/Features/Orders/OrderFilterFeature.swift
  - apps/ios/BuyLedger/Features/Orders/OrderFilterConfirmations.swift
  - apps/ios/BuyLedgerUITests/Screens/OrdersScreen+CategoryReveal.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrderCategoryGrid/orderCategoryGrid_長名稱同列等高_符合基準圖.1.png
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Chips/BLFilterChip.swift
  - apps/ios/BuyLedgerTests/OrderCategoryGroupsTests+Display.swift
  - apps/ios/BuyLedgerTests/OrderFilterFeatureTests+Queries.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+FilterPending.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Orders/ordersView_寬版多選模式_顯示選取列.1.png
  - apps/ios/BuyLedger/Features/App/RootFeature.swift
  - apps/ios/BuyLedgerTests/OrdersFeaturePerformanceTests.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+CategoryPickerSync.swift
  - apps/ios/BuyLedgerTests/ProjectionWriteBoundaryTests+Patterns.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestSeedData+CategoryFilter.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrderCategoryGrid/orderCategoryGrid_無障礙字級單欄_符合基準圖.1.png
  - apps/ios/BuyLedger/Resources/Localizable.xcstrings
  - apps/ios/BuyLedger/App/Testing/BLUITestSeedData+CategoryFilterLarge.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFormatters.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersRegularListColumn.swift
  - apps/ios/BuyLedgerTests/OrderEditCampaignOptionsTests.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+Campaigns.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestSeedData.swift
  - apps/ios/BuyLedgerTests/OrderFilterFeatureTests+Search.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersCompactView.swift
  - apps/ios/BuyLedger/Features/Orders/OrderListFeature.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrdersBaseline/ordersView_寬版選取含成本明細訂單_符合基準圖.1.png
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+Destination.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderCategoryPickerTests.swift
  - apps/ios/BuyLedger/Features/Orders/OrderListFeature+Destination.swift
  - apps/ios/BuyLedger.xcodeproj/project.pbxproj
  - apps/ios/BuyLedgerTests/OrderCategoryPickerFeatureTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Orders/ordersCompactView_一般訂單清單_符合基準圖.1.png
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderFilterSheetTests.swift
  - apps/ios/BuyLedgerTests/OrdersQueryTests.swift
  - apps/ios/BuyLedgerTests/OrderSummaryPromptTests.swift
  - apps/ios/BuyLedgerTests/OrdersFeatureTests.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+FilterSheet.swift
  - apps/ios/BuyLedgerTests/OrderListSnapshotSourceScanTests.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+Snapshot.swift
  - apps/ios/BuyLedgerTests/ProjectionWriteBoundaryTests+SharedCampaignScenarios.swift
  - apps/ios/BuyLedgerTests/OrderFilterFeatureTests.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderCategoryPickerSheet.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrdersBaseline/orderFilterSheet_已選日期類別付款方式_符合基準圖.1.png
  - apps/ios/BuyLedgerTests/OrderCategoryPickerFeatureTests+Search.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+FilterDelegates.swift
  - apps/ios/BuyLedger/Features/Orders/OrderListInteraction.swift
  - apps/ios/BuyLedgerTests/OrderCategoryGroupsTests.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+CategoryPickerApply.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderCategoryFilterRows.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+ClearFilterFixtures.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+NewOrderOptions.swift
  - apps/ios/BuyLedgerTests/SnapshotTests+OrderCategoryGrid.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderPaymentMethodMenuTests.swift
  - apps/ios/BuyLedger/Features/Orders/OrderSummaryPrompt.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+Filters.swift
  - apps/ios/BuyLedgerTests/ProjectionWriteBoundaryTests+Scanner.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+CampaignLoading.swift
  - apps/ios/BuyLedgerTests/SnapshotTests+OrdersBaseline.swift
  - apps/ios/BuyLedgerTests/OrdersFilterOperationsTests+FilterSheet.swift
  - apps/ios/BuyLedger/Features/Orders/OrderCategoryPickerFeature.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+Presentation.swift
  - apps/ios/BuyLedgerTests/OrdersSearchCancellationTests.swift
  - apps/ios/README.md
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Orders/ordersCompactView_多選模式_顯示勾選與工具列.1.png
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Chips/BLFilterChipLabel.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+Dates.swift
  - apps/ios/BuyLedgerTests/OrdersFilterOperationsTests+ClearFilters.swift
  - apps/ios/BuyLedger/Features/Orders/OrderListDestinationOperations.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFilterCategorySection.swift
  - apps/ios/BuyLedgerTests/ProjectionWriteBoundaryTests+SharedCampaigns.swift
  - apps/ios/BuyLedgerTests/OrdersQueryTests+Categories.swift
  - apps/ios/BuyLedger/Features/Orders/OrderEditFeature.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrdersBaseline/orderFilterSheet_已收單展開含長名稱_符合基準圖.1.png
  - apps/ios/BuyLedgerTests/CampaignIntegrationTests+Delete.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+ClearFilters.swift
  - apps/ios/BuyLedgerTests/OrdersFilterOperationsTests+FilteredOrders.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersFilterOperations.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Orders/ordersCompactView_長內容訂單清單_避免撐寬版面.1.png
  - apps/ios/BuyLedgerTests/OrdersFeatureTests+LoadAndSummary.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderCategoryPickerLargeTests.swift
  - apps/ios/BuyLedgerAccessibilityIDs/BLAccessibilityID+Orders.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrderCategoryGrid/orderCategoryGrid_單一類別保留一欄寬_符合基準圖.1.png
  - apps/ios/BuyLedger/Features/Orders/OrdersQuery.swift
  - apps/ios/BuyLedger/Features/Orders/OrderListSnapshot.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrderFilterEmptyStates/orderFilterSheet_搜尋無符合類別_符合基準圖.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrderCategoryGrid/orderCategoryGrid_欄數減一_符合基準圖.1.png
  - apps/ios/BuyLedgerUITests/Support/PlatformScope.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersContainerPlan+Requests.swift
  - apps/ios/BuyLedgerTests/OrderCategoryGroupsTests+EntryPoint.swift
  - apps/ios/BuyLedgerTests/CampaignIntegrationTests+Rename.swift
-->

---
### Requirement: Unified filter sheet exposes date period, category, and payment method sections

The unified filter sheet SHALL render, from top to bottom:
1. A filter-conditions header row titled `篩選條件` that carries the clear-filters control defined by the "Clear filters control restores default filter values" requirement.
2. A date-period menu row and a payment-method menu row, grouped together. Each row SHALL show a leading icon, its title (`日期區間`, `付款方式`), and the title of its current pending value as trailing text (`全部時間` for `.all` and `全部` for no payment method), followed by a menu indicator.
3. A category section titled `商品類別` that contains, in order, the category search field defined by the "Search in the unified filter sheet filters only the category options" requirement, an "all categories" row labeled `全部`, and the grouped category grid defined by the order-category-filter capability.

Opening the date-period menu SHALL list every entry of the orders-browsing date-period set (`OrderDatePeriod.orderBrowsingCases`) — namely `.all`, `.thisWeek`, `.thisMonth`, and `.lastMonth` — and mark the entry equal to the pending date period. Opening the payment-method menu SHALL list a `全部` entry followed by one entry per available payment method, and mark the entry matching the pending payment method (`全部` when none). Choosing a menu entry SHALL update the corresponding pending selection, close the menu, and keep the sheet open. The date period and the payment method SHALL NOT be rendered as list sections with one row per value.

The pending selections SHALL be held by the orders feature rather than by the sheet view, so that they are observable and assertable outside the view layer. When the sheet is presented, each pending selection SHALL be seeded from the orders feature's corresponding committed filter value, the sheet's search text SHALL be reset to empty, and the category group expansion SHALL be computed from the rules of the order-category-filter capability.

Tapping a category cell SHALL toggle that category's membership in the pending category set: an unselected category is added and a selected category is removed. Tapping the `全部` row SHALL empty the pending category set. None of these interactions SHALL change a committed filter value or dismiss the sheet; the sheet SHALL only commit the pending selections when the user taps the apply control (see the "Apply control commits pending changes and dismisses the sheet" requirement).

The `全部` row SHALL be marked as currently selected exactly when the pending category set is empty. Every category cell whose name is in the pending set SHALL be marked as selected, and no other cell SHALL be marked.

The menu rows and the `全部` row SHALL support multi-line text wrapping when their title or trailing value exceeds the available single-line width — the row SHALL grow vertically to fit the wrapped text rather than truncating it — and their trailing value, menu indicator, or selection checkmark SHALL align to the first text baseline.

#### Scenario: Presenting the sheet seeds pending selections from committed values

- **GIVEN** the orders list has committed date period `.thisMonth`, committed categories {`beauty`}, and no committed payment method
- **WHEN** the unified filter sheet is presented
- **THEN** the pending date period is `.thisMonth`, the pending categories are {`beauty`}, and the pending payment method is "no specific value"
- **AND** the sheet's search text is empty
- **AND** the date-period menu row shows `本月` and the payment-method menu row shows `全部`

#### Scenario: Choosing a date menu entry updates the pending selection without dismissing

- **GIVEN** the unified filter sheet is open with the pending date period being `.all`
- **WHEN** the user opens the date-period menu and chooses `本月`
- **THEN** the pending date period becomes `.thisMonth`
- **AND** the committed date period is unchanged
- **AND** the menu closes and the sheet remains open
- **AND** the date-period menu row shows `本月`

#### Scenario: Choosing a payment-method menu entry updates the pending selection

- **GIVEN** the unified filter sheet is open with no specific pending payment method and the available payment methods include `轉帳`
- **WHEN** the user opens the payment-method menu and chooses `轉帳`
- **THEN** the pending payment method becomes `轉帳`
- **AND** the committed payment method is unchanged
- **AND** the sheet remains open

#### Scenario: Toggling category cells builds the pending set

- **GIVEN** the unified filter sheet is open with an empty pending category set and the available categories include `beauty` and `books`
- **WHEN** the user taps the `beauty` cell, then the `books` cell, then the `beauty` cell again
- **THEN** the pending categories are {`books`}
- **AND** only the `books` cell is marked as selected
- **AND** the `全部` row is not marked
- **AND** no committed filter value has changed and the sheet remains open

#### Scenario: Tapping the all-categories row empties the pending set

- **GIVEN** the unified filter sheet is open with pending categories {`beauty`, `books`}
- **WHEN** the user taps the `全部` row in the category section
- **THEN** the pending category set becomes empty
- **AND** the `全部` row is marked as currently selected and no category cell is marked
- **AND** the committed categories are unchanged and the sheet remains open

#### Scenario: Multiple selections in the same sheet session are tracked together

- **GIVEN** the unified filter sheet is open with pending date period `.all` and an empty pending category set, and the available categories include `beauty`
- **WHEN** the user chooses `本月` from the date-period menu, then taps the `beauty` cell
- **THEN** the pending date period is `.thisMonth` and the pending categories are {`beauty`}
- **AND** no committed filter value has changed
- **AND** the sheet remains open


<!-- @trace
source: order-filter-sheet-redesign
updated: 2026-10-19
code:
  - apps/ios/BuyLedgerTests/OrdersContainerPlanTests+Categories.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+ClearFilterPresentation.swift
  - apps/ios/BuyLedgerTests/OrdersFeaturePerformanceTests+FilterSheet.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+CategoryPickerRoot.swift
  - apps/ios/BuyLedgerTests/OrderCategoryPickerFeatureTests+Dismissal.swift
  - apps/ios/BuyLedgerTests/OrderCategoryPickerFeatureTests+Groups.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+DetailNavigation.swift
  - apps/ios/BuyLedgerUITests/Support/LaunchOptions.swift
  - apps/ios/CLAUDE.md
  - apps/ios/BuyLedgerTests/OrderCategoryGroupsTests+Expansion.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFilterPreviewFixtures.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrderFilterEmptyStates/orderCategoryPickerSheet_搜尋無符合類別_符合基準圖.1.png
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderFilterSheetTests+Assertions.swift
  - apps/ios/BuyLedgerTests/CampaignIntegrationTests.swift
  - apps/ios/BuyLedgerTests/OrderCategoryGridTests.swift
  - apps/ios/BuyLedgerTests/OrderEditFeatureTests+Campaigns.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+FilterLabels.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+FilterSummary.swift
  - apps/ios/BuyLedgerTests/BLUITestSeedDataTests+CategoryFilter.swift
  - apps/ios/BuyLedger/Features/Orders/OrderFilterSelection.swift
  - apps/ios/BuyLedgerTests/OrderFilterFeatureTests+Categories.swift
  - apps/ios/BuyLedgerTests/OrderFilterFeatureTests+Clear.swift
  - apps/ios/BuyLedgerUITests/Screens/OrdersScreen+CategoryPicker.swift
  - apps/ios/BuyLedgerTests/CampaignIntegrationTests+Fixtures.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFilterSheet.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+CategoryPicker.swift
  - apps/ios/BuyLedgerTests/ProjectionWriteBoundaryTests+Orders.swift
  - apps/ios/BuyLedgerTests/OrderCategoryPickerFeatureTests+Selection.swift
  - apps/ios/BuyLedgerUITests/Support/AppNavigator.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersView.swift
  - apps/ios/BuyLedgerTests/OrdersFilterOperationsTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderFilterSheetLargeTests.swift
  - apps/ios/BuyLedgerTests/SnapshotTests+OrderFilterEmptyStates.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFilterDateSection.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFilterPaymentMethodSection.swift
  - apps/ios/BuyLedger/Features/Orders/OrderCategoryGroups.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrderFilterEmptyStates/ordersView_寬版無付款方式與類別_符合基準圖.1.png
  - apps/ios/BuyLedger/Features/Orders/Components/OrderCategoryGrid.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderRegularClearFiltersTests.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+DeepLinks.swift
  - apps/ios/BuyLedgerUITests/Screens/OrdersScreen+FilterSheet.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersFeature.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestSeedProfile.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersListQuery.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+Selection.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Orders/ordersView_大尺寸iPhone橫向_顯示單欄清單與整合篩選鈕.1.png
  - apps/ios/BuyLedgerUITests/Screens/OrdersScreen+RegularFilters.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+OrderFilters.swift
  - apps/ios/BuyLedger/Features/Orders/OrderFilterFeature.swift
  - apps/ios/BuyLedger/Features/Orders/OrderFilterConfirmations.swift
  - apps/ios/BuyLedgerUITests/Screens/OrdersScreen+CategoryReveal.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrderCategoryGrid/orderCategoryGrid_長名稱同列等高_符合基準圖.1.png
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Chips/BLFilterChip.swift
  - apps/ios/BuyLedgerTests/OrderCategoryGroupsTests+Display.swift
  - apps/ios/BuyLedgerTests/OrderFilterFeatureTests+Queries.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+FilterPending.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Orders/ordersView_寬版多選模式_顯示選取列.1.png
  - apps/ios/BuyLedger/Features/App/RootFeature.swift
  - apps/ios/BuyLedgerTests/OrdersFeaturePerformanceTests.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+CategoryPickerSync.swift
  - apps/ios/BuyLedgerTests/ProjectionWriteBoundaryTests+Patterns.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestSeedData+CategoryFilter.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrderCategoryGrid/orderCategoryGrid_無障礙字級單欄_符合基準圖.1.png
  - apps/ios/BuyLedger/Resources/Localizable.xcstrings
  - apps/ios/BuyLedger/App/Testing/BLUITestSeedData+CategoryFilterLarge.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFormatters.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersRegularListColumn.swift
  - apps/ios/BuyLedgerTests/OrderEditCampaignOptionsTests.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+Campaigns.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestSeedData.swift
  - apps/ios/BuyLedgerTests/OrderFilterFeatureTests+Search.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersCompactView.swift
  - apps/ios/BuyLedger/Features/Orders/OrderListFeature.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrdersBaseline/ordersView_寬版選取含成本明細訂單_符合基準圖.1.png
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+Destination.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderCategoryPickerTests.swift
  - apps/ios/BuyLedger/Features/Orders/OrderListFeature+Destination.swift
  - apps/ios/BuyLedger.xcodeproj/project.pbxproj
  - apps/ios/BuyLedgerTests/OrderCategoryPickerFeatureTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Orders/ordersCompactView_一般訂單清單_符合基準圖.1.png
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderFilterSheetTests.swift
  - apps/ios/BuyLedgerTests/OrdersQueryTests.swift
  - apps/ios/BuyLedgerTests/OrderSummaryPromptTests.swift
  - apps/ios/BuyLedgerTests/OrdersFeatureTests.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+FilterSheet.swift
  - apps/ios/BuyLedgerTests/OrderListSnapshotSourceScanTests.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+Snapshot.swift
  - apps/ios/BuyLedgerTests/ProjectionWriteBoundaryTests+SharedCampaignScenarios.swift
  - apps/ios/BuyLedgerTests/OrderFilterFeatureTests.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderCategoryPickerSheet.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrdersBaseline/orderFilterSheet_已選日期類別付款方式_符合基準圖.1.png
  - apps/ios/BuyLedgerTests/OrderCategoryPickerFeatureTests+Search.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+FilterDelegates.swift
  - apps/ios/BuyLedger/Features/Orders/OrderListInteraction.swift
  - apps/ios/BuyLedgerTests/OrderCategoryGroupsTests.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+CategoryPickerApply.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderCategoryFilterRows.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+ClearFilterFixtures.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+NewOrderOptions.swift
  - apps/ios/BuyLedgerTests/SnapshotTests+OrderCategoryGrid.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderPaymentMethodMenuTests.swift
  - apps/ios/BuyLedger/Features/Orders/OrderSummaryPrompt.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+Filters.swift
  - apps/ios/BuyLedgerTests/ProjectionWriteBoundaryTests+Scanner.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+CampaignLoading.swift
  - apps/ios/BuyLedgerTests/SnapshotTests+OrdersBaseline.swift
  - apps/ios/BuyLedgerTests/OrdersFilterOperationsTests+FilterSheet.swift
  - apps/ios/BuyLedger/Features/Orders/OrderCategoryPickerFeature.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+Presentation.swift
  - apps/ios/BuyLedgerTests/OrdersSearchCancellationTests.swift
  - apps/ios/README.md
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Orders/ordersCompactView_多選模式_顯示勾選與工具列.1.png
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Chips/BLFilterChipLabel.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+Dates.swift
  - apps/ios/BuyLedgerTests/OrdersFilterOperationsTests+ClearFilters.swift
  - apps/ios/BuyLedger/Features/Orders/OrderListDestinationOperations.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFilterCategorySection.swift
  - apps/ios/BuyLedgerTests/ProjectionWriteBoundaryTests+SharedCampaigns.swift
  - apps/ios/BuyLedgerTests/OrdersQueryTests+Categories.swift
  - apps/ios/BuyLedger/Features/Orders/OrderEditFeature.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrdersBaseline/orderFilterSheet_已收單展開含長名稱_符合基準圖.1.png
  - apps/ios/BuyLedgerTests/CampaignIntegrationTests+Delete.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+ClearFilters.swift
  - apps/ios/BuyLedgerTests/OrdersFilterOperationsTests+FilteredOrders.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersFilterOperations.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Orders/ordersCompactView_長內容訂單清單_避免撐寬版面.1.png
  - apps/ios/BuyLedgerTests/OrdersFeatureTests+LoadAndSummary.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderCategoryPickerLargeTests.swift
  - apps/ios/BuyLedgerAccessibilityIDs/BLAccessibilityID+Orders.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrderCategoryGrid/orderCategoryGrid_單一類別保留一欄寬_符合基準圖.1.png
  - apps/ios/BuyLedger/Features/Orders/OrdersQuery.swift
  - apps/ios/BuyLedger/Features/Orders/OrderListSnapshot.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrderFilterEmptyStates/orderFilterSheet_搜尋無符合類別_符合基準圖.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrderCategoryGrid/orderCategoryGrid_欄數減一_符合基準圖.1.png
  - apps/ios/BuyLedgerUITests/Support/PlatformScope.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersContainerPlan+Requests.swift
  - apps/ios/BuyLedgerTests/OrderCategoryGroupsTests+EntryPoint.swift
  - apps/ios/BuyLedgerTests/CampaignIntegrationTests+Rename.swift
-->

---
### Requirement: Clear filters control restores default filter values

The orders list SHALL offer a clear-filters control labeled `清除篩選` that restores the date period to `.all`, the payment method to "no specific value", and the category set to empty. The control SHALL NOT change the status filter or the search text. The control SHALL be disabled, and SHALL expose the disabled state to accessibility, whenever all three values it restores are already at their defaults.

On iPhone Compact the control SHALL be rendered in the filter-conditions header row of the unified filter sheet. It SHALL act on the pending selections only: it SHALL NOT commit any value and SHALL NOT dismiss the sheet; the user commits the cleared values with the apply control or discards them with cancel. Its enabled state SHALL be derived from the pending selections.

On iPadOS the control SHALL be rendered in the orders filter area below the payment-method and category filter triggers. It SHALL act on the committed filters immediately and recompute the currently selected order once. Its enabled state SHALL be derived from the committed filters.

#### Scenario: Clearing inside the iPhone sheet resets pending values only

- **GIVEN** the unified filter sheet is open with pending date period `.thisMonth`, pending payment method `信用卡`, and pending categories {`beauty`, `books`}, and the committed values are the same
- **WHEN** the user taps `清除篩選`
- **THEN** the pending date period is `.all`, the pending payment method is "no specific value", and the pending category set is empty
- **AND** the committed values are unchanged and the sheet remains open
- **AND** the clear-filters control becomes disabled
- **AND** tapping the apply control afterwards commits the default values and the trigger label reads `篩選：全部`

#### Scenario: The iPhone control is disabled when the pending values are already default

- **GIVEN** the unified filter sheet is open with pending date period `.all`, no pending payment method, and an empty pending category set
- **WHEN** the sheet content is displayed
- **THEN** the clear-filters control is disabled

#### Scenario: Clearing on iPadOS applies immediately

- **GIVEN** the orders list on iPadOS has committed status filter `purchased`, search text `Alice`, date period `.thisMonth`, payment method `現金`, and categories {`beauty`}
- **WHEN** the user taps `清除篩選`
- **THEN** the committed date period becomes `.all`, the committed payment method becomes "no specific value", and the committed category set becomes empty
- **AND** the status filter remains `purchased` and the search text remains `Alice`
- **AND** the currently selected order is recomputed once to the first order of the newly filtered list
- **AND** the clear-filters control becomes disabled


<!-- @trace
source: order-filter-sheet-redesign
updated: 2026-10-19
code:
  - apps/ios/BuyLedgerTests/OrdersContainerPlanTests+Categories.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+ClearFilterPresentation.swift
  - apps/ios/BuyLedgerTests/OrdersFeaturePerformanceTests+FilterSheet.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+CategoryPickerRoot.swift
  - apps/ios/BuyLedgerTests/OrderCategoryPickerFeatureTests+Dismissal.swift
  - apps/ios/BuyLedgerTests/OrderCategoryPickerFeatureTests+Groups.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+DetailNavigation.swift
  - apps/ios/BuyLedgerUITests/Support/LaunchOptions.swift
  - apps/ios/CLAUDE.md
  - apps/ios/BuyLedgerTests/OrderCategoryGroupsTests+Expansion.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFilterPreviewFixtures.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrderFilterEmptyStates/orderCategoryPickerSheet_搜尋無符合類別_符合基準圖.1.png
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderFilterSheetTests+Assertions.swift
  - apps/ios/BuyLedgerTests/CampaignIntegrationTests.swift
  - apps/ios/BuyLedgerTests/OrderCategoryGridTests.swift
  - apps/ios/BuyLedgerTests/OrderEditFeatureTests+Campaigns.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+FilterLabels.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+FilterSummary.swift
  - apps/ios/BuyLedgerTests/BLUITestSeedDataTests+CategoryFilter.swift
  - apps/ios/BuyLedger/Features/Orders/OrderFilterSelection.swift
  - apps/ios/BuyLedgerTests/OrderFilterFeatureTests+Categories.swift
  - apps/ios/BuyLedgerTests/OrderFilterFeatureTests+Clear.swift
  - apps/ios/BuyLedgerUITests/Screens/OrdersScreen+CategoryPicker.swift
  - apps/ios/BuyLedgerTests/CampaignIntegrationTests+Fixtures.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFilterSheet.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+CategoryPicker.swift
  - apps/ios/BuyLedgerTests/ProjectionWriteBoundaryTests+Orders.swift
  - apps/ios/BuyLedgerTests/OrderCategoryPickerFeatureTests+Selection.swift
  - apps/ios/BuyLedgerUITests/Support/AppNavigator.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersView.swift
  - apps/ios/BuyLedgerTests/OrdersFilterOperationsTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderFilterSheetLargeTests.swift
  - apps/ios/BuyLedgerTests/SnapshotTests+OrderFilterEmptyStates.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFilterDateSection.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFilterPaymentMethodSection.swift
  - apps/ios/BuyLedger/Features/Orders/OrderCategoryGroups.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrderFilterEmptyStates/ordersView_寬版無付款方式與類別_符合基準圖.1.png
  - apps/ios/BuyLedger/Features/Orders/Components/OrderCategoryGrid.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderRegularClearFiltersTests.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+DeepLinks.swift
  - apps/ios/BuyLedgerUITests/Screens/OrdersScreen+FilterSheet.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersFeature.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestSeedProfile.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersListQuery.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+Selection.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Orders/ordersView_大尺寸iPhone橫向_顯示單欄清單與整合篩選鈕.1.png
  - apps/ios/BuyLedgerUITests/Screens/OrdersScreen+RegularFilters.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+OrderFilters.swift
  - apps/ios/BuyLedger/Features/Orders/OrderFilterFeature.swift
  - apps/ios/BuyLedger/Features/Orders/OrderFilterConfirmations.swift
  - apps/ios/BuyLedgerUITests/Screens/OrdersScreen+CategoryReveal.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrderCategoryGrid/orderCategoryGrid_長名稱同列等高_符合基準圖.1.png
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Chips/BLFilterChip.swift
  - apps/ios/BuyLedgerTests/OrderCategoryGroupsTests+Display.swift
  - apps/ios/BuyLedgerTests/OrderFilterFeatureTests+Queries.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+FilterPending.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Orders/ordersView_寬版多選模式_顯示選取列.1.png
  - apps/ios/BuyLedger/Features/App/RootFeature.swift
  - apps/ios/BuyLedgerTests/OrdersFeaturePerformanceTests.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+CategoryPickerSync.swift
  - apps/ios/BuyLedgerTests/ProjectionWriteBoundaryTests+Patterns.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestSeedData+CategoryFilter.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrderCategoryGrid/orderCategoryGrid_無障礙字級單欄_符合基準圖.1.png
  - apps/ios/BuyLedger/Resources/Localizable.xcstrings
  - apps/ios/BuyLedger/App/Testing/BLUITestSeedData+CategoryFilterLarge.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFormatters.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersRegularListColumn.swift
  - apps/ios/BuyLedgerTests/OrderEditCampaignOptionsTests.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+Campaigns.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestSeedData.swift
  - apps/ios/BuyLedgerTests/OrderFilterFeatureTests+Search.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersCompactView.swift
  - apps/ios/BuyLedger/Features/Orders/OrderListFeature.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrdersBaseline/ordersView_寬版選取含成本明細訂單_符合基準圖.1.png
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+Destination.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderCategoryPickerTests.swift
  - apps/ios/BuyLedger/Features/Orders/OrderListFeature+Destination.swift
  - apps/ios/BuyLedger.xcodeproj/project.pbxproj
  - apps/ios/BuyLedgerTests/OrderCategoryPickerFeatureTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Orders/ordersCompactView_一般訂單清單_符合基準圖.1.png
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderFilterSheetTests.swift
  - apps/ios/BuyLedgerTests/OrdersQueryTests.swift
  - apps/ios/BuyLedgerTests/OrderSummaryPromptTests.swift
  - apps/ios/BuyLedgerTests/OrdersFeatureTests.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+FilterSheet.swift
  - apps/ios/BuyLedgerTests/OrderListSnapshotSourceScanTests.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+Snapshot.swift
  - apps/ios/BuyLedgerTests/ProjectionWriteBoundaryTests+SharedCampaignScenarios.swift
  - apps/ios/BuyLedgerTests/OrderFilterFeatureTests.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderCategoryPickerSheet.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrdersBaseline/orderFilterSheet_已選日期類別付款方式_符合基準圖.1.png
  - apps/ios/BuyLedgerTests/OrderCategoryPickerFeatureTests+Search.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+FilterDelegates.swift
  - apps/ios/BuyLedger/Features/Orders/OrderListInteraction.swift
  - apps/ios/BuyLedgerTests/OrderCategoryGroupsTests.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+CategoryPickerApply.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderCategoryFilterRows.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+ClearFilterFixtures.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+NewOrderOptions.swift
  - apps/ios/BuyLedgerTests/SnapshotTests+OrderCategoryGrid.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderPaymentMethodMenuTests.swift
  - apps/ios/BuyLedger/Features/Orders/OrderSummaryPrompt.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+Filters.swift
  - apps/ios/BuyLedgerTests/ProjectionWriteBoundaryTests+Scanner.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+CampaignLoading.swift
  - apps/ios/BuyLedgerTests/SnapshotTests+OrdersBaseline.swift
  - apps/ios/BuyLedgerTests/OrdersFilterOperationsTests+FilterSheet.swift
  - apps/ios/BuyLedger/Features/Orders/OrderCategoryPickerFeature.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+Presentation.swift
  - apps/ios/BuyLedgerTests/OrdersSearchCancellationTests.swift
  - apps/ios/README.md
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Orders/ordersCompactView_多選模式_顯示勾選與工具列.1.png
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Chips/BLFilterChipLabel.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+Dates.swift
  - apps/ios/BuyLedgerTests/OrdersFilterOperationsTests+ClearFilters.swift
  - apps/ios/BuyLedger/Features/Orders/OrderListDestinationOperations.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFilterCategorySection.swift
  - apps/ios/BuyLedgerTests/ProjectionWriteBoundaryTests+SharedCampaigns.swift
  - apps/ios/BuyLedgerTests/OrdersQueryTests+Categories.swift
  - apps/ios/BuyLedger/Features/Orders/OrderEditFeature.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrdersBaseline/orderFilterSheet_已收單展開含長名稱_符合基準圖.1.png
  - apps/ios/BuyLedgerTests/CampaignIntegrationTests+Delete.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+ClearFilters.swift
  - apps/ios/BuyLedgerTests/OrdersFilterOperationsTests+FilteredOrders.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersFilterOperations.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Orders/ordersCompactView_長內容訂單清單_避免撐寬版面.1.png
  - apps/ios/BuyLedgerTests/OrdersFeatureTests+LoadAndSummary.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderCategoryPickerLargeTests.swift
  - apps/ios/BuyLedgerAccessibilityIDs/BLAccessibilityID+Orders.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrderCategoryGrid/orderCategoryGrid_單一類別保留一欄寬_符合基準圖.1.png
  - apps/ios/BuyLedger/Features/Orders/OrdersQuery.swift
  - apps/ios/BuyLedger/Features/Orders/OrderListSnapshot.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrderFilterEmptyStates/orderFilterSheet_搜尋無符合類別_符合基準圖.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrderCategoryGrid/orderCategoryGrid_欄數減一_符合基準圖.1.png
  - apps/ios/BuyLedgerUITests/Support/PlatformScope.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersContainerPlan+Requests.swift
  - apps/ios/BuyLedgerTests/OrderCategoryGroupsTests+EntryPoint.swift
  - apps/ios/BuyLedgerTests/CampaignIntegrationTests+Rename.swift
-->

---
### Requirement: Regular-width payment method filter is a menu

On iPadOS the orders list payment-method filter SHALL be rendered as a menu whose label is a full-width capsule trigger showing a leading payment icon, the text `付款方式：<current>` (where `<current>` is `全部` when no payment method is selected and the payment method name otherwise), and a trailing menu indicator. The menu SHALL list a `全部` entry followed by one entry per available payment method and mark the entry matching the committed selection. Choosing an entry SHALL immediately set the committed payment method (or clear it for `全部`) and recompute the currently selected order once. The payment-method filter SHALL NOT present a picker sheet. The trigger SHALL only be rendered when at least one payment method is available, and its hit region SHALL remain at least 44 points tall.

#### Scenario: Choosing a payment method from the menu applies it immediately

- **GIVEN** the orders list is displayed on iPadOS with available payment methods `["信用卡", "現金"]` and no committed payment method
- **WHEN** the user opens the payment-method menu and chooses `信用卡`
- **THEN** the committed payment method becomes `信用卡` without presenting any sheet
- **AND** the trigger reads `付款方式：信用卡`
- **AND** the orders list shows only orders paid by `信用卡`, combined with the other active filters

#### Scenario: Choosing the all entry clears the payment method

- **GIVEN** the orders list on iPadOS has committed payment method `現金`
- **WHEN** the user opens the payment-method menu and chooses `全部`
- **THEN** the committed payment method becomes "no specific value" and the trigger reads `付款方式：全部`

#### Scenario: Payment-method menu is hidden without payment methods

- **GIVEN** the orders list on iPadOS has no available payment methods
- **WHEN** the orders filter area is rendered
- **THEN** the payment-method trigger is not rendered


<!-- @trace
source: order-filter-sheet-redesign
updated: 2026-10-19
code:
  - apps/ios/BuyLedgerTests/OrdersContainerPlanTests+Categories.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+ClearFilterPresentation.swift
  - apps/ios/BuyLedgerTests/OrdersFeaturePerformanceTests+FilterSheet.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+CategoryPickerRoot.swift
  - apps/ios/BuyLedgerTests/OrderCategoryPickerFeatureTests+Dismissal.swift
  - apps/ios/BuyLedgerTests/OrderCategoryPickerFeatureTests+Groups.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+DetailNavigation.swift
  - apps/ios/BuyLedgerUITests/Support/LaunchOptions.swift
  - apps/ios/CLAUDE.md
  - apps/ios/BuyLedgerTests/OrderCategoryGroupsTests+Expansion.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFilterPreviewFixtures.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrderFilterEmptyStates/orderCategoryPickerSheet_搜尋無符合類別_符合基準圖.1.png
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderFilterSheetTests+Assertions.swift
  - apps/ios/BuyLedgerTests/CampaignIntegrationTests.swift
  - apps/ios/BuyLedgerTests/OrderCategoryGridTests.swift
  - apps/ios/BuyLedgerTests/OrderEditFeatureTests+Campaigns.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+FilterLabels.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+FilterSummary.swift
  - apps/ios/BuyLedgerTests/BLUITestSeedDataTests+CategoryFilter.swift
  - apps/ios/BuyLedger/Features/Orders/OrderFilterSelection.swift
  - apps/ios/BuyLedgerTests/OrderFilterFeatureTests+Categories.swift
  - apps/ios/BuyLedgerTests/OrderFilterFeatureTests+Clear.swift
  - apps/ios/BuyLedgerUITests/Screens/OrdersScreen+CategoryPicker.swift
  - apps/ios/BuyLedgerTests/CampaignIntegrationTests+Fixtures.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFilterSheet.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+CategoryPicker.swift
  - apps/ios/BuyLedgerTests/ProjectionWriteBoundaryTests+Orders.swift
  - apps/ios/BuyLedgerTests/OrderCategoryPickerFeatureTests+Selection.swift
  - apps/ios/BuyLedgerUITests/Support/AppNavigator.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersView.swift
  - apps/ios/BuyLedgerTests/OrdersFilterOperationsTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderFilterSheetLargeTests.swift
  - apps/ios/BuyLedgerTests/SnapshotTests+OrderFilterEmptyStates.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFilterDateSection.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFilterPaymentMethodSection.swift
  - apps/ios/BuyLedger/Features/Orders/OrderCategoryGroups.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrderFilterEmptyStates/ordersView_寬版無付款方式與類別_符合基準圖.1.png
  - apps/ios/BuyLedger/Features/Orders/Components/OrderCategoryGrid.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderRegularClearFiltersTests.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+DeepLinks.swift
  - apps/ios/BuyLedgerUITests/Screens/OrdersScreen+FilterSheet.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersFeature.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestSeedProfile.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersListQuery.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+Selection.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Orders/ordersView_大尺寸iPhone橫向_顯示單欄清單與整合篩選鈕.1.png
  - apps/ios/BuyLedgerUITests/Screens/OrdersScreen+RegularFilters.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+OrderFilters.swift
  - apps/ios/BuyLedger/Features/Orders/OrderFilterFeature.swift
  - apps/ios/BuyLedger/Features/Orders/OrderFilterConfirmations.swift
  - apps/ios/BuyLedgerUITests/Screens/OrdersScreen+CategoryReveal.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrderCategoryGrid/orderCategoryGrid_長名稱同列等高_符合基準圖.1.png
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Chips/BLFilterChip.swift
  - apps/ios/BuyLedgerTests/OrderCategoryGroupsTests+Display.swift
  - apps/ios/BuyLedgerTests/OrderFilterFeatureTests+Queries.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+FilterPending.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Orders/ordersView_寬版多選模式_顯示選取列.1.png
  - apps/ios/BuyLedger/Features/App/RootFeature.swift
  - apps/ios/BuyLedgerTests/OrdersFeaturePerformanceTests.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+CategoryPickerSync.swift
  - apps/ios/BuyLedgerTests/ProjectionWriteBoundaryTests+Patterns.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestSeedData+CategoryFilter.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrderCategoryGrid/orderCategoryGrid_無障礙字級單欄_符合基準圖.1.png
  - apps/ios/BuyLedger/Resources/Localizable.xcstrings
  - apps/ios/BuyLedger/App/Testing/BLUITestSeedData+CategoryFilterLarge.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFormatters.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersRegularListColumn.swift
  - apps/ios/BuyLedgerTests/OrderEditCampaignOptionsTests.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+Campaigns.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestSeedData.swift
  - apps/ios/BuyLedgerTests/OrderFilterFeatureTests+Search.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersCompactView.swift
  - apps/ios/BuyLedger/Features/Orders/OrderListFeature.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrdersBaseline/ordersView_寬版選取含成本明細訂單_符合基準圖.1.png
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+Destination.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderCategoryPickerTests.swift
  - apps/ios/BuyLedger/Features/Orders/OrderListFeature+Destination.swift
  - apps/ios/BuyLedger.xcodeproj/project.pbxproj
  - apps/ios/BuyLedgerTests/OrderCategoryPickerFeatureTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Orders/ordersCompactView_一般訂單清單_符合基準圖.1.png
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderFilterSheetTests.swift
  - apps/ios/BuyLedgerTests/OrdersQueryTests.swift
  - apps/ios/BuyLedgerTests/OrderSummaryPromptTests.swift
  - apps/ios/BuyLedgerTests/OrdersFeatureTests.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+FilterSheet.swift
  - apps/ios/BuyLedgerTests/OrderListSnapshotSourceScanTests.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+Snapshot.swift
  - apps/ios/BuyLedgerTests/ProjectionWriteBoundaryTests+SharedCampaignScenarios.swift
  - apps/ios/BuyLedgerTests/OrderFilterFeatureTests.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderCategoryPickerSheet.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrdersBaseline/orderFilterSheet_已選日期類別付款方式_符合基準圖.1.png
  - apps/ios/BuyLedgerTests/OrderCategoryPickerFeatureTests+Search.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+FilterDelegates.swift
  - apps/ios/BuyLedger/Features/Orders/OrderListInteraction.swift
  - apps/ios/BuyLedgerTests/OrderCategoryGroupsTests.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+CategoryPickerApply.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderCategoryFilterRows.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+ClearFilterFixtures.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+NewOrderOptions.swift
  - apps/ios/BuyLedgerTests/SnapshotTests+OrderCategoryGrid.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderPaymentMethodMenuTests.swift
  - apps/ios/BuyLedger/Features/Orders/OrderSummaryPrompt.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+Filters.swift
  - apps/ios/BuyLedgerTests/ProjectionWriteBoundaryTests+Scanner.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+CampaignLoading.swift
  - apps/ios/BuyLedgerTests/SnapshotTests+OrdersBaseline.swift
  - apps/ios/BuyLedgerTests/OrdersFilterOperationsTests+FilterSheet.swift
  - apps/ios/BuyLedger/Features/Orders/OrderCategoryPickerFeature.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+Presentation.swift
  - apps/ios/BuyLedgerTests/OrdersSearchCancellationTests.swift
  - apps/ios/README.md
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Orders/ordersCompactView_多選模式_顯示勾選與工具列.1.png
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Chips/BLFilterChipLabel.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+Dates.swift
  - apps/ios/BuyLedgerTests/OrdersFilterOperationsTests+ClearFilters.swift
  - apps/ios/BuyLedger/Features/Orders/OrderListDestinationOperations.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFilterCategorySection.swift
  - apps/ios/BuyLedgerTests/ProjectionWriteBoundaryTests+SharedCampaigns.swift
  - apps/ios/BuyLedgerTests/OrdersQueryTests+Categories.swift
  - apps/ios/BuyLedger/Features/Orders/OrderEditFeature.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrdersBaseline/orderFilterSheet_已收單展開含長名稱_符合基準圖.1.png
  - apps/ios/BuyLedgerTests/CampaignIntegrationTests+Delete.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+ClearFilters.swift
  - apps/ios/BuyLedgerTests/OrdersFilterOperationsTests+FilteredOrders.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersFilterOperations.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Orders/ordersCompactView_長內容訂單清單_避免撐寬版面.1.png
  - apps/ios/BuyLedgerTests/OrdersFeatureTests+LoadAndSummary.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderCategoryPickerLargeTests.swift
  - apps/ios/BuyLedgerAccessibilityIDs/BLAccessibilityID+Orders.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrderCategoryGrid/orderCategoryGrid_單一類別保留一欄寬_符合基準圖.1.png
  - apps/ios/BuyLedger/Features/Orders/OrdersQuery.swift
  - apps/ios/BuyLedger/Features/Orders/OrderListSnapshot.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrderFilterEmptyStates/orderFilterSheet_搜尋無符合類別_符合基準圖.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrderCategoryGrid/orderCategoryGrid_欄數減一_符合基準圖.1.png
  - apps/ios/BuyLedgerUITests/Support/PlatformScope.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersContainerPlan+Requests.swift
  - apps/ios/BuyLedgerTests/OrderCategoryGroupsTests+EntryPoint.swift
  - apps/ios/BuyLedgerTests/CampaignIntegrationTests+Rename.swift
-->

---
### Requirement: Search in the unified filter sheet filters only the category options

The unified filter sheet SHALL place its search field inside the category section, with the prompt `搜尋類別`, and the search SHALL filter category cells only. The search text SHALL NOT affect the date-period menu, the payment-method menu, or the `全部` row, which SHALL remain available regardless of the search text.

When the search text, after trimming whitespace and newlines, is non-empty, each category group SHALL show only the categories whose name contains the trimmed text using a case-insensitive, locale-aware comparison; a text made only of whitespace SHALL be treated as no search; both groups SHALL be displayed expanded while the search text is non-empty, and a group with no matching category SHALL be hidden. When no category in any group matches, the category section SHALL display an empty-state row beneath the `全部` row indicating that nothing matches the current search. Searching SHALL NOT change the pending category set: a selected category that the search hides SHALL remain selected.

The search text, the search field's focus, and the resulting filtered groups SHALL be held by or computed from the orders feature state rather than computed inside the sheet view. The search field SHALL show a clear button while it has text, which empties the search text; pressing the return key SHALL dismiss the keyboard by clearing the focus; scrolling the sheet content SHALL also dismiss the keyboard.

#### Scenario: Search narrows the category groups and expands them

- **GIVEN** the unified filter sheet is open with categories `美妝`, `3C`, `零食` in the 開團中 group and `精品`, `食品`, `書籍` in the 已收單 group, and the 已收單 group is collapsed
- **WHEN** the user types `食` into the search field
- **THEN** the 開團中 group shows only `零食` and the 已收單 group shows only `食品`, and both groups are displayed expanded
- **AND** the date-period and payment-method menu rows and the `全部` row remain visible

#### Scenario: A group without matches is hidden

- **GIVEN** the same categories as above
- **WHEN** the user types `品`
- **THEN** the 開團中 group is hidden and the 已收單 group shows `精品` and `食品`

#### Scenario: Search with no matches shows the all row and an empty state

- **GIVEN** the unified filter sheet is open with available categories `["beauty", "snacks"]`
- **WHEN** the user types text that matches no available category
- **THEN** the category section shows the `全部` row and an empty-state row indicating no categories match
- **AND** no category group is shown

#### Scenario: The clear button empties the search

- **GIVEN** the unified filter sheet is open with the search text `食`
- **WHEN** the user taps the search field's clear button
- **THEN** the search text is empty and every category group is shown with its stored expansion

#### Scenario: Return dismisses the keyboard

- **GIVEN** the search field has focus
- **WHEN** the user presses the return key
- **THEN** the search field loses focus and the search text is kept

#### Scenario: Searching preserves hidden selections

- **GIVEN** the unified filter sheet is open with pending categories {`美妝`, `書籍`}
- **WHEN** the user types `食` and then clears the search text
- **THEN** the pending categories are still {`美妝`, `書籍`}

<!-- @trace
source: order-filter-sheet-redesign
updated: 2026-10-19
code:
  - apps/ios/BuyLedgerTests/OrdersContainerPlanTests+Categories.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+ClearFilterPresentation.swift
  - apps/ios/BuyLedgerTests/OrdersFeaturePerformanceTests+FilterSheet.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+CategoryPickerRoot.swift
  - apps/ios/BuyLedgerTests/OrderCategoryPickerFeatureTests+Dismissal.swift
  - apps/ios/BuyLedgerTests/OrderCategoryPickerFeatureTests+Groups.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+DetailNavigation.swift
  - apps/ios/BuyLedgerUITests/Support/LaunchOptions.swift
  - apps/ios/CLAUDE.md
  - apps/ios/BuyLedgerTests/OrderCategoryGroupsTests+Expansion.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFilterPreviewFixtures.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrderFilterEmptyStates/orderCategoryPickerSheet_搜尋無符合類別_符合基準圖.1.png
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderFilterSheetTests+Assertions.swift
  - apps/ios/BuyLedgerTests/CampaignIntegrationTests.swift
  - apps/ios/BuyLedgerTests/OrderCategoryGridTests.swift
  - apps/ios/BuyLedgerTests/OrderEditFeatureTests+Campaigns.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+FilterLabels.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+FilterSummary.swift
  - apps/ios/BuyLedgerTests/BLUITestSeedDataTests+CategoryFilter.swift
  - apps/ios/BuyLedger/Features/Orders/OrderFilterSelection.swift
  - apps/ios/BuyLedgerTests/OrderFilterFeatureTests+Categories.swift
  - apps/ios/BuyLedgerTests/OrderFilterFeatureTests+Clear.swift
  - apps/ios/BuyLedgerUITests/Screens/OrdersScreen+CategoryPicker.swift
  - apps/ios/BuyLedgerTests/CampaignIntegrationTests+Fixtures.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFilterSheet.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+CategoryPicker.swift
  - apps/ios/BuyLedgerTests/ProjectionWriteBoundaryTests+Orders.swift
  - apps/ios/BuyLedgerTests/OrderCategoryPickerFeatureTests+Selection.swift
  - apps/ios/BuyLedgerUITests/Support/AppNavigator.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersView.swift
  - apps/ios/BuyLedgerTests/OrdersFilterOperationsTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderFilterSheetLargeTests.swift
  - apps/ios/BuyLedgerTests/SnapshotTests+OrderFilterEmptyStates.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFilterDateSection.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFilterPaymentMethodSection.swift
  - apps/ios/BuyLedger/Features/Orders/OrderCategoryGroups.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrderFilterEmptyStates/ordersView_寬版無付款方式與類別_符合基準圖.1.png
  - apps/ios/BuyLedger/Features/Orders/Components/OrderCategoryGrid.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderRegularClearFiltersTests.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+DeepLinks.swift
  - apps/ios/BuyLedgerUITests/Screens/OrdersScreen+FilterSheet.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersFeature.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestSeedProfile.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersListQuery.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+Selection.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Orders/ordersView_大尺寸iPhone橫向_顯示單欄清單與整合篩選鈕.1.png
  - apps/ios/BuyLedgerUITests/Screens/OrdersScreen+RegularFilters.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+OrderFilters.swift
  - apps/ios/BuyLedger/Features/Orders/OrderFilterFeature.swift
  - apps/ios/BuyLedger/Features/Orders/OrderFilterConfirmations.swift
  - apps/ios/BuyLedgerUITests/Screens/OrdersScreen+CategoryReveal.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrderCategoryGrid/orderCategoryGrid_長名稱同列等高_符合基準圖.1.png
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Chips/BLFilterChip.swift
  - apps/ios/BuyLedgerTests/OrderCategoryGroupsTests+Display.swift
  - apps/ios/BuyLedgerTests/OrderFilterFeatureTests+Queries.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+FilterPending.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Orders/ordersView_寬版多選模式_顯示選取列.1.png
  - apps/ios/BuyLedger/Features/App/RootFeature.swift
  - apps/ios/BuyLedgerTests/OrdersFeaturePerformanceTests.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+CategoryPickerSync.swift
  - apps/ios/BuyLedgerTests/ProjectionWriteBoundaryTests+Patterns.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestSeedData+CategoryFilter.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrderCategoryGrid/orderCategoryGrid_無障礙字級單欄_符合基準圖.1.png
  - apps/ios/BuyLedger/Resources/Localizable.xcstrings
  - apps/ios/BuyLedger/App/Testing/BLUITestSeedData+CategoryFilterLarge.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFormatters.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersRegularListColumn.swift
  - apps/ios/BuyLedgerTests/OrderEditCampaignOptionsTests.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+Campaigns.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestSeedData.swift
  - apps/ios/BuyLedgerTests/OrderFilterFeatureTests+Search.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersCompactView.swift
  - apps/ios/BuyLedger/Features/Orders/OrderListFeature.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrdersBaseline/ordersView_寬版選取含成本明細訂單_符合基準圖.1.png
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+Destination.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderCategoryPickerTests.swift
  - apps/ios/BuyLedger/Features/Orders/OrderListFeature+Destination.swift
  - apps/ios/BuyLedger.xcodeproj/project.pbxproj
  - apps/ios/BuyLedgerTests/OrderCategoryPickerFeatureTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Orders/ordersCompactView_一般訂單清單_符合基準圖.1.png
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderFilterSheetTests.swift
  - apps/ios/BuyLedgerTests/OrdersQueryTests.swift
  - apps/ios/BuyLedgerTests/OrderSummaryPromptTests.swift
  - apps/ios/BuyLedgerTests/OrdersFeatureTests.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+FilterSheet.swift
  - apps/ios/BuyLedgerTests/OrderListSnapshotSourceScanTests.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+Snapshot.swift
  - apps/ios/BuyLedgerTests/ProjectionWriteBoundaryTests+SharedCampaignScenarios.swift
  - apps/ios/BuyLedgerTests/OrderFilterFeatureTests.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderCategoryPickerSheet.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrdersBaseline/orderFilterSheet_已選日期類別付款方式_符合基準圖.1.png
  - apps/ios/BuyLedgerTests/OrderCategoryPickerFeatureTests+Search.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+FilterDelegates.swift
  - apps/ios/BuyLedger/Features/Orders/OrderListInteraction.swift
  - apps/ios/BuyLedgerTests/OrderCategoryGroupsTests.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+CategoryPickerApply.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderCategoryFilterRows.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+ClearFilterFixtures.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+NewOrderOptions.swift
  - apps/ios/BuyLedgerTests/SnapshotTests+OrderCategoryGrid.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderPaymentMethodMenuTests.swift
  - apps/ios/BuyLedger/Features/Orders/OrderSummaryPrompt.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+Filters.swift
  - apps/ios/BuyLedgerTests/ProjectionWriteBoundaryTests+Scanner.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+CampaignLoading.swift
  - apps/ios/BuyLedgerTests/SnapshotTests+OrdersBaseline.swift
  - apps/ios/BuyLedgerTests/OrdersFilterOperationsTests+FilterSheet.swift
  - apps/ios/BuyLedger/Features/Orders/OrderCategoryPickerFeature.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+Presentation.swift
  - apps/ios/BuyLedgerTests/OrdersSearchCancellationTests.swift
  - apps/ios/README.md
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Orders/ordersCompactView_多選模式_顯示勾選與工具列.1.png
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Chips/BLFilterChipLabel.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+Dates.swift
  - apps/ios/BuyLedgerTests/OrdersFilterOperationsTests+ClearFilters.swift
  - apps/ios/BuyLedger/Features/Orders/OrderListDestinationOperations.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFilterCategorySection.swift
  - apps/ios/BuyLedgerTests/ProjectionWriteBoundaryTests+SharedCampaigns.swift
  - apps/ios/BuyLedgerTests/OrdersQueryTests+Categories.swift
  - apps/ios/BuyLedger/Features/Orders/OrderEditFeature.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrdersBaseline/orderFilterSheet_已收單展開含長名稱_符合基準圖.1.png
  - apps/ios/BuyLedgerTests/CampaignIntegrationTests+Delete.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+ClearFilters.swift
  - apps/ios/BuyLedgerTests/OrdersFilterOperationsTests+FilteredOrders.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersFilterOperations.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Orders/ordersCompactView_長內容訂單清單_避免撐寬版面.1.png
  - apps/ios/BuyLedgerTests/OrdersFeatureTests+LoadAndSummary.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderCategoryPickerLargeTests.swift
  - apps/ios/BuyLedgerAccessibilityIDs/BLAccessibilityID+Orders.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrderCategoryGrid/orderCategoryGrid_單一類別保留一欄寬_符合基準圖.1.png
  - apps/ios/BuyLedger/Features/Orders/OrdersQuery.swift
  - apps/ios/BuyLedger/Features/Orders/OrderListSnapshot.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrderFilterEmptyStates/orderFilterSheet_搜尋無符合類別_符合基準圖.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrderCategoryGrid/orderCategoryGrid_欄數減一_符合基準圖.1.png
  - apps/ios/BuyLedgerUITests/Support/PlatformScope.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersContainerPlan+Requests.swift
  - apps/ios/BuyLedgerTests/OrderCategoryGroupsTests+EntryPoint.swift
  - apps/ios/BuyLedgerTests/CampaignIntegrationTests+Rename.swift
-->