# text-input-ergonomics Specification

## Purpose

本規格涵蓋表單欄位的個別人因規則，包括可填寫欄位宣告內容類型以啟用自動填寫、表單值欄位符合最小熱區、長表單管理焦點順序。不涵蓋 `keyboard-dismissal-paths` 所訂的各種鍵盤收合路徑與其操作機制。

## Requirements

### Requirement: Fillable fields declare their content type

Text fields whose content the system can supply SHALL declare their content type so that autofill and refined keyboard suggestions become available. Free-form fields that the system cannot meaningfully fill SHALL declare that explicitly rather than leaving the content type unset, so that the system does not misclassify them.

#### Scenario: Customer name offers autofill

- **WHEN** the user focuses the customer name field and contact data is available on the device
- **THEN** the system offers a fill suggestion for the field

#### Scenario: Free-form fields are not misclassified

- **WHEN** the user focuses a free-form name field such as a lookup item or campaign name
- **THEN** the system does not offer unrelated suggestions such as addresses


<!-- @trace
source: touch-target-and-input
updated: 2026-07-23
code:
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLTone.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneInformativeSurfaceText.colorset/Contents.json
  - apps/ios/BuyLedger/Features/Orders/Components/OptionPickerSheet.swift
  - apps/ios/BuyLedger/Features/AISummary/AISummaryFeature.swift
  - apps/ios/BuyLedger/Features/FX/FxFeature.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneSuccessOnIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Avatar/BLAvatar.swift
  - apps/ios/BuyLedger/Features/Orders/Components/MergePhotoPickerSheet.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Buttons/BLButtonStyle.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLDonutSegment.swift
  - apps/ios/BuyLedger/Features/FX/FxView.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests.swift
  - apps/ios/BuyLedgerTests/ColorContrastTests.swift
  - apps/ios/README.md
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneWarningOnIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/SegmentedControls/BLSegmentedControl.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLPalette.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneWarningSurfaceText.colorset/Contents.json
  - apps/ios/BuyLedgerTests/OrdersLoadStateTests.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLRankBadgeFirstBackground.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneWarningIndicator.colorset/Contents.json
  - apps/ios/BuyLedgerTests/SettingsFeatureTests.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignDetailView.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneDestructiveOnIndicator.colorset/Contents.json
  - apps/ios/BuyLedger.xcodeproj/project.pbxproj
  - apps/ios/BuyLedger.xcodeproj/xcshareddata/xcschemes/BuyLedger.xcscheme
  - apps/ios/BuyLedger/Features/Customers/CustomersView.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLSparkline.swift
  - apps/ios/BuyLedger/Features/Quote/QuoteFeature.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneAccentSurfaceText.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel4Numeral.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneAccentOnIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Features/Lookups/LookupNameEditorSheet.swift
  - apps/ios/BuyLedger/Features/App/RootView.swift
  - apps/ios/BuyLedger/Features/Orders/Components/PaymentMethodEditorSheet.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneSuccessSurfaceText.colorset/Contents.json
  - apps/ios/BuyLedger/Features/Insights/InsightsView.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/States/DelayedProgressView.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneDestructiveSurfaceText.colorset/Contents.json
  - apps/ios/BuyLedgerTests/LookupManagementFeatureTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/insightsViewBaseline.1.png
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Status/BLStatusPill.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLMetrics.swift
  - apps/ios/BuyLedgerTests/CampaignReminderFailureTests.swift
  - apps/ios/BuyLedgerTests/SnapshotTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewBaseline.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewMergeContextBaseline.1.png
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoThumbnail.swift
  - apps/ios/CLAUDE.md
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneInformativeOnIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Features/Quote/QuoteView.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderDetailView.swift
  - apps/ios/BuyLedger/Resources/Localizable.xcstrings
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLHeatmapDepth.swift
  - apps/ios/BuyLedgerTests/OrderEditFeatureTests.swift
  - apps/ios/BuyLedger/Features/App/RootSidebarLayout.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsView.swift
  - apps/ios/BuyLedger/Features/Orders/OrderEditView.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementView.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeroGradientStart.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLBarChartValue.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneNeutralIndicator.colorset/Contents.json
  - apps/ios/BuyLedger.xcodeproj/xcshareddata/xcschemes/BuyLedgerUITests.xcscheme
  - apps/ios/BuyLedger/Features/Campaigns/CampaignListView.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift
  - apps/ios/BuyLedgerTests/CampaignFeatureTests.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel3Numeral.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Cards/BLCard.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneInformativeIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Features/Orders/OrdersFeature.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersView.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneAccentIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Features/Settings/SettingsSnapshot.swift
  - apps/ios/BuyLedgerUITests/KeyboardDismissTests.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneSuccessSoftBackground.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneWarningSoftBackground.colorset/Contents.json
  - apps/ios/BuyLedger/Features/Insights/InsightsStats.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignEditView.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneDestructiveSoftBackground.colorset/Contents.json
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/dashboardViewBaseline.1.png
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLDonutChart.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderStatus+Presentation.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel1Background.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/TextFields/BLAmountField.swift
  - apps/ios/BuyLedgerTests/OrderEditFocusTests.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderRowView.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneNeutralSurfaceText.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneDestructiveIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Features/Orders/OrdersCompactView.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoViewer.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneAccentSoftBackground.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Lists/BLListRow.swift
  - apps/ios/BuyLedgerTests/OrdersSearchCancellationTests.swift
  - apps/ios/BuyLedgerTests/AISummaryFeatureTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewLongContentBaseline.1.png
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementDestination.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Chips/BLFilterChip.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsStorage.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel3Background.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneSuccessIndicator.colorset/Contents.json
  - apps/ios/BuyLedgerTests/ContrastComplianceTests.swift
  - apps/ios/BuyLedger/Shared/Extensions/Bundle+Extensions.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLBarChart.swift
  - apps/ios/BuyLedger/Features/Customers/CustomerRankBadgeStyle.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignEditFeature.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneNeutralOnIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/TextFields/BLSearchField.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneInformativeSoftBackground.colorset/Contents.json
  - apps/ios/BuyLedgerTests/ColorContrast.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/ViewModifiers/BLTypographyModifier.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel4Background.colorset/Contents.json
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/blBarChartThirtyDaysBaseline.1.png
  - apps/ios/BuyLedgerUITests/PhotoViewerPagingTests.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel5Numeral.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel1Numeral.colorset/Contents.json
  - apps/ios/BuyLedger/Features/Orders/OrderEditFeature.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardView.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignFeature.swift
  - apps/ios/BuyLedger/Features/App/RootFeature.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFilterSheet.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewBaseline.1.png
  - apps/ios/BuyLedger/Core/Dependencies/OpenSettingsClient.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Progress/BLProgressBar.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/States/BLLoadFailureView.swift
  - apps/ios/BuyLedger/Features/Settings/AppearancePreference.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel2Numeral.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel5Background.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/Keyboard/KeyboardDismissOnTap.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Badges/BLBadge.swift
  - apps/ios/BuyLedger/Features/More/MoreView.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsFeature.swift
  - apps/ios/BuyLedgerTests/InsightsStatsTests.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeroGradientEnd.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel2Background.colorset/Contents.json
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderDetailCostBreakdownBaseline.1.png
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneNeutralSoftBackground.colorset/Contents.json
-->

---
### Requirement: Numeric keyboards provide a dismissal path

A form presenting a numeric keyboard SHALL provide a visible way to dismiss it, because numeric keyboards have no return key. The form SHALL provide a keyboard toolbar carrying a done action, and SHALL additionally dismiss the keyboard on scroll. Dismissal SHALL NOT depend solely on tapping empty space.

#### Scenario: Done button dismisses the keyboard

- **WHEN** a numeric keyboard is presented and the user activates the done action in the keyboard toolbar
- **THEN** the keyboard dismisses and the entered value is retained

#### Scenario: Scrolling dismisses the keyboard

- **WHEN** a numeric keyboard is presented and the user scrolls the form
- **THEN** the keyboard dismisses

#### Scenario: Toolbar appears only for numeric input

- **WHEN** the user focuses a field that presents a standard keyboard with a return key
- **THEN** no redundant done toolbar is shown


<!-- @trace
source: touch-target-and-input
updated: 2026-07-23
code:
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLTone.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneInformativeSurfaceText.colorset/Contents.json
  - apps/ios/BuyLedger/Features/Orders/Components/OptionPickerSheet.swift
  - apps/ios/BuyLedger/Features/AISummary/AISummaryFeature.swift
  - apps/ios/BuyLedger/Features/FX/FxFeature.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneSuccessOnIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Avatar/BLAvatar.swift
  - apps/ios/BuyLedger/Features/Orders/Components/MergePhotoPickerSheet.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Buttons/BLButtonStyle.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLDonutSegment.swift
  - apps/ios/BuyLedger/Features/FX/FxView.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests.swift
  - apps/ios/BuyLedgerTests/ColorContrastTests.swift
  - apps/ios/README.md
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneWarningOnIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/SegmentedControls/BLSegmentedControl.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLPalette.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneWarningSurfaceText.colorset/Contents.json
  - apps/ios/BuyLedgerTests/OrdersLoadStateTests.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLRankBadgeFirstBackground.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneWarningIndicator.colorset/Contents.json
  - apps/ios/BuyLedgerTests/SettingsFeatureTests.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignDetailView.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneDestructiveOnIndicator.colorset/Contents.json
  - apps/ios/BuyLedger.xcodeproj/project.pbxproj
  - apps/ios/BuyLedger.xcodeproj/xcshareddata/xcschemes/BuyLedger.xcscheme
  - apps/ios/BuyLedger/Features/Customers/CustomersView.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLSparkline.swift
  - apps/ios/BuyLedger/Features/Quote/QuoteFeature.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneAccentSurfaceText.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel4Numeral.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneAccentOnIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Features/Lookups/LookupNameEditorSheet.swift
  - apps/ios/BuyLedger/Features/App/RootView.swift
  - apps/ios/BuyLedger/Features/Orders/Components/PaymentMethodEditorSheet.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneSuccessSurfaceText.colorset/Contents.json
  - apps/ios/BuyLedger/Features/Insights/InsightsView.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/States/DelayedProgressView.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneDestructiveSurfaceText.colorset/Contents.json
  - apps/ios/BuyLedgerTests/LookupManagementFeatureTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/insightsViewBaseline.1.png
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Status/BLStatusPill.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLMetrics.swift
  - apps/ios/BuyLedgerTests/CampaignReminderFailureTests.swift
  - apps/ios/BuyLedgerTests/SnapshotTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewBaseline.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewMergeContextBaseline.1.png
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoThumbnail.swift
  - apps/ios/CLAUDE.md
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneInformativeOnIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Features/Quote/QuoteView.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderDetailView.swift
  - apps/ios/BuyLedger/Resources/Localizable.xcstrings
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLHeatmapDepth.swift
  - apps/ios/BuyLedgerTests/OrderEditFeatureTests.swift
  - apps/ios/BuyLedger/Features/App/RootSidebarLayout.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsView.swift
  - apps/ios/BuyLedger/Features/Orders/OrderEditView.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementView.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeroGradientStart.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLBarChartValue.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneNeutralIndicator.colorset/Contents.json
  - apps/ios/BuyLedger.xcodeproj/xcshareddata/xcschemes/BuyLedgerUITests.xcscheme
  - apps/ios/BuyLedger/Features/Campaigns/CampaignListView.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift
  - apps/ios/BuyLedgerTests/CampaignFeatureTests.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel3Numeral.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Cards/BLCard.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneInformativeIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Features/Orders/OrdersFeature.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersView.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneAccentIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Features/Settings/SettingsSnapshot.swift
  - apps/ios/BuyLedgerUITests/KeyboardDismissTests.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneSuccessSoftBackground.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneWarningSoftBackground.colorset/Contents.json
  - apps/ios/BuyLedger/Features/Insights/InsightsStats.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignEditView.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneDestructiveSoftBackground.colorset/Contents.json
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/dashboardViewBaseline.1.png
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLDonutChart.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderStatus+Presentation.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel1Background.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/TextFields/BLAmountField.swift
  - apps/ios/BuyLedgerTests/OrderEditFocusTests.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderRowView.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneNeutralSurfaceText.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneDestructiveIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Features/Orders/OrdersCompactView.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoViewer.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneAccentSoftBackground.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Lists/BLListRow.swift
  - apps/ios/BuyLedgerTests/OrdersSearchCancellationTests.swift
  - apps/ios/BuyLedgerTests/AISummaryFeatureTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewLongContentBaseline.1.png
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementDestination.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Chips/BLFilterChip.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsStorage.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel3Background.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneSuccessIndicator.colorset/Contents.json
  - apps/ios/BuyLedgerTests/ContrastComplianceTests.swift
  - apps/ios/BuyLedger/Shared/Extensions/Bundle+Extensions.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLBarChart.swift
  - apps/ios/BuyLedger/Features/Customers/CustomerRankBadgeStyle.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignEditFeature.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneNeutralOnIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/TextFields/BLSearchField.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneInformativeSoftBackground.colorset/Contents.json
  - apps/ios/BuyLedgerTests/ColorContrast.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/ViewModifiers/BLTypographyModifier.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel4Background.colorset/Contents.json
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/blBarChartThirtyDaysBaseline.1.png
  - apps/ios/BuyLedgerUITests/PhotoViewerPagingTests.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel5Numeral.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel1Numeral.colorset/Contents.json
  - apps/ios/BuyLedger/Features/Orders/OrderEditFeature.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardView.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignFeature.swift
  - apps/ios/BuyLedger/Features/App/RootFeature.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFilterSheet.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewBaseline.1.png
  - apps/ios/BuyLedger/Core/Dependencies/OpenSettingsClient.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Progress/BLProgressBar.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/States/BLLoadFailureView.swift
  - apps/ios/BuyLedger/Features/Settings/AppearancePreference.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel2Numeral.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel5Background.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/Keyboard/KeyboardDismissOnTap.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Badges/BLBadge.swift
  - apps/ios/BuyLedger/Features/More/MoreView.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsFeature.swift
  - apps/ios/BuyLedgerTests/InsightsStatsTests.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeroGradientEnd.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel2Background.colorset/Contents.json
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderDetailCostBreakdownBaseline.1.png
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneNeutralSoftBackground.colorset/Contents.json
-->

---
### Requirement: Form value fields meet the minimum hit region

A value field inside a form row SHALL provide a hit region of at least 44 points in height, so that tapping anywhere within the row's vertical extent focuses the field. The row's own inset SHALL NOT be relied upon, because it belongs to the row rather than to the field.

#### Scenario: Tapping the row edge focuses the field

- **WHEN** the user taps near the top or bottom edge of a form row containing a numeric field
- **THEN** that field receives focus

##### Example: measured fields

