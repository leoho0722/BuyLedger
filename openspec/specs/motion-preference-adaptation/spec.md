# motion-preference-adaptation Specification

## Purpose

TBD - created by archiving change 'dynamic-type-and-grouping'. Update Purpose after archive.

## Requirements

### Requirement: Animations honor the reduce motion preference

Animation SHALL read the reduce motion preference from the environment and SHALL be suppressed or replaced with a non-moving equivalent when the preference is enabled. The check SHALL be applied at the point where animation is declared, so that the pattern is established for animations added later rather than requiring each new site to rediscover it.

#### Scenario: Press feedback animation is suppressed

- **WHEN** the reduce motion preference is enabled and the user presses a button using the custom style
- **THEN** the button reaches its pressed appearance without an animated transition

#### Scenario: Animation is unchanged when the preference is off

- **WHEN** the reduce motion preference is disabled
- **THEN** the press feedback animates exactly as it did before this change

<!-- @trace
source: dynamic-type-and-grouping
updated: 2026-07-23
code:
  - apps/ios/BuyLedger/Features/Campaigns/CampaignListView.swift
  - apps/ios/BuyLedger.xcodeproj/project.pbxproj
  - apps/ios/BuyLedger/Resources/Localizable.xcstrings
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel1Numeral.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLBarChart.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderDetailView.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewMergeContextBaseline.1.png
  - apps/ios/BuyLedger/Shared/Keyboard/KeyboardDismissOnTap.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneInformativeIndicator.colorset/Contents.json
  - apps/ios/BuyLedgerTests/LookupManagementFeatureTests.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderRowView.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLRankBadgeFirstBackground.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/States/BLLoadFailureView.swift
  - apps/ios/BuyLedgerTests/OrdersLoadStateTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Buttons/BLButtonStyle.swift
  - apps/ios/BuyLedger/Features/FX/FxFeature.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel4Background.colorset/Contents.json
  - apps/ios/BuyLedger/Features/Orders/Components/MergePhotoPickerSheet.swift
  - apps/ios/BuyLedger/Features/Orders/Components/PaymentMethodEditorSheet.swift
  - apps/ios/BuyLedger/Features/App/RootSidebarLayout.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoViewer.swift
  - apps/ios/BuyLedger/Shared/Extensions/Bundle+Extensions.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/dashboardViewBaseline.1.png
  - apps/ios/BuyLedger/Features/Orders/OrderEditView.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/SegmentedControls/BLSegmentedControl.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneInformativeSoftBackground.colorset/Contents.json
  - apps/ios/README.md
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel3Background.colorset/Contents.json
  - apps/ios/BuyLedgerTests/CampaignReminderFailureTests.swift
  - apps/ios/BuyLedger/Features/Settings/AppearancePreference.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel2Background.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel2Numeral.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneAccentSoftBackground.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneDestructiveSoftBackground.colorset/Contents.json
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementDestination.swift
  - apps/ios/BuyLedgerTests/OrderEditFeatureTests.swift
  - apps/ios/BuyLedgerTests/SnapshotTests.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneAccentSurfaceText.colorset/Contents.json
  - apps/ios/BuyLedger/Features/More/MoreView.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFilterSheet.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneInformativeSurfaceText.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Cards/BLCard.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLDonutChart.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneNeutralSurfaceText.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneDestructiveIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Features/Orders/OrdersView.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeroGradientStart.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Badges/BLBadge.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLPalette.swift
  - apps/ios/BuyLedger/Features/Customers/CustomersView.swift
  - apps/ios/BuyLedger.xcodeproj/xcshareddata/xcschemes/BuyLedgerUITests.xcscheme
  - apps/ios/BuyLedger/Features/Settings/SettingsFeature.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLSparkline.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsStorage.swift
  - apps/ios/BuyLedgerTests/ColorContrast.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/blBarChartThirtyDaysBaseline.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderDetailCostBreakdownBaseline.1.png
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel5Numeral.colorset/Contents.json
  - apps/ios/BuyLedger/Features/Campaigns/CampaignDetailView.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OptionPickerSheet.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersCompactView.swift
  - apps/ios/BuyLedger/Core/Dependencies/OpenSettingsClient.swift
  - apps/ios/BuyLedgerTests/ColorContrastTests.swift
  - apps/ios/BuyLedger/Features/Customers/CustomerRankBadgeStyle.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneWarningOnIndicator.colorset/Contents.json
  - apps/ios/CLAUDE.md
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Chips/BLFilterChip.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneWarningIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Features/FX/FxView.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsView.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsView.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneAccentIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Progress/BLProgressBar.swift
  - apps/ios/BuyLedger/Features/App/RootView.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderStatus+Presentation.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLMetrics.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignEditView.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneSuccessSoftBackground.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLHeatmapDepth.swift
  - apps/ios/BuyLedger/Features/Orders/OrderEditFeature.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeroGradientEnd.colorset/Contents.json
  - apps/ios/BuyLedgerTests/InsightsStatsTests.swift
  - apps/ios/BuyLedger/Features/App/RootFeature.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel4Numeral.colorset/Contents.json
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewBaseline.1.png
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneSuccessSurfaceText.colorset/Contents.json
  - apps/ios/BuyLedgerTests/ContrastComplianceTests.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsSnapshot.swift
  - apps/ios/BuyLedgerTests/OrderEditFocusTests.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneNeutralIndicator.colorset/Contents.json
  - apps/ios/BuyLedgerUITests/PhotoViewerPagingTests.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneSuccessOnIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Features/Quote/QuoteFeature.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneNeutralOnIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementView.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneSuccessIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Features/Insights/InsightsStats.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/States/DelayedProgressView.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLDonutSegment.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneDestructiveOnIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneWarningSoftBackground.colorset/Contents.json
  - apps/ios/BuyLedger/Features/Orders/OrdersFeature.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/ViewModifiers/BLTypographyModifier.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/TextFields/BLAmountField.swift
  - apps/ios/BuyLedger/Features/Quote/QuoteView.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneAccentOnIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Features/Campaigns/CampaignFeature.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Avatar/BLAvatar.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/TextFields/BLSearchField.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel1Background.colorset/Contents.json
  - apps/ios/BuyLedger/Features/Lookups/LookupNameEditorSheet.swift
  - apps/ios/BuyLedgerTests/AISummaryFeatureTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Status/BLStatusPill.swift
  - apps/ios/BuyLedgerTests/CampaignFeatureTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/insightsViewBaseline.1.png
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneNeutralSoftBackground.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel3Numeral.colorset/Contents.json
  - apps/ios/BuyLedgerTests/SettingsFeatureTests.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneInformativeOnIndicator.colorset/Contents.json
  - apps/ios/BuyLedger.xcodeproj/xcshareddata/xcschemes/BuyLedger.xcscheme
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel5Background.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoThumbnail.swift
  - apps/ios/BuyLedger/Features/AISummary/AISummaryFeature.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignEditFeature.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneDestructiveSurfaceText.colorset/Contents.json
  - apps/ios/BuyLedgerUITests/KeyboardDismissTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewBaseline.1.png
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLBarChartValue.swift
  - apps/ios/BuyLedgerTests/OrdersSearchCancellationTests.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneWarningSurfaceText.colorset/Contents.json
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewLongContentBaseline.1.png
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Lists/BLListRow.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardView.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLTone.swift
-->