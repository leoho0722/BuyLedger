# ai-order-summary Specification

## Purpose

TBD - created by archiving change 'ai-product-summary'. Update Purpose after archive.

## Requirements

### Requirement: AI summary entry point gated by setting

The orders list SHALL present an "AI summary" toolbar action on iOS and iPadOS, placed alongside the existing new-order action. The action SHALL be disabled when the currently filtered orders list is empty. When activated, the system SHALL read the `useAiSummary` setting and branch: if enabled, it SHALL present the streaming summary sheet; if disabled, it SHALL present a prompt alert.

#### Scenario: Activate with AI summary enabled

- **WHEN** the user activates the AI summary action and `useAiSummary` is enabled
- **THEN** the system presents the streaming summary sheet and begins summarizing the filtered list's product details

#### Scenario: Activate with AI summary disabled

- **WHEN** the user activates the AI summary action and `useAiSummary` is disabled
- **THEN** the system presents a prompt alert instead of the sheet, and does not call the AI service

#### Scenario: Empty filtered list

- **WHEN** the currently filtered orders list contains no orders
- **THEN** the AI summary action is disabled

---
### Requirement: Streaming Markdown summary sheet

When AI summary is enabled, the system SHALL stream the summary from the configured AI provider's chat streaming API through the LKAIKit chat client and render the summary as Markdown that updates incrementally as content streams in. The summary content SHALL be produced in Traditional Chinese. Rendered Markdown SHALL display block structure including headings and lists, not only inline styles. While streaming, the sheet SHALL indicate progress; on completion it SHALL show the full rendered summary.

The stream SHALL be bounded by an overall duration limit of 30 seconds in production, in addition to any idle timeout the request layer provides. A response that keeps producing content slowly SHALL NOT be able to hold the sheet indefinitely. On reaching the limit the system SHALL stop the stream and present what was received together with a statement that the summary was cut short, rather than discarding the partial content or continuing to wait.

When the stream completes, or reaches the overall duration limit, without having received any content other than whitespace, the sheet SHALL stop the progress indication and present the failure state with a retry action instead of an empty summary or a statement that the summary was cut short.

#### Scenario: Streaming renders incrementally

- **WHEN** the summary sheet is presented and the service streams Markdown content
- **THEN** the sheet appends each streamed chunk to the displayed summary and re-renders the Markdown as it grows

#### Scenario: Stream completion

- **WHEN** the service signals the stream is done
- **THEN** the sheet shows the complete rendered Markdown summary and stops the progress indication

#### Scenario: Cancel by dismissing the sheet

- **WHEN** the user dismisses the summary sheet while streaming is in progress
- **THEN** the system cancels the in-flight stream and underlying network request without surfacing an error

#### Scenario: Overall 30-second duration limit ends a slow stream

- **WHEN** a stream keeps producing content past the 30-second overall duration limit
- **THEN** the system stops the stream, keeps the content received so far, stops the progress indication, and states that the summary was cut short

#### Scenario: A stream that ends without content shows a failure

- **WHEN** the stream completes, or reaches the 30-second overall duration limit, without having received any content other than whitespace
- **THEN** the sheet stops the progress indication and shows the failure state with a retry action instead of an empty summary