| Field | Measured height before | Required |
| ----- | ---------------------- | -------- |
| Line item unit price | about 22 points | at least 44 points |
| Decimal value fields | about 22 points | at least 44 points |
| Percentage fields | about 22 points | at least 44 points |


<!-- @trace
source: touch-target-and-input
updated: 2026-07-23
code:
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLTone.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneInformativeSurfaceText.colorset/Contents.json
  - apps/ios/BuyLedger/Features/Orders/Components/OptionPickerSheet.swift
  - apps/ios/BuyLedger/Features/AISummary/AISummaryFeature.swift
  - apps/ios/BuyLedger/Features/FX/FxFeature.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneSuccessOnIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Avatar/BLAvatar.swift
  - apps/ios/BuyLedger/Features/Orders/Components/MergePhotoPickerSheet.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Buttons/BLButtonStyle.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLDonutSegment.swift
  - apps/ios/BuyLedger/Features/FX/FxView.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests.swift
  - apps/ios/BuyLedgerTests/ColorContrastTests.swift
  - apps/ios/README.md
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneWarningOnIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/SegmentedControls/BLSegmentedControl.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLPalette.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneWarningSurfaceText.colorset/Contents.json
  - apps/ios/BuyLedgerTests/OrdersLoadStateTests.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLRankBadgeFirstBackground.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneWarningIndicator.colorset/Contents.json
  - apps/ios/BuyLedgerTests/SettingsFeatureTests.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignDetailView.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneDestructiveOnIndicator.colorset/Contents.json
  - apps/ios/BuyLedger.xcodeproj/project.pbxproj
  - apps/ios/BuyLedger.xcodeproj/xcshareddata/xcschemes/BuyLedger.xcscheme
  - apps/ios/BuyLedger/Features/Customers/CustomersView.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLSparkline.swift
  - apps/ios/BuyLedger/Features/Quote/QuoteFeature.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneAccentSurfaceText.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel4Numeral.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneAccentOnIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Features/Lookups/LookupNameEditorSheet.swift
  - apps/ios/BuyLedger/Features/App/RootView.swift
  - apps/ios/BuyLedger/Features/Orders/Components/PaymentMethodEditorSheet.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneSuccessSurfaceText.colorset/Contents.json
  - apps/ios/BuyLedger/Features/Insights/InsightsView.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/States/DelayedProgressView.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneDestructiveSurfaceText.colorset/Contents.json
  - apps/ios/BuyLedgerTests/LookupManagementFeatureTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/insightsViewBaseline.1.png
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Status/BLStatusPill.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLMetrics.swift
  - apps/ios/BuyLedgerTests/CampaignReminderFailureTests.swift
  - apps/ios/BuyLedgerTests/SnapshotTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewBaseline.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewMergeContextBaseline.1.png
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoThumbnail.swift
  - apps/ios/CLAUDE.md
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneInformativeOnIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Features/Quote/QuoteView.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderDetailView.swift
  - apps/ios/BuyLedger/Resources/Localizable.xcstrings
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLHeatmapDepth.swift
  - apps/ios/BuyLedgerTests/OrderEditFeatureTests.swift
  - apps/ios/BuyLedger/Features/App/RootSidebarLayout.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsView.swift
  - apps/ios/BuyLedger/Features/Orders/OrderEditView.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementView.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeroGradientStart.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLBarChartValue.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneNeutralIndicator.colorset/Contents.json
  - apps/ios/BuyLedger.xcodeproj/xcshareddata/xcschemes/BuyLedgerUITests.xcscheme
  - apps/ios/BuyLedger/Features/Campaigns/CampaignListView.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift
  - apps/ios/BuyLedgerTests/CampaignFeatureTests.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel3Numeral.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Cards/BLCard.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneInformativeIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Features/Orders/OrdersFeature.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersView.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneAccentIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Features/Settings/SettingsSnapshot.swift
  - apps/ios/BuyLedgerUITests/KeyboardDismissTests.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneSuccessSoftBackground.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneWarningSoftBackground.colorset/Contents.json
  - apps/ios/BuyLedger/Features/Insights/InsightsStats.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignEditView.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneDestructiveSoftBackground.colorset/Contents.json
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/dashboardViewBaseline.1.png
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLDonutChart.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderStatus+Presentation.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel1Background.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/TextFields/BLAmountField.swift
  - apps/ios/BuyLedgerTests/OrderEditFocusTests.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderRowView.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneNeutralSurfaceText.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneDestructiveIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Features/Orders/OrdersCompactView.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoViewer.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneAccentSoftBackground.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Lists/BLListRow.swift
  - apps/ios/BuyLedgerTests/OrdersSearchCancellationTests.swift
  - apps/ios/BuyLedgerTests/AISummaryFeatureTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewLongContentBaseline.1.png
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementDestination.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Chips/BLFilterChip.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsStorage.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel3Background.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneSuccessIndicator.colorset/Contents.json
  - apps/ios/BuyLedgerTests/ContrastComplianceTests.swift
  - apps/ios/BuyLedger/Shared/Extensions/Bundle+Extensions.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLBarChart.swift
  - apps/ios/BuyLedger/Features/Customers/CustomerRankBadgeStyle.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignEditFeature.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneNeutralOnIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/TextFields/BLSearchField.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneInformativeSoftBackground.colorset/Contents.json
  - apps/ios/BuyLedgerTests/ColorContrast.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/ViewModifiers/BLTypographyModifier.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel4Background.colorset/Contents.json
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/blBarChartThirtyDaysBaseline.1.png
  - apps/ios/BuyLedgerUITests/PhotoViewerPagingTests.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel5Numeral.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel1Numeral.colorset/Contents.json
  - apps/ios/BuyLedger/Features/Orders/OrderEditFeature.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardView.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignFeature.swift
  - apps/ios/BuyLedger/Features/App/RootFeature.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFilterSheet.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewBaseline.1.png
  - apps/ios/BuyLedger/Core/Dependencies/OpenSettingsClient.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Progress/BLProgressBar.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/States/BLLoadFailureView.swift
  - apps/ios/BuyLedger/Features/Settings/AppearancePreference.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel2Numeral.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel5Background.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/Keyboard/KeyboardDismissOnTap.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Badges/BLBadge.swift
  - apps/ios/BuyLedger/Features/More/MoreView.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsFeature.swift
  - apps/ios/BuyLedgerTests/InsightsStatsTests.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeroGradientEnd.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel2Background.colorset/Contents.json
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderDetailCostBreakdownBaseline.1.png
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneNeutralSoftBackground.colorset/Contents.json
-->

---
### Requirement: Long forms manage focus order

A form with many input fields SHALL manage focus so that fields can be traversed in visual order, and the focus state SHALL live in the feature state rather than in view-local state, consistent with the project convention that store-bound views hold no presentation state. Opening a blank order SHALL focus the first field. Focus SHALL be cleared when the form is dismissed so that reopening it does not restore a stale focus.

#### Scenario: New order focuses the first field

- **WHEN** the user opens the order edit form for a new order
- **THEN** the first input field receives focus

#### Scenario: Focus does not persist across presentations

- **WHEN** the user dismisses the order edit form while a field is focused, then opens the form again
- **THEN** focus is not restored to the previously focused field

#### Scenario: Focus follows visual order

- **WHEN** the user advances focus from a field using an external keyboard
- **THEN** focus moves to the next field in visual order

<!-- @trace
source: touch-target-and-input
updated: 2026-07-23
code:
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLTone.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneInformativeSurfaceText.colorset/Contents.json
  - apps/ios/BuyLedger/Features/Orders/Components/OptionPickerSheet.swift
  - apps/ios/BuyLedger/Features/AISummary/AISummaryFeature.swift
  - apps/ios/BuyLedger/Features/FX/FxFeature.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneSuccessOnIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Avatar/BLAvatar.swift
  - apps/ios/BuyLedger/Features/Orders/Components/MergePhotoPickerSheet.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Buttons/BLButtonStyle.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLDonutSegment.swift
  - apps/ios/BuyLedger/Features/FX/FxView.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests.swift
  - apps/ios/BuyLedgerTests/ColorContrastTests.swift
  - apps/ios/README.md
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneWarningOnIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/SegmentedControls/BLSegmentedControl.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLPalette.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneWarningSurfaceText.colorset/Contents.json
  - apps/ios/BuyLedgerTests/OrdersLoadStateTests.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLRankBadgeFirstBackground.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneWarningIndicator.colorset/Contents.json
  - apps/ios/BuyLedgerTests/SettingsFeatureTests.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignDetailView.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneDestructiveOnIndicator.colorset/Contents.json
  - apps/ios/BuyLedger.xcodeproj/project.pbxproj
  - apps/ios/BuyLedger.xcodeproj/xcshareddata/xcschemes/BuyLedger.xcscheme
  - apps/ios/BuyLedger/Features/Customers/CustomersView.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLSparkline.swift
  - apps/ios/BuyLedger/Features/Quote/QuoteFeature.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneAccentSurfaceText.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel4Numeral.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneAccentOnIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Features/Lookups/LookupNameEditorSheet.swift
  - apps/ios/BuyLedger/Features/App/RootView.swift
  - apps/ios/BuyLedger/Features/Orders/Components/PaymentMethodEditorSheet.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneSuccessSurfaceText.colorset/Contents.json
  - apps/ios/BuyLedger/Features/Insights/InsightsView.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/States/DelayedProgressView.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneDestructiveSurfaceText.colorset/Contents.json
  - apps/ios/BuyLedgerTests/LookupManagementFeatureTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/insightsViewBaseline.1.png
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Status/BLStatusPill.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLMetrics.swift
  - apps/ios/BuyLedgerTests/CampaignReminderFailureTests.swift
  - apps/ios/BuyLedgerTests/SnapshotTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewBaseline.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewMergeContextBaseline.1.png
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoThumbnail.swift
  - apps/ios/CLAUDE.md
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneInformativeOnIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Features/Quote/QuoteView.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderDetailView.swift
  - apps/ios/BuyLedger/Resources/Localizable.xcstrings
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLHeatmapDepth.swift
  - apps/ios/BuyLedgerTests/OrderEditFeatureTests.swift
  - apps/ios/BuyLedger/Features/App/RootSidebarLayout.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsView.swift
  - apps/ios/BuyLedger/Features/Orders/OrderEditView.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementView.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeroGradientStart.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLBarChartValue.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneNeutralIndicator.colorset/Contents.json
  - apps/ios/BuyLedger.xcodeproj/xcshareddata/xcschemes/BuyLedgerUITests.xcscheme
  - apps/ios/BuyLedger/Features/Campaigns/CampaignListView.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift
  - apps/ios/BuyLedgerTests/CampaignFeatureTests.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel3Numeral.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Cards/BLCard.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneInformativeIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Features/Orders/OrdersFeature.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersView.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneAccentIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Features/Settings/SettingsSnapshot.swift
  - apps/ios/BuyLedgerUITests/KeyboardDismissTests.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneSuccessSoftBackground.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneWarningSoftBackground.colorset/Contents.json
  - apps/ios/BuyLedger/Features/Insights/InsightsStats.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignEditView.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneDestructiveSoftBackground.colorset/Contents.json
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/dashboardViewBaseline.1.png
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLDonutChart.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderStatus+Presentation.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel1Background.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/TextFields/BLAmountField.swift
  - apps/ios/BuyLedgerTests/OrderEditFocusTests.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderRowView.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneNeutralSurfaceText.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneDestructiveIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Features/Orders/OrdersCompactView.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoViewer.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneAccentSoftBackground.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Lists/BLListRow.swift
  - apps/ios/BuyLedgerTests/OrdersSearchCancellationTests.swift
  - apps/ios/BuyLedgerTests/AISummaryFeatureTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewLongContentBaseline.1.png
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementDestination.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Chips/BLFilterChip.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsStorage.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel3Background.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneSuccessIndicator.colorset/Contents.json
  - apps/ios/BuyLedgerTests/ContrastComplianceTests.swift
  - apps/ios/BuyLedger/Shared/Extensions/Bundle+Extensions.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLBarChart.swift
  - apps/ios/BuyLedger/Features/Customers/CustomerRankBadgeStyle.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignEditFeature.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneNeutralOnIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/TextFields/BLSearchField.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneInformativeSoftBackground.colorset/Contents.json
  - apps/ios/BuyLedgerTests/ColorContrast.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/ViewModifiers/BLTypographyModifier.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel4Background.colorset/Contents.json
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/blBarChartThirtyDaysBaseline.1.png
  - apps/ios/BuyLedgerUITests/PhotoViewerPagingTests.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel5Numeral.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel1Numeral.colorset/Contents.json
  - apps/ios/BuyLedger/Features/Orders/OrderEditFeature.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardView.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignFeature.swift
  - apps/ios/BuyLedger/Features/App/RootFeature.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFilterSheet.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewBaseline.1.png
  - apps/ios/BuyLedger/Core/Dependencies/OpenSettingsClient.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Progress/BLProgressBar.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/States/BLLoadFailureView.swift
  - apps/ios/BuyLedger/Features/Settings/AppearancePreference.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel2Numeral.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel5Background.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/Keyboard/KeyboardDismissOnTap.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Badges/BLBadge.swift
  - apps/ios/BuyLedger/Features/More/MoreView.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsFeature.swift
  - apps/ios/BuyLedgerTests/InsightsStatsTests.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeroGradientEnd.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel2Background.colorset/Contents.json
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderDetailCostBreakdownBaseline.1.png
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneNeutralSoftBackground.colorset/Contents.json
-->

---
### Requirement: Text fields place the caret at the end when focus arrives

A free-text entry field (single-line, multi-line, or search) SHALL place the caret after the last character of its existing text at the moment it gains focus, regardless of where the user tapped. The field SHALL NOT select or clear its existing text when focus arrives. The caret SHALL be placed only on the transition from unfocused to focused; while the field stays focused, later taps SHALL be left to the system. An empty field SHALL behave as the system default. Managing the caret SHALL NOT interrupt keyboard text composition.

#### Scenario: Typing appends to an existing name

- **GIVEN** an order edit form whose customer name field shows 林書宇
- **WHEN** the user taps the left part of the customer name field and types 小姐
- **THEN** the field shows 林書宇小姐

#### Scenario: A later tap leaves caret placement to the system

- **GIVEN** a focused customer name field showing 林書宇 whose caret was placed at the end when focus arrived
- **WHEN** the user taps the left part of the same field and types 小
- **THEN** the field text contains 林書宇 and the typed 小 is not placed after the last character

#### Scenario: Multi-line notes continue at the end

- **GIVEN** an order notes field containing two lines of text
- **WHEN** the user taps the first line and types additional text
- **THEN** the additional text appears after the last character of the second line

#### Scenario: Search query continues at the end

- **GIVEN** a category search field containing 保養
- **WHEN** the user taps the left part of the search field and types 品
- **THEN** the search field shows 保養品

