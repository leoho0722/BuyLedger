# destructive-action-safeguard Specification

## Purpose

TBD - created by archiving change 'navigation-integrity'. Update Purpose after archive.

## Requirements

### Requirement: Destructive actions are confirmed consistently across the app

A destructive action that is uncommon and not reversible SHALL require confirmation before it proceeds. The requirement SHALL apply consistently regardless of which feature module the action lives in. Deleting a lookup item cascades into existing orders and is therefore at least as destructive as deleting a single order, which already requires confirmation.

#### Scenario: Deleting a lookup item requires confirmation

- **WHEN** the user invokes delete on a lookup item, whether from the context menu or the swipe action
- **THEN** a confirmation is presented before anything is removed, and its message states that existing orders referencing the item are affected

#### Scenario: Cancelling the confirmation changes nothing

- **WHEN** the user dismisses the deletion confirmation without confirming
- **THEN** the item remains present and no persistence operation occurs


<!-- @trace
source: navigation-integrity
updated: 2026-07-23
code:
  - apps/ios/BuyLedger/Features/Orders/OrderEditFeature.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderDetailView.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel1Background.colorset/Contents.json
  - apps/ios/BuyLedger.xcodeproj/project.pbxproj
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Cards/BLCard.swift
  - apps/ios/BuyLedger/Features/Settings/AppearancePreference.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewLongContentBaseline.1.png
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneInformativeIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Features/Quote/QuoteFeature.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneDestructiveOnIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLBarChart.swift
  - apps/ios/BuyLedgerTests/InsightsStatsTests.swift
  - apps/ios/BuyLedgerTests/ContrastComplianceTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLMetrics.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneInformativeOnIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Avatar/BLAvatar.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLDonutChart.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLHeatmapDepth.swift
  - apps/ios/BuyLedger/Features/AISummary/AISummaryFeature.swift
  - apps/ios/BuyLedgerTests/SnapshotTests.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneWarningSurfaceText.colorset/Contents.json
  - apps/ios/BuyLedger/Features/Orders/OrderEditView.swift
  - apps/ios/BuyLedgerTests/OrderEditFocusTests.swift
  - apps/ios/BuyLedger/Shared/Keyboard/KeyboardDismissOnTap.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsFeature.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsStorage.swift
  - apps/ios/BuyLedgerTests/CampaignFeatureTests.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel4Background.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel5Numeral.colorset/Contents.json
  - apps/ios/BuyLedger/Features/FX/FxFeature.swift
  - apps/ios/BuyLedger/Features/Orders/Components/PaymentMethodEditorSheet.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsStats.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementView.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneInformativeSoftBackground.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneWarningOnIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Features/Campaigns/CampaignEditFeature.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLBarChartValue.swift
  - apps/ios/BuyLedgerTests/ColorContrastTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewBaseline.1.png
  - apps/ios/BuyLedgerUITests/PhotoViewerPagingTests.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignEditView.swift
  - apps/ios/BuyLedgerTests/ColorContrast.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneWarningIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLSparkline.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/States/BLLoadFailureView.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Badges/BLBadge.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersFeature.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneSuccessIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoViewer.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLTone.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignFeature.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewMergeContextBaseline.1.png
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLDonutSegment.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel5Background.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLPalette.swift
  - apps/ios/BuyLedgerTests/CampaignReminderFailureTests.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupNameEditorSheet.swift
  - apps/ios/BuyLedger/Core/Dependencies/OpenSettingsClient.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsView.swift
  - apps/ios/BuyLedger.xcodeproj/xcshareddata/xcschemes/BuyLedgerUITests.xcscheme
  - apps/ios/BuyLedgerTests/SettingsFeatureTests.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OptionPickerSheet.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderStatus+Presentation.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneAccentIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneInformativeSurfaceText.colorset/Contents.json
  - apps/ios/BuyLedger.xcodeproj/xcshareddata/xcschemes/BuyLedger.xcscheme
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeroGradientEnd.colorset/Contents.json
  - apps/ios/BuyLedgerTests/RootFeatureTests.swift
  - apps/ios/BuyLedger/Features/Customers/CustomersView.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFilterSheet.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoThumbnail.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignDetailView.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel4Numeral.colorset/Contents.json
  - apps/ios/BuyLedger/Features/Quote/QuoteView.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneNeutralIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel1Numeral.colorset/Contents.json
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderDetailCostBreakdownBaseline.1.png
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneSuccessOnIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/States/DelayedProgressView.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsView.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/blBarChartThirtyDaysBaseline.1.png
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel3Numeral.colorset/Contents.json
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewBaseline.1.png
  - apps/ios/BuyLedger/Features/App/RootFeature.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneDestructiveIndicator.colorset/Contents.json
  - apps/ios/BuyLedgerTests/OrdersSearchCancellationTests.swift
  - apps/ios/BuyLedgerTests/AISummaryFeatureTests.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementDestination.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneAccentSoftBackground.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Localizable.xcstrings
  - apps/ios/BuyLedger/Features/Dashboard/DashboardView.swift
  - apps/ios/BuyLedger/Features/Orders/Components/MergePhotoPickerSheet.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/TextFields/BLAmountField.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneAccentSurfaceText.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneNeutralOnIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneNeutralSoftBackground.colorset/Contents.json
  - apps/ios/BuyLedgerTests/OrdersLoadStateTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Lists/BLListRow.swift
  - apps/ios/BuyLedger/Features/More/MoreView.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneDestructiveSurfaceText.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Progress/BLProgressBar.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/TextFields/BLSearchField.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/insightsViewBaseline.1.png
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Status/BLStatusPill.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneSuccessSurfaceText.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneDestructiveSoftBackground.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneNeutralSurfaceText.colorset/Contents.json
  - apps/ios/BuyLedger/Features/App/RootSidebarLayout.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Chips/BLFilterChip.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/ViewModifiers/BLTypographyModifier.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsSnapshot.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Buttons/BLButtonStyle.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneWarningSoftBackground.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel2Background.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel3Background.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLRankBadgeFirstBackground.colorset/Contents.json
  - apps/ios/BuyLedger/Features/Campaigns/CampaignListView.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeroGradientStart.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneAccentOnIndicator.colorset/Contents.json
  - apps/ios/CLAUDE.md
  - apps/ios/BuyLedger/Features/FX/FxView.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/SegmentedControls/BLSegmentedControl.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel2Numeral.colorset/Contents.json
  - apps/ios/BuyLedger/Features/Customers/CustomerRankBadgeStyle.swift
  - apps/ios/README.md
  - apps/ios/BuyLedger/Features/Orders/OrdersCompactView.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderRowView.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersView.swift
  - apps/ios/BuyLedgerUITests/KeyboardDismissTests.swift
  - apps/ios/BuyLedgerTests/LookupManagementFeatureTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/dashboardViewBaseline.1.png
  - apps/ios/BuyLedger/Features/App/RootView.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneSuccessSoftBackground.colorset/Contents.json
  - apps/ios/BuyLedgerTests/OrderEditFeatureTests.swift
  - apps/ios/BuyLedger/Shared/Extensions/Bundle+Extensions.swift