<!-- @trace
source: ai-summary-lkaikit-provider
updated: 2026-11-25
code:
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersContainerPlanCategoriesTests.swift
  - apps/ios/BuyLedgerTests/Features/AISummary/AISummaryServiceTests.swift
  - apps/ios/BuyLedgerTests/Features/AISummary/AISummaryServiceTransportTests.swift
  - apps/ios/BuyLedger/Features/AISummary/Data/AISummaryService.swift
  - apps/ios/BuyLedgerTests/Features/App/RootFeatureAISummaryProjectionTests.swift
  - apps/ios/BuyLedger/Features/AISummary/Presentation/Root/AISummaryView.swift
  - apps/ios/BuyLedger.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotMoreTests/settingsView_開啟AI摘要與生物辨識_顯示對應列.1.png
  - apps/ios/BuyLedger/Features/AISummary/Domain/AISummaryProvider.swift
  - apps/ios/BuyLedgerTests/Features/More/MoreFeatureTests.swift
  - apps/ios/BuyLedgerTests/Core/Storage/AppConfigurationStoreTests.swift
  - apps/ios/BuyLedger/Resources/Info.plist
  - apps/ios/BuyLedger/Features/Settings/Domain/SettingsSnapshot.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersFeatureAISummaryProjectionTests.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/Root/Plans/OrdersContainerPlan+Requests.swift
  - apps/ios/BuyLedger/Features/App/Presentation/Root/RootFeature.swift
  - apps/ios/BuyLedger/Features/Settings/Data/SettingsService.swift
  - apps/ios/BuyLedgerTests/Features/AISummary/AISummaryServiceTestSupport.swift
  - apps/ios/BuyLedger/Features/AISummary/Presentation/Root/AISummaryFeature.swift
  - apps/ios/BuyLedgerTests/Features/More/MoreFeatureRelaysTests.swift
  - apps/ios/BuyLedgerTests/Features/Settings/SettingsFeatureTests.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotMoreTests/settingsView_預設偏好_顯示版本與偏好列.1.png
  - apps/ios/CLAUDE.md
  - apps/ios/README.md
  - apps/ios/BuyLedger/Features/Settings/Presentation/Root/SettingsView.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersFeatureLoadAndSummaryTests.swift
  - apps/ios/BuyLedger/Resources/Config.example.xcconfig
  - apps/ios/BuyLedgerTests/Features/App/RootFeatureDeepLinksTests.swift
  - apps/ios/BuyLedger/App/Testing/TestDoubles/BLUITestStubs.swift
  - apps/ios/BuyLedger/Resources/Localizable.xcstrings
  - apps/ios/BuyLedgerTests/Mocks/MockChatURLProtocol.swift
  - apps/ios/BuyLedger.xcodeproj/project.xcproj
  - apps/ios/BuyLedger/Features/Settings/Presentation/Root/SettingsFeature.swift
  - apps/ios/BuyLedgerTests/Features/Settings/SettingsFeatureAppLockTests.swift
  - apps/ios/BuyLedger/Features/Orders/Domain/OrderAISummarySettings.swift
  - apps/ios/BuyLedgerTests/Features/AISummary/AISummaryFeatureTests.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/Root/OrdersFeature.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersFeatureFailureTimingTests.swift
  - apps/ios/BuyLedgerTests/Features/Settings/SettingsServiceTests.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersContainerPlanRequestPresentationTests.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/SnapshotSharedTests.swift
-->

---
### Requirement: Summary input scope is the filtered list's product details

The summary input SHALL be derived from the product details (item name, quantity, unit price with currency, and category) of the orders in the currently filtered list. When a category filter is active, the input SHALL be limited to the orders that contain at least one selected category, because the filtered list itself is already scoped to the selected category set, and the prompt SHALL state every selected category as the filtered scope. The system SHALL NOT include fabricated data not present in the orders.

#### Scenario: No category filter active

- **WHEN** no category filter is active
- **THEN** the summary input covers the product details of all orders in the current filtered list
- **AND** the prompt states that it covers every category of the current list

#### Scenario: Category filter active

- **WHEN** a category filter with one or more selected categories is active
- **THEN** the summary input covers only the product details of the orders in the filtered list, matching the filtered list
- **AND** the prompt names every selected category as the filtered scope

##### Example: scope text for selected categories

| Selected categories | Scope stated in the prompt |
| --- | --- |
| none | covers every category of the current list |
| {"美妝"} | filtered categories: 美妝 |
| {"書籍", "美妝"} | filtered categories: 美妝、書籍 (names ordered with a locale-aware standard comparison) |


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
### Requirement: Disabled-state prompt alert with deep link to settings

When AI summary is disabled, the prompt alert SHALL present two actions: a left "close" action that dismisses the alert, and a right "go to settings" action. Activating the right action SHALL navigate the user to the settings page where the toggle lives. On iOS and iPadOS this SHALL switch to the more tab and push the settings page.

#### Scenario: Close the prompt

- **WHEN** the user activates the left "close" action
- **THEN** the alert is dismissed and no navigation occurs

#### Scenario: Navigate to settings (iOS / iPadOS)