#### Scenario: List search query continues at the end

- **GIVEN** an order list search field containing 林 whose keyboard has been dismissed
- **WHEN** the user taps the left part of the search field and types 書
- **THEN** the search field shows 林書

#### Scenario: Phonetic composition is not interrupted

- **GIVEN** a focused customer name field showing 林書宇 with a Zhuyin keyboard
- **WHEN** the user composes a syllable with the keyboard keys and picks the candidate 小
- **THEN** the field shows 林書宇小


<!-- @trace
source: input-focus-selection
updated: 2026-11-07
code:
  - apps/ios/BuyLedgerTests/Features/App/RootFeatureTabSelectionTests.swift
  - apps/ios/BuyLedgerUITests/Support/XCUIElement+Waiting.swift
  - apps/ios/BuyLedgerTests/Guards/DesignSystemSourceScan/DesignSystemSourceScanner.swift
  - apps/ios/BuyLedgerUITests/Tests/Customers/CustomersTests.swift
  - apps/ios/BuyLedger/Features/More/Presentation/Root/MoreFeature.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrderListFeatureClearFiltersTests.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotDashboardTests/dashboardView_寬版_並排顯示hero與KPI.1.png
  - apps/ios/BuyLedger/Features/Orders/Presentation/OrderEdit/Operations/OrderEditDraftOperations.swift
  - apps/ios/BuyLedgerUITests/Support/KPIPresenceCheck.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/OrderEdit/OrderEditFeature.swift
  - apps/ios/BuyLedger/Features/Campaigns/Presentation/CampaignList/Views/CampaignSectionList.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersFeatureStatusFailuresTests.swift
  - apps/ios/BuyLedger/Features/Campaigns/Presentation/CampaignDetail/CampaignDetailView.swift
  - apps/ios/BuyLedgerUITests/Support/XCUIApplication+MenuInteraction.swift
  - apps/ios/BuyLedgerTests/Features/Lookups/LookupAddFormFeatureTests.swift
  - apps/ios/BuyLedgerUITests/Screens/App/RootNavigationScreen.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/SnapshotInsightsTests.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersFilterOperationsTests.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/OrderEdit/Views/Sections/OrderEditNotesSection.swift
  - apps/ios/BuyLedger/Features/Quote/Presentation/Root/QuoteFeature.swift
  - apps/ios/BuyLedger/Features/Campaigns/Presentation/Root/CampaignFeature+Path.swift
  - apps/ios/BuyLedgerTests/Features/App/RootFeaturePaymentMethodCorrectionTests.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrderListFeatureDatesTests.swift
  - apps/ios/BuyLedger/Features/Lookups/Presentation/Root/Views/LookupManagementView.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotOrderDetailTests/orderDetailView_393點寬最大輔助字級_標頭與卡片留在畫面內.1.png
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotOrdersTests/ordersView_大尺寸iPhone橫向_顯示單欄清單與整合篩選鈕.1.png
  - apps/ios/BuyLedger/Features/Campaigns/Presentation/Root/CampaignFeature.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/OrderDetail/Views/OrderDetailContentView.swift
  - apps/ios/BuyLedgerTests/Features/Campaigns/CampaignFeatureFailureTimingFollowUpTests.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersFeatureListEntryTests.swift
  - apps/ios/BuyLedgerTests/Support/RootFeatureTestSupport.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotOrderDetailTests/orderDetailSections_頁面內容寬361最大輔助字級_大額金額完整不裁切.1.png
  - apps/ios/BuyLedgerTests/SnapshotTests/SnapshotOrderEditSectionsTests.swift
  - apps/ios/BuyLedgerUITests/Support/Assertions/Diagnostics.swift
  - apps/ios/BuyLedgerTests/Features/App/RootFeatureOrderFiltersTests.swift
  - apps/ios/BuyLedgerUITests/Support/CheckOutcome.swift
  - apps/ios/BuyLedgerAccessibilityIDs/BLAccessibilityID+Insights.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Forms/BLNumberField.swift
  - apps/ios/BuyLedgerTests/Features/App/RootFeatureLoadRequestsTests.swift
  - apps/ios/BuyLedgerUITests/Support/Interactions/MenuInteraction.swift
  - apps/ios/BuyLedger/Features/Lookups/Presentation/LookupRenameForm/LookupRenameFormFeature.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotOrdersTests/ordersCompactView_多選模式_顯示勾選與工具列.1.png
  - apps/ios/BuyLedgerTests/Features/Orders/OrderEditFeatureDisplayTextTests.swift
  - apps/ios/BuyLedger/Features/Dashboard/Presentation/Root/Views/DashboardSummarySection.swift
  - apps/ios/BuyLedger/Features/Insights/Presentation/Root/Views/InsightsCategoryCard.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotOrdersTests/ordersCompactView_長內容訂單清單_避免撐寬版面.1.png
  - apps/ios/BuyLedgerTests/Support/ViewLayoutMeasurementSupport.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersFeatureDeleteEditFailuresTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Cards/BLCardRowBackground.swift
  - apps/ios/BuyLedgerTests/Features/Campaigns/CampaignFeatureDeletionReminderTests.swift
  - apps/ios/BuyLedgerTests/Features/App/RootFeatureSharedOrdersTests.swift
  - apps/ios/BuyLedgerTests/Guards/ProjectionWriteBoundary/ProjectionWriteBoundaryGuardsTests.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrderListFeatureFilterSheetTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLDonutChart.swift
  - apps/ios/BuyLedgerUITests/Support/XCUIElement+ValueParsing.swift
  - apps/ios/BuyLedgerUITests/Tests/Forms/QuoteInputFocusUITests.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotDashboardTests/dashboardView_最大輔助字級_目標進度堆疊排列.1.png
  - apps/ios/BuyLedger/Features/Campaigns/Presentation/CampaignPresentation/CampaignPresentationQueue.swift
  - apps/ios/BuyLedgerTests/Guards/DesignSystemSourceScan/DesignSystemSourceScanTests.swift
  - apps/ios/BuyLedgerUITests/Support/Interactions/AlertInteraction.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersContainerPlanRequestsTests.swift
  - apps/ios/BuyLedger/Features/Campaigns/Presentation/Root/CampaignRequest.swift
  - apps/ios/BuyLedgerUITests/Support/PathCheck.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLReadableContentType.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/Root/Plans/OrdersWriteOutcome.swift
  - apps/ios/BuyLedgerUITests/Support/Launch/LaunchOptions.swift
  - apps/ios/BuyLedger/Features/App/Presentation/Root/RootView.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrderListFeatureTests.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/SnapshotOrderDetailTests.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotOrderDetailTests/orderDetailCostView_393點寬最大輔助字級_成本卡圓餅圖與中心文字在卡片內.1.png
  - apps/ios/BuyLedgerUITests/Support/XCTestCase+CampaignFlow.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersDetailNavigationFeatureTests.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/OrderEdit/Views/Sections/OrderEditItemsSection.swift
  - apps/ios/BuyLedgerAccessibilityIDs/BLAccessibilityID+Campaigns.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrderListFeatureClearFilterPresentationTests.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersFeatureEditFieldsTests.swift
  - apps/ios/BuyLedger/Features/Lookups/Presentation/Root/Views/LookupManagementPresentations.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/OrderList/Operations/OrderListDestinationOperations.swift
  - apps/ios/BuyLedger/Features/Campaigns/Presentation/CampaignEdit/CampaignEditView.swift
  - apps/ios/BuyLedgerUITests/Support/IdentifierCheck.swift
  - apps/ios/BuyLedgerTests/Shared/DesignSystem/BLBarChartLayoutTests.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrderEditFeatureDeductionTests.swift
  - apps/ios/BuyLedger/Resources/Localizable.xcstrings
  - apps/ios/BuyLedgerUITests/Tests/Navigation/ReadableWidthUITests.swift
  - apps/ios/BuyLedgerUITests/Support/Layout/HorizontalBounds.swift
  - apps/ios/BuyLedgerUITests/Support/ValueParsing.swift
  - apps/ios/BuyLedgerTests/Shared/DesignSystem/BLNumberFieldDraftTests.swift
  - apps/ios/BuyLedgerUITests/Support/Interactions/Scrolling.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersFilterOperationsSearchAndSelectionTests.swift
  - apps/ios/BuyLedger/Features/Campaigns/Presentation/Root/CampaignRequestPlan.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/Root/Views/OrdersCompactView.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotCampaignsTests/campaignListView_依日分組含今天與昨天_符合基準圖.1.png
  - apps/ios/BuyLedgerUITests/Screens/Tools/QuoteScreen.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/OrderEdit/Views/OrderEditPercentField.swift
  - apps/ios/BuyLedgerUITests/Tests/Navigation/AdaptiveNavigationContinuityUITests.swift
  - apps/ios/BuyLedger/Features/Insights/Presentation/Root/Views/InsightsHeatmapCard.swift
  - apps/ios/BuyLedger/Features/Campaigns/Presentation/CampaignList/Views/CampaignRow.swift
  - apps/ios/BuyLedger/Features/Dashboard/Presentation/Root/Views/DashboardKPITiles.swift
  - apps/ios/BuyLedgerTests/AccessibilityIDs/BLAccessibilityIDTests.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersFeatureListRequestsTests.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersFilterOperationsSearchTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Forms/PaymentMethodEditorSheet.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/Regular/OrderRegularClearFiltersTests.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/OrderEdit/Views/OrderEditView.swift
  - apps/ios/BuyLedgerUITests/Support/XCTestCase+HorizontalBounds.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/Root/Views/OrdersView.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotCampaignsTests/campaignListView_選取其中一筆開團_符合基準圖.1.png
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotDashboardTests/dashboardView_寬版_摘要在上四項KPI兩欄.1.png
  - apps/ios/BuyLedgerTests/SnapshotTests/SnapshotOrderFilterEmptyStatesTests.swift
  - apps/ios/BuyLedgerUITests/Support/Interactions/TextInput.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/OrderEdit/Views/Sections/OrderEditFeesSection.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotCampaignsTests/campaignListView_依日分組同日三筆與他日一筆_符合基準圖.1.png
  - apps/ios/BuyLedgerAccessibilityIDs/BLAccessibilityID+Orders.swift
  - apps/ios/BuyLedgerAccessibilityIDs/BLAccessibilityID+More.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrdersListTests.swift
  - apps/ios/BuyLedgerUITests/Support/XCUIApplication+AlertInteraction.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrderSaveGuardTests.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotOrdersTests/ordersCompactView_同日三筆與他日一筆_符合基準圖.1.png
  - apps/ios/BuyLedgerUITests/Screens/Orders/OrderEditScreen.swift
  - apps/ios/BuyLedgerUITests/Support/Layout/Orientation.swift
  - apps/ios/BuyLedgerUITests/Tests/Campaigns/CampaignFlowTests.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/OrderList/OrderListFeature.swift
  - apps/ios/BuyLedgerTests/Features/More/MoreFeatureRelaysTests.swift
  - apps/ios/BuyLedgerTests/Features/Campaigns/CampaignFeatureFailureTimingTests.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrderFilterFeatureClearTests.swift
  - apps/ios/BuyLedgerTests/Guards/ToolReadableWidthGuardTests.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/Root/Requests/OrderRequest.swift
  - apps/ios/BuyLedgerTests/Support/CampaignFeatureTestSupport.swift
  - apps/ios/BuyLedgerTests/Support/View+LayoutMeasurement.swift
  - apps/ios/BuyLedger/Features/Quote/Presentation/Root/QuoteInputsCard.swift
  - apps/ios/BuyLedger/Features/Lookups/Presentation/Root/LookupManagementFeature+Destination.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotInsightsTests/insightsView_大尺寸iPhone橫向_類別排行與成本結構上下堆疊.1.png
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotInsightsTests/insightsCategoryCard_393點寬最大輔助字級_金額不斷字.1.png
  - apps/ios/BuyLedgerTests/Features/More/MoreFeatureEntrySelectionTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Insights/InsightsLayoutSmokeTests.swift
  - apps/ios/BuyLedgerTests/Shared/DesignSystem/BLLayoutClassTests.swift
  - apps/ios/BuyLedgerUITests/Screens/Orders/OrdersScreen.swift
  - apps/ios/BuyLedger/Features/Campaigns/Presentation/CampaignList/CampaignListFeature.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/Root/Plans/OrdersContainerPlan.swift
  - apps/ios/BuyLedgerTests/Guards/BottomBarPlacementScanTests.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersFeatureMergeWritesTests.swift
  - apps/ios/BuyLedger/Features/Campaigns/Presentation/CampaignPresentation/CampaignPresentationFeature.swift
  - apps/ios/BuyLedger/Features/Lookups/Presentation/LookupAddForm/LookupAddFormFeature.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersViewLayoutTests.swift
  - apps/ios/BuyLedgerUITests/Screens/More/LookupManagementScreen.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotOrderDetailTests/orderDetailSections_頁面內容寬361最大輔助字級_成本圖例與商品金額不斷字.1.png
  - apps/ios/BuyLedgerUITests/Support/Assertions/Assertions.swift
  - apps/ios/BuyLedgerUITests/Tests/Navigation/NavigationScenarioUITests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLLayoutClass.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLBarChart.swift
  - apps/ios/BuyLedgerTests/Guards/LayerBoundary/LanguageProjectionBoundaryTests.swift
  - apps/ios/BuyLedgerTests/Shared/DesignSystem/BLReadableScrollContentLayoutTests.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotCampaignsTests/campaignListView_依月分組_符合基準圖.1.png
  - apps/ios/BuyLedgerTests/Features/App/RootFeatureLookupSyncTests.swift
  - apps/ios/BuyLedgerUITests/Support/LaunchOptions.swift
  - apps/ios/BuyLedgerUITests/Tests/Smoke/LaunchSmokeTests.swift
  - apps/ios/BuyLedgerUITests/Screens/Campaigns/CampaignsScreen.swift
  - apps/ios/BuyLedgerUITests/Tests/Navigation/AdaptiveLayoutCheckCounterexampleTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/Filters/OrderPaymentMethodMenuTests.swift
  - apps/ios/README.md
  - apps/ios/BuyLedgerTests/Features/Lookups/PaymentMethodEditFormFeatureTests.swift
  - apps/ios/BuyLedger/Features/Lookups/Presentation/Root/LookupManagementFeature.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/OrderEdit/Models/OrderDraft.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/OrderMerge/OrderMergeFeature.swift
  - apps/ios/BuyLedgerTests/Features/Campaigns/CampaignFeatureNavigationTests.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersFilterOperationsClearFiltersTests.swift
  - apps/ios/BuyLedgerTests/Features/Lookups/LookupManagementFeatureFailuresTests.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotOrderFilterEmptyStatesTests/ordersRegularListContent_寬版清單欄無付款方式與類別_符合基準圖.1.png
  - apps/ios/BuyLedgerUITests/Tests/Dashboard/DashboardLayoutSmokeTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/Regular/OrderRegularColumnWidthTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLCardRowMetrics.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/Root/Views/OrdersRegularListContent.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotOrderFilterEmptyStatesTests/ordersView_寬版清單欄無付款方式與類別_符合基準圖.1.png
  - apps/ios/BuyLedgerUITests/Tests/Smoke/OrientationLayoutTests.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersFilterOperationsFilterSheetTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/ViewModifiers/BLSearchableModifier.swift
  - apps/ios/BuyLedger/Features/Campaigns/Presentation/Root/CampaignView.swift
  - apps/ios/BuyLedger/App/Testing/Configuration/BLUITestConfiguration.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersFeatureLoadAndSummaryTests.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersFeatureOptionWritesTests.swift
  - apps/ios/BuyLedger/Features/Dashboard/Presentation/Root/Views/DashboardHeroCard.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotOrderEditSectionsTests/orderEditItemsSection_最大輔助字級_商品列堆疊排列.1.png
  - apps/ios/BuyLedgerUITests/Support/XCTestCase+Diagnostics.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/OrderEdit/Views/Sections/OrderEditBasicSection.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Forms/BLTextField.swift
  - apps/ios/BuyLedgerTests/Features/App/RootFeatureSidebarTests.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/OrdersDetailNavigation/OrdersDetailSelection.swift
  - apps/ios/BuyLedgerUITests/Support/XCUIApplication+TextInput.swift
  - apps/ios/BuyLedgerTests/Guards/LayerBoundary/LanguageProjectionScanner.swift
  - apps/ios/BuyLedgerUITests/Support/XCUIApplication+NavigationBackInteraction.swift
  - apps/ios/BuyLedgerTests/Features/More/MoreFeatureTests.swift
  - apps/ios/BuyLedgerUITests/Support/XCUIApplication+Diagnostics.swift
  - apps/ios/CLAUDE.md
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotCampaignsTests/campaignListView_依年分組_符合基準圖.1.png
  - apps/ios/BuyLedgerUITests/Tests/Orders/Filters/OrderFilterSheetLargeTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/Filters/OrderFilterSheetTests.swift
  - apps/ios/BuyLedgerUITests/Screens/Campaigns/CampaignEditScreen.swift
  - apps/ios/BuyLedger.xcodeproj/project.xcproj
  - apps/ios/BuyLedger/Features/Quote/Presentation/Root/QuoteView.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersFeatureCreateTests.swift
  - apps/ios/BuyLedgerTests/Guards/OrderListSnapshotSourceScanTests.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/SnapshotDashboardTests.swift
  - apps/ios/BuyLedgerTests/Features/Lookups/LookupRenameFormFeatureTests.swift
  - apps/ios/BuyLedgerUITests/Support/XCTestCase+Orientation.swift
  - apps/ios/BuyLedgerUITests/Tests/Forms/OrderEditInputFocusUITests.swift
  - apps/ios/BuyLedgerTests/Features/Campaigns/CampaignPresentationQueueTests.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/Root/Plans/OrdersContainerPlan+Requests.swift
  - apps/ios/BuyLedger/Features/Lookups/Presentation/Root/Views/LookupNameEditorSheet.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotOrdersTests/ordersView_大尺寸iPhone橫向_分欄顯示清單與整合篩選鈕.1.png
  - apps/ios/BuyLedgerTests/Shared/DesignSystem/BLLayoutClassEnvironmentTests.swift
  - .github/workflows/ci.yml
  - apps/ios/BuyLedgerUITests/Support/Interactions/SheetInteraction.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersLoadStateTests.swift
  - apps/ios/BuyLedgerTests/Features/Campaigns/CampaignPresentationFeatureTests.swift
  - apps/ios/BuyLedger/Features/Customers/Presentation/Root/CustomersView.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotInsightsTests/insightsCostStructureCard_393點寬最大輔助字級_圓餅圖與中心文字留在卡片內.1.png
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotInsightsTests/insightsView_寬版_卡片依固定順序垂直排列.1.png
  - apps/ios/BuyLedger/Features/Orders/Presentation/OrdersDetailNavigation/OrdersDetailNavigationFeature.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotMoreTests/moreView_預設清單_顯示各入口.1.png
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotToolsTests/quoteView_最大輔助字級_輸入列堆疊排列.1.png
  - apps/ios/BuyLedger/Features/Orders/Presentation/Root/Plans/OrdersRequestOutcome.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrderListFeatureFiltersTests.swift
  - apps/ios/BuyLedger/Features/App/Presentation/Root/RootFeature.swift
  - apps/ios/BuyLedger/Features/FX/Presentation/Root/FxView.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersFeatureMergeSaveTests.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/OrderEdit/Views/Sections/OrderEditPaymentSection.swift
  - apps/ios/BuyLedgerUITests/Tests/Tools/FxTests.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersContainerPlanWritesTests.swift
  - apps/ios/BuyLedgerAccessibilityIDs/BLAccessibilityID+Common.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrderListFeatureFilterDelegatesTests.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/SnapshotOrdersBaselineTests.swift
  - apps/ios/BuyLedgerTests/Support/OrderListFeatureTestSupport.swift
  - apps/ios/BuyLedgerTests/Features/Lookups/LookupManagementFeatureTestSupport.swift
  - apps/ios/BuyLedger/Features/App/Presentation/Root/RootTabLayout.swift
  - apps/ios/BuyLedgerTests/Features/Campaigns/CampaignFeatureReloadTests.swift
  - apps/ios/BuyLedgerUITests/Screens/Insights/InsightsScreen.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/OrderMerge/OrderMergeCandidateSheet.swift
  - apps/ios/BuyLedgerTests/Features/Lookups/LookupManagementFeatureAlertTimingTests.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersFeatureEditDeductionTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Forms/SearchInputFocusUITests.swift
  - apps/ios/BuyLedgerUITests/Support/XCUIElement+TextInput.swift
  - CLAUDE.md
  - apps/ios/BuyLedgerTests/Features/Orders/OrderListFeatureCategoryPickerApplyTests.swift
  - apps/ios/BuyLedgerUITests/Support/BLUITestCase.swift
  - apps/ios/BuyLedgerUITests/Support/XCTestCase+OrdersLayoutAssertions.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotOrdersTests/ordersCompactView_一般訂單清單_符合基準圖.1.png
  - apps/ios/BuyLedgerTests/Features/Orders/OrderFilterFeatureCategoriesTests.swift
  - apps/ios/BuyLedgerTests/Features/Campaigns/CampaignFeatureWriteFailuresTests.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersSearchCancellationTests.swift
  - apps/ios/BuyLedger/Features/Campaigns/Presentation/CampaignPresentation/CampaignPresentationFeature+Destination.swift
  - apps/ios/BuyLedgerUITests/Support/XCUIApplication+SheetInteraction.swift
  - apps/ios/BuyLedger/Features/App/Presentation/Root/RootNavigationLayout.swift
  - apps/ios/BuyLedger/Features/Campaigns/Presentation/CampaignList/Views/CampaignListView.swift
  - apps/ios/BuyLedgerTests/Shared/DesignSystem/BLReadableContentLayoutTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrdersNavigationSmokeTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/ViewModifiers/BLReadableContentLayout.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Forms/BLNumberFieldDraft.swift
  - apps/ios/BuyLedgerUITests/Support/AppNavigator.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/ViewModifiers/BLReadableScrollContentLayout.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Cards/BLCardRowPosition.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/Regular/OrderRegularColumnScopeTests.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/OrderList/Views/OrdersCompactListView.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/Components/OrdersFilterControlsView.swift
  - apps/ios/BuyLedgerUITests/Tests/More/MoreNavigationSmokeTests.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/SnapshotCampaignsTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Pickers/BLSearchableModifier.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/Root/Views/OrdersRegularDetailColumn.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotCampaignsTests/campaignListView_英文月分組_符合基準圖.1.png
  - apps/ios/BuyLedgerTests/Guards/ActionGrouping/ActionGroupingScanner.swift
  - apps/ios/BuyLedgerUITests/Screens/Tools/FxScreen.swift
  - apps/ios/BuyLedgerUITests/Support/XCTestCase+Assertions.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersContainerPlanTests.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/OrderDetail/Views/OrderDetailCostView.swift
  - apps/ios/BuyLedgerUITests/Support/XCUIApplication+Scrolling.swift
  - apps/ios/BuyLedgerTests/Features/Campaigns/CampaignIntegrationTests.swift
  - apps/ios/BuyLedger/Features/Settings/Presentation/Root/SettingsView.swift
  - apps/ios/BuyLedgerTests/Features/Campaigns/CampaignFeaturePresentationTests.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotInsightsTests/insightsTrendCard_393點寬最大輔助字級_走勢軸標不重疊.1.png
  - apps/ios/BuyLedger/Features/Dashboard/Presentation/Root/Views/DashboardView.swift
  - apps/ios/BuyLedgerUITests/Tests/More/LookupManagementTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/Filters/OrderCategoryPickerLargeTests.swift
  - apps/ios/BuyLedger/Features/More/Presentation/Root/MoreView.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/Filters/OrderCategoryPickerTests.swift
  - apps/ios/BuyLedgerTests/Guards/InputFieldConventionScanTests.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/Root/Plans/OrdersContainerPlan+Writes.swift
  - apps/ios/BuyLedger/Features/Lookups/Presentation/PaymentMethodEditForm/PaymentMethodEditFormFeature.swift
  - apps/ios/BuyLedgerTests/Features/Lookups/LookupManagementFeaturePaymentMethodCorrectionTests.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersFeatureDetailTests.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotInsightsTests/insightsView_載入中_顯示載入骨架.1.png
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Pickers/OptionPickerSheet.swift
  - apps/ios/BuyLedgerTests/Features/Campaigns/CampaignFeatureReloadDeleteTests.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/OrderDetail/Views/OrderDetailItemsView.swift
  - apps/ios/BuyLedgerUITests/Screens/Dashboard/DashboardScreen.swift
  - apps/ios/BuyLedgerUITests/Support/Assertions/Waiting.swift
  - apps/ios/BuyLedgerUITests/Support/XCTestCase+PlatformScope.swift
  - apps/ios/BuyLedgerUITests/Screens/More/SettingsScreen.swift
  - apps/ios/BuyLedger/Features/Lookups/Presentation/Root/Views/LookupItemList.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/OrderList/Operations/OrderListInteraction.swift
  - apps/ios/BuyLedgerUITests/Support/XCUIApplication+StableVisibleFrame.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/Edit/KeyboardDismissTests.swift
  - apps/ios/BuyLedgerUITests/Support/Assertions/ValueParsing.swift
  - apps/ios/BuyLedgerTests/Guards/LayerBoundary/LayerBoundaryTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Forms/ToolsInputFocusUITests.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/OrderDetail/Views/OrderDetailView.swift
  - apps/ios/BuyLedgerUITests/Support/Launch/BLUITestCase.swift
  - apps/ios/BuyLedgerUITests/Support/BoundsCheck.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrderMergeFeatureTests.swift
  - apps/ios/BuyLedger/Features/App/Presentation/Root/RootSidebarLayout.swift
  - apps/ios/BuyLedgerUITests/Tests/Tools/SettingsGoalInputTests.swift
  - apps/ios/BuyLedgerUITests/Screens/Orders/OrderFilterSheetScreen.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotOrdersTests/ordersView_寬版清單欄多選模式_顯示選取列.1.png
  - apps/ios/BuyLedgerUITests/Tests/Tools/QuoteTests.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/OrderList/Operations/OrdersFilterOperations.swift
  - apps/ios/BuyLedgerTests/Features/App/RootFeatureDetailNavigationTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/Regular/OrderRegularAccessibilitySizeTests.swift
  - apps/ios/BuyLedgerUITests/Support/Layout/PlatformScope.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/Regular/OrderRegularSearchBarTests.swift
  - apps/ios/BuyLedgerUITests/Support/XCUIElement+FocusTap.swift
  - apps/ios/BuyLedger/Features/Campaigns/Presentation/CampaignEdit/CampaignEditNotesSection.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/Components/OrderCategoryFilterRows.swift
  - apps/ios/BuyLedgerTests/Features/Quote/QuoteFeatureTests.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/SnapshotOrdersTests.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/Root/Requests/OrderRequestPlan.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotInsightsTests/insightsView_寬版_並排顯示類別排行與成本結構.1.png
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersFeatureFilterPathTests.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersFeatureDateRefreshTests.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/SnapshotToolsTests.swift
  - apps/ios/BuyLedger/Features/Insights/Presentation/Root/Views/InsightsView.swift
  - apps/ios/BuyLedgerTests/Features/App/RootFeatureForegroundTests.swift
  - apps/ios/BuyLedgerUITests/Support/CampaignSeedFixture.swift
  - apps/ios/BuyLedgerUITests/Support/Launch/AppNavigator.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/Root/OrdersFeature.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/OrderEdit/Views/OrderEditDecimalField.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/Root/Views/OrdersRegularListColumn.swift
  - apps/ios/BuyLedgerTests/Features/Campaigns/CampaignListFeatureInteractionsTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Forms/EditorTextInputFocusUITests.swift
