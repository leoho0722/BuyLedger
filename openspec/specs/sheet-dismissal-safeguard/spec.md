# sheet-dismissal-safeguard Specification

## Purpose

本規格涵蓋訂單編輯、活動編輯、付款方式編輯三個編輯 sheet 的未儲存變更防護，包括草稿是否變動的判斷 (dirty state)、滑動關閉的攔截、取消時的捨棄確認對話框。不涵蓋 `irreversible-action-safeguard` 所訂的其他暫存變更 sheet (如篩選 sheet) 的防護，以及非刪除類不可逆狀態轉換的確認。

## Requirements

### Requirement: Guard edit sheets against silent data loss on dismissal

Each sheet that holds user input which is not yet committed — the order editor, the campaign editor, the payment method editor, the orders filter sheet, and the iPadOS orders category picker sheet — SHALL track whether that input differs from the values it was opened with (a dirty state). While the sheet is dirty, it SHALL prevent interactive swipe-to-dismiss so that uncommitted input cannot be lost silently. The dirty state SHALL be derived from all uncommitted fields of that sheet, not a partial subset.

For sheets bound to a feature store, the dirty state SHALL be derived from state held by that feature rather than from view-local state, so that it is observable and assertable outside the view layer.

Coverage of all uncommitted fields SHALL be guaranteed structurally rather than by maintaining a parallel list of fields. Where a sheet's uncommitted input is grouped into a single value, the dirty state SHALL be that value compared against the value captured when the sheet opened, so that adding a field cannot omit it from the comparison. A separate fingerprint enumerating the fields SHALL NOT be maintained, because it duplicates the field list and can silently fall out of step with it.

Values that are presentation state rather than user input — focus, navigation route within the sheet, in-flight picker selections, search text, and the expansion of category groups — SHALL NOT contribute to the dirty state.

#### Scenario: Dirty edit sheet resists swipe-to-dismiss

- **WHEN** the user has modified at least one draft field in the order, campaign, or payment method editor and then swipes down to dismiss the sheet
- **THEN** the sheet does not dismiss and the draft is preserved

#### Scenario: Clean edit sheet dismisses freely

- **WHEN** the user opens an editor and swipes down to dismiss without modifying any draft field
- **THEN** the sheet dismisses immediately without any confirmation

#### Scenario: Filter sheet with pending selections resists swipe-to-dismiss

- **WHEN** the user has changed at least one pending selection in the orders filter sheet and then swipes down to dismiss it
- **THEN** the sheet does not dismiss and the pending selections are preserved

#### Scenario: Category picker with a changed pending set resists swipe-to-dismiss

- **WHEN** the user has toggled the iPadOS orders category picker's pending set so that it differs from the committed set and then swipes down to dismiss it
- **THEN** the sheet does not dismiss and the pending set is preserved
- **WHEN** the user toggles a category on and off again so that the pending set equals the committed set and then swipes down
- **THEN** the sheet dismisses without a confirmation

#### Scenario: Dirty state is derived from feature state

- **WHEN** the dirty state of a store-bound sheet is inspected
- **THEN** it is computed from values held by that sheet's feature, so a test driving the feature can assert it without rendering the view

#### Scenario: A newly added draft field is covered without any further step

- **WHEN** a new field is added to a sheet's uncommitted input
- **THEN** modifying it makes the sheet dirty, because the dirty state compares the whole grouped value rather than an enumerated list of fields

#### Scenario: Presentation state does not make the sheet dirty

- **WHEN** the user only moves focus between fields, navigates within the sheet, opens a picker without choosing a value, types into a sheet's search field, or expands or collapses a category group
- **THEN** the sheet is not dirty and dismisses without a confirmation


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
### Requirement: Confirm discarding unsaved changes when cancelling