-->

---
### Requirement: Deletion updates state only after persistence succeeds

A deletion SHALL update the presented state only after the persistence operation succeeds. Optimistic removal followed by an error message SHALL NOT be used, because it leaves the user seeing a failure message alongside an item that has already disappeared.

#### Scenario: Failed deletion leaves the item visible

- **WHEN** the user confirms deletion and the persistence operation fails
- **THEN** the item remains visible in the list and a failure message is shown

#### Scenario: Successful deletion removes the item

- **WHEN** the user confirms deletion and the persistence operation succeeds
- **THEN** the item is removed from the list and from any in-memory copies held elsewhere

<!-- @trace
source: navigation-integrity
updated: 2026-07-23
code:
  - apps/ios/BuyLedger/Features/Orders/OrderEditFeature.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderDetailView.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel1Background.colorset/Contents.json
  - apps/ios/BuyLedger.xcodeproj/project.pbxproj
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Cards/BLCard.swift
  - apps/ios/BuyLedger/Features/Settings/AppearancePreference.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewLongContentBaseline.1.png
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneInformativeIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Features/Quote/QuoteFeature.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneDestructiveOnIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLBarChart.swift
  - apps/ios/BuyLedgerTests/InsightsStatsTests.swift
  - apps/ios/BuyLedgerTests/ContrastComplianceTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLMetrics.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneInformativeOnIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Avatar/BLAvatar.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLDonutChart.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLHeatmapDepth.swift
  - apps/ios/BuyLedger/Features/AISummary/AISummaryFeature.swift
  - apps/ios/BuyLedgerTests/SnapshotTests.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneWarningSurfaceText.colorset/Contents.json
  - apps/ios/BuyLedger/Features/Orders/OrderEditView.swift
  - apps/ios/BuyLedgerTests/OrderEditFocusTests.swift
  - apps/ios/BuyLedger/Shared/Keyboard/KeyboardDismissOnTap.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsFeature.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsStorage.swift
  - apps/ios/BuyLedgerTests/CampaignFeatureTests.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel4Background.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel5Numeral.colorset/Contents.json
  - apps/ios/BuyLedger/Features/FX/FxFeature.swift
  - apps/ios/BuyLedger/Features/Orders/Components/PaymentMethodEditorSheet.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsStats.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementView.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneInformativeSoftBackground.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneWarningOnIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Features/Campaigns/CampaignEditFeature.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLBarChartValue.swift
  - apps/ios/BuyLedgerTests/ColorContrastTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewBaseline.1.png
  - apps/ios/BuyLedgerUITests/PhotoViewerPagingTests.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignEditView.swift
  - apps/ios/BuyLedgerTests/ColorContrast.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneWarningIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLSparkline.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/States/BLLoadFailureView.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Badges/BLBadge.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersFeature.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneSuccessIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoViewer.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLTone.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignFeature.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewMergeContextBaseline.1.png
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLDonutSegment.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel5Background.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLPalette.swift
  - apps/ios/BuyLedgerTests/CampaignReminderFailureTests.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupNameEditorSheet.swift
  - apps/ios/BuyLedger/Core/Dependencies/OpenSettingsClient.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsView.swift
  - apps/ios/BuyLedger.xcodeproj/xcshareddata/xcschemes/BuyLedgerUITests.xcscheme
  - apps/ios/BuyLedgerTests/SettingsFeatureTests.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OptionPickerSheet.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderStatus+Presentation.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneAccentIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneInformativeSurfaceText.colorset/Contents.json
  - apps/ios/BuyLedger.xcodeproj/xcshareddata/xcschemes/BuyLedger.xcscheme
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeroGradientEnd.colorset/Contents.json
  - apps/ios/BuyLedgerTests/RootFeatureTests.swift
  - apps/ios/BuyLedger/Features/Customers/CustomersView.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFilterSheet.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoThumbnail.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignDetailView.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel4Numeral.colorset/Contents.json
  - apps/ios/BuyLedger/Features/Quote/QuoteView.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneNeutralIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel1Numeral.colorset/Contents.json
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderDetailCostBreakdownBaseline.1.png
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneSuccessOnIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/States/DelayedProgressView.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsView.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/blBarChartThirtyDaysBaseline.1.png
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel3Numeral.colorset/Contents.json
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewBaseline.1.png
  - apps/ios/BuyLedger/Features/App/RootFeature.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneDestructiveIndicator.colorset/Contents.json
  - apps/ios/BuyLedgerTests/OrdersSearchCancellationTests.swift
  - apps/ios/BuyLedgerTests/AISummaryFeatureTests.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementDestination.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneAccentSoftBackground.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Localizable.xcstrings
  - apps/ios/BuyLedger/Features/Dashboard/DashboardView.swift
  - apps/ios/BuyLedger/Features/Orders/Components/MergePhotoPickerSheet.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/TextFields/BLAmountField.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneAccentSurfaceText.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneNeutralOnIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneNeutralSoftBackground.colorset/Contents.json
  - apps/ios/BuyLedgerTests/OrdersLoadStateTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Lists/BLListRow.swift
  - apps/ios/BuyLedger/Features/More/MoreView.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneDestructiveSurfaceText.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Progress/BLProgressBar.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/TextFields/BLSearchField.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/insightsViewBaseline.1.png
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Status/BLStatusPill.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneSuccessSurfaceText.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneDestructiveSoftBackground.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneNeutralSurfaceText.colorset/Contents.json
  - apps/ios/BuyLedger/Features/App/RootSidebarLayout.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Chips/BLFilterChip.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/ViewModifiers/BLTypographyModifier.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsSnapshot.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Buttons/BLButtonStyle.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneWarningSoftBackground.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel2Background.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel3Background.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLRankBadgeFirstBackground.colorset/Contents.json
  - apps/ios/BuyLedger/Features/Campaigns/CampaignListView.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeroGradientStart.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneAccentOnIndicator.colorset/Contents.json
  - apps/ios/CLAUDE.md
  - apps/ios/BuyLedger/Features/FX/FxView.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/SegmentedControls/BLSegmentedControl.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel2Numeral.colorset/Contents.json
  - apps/ios/BuyLedger/Features/Customers/CustomerRankBadgeStyle.swift
  - apps/ios/README.md
  - apps/ios/BuyLedger/Features/Orders/OrdersCompactView.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderRowView.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersView.swift
  - apps/ios/BuyLedgerUITests/KeyboardDismissTests.swift
  - apps/ios/BuyLedgerTests/LookupManagementFeatureTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/dashboardViewBaseline.1.png
  - apps/ios/BuyLedger/Features/App/RootView.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneSuccessSoftBackground.colorset/Contents.json
  - apps/ios/BuyLedgerTests/OrderEditFeatureTests.swift
  - apps/ios/BuyLedger/Shared/Extensions/Bundle+Extensions.swift
-->