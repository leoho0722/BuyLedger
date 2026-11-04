# order-category-filter Specification

## Purpose

TBD - created by archiving change 'ai-product-summary'. Update Purpose after archive.

## Requirements

### Requirement: Category filter on the orders list

The orders list SHALL provide a product-category filter that coexists with the existing status, date-period, payment-method, and search filters on iOS and iPadOS. The category filter SHALL hold a set of selected categories, so that the user can select any number of categories at once. The filter SHALL offer an "all categories" option plus one option per available category. The available categories SHALL be sourced from the existing merged category options (category master plus categories used by orders). Selecting "all categories" SHALL empty the selected set, which clears the category constraint.

#### Scenario: Select a specific category

- **WHEN** the user's selected category set is {`beauty`}
- **THEN** the orders list shows only orders whose category list contains `beauty`, while still honoring the active status, date-period, payment-method, and search filters

#### Scenario: Select several categories

- **WHEN** the user's selected category set is {`beauty`, `books`}
- **THEN** the orders list shows every order whose category list contains `beauty` or `books`, while still honoring the other active filters

#### Scenario: Select all categories

- **WHEN** the user selects the "all categories" option
- **THEN** the selected category set becomes empty and the orders list is no longer narrowed by category


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
### Requirement: Category filter combines with existing filters

The filtered orders result SHALL be the conjunction of the status, search, date-period, payment-method, and category predicates. A category constraint SHALL match an order when the order's category list contains at least one category of the selected set; an empty selected set SHALL match every order. After a committed category change, the current destination SHALL follow the matching-selection rule of `navigation-path-integrity`, without automatically selecting the first result.

#### Scenario: Category combined with status filter

- **WHEN** both a status filter and a category filter are active
- **THEN** only orders matching the status and containing at least one selected category appear in the list

##### Example: conjunction of filters with multi-category orders

- **GIVEN** orders: O1(categories=["beauty"], status=purchased), O2(categories=["beauty", "snacks"], status=quoting), O3(categories=["snacks"], status=purchased), O4(categories=["books"], status=purchased), O5(categories=[], status=purchased)

| Status filter | Selected categories | Listed orders |
| --- | --- | --- |
| purchased | {beauty} | { O1 } |
| purchased | {beauty, snacks} | { O1, O3 } |
| purchased | {books} | { O4 } |
| purchased | none | { O1, O3, O4, O5 } |
| all | {snacks} | { O2, O3 } |

#### Scenario: Category changes retain only a matching destination

- **GIVEN** the orders list has a current destination or no selection
- **WHEN** the committed category set changes
- **THEN** the system retains the existing destination and detail state if it remains in the filtered result, and clears it otherwise
- **AND** an unselected list stays unselected without choosing the first order