-->

---
### Requirement: Numeric fields clear their text when focus arrives

A numeric entry field (amount, percentage, exchange amount, quote input, unit price, or monthly goal) SHALL show empty text at the moment that individual field gains focus, whatever its value and including when focus moves directly from another field on the same screen, so that typed digits replace the existing value instead of being inserted beside it. Clearing SHALL NOT write to the bound value. The field SHALL clear only on its transition from unfocused to focused; while the field stays focused, later taps SHALL NOT clear the typed text again. When editing ends and no parsable text was typed, the field SHALL show the bound value in the field's format again. Clearing SHALL NOT change the field's number format, fraction digits, keyboard type, alignment, or validation.

#### Scenario: Typing replaces a displayed zero

- **GIVEN** a numeric field whose bound value is 0
- **WHEN** the user taps the left part of the field, types the text, and ends editing
- **THEN** the shown text and the bound value match the example table

##### Example: Zero fields

| Field | Shown before focus | Typed text | Shown while focused | Shown after editing ends | Bound value |
| ----- | ------------------ | ---------- | ------------------- | ------------------------ | ----------- |
| Charged amount (whole numbers) | 0 | 1000 | 1000 | 1000 | 1000 |
| Order card fee percentage (two fraction digits) | 0.00 | 5 | 5 | 5.00 | 5 percent |
| Quote card fee percentage (one fraction digit) | 0.0 | 5 | 5 | 5.0 | 5 percent |

#### Scenario: Typing replaces an existing value

- **GIVEN** a quote whose principal field shows 2500 and whose keyboard has been dismissed
- **WHEN** the user taps the left part of the principal field and types 1000
- **THEN** the principal field shows 1000 and the suggested price shows $30

