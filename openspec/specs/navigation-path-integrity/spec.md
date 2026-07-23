# navigation-path-integrity Specification

## Purpose

TBD - created by archiving change 'navigation-integrity'. Update Purpose after archive.

## Requirements

### Requirement: Each destination is reachable through a single path

A destination SHALL be reachable through exactly one navigation path, so that the back path always reflects the true hierarchy. Where a destination can be opened both from a list and from a deep link, both SHALL write into the same navigation stack rather than using independent presentation mechanisms. A deep link SHALL reset the stack before pushing, and the reset and push SHALL occur within a single state update so that no intermediate state presents two copies.

#### Scenario: Deep link does not stack a second copy

- **WHEN** the user has already navigated to settings from the list, and a deep link to settings is then triggered
- **THEN** exactly one settings screen exists, and navigating back once returns to the root of that tab

#### Scenario: Back path reflects the true hierarchy

- **WHEN** the user reaches settings by any available path
- **THEN** navigating back returns to the tab root rather than to an unrelated sibling screen


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
### Requirement: Selection has a single source of truth

A list that supports selection SHALL express all of its selectable items through one selection model. Two selection mechanisms SHALL NOT coexist in the same list, because their independent states allow two rows to appear selected at once.

#### Scenario: Sidebar highlights exactly one row

- **WHEN** the user selects a smart group in the sidebar
- **THEN** exactly one row appears selected, and the tab row for the destination the smart group leads to does not also appear selected

#### Scenario: Selecting a smart group preserves existing filters

- **WHEN** the user has set a date period and a category filter, and then selects a smart group
- **THEN** the previously chosen date period and category filter remain unchanged


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
### Requirement: Only one modal layer is presented at a time

The interface SHALL NOT present a modal on top of another modal. Where content must be shown from within a presented sheet, it SHALL be pushed onto that sheet's existing navigation stack. A screen SHALL NOT declare two presentation modifiers of the same kind whose states can both become true, because the system silently drops the second.

#### Scenario: Photo viewing is pushed rather than stacked

- **WHEN** the user opens photo viewing from within the order edit form
- **THEN** the photo viewer is pushed onto the form's navigation stack, no second modal layer exists, and navigating back returns to the form

#### Scenario: Unsaved change protection survives photo viewing

- **WHEN** the user has unsaved edits, opens photo viewing, and returns
- **THEN** the unsaved change protection still applies to the form

#### Scenario: Lookup management presents one sheet

- **WHEN** the lookup management screen presents an add or an edit form
- **THEN** exactly one sheet is presented, and its content is determined by a single presentation state rather than by two independent modifiers

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