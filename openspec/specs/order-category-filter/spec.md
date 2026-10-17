# order-category-filter Specification

## Purpose

TBD - created by archiving change 'ai-product-summary'. Update Purpose after archive.

## Requirements

### Requirement: Category filter on the orders list

The orders list SHALL provide a product-category filter that coexists with the existing status, date-period, and search filters on iOS and iPadOS. The filter SHALL offer an "all categories" option plus one option per available category. The available categories SHALL be sourced from the existing merged category options (category master plus categories used by orders). Selecting "all categories" SHALL clear the category constraint.

#### Scenario: Select a specific category

- **WHEN** the user selects a specific category in the filter
- **THEN** the orders list shows only orders whose category list contains the selected category, while still honoring the active status, date-period, and search filters

#### Scenario: Select all categories

- **WHEN** the user selects the "all categories" option
- **THEN** the category constraint is cleared and the orders list is no longer narrowed by category

---
### Requirement: Category filter combines with existing filters

The filtered orders result SHALL be the conjunction of the status, search, date-period, and category predicates. A category constraint SHALL match an order only when the order's category list contains the selected category.

#### Scenario: Category combined with status filter

- **WHEN** both a status filter and a category filter are active
- **THEN** only orders matching both the status and the category appear in the list

##### Example: conjunction of filters with multi-category orders

- **GIVEN** orders: O1(categories=["beauty"], status=purchased), O2(categories=["beauty", "snacks"], status=quoting), O3(categories=["snacks"], status=purchased), O4(categories=["beauty", "snacks"], status=purchased)
- **WHEN** the status filter is "purchased" and the category filter is "beauty"
- **THEN** the list shows exactly { O1, O4 }

#### Scenario: Selection recomputes the active selection

- **WHEN** the user changes the category filter
- **THEN** the system recomputes the currently selected order to the first order of the newly filtered list


<!-- @trace
source: add-order-merge
updated: 2026-06-07
code:
  - apps/apple/BuyLedger/Features/Orders/OrdersView.swift
  - apps/apple/BuyLedger/Features/Orders/OrdersCompactView.swift
  - apps/apple/BuyLedger/Features/Orders/OrdersMacView.swift
  - apps/apple/BuyLedgerTests/OrderMergeFeatureTests.swift
  - apps/apple/BuyLedger/Features/Orders/OrdersFeature.swift
  - apps/apple/BuyLedger/Features/Orders/Components/OrderRowView.swift
  - apps/apple/BuyLedger/Features/Orders/Components/OrderMergeCandidateSheet.swift
  - apps/apple/BuyLedger/Features/Orders/OrderMergeFeature.swift
-->

---
### Requirement: Deep link from analytics applies the category filter

When the user taps a category row in the analytics page's category ranking, the app SHALL navigate to the orders tab and apply the tapped category as the active category filter on the orders list. The active category filter value SHALL drive both the orders list filtering and the visual state of the category filter trigger button and picker sheet (trigger label and picker selected-row indicator compare against the active category filter value). The orders list SHALL be filtered by containment against each order's category list — it SHALL NOT rely on text search to approximate the filter.

#### Scenario: Tapping a category row navigates and applies the filter

- **WHEN** the user is on the analytics page and taps the category row whose name is "beauty"
- **THEN** the active tab changes to "orders"
- **AND** the orders list's active category filter equals "beauty"
- **AND** the category filter trigger button label reads `類別：beauty` and the trigger background uses the active-selection style
- **AND** opening the picker sheet shows the `beauty` row as the currently selected row
- **AND** the orders list contains exactly those orders whose category list contains "beauty"

##### Example: deep link with mixed-category data

- **GIVEN** orders: O1(categories=["beauty"], customer="Alice"), O2(categories=["snacks"], customer="Beauty Bob"), O3(categories=["beauty", "snacks"], customer="Carol")
- **WHEN** the user taps the "beauty" row in the analytics category ranking
- **THEN** the orders list contains exactly { O1, O3 } and excludes O2, even though O2's customer name contains the substring "Beauty"

#### Scenario: Tapping a category row resets unrelated orders-list filters

- **WHEN** the user has the orders list state with status filter "delivered" and date-period filter "this month", then taps a category row on the analytics page
- **THEN** the status filter resets to "all"
- **AND** the date-period filter resets to "all"
- **AND** the search text is cleared
- **AND** the active category filter equals the tapped category