#### Scenario: Moving focus between quote fields also clears

- **GIVEN** a quote whose focused principal field shows 2500 and whose local shipping field shows 30
- **WHEN** the user taps the local shipping field without dismissing the keyboard and types 5
- **THEN** the local shipping field shows 5 and the principal field still shows 2500

#### Scenario: Moving focus from another field also clears

- **GIVEN** an order item whose name field is focused and whose unit price field shows 120
- **WHEN** the user taps the unit price field and types 95
- **THEN** the unit price field shows 95

#### Scenario: A later tap does not clear typed text

- **GIVEN** a focused percentage field in which the user has typed 12
- **WHEN** the user taps the left part of the same field and types 3
- **THEN** the field text contains the digits 12 and the typed 3

#### Scenario: An untouched field returns to its display

- **GIVEN** a numeric field showing the text in the example table
- **WHEN** the user focuses the field and dismisses the keyboard without typing
- **THEN** the field shows no text while focused and shows the same text after the keyboard is dismissed

##### Example: Untouched fields

| Field | Shown before focus | Shown after the keyboard is dismissed |
| ----- | ------------------ | ------------------------------------- |
| Order card fee percentage (two fraction digits) | 0.00 | 0.00 |
| Quote principal (up to two fraction digits) | 2500 | 2500 |