<!-- @trace
source: adaptive-navigation-continuity
updated: 2026-11-04
code:
  - apps/ios/BuyLedgerUITests/Support/BLUITestCase.swift
  - apps/ios/BuyLedgerTests/Shared/DesignSystem/BLBarChartLayoutTests.swift
  - apps/ios/BuyLedgerTests/Features/Campaigns/CampaignIntegrationTests.swift
  - apps/ios/BuyLedgerUITests/Support/XCTestCase+HorizontalBounds.swift
  - apps/ios/BuyLedgerUITests/Screens/Orders/OrdersScreen.swift
  - apps/ios/BuyLedgerTests/Features/Campaigns/CampaignFeatureDeletionReminderTests.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersFilterOperationsFilterSheetTests.swift
  - apps/ios/BuyLedger/Features/Campaigns/Presentation/CampaignPresentation/CampaignPresentationFeature.swift
  - apps/ios/BuyLedger/Features/Campaigns/Presentation/Root/CampaignRequestPlan.swift
  - apps/ios/BuyLedgerUITests/Support/AppNavigator.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrderFilterFeatureClearTests.swift
  - apps/ios/BuyLedgerUITests/Screens/Orders/OrderEditScreen.swift
  - apps/ios/BuyLedger/Features/App/Presentation/Root/RootSidebarLayout.swift
  - apps/ios/BuyLedger/Features/Insights/Presentation/Root/Views/InsightsHeatmapCard.swift
  - apps/ios/BuyLedgerUITests/Support/Interactions/MenuInteraction.swift
  - apps/ios/BuyLedgerUITests/Tests/Tools/FxTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Pickers/OptionPickerSheet.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotOrdersTests/ordersView_大尺寸iPhone橫向_分欄顯示清單與整合篩選鈕.1.png
  - apps/ios/README.md
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersContainerPlanWritesTests.swift
  - apps/ios/BuyLedger/Features/App/Presentation/Root/RootFeature.swift
  - apps/ios/BuyLedgerUITests/Support/Assertions/Diagnostics.swift
  - apps/ios/BuyLedger.xcodeproj/project.xcproj
  - apps/ios/BuyLedger/Features/Lookups/Presentation/PaymentMethodEditForm/PaymentMethodEditFormFeature.swift
  - apps/ios/BuyLedgerTests/Features/Campaigns/CampaignFeatureReloadDeleteTests.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotInsightsTests/insightsCategoryCard_393點寬最大輔助字級_金額不斷字.1.png
  - apps/ios/BuyLedgerUITests/Tests/Navigation/ReadableWidthUITests.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersFeatureListEntryTests.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/OrderDetail/Views/OrderDetailView.swift
  - apps/ios/BuyLedgerUITests/Support/XCTestCase+Assertions.swift
  - apps/ios/BuyLedgerUITests/Support/Assertions/ValueParsing.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/Root/Plans/OrdersWriteOutcome.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLBarChart.swift
  - apps/ios/BuyLedger/Resources/Localizable.xcstrings
  - apps/ios/BuyLedgerUITests/Screens/More/LookupManagementScreen.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrderListFeatureCategoryPickerApplyTests.swift
  - apps/ios/BuyLedgerUITests/Support/LaunchOptions.swift
  - apps/ios/BuyLedgerTests/Guards/OrderListSnapshotSourceScanTests.swift
  - apps/ios/BuyLedgerTests/Guards/DesignSystemSourceScan/DesignSystemSourceScanner.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/Filters/OrderFilterSheetTests.swift
  - apps/ios/BuyLedger/Features/Campaigns/Presentation/Root/CampaignFeature+Path.swift
  - apps/ios/BuyLedger/Features/Campaigns/Presentation/Root/CampaignView.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersSearchCancellationTests.swift
  - apps/ios/BuyLedgerTests/Guards/ProjectionWriteBoundary/ProjectionWriteBoundaryGuardsTests.swift
  - apps/ios/BuyLedgerTests/Support/OrderListFeatureTestSupport.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersFilterOperationsClearFiltersTests.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrderFilterFeatureCategoriesTests.swift
  - apps/ios/BuyLedgerTests/Features/App/RootFeatureForegroundTests.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotOrdersTests/ordersCompactView_多選模式_顯示勾選與工具列.1.png
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotOrdersTests/ordersCompactView_一般訂單清單_符合基準圖.1.png
  - apps/ios/BuyLedgerTests/SnapshotTests/SnapshotCampaignsTests.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotOrderEditSectionsTests/orderEditItemsSection_最大輔助字級_商品列堆疊排列.1.png
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotCampaignsTests/campaignListView_依年分組_符合基準圖.1.png
  - apps/ios/BuyLedgerTests/Guards/LayerBoundary/LayerBoundaryTests.swift
  - apps/ios/BuyLedger/Features/Lookups/Presentation/Root/Views/LookupManagementView.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrderListFeatureFilterDelegatesTests.swift
  - apps/ios/BuyLedgerUITests/Screens/Campaigns/CampaignEditScreen.swift
  - apps/ios/BuyLedgerTests/Support/RootFeatureTestSupport.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLDonutChart.swift
  - apps/ios/BuyLedgerTests/Support/View+LayoutMeasurement.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/Regular/OrderRegularAccessibilitySizeTests.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersFeatureMergeSaveTests.swift
  - apps/ios/BuyLedgerTests/Guards/ToolReadableWidthGuardTests.swift
  - apps/ios/BuyLedgerAccessibilityIDs/BLAccessibilityID+More.swift
  - apps/ios/BuyLedgerTests/Features/Lookups/LookupRenameFormFeatureTests.swift
  - apps/ios/BuyLedgerUITests/Support/Interactions/SheetInteraction.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotOrderFilterEmptyStatesTests/ordersView_寬版清單欄無付款方式與類別_符合基準圖.1.png
  - apps/ios/BuyLedgerTests/SnapshotTests/SnapshotToolsTests.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotDashboardTests/dashboardView_寬版_並排顯示hero與KPI.1.png
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotOrderFilterEmptyStatesTests/ordersRegularListContent_寬版清單欄無付款方式與類別_符合基準圖.1.png
  - apps/ios/BuyLedger/Features/Campaigns/Presentation/CampaignList/Views/CampaignRow.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersViewLayoutTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Navigation/NavigationScenarioUITests.swift
  - apps/ios/BuyLedgerUITests/Support/Interactions/TextInput.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrderListFeatureClearFilterPresentationTests.swift
  - apps/ios/BuyLedgerUITests/Support/XCUIElement+Waiting.swift
  - apps/ios/BuyLedger/Features/Campaigns/Presentation/CampaignList/Views/CampaignSectionList.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/Root/Plans/OrdersContainerPlan+Requests.swift
  - apps/ios/BuyLedger/Features/App/Presentation/Root/RootNavigationLayout.swift
  - apps/ios/BuyLedger/Features/Campaigns/Presentation/CampaignList/Views/CampaignListView.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersContainerPlanRequestsTests.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotCampaignsTests/campaignListView_依日分組同日三筆與他日一筆_符合基準圖.1.png
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotInsightsTests/insightsTrendCard_393點寬最大輔助字級_走勢軸標不重疊.1.png
  - apps/ios/BuyLedgerUITests/Tests/Smoke/LaunchSmokeTests.swift
  - apps/ios/BuyLedgerTests/Features/App/RootFeatureOrderFiltersTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/Regular/OrderRegularSearchBarTests.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotOrderDetailTests/orderDetailView_393點寬最大輔助字級_標頭與卡片留在畫面內.1.png
  - apps/ios/BuyLedger/Features/Orders/Presentation/OrdersDetailNavigation/OrdersDetailSelection.swift
  - apps/ios/BuyLedgerUITests/Screens/Tools/QuoteScreen.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/Root/Plans/OrdersContainerPlan+Writes.swift
  - apps/ios/BuyLedgerUITests/Support/BoundsCheck.swift
  - apps/ios/BuyLedgerUITests/Support/XCTestCase+CampaignFlow.swift
  - apps/ios/BuyLedger/Features/Dashboard/Presentation/Root/Views/DashboardSummarySection.swift
  - apps/ios/BuyLedger/Features/App/Presentation/Root/RootTabLayout.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/SnapshotOrderDetailTests.swift
  - apps/ios/BuyLedgerTests/Features/App/RootFeatureLoadRequestsTests.swift
  - apps/ios/BuyLedgerTests/Features/App/RootFeatureDetailNavigationTests.swift
  - apps/ios/BuyLedgerTests/AccessibilityIDs/BLAccessibilityIDTests.swift
  - apps/ios/BuyLedgerTests/Features/Campaigns/CampaignFeaturePresentationTests.swift
  - apps/ios/BuyLedgerTests/Features/App/RootFeatureLookupSyncTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/ViewModifiers/BLReadableContentLayout.swift
  - apps/ios/BuyLedger/Features/Dashboard/Presentation/Root/Views/DashboardView.swift
  - apps/ios/BuyLedgerUITests/Support/CheckOutcome.swift
  - apps/ios/BuyLedger/Features/Campaigns/Presentation/CampaignPresentation/CampaignPresentationQueue.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/SnapshotOrdersTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/Edit/KeyboardDismissTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Customers/CustomersTests.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrderListFeatureFilterSheetTests.swift
  - apps/ios/BuyLedger/Features/Campaigns/Presentation/CampaignDetail/CampaignDetailView.swift
  - apps/ios/BuyLedgerTests/Features/Campaigns/CampaignFeatureFailureTimingTests.swift
  - apps/ios/BuyLedgerUITests/Screens/App/RootNavigationScreen.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLCardRowMetrics.swift
  - apps/ios/BuyLedgerUITests/Support/PathCheck.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/OrderDetail/Views/OrderDetailItemsView.swift
  - apps/ios/BuyLedgerUITests/Support/XCUIApplication+NavigationBackInteraction.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersLoadStateTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/Filters/OrderPaymentMethodMenuTests.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersFeatureCreateTests.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/SnapshotOrdersBaselineTests.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrderListFeatureClearFiltersTests.swift
  - apps/ios/BuyLedgerUITests/Support/XCTestCase+OrdersLayoutAssertions.swift
  - apps/ios/BuyLedger/Features/Quote/Presentation/Root/QuoteInputsCard.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrderListFeatureTests.swift
  - apps/ios/BuyLedger/Features/Campaigns/Presentation/Root/CampaignRequest.swift
  - apps/ios/BuyLedgerUITests/Screens/More/SettingsScreen.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotDashboardTests/dashboardView_最大輔助字級_目標進度堆疊排列.1.png
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersFeatureMergeWritesTests.swift
  - apps/ios/BuyLedgerUITests/Support/Launch/BLUITestCase.swift
  - apps/ios/BuyLedgerUITests/Support/Assertions/Waiting.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/ViewModifiers/BLReadableScrollContentLayout.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersFilterOperationsSearchAndSelectionTests.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersFeatureListRequestsTests.swift
  - apps/ios/BuyLedgerUITests/Support/XCTestCase+Diagnostics.swift
  - apps/ios/BuyLedgerUITests/Support/XCUIElement+ValueParsing.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/OrderList/Operations/OrderListInteraction.swift
  - apps/ios/BuyLedgerUITests/Tests/Dashboard/DashboardLayoutSmokeTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/Filters/OrderCategoryPickerTests.swift
  - apps/ios/BuyLedger/Features/Campaigns/Presentation/CampaignEdit/CampaignEditView.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersContainerPlanTests.swift
  - apps/ios/BuyLedgerTests/Guards/BottomBarPlacementScanTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Navigation/AdaptiveLayoutCheckCounterexampleTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/Filters/OrderFilterSheetLargeTests.swift
  - apps/ios/CLAUDE.md
  - apps/ios/BuyLedger/Features/Orders/Presentation/OrderList/Operations/OrdersFilterOperations.swift
  - apps/ios/BuyLedger/Features/Insights/Presentation/Root/Views/InsightsCategoryCard.swift
  - apps/ios/BuyLedgerTests/Features/Lookups/LookupAddFormFeatureTests.swift
  - apps/ios/BuyLedger/Features/Campaigns/Presentation/CampaignList/CampaignListFeature.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/OrderEdit/Views/Sections/OrderEditItemsSection.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotCampaignsTests/campaignListView_依日分組含今天與昨天_符合基準圖.1.png
  - apps/ios/BuyLedgerTests/Guards/LayerBoundary/LanguageProjectionBoundaryTests.swift
  - apps/ios/BuyLedgerUITests/Support/XCUIApplication+TextInput.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/Regular/OrderRegularColumnScopeTests.swift
  - apps/ios/BuyLedgerTests/Features/Campaigns/CampaignFeatureWriteFailuresTests.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/SnapshotOrderFilterEmptyStatesTests.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersFeatureFilterPathTests.swift
  - apps/ios/BuyLedgerTests/Features/Campaigns/CampaignPresentationQueueTests.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/SnapshotOrderEditSectionsTests.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotToolsTests/quoteView_最大輔助字級_輸入列堆疊排列.1.png
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotOrderDetailTests/orderDetailSections_頁面內容寬361最大輔助字級_成本圖例與商品金額不斷字.1.png
  - apps/ios/BuyLedger/Features/Orders/Presentation/OrderList/Operations/OrderListDestinationOperations.swift
  - apps/ios/BuyLedgerUITests/Support/Launch/AppNavigator.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotInsightsTests/insightsView_寬版_並排顯示類別排行與成本結構.1.png
  - apps/ios/BuyLedgerUITests/Support/Launch/LaunchOptions.swift
  - apps/ios/BuyLedgerTests/Support/ViewLayoutMeasurementSupport.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/Root/Plans/OrdersRequestOutcome.swift
  - apps/ios/BuyLedgerTests/Guards/LayerBoundary/LanguageProjectionScanner.swift
  - apps/ios/BuyLedger/Features/Lookups/Presentation/Root/Views/LookupNameEditorSheet.swift
  - apps/ios/BuyLedgerUITests/Support/Layout/Orientation.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersFeatureDateRefreshTests.swift
  - apps/ios/BuyLedgerTests/Features/More/MoreFeatureRelaysTests.swift
  - apps/ios/BuyLedger/Features/More/Presentation/Root/MoreFeature.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrdersListTests.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotOrdersTests/ordersView_大尺寸iPhone橫向_顯示單欄清單與整合篩選鈕.1.png
  - apps/ios/BuyLedger/Features/Insights/Presentation/Root/Views/InsightsView.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotInsightsTests/insightsCostStructureCard_393點寬最大輔助字級_圓餅圖與中心文字留在卡片內.1.png
  - apps/ios/BuyLedgerUITests/Screens/Dashboard/DashboardScreen.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/OrderDetail/Views/OrderDetailContentView.swift
  - apps/ios/BuyLedger/Features/Lookups/Presentation/LookupRenameForm/LookupRenameFormFeature.swift
  - apps/ios/BuyLedgerUITests/Support/Layout/HorizontalBounds.swift
  - apps/ios/BuyLedgerTests/Features/Lookups/PaymentMethodEditFormFeatureTests.swift
  - apps/ios/BuyLedger/Features/Dashboard/Presentation/Root/Views/DashboardHeroCard.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/Root/Views/OrdersRegularListColumn.swift
  - apps/ios/BuyLedgerUITests/Support/Interactions/AlertInteraction.swift
  - apps/ios/BuyLedgerTests/Guards/DesignSystemSourceScan/DesignSystemSourceScanTests.swift
  - apps/ios/BuyLedgerTests/Features/More/MoreFeatureTests.swift
  - apps/ios/BuyLedgerTests/Features/Lookups/LookupManagementFeaturePaymentMethodCorrectionTests.swift
  - apps/ios/BuyLedgerTests/Features/Campaigns/CampaignFeatureFailureTimingFollowUpTests.swift
  - apps/ios/BuyLedgerUITests/Screens/Insights/InsightsScreen.swift
  - apps/ios/BuyLedgerUITests/Support/KPIPresenceCheck.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotCampaignsTests/campaignListView_依月分組_符合基準圖.1.png
  - apps/ios/BuyLedger/Features/Orders/Presentation/Root/Views/OrdersView.swift
  - apps/ios/BuyLedger/Features/Settings/Presentation/Root/SettingsView.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/SnapshotInsightsTests.swift
  - apps/ios/BuyLedger/Features/Lookups/Presentation/Root/Views/LookupManagementPresentations.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/Root/Views/OrdersRegularListContent.swift
  - apps/ios/BuyLedger/Features/Lookups/Presentation/Root/LookupManagementFeature+Destination.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/Regular/OrderRegularClearFiltersTests.swift
  - apps/ios/BuyLedgerTests/Features/Campaigns/CampaignFeatureReloadTests.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotCampaignsTests/campaignListView_選取其中一筆開團_符合基準圖.1.png
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLLayoutClass.swift
  - apps/ios/BuyLedgerUITests/Tests/Tools/QuoteTests.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotInsightsTests/insightsView_大尺寸iPhone橫向_類別排行與成本結構上下堆疊.1.png
  - apps/ios/BuyLedger/Features/Campaigns/Presentation/Root/CampaignFeature.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersFilterOperationsSearchTests.swift
  - apps/ios/BuyLedger/Features/More/Presentation/Root/MoreView.swift
  - apps/ios/BuyLedgerTests/Features/App/RootFeatureTabSelectionTests.swift
  - apps/ios/BuyLedgerUITests/Support/XCTestCase+Orientation.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersFilterOperationsTests.swift
  - apps/ios/BuyLedgerUITests/Support/XCUIApplication+MenuInteraction.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/SnapshotDashboardTests.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/Root/OrdersFeature.swift
  - apps/ios/BuyLedgerUITests/Support/IdentifierCheck.swift
  - apps/ios/BuyLedger/App/Testing/Configuration/BLUITestConfiguration.swift
  - apps/ios/BuyLedgerUITests/Support/CampaignSeedFixture.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotInsightsTests/insightsView_載入中_顯示載入骨架.1.png
  - apps/ios/BuyLedgerUITests/Support/XCUIElement+TextInput.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotDashboardTests/dashboardView_寬版_摘要在上四項KPI兩欄.1.png
  - apps/ios/BuyLedgerTests/Features/Orders/OrderSaveGuardTests.swift
  - apps/ios/BuyLedgerTests/Features/Campaigns/CampaignFeatureNavigationTests.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/Components/OrdersFilterControlsView.swift
  - apps/ios/BuyLedgerUITests/Tests/More/LookupManagementTests.swift
  - apps/ios/BuyLedgerUITests/Screens/Tools/FxScreen.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotCampaignsTests/campaignListView_英文月分組_符合基準圖.1.png
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersFeatureEditFieldsTests.swift
  - apps/ios/BuyLedgerTests/Features/Lookups/LookupManagementFeatureFailuresTests.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/OrdersDetailNavigation/OrdersDetailNavigationFeature.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Cards/BLCardRowPosition.swift
  - apps/ios/BuyLedgerTests/Features/More/MoreFeatureEntrySelectionTests.swift
  - apps/ios/BuyLedgerUITests/Support/XCTestCase+PlatformScope.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotOrderDetailTests/orderDetailSections_頁面內容寬361最大輔助字級_大額金額完整不裁切.1.png
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersFeatureLoadAndSummaryTests.swift
  - apps/ios/BuyLedgerTests/Support/CampaignFeatureTestSupport.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotMoreTests/moreView_預設清單_顯示各入口.1.png
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersFeatureOptionWritesTests.swift
  - apps/ios/BuyLedgerTests/Shared/DesignSystem/BLLayoutClassTests.swift
  - apps/ios/BuyLedgerUITests/Support/Interactions/Scrolling.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotInsightsTests/insightsView_寬版_卡片依固定順序垂直排列.1.png
  - apps/ios/BuyLedgerTests/Features/App/RootFeatureSidebarTests.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/OrderList/OrderListFeature.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotOrdersTests/ordersView_寬版清單欄多選模式_顯示選取列.1.png
  - apps/ios/BuyLedger/Features/Orders/Presentation/Root/Views/OrdersCompactView.swift
  - apps/ios/BuyLedgerTests/Shared/DesignSystem/BLReadableScrollContentLayoutTests.swift
  - apps/ios/BuyLedgerUITests/Support/Assertions/Assertions.swift
  - apps/ios/BuyLedger/Features/Dashboard/Presentation/Root/Views/DashboardKPITiles.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersFeatureDeleteEditFailuresTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrdersNavigationSmokeTests.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrderListFeatureDatesTests.swift
  - apps/ios/BuyLedgerTests/Features/Lookups/LookupManagementFeatureTestSupport.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/Root/Requests/OrderRequestPlan.swift
  - apps/ios/BuyLedgerUITests/Support/XCUIApplication+Diagnostics.swift
  - apps/ios/BuyLedgerUITests/Support/XCUIApplication+SheetInteraction.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/OrderDetail/Views/OrderDetailCostView.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotOrdersTests/ordersCompactView_長內容訂單清單_避免撐寬版面.1.png
  - apps/ios/BuyLedgerTests/Features/Campaigns/CampaignPresentationFeatureTests.swift
  - apps/ios/BuyLedgerTests/Features/Lookups/LookupManagementFeatureAlertTimingTests.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/Root/Views/OrdersRegularDetailColumn.swift
  - apps/ios/BuyLedgerUITests/Tests/Smoke/OrientationLayoutTests.swift
  - apps/ios/BuyLedgerTests/Shared/DesignSystem/BLReadableContentLayoutTests.swift
  - apps/ios/BuyLedgerUITests/Support/XCUIApplication+Scrolling.swift
  - apps/ios/BuyLedgerUITests/Tests/Tools/SettingsGoalInputTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Forms/PaymentMethodEditorSheet.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrderListFeatureFiltersTests.swift
  - apps/ios/BuyLedgerUITests/Screens/Orders/OrderFilterSheetScreen.swift
  - apps/ios/BuyLedger/Features/Lookups/Presentation/Root/LookupManagementFeature.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersDetailNavigationFeatureTests.swift
  - apps/ios/BuyLedgerUITests/Screens/Campaigns/CampaignsScreen.swift
  - apps/ios/BuyLedgerUITests/Tests/More/MoreNavigationSmokeTests.swift
  - apps/ios/BuyLedger/Features/Lookups/Presentation/Root/Views/LookupItemList.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/Root/Plans/OrdersContainerPlan.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Cards/BLCardRowBackground.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/Root/Requests/OrderRequest.swift
  - apps/ios/BuyLedgerUITests/Tests/Navigation/AdaptiveNavigationContinuityUITests.swift
  - apps/ios/BuyLedgerUITests/Support/XCUIApplication+StableVisibleFrame.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotOrderDetailTests/orderDetailCostView_393點寬最大輔助字級_成本卡圓餅圖與中心文字在卡片內.1.png
  - apps/ios/BuyLedger/Features/FX/Presentation/Root/FxView.swift
  - apps/ios/BuyLedgerTests/Features/App/RootFeatureSharedOrdersTests.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/OrderList/Views/OrdersCompactListView.swift
  - apps/ios/BuyLedger/Features/App/Presentation/Root/RootView.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLReadableContentType.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersFeatureDetailTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/Regular/OrderRegularColumnWidthTests.swift
  - apps/ios/BuyLedgerUITests/Support/XCUIApplication+AlertInteraction.swift
  - apps/ios/BuyLedgerTests/Features/App/RootFeaturePaymentMethodCorrectionTests.swift
  - apps/ios/BuyLedger/Features/Campaigns/Presentation/CampaignPresentation/CampaignPresentationFeature+Destination.swift
  - apps/ios/BuyLedgerAccessibilityIDs/BLAccessibilityID+Insights.swift
  - apps/ios/BuyLedger/Features/Customers/Presentation/Root/CustomersView.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotOrdersTests/ordersCompactView_同日三筆與他日一筆_符合基準圖.1.png
  - apps/ios/BuyLedgerUITests/Tests/Insights/InsightsLayoutSmokeTests.swift
  - apps/ios/BuyLedgerTests/Guards/ActionGrouping/ActionGroupingScanner.swift
  - apps/ios/BuyLedgerTests/Shared/DesignSystem/BLLayoutClassEnvironmentTests.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/OrderEdit/Views/OrderEditView.swift
  - apps/ios/BuyLedger/Features/Quote/Presentation/Root/QuoteView.swift
  - apps/ios/BuyLedgerTests/Features/Campaigns/CampaignListFeatureInteractionsTests.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersFeatureStatusFailuresTests.swift
  - apps/ios/BuyLedger/Features/Lookups/Presentation/LookupAddForm/LookupAddFormFeature.swift
  - apps/ios/BuyLedgerUITests/Support/Layout/PlatformScope.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/Filters/OrderCategoryPickerLargeTests.swift
  - apps/ios/BuyLedgerUITests/Support/ValueParsing.swift
  - apps/ios/BuyLedgerUITests/Tests/Campaigns/CampaignFlowTests.swift
  - apps/ios/BuyLedgerAccessibilityIDs/BLAccessibilityID+Common.swift