<!-- @trace
source: add-order-merge
updated: 2026-06-07
code:
  - apps/apple/BuyLedger/Features/Orders/OrdersView.swift
  - apps/apple/BuyLedger/Features/Orders/OrdersCompactView.swift
  - apps/apple/BuyLedger/Features/Orders/OrdersMacView.swift
  - apps/apple/BuyLedgerTests/OrderMergeFeatureTests.swift
  - apps/apple/BuyLedger/Features/Orders/OrdersFeature.swift
  - apps/apple/BuyLedger/Features/Orders/Components/OrderRowView.swift
  - apps/apple/BuyLedger/Features/Orders/Components/OrderMergeCandidateSheet.swift
  - apps/apple/BuyLedger/Features/Orders/OrderMergeFeature.swift
-->

---
### Requirement: Cross-feature navigations reset the category filter

Cross-feature navigations into the orders list SHALL reset the orders list's active category filter to "all categories" unless the navigation explicitly applies a category. This applies to navigations originating from customer-name selection. This prevents a stale category filter from intersecting with the new navigation's filters and producing an empty list.

#### Scenario: Customer deep link clears a stale category filter

- **WHEN** the user has the orders list category filter set to "snacks", then taps the customer name "Alice" from the customers page
- **THEN** the active tab changes to "orders"
- **AND** the orders list's search text equals "Alice"
- **AND** the active category filter resets to "all categories"