<!-- @trace
source: input-focus-selection
updated: 2026-11-07
code:
  - apps/ios/BuyLedgerTests/Features/App/RootFeatureTabSelectionTests.swift
  - apps/ios/BuyLedgerUITests/Support/XCUIElement+Waiting.swift
  - apps/ios/BuyLedgerTests/Guards/DesignSystemSourceScan/DesignSystemSourceScanner.swift
  - apps/ios/BuyLedgerUITests/Tests/Customers/CustomersTests.swift
  - apps/ios/BuyLedger/Features/More/Presentation/Root/MoreFeature.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrderListFeatureClearFiltersTests.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotDashboardTests/dashboardView_寬版_並排顯示hero與KPI.1.png
  - apps/ios/BuyLedger/Features/Orders/Presentation/OrderEdit/Operations/OrderEditDraftOperations.swift
  - apps/ios/BuyLedgerUITests/Support/KPIPresenceCheck.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/OrderEdit/OrderEditFeature.swift
  - apps/ios/BuyLedger/Features/Campaigns/Presentation/CampaignList/Views/CampaignSectionList.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersFeatureStatusFailuresTests.swift
  - apps/ios/BuyLedger/Features/Campaigns/Presentation/CampaignDetail/CampaignDetailView.swift
  - apps/ios/BuyLedgerUITests/Support/XCUIApplication+MenuInteraction.swift
  - apps/ios/BuyLedgerTests/Features/Lookups/LookupAddFormFeatureTests.swift
  - apps/ios/BuyLedgerUITests/Screens/App/RootNavigationScreen.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/SnapshotInsightsTests.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersFilterOperationsTests.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/OrderEdit/Views/Sections/OrderEditNotesSection.swift
  - apps/ios/BuyLedger/Features/Quote/Presentation/Root/QuoteFeature.swift
  - apps/ios/BuyLedger/Features/Campaigns/Presentation/Root/CampaignFeature+Path.swift
  - apps/ios/BuyLedgerTests/Features/App/RootFeaturePaymentMethodCorrectionTests.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrderListFeatureDatesTests.swift
  - apps/ios/BuyLedger/Features/Lookups/Presentation/Root/Views/LookupManagementView.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotOrderDetailTests/orderDetailView_393點寬最大輔助字級_標頭與卡片留在畫面內.1.png
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotOrdersTests/ordersView_大尺寸iPhone橫向_顯示單欄清單與整合篩選鈕.1.png
  - apps/ios/BuyLedger/Features/Campaigns/Presentation/Root/CampaignFeature.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/OrderDetail/Views/OrderDetailContentView.swift
  - apps/ios/BuyLedgerTests/Features/Campaigns/CampaignFeatureFailureTimingFollowUpTests.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersFeatureListEntryTests.swift
  - apps/ios/BuyLedgerTests/Support/RootFeatureTestSupport.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotOrderDetailTests/orderDetailSections_頁面內容寬361最大輔助字級_大額金額完整不裁切.1.png
  - apps/ios/BuyLedgerTests/SnapshotTests/SnapshotOrderEditSectionsTests.swift
  - apps/ios/BuyLedgerUITests/Support/Assertions/Diagnostics.swift
  - apps/ios/BuyLedgerTests/Features/App/RootFeatureOrderFiltersTests.swift
  - apps/ios/BuyLedgerUITests/Support/CheckOutcome.swift
  - apps/ios/BuyLedgerAccessibilityIDs/BLAccessibilityID+Insights.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Forms/BLNumberField.swift
  - apps/ios/BuyLedgerTests/Features/App/RootFeatureLoadRequestsTests.swift
  - apps/ios/BuyLedgerUITests/Support/Interactions/MenuInteraction.swift
  - apps/ios/BuyLedger/Features/Lookups/Presentation/LookupRenameForm/LookupRenameFormFeature.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotOrdersTests/ordersCompactView_多選模式_顯示勾選與工具列.1.png
  - apps/ios/BuyLedgerTests/Features/Orders/OrderEditFeatureDisplayTextTests.swift
  - apps/ios/BuyLedger/Features/Dashboard/Presentation/Root/Views/DashboardSummarySection.swift
  - apps/ios/BuyLedger/Features/Insights/Presentation/Root/Views/InsightsCategoryCard.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotOrdersTests/ordersCompactView_長內容訂單清單_避免撐寬版面.1.png
  - apps/ios/BuyLedgerTests/Support/ViewLayoutMeasurementSupport.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersFeatureDeleteEditFailuresTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Cards/BLCardRowBackground.swift
  - apps/ios/BuyLedgerTests/Features/Campaigns/CampaignFeatureDeletionReminderTests.swift
  - apps/ios/BuyLedgerTests/Features/App/RootFeatureSharedOrdersTests.swift
  - apps/ios/BuyLedgerTests/Guards/ProjectionWriteBoundary/ProjectionWriteBoundaryGuardsTests.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrderListFeatureFilterSheetTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLDonutChart.swift
  - apps/ios/BuyLedgerUITests/Support/XCUIElement+ValueParsing.swift
  - apps/ios/BuyLedgerUITests/Tests/Forms/QuoteInputFocusUITests.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotDashboardTests/dashboardView_最大輔助字級_目標進度堆疊排列.1.png
  - apps/ios/BuyLedger/Features/Campaigns/Presentation/CampaignPresentation/CampaignPresentationQueue.swift
  - apps/ios/BuyLedgerTests/Guards/DesignSystemSourceScan/DesignSystemSourceScanTests.swift
  - apps/ios/BuyLedgerUITests/Support/Interactions/AlertInteraction.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersContainerPlanRequestsTests.swift
  - apps/ios/BuyLedger/Features/Campaigns/Presentation/Root/CampaignRequest.swift
  - apps/ios/BuyLedgerUITests/Support/PathCheck.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLReadableContentType.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/Root/Plans/OrdersWriteOutcome.swift
  - apps/ios/BuyLedgerUITests/Support/Launch/LaunchOptions.swift
  - apps/ios/BuyLedger/Features/App/Presentation/Root/RootView.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrderListFeatureTests.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/SnapshotOrderDetailTests.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotOrderDetailTests/orderDetailCostView_393點寬最大輔助字級_成本卡圓餅圖與中心文字在卡片內.1.png
  - apps/ios/BuyLedgerUITests/Support/XCTestCase+CampaignFlow.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersDetailNavigationFeatureTests.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/OrderEdit/Views/Sections/OrderEditItemsSection.swift
  - apps/ios/BuyLedgerAccessibilityIDs/BLAccessibilityID+Campaigns.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrderListFeatureClearFilterPresentationTests.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersFeatureEditFieldsTests.swift
  - apps/ios/BuyLedger/Features/Lookups/Presentation/Root/Views/LookupManagementPresentations.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/OrderList/Operations/OrderListDestinationOperations.swift
  - apps/ios/BuyLedger/Features/Campaigns/Presentation/CampaignEdit/CampaignEditView.swift
  - apps/ios/BuyLedgerUITests/Support/IdentifierCheck.swift
  - apps/ios/BuyLedgerTests/Shared/DesignSystem/BLBarChartLayoutTests.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrderEditFeatureDeductionTests.swift
  - apps/ios/BuyLedger/Resources/Localizable.xcstrings
  - apps/ios/BuyLedgerUITests/Tests/Navigation/ReadableWidthUITests.swift
  - apps/ios/BuyLedgerUITests/Support/Layout/HorizontalBounds.swift
  - apps/ios/BuyLedgerUITests/Support/ValueParsing.swift
  - apps/ios/BuyLedgerTests/Shared/DesignSystem/BLNumberFieldDraftTests.swift
  - apps/ios/BuyLedgerUITests/Support/Interactions/Scrolling.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersFilterOperationsSearchAndSelectionTests.swift
  - apps/ios/BuyLedger/Features/Campaigns/Presentation/Root/CampaignRequestPlan.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/Root/Views/OrdersCompactView.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotCampaignsTests/campaignListView_依日分組含今天與昨天_符合基準圖.1.png
  - apps/ios/BuyLedgerUITests/Screens/Tools/QuoteScreen.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/OrderEdit/Views/OrderEditPercentField.swift
  - apps/ios/BuyLedgerUITests/Tests/Navigation/AdaptiveNavigationContinuityUITests.swift
  - apps/ios/BuyLedger/Features/Insights/Presentation/Root/Views/InsightsHeatmapCard.swift
  - apps/ios/BuyLedger/Features/Campaigns/Presentation/CampaignList/Views/CampaignRow.swift
  - apps/ios/BuyLedger/Features/Dashboard/Presentation/Root/Views/DashboardKPITiles.swift
  - apps/ios/BuyLedgerTests/AccessibilityIDs/BLAccessibilityIDTests.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersFeatureListRequestsTests.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersFilterOperationsSearchTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Forms/PaymentMethodEditorSheet.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/Regular/OrderRegularClearFiltersTests.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/OrderEdit/Views/OrderEditView.swift
  - apps/ios/BuyLedgerUITests/Support/XCTestCase+HorizontalBounds.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/Root/Views/OrdersView.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotCampaignsTests/campaignListView_選取其中一筆開團_符合基準圖.1.png
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotDashboardTests/dashboardView_寬版_摘要在上四項KPI兩欄.1.png
  - apps/ios/BuyLedgerTests/SnapshotTests/SnapshotOrderFilterEmptyStatesTests.swift
  - apps/ios/BuyLedgerUITests/Support/Interactions/TextInput.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/OrderEdit/Views/Sections/OrderEditFeesSection.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotCampaignsTests/campaignListView_依日分組同日三筆與他日一筆_符合基準圖.1.png
  - apps/ios/BuyLedgerAccessibilityIDs/BLAccessibilityID+Orders.swift
  - apps/ios/BuyLedgerAccessibilityIDs/BLAccessibilityID+More.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrdersListTests.swift
  - apps/ios/BuyLedgerUITests/Support/XCUIApplication+AlertInteraction.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrderSaveGuardTests.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotOrdersTests/ordersCompactView_同日三筆與他日一筆_符合基準圖.1.png
  - apps/ios/BuyLedgerUITests/Screens/Orders/OrderEditScreen.swift
  - apps/ios/BuyLedgerUITests/Support/Layout/Orientation.swift
  - apps/ios/BuyLedgerUITests/Tests/Campaigns/CampaignFlowTests.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/OrderList/OrderListFeature.swift
  - apps/ios/BuyLedgerTests/Features/More/MoreFeatureRelaysTests.swift
  - apps/ios/BuyLedgerTests/Features/Campaigns/CampaignFeatureFailureTimingTests.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrderFilterFeatureClearTests.swift
  - apps/ios/BuyLedgerTests/Guards/ToolReadableWidthGuardTests.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/Root/Requests/OrderRequest.swift
  - apps/ios/BuyLedgerTests/Support/CampaignFeatureTestSupport.swift
  - apps/ios/BuyLedgerTests/Support/View+LayoutMeasurement.swift
  - apps/ios/BuyLedger/Features/Quote/Presentation/Root/QuoteInputsCard.swift
  - apps/ios/BuyLedger/Features/Lookups/Presentation/Root/LookupManagementFeature+Destination.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotInsightsTests/insightsView_大尺寸iPhone橫向_類別排行與成本結構上下堆疊.1.png
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotInsightsTests/insightsCategoryCard_393點寬最大輔助字級_金額不斷字.1.png
  - apps/ios/BuyLedgerTests/Features/More/MoreFeatureEntrySelectionTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Insights/InsightsLayoutSmokeTests.swift
  - apps/ios/BuyLedgerTests/Shared/DesignSystem/BLLayoutClassTests.swift
  - apps/ios/BuyLedgerUITests/Screens/Orders/OrdersScreen.swift
  - apps/ios/BuyLedger/Features/Campaigns/Presentation/CampaignList/CampaignListFeature.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/Root/Plans/OrdersContainerPlan.swift
  - apps/ios/BuyLedgerTests/Guards/BottomBarPlacementScanTests.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersFeatureMergeWritesTests.swift
  - apps/ios/BuyLedger/Features/Campaigns/Presentation/CampaignPresentation/CampaignPresentationFeature.swift
  - apps/ios/BuyLedger/Features/Lookups/Presentation/LookupAddForm/LookupAddFormFeature.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersViewLayoutTests.swift
  - apps/ios/BuyLedgerUITests/Screens/More/LookupManagementScreen.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotOrderDetailTests/orderDetailSections_頁面內容寬361最大輔助字級_成本圖例與商品金額不斷字.1.png
  - apps/ios/BuyLedgerUITests/Support/Assertions/Assertions.swift
  - apps/ios/BuyLedgerUITests/Tests/Navigation/NavigationScenarioUITests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLLayoutClass.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLBarChart.swift
  - apps/ios/BuyLedgerTests/Guards/LayerBoundary/LanguageProjectionBoundaryTests.swift
  - apps/ios/BuyLedgerTests/Shared/DesignSystem/BLReadableScrollContentLayoutTests.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotCampaignsTests/campaignListView_依月分組_符合基準圖.1.png
  - apps/ios/BuyLedgerTests/Features/App/RootFeatureLookupSyncTests.swift
  - apps/ios/BuyLedgerUITests/Support/LaunchOptions.swift
  - apps/ios/BuyLedgerUITests/Tests/Smoke/LaunchSmokeTests.swift
  - apps/ios/BuyLedgerUITests/Screens/Campaigns/CampaignsScreen.swift
  - apps/ios/BuyLedgerUITests/Tests/Navigation/AdaptiveLayoutCheckCounterexampleTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/Filters/OrderPaymentMethodMenuTests.swift
  - apps/ios/README.md
  - apps/ios/BuyLedgerTests/Features/Lookups/PaymentMethodEditFormFeatureTests.swift
  - apps/ios/BuyLedger/Features/Lookups/Presentation/Root/LookupManagementFeature.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/OrderEdit/Models/OrderDraft.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/OrderMerge/OrderMergeFeature.swift
  - apps/ios/BuyLedgerTests/Features/Campaigns/CampaignFeatureNavigationTests.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersFilterOperationsClearFiltersTests.swift
  - apps/ios/BuyLedgerTests/Features/Lookups/LookupManagementFeatureFailuresTests.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotOrderFilterEmptyStatesTests/ordersRegularListContent_寬版清單欄無付款方式與類別_符合基準圖.1.png
  - apps/ios/BuyLedgerUITests/Tests/Dashboard/DashboardLayoutSmokeTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/Regular/OrderRegularColumnWidthTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLCardRowMetrics.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/Root/Views/OrdersRegularListContent.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotOrderFilterEmptyStatesTests/ordersView_寬版清單欄無付款方式與類別_符合基準圖.1.png
  - apps/ios/BuyLedgerUITests/Tests/Smoke/OrientationLayoutTests.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersFilterOperationsFilterSheetTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/ViewModifiers/BLSearchableModifier.swift
  - apps/ios/BuyLedger/Features/Campaigns/Presentation/Root/CampaignView.swift
  - apps/ios/BuyLedger/App/Testing/Configuration/BLUITestConfiguration.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersFeatureLoadAndSummaryTests.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersFeatureOptionWritesTests.swift
  - apps/ios/BuyLedger/Features/Dashboard/Presentation/Root/Views/DashboardHeroCard.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotOrderEditSectionsTests/orderEditItemsSection_最大輔助字級_商品列堆疊排列.1.png
  - apps/ios/BuyLedgerUITests/Support/XCTestCase+Diagnostics.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/OrderEdit/Views/Sections/OrderEditBasicSection.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Forms/BLTextField.swift
  - apps/ios/BuyLedgerTests/Features/App/RootFeatureSidebarTests.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/OrdersDetailNavigation/OrdersDetailSelection.swift
  - apps/ios/BuyLedgerUITests/Support/XCUIApplication+TextInput.swift
  - apps/ios/BuyLedgerTests/Guards/LayerBoundary/LanguageProjectionScanner.swift
  - apps/ios/BuyLedgerUITests/Support/XCUIApplication+NavigationBackInteraction.swift
  - apps/ios/BuyLedgerTests/Features/More/MoreFeatureTests.swift
  - apps/ios/BuyLedgerUITests/Support/XCUIApplication+Diagnostics.swift
  - apps/ios/CLAUDE.md
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotCampaignsTests/campaignListView_依年分組_符合基準圖.1.png
  - apps/ios/BuyLedgerUITests/Tests/Orders/Filters/OrderFilterSheetLargeTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/Filters/OrderFilterSheetTests.swift
  - apps/ios/BuyLedgerUITests/Screens/Campaigns/CampaignEditScreen.swift
  - apps/ios/BuyLedger.xcodeproj/project.xcproj
  - apps/ios/BuyLedger/Features/Quote/Presentation/Root/QuoteView.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersFeatureCreateTests.swift
  - apps/ios/BuyLedgerTests/Guards/OrderListSnapshotSourceScanTests.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/SnapshotDashboardTests.swift
  - apps/ios/BuyLedgerTests/Features/Lookups/LookupRenameFormFeatureTests.swift
  - apps/ios/BuyLedgerUITests/Support/XCTestCase+Orientation.swift
  - apps/ios/BuyLedgerUITests/Tests/Forms/OrderEditInputFocusUITests.swift
  - apps/ios/BuyLedgerTests/Features/Campaigns/CampaignPresentationQueueTests.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/Root/Plans/OrdersContainerPlan+Requests.swift
  - apps/ios/BuyLedger/Features/Lookups/Presentation/Root/Views/LookupNameEditorSheet.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotOrdersTests/ordersView_大尺寸iPhone橫向_分欄顯示清單與整合篩選鈕.1.png
  - apps/ios/BuyLedgerTests/Shared/DesignSystem/BLLayoutClassEnvironmentTests.swift
  - .github/workflows/ci.yml
  - apps/ios/BuyLedgerUITests/Support/Interactions/SheetInteraction.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersLoadStateTests.swift
  - apps/ios/BuyLedgerTests/Features/Campaigns/CampaignPresentationFeatureTests.swift
  - apps/ios/BuyLedger/Features/Customers/Presentation/Root/CustomersView.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotInsightsTests/insightsCostStructureCard_393點寬最大輔助字級_圓餅圖與中心文字留在卡片內.1.png
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotInsightsTests/insightsView_寬版_卡片依固定順序垂直排列.1.png
  - apps/ios/BuyLedger/Features/Orders/Presentation/OrdersDetailNavigation/OrdersDetailNavigationFeature.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotMoreTests/moreView_預設清單_顯示各入口.1.png
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotToolsTests/quoteView_最大輔助字級_輸入列堆疊排列.1.png
  - apps/ios/BuyLedger/Features/Orders/Presentation/Root/Plans/OrdersRequestOutcome.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrderListFeatureFiltersTests.swift
  - apps/ios/BuyLedger/Features/App/Presentation/Root/RootFeature.swift
  - apps/ios/BuyLedger/Features/FX/Presentation/Root/FxView.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersFeatureMergeSaveTests.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/OrderEdit/Views/Sections/OrderEditPaymentSection.swift
  - apps/ios/BuyLedgerUITests/Tests/Tools/FxTests.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersContainerPlanWritesTests.swift
  - apps/ios/BuyLedgerAccessibilityIDs/BLAccessibilityID+Common.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrderListFeatureFilterDelegatesTests.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/SnapshotOrdersBaselineTests.swift
  - apps/ios/BuyLedgerTests/Support/OrderListFeatureTestSupport.swift
  - apps/ios/BuyLedgerTests/Features/Lookups/LookupManagementFeatureTestSupport.swift
  - apps/ios/BuyLedger/Features/App/Presentation/Root/RootTabLayout.swift
  - apps/ios/BuyLedgerTests/Features/Campaigns/CampaignFeatureReloadTests.swift
  - apps/ios/BuyLedgerUITests/Screens/Insights/InsightsScreen.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/OrderMerge/OrderMergeCandidateSheet.swift
  - apps/ios/BuyLedgerTests/Features/Lookups/LookupManagementFeatureAlertTimingTests.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersFeatureEditDeductionTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Forms/SearchInputFocusUITests.swift
  - apps/ios/BuyLedgerUITests/Support/XCUIElement+TextInput.swift
  - CLAUDE.md
  - apps/ios/BuyLedgerTests/Features/Orders/OrderListFeatureCategoryPickerApplyTests.swift
  - apps/ios/BuyLedgerUITests/Support/BLUITestCase.swift
  - apps/ios/BuyLedgerUITests/Support/XCTestCase+OrdersLayoutAssertions.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotOrdersTests/ordersCompactView_一般訂單清單_符合基準圖.1.png
  - apps/ios/BuyLedgerTests/Features/Orders/OrderFilterFeatureCategoriesTests.swift
  - apps/ios/BuyLedgerTests/Features/Campaigns/CampaignFeatureWriteFailuresTests.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersSearchCancellationTests.swift
  - apps/ios/BuyLedger/Features/Campaigns/Presentation/CampaignPresentation/CampaignPresentationFeature+Destination.swift
  - apps/ios/BuyLedgerUITests/Support/XCUIApplication+SheetInteraction.swift
  - apps/ios/BuyLedger/Features/App/Presentation/Root/RootNavigationLayout.swift
  - apps/ios/BuyLedger/Features/Campaigns/Presentation/CampaignList/Views/CampaignListView.swift
  - apps/ios/BuyLedgerTests/Shared/DesignSystem/BLReadableContentLayoutTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrdersNavigationSmokeTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/ViewModifiers/BLReadableContentLayout.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Forms/BLNumberFieldDraft.swift
  - apps/ios/BuyLedgerUITests/Support/AppNavigator.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/ViewModifiers/BLReadableScrollContentLayout.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Cards/BLCardRowPosition.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/Regular/OrderRegularColumnScopeTests.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/OrderList/Views/OrdersCompactListView.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/Components/OrdersFilterControlsView.swift
  - apps/ios/BuyLedgerUITests/Tests/More/MoreNavigationSmokeTests.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/SnapshotCampaignsTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Pickers/BLSearchableModifier.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/Root/Views/OrdersRegularDetailColumn.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotCampaignsTests/campaignListView_英文月分組_符合基準圖.1.png
  - apps/ios/BuyLedgerTests/Guards/ActionGrouping/ActionGroupingScanner.swift
  - apps/ios/BuyLedgerUITests/Screens/Tools/FxScreen.swift
  - apps/ios/BuyLedgerUITests/Support/XCTestCase+Assertions.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersContainerPlanTests.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/OrderDetail/Views/OrderDetailCostView.swift
  - apps/ios/BuyLedgerUITests/Support/XCUIApplication+Scrolling.swift
  - apps/ios/BuyLedgerTests/Features/Campaigns/CampaignIntegrationTests.swift
  - apps/ios/BuyLedger/Features/Settings/Presentation/Root/SettingsView.swift
  - apps/ios/BuyLedgerTests/Features/Campaigns/CampaignFeaturePresentationTests.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotInsightsTests/insightsTrendCard_393點寬最大輔助字級_走勢軸標不重疊.1.png
  - apps/ios/BuyLedger/Features/Dashboard/Presentation/Root/Views/DashboardView.swift
  - apps/ios/BuyLedgerUITests/Tests/More/LookupManagementTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/Filters/OrderCategoryPickerLargeTests.swift
  - apps/ios/BuyLedger/Features/More/Presentation/Root/MoreView.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/Filters/OrderCategoryPickerTests.swift
  - apps/ios/BuyLedgerTests/Guards/InputFieldConventionScanTests.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/Root/Plans/OrdersContainerPlan+Writes.swift
  - apps/ios/BuyLedger/Features/Lookups/Presentation/PaymentMethodEditForm/PaymentMethodEditFormFeature.swift
  - apps/ios/BuyLedgerTests/Features/Lookups/LookupManagementFeaturePaymentMethodCorrectionTests.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersFeatureDetailTests.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotInsightsTests/insightsView_載入中_顯示載入骨架.1.png
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Pickers/OptionPickerSheet.swift
  - apps/ios/BuyLedgerTests/Features/Campaigns/CampaignFeatureReloadDeleteTests.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/OrderDetail/Views/OrderDetailItemsView.swift
  - apps/ios/BuyLedgerUITests/Screens/Dashboard/DashboardScreen.swift
  - apps/ios/BuyLedgerUITests/Support/Assertions/Waiting.swift
  - apps/ios/BuyLedgerUITests/Support/XCTestCase+PlatformScope.swift
  - apps/ios/BuyLedgerUITests/Screens/More/SettingsScreen.swift
  - apps/ios/BuyLedger/Features/Lookups/Presentation/Root/Views/LookupItemList.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/OrderList/Operations/OrderListInteraction.swift
  - apps/ios/BuyLedgerUITests/Support/XCUIApplication+StableVisibleFrame.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/Edit/KeyboardDismissTests.swift
  - apps/ios/BuyLedgerUITests/Support/Assertions/ValueParsing.swift
  - apps/ios/BuyLedgerTests/Guards/LayerBoundary/LayerBoundaryTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Forms/ToolsInputFocusUITests.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/OrderDetail/Views/OrderDetailView.swift
  - apps/ios/BuyLedgerUITests/Support/Launch/BLUITestCase.swift
  - apps/ios/BuyLedgerUITests/Support/BoundsCheck.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrderMergeFeatureTests.swift
  - apps/ios/BuyLedger/Features/App/Presentation/Root/RootSidebarLayout.swift
  - apps/ios/BuyLedgerUITests/Tests/Tools/SettingsGoalInputTests.swift
  - apps/ios/BuyLedgerUITests/Screens/Orders/OrderFilterSheetScreen.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotOrdersTests/ordersView_寬版清單欄多選模式_顯示選取列.1.png
  - apps/ios/BuyLedgerUITests/Tests/Tools/QuoteTests.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/OrderList/Operations/OrdersFilterOperations.swift
  - apps/ios/BuyLedgerTests/Features/App/RootFeatureDetailNavigationTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/Regular/OrderRegularAccessibilitySizeTests.swift
  - apps/ios/BuyLedgerUITests/Support/Layout/PlatformScope.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/Regular/OrderRegularSearchBarTests.swift
  - apps/ios/BuyLedgerUITests/Support/XCUIElement+FocusTap.swift
  - apps/ios/BuyLedger/Features/Campaigns/Presentation/CampaignEdit/CampaignEditNotesSection.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/Components/OrderCategoryFilterRows.swift
  - apps/ios/BuyLedgerTests/Features/Quote/QuoteFeatureTests.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/SnapshotOrdersTests.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/Root/Requests/OrderRequestPlan.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotInsightsTests/insightsView_寬版_並排顯示類別排行與成本結構.1.png
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersFeatureFilterPathTests.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersFeatureDateRefreshTests.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/SnapshotToolsTests.swift
  - apps/ios/BuyLedger/Features/Insights/Presentation/Root/Views/InsightsView.swift
  - apps/ios/BuyLedgerTests/Features/App/RootFeatureForegroundTests.swift
  - apps/ios/BuyLedgerUITests/Support/CampaignSeedFixture.swift
  - apps/ios/BuyLedgerUITests/Support/Launch/AppNavigator.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/Root/OrdersFeature.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/OrderEdit/Views/OrderEditDecimalField.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/Root/Views/OrdersRegularListColumn.swift
  - apps/ios/BuyLedgerTests/Features/Campaigns/CampaignListFeatureInteractionsTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Forms/EditorTextInputFocusUITests.swift
-->

---
### Requirement: Numeric entry keeps its parsing and write-back behavior

Changing how a numeric field manages focus SHALL NOT change which text it accepts, how it rounds or limits fraction digits, or when the parsed value is written back to the feature state. Text that the field's number format cannot parse SHALL leave the bound value unchanged, except that empty text SHALL restore the value bound when focus arrived if this focus has already written a value. Gaining or losing focus without typing SHALL NOT write to the bound value. When editing ends, the field SHALL show the bound value in the field's format, and a bound value changed from outside the field SHALL replace the field's text.

#### Scenario: Fraction digits follow the field's format

- **GIVEN** a numeric field with its existing number format
- **WHEN** the field holds the given text and editing ends
- **THEN** the bound value and the shown text match the example table

##### Example: Parsing outcomes stay the same