When an editing sheet is dirty and the user taps its cancel control, the sheet SHALL present a confirmation dialog offering a destructive "discard changes" choice and a non-destructive "keep editing" choice, rather than dismissing directly. Choosing discard SHALL dismiss the sheet without saving; choosing keep editing SHALL leave the sheet open with the draft intact. When the sheet is not dirty, the cancel control SHALL dismiss directly without a confirmation dialog.

#### Scenario: Cancel with unsaved changes asks for confirmation

- **WHEN** the user has modified a draft field and taps the cancel control
- **THEN** a confirmation dialog appears with "discard changes" (destructive) and "keep editing" options

#### Scenario: Discard confirmed dismisses without saving

- **WHEN** the confirmation dialog is showing and the user chooses "discard changes"
- **THEN** the sheet dismisses and no draft changes are persisted

#### Scenario: Keep editing returns to the form

- **WHEN** the confirmation dialog is showing and the user chooses "keep editing"
- **THEN** the confirmation dialog closes and the sheet stays open with the draft unchanged

#### Scenario: Cancel without changes dismisses directly

- **WHEN** the user taps the cancel control without having modified any draft field
- **THEN** the sheet dismisses immediately without a confirmation dialog

<!-- @trace
source: sheet-hig-compliance
updated: 2026-07-19
code:
  - apps/ios/BuyLedger.xcodeproj/project.pbxproj
  - apps/ios/BuyLedger/Features/Orders/OrderEditFeature.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignEditView.swift
  - apps/ios/BuyLedger/Features/Orders/Components/PaymentMethodEditorSheet.swift
  - apps/ios/BuyLedger/Features/Orders/OrderMergeFeature.swift
  - apps/ios/BuyLedger/Resources/InfoPlist.xcstrings
  - apps/ios/BuyLedgerTests/CampaignEditFeatureTests.swift
  - apps/ios/BuyLedgerTests/OrderMergeFeatureTests.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignEditFeature.swift
  - apps/ios/BuyLedgerTests/CampaignFeatureTests.swift
  - apps/ios/BuyLedgerTests/OrderEditFeatureTests.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderMergeCandidateSheet.swift
  - apps/ios/BuyLedger/Resources/Localizable.xcstrings
  - apps/ios/CLAUDE.md
  - apps/ios/BuyLedger/Features/Orders/Components/OptionPickerSheet.swift
  - apps/ios/BuyLedger/Features/Orders/OrderEditView.swift
-->

---
### Requirement: Values an editor opens with or re-confirms do not make it dirty

An editor's dirty state SHALL compare against the values it was opened with, including values prefilled by the entry point — such as the fields a merge confirmation prefills from the source orders, or the default currency of a new order — so that opening an editor never makes it dirty by itself. Choosing a value equal to the current one, such as re-selecting the same date and time in the order editor, SHALL leave the draft unchanged and SHALL NOT make the editor dirty. Returning the order editor's date and time to the minute it was opened with, after moving it elsewhere, SHALL restore the opened value exactly and SHALL NOT leave the editor dirty.

#### Scenario: A merge confirmation opens clean

- **WHEN** the user opens the merge confirmation form for two orders
- **THEN** the form is not dirty, swiping down dismisses it, and cancelling closes it without a discard confirmation

#### Scenario: Editing a prefilled merge field makes it dirty

- **WHEN** the user changes the customer name in an open merge confirmation form
- **THEN** the form becomes dirty and resists swipe-to-dismiss

#### Scenario: Re-selecting the same date does not make the order editor dirty

- **GIVEN** an order editor opened with the date 2026-04-26 14:30
- **WHEN** the user picks 2026-04-26 14:30 again in the date picker
- **THEN** the draft date is unchanged and the editor is not dirty

#### Scenario: Moving the order time away and back leaves the editor clean

- **GIVEN** an order editor opened with the date 2026-04-26 14:30:00 and a current time whose seconds are 37
- **WHEN** the user moves the time to 14:31 and then back to 14:30
- **THEN** the draft date is 2026-04-26 14:30:00 again and the editor is not dirty

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