<!-- @trace
source: order-edit-style-compliance
updated: 2026-10-10
code:
  - apps/ios/BuyLedgerTests/OrderStatusRulesTests.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignFeature+Destination.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersFeature+StateQuery.swift
  - apps/ios/BuyLedgerTests/OrderWritesFeatureTests+BatchDelete.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrdersBaseline/ordersCompactView_推入含成本明細訂單_符合基準圖.1.png
  - apps/ios/BuyLedgerTests/OrderEditFocusTests.swift
  - apps/ios/BuyLedgerTests/ActionGroupingScanTests.swift
  - apps/ios/BuyLedgerTests/OrderEditFeatureTests+Discard.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+Dates.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersContainerPlan.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderEditDecimalField.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignFormatters.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+DeepLinks.swift
  - apps/ios/BuyLedgerAccessibilityIDs/BLAccessibilityID+App.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderDetailView.swift
  - apps/ios/BuyLedgerTests/DashboardFeatureTests.swift
  - apps/ios/BuyLedgerTests/OrdersFeatureTests+SaveFailureTiming.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+FilterSheet.swift
  - apps/ios/BuyLedgerUITests/Support/Waiting.swift
  - apps/ios/BuyLedgerTests/OrdersFeatureTests+MergeCandidates.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersRequestOutcome.swift
  - apps/ios/BuyLedgerTests/CampaignSummaryTests.swift
  - apps/ios/BuyLedgerTests/OrdersFeatureTests+AISummaryProjection.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFilterCategorySection.swift
  - apps/ios/BuyLedgerTests/OrdersFeatureTests+MergeSave.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+Campaigns.swift
  - apps/ios/BuyLedger/Features/Orders/OrderFilterFeature.swift
  - apps/ios/BuyLedgerTests/ProjectionWriteBoundaryTests+RootProjections.swift
  - apps/ios/BuyLedger/Features/Orders/OrderEditPickersFeature.swift
  - apps/ios/BuyLedgerTests/OrdersFilterOperationsTests.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersLoadState.swift
  - apps/ios/BuyLedgerTests/OrderEditPhotosFeatureTests.swift
  - apps/ios/BuyLedgerTests/OrderEditFeatureTests+Deduction.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignView.swift
  - apps/ios/BuyLedgerTests/OrderWritesFeatureTests+Create.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderEditBasicSection.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+PaymentMethodRename.swift
  - apps/ios/BuyLedger/Features/Orders/OrderOptionWritePlan.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderDetailSourceView.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFilterPreviewFixtures.swift
  - apps/ios/BuyLedgerTests/OrderSaveGuardTests.swift
  - apps/ios/BuyLedgerUITests/Screens/InsightsScreen+LaunchLoading.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignDetailView.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+PaymentMethodCorrection.swift
  - apps/ios/BuyLedger/Features/App/SidebarSmartGroup.swift
  - apps/ios/BuyLedgerTests/OrderEditFeatureTests+PaymentMethod.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersListQuery.swift
  - apps/ios/BuyLedgerTests/OrderFormattersTests.swift
  - apps/ios/BuyLedgerTests/OrdersFeatureTests+MergePrefill.swift
  - apps/ios/BuyLedgerTests/OrdersFeatureTests+MergeWrites.swift
  - apps/ios/BuyLedgerTests/CampaignFeatureTests+ReminderRename.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderDetailRowMenu.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderEditOriginalSection.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignPresentationQueue.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderEditNotesSection.swift
  - apps/ios/BuyLedger/Features/App/SidebarBadgeCounts.swift
  - apps/ios/BuyLedger/Features/Orders/OrderEditView.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFormatters.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignPresentationFeature+Destination.swift
  - apps/ios/BuyLedger/Features/Orders/OrderWritesFeature.swift
  - apps/ios/BuyLedgerTests/CampaignDetailFeatureTests.swift
  - apps/ios/BuyLedgerTests/LocalizationCatalogTests+LiteralScan.swift
  - apps/ios/BuyLedgerTests/CampaignIntegrationTests+Filters.swift
  - apps/ios/BuyLedgerTests/CampaignFeatureTests+Writes.swift
  - apps/ios/BuyLedgerTests/OrderEditFeatureTests+Merge.swift
  - apps/ios/BuyLedgerTests/OrderPercentConversionTests.swift
  - apps/ios/BuyLedger/Features/App/RootLaunchFeature.swift
  - apps/ios/BuyLedgerTests/OrdersFeatureTests+ListRequests.swift
  - apps/ios/BuyLedgerTests/CampaignIntegrationTests+Delete.swift
  - apps/ios/BuyLedgerTests/OrdersFeatureTests+FailureTiming.swift
  - apps/ios/BuyLedgerTests/OrdersFeatureTests+OptionWriteFailures.swift
  - apps/ios/BuyLedgerTests/OrdersFilterOperationsTests+FilteredOrders.swift
  - apps/ios/BuyLedgerTests/OrderWritesFeatureTests+Requests.swift
  - apps/ios/BuyLedgerTests/OrderDetailFeatureTests+Display.swift
  - apps/ios/BuyLedger/Features/Orders/OrderAISummarySettings.swift
  - apps/ios/BuyLedgerTests/OrderEditFeatureTests+Dates.swift
  - apps/ios/BuyLedgerTests/OrdersFeatureTests.swift
  - apps/ios/BuyLedgerTests/OrdersFeatureTests+StatusWrites.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderMergeCandidateSheet.swift
  - apps/ios/BuyLedgerTests/CampaignFeatureTests+Fixtures.swift
  - apps/ios/BuyLedgerTests/CampaignFeatureTests+Loading.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLFormatters.swift
  - apps/ios/BuyLedgerTests/CampaignFeatureTests+ReminderCancellation.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderDetailSummaryView.swift
  - apps/ios/BuyLedger/Features/Orders/OrderEditPickerOperations.swift
  - apps/ios/BuyLedgerTests/CampaignListFeatureTests.swift
  - apps/ios/BuyLedgerTests/ProjectionWriteBoundaryTests+Guards.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+DetailNavigation.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderStatus+Presentation.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardFeature.swift
  - apps/ios/BuyLedgerTests/SnapshotTests+OrderDetail.swift
  - apps/ios/BuyLedgerTests/OrderEditFeatureTests+Items.swift
  - apps/ios/BuyLedgerTests/LocalizationCatalogTests.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardView.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+Presentation.swift
  - apps/ios/BuyLedgerTests/OrdersPresentationFeatureTests+Transition.swift
  - apps/ios/BuyLedgerTests/OrderDetailFeatureTests.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderCompactDetailView.swift
  - apps/ios/README.md
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+Selection.swift
  - apps/ios/BuyLedgerTests/OrderEditFeatureTests+Campaigns.swift
  - apps/ios/BuyLedgerTests/OrderEditCampaignOptionsTests.swift
  - apps/ios/BuyLedgerTests/OrderEditFeatureTests+OrderSourceAndCurrency.swift
  - apps/ios/BuyLedgerTests/OrdersContainerPlanTests+RequestPresentation.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersPresentationQueue.swift
  - apps/ios/BuyLedgerTests/OrdersDetailNavigationFeatureTests.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderDetailCardlessView.swift
  - apps/ios/BuyLedger/Features/Orders/OrderWriteOperations.swift
  - apps/ios/BuyLedgerTests/ActionGroupingScanTests+Scanner.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersFeature.swift
  - apps/ios/BuyLedgerTests/OrderEditFeatureTests+Categories.swift
  - apps/ios/BuyLedgerTests/OrderEditPickersFeatureTests.swift
  - apps/ios/BuyLedgerTests/OrdersFeatureTests+EditFields.swift
  - apps/ios/BuyLedgerTests/OrdersPresentationFeatureTests.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersView.swift
  - apps/ios/CLAUDE.md
  - apps/ios/BuyLedgerTests/CampaignFeatureTests+ReloadDelete.swift
  - apps/ios/BuyLedgerTests/CampaignFeatureTests+WriteFailures.swift
  - apps/ios/BuyLedgerTests/OrdersFeatureTests+PaymentMethodParity.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderEditPaymentSection.swift
  - apps/ios/BuyLedgerTests/CampaignPresentationQueueTests.swift
  - apps/ios/BuyLedgerTests/OrderFilterFeatureTests+Queries.swift
  - apps/ios/BuyLedgerUITests/Support/Scrolling.swift
  - apps/ios/BuyLedger/Features/Orders/OrderPercentConversion.swift
  - apps/ios/BuyLedgerTests/CampaignFeatureTests+UnchangedName.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersContainerPlan+Writes.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrdersToolbarContent.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrderEdit/orderEditView_合併訂單情境_符合基準圖.1.png
  - apps/ios/BuyLedgerTests/ActionGroupingScanTests+Scenarios.swift
  - apps/ios/BuyLedgerTests/SnapshotTests+OrderEdit.swift
  - apps/ios/BuyLedgerTests/LocalizationCatalogTests+AppLanguage.swift
  - apps/ios/BuyLedgerTests/OrdersFeatureTests+EditDeduction.swift
  - apps/ios/BuyLedgerAccessibilityIDs/BLAccessibilityID+Dashboard.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+LookupSync.swift
  - apps/ios/BuyLedgerTests/ServiceTestValueStrictnessTests.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+FilterSummary.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersPresentationFeature+Destination.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderDetailCostView.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderDetailMenu.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderSelectableRow.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersFilterOperations.swift
  - apps/ios/BuyLedgerTests/OrderStatusPresentationTests.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignListFeature.swift
  - apps/ios/BuyLedger/Features/Orders/OrderMergeCandidates.swift
  - apps/ios/BuyLedger/Features/Orders/OrderDetailFeature.swift
  - apps/ios/BuyLedgerTests/LocalizationCatalogTests+SourceGuards.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFilterDateSection.swift
  - apps/ios/BuyLedgerTests/ProjectionWriteBoundaryTests.swift
  - apps/ios/BuyLedgerTests/OrderDateSectionTests.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+CurrencyCodes.swift
  - apps/ios/BuyLedger/Core/Domain/CampaignDistributionRow.swift
  - apps/ios/BuyLedgerTests/CampaignIntegrationTests+Rename.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderEditFeesSection.swift
  - apps/ios/BuyLedgerTests/ContrastComplianceTests.swift
  - apps/ios/BuyLedgerTests/OrderMergeFeatureTests.swift
  - apps/ios/BuyLedger/Features/Orders/OrderFilterSelection.swift
  - apps/ios/BuyLedger/Core/Dependencies/SharedKey+CurrencyCodes.swift
  - apps/ios/BuyLedger/Features/Orders/OrderListFeature.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsView.swift
  - apps/ios/BuyLedgerTests/ProjectionWriteBoundaryTests+Orders.swift
  - apps/ios/BuyLedgerTests/OrderEditFeatureTests+Initialization.swift
  - apps/ios/BuyLedger/Features/App/RootCascadeOperations.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignRequestPlan.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderDetailContentView.swift
  - apps/ios/BuyLedger/Features/App/RootSidebarLayout.swift
  - apps/ios/BuyLedgerTests/OrdersLoadFeatureTests+Requests.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignFeature+Path.swift
  - apps/ios/BuyLedgerTests/OrdersFeatureTests+Deletion.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+AISummaryProjection.swift
  - apps/ios/BuyLedger/Features/App/RootFeature.swift
  - apps/ios/BuyLedgerTests/RootLaunchFeatureTests.swift
  - apps/ios/BuyLedgerTests/OrderWritesFeatureTests+Receipt.swift
  - apps/ios/BuyLedgerTests/OrdersLoadFeatureTests.swift
  - apps/ios/BuyLedgerTests/OrdersFeatureTests+AIDisabledAlert.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersBatchOperations.swift
  - apps/ios/BuyLedgerTests/CampaignLoadFeatureTests+Requests.swift
  - apps/ios/BuyLedger/Features/Orders/OrderMergeSavePlan.swift
  - apps/ios/BuyLedgerTests/CampaignIntegrationTests+Receipt.swift
  - apps/ios/BuyLedger/Features/Orders/Components/MergePhotoTile.swift
  - apps/ios/BuyLedgerTests/OrdersFeatureTests+Detail.swift
  - apps/ios/BuyLedgerTests/OrderEditFeatureTests+Photos.swift
  - apps/ios/BuyLedger/Features/Orders/OrderDraft+WriteResult.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersDetailNavigationFeature+Path.swift
  - apps/ios/BuyLedgerTests/OrdersFilterOperationsTests+FilterSheet.swift
  - apps/ios/BuyLedgerTests/OrderWritesFeatureTests.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+AppShell.swift
  - apps/ios/BuyLedger/Features/Orders/OrderDateContext.swift
  - apps/ios/BuyLedgerUITests/Screens/DashboardScreen.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFilterPaymentMethodSection.swift
  - apps/ios/BuyLedgerTests/OrderWritesFeatureTests+Save.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersCompactView.swift
  - apps/ios/BuyLedger/Features/Orders/OrderMergeFeature.swift
  - apps/ios/BuyLedgerTests/CampaignLoadFeatureTests+Dates.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersRegularListColumn.swift
  - apps/ios/BuyLedgerTests/OrderMergeFeatureTests+PhotoSelection.swift
  - apps/ios/BuyLedgerTests/OrderWritesFeatureTests+Status.swift
  - apps/ios/BuyLedger/Features/Orders/OrderRequestPlan.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+Fixtures.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrdersCompactListView.swift
  - apps/ios/BuyLedger/Features/Orders/OrderDetailPath.swift
  - apps/ios/BuyLedgerTests/CampaignFeatureTests+Reload.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderEditCostSection.swift
  - apps/ios/BuyLedgerTests/OrdersFeatureTests+OptionWrites.swift
  - apps/ios/BuyLedger/Features/Orders/OrderEditOptionNormalizer.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+SharedOrders.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrdersBaseline/ordersView_寬版選取含成本明細訂單_符合基準圖.1.png
  - apps/ios/BuyLedger/Features/Orders/Components/OrderEditStatusSection.swift
  - apps/ios/BuyLedgerTests/OrderWritesFeatureTests+Cascade.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsFeature.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignDetailContent.swift
  - apps/ios/BuyLedgerTests/ProjectionWriteBoundaryTests+Scanner.swift
  - apps/ios/BuyLedgerTests/OrderEditFeatureTests+Binding.swift
  - apps/ios/BuyLedgerTests/OrdersFeaturePerformanceTests.swift
  - apps/ios/BuyLedgerTests/OrdersFeatureTests+EditPayment.swift
  - apps/ios/BuyLedgerTests/OrderEditOptionsTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Insights/InsightsLaunchLoadingTests.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignPresentationFeature.swift
  - apps/ios/BuyLedgerTests/CampaignFeatureTests+FailureTiming.swift
  - apps/ios/BuyLedgerTests/OrdersFeatureTests+StatusFailures.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignListView.swift
  - apps/ios/BuyLedger.xcodeproj/project.pbxproj
  - apps/ios/BuyLedger/Features/Campaigns/CampaignDetailFeature.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderEditPickerDestination.swift
  - apps/ios/BuyLedgerTests/CampaignFeatureTests+DeletionReminder.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderEditPercentField.swift
  - apps/ios/BuyLedgerTests/OrderDraftTests+Customer.swift
  - apps/ios/BuyLedgerTests/OrderWritesFeatureTests+Options.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersRegularDetailColumn.swift
  - apps/ios/BuyLedgerTests/OrderFilterFeatureTests.swift
  - apps/ios/BuyLedgerTests/OrdersFilterOperationsTests+SearchAndSelection.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+Foreground.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardRecentOrdersSection.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersQuery.swift
  - apps/ios/BuyLedgerTests/OrdersContainerPlanTests.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderRowView.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersContainerPlan+Presentation.swift
  - apps/ios/BuyLedger/Features/Orders/Components/MergePhotoPickerSheet.swift
  - apps/ios/BuyLedger/Features/Orders/OrderEditPhotosFeature.swift
  - apps/ios/BuyLedgerTests/OrdersFeatureTests+ListEntry.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+CampaignLoading.swift
  - apps/ios/BuyLedgerTests/CampaignIntegrationTests+Navigation.swift
  - apps/ios/BuyLedgerTests/OrderDraftTests+DefaultCurrency.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersPresentationFeature.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFilterSheet.swift
  - apps/ios/BuyLedgerTests/DateSectionFormattingTests.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersCascadeOperations.swift
  - apps/ios/BuyLedgerTests/OrdersSearchCancellationTests.swift
  - apps/ios/BuyLedgerTests/OrdersFeatureTests+EditAmounts.swift
  - apps/ios/BuyLedger/Features/App/RootNavigationOperations.swift
  - apps/ios/BuyLedger/Features/Orders/OrderSummaryPrompt.swift
  - apps/ios/BuyLedgerTests/CampaignLoadFeatureTests.swift
  - apps/ios/BuyLedgerTests/SidebarBadgeCountsTests.swift
  - apps/ios/BuyLedgerTests/SnapshotTests+CampaignDetail.swift
  - apps/ios/BuyLedgerTests/OrderEditFeatureTests+Reconciliation.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrdersBaseline/orderFilterSheet_已選日期類別付款方式_符合基準圖.1.png
  - apps/ios/BuyLedgerTests/OrderEditFeatureTests.swift
  - apps/ios/BuyLedgerTests/OrderCostBreakdownTests.swift
  - apps/ios/BuyLedgerTests/OrderSummaryPromptTests.swift
  - apps/ios/BuyLedger/Features/Orders/OrderCostBreakdown.swift
  - apps/ios/BuyLedgerTests/InsightsFeatureTests.swift
  - apps/ios/BuyLedgerTests/OrderMergeFeatureTests+CandidateSelection.swift
  - apps/ios/BuyLedgerTests/OrderEditFeatureTests+DirtyState.swift
  - apps/ios/BuyLedgerTests/OrdersPresentationFeatureTests+Fixtures.swift
  - apps/ios/BuyLedgerTests/CampaignLoadFeatureTests+AutoClose.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+OrderFilters.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignFeature.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderDetailItemsView.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderEditSelectionRow.swift
  - apps/ios/BuyLedgerTests/CampaignFeatureTests+NameConflict.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+DefaultCurrency.swift
  - apps/ios/BuyLedgerTests/CampaignFeatureTests+FailureTimingFollowUp.swift
  - apps/ios/BuyLedgerTests/SnapshotTests+Campaigns.swift
  - apps/ios/BuyLedgerTests/OrdersContainerPlanTests+Presentation.swift
  - apps/ios/BuyLedger/Features/Orders/OrderDateSection.swift
  - apps/ios/BuyLedger/Features/Campaigns/Components/CampaignDetailDistributionSection.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersMergeFlowOperations.swift
  - apps/ios/BuyLedgerTests/OrdersContainerPlanTests+Writes.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersDetailNavigationFeature.swift
  - apps/ios/BuyLedger/Features/App/RootLaunchOperations.swift
  - apps/ios/BuyLedgerTests/OrdersFeatureTests+DeleteEditFailures.swift
  - apps/ios/BuyLedgerTests/OrdersFeatureTests+LoadAndSummary.swift
  - apps/ios/BuyLedgerTests/InsightsAttributionTests.swift
  - apps/ios/BuyLedgerTests/CampaignIntegrationTests.swift
  - apps/ios/BuyLedgerTests/OrdersLoadStateTests.swift
  - apps/ios/BuyLedgerTests/OrdersSharedStateTests.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+LookupRename.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+Sidebar.swift
  - apps/ios/BuyLedgerTests/String+SourceLiteralScan.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderCreateTests.swift
  - apps/ios/BuyLedger/Features/Orders/OrderDraft.swift
  - apps/ios/BuyLedgerTests/CampaignFeatureTests+Editing.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+Filters.swift
  - apps/ios/BuyLedgerTests/SnapshotTests+Orders.swift
  - apps/ios/BuyLedgerUITests/Tests/Dashboard/DashboardLaunchLoadingTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderDetailMenuTests.swift
  - apps/ios/BuyLedgerTests/SnapshotTests+OrdersBaseline.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderMergeTests.swift
  - apps/ios/BuyLedger/Features/Orders/OrderEditPhotosSection.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardOngoingCampaignsSection.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderEditCampaignSection.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderEditItemsSection.swift
  - apps/ios/BuyLedgerTests/OrderDraftTests.swift
  - apps/ios/BuyLedger/Features/Orders/OrderStatusRules.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+FilterDelegates.swift
  - apps/ios/BuyLedgerTests/CurrencyMetadataServiceTests+Refresh.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+NewOrderOptions.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersContainerPlan+Requests.swift
  - apps/ios/BuyLedger/Features/Orders/OrderListInteraction.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersLoadFeature.swift
  - apps/ios/BuyLedgerTests/CampaignFeatureTests+ReminderIntegration.swift
  - apps/ios/BuyLedgerTests/CampaignListFeatureTests+DateContext.swift
  - apps/ios/BuyLedgerTests/CampaignPresentationFeatureTests.swift
  - apps/ios/BuyLedgerTests/CampaignFeatureTests+Presentation.swift
  - apps/ios/BuyLedgerTests/OrdersQueryTests.swift
  - apps/ios/BuyLedgerTests/ProjectionWriteBoundaryTests+Patterns.swift
  - apps/ios/BuyLedger/Features/Orders/OrderEditOptions.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+FilterPending.swift
  - apps/ios/BuyLedgerTests/CampaignDetailContentTests.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+Cascade.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+FilterLabels.swift
  - apps/ios/BuyLedgerTests/OrdersBatchOperationsTests.swift
  - apps/ios/BuyLedgerTests/CampaignListFeatureTests+Loading.swift
  - apps/ios/BuyLedger/Features/Orders/OrderEditOperations.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersEditorOptions.swift
  - apps/ios/BuyLedgerTests/OrdersFeatureTests+MergeTiming.swift
  - apps/ios/BuyLedgerTests/OrderWritesFeatureTests+Merge.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignLoadFeature.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+LoadRequests.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersWriteOutcome.swift
  - apps/ios/BuyLedgerTests/OrdersContainerPlanTests+Requests.swift
  - apps/ios/BuyLedgerTests/CampaignFeatureTests.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderDetailNotesView.swift
  - apps/ios/BuyLedger/Features/Orders/OrderEditFeature.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersDetailSelection.swift
  - apps/ios/BuyLedgerTests/OrderDraftTests+Photos.swift
  - apps/ios/BuyLedgerTests/OrdersFeatureTests+Create.swift
  - apps/ios/BuyLedger/Features/Orders/OrderRequest.swift
  - apps/ios/BuyLedgerTests/CampaignIntegrationTests+Fixtures.swift
  - apps/ios/BuyLedger/Features/Orders/OrderEditDraftOperations.swift
  - apps/ios/BuyLedgerTests/OrdersFeatureTests+Photos.swift
  - apps/ios/BuyLedgerTests/OrdersPresentationFeatureTests+Delegate.swift
  - apps/ios/BuyLedgerTests/CampaignListFeatureTests+AutoClose.swift