- **WHEN** the user activates the right "go to settings" action on iOS or iPadOS
- **THEN** the app switches to the more tab and pushes the settings page

---
### Requirement: AI summary setting and model configuration

The settings page SHALL provide a toggle that persists whether AI summary is enabled. The system SHALL persist the AI summary provider together with a model name for that provider, defaulting to the default provider and that provider's default model. In Debug builds the settings page SHALL provide a control to change the model at runtime from the selected provider's candidate list with a custom-value option; in Release builds no model-switching control SHALL be presented and the persisted model SHALL be used. No build SHALL present a control to change the provider in this version.

A model equal to the provider's default model SHALL be stored as following the default rather than as a fixed name, so that a later change of the provider's default model applies to installations where the user never chose another model. A stored model name SHALL be used only together with the provider it was saved with. When no provider is stored, as for values written before providers were introduced, or the stored provider is not a supported provider, the system SHALL use the default provider and its default model and SHALL NOT send the stored model name to any provider.

Renaming the code identifiers that hold these settings SHALL NOT change the keys under which they are stored, so that a value persisted by an earlier version is still read after an update.

#### Scenario: Toggle persists across launches

- **WHEN** the user changes the AI summary toggle
- **THEN** the new value is persisted and restored on the next launch

#### Scenario: Model switching available only in Debug

- **WHEN** the build is a Debug build
- **THEN** the settings page presents a model-switching control listing the selected provider's candidate models and a custom option, whose selection persists and takes effect on the next summary

#### Scenario: Model fixed in Release

- **WHEN** the build is a Release build
- **THEN** the settings page presents no model-switching control and the persisted model is used

#### Scenario: A toggle saved before an identifier rename is still read

- **WHEN** the AI summary toggle was turned on by a version that used a different code identifier for it, and the app is updated
- **THEN** the toggle is still on after the update, because the stored key did not change

#### Scenario: A model saved before providers existed is not sent to the new provider

- **WHEN** the stored settings contain a model name but no provider, and the settings are read
- **THEN** the provider is the default provider and the model is that provider's default model

##### Example: provider and model reads

| Stored provider | Stored model | Read provider | Read model | Notes |
| --------------- | ------------ | ------------- | ---------- | ----- |
| never written | never written | `anthropic` | `claude-haiku-5-5` | fresh install |
| never written | `gemma4:31b-cloud` | `anthropic` | `claude-haiku-5-5` | written before providers existed |
| `anthropic` | `claude-sonnet-5-5` | `anthropic` | `claude-sonnet-5-5` | user choice in Debug |
| `anthropic` | empty | `anthropic` | `claude-haiku-5-5` | empty model falls back to the provider default |
| `retired-provider` | `some-model` | `anthropic` | `claude-haiku-5-5` | unsupported provider |

#### Scenario: Saving settings writes the provider with the model

- **WHEN** the settings are saved with a provider and a model
- **THEN** the provider is persisted, and the model is persisted as following the default when it equals the provider's default model, otherwise as the chosen name

##### Example: stored values after saving

| Saved provider | Saved model | Stored provider | Stored model |
| -------------- | ----------- | --------------- | ------------ |
| `anthropic` | `claude-haiku-5-5` | `anthropic` | empty (follows the provider default) |
| `anthropic` | `claude-sonnet-5-5` | `anthropic` | `claude-sonnet-5-5` |