| Field | Starting value | Text when editing ends | Bound value after editing ends | Field shows after editing ends | Notes |
| ----- | -------------- | ---------------------- | ------------------------------ | ------------------------------ | ----- |
| Charged amount (whole numbers) | 0 | 1000 | 1000 | 1000 | the shown 0 was cleared on focus |
| Quote principal (up to two fraction digits) | 0 | 22.8 | 22.8 | 22.8 | decimal entry allowed |
| Monthly goal (whole numbers) | 80000 | abc | 80000 | 80000 | unparsable text keeps the previous value |
| Monthly goal (whole numbers) | 80000 | empty text | 80000 | 80000 | left without typing |
| Charged amount (whole numbers) | 0 | empty text | 0 | 0 | left without typing |
| Card fee percentage (two fraction digits) | 0 | 12.345 | 12.35 | 12.35 | midpoint rounds away from zero |

#### Scenario: Emptying typed text restores the value from focus

- **GIVEN** an order edit form with no unsaved change whose charged amount field shows 2500
- **WHEN** the user focuses the field, types 1, deletes it, dismisses the keyboard, and taps cancel
- **THEN** the field shows 2500 after the keyboard is dismissed and the form closes without a discard confirmation

#### Scenario: Typing updates dependent results before editing ends

- **GIVEN** a quote whose principal field shows the default value 0 and is focused with the keyboard showing
- **WHEN** the user types 1000 without dismissing the keyboard
- **THEN** the suggested price shows $30 while the keyboard is still showing

#### Scenario: Focusing without typing keeps the form unmodified

- **GIVEN** an order edit form with no unsaved change
- **WHEN** the user focuses the charged amount field, dismisses the keyboard without typing, and taps cancel
- **THEN** the form closes without a discard confirmation

#### Scenario: An outside value change replaces the field text

- **GIVEN** an exchange amount field showing 150000
- **WHEN** the user taps a preset amount button
- **THEN** the field shows the preset amount