-->

---
### Requirement: Category filter is presented as a trigger button with a searchable picker sheet

On iPadOS the orders list category filter SHALL be rendered as a single capsule-shaped trigger button. The trigger button SHALL display the currently active category selection in its label so the user can identify the active selection without opening the picker. The category filter SHALL NOT be rendered as a horizontally scrolling row of capsule chips and SHALL NOT be rendered as an inline Menu.

On iOS in the Compact size class the orders list category filter SHALL instead be folded into the unified filter sheet defined by the `order-filter-sheet` capability. The dedicated category trigger described in this requirement SHALL NOT be rendered in that size class.

The trigger button SHALL occupy the full available horizontal width of the orders filter area on every platform where it is rendered, so its left and right edges align with the search field and other full-width controls above it.

The trigger button label SHALL be composed of, in order:
1. A leading tag icon consistent with the icon previously used by the category chips.
2. A text segment of the form `類別：<current>`, where `<current>` is `全部` when no category is selected, and the category name otherwise. The text segment SHALL support multi-line wrapping when the category name exceeds the available single-line width — the capsule SHALL grow vertically to fit the wrapped text rather than truncating it.
3. A trailing chevron-down indicator that communicates the control opens a picker sheet.

When the label wraps to multiple lines, the leading tag icon and the trailing chevron-down icon SHALL align to the first text baseline rather than the vertical center of the capsule.

The trigger button SHALL apply a filled capsule background. The fill SHALL be the active-selection style when a category is selected and the inactive-selection style otherwise, so the user can tell from the trigger alone whether a category filter is currently applied.

The trigger button SHALL only be rendered when the set of available categories is non-empty. When no categories are available, the category filter UI on iPadOS SHALL be hidden, matching the prior behavior.

Tapping the trigger button SHALL present a category picker sheet that:
1. Lists, in order, a "clear" row labeled `全部` (which clears the active category filter when tapped) followed by one row per entry in the available categories list (which sets the active category to that name when tapped).
2. Provides a search field that filters the category rows in real time. The "clear" row SHALL remain visible regardless of the search input.
3. Marks exactly one row as the currently selected row — the "clear" row when no category is selected, or the matching category row otherwise — with a visually distinguishable indicator such as a leading or trailing checkmark glyph.
4. Dismisses itself after the user taps any row.

#### Scenario: Trigger label reflects the active selection on iPadOS

- **GIVEN** the orders list is displayed on iPadOS and has at least one available category
- **WHEN** the active category filter is "all categories" (no specific category selected)
- **THEN** the trigger button label reads `類別：全部`
- **AND** the trigger background uses the inactive-selection style

##### Example: trigger labels under different selections

| Active selection           | Trigger label  | Trigger background style |
| -------------------------- | -------------- | ------------------------ |
| none ("all categories")    | `類別：全部`   | inactive                 |
| "beauty"                   | `類別：beauty` | active                   |
| "snacks"                   | `類別：snacks` | active                   |