<!-- @trace
source: ai-summary-lkaikit-provider
updated: 2026-11-25
code:
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersContainerPlanCategoriesTests.swift
  - apps/ios/BuyLedgerTests/Features/AISummary/AISummaryServiceTests.swift
  - apps/ios/BuyLedgerTests/Features/AISummary/AISummaryServiceTransportTests.swift
  - apps/ios/BuyLedger/Features/AISummary/Data/AISummaryService.swift
  - apps/ios/BuyLedgerTests/Features/App/RootFeatureAISummaryProjectionTests.swift
  - apps/ios/BuyLedger/Features/AISummary/Presentation/Root/AISummaryView.swift
  - apps/ios/BuyLedger.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotMoreTests/settingsView_開啟AI摘要與生物辨識_顯示對應列.1.png
  - apps/ios/BuyLedger/Features/AISummary/Domain/AISummaryProvider.swift
  - apps/ios/BuyLedgerTests/Features/More/MoreFeatureTests.swift
  - apps/ios/BuyLedgerTests/Core/Storage/AppConfigurationStoreTests.swift
  - apps/ios/BuyLedger/Resources/Info.plist
  - apps/ios/BuyLedger/Features/Settings/Domain/SettingsSnapshot.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersFeatureAISummaryProjectionTests.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/Root/Plans/OrdersContainerPlan+Requests.swift
  - apps/ios/BuyLedger/Features/App/Presentation/Root/RootFeature.swift
  - apps/ios/BuyLedger/Features/Settings/Data/SettingsService.swift
  - apps/ios/BuyLedgerTests/Features/AISummary/AISummaryServiceTestSupport.swift
  - apps/ios/BuyLedger/Features/AISummary/Presentation/Root/AISummaryFeature.swift
  - apps/ios/BuyLedgerTests/Features/More/MoreFeatureRelaysTests.swift
  - apps/ios/BuyLedgerTests/Features/Settings/SettingsFeatureTests.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotMoreTests/settingsView_預設偏好_顯示版本與偏好列.1.png
  - apps/ios/CLAUDE.md
  - apps/ios/README.md
  - apps/ios/BuyLedger/Features/Settings/Presentation/Root/SettingsView.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersFeatureLoadAndSummaryTests.swift
  - apps/ios/BuyLedger/Resources/Config.example.xcconfig
  - apps/ios/BuyLedgerTests/Features/App/RootFeatureDeepLinksTests.swift
  - apps/ios/BuyLedger/App/Testing/TestDoubles/BLUITestStubs.swift
  - apps/ios/BuyLedger/Resources/Localizable.xcstrings
  - apps/ios/BuyLedgerTests/Mocks/MockChatURLProtocol.swift
  - apps/ios/BuyLedger.xcodeproj/project.xcproj
  - apps/ios/BuyLedger/Features/Settings/Presentation/Root/SettingsFeature.swift
  - apps/ios/BuyLedgerTests/Features/Settings/SettingsFeatureAppLockTests.swift
  - apps/ios/BuyLedger/Features/Orders/Domain/OrderAISummarySettings.swift
  - apps/ios/BuyLedgerTests/Features/AISummary/AISummaryFeatureTests.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/Root/OrdersFeature.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersFeatureFailureTimingTests.swift
  - apps/ios/BuyLedgerTests/Features/Settings/SettingsServiceTests.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersContainerPlanRequestPresentationTests.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/SnapshotSharedTests.swift
-->

---
### Requirement: Failure handling shows empty/error state without fake data

When the AI service cannot produce a summary — missing API key, authentication failure, transport error, or non-success HTTP status — the sheet SHALL present a failure state with a retry action and SHALL NOT display fabricated summary content.

Failures reported by the chat client SHALL map to the sheet's existing failure categories: an invalid key or a permission failure SHALL be shown as an authentication failure; an exhausted quota as quota exhaustion; rate limiting as a server error with status 429; an unavailable service as a server error with its status code; a network failure as a connection problem; an unreadable response as a response that could not be parsed; and a rejected request, a refusal, or an unrecognized failure as a service error with a short code. A cancelled stream SHALL end without surfacing an error.

#### Scenario: Missing API key

- **WHEN** the API key for the configured provider is not configured
- **THEN** the sheet shows a failure state indicating the summary is not set up, offers retry, and sends no request

#### Scenario: Service or transport error

- **WHEN** the service returns an authentication failure, a non-success status, or a transport error occurs
- **THEN** the sheet shows a failure state with a friendly message and a retry action, and no partial fabricated content is presented as success

##### Example: chat client failure mapping

| Chat client failure | Failure shown by the sheet |
| ------------------- | -------------------------- |
| invalid API key | AI service authentication failed |
| permission denied | AI service authentication failed |
| quota exceeded | API quota exhausted |
| rate limited | server error (429) |
| service unavailable with status 529 | server error (529) |
| network failure | connection problem |
| unreadable response | response could not be parsed |
| invalid request | service error (invalid_request) |
| refused | service error (refused) |
| cancelled | no failure; the stream ends |