<!-- @trace
source: input-focus-selection
updated: 2026-11-07
code:
  - apps/ios/BuyLedgerTests/Features/App/RootFeatureTabSelectionTests.swift
  - apps/ios/BuyLedgerUITests/Support/XCUIElement+Waiting.swift
  - apps/ios/BuyLedgerTests/Guards/DesignSystemSourceScan/DesignSystemSourceScanner.swift
  - apps/ios/BuyLedgerUITests/Tests/Customers/CustomersTests.swift
  - apps/ios/BuyLedger/Features/More/Presentation/Root/MoreFeature.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrderListFeatureClearFiltersTests.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotDashboardTests/dashboardView_寬版_並排顯示hero與KPI.1.png
  - apps/ios/BuyLedger/Features/Orders/Presentation/OrderEdit/Operations/OrderEditDraftOperations.swift
  - apps/ios/BuyLedgerUITests/Support/KPIPresenceCheck.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/OrderEdit/OrderEditFeature.swift
  - apps/ios/BuyLedger/Features/Campaigns/Presentation/CampaignList/Views/CampaignSectionList.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersFeatureStatusFailuresTests.swift
  - apps/ios/BuyLedger/Features/Campaigns/Presentation/CampaignDetail/CampaignDetailView.swift
  - apps/ios/BuyLedgerUITests/Support/XCUIApplication+MenuInteraction.swift
  - apps/ios/BuyLedgerTests/Features/Lookups/LookupAddFormFeatureTests.swift
  - apps/ios/BuyLedgerUITests/Screens/App/RootNavigationScreen.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/SnapshotInsightsTests.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersFilterOperationsTests.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/OrderEdit/Views/Sections/OrderEditNotesSection.swift
  - apps/ios/BuyLedger/Features/Quote/Presentation/Root/QuoteFeature.swift
  - apps/ios/BuyLedger/Features/Campaigns/Presentation/Root/CampaignFeature+Path.swift
  - apps/ios/BuyLedgerTests/Features/App/RootFeaturePaymentMethodCorrectionTests.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrderListFeatureDatesTests.swift
  - apps/ios/BuyLedger/Features/Lookups/Presentation/Root/Views/LookupManagementView.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotOrderDetailTests/orderDetailView_393點寬最大輔助字級_標頭與卡片留在畫面內.1.png
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotOrdersTests/ordersView_大尺寸iPhone橫向_顯示單欄清單與整合篩選鈕.1.png
  - apps/ios/BuyLedger/Features/Campaigns/Presentation/Root/CampaignFeature.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/OrderDetail/Views/OrderDetailContentView.swift
  - apps/ios/BuyLedgerTests/Features/Campaigns/CampaignFeatureFailureTimingFollowUpTests.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersFeatureListEntryTests.swift
  - apps/ios/BuyLedgerTests/Support/RootFeatureTestSupport.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotOrderDetailTests/orderDetailSections_頁面內容寬361最大輔助字級_大額金額完整不裁切.1.png
  - apps/ios/BuyLedgerTests/SnapshotTests/SnapshotOrderEditSectionsTests.swift
  - apps/ios/BuyLedgerUITests/Support/Assertions/Diagnostics.swift
  - apps/ios/BuyLedgerTests/Features/App/RootFeatureOrderFiltersTests.swift
  - apps/ios/BuyLedgerUITests/Support/CheckOutcome.swift
  - apps/ios/BuyLedgerAccessibilityIDs/BLAccessibilityID+Insights.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Forms/BLNumberField.swift
  - apps/ios/BuyLedgerTests/Features/App/RootFeatureLoadRequestsTests.swift
  - apps/ios/BuyLedgerUITests/Support/Interactions/MenuInteraction.swift
  - apps/ios/BuyLedger/Features/Lookups/Presentation/LookupRenameForm/LookupRenameFormFeature.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotOrdersTests/ordersCompactView_多選模式_顯示勾選與工具列.1.png
  - apps/ios/BuyLedgerTests/Features/Orders/OrderEditFeatureDisplayTextTests.swift
  - apps/ios/BuyLedger/Features/Dashboard/Presentation/Root/Views/DashboardSummarySection.swift
  - apps/ios/BuyLedger/Features/Insights/Presentation/Root/Views/InsightsCategoryCard.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotOrdersTests/ordersCompactView_長內容訂單清單_避免撐寬版面.1.png
  - apps/ios/BuyLedgerTests/Support/ViewLayoutMeasurementSupport.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersFeatureDeleteEditFailuresTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Cards/BLCardRowBackground.swift
  - apps/ios/BuyLedgerTests/Features/Campaigns/CampaignFeatureDeletionReminderTests.swift
  - apps/ios/BuyLedgerTests/Features/App/RootFeatureSharedOrdersTests.swift
  - apps/ios/BuyLedgerTests/Guards/ProjectionWriteBoundary/ProjectionWriteBoundaryGuardsTests.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrderListFeatureFilterSheetTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLDonutChart.swift
  - apps/ios/BuyLedgerUITests/Support/XCUIElement+ValueParsing.swift
  - apps/ios/BuyLedgerUITests/Tests/Forms/QuoteInputFocusUITests.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotDashboardTests/dashboardView_最大輔助字級_目標進度堆疊排列.1.png
  - apps/ios/BuyLedger/Features/Campaigns/Presentation/CampaignPresentation/CampaignPresentationQueue.swift
  - apps/ios/BuyLedgerTests/Guards/DesignSystemSourceScan/DesignSystemSourceScanTests.swift
  - apps/ios/BuyLedgerUITests/Support/Interactions/AlertInteraction.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersContainerPlanRequestsTests.swift
  - apps/ios/BuyLedger/Features/Campaigns/Presentation/Root/CampaignRequest.swift
  - apps/ios/BuyLedgerUITests/Support/PathCheck.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLReadableContentType.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/Root/Plans/OrdersWriteOutcome.swift
  - apps/ios/BuyLedgerUITests/Support/Launch/LaunchOptions.swift
  - apps/ios/BuyLedger/Features/App/Presentation/Root/RootView.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrderListFeatureTests.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/SnapshotOrderDetailTests.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotOrderDetailTests/orderDetailCostView_393點寬最大輔助字級_成本卡圓餅圖與中心文字在卡片內.1.png
  - apps/ios/BuyLedgerUITests/Support/XCTestCase+CampaignFlow.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersDetailNavigationFeatureTests.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/OrderEdit/Views/Sections/OrderEditItemsSection.swift
  - apps/ios/BuyLedgerAccessibilityIDs/BLAccessibilityID+Campaigns.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrderListFeatureClearFilterPresentationTests.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersFeatureEditFieldsTests.swift
  - apps/ios/BuyLedger/Features/Lookups/Presentation/Root/Views/LookupManagementPresentations.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/OrderList/Operations/OrderListDestinationOperations.swift
  - apps/ios/BuyLedger/Features/Campaigns/Presentation/CampaignEdit/CampaignEditView.swift
  - apps/ios/BuyLedgerUITests/Support/IdentifierCheck.swift
  - apps/ios/BuyLedgerTests/Shared/DesignSystem/BLBarChartLayoutTests.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrderEditFeatureDeductionTests.swift
  - apps/ios/BuyLedger/Resources/Localizable.xcstrings
  - apps/ios/BuyLedgerUITests/Tests/Navigation/ReadableWidthUITests.swift
  - apps/ios/BuyLedgerUITests/Support/Layout/HorizontalBounds.swift
  - apps/ios/BuyLedgerUITests/Support/ValueParsing.swift
  - apps/ios/BuyLedgerTests/Shared/DesignSystem/BLNumberFieldDraftTests.swift
  - apps/ios/BuyLedgerUITests/Support/Interactions/Scrolling.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersFilterOperationsSearchAndSelectionTests.swift
  - apps/ios/BuyLedger/Features/Campaigns/Presentation/Root/CampaignRequestPlan.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/Root/Views/OrdersCompactView.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotCampaignsTests/campaignListView_依日分組含今天與昨天_符合基準圖.1.png
  - apps/ios/BuyLedgerUITests/Screens/Tools/QuoteScreen.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/OrderEdit/Views/OrderEditPercentField.swift
  - apps/ios/BuyLedgerUITests/Tests/Navigation/AdaptiveNavigationContinuityUITests.swift
  - apps/ios/BuyLedger/Features/Insights/Presentation/Root/Views/InsightsHeatmapCard.swift
  - apps/ios/BuyLedger/Features/Campaigns/Presentation/CampaignList/Views/CampaignRow.swift
  - apps/ios/BuyLedger/Features/Dashboard/Presentation/Root/Views/DashboardKPITiles.swift
  - apps/ios/BuyLedgerTests/AccessibilityIDs/BLAccessibilityIDTests.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersFeatureListRequestsTests.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersFilterOperationsSearchTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Forms/PaymentMethodEditorSheet.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/Regular/OrderRegularClearFiltersTests.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/OrderEdit/Views/OrderEditView.swift
  - apps/ios/BuyLedgerUITests/Support/XCTestCase+HorizontalBounds.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/Root/Views/OrdersView.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotCampaignsTests/campaignListView_選取其中一筆開團_符合基準圖.1.png
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotDashboardTests/dashboardView_寬版_摘要在上四項KPI兩欄.1.png
  - apps/ios/BuyLedgerTests/SnapshotTests/SnapshotOrderFilterEmptyStatesTests.swift
  - apps/ios/BuyLedgerUITests/Support/Interactions/TextInput.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/OrderEdit/Views/Sections/OrderEditFeesSection.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotCampaignsTests/campaignListView_依日分組同日三筆與他日一筆_符合基準圖.1.png
  - apps/ios/BuyLedgerAccessibilityIDs/BLAccessibilityID+Orders.swift
  - apps/ios/BuyLedgerAccessibilityIDs/BLAccessibilityID+More.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrdersListTests.swift
  - apps/ios/BuyLedgerUITests/Support/XCUIApplication+AlertInteraction.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrderSaveGuardTests.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotOrdersTests/ordersCompactView_同日三筆與他日一筆_符合基準圖.1.png
  - apps/ios/BuyLedgerUITests/Screens/Orders/OrderEditScreen.swift
  - apps/ios/BuyLedgerUITests/Support/Layout/Orientation.swift
  - apps/ios/BuyLedgerUITests/Tests/Campaigns/CampaignFlowTests.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/OrderList/OrderListFeature.swift
  - apps/ios/BuyLedgerTests/Features/More/MoreFeatureRelaysTests.swift
  - apps/ios/BuyLedgerTests/Features/Campaigns/CampaignFeatureFailureTimingTests.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrderFilterFeatureClearTests.swift
  - apps/ios/BuyLedgerTests/Guards/ToolReadableWidthGuardTests.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/Root/Requests/OrderRequest.swift
  - apps/ios/BuyLedgerTests/Support/CampaignFeatureTestSupport.swift
  - apps/ios/BuyLedgerTests/Support/View+LayoutMeasurement.swift
  - apps/ios/BuyLedger/Features/Quote/Presentation/Root/QuoteInputsCard.swift
  - apps/ios/BuyLedger/Features/Lookups/Presentation/Root/LookupManagementFeature+Destination.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotInsightsTests/insightsView_大尺寸iPhone橫向_類別排行與成本結構上下堆疊.1.png
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotInsightsTests/insightsCategoryCard_393點寬最大輔助字級_金額不斷字.1.png
  - apps/ios/BuyLedgerTests/Features/More/MoreFeatureEntrySelectionTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Insights/InsightsLayoutSmokeTests.swift
  - apps/ios/BuyLedgerTests/Shared/DesignSystem/BLLayoutClassTests.swift
  - apps/ios/BuyLedgerUITests/Screens/Orders/OrdersScreen.swift
  - apps/ios/BuyLedger/Features/Campaigns/Presentation/CampaignList/CampaignListFeature.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/Root/Plans/OrdersContainerPlan.swift
  - apps/ios/BuyLedgerTests/Guards/BottomBarPlacementScanTests.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersFeatureMergeWritesTests.swift
  - apps/ios/BuyLedger/Features/Campaigns/Presentation/CampaignPresentation/CampaignPresentationFeature.swift
  - apps/ios/BuyLedger/Features/Lookups/Presentation/LookupAddForm/LookupAddFormFeature.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersViewLayoutTests.swift
  - apps/ios/BuyLedgerUITests/Screens/More/LookupManagementScreen.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotOrderDetailTests/orderDetailSections_頁面內容寬361最大輔助字級_成本圖例與商品金額不斷字.1.png
  - apps/ios/BuyLedgerUITests/Support/Assertions/Assertions.swift
  - apps/ios/BuyLedgerUITests/Tests/Navigation/NavigationScenarioUITests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLLayoutClass.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLBarChart.swift
  - apps/ios/BuyLedgerTests/Guards/LayerBoundary/LanguageProjectionBoundaryTests.swift
  - apps/ios/BuyLedgerTests/Shared/DesignSystem/BLReadableScrollContentLayoutTests.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotCampaignsTests/campaignListView_依月分組_符合基準圖.1.png
  - apps/ios/BuyLedgerTests/Features/App/RootFeatureLookupSyncTests.swift
  - apps/ios/BuyLedgerUITests/Support/LaunchOptions.swift
  - apps/ios/BuyLedgerUITests/Tests/Smoke/LaunchSmokeTests.swift
  - apps/ios/BuyLedgerUITests/Screens/Campaigns/CampaignsScreen.swift
  - apps/ios/BuyLedgerUITests/Tests/Navigation/AdaptiveLayoutCheckCounterexampleTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/Filters/OrderPaymentMethodMenuTests.swift
  - apps/ios/README.md
  - apps/ios/BuyLedgerTests/Features/Lookups/PaymentMethodEditFormFeatureTests.swift
  - apps/ios/BuyLedger/Features/Lookups/Presentation/Root/LookupManagementFeature.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/OrderEdit/Models/OrderDraft.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/OrderMerge/OrderMergeFeature.swift
  - apps/ios/BuyLedgerTests/Features/Campaigns/CampaignFeatureNavigationTests.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersFilterOperationsClearFiltersTests.swift
  - apps/ios/BuyLedgerTests/Features/Lookups/LookupManagementFeatureFailuresTests.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotOrderFilterEmptyStatesTests/ordersRegularListContent_寬版清單欄無付款方式與類別_符合基準圖.1.png
  - apps/ios/BuyLedgerUITests/Tests/Dashboard/DashboardLayoutSmokeTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/Regular/OrderRegularColumnWidthTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLCardRowMetrics.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/Root/Views/OrdersRegularListContent.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotOrderFilterEmptyStatesTests/ordersView_寬版清單欄無付款方式與類別_符合基準圖.1.png
  - apps/ios/BuyLedgerUITests/Tests/Smoke/OrientationLayoutTests.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersFilterOperationsFilterSheetTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/ViewModifiers/BLSearchableModifier.swift
  - apps/ios/BuyLedger/Features/Campaigns/Presentation/Root/CampaignView.swift
  - apps/ios/BuyLedger/App/Testing/Configuration/BLUITestConfiguration.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersFeatureLoadAndSummaryTests.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersFeatureOptionWritesTests.swift
  - apps/ios/BuyLedger/Features/Dashboard/Presentation/Root/Views/DashboardHeroCard.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotOrderEditSectionsTests/orderEditItemsSection_最大輔助字級_商品列堆疊排列.1.png
  - apps/ios/BuyLedgerUITests/Support/XCTestCase+Diagnostics.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/OrderEdit/Views/Sections/OrderEditBasicSection.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Forms/BLTextField.swift
  - apps/ios/BuyLedgerTests/Features/App/RootFeatureSidebarTests.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/OrdersDetailNavigation/OrdersDetailSelection.swift
  - apps/ios/BuyLedgerUITests/Support/XCUIApplication+TextInput.swift
  - apps/ios/BuyLedgerTests/Guards/LayerBoundary/LanguageProjectionScanner.swift
  - apps/ios/BuyLedgerUITests/Support/XCUIApplication+NavigationBackInteraction.swift
  - apps/ios/BuyLedgerTests/Features/More/MoreFeatureTests.swift
  - apps/ios/BuyLedgerUITests/Support/XCUIApplication+Diagnostics.swift
  - apps/ios/CLAUDE.md
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotCampaignsTests/campaignListView_依年分組_符合基準圖.1.png
  - apps/ios/BuyLedgerUITests/Tests/Orders/Filters/OrderFilterSheetLargeTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/Filters/OrderFilterSheetTests.swift
  - apps/ios/BuyLedgerUITests/Screens/Campaigns/CampaignEditScreen.swift
  - apps/ios/BuyLedger.xcodeproj/project.xcproj
  - apps/ios/BuyLedger/Features/Quote/Presentation/Root/QuoteView.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersFeatureCreateTests.swift
  - apps/ios/BuyLedgerTests/Guards/OrderListSnapshotSourceScanTests.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/SnapshotDashboardTests.swift
  - apps/ios/BuyLedgerTests/Features/Lookups/LookupRenameFormFeatureTests.swift
  - apps/ios/BuyLedgerUITests/Support/XCTestCase+Orientation.swift
  - apps/ios/BuyLedgerUITests/Tests/Forms/OrderEditInputFocusUITests.swift
  - apps/ios/BuyLedgerTests/Features/Campaigns/CampaignPresentationQueueTests.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/Root/Plans/OrdersContainerPlan+Requests.swift
  - apps/ios/BuyLedger/Features/Lookups/Presentation/Root/Views/LookupNameEditorSheet.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotOrdersTests/ordersView_大尺寸iPhone橫向_分欄顯示清單與整合篩選鈕.1.png
  - apps/ios/BuyLedgerTests/Shared/DesignSystem/BLLayoutClassEnvironmentTests.swift
  - .github/workflows/ci.yml
  - apps/ios/BuyLedgerUITests/Support/Interactions/SheetInteraction.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersLoadStateTests.swift
  - apps/ios/BuyLedgerTests/Features/Campaigns/CampaignPresentationFeatureTests.swift
  - apps/ios/BuyLedger/Features/Customers/Presentation/Root/CustomersView.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotInsightsTests/insightsCostStructureCard_393點寬最大輔助字級_圓餅圖與中心文字留在卡片內.1.png
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotInsightsTests/insightsView_寬版_卡片依固定順序垂直排列.1.png
  - apps/ios/BuyLedger/Features/Orders/Presentation/OrdersDetailNavigation/OrdersDetailNavigationFeature.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotMoreTests/moreView_預設清單_顯示各入口.1.png
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotToolsTests/quoteView_最大輔助字級_輸入列堆疊排列.1.png
  - apps/ios/BuyLedger/Features/Orders/Presentation/Root/Plans/OrdersRequestOutcome.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrderListFeatureFiltersTests.swift
  - apps/ios/BuyLedger/Features/App/Presentation/Root/RootFeature.swift
  - apps/ios/BuyLedger/Features/FX/Presentation/Root/FxView.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersFeatureMergeSaveTests.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/OrderEdit/Views/Sections/OrderEditPaymentSection.swift
  - apps/ios/BuyLedgerUITests/Tests/Tools/FxTests.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersContainerPlanWritesTests.swift
  - apps/ios/BuyLedgerAccessibilityIDs/BLAccessibilityID+Common.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrderListFeatureFilterDelegatesTests.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/SnapshotOrdersBaselineTests.swift
  - apps/ios/BuyLedgerTests/Support/OrderListFeatureTestSupport.swift
  - apps/ios/BuyLedgerTests/Features/Lookups/LookupManagementFeatureTestSupport.swift
  - apps/ios/BuyLedger/Features/App/Presentation/Root/RootTabLayout.swift
  - apps/ios/BuyLedgerTests/Features/Campaigns/CampaignFeatureReloadTests.swift
  - apps/ios/BuyLedgerUITests/Screens/Insights/InsightsScreen.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/OrderMerge/OrderMergeCandidateSheet.swift
  - apps/ios/BuyLedgerTests/Features/Lookups/LookupManagementFeatureAlertTimingTests.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersFeatureEditDeductionTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Forms/SearchInputFocusUITests.swift
  - apps/ios/BuyLedgerUITests/Support/XCUIElement+TextInput.swift
  - CLAUDE.md
  - apps/ios/BuyLedgerTests/Features/Orders/OrderListFeatureCategoryPickerApplyTests.swift
  - apps/ios/BuyLedgerUITests/Support/BLUITestCase.swift
  - apps/ios/BuyLedgerUITests/Support/XCTestCase+OrdersLayoutAssertions.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotOrdersTests/ordersCompactView_一般訂單清單_符合基準圖.1.png
  - apps/ios/BuyLedgerTests/Features/Orders/OrderFilterFeatureCategoriesTests.swift
  - apps/ios/BuyLedgerTests/Features/Campaigns/CampaignFeatureWriteFailuresTests.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersSearchCancellationTests.swift
  - apps/ios/BuyLedger/Features/Campaigns/Presentation/CampaignPresentation/CampaignPresentationFeature+Destination.swift
  - apps/ios/BuyLedgerUITests/Support/XCUIApplication+SheetInteraction.swift
  - apps/ios/BuyLedger/Features/App/Presentation/Root/RootNavigationLayout.swift
  - apps/ios/BuyLedger/Features/Campaigns/Presentation/CampaignList/Views/CampaignListView.swift
  - apps/ios/BuyLedgerTests/Shared/DesignSystem/BLReadableContentLayoutTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrdersNavigationSmokeTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/ViewModifiers/BLReadableContentLayout.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Forms/BLNumberFieldDraft.swift
  - apps/ios/BuyLedgerUITests/Support/AppNavigator.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/ViewModifiers/BLReadableScrollContentLayout.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Cards/BLCardRowPosition.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/Regular/OrderRegularColumnScopeTests.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/OrderList/Views/OrdersCompactListView.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/Components/OrdersFilterControlsView.swift
  - apps/ios/BuyLedgerUITests/Tests/More/MoreNavigationSmokeTests.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/SnapshotCampaignsTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Pickers/BLSearchableModifier.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/Root/Views/OrdersRegularDetailColumn.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotCampaignsTests/campaignListView_英文月分組_符合基準圖.1.png
  - apps/ios/BuyLedgerTests/Guards/ActionGrouping/ActionGroupingScanner.swift
  - apps/ios/BuyLedgerUITests/Screens/Tools/FxScreen.swift
  - apps/ios/BuyLedgerUITests/Support/XCTestCase+Assertions.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersContainerPlanTests.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/OrderDetail/Views/OrderDetailCostView.swift
  - apps/ios/BuyLedgerUITests/Support/XCUIApplication+Scrolling.swift
  - apps/ios/BuyLedgerTests/Features/Campaigns/CampaignIntegrationTests.swift
  - apps/ios/BuyLedger/Features/Settings/Presentation/Root/SettingsView.swift
  - apps/ios/BuyLedgerTests/Features/Campaigns/CampaignFeaturePresentationTests.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotInsightsTests/insightsTrendCard_393點寬最大輔助字級_走勢軸標不重疊.1.png
  - apps/ios/BuyLedger/Features/Dashboard/Presentation/Root/Views/DashboardView.swift
  - apps/ios/BuyLedgerUITests/Tests/More/LookupManagementTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/Filters/OrderCategoryPickerLargeTests.swift
  - apps/ios/BuyLedger/Features/More/Presentation/Root/MoreView.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/Filters/OrderCategoryPickerTests.swift
  - apps/ios/BuyLedgerTests/Guards/InputFieldConventionScanTests.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/Root/Plans/OrdersContainerPlan+Writes.swift
  - apps/ios/BuyLedger/Features/Lookups/Presentation/PaymentMethodEditForm/PaymentMethodEditFormFeature.swift
  - apps/ios/BuyLedgerTests/Features/Lookups/LookupManagementFeaturePaymentMethodCorrectionTests.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersFeatureDetailTests.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotInsightsTests/insightsView_載入中_顯示載入骨架.1.png
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Pickers/OptionPickerSheet.swift
  - apps/ios/BuyLedgerTests/Features/Campaigns/CampaignFeatureReloadDeleteTests.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/OrderDetail/Views/OrderDetailItemsView.swift
  - apps/ios/BuyLedgerUITests/Screens/Dashboard/DashboardScreen.swift
  - apps/ios/BuyLedgerUITests/Support/Assertions/Waiting.swift
  - apps/ios/BuyLedgerUITests/Support/XCTestCase+PlatformScope.swift
  - apps/ios/BuyLedgerUITests/Screens/More/SettingsScreen.swift
  - apps/ios/BuyLedger/Features/Lookups/Presentation/Root/Views/LookupItemList.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/OrderList/Operations/OrderListInteraction.swift
  - apps/ios/BuyLedgerUITests/Support/XCUIApplication+StableVisibleFrame.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/Edit/KeyboardDismissTests.swift
  - apps/ios/BuyLedgerUITests/Support/Assertions/ValueParsing.swift
  - apps/ios/BuyLedgerTests/Guards/LayerBoundary/LayerBoundaryTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Forms/ToolsInputFocusUITests.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/OrderDetail/Views/OrderDetailView.swift
  - apps/ios/BuyLedgerUITests/Support/Launch/BLUITestCase.swift
  - apps/ios/BuyLedgerUITests/Support/BoundsCheck.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrderMergeFeatureTests.swift
  - apps/ios/BuyLedger/Features/App/Presentation/Root/RootSidebarLayout.swift
  - apps/ios/BuyLedgerUITests/Tests/Tools/SettingsGoalInputTests.swift
  - apps/ios/BuyLedgerUITests/Screens/Orders/OrderFilterSheetScreen.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotOrdersTests/ordersView_寬版清單欄多選模式_顯示選取列.1.png
  - apps/ios/BuyLedgerUITests/Tests/Tools/QuoteTests.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/OrderList/Operations/OrdersFilterOperations.swift
  - apps/ios/BuyLedgerTests/Features/App/RootFeatureDetailNavigationTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/Regular/OrderRegularAccessibilitySizeTests.swift
  - apps/ios/BuyLedgerUITests/Support/Layout/PlatformScope.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/Regular/OrderRegularSearchBarTests.swift
  - apps/ios/BuyLedgerUITests/Support/XCUIElement+FocusTap.swift
  - apps/ios/BuyLedger/Features/Campaigns/Presentation/CampaignEdit/CampaignEditNotesSection.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/Components/OrderCategoryFilterRows.swift
  - apps/ios/BuyLedgerTests/Features/Quote/QuoteFeatureTests.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/SnapshotOrdersTests.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/Root/Requests/OrderRequestPlan.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotInsightsTests/insightsView_寬版_並排顯示類別排行與成本結構.1.png
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersFeatureFilterPathTests.swift
  - apps/ios/BuyLedgerTests/Features/Orders/OrdersFeatureDateRefreshTests.swift
  - apps/ios/BuyLedgerTests/SnapshotTests/SnapshotToolsTests.swift
  - apps/ios/BuyLedger/Features/Insights/Presentation/Root/Views/InsightsView.swift
  - apps/ios/BuyLedgerTests/Features/App/RootFeatureForegroundTests.swift
  - apps/ios/BuyLedgerUITests/Support/CampaignSeedFixture.swift
  - apps/ios/BuyLedgerUITests/Support/Launch/AppNavigator.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/Root/OrdersFeature.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/OrderEdit/Views/OrderEditDecimalField.swift
  - apps/ios/BuyLedger/Features/Orders/Presentation/Root/Views/OrdersRegularListColumn.swift
  - apps/ios/BuyLedgerTests/Features/Campaigns/CampaignListFeatureInteractionsTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Forms/EditorTextInputFocusUITests.swift
-->