-->

---
### Requirement: Deep link from analytics applies the category filter

When the user taps a category row in the analytics page's category ranking, the app SHALL navigate to the orders tab and set the orders list's selected category set to exactly the tapped category. The selected category set SHALL drive both the orders list filtering and the visual state of the category filter trigger and category grid (trigger label and selected cells compare against the selected set). The orders list SHALL be filtered by containment against each order's category list — it SHALL NOT rely on text search to approximate the filter.

#### Scenario: Tapping a category row navigates and applies the filter

- **WHEN** the user is on the analytics page and taps the category row whose name is "beauty"
- **THEN** the active tab changes to "orders"
- **AND** the orders list's selected category set equals {"beauty"}
- **AND** on iPadOS the category filter trigger label reads `類別：beauty` and the trigger background uses the active-selection style
- **AND** opening the category grid shows the `beauty` cell as the only selected cell
- **AND** the orders list contains exactly those orders whose category list contains "beauty"

##### Example: deep link with mixed-category data

- **GIVEN** orders: O1(categories=["beauty"], customer="Alice"), O2(categories=["snacks"], customer="Beauty Bob"), O3(categories=["beauty", "snacks"], customer="Carol")
- **WHEN** the user taps the "beauty" row in the analytics category ranking
- **THEN** the orders list contains exactly { O1, O3 } and excludes O2, even though O2's customer name contains the substring "Beauty"