<!-- @trace
source: ai-summary-lkaikit-provider
updated: 2026-11-25
code:
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersContainerPlanCategoriesTests.swift
  - apps/ios/BuyLedgerTests/Features/AISummary/AISummaryServiceTests.swift
  - apps/ios/BuyLedgerTests/Features/AISummary/AISummaryServiceTransportTests.swift
  - apps/ios/BuyLedger/Features/AISummary/Data/AISummaryService.swift
  - apps/ios/BuyLedgerTests/Features/App/RootFeatureAISummaryProjectionTests.swift
  - apps/ios/BuyLedger/Features/AISummary/Presentation/Root/AISummaryView.swift
  - apps/ios/BuyLedger.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotMoreTests/settingsView_開啟AI摘要與生物辨識_顯示對應列.1.png
  - apps/ios/BuyLedger/Features/AISummary/Domain/AISummaryProvider.swift
  - apps/ios/BuyLedgerTests/Features/More/MoreFeatureTests.swift
  - apps/ios/BuyLedgerTests/Core/Storage/AppConfigurationStoreTests.swift
  - apps/ios/BuyLedger/Resources/Info.plist
  - apps/ios/BuyLedger/Features/Settings/Domain/SettingsSnapshot.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersFeatureAISummaryProjectionTests.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/Root/Plans/OrdersContainerPlan+Requests.swift
  - apps/ios/BuyLedger/Features/App/Presentation/Root/RootFeature.swift
  - apps/ios/BuyLedger/Features/Settings/Data/SettingsService.swift
  - apps/ios/BuyLedgerTests/Features/AISummary/AISummaryServiceTestSupport.swift
  - apps/ios/BuyLedger/Features/AISummary/Presentation/Root/AISummaryFeature.swift
  - apps/ios/BuyLedgerTests/Features/More/MoreFeatureRelaysTests.swift
  - apps/ios/BuyLedgerTests/Features/Settings/SettingsFeatureTests.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotMoreTests/settingsView_預設偏好_顯示版本與偏好列.1.png
  - apps/ios/CLAUDE.md
  - apps/ios/README.md
  - apps/ios/BuyLedger/Features/Settings/Presentation/Root/SettingsView.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersFeatureLoadAndSummaryTests.swift
  - apps/ios/BuyLedger/Resources/Config.example.xcconfig
  - apps/ios/BuyLedgerTests/Features/App/RootFeatureDeepLinksTests.swift
  - apps/ios/BuyLedger/App/Testing/TestDoubles/BLUITestStubs.swift
  - apps/ios/BuyLedger/Resources/Localizable.xcstrings
  - apps/ios/BuyLedgerTests/Mocks/MockChatURLProtocol.swift
  - apps/ios/BuyLedger.xcodeproj/project.xcproj
  - apps/ios/BuyLedger/Features/Settings/Presentation/Root/SettingsFeature.swift
  - apps/ios/BuyLedgerTests/Features/Settings/SettingsFeatureAppLockTests.swift
  - apps/ios/BuyLedger/Features/Orders/Domain/OrderAISummarySettings.swift
  - apps/ios/BuyLedgerTests/Features/AISummary/AISummaryFeatureTests.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/Root/OrdersFeature.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersFeatureFailureTimingTests.swift
  - apps/ios/BuyLedgerTests/Features/Settings/SettingsServiceTests.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersContainerPlanRequestPresentationTests.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/SnapshotSharedTests.swift
-->

---
### Requirement: AI summary provider is a configured value with a single extension point

The AI summary SHALL be produced by an AI provider selected from a closed list of supported providers, together with a model name for that provider. Each supported provider SHALL define the name of its API key configuration, its default model, and its Debug candidate models, and the summary request SHALL be sent through a provider-neutral chat client built for the selected provider. Supporting an additional provider SHALL require adding it to the provider list and to the client construction for providers, and SHALL NOT require changing the summary sheet's reducer or view. In this version the only supported provider SHALL be Anthropic, with default model `claude-haiku-5-5`, Debug candidates `claude-haiku-5-5`, `claude-sonnet-5-5` and `claude-opus-5-5`, and API key configuration `ANTHROPIC_API_KEY`.