#### Scenario: Dedicated category trigger is not rendered on iOS Compact

- **GIVEN** the orders list is displayed on iOS in the Compact horizontal size class
- **WHEN** the orders list filter area is rendered
- **THEN** the dedicated category trigger described in this requirement is not rendered
- **AND** the category filter is exposed instead through the unified filter sheet defined by the `order-filter-sheet` capability

#### Scenario: Picker sheet lists clear row and all categories with a selection indicator

- **GIVEN** the orders list is displayed on iPadOS with available categories `["beauty", "snacks", "books"]` and the active category filter is "snacks"
- **WHEN** the user taps the trigger button and the picker sheet opens
- **THEN** the picker shows rows in order: `全部`, `beauty`, `snacks`, `books`
- **AND** the `snacks` row is marked as the currently selected row
- **AND** no other row is marked as currently selected

#### Scenario: Selecting a category from the picker sheet updates the filter

- **GIVEN** the orders list is displayed on iPadOS with the category filter currently `全部` (no category selected)
- **WHEN** the user opens the picker sheet and taps the `beauty` row
- **THEN** the active category filter equals "beauty"
- **AND** the picker sheet dismisses
- **AND** the trigger button label reads `類別：beauty` and the trigger background uses the active-selection style
- **AND** the orders list is filtered to orders whose category list contains "beauty" (combined with any other active filters)
- **AND** reopening the picker sheet shows `beauty` as the currently selected row

#### Scenario: Selecting the clear row from the picker sheet clears the filter

- **GIVEN** the orders list is displayed on iPadOS
- **WHEN** the user opens the picker sheet while a specific category is active and taps the `全部` row
- **THEN** the active category filter is cleared
- **AND** the picker sheet dismisses
- **AND** the trigger button label reads `類別：全部` and the trigger background uses the inactive-selection style
- **AND** the orders list is no longer narrowed by category

#### Scenario: Search filters the category rows but preserves the clear row

- **GIVEN** the orders list is displayed on iPadOS with available categories `["beauty", "snacks", "books"]` and the picker sheet is open
- **WHEN** the user types `boo` into the search field
- **THEN** the picker shows the `全部` row at the top and the `books` row as the only matching category row
- **AND** the `beauty` and `snacks` rows are not shown

#### Scenario: Category filter is hidden when no categories are available on iPadOS

- **GIVEN** the orders list is displayed on iPadOS and the merged available categories list is empty
- **WHEN** the orders list is displayed
- **THEN** the trigger button is not rendered
- **AND** the active category filter remains cleared