#### Scenario: Tapping a category row replaces an earlier multi-selection

- **WHEN** the orders list has the selected category set {"snacks", "books"}, then the user taps the "beauty" row on the analytics page
- **THEN** the selected category set equals {"beauty"}

#### Scenario: Tapping a category row resets unrelated orders-list filters

- **WHEN** the user has the orders list state with status filter "delivered" and date-period filter "this month", then taps a category row on the analytics page
- **THEN** the status filter resets to "all"
- **AND** the date-period filter resets to "all"
- **AND** the search text is cleared
- **AND** the selected category set equals the tapped category alone


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
### Requirement: Cross-feature navigations reset the category filter

Cross-feature navigations into the orders list SHALL reset the orders list's selected category set to empty ("all categories") unless the navigation explicitly applies a category. This applies to navigations originating from customer-name selection. This prevents a stale category filter from intersecting with the new navigation's filters and producing an empty list.

#### Scenario: Customer deep link clears a stale category filter

- **WHEN** the user has the orders list selected category set {"snacks", "books"}, then taps the customer name "Alice" from the customers page
- **THEN** the active tab changes to "orders"
- **AND** the orders list's search text equals "Alice"
- **AND** the selected category set becomes empty


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
### Requirement: Category filter is presented as a trigger button with a searchable picker sheet