The request for the selected provider SHALL carry the summary prompt as a single user message, SHALL carry the selected model, and SHALL carry its API key only in a request header, never in the request URL.

#### Scenario: The default configuration summarizes with Claude Haiku 5.5

- **WHEN** the user has never chosen a provider or model and opens the AI summary sheet with an Anthropic key configured
- **THEN** the summary request is sent to Anthropic with model `claude-haiku-5-5`, the prompt as the only user message, and the key in a request header

#### Scenario: The summary sheet passes the configured provider and model

- **WHEN** the orders container presents the AI summary sheet while the settings hold provider `anthropic` and model `claude-sonnet-5-5`
- **THEN** the sheet requests the summary from provider `anthropic` with model `claude-sonnet-5-5` and reads the API key configured for `anthropic`

<!-- @trace
source: ai-summary-lkaikit-provider
updated: 2026-11-25
code:
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersContainerPlanCategoriesTests.swift
  - apps/ios/BuyLedgerTests/Features/AISummary/AISummaryServiceTests.swift
  - apps/ios/BuyLedgerTests/Features/AISummary/AISummaryServiceTransportTests.swift
  - apps/ios/BuyLedger/Features/AISummary/Data/AISummaryService.swift
  - apps/ios/BuyLedgerTests/Features/App/RootFeatureAISummaryProjectionTests.swift
  - apps/ios/BuyLedger/Features/AISummary/Presentation/Root/AISummaryView.swift
  - apps/ios/BuyLedger.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotMoreTests/settingsView_開啟AI摘要與生物辨識_顯示對應列.1.png
  - apps/ios/BuyLedger/Features/AISummary/Domain/AISummaryProvider.swift
  - apps/ios/BuyLedgerTests/Features/More/MoreFeatureTests.swift
  - apps/ios/BuyLedgerTests/Core/Storage/AppConfigurationStoreTests.swift
  - apps/ios/BuyLedger/Resources/Info.plist
  - apps/ios/BuyLedger/Features/Settings/Domain/SettingsSnapshot.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersFeatureAISummaryProjectionTests.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/Root/Plans/OrdersContainerPlan+Requests.swift
  - apps/ios/BuyLedger/Features/App/Presentation/Root/RootFeature.swift
  - apps/ios/BuyLedger/Features/Settings/Data/SettingsService.swift
  - apps/ios/BuyLedgerTests/Features/AISummary/AISummaryServiceTestSupport.swift
  - apps/ios/BuyLedger/Features/AISummary/Presentation/Root/AISummaryFeature.swift
  - apps/ios/BuyLedgerTests/Features/More/MoreFeatureRelaysTests.swift
  - apps/ios/BuyLedgerTests/Features/Settings/SettingsFeatureTests.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotMoreTests/settingsView_預設偏好_顯示版本與偏好列.1.png
  - apps/ios/CLAUDE.md
  - apps/ios/README.md
  - apps/ios/BuyLedger/Features/Settings/Presentation/Root/SettingsView.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersFeatureLoadAndSummaryTests.swift
  - apps/ios/BuyLedger/Resources/Config.example.xcconfig
  - apps/ios/BuyLedgerTests/Features/App/RootFeatureDeepLinksTests.swift
  - apps/ios/BuyLedger/App/Testing/TestDoubles/BLUITestStubs.swift
  - apps/ios/BuyLedger/Resources/Localizable.xcstrings
  - apps/ios/BuyLedgerTests/Mocks/MockChatURLProtocol.swift
  - apps/ios/BuyLedger.xcodeproj/project.xcproj
  - apps/ios/BuyLedger/Features/Settings/Presentation/Root/SettingsFeature.swift
  - apps/ios/BuyLedgerTests/Features/Settings/SettingsFeatureAppLockTests.swift
  - apps/ios/BuyLedger/Features/Orders/Domain/OrderAISummarySettings.swift
  - apps/ios/BuyLedgerTests/Features/AISummary/AISummaryFeatureTests.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/Root/OrdersFeature.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersFeatureFailureTimingTests.swift
  - apps/ios/BuyLedgerTests/Features/Settings/SettingsServiceTests.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersContainerPlanRequestPresentationTests.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/SnapshotSharedTests.swift
-->