In this requirement "iPadOS" means the regular-width orders layout; an iPad window that uses the compact orders layout exposes the category filter through the unified filter sheet instead. On iPadOS the orders list category filter SHALL be rendered as a single capsule-shaped trigger button. The trigger button SHALL summarize the committed category selection in its label so the user can identify it without opening the picker. The category filter SHALL NOT be rendered as a horizontally scrolling row of capsule chips and SHALL NOT be rendered as an inline Menu.

On iOS in the Compact size class the orders list category filter SHALL instead be folded into the unified filter sheet defined by the `order-filter-sheet` capability. The dedicated category trigger described in this requirement SHALL NOT be rendered in that size class.

The trigger button SHALL occupy the full available horizontal width of the orders filter area on every platform where it is rendered, so its left and right edges align with the search field and other full-width controls above it.

The trigger button label SHALL be composed of, in order:
1. A leading tag icon consistent with the icon previously used by the category chips.
2. A text segment of the form `類別：<current>`, where `<current>` is `全部` when the selected set is empty, the category name when exactly one category is selected, and `<N> 項` when N ≥ 2 categories are selected. The text segment SHALL support multi-line wrapping when the category name exceeds the available single-line width — the capsule SHALL grow vertically to fit the wrapped text rather than truncating it.
3. A trailing chevron-down indicator that communicates the control opens a picker sheet.

When the label wraps to multiple lines, the leading tag icon and the trailing chevron-down icon SHALL align to the first text baseline rather than the vertical center of the capsule.

The trigger button SHALL apply a filled capsule background. The fill SHALL be the active-selection style when at least one category is selected and the inactive-selection style otherwise, so the user can tell from the trigger alone whether a category filter is currently applied.

The trigger button SHALL only be rendered when the set of available categories is non-empty. When no categories are available, the category filter UI on iPadOS SHALL be hidden, matching the prior behavior.

Tapping the trigger button SHALL present a category picker sheet titled `選擇商品類別` that:
1. Holds a pending category set seeded from the committed set when presented, together with an empty search text and group expansion computed by the "Category options are grouped by campaign activity" requirement. The pending set, search text, and expansion SHALL be held by the orders feature rather than by the view.
2. Shows, in order, a search field with the prompt `搜尋類別`, an "all categories" row labeled `全部`, and the grouped category grid shared with the iPhone unified filter sheet. The search narrows the grid with the same rules as the iPhone unified filter sheet search; the `全部` row stays visible regardless of the search text.
3. Toggles a category's membership in the pending set when its cell is tapped, and empties the pending set when the `全部` row is tapped, without dismissing the sheet and without changing the committed selection.
4. Presents a confirmation control labeled `完成` that commits the pending set as the committed selection, recomputes the currently selected order once when the set changed, and dismisses the sheet.
5. Presents a cancellation control that never commits the pending set. When the pending set differs from the committed set, cancelling SHALL ask for confirmation and swiping down SHALL NOT dismiss the sheet, as defined by the sheet-dismissal-safeguard capability.

#### Scenario: Trigger label reflects the committed selection on iPadOS

- **GIVEN** the orders list is displayed on iPadOS and has at least one available category
- **WHEN** the committed category set is empty
- **THEN** the trigger button label reads `類別：全部`
- **AND** the trigger background uses the inactive-selection style

##### Example: trigger labels under different selections

| Committed set | Trigger label | Trigger background style |
| --- | --- | --- |
| empty ("all categories") | `類別：全部` | inactive |
| {"beauty"} | `類別：beauty` | active |
| {"beauty", "snacks"} | `類別：2 項` | active |
| {"beauty", "snacks", "books"} | `類別：3 項` | active |

#### Scenario: Dedicated category trigger is not rendered on iOS Compact

- **GIVEN** the orders list is displayed on iOS in the Compact horizontal size class
- **WHEN** the orders list filter area is rendered
- **THEN** the dedicated category trigger described in this requirement is not rendered
- **AND** the category filter is exposed instead through the unified filter sheet defined by the `order-filter-sheet` capability

#### Scenario: Picker sheet seeds the pending set and marks selected cells

- **GIVEN** the orders list is displayed on iPadOS with available categories `["beauty", "snacks", "books"]` and the committed set is {"snacks"}
- **WHEN** the user taps the trigger button and the picker sheet opens
- **THEN** the pending set is {"snacks"} and the `snacks` cell is the only selected cell
- **AND** the `全部` row is not marked

#### Scenario: Toggling cells and tapping done commits the pending set

- **GIVEN** the picker sheet is open on iPadOS with an empty committed set
- **WHEN** the user taps the `beauty` cell and the `books` cell, then taps `完成`
- **THEN** the committed set becomes {"beauty", "books"}
- **AND** the picker sheet dismisses
- **AND** the trigger button label reads `類別：2 項` and the trigger background uses the active-selection style
- **AND** the orders list shows orders whose category list contains `beauty` or `books`, combined with any other active filters

#### Scenario: Toggling cells does not change the committed set before done

- **GIVEN** the picker sheet is open on iPadOS with the committed set {"snacks"}
- **WHEN** the user taps the `beauty` cell
- **THEN** the pending set is {"snacks", "beauty"} and the committed set is still {"snacks"}
- **AND** the orders list behind the sheet is still filtered by {"snacks"}

#### Scenario: Tapping the all row and done clears the filter

- **GIVEN** the picker sheet is open on iPadOS with the committed set {"beauty"}
- **WHEN** the user taps the `全部` row and then `完成`
- **THEN** the committed set becomes empty
- **AND** the trigger button label reads `類別：全部` and the trigger background uses the inactive-selection style

#### Scenario: Cancelling with pending changes asks before discarding

- **GIVEN** the picker sheet is open on iPadOS with the committed set {"beauty"} and the user has tapped the `books` cell
- **WHEN** the user taps the cancellation control and confirms discarding
- **THEN** the committed set is still {"beauty"} and the sheet dismisses

#### Scenario: Category filter is hidden when no categories are available on iPadOS

- **GIVEN** the orders list is displayed on iPadOS, the merged available categories list is empty, and the selected category set is empty
- **WHEN** the orders list is displayed
- **THEN** the trigger button is not rendered
- **AND** the selected category set remains empty

#### Scenario: A selection whose categories disappear is kept until cleared

- **GIVEN** the selected category set is {"beauty"} on iPadOS
- **WHEN** the orders and the category master no longer contain "beauty", so the available categories list becomes empty
- **THEN** the selected category set stays {"beauty"} and the orders list stays filtered by it
- **AND** the clear-filters control is enabled, and tapping it empties the selected category set

#### Scenario: Search in the picker narrows cells and keeps selections

- **GIVEN** the picker sheet is open on iPadOS with the pending set {"美妝", "書籍"} and categories `美妝`, `3C`, `零食` in 開團中 and `精品`, `食品`, `書籍` in 已收單
- **WHEN** the user types `食` into the search field
- **THEN** the grid shows only `零食` and `食品`, both groups expanded, and the `全部` row stays visible
- **AND** after the search text is cleared the pending set is still {"美妝", "書籍"}


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
### Requirement: Category options are grouped by campaign activity

Wherever the category filter options are offered (the iPhone unified filter sheet and the iPadOS category picker sheet), the available categories SHALL be split into two groups derived from the orders, without any stored grouping:

- The `開團中` group SHALL contain every available category for which at least one order whose category list contains it is assigned to a campaign that is ongoing. Whether a campaign is ongoing SHALL be evaluated with `Campaign.evaluatingAutoClose(asOf:calendar:)` using the orders list's recorded current time and calendar; a campaign name that matches no known campaign SHALL NOT count as ongoing.
- The `已收單` group SHALL contain every other available category, including master categories that no order uses and categories used only by orders without an ongoing campaign.

Each category SHALL appear in exactly one group. Within a group, categories SHALL be ordered by name using a locale-aware standard comparison. The `開團中` group SHALL be listed before the `已收單` group.

Each group SHALL be presented under a header that toggles the group between expanded and collapsed. The header SHALL show the group title, the number of categories the group currently shows, and, when at least one category of the group is in the pending selection, an indicator `已選 <N>` with the number of selected categories in that group. A collapsed group SHALL hide its category cells but keep its header.

The expansion SHALL be recomputed every time a category picker surface is presented, as follows:
1. The `開團中` group is expanded.
2. The `已收單` group is collapsed, except that it is expanded when any category of the `已收單` group is in the pending selection, or when the `開團中` group has no category.
3. A group with no category is hidden, so when no category belongs to `開團中` only the `已收單` group is shown, expanded.

Toggling a header SHALL change only that group's expansion for the current presentation. A search is active when the search text, after trimming whitespace and newlines, is non-empty; a text made only of whitespace is not a search. While a search is active, every shown group SHALL be displayed expanded regardless of its stored expansion, and tapping its header SHALL leave the stored expansion unchanged; once the search ends, each group returns to its stored expansion. The `已選 <N>` indicator SHALL count every selected category of the group, including selected categories that the search hides. The expansion and the search text are presentation state and SHALL NOT make the sheet dirty.

#### Scenario: Categories are grouped by ongoing campaigns

- **WHEN** the category groups are computed for the example data below
- **THEN** each category lands in the listed group

##### Example: grouping from orders and campaigns

- **GIVEN** campaigns: 春季團 (ongoing), 冬季團 (closed), 舊團 (status ongoing but its close date passed before the recorded current time); master categories: `美妝`, `書籍`, `保健`; orders: O1(categories=["美妝"], campaigns=["春季團"]), O2(categories=["3C", "零食"], campaigns=["冬季團", "春季團"]), O3(categories=["精品"], campaigns=["冬季團"]), O4(categories=["食品"], campaigns=["舊團"]), O5(categories=["書籍"], campaigns=[]), O6(categories=["精品"], campaigns=["已刪除團"])

| Category | Group | Reason |
| --- | --- | --- |
| `3C` | 開團中 | O2 includes the ongoing 春季團 |
| `美妝` | 開團中 | O1 is in the ongoing 春季團 |
| `零食` | 開團中 | O2 includes the ongoing 春季團 |
| `保健` | 已收單 | master category used by no order |
| `書籍` | 已收單 | O5 has no campaign |
| `精品` | 已收單 | 冬季團 is closed and 已刪除團 matches no known campaign |
| `食品` | 已收單 | 舊團 auto-closes at the recorded current time |

#### Scenario: Default expansion when opening

- **GIVEN** both groups have categories and no category of the 已收單 group is selected
- **WHEN** a category picker surface is presented
- **THEN** the 開團中 group is expanded and the 已收單 group is collapsed

#### Scenario: A selected archived category expands its group

- **GIVEN** the committed selection is {`美妝`, `書籍`} where `美妝` is in 開團中 and `書籍` is in 已收單
- **WHEN** a category picker surface is presented
- **THEN** both groups are expanded
- **AND** the 開團中 header shows `已選 1` and the 已收單 header shows `已選 1`

#### Scenario: No ongoing category shows only the archived group expanded

- **GIVEN** no available category belongs to the 開團中 group
- **WHEN** a category picker surface is presented
- **THEN** the 開團中 group and its header are not shown
- **AND** the 已收單 group is shown expanded

#### Scenario: Toggling a header collapses and expands a group

- **GIVEN** a category picker surface is open with the 開團中 group expanded
- **WHEN** the user taps the 開團中 header twice
- **THEN** after the first tap the group's cells are hidden and its header remains, and after the second tap the cells are shown again
- **AND** the pending selection is unchanged

#### Scenario: Header taps during a search do not change the stored expansion

- **GIVEN** a category picker surface is open with the 已收單 group collapsed
- **WHEN** the user types `食`, taps the 已收單 header, and then clears the search text
- **THEN** the 已收單 group is collapsed again

#### Scenario: Whitespace is not a search

- **GIVEN** a category picker surface is open with the 已收單 group collapsed
- **WHEN** the search text is three spaces
- **THEN** every category is shown as if no search were typed and the 已收單 group stays collapsed

#### Scenario: Selected count includes hidden selections

- **GIVEN** the 已收單 group has the pending selection {`食品`, `書籍`}
- **WHEN** the user types `食`
- **THEN** the 已收單 group shows only `食品` and its header still shows `已選 2`

#### Scenario: Expansion resets on the next presentation

- **GIVEN** the user collapsed the 開團中 group and then closed the picker surface
- **WHEN** the picker surface is presented again
- **THEN** the 開團中 group is expanded


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
### Requirement: Category options render as an equal-height fixed-column grid

The grouped category options SHALL be rendered by one shared grid view used by both the iPhone unified filter sheet and the iPadOS category picker sheet. Within each expanded group the cells SHALL be laid out in a fixed number of equally wide columns that fill rows from leading to trailing edge. The column count SHALL be the number of columns of at least the minimum cell width (which scales with Dynamic Type) that fit the width actually available to the grid, and never less than one; at accessibility text sizes the grid SHALL use a single column. Every cell SHALL be independently tappable: tapping one cell SHALL toggle only that cell, even when other cells share its row. Every cell SHALL show the full category name, wrapping onto additional lines instead of truncating, and all cells in the same row SHALL share the height of the tallest cell in that row. A row that holds fewer categories than the column count SHALL keep every cell at the width of one column instead of stretching its cells across the row. Each cell SHALL keep a hit region of at least 44 points in both dimensions.

The number of categories, orders, and campaigns is unbounded and unknown in advance. The grid and its grouping SHALL behave correctly for any count, from a single category to hundreds of categories: rows SHALL be created as they scroll into view rather than all at once. Merging and grouping the categories SHALL scan the orders, their category references, and their campaign references a bounded number of times rather than once per category, sorting the K category names SHALL cost no more than O(K log K), and searching and counting selections SHALL be proportional to the number of categories.

A selected cell SHALL be distinguishable by more than color: it SHALL show a checkmark glyph in addition to its selected appearance, and it SHALL expose the selected accessibility trait. The checkmark glyph itself SHALL be hidden from accessibility. An unselected cell SHALL NOT expose the selected trait.

#### Scenario: Long names wrap and keep the row aligned

- **GIVEN** a group whose second row holds `書籍` and `aespa Lemonade QQ 音樂限定禮包` at the default text size
- **WHEN** the grid is rendered
- **THEN** the long name wraps onto several lines without truncation
- **AND** the `書籍` cell in the same row has the same height as the long-name cell

#### Scenario: Few categories keep the column width

- **GIVEN** a group shows fewer categories than the column count
- **WHEN** the grid is rendered
- **THEN** each of those cells has the same width as a cell in a full row, and the rest of the row is empty

##### Example: partial rows with three columns

| Categories in the group | Rows | Cells in the last row |
| --- | --- | --- |
| 1 | 1 | 1 cell, one column wide |
| 2 | 1 | 2 cells, each one column wide |
| 3 | 1 | 3 cells filling the row |
| 4 | 2 | 1 cell, one column wide |

#### Scenario: Many categories remain usable

- **GIVEN** the 已收單 group holds 300 categories
- **WHEN** the user expands the group, scrolls to the last category, selects it together with one 開團中 category, and applies the filter
- **THEN** both categories are in the committed set and the orders list is filtered by them
- **AND** typing a search text narrows the 300 categories to the matching ones

#### Scenario: Accessibility text sizes use one column

- **GIVEN** the user's Dynamic Type size is an accessibility size
- **WHEN** the grid is rendered
- **THEN** every category cell occupies a full row

#### Scenario: Column count follows the available width

- **WHEN** the same grid is rendered in surfaces of different widths at the default text size
- **THEN** a wider surface shows at least as many columns as a narrower one, and a surface narrower than two minimum cells shows one column

#### Scenario: Cells in one row are tapped independently

- **GIVEN** a row shows `美妝`, `3C`, and `零食` and none is selected
- **WHEN** the user taps `3C`
- **THEN** only `3C` becomes selected

#### Scenario: Selected cells expose the selected trait

- **GIVEN** the pending selection is {`美妝`}
- **WHEN** the grid is rendered
- **THEN** the `美妝` cell shows a checkmark and exposes the selected accessibility trait
- **AND** the other cells do not expose the selected trait

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