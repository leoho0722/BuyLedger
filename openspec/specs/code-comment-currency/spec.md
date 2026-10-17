# code-comment-currency Specification

## Purpose

本規格涵蓋程式碼註解時效性的稽核範圍，包括描述的機制或理由不再成立時的改寫或移除、產生檔註解僅回報不編輯、稽核範圍限於內容時效而非風格。不涵蓋 `documentation-currency` 所訂的專案文件 (README、CLAUDE.md 等) 時效性稽核，兩者稽核對象不同。

## Requirements

### Requirement: Comments do not describe mechanisms or rationale that no longer hold

A code comment SHALL NOT state a rationale, constraint, or mechanism that the current implementation contradicts. When a change removes or replaces something a comment explains, that comment SHALL be rewritten or removed, including comments in files the change did not otherwise modify.

A comment describing an intent the implementation does not fulfill SHALL be resolved by first determining which side is wrong. Where the implementation is to be corrected, that work belongs to the change owning it and SHALL NOT be performed here. Where the implementation is deliberately staying as it is, the comment SHALL be rewritten to describe what the code actually does, and the decision it defers to SHALL be identifiable.

#### Scenario: Rationale for a removed mechanism is not left standing

- **WHEN** a comment explains why a particular approach was chosen, and that approach has since been replaced
- **THEN** the comment is rewritten to reflect the current approach, or removed together with the construct it explained

#### Scenario: Comment describing unfulfilled intent is corrected

- **WHEN** a comment describes a layout or behavior the implementation does not produce, and the implementation is deliberately unchanged
- **THEN** the comment is rewritten to describe the actual behavior, rather than left stating the unachieved intent

#### Scenario: Implementation corrections are not made here

- **WHEN** a comment and its implementation disagree and the implementation is the side requiring correction
- **THEN** the discrepancy is recorded for the owning change and neither the implementation nor the comment is altered here


<!-- @trace
source: documentation-consistency-audit
updated: 2026-07-23
code:
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneNeutralOnIndicator.colorset/Contents.json
  - apps/ios/BuyLedgerTests/CampaignReminderFailureTests.swift
  - apps/ios/BuyLedgerTests/OrdersLoadStateTests.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignListView.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/TextFields/BLSearchField.swift
  - apps/ios/BuyLedgerUITests/KeyboardDismissTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/SegmentedControls/BLSegmentedControl.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OptionPickerSheet.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignFeature.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderDetailCostBreakdownBaseline.1.png
  - apps/ios/BuyLedgerTests/OrdersSearchCancellationTests.swift
  - apps/ios/BuyLedger/Features/Orders/Components/MergePhotoPickerSheet.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderRowView.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Progress/BLProgressBar.swift
  - apps/ios/BuyLedger/Features/More/MoreView.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderDetailView.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel3Background.colorset/Contents.json
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFilterSheet.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneDestructiveSoftBackground.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneWarningOnIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/TextFields/BLAmountField.swift
  - apps/ios/BuyLedgerUITests/PhotoViewerPagingTests.swift
  - apps/ios/BuyLedger/Features/App/RootSidebarLayout.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLTone.swift
  - apps/ios/CLAUDE.md
  - apps/ios/BuyLedger/Features/Settings/SettingsSnapshot.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsView.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneInformativeOnIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Localizable.xcstrings
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneAccentIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneInformativeSurfaceText.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoThumbnail.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoViewer.swift
  - apps/ios/BuyLedger/Features/FX/FxFeature.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardView.swift
  - apps/ios/BuyLedger/Features/App/RootFeature.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneAccentSoftBackground.colorset/Contents.json
  - apps/ios/BuyLedger/Features/Orders/OrdersView.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersCompactView.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneSuccessOnIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneSuccessSurfaceText.colorset/Contents.json
  - apps/ios/BuyLedger.xcodeproj/xcshareddata/xcschemes/BuyLedgerUITests.xcscheme
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel3Numeral.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Chips/BLFilterChip.swift
  - apps/ios/BuyLedger/Features/FX/FxView.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewBaseline.1.png
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift
  - apps/ios/BuyLedger/Shared/Keyboard/KeyboardDismissOnTap.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeroGradientStart.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Status/BLStatusPill.swift
  - apps/ios/BuyLedgerTests/ColorContrastTests.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupNameEditorSheet.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeroGradientEnd.colorset/Contents.json
  - apps/ios/BuyLedger/Features/AISummary/AISummaryFeature.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel4Background.colorset/Contents.json
  - apps/ios/BuyLedgerTests/OrderEditFeatureTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Cards/BLCard.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel5Numeral.colorset/Contents.json
  - apps/ios/BuyLedgerTests/AISummaryFeatureTests.swift
  - apps/ios/README.md
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLRankBadgeFirstBackground.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLMetrics.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderStatus+Presentation.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel2Background.colorset/Contents.json
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementDestination.swift
  - apps/ios/BuyLedger/Features/App/RootView.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignDetailView.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/States/DelayedProgressView.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneNeutralSurfaceText.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneWarningIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/States/BLLoadFailureView.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneAccentSurfaceText.colorset/Contents.json
  - apps/ios/BuyLedger/Features/Customers/CustomersView.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsStats.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersFeature.swift
  - apps/ios/BuyLedgerTests/ContrastComplianceTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLBarChart.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignEditView.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLDonutSegment.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneWarningSurfaceText.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneNeutralIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Avatar/BLAvatar.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewMergeContextBaseline.1.png
  - apps/ios/BuyLedger/Features/Campaigns/CampaignEditFeature.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLDonutChart.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneInformativeIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Features/Settings/SettingsStorage.swift
  - apps/ios/BuyLedgerTests/CampaignFeatureTests.swift
  - apps/ios/BuyLedgerTests/LookupManagementFeatureTests.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel1Numeral.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneDestructiveSurfaceText.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLBarChartValue.swift
  - apps/ios/BuyLedgerTests/OrderEditFocusTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Buttons/BLButtonStyle.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel4Numeral.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel1Background.colorset/Contents.json
  - apps/ios/BuyLedger/Features/Orders/OrderEditFeature.swift
  - apps/ios/BuyLedger/Features/Quote/QuoteFeature.swift
  - apps/ios/BuyLedgerTests/InsightsStatsTests.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneSuccessIndicator.colorset/Contents.json
  - apps/ios/BuyLedgerTests/SettingsFeatureTests.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementView.swift
  - apps/ios/BuyLedgerTests/ColorContrast.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsView.swift
  - apps/ios/BuyLedger.xcodeproj/xcshareddata/xcschemes/BuyLedger.xcscheme
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/ViewModifiers/BLTypographyModifier.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel5Background.colorset/Contents.json
  - apps/ios/BuyLedger/Features/Customers/CustomerRankBadgeStyle.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneWarningSoftBackground.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneDestructiveIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLSparkline.swift
  - apps/ios/BuyLedger/Features/Settings/AppearancePreference.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsFeature.swift
  - apps/ios/BuyLedger/Shared/Extensions/Bundle+Extensions.swift
  - apps/ios/BuyLedger/Features/Orders/OrderEditView.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/insightsViewBaseline.1.png
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel2Numeral.colorset/Contents.json
  - apps/ios/BuyLedgerTests/SnapshotTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/dashboardViewBaseline.1.png
  - apps/ios/BuyLedger.xcodeproj/project.pbxproj
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneDestructiveOnIndicator.colorset/Contents.json
  - apps/ios/BuyLedgerTests/RootFeatureTests.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneAccentOnIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Core/Dependencies/OpenSettingsClient.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneSuccessSoftBackground.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneNeutralSoftBackground.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLHeatmapDepth.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Lists/BLListRow.swift
  - apps/ios/BuyLedger/Features/Quote/QuoteView.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewBaseline.1.png
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneInformativeSoftBackground.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLPalette.swift
  - apps/ios/BuyLedger/Features/Orders/Components/PaymentMethodEditorSheet.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewLongContentBaseline.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/blBarChartThirtyDaysBaseline.1.png
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Badges/BLBadge.swift
-->

---
### Requirement: Comment auditing is limited to currency, not style

Comment auditing under this capability SHALL assess only whether a comment's content still holds. Language, terminal punctuation, bracket form, spacing, and conciseness SHALL NOT be assessed here, because a dedicated style gate already reviews those against each change's modified files.

This audit covers what that gate structurally cannot see: comments in files no change modified, which have become false because of changes elsewhere.

#### Scenario: Style issues are left to the style gate

- **WHEN** a comment is encountered whose content still holds but whose formatting departs from project conventions
- **THEN** it is left unmodified by this audit

#### Scenario: Unmodified files are still covered

- **WHEN** a comment resides in a file that no recent change modified
- **THEN** it is still assessed for whether its content still holds


<!-- @trace
source: documentation-consistency-audit
updated: 2026-07-23
code:
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneNeutralOnIndicator.colorset/Contents.json
  - apps/ios/BuyLedgerTests/CampaignReminderFailureTests.swift
  - apps/ios/BuyLedgerTests/OrdersLoadStateTests.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignListView.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/TextFields/BLSearchField.swift
  - apps/ios/BuyLedgerUITests/KeyboardDismissTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/SegmentedControls/BLSegmentedControl.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OptionPickerSheet.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignFeature.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderDetailCostBreakdownBaseline.1.png
  - apps/ios/BuyLedgerTests/OrdersSearchCancellationTests.swift
  - apps/ios/BuyLedger/Features/Orders/Components/MergePhotoPickerSheet.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderRowView.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Progress/BLProgressBar.swift
  - apps/ios/BuyLedger/Features/More/MoreView.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderDetailView.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel3Background.colorset/Contents.json
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFilterSheet.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneDestructiveSoftBackground.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneWarningOnIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/TextFields/BLAmountField.swift
  - apps/ios/BuyLedgerUITests/PhotoViewerPagingTests.swift
  - apps/ios/BuyLedger/Features/App/RootSidebarLayout.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLTone.swift
  - apps/ios/CLAUDE.md
  - apps/ios/BuyLedger/Features/Settings/SettingsSnapshot.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsView.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneInformativeOnIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Localizable.xcstrings
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneAccentIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneInformativeSurfaceText.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoThumbnail.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoViewer.swift
  - apps/ios/BuyLedger/Features/FX/FxFeature.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardView.swift
  - apps/ios/BuyLedger/Features/App/RootFeature.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneAccentSoftBackground.colorset/Contents.json
  - apps/ios/BuyLedger/Features/Orders/OrdersView.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersCompactView.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneSuccessOnIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneSuccessSurfaceText.colorset/Contents.json
  - apps/ios/BuyLedger.xcodeproj/xcshareddata/xcschemes/BuyLedgerUITests.xcscheme
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel3Numeral.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Chips/BLFilterChip.swift
  - apps/ios/BuyLedger/Features/FX/FxView.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewBaseline.1.png
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift
  - apps/ios/BuyLedger/Shared/Keyboard/KeyboardDismissOnTap.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeroGradientStart.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Status/BLStatusPill.swift
  - apps/ios/BuyLedgerTests/ColorContrastTests.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupNameEditorSheet.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeroGradientEnd.colorset/Contents.json
  - apps/ios/BuyLedger/Features/AISummary/AISummaryFeature.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel4Background.colorset/Contents.json
  - apps/ios/BuyLedgerTests/OrderEditFeatureTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Cards/BLCard.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel5Numeral.colorset/Contents.json
  - apps/ios/BuyLedgerTests/AISummaryFeatureTests.swift
  - apps/ios/README.md
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLRankBadgeFirstBackground.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLMetrics.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderStatus+Presentation.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel2Background.colorset/Contents.json
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementDestination.swift
  - apps/ios/BuyLedger/Features/App/RootView.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignDetailView.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/States/DelayedProgressView.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneNeutralSurfaceText.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneWarningIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/States/BLLoadFailureView.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneAccentSurfaceText.colorset/Contents.json
  - apps/ios/BuyLedger/Features/Customers/CustomersView.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsStats.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersFeature.swift
  - apps/ios/BuyLedgerTests/ContrastComplianceTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLBarChart.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignEditView.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLDonutSegment.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneWarningSurfaceText.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneNeutralIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Avatar/BLAvatar.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewMergeContextBaseline.1.png
  - apps/ios/BuyLedger/Features/Campaigns/CampaignEditFeature.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLDonutChart.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneInformativeIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Features/Settings/SettingsStorage.swift
  - apps/ios/BuyLedgerTests/CampaignFeatureTests.swift
  - apps/ios/BuyLedgerTests/LookupManagementFeatureTests.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel1Numeral.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneDestructiveSurfaceText.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLBarChartValue.swift
  - apps/ios/BuyLedgerTests/OrderEditFocusTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Buttons/BLButtonStyle.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel4Numeral.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel1Background.colorset/Contents.json
  - apps/ios/BuyLedger/Features/Orders/OrderEditFeature.swift
  - apps/ios/BuyLedger/Features/Quote/QuoteFeature.swift
  - apps/ios/BuyLedgerTests/InsightsStatsTests.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneSuccessIndicator.colorset/Contents.json
  - apps/ios/BuyLedgerTests/SettingsFeatureTests.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementView.swift
  - apps/ios/BuyLedgerTests/ColorContrast.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsView.swift
  - apps/ios/BuyLedger.xcodeproj/xcshareddata/xcschemes/BuyLedger.xcscheme
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/ViewModifiers/BLTypographyModifier.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel5Background.colorset/Contents.json
  - apps/ios/BuyLedger/Features/Customers/CustomerRankBadgeStyle.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneWarningSoftBackground.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneDestructiveIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLSparkline.swift
  - apps/ios/BuyLedger/Features/Settings/AppearancePreference.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsFeature.swift
  - apps/ios/BuyLedger/Shared/Extensions/Bundle+Extensions.swift
  - apps/ios/BuyLedger/Features/Orders/OrderEditView.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/insightsViewBaseline.1.png
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel2Numeral.colorset/Contents.json
  - apps/ios/BuyLedgerTests/SnapshotTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/dashboardViewBaseline.1.png
  - apps/ios/BuyLedger.xcodeproj/project.pbxproj
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneDestructiveOnIndicator.colorset/Contents.json
  - apps/ios/BuyLedgerTests/RootFeatureTests.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneAccentOnIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Core/Dependencies/OpenSettingsClient.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneSuccessSoftBackground.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneNeutralSoftBackground.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLHeatmapDepth.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Lists/BLListRow.swift
  - apps/ios/BuyLedger/Features/Quote/QuoteView.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewBaseline.1.png
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneInformativeSoftBackground.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLPalette.swift
  - apps/ios/BuyLedger/Features/Orders/Components/PaymentMethodEditorSheet.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewLongContentBaseline.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/blBarChartThirtyDaysBaseline.1.png
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Badges/BLBadge.swift
-->

---
### Requirement: Generated file comments are reported rather than edited

Comments in generated files SHALL NOT be edited directly. Generated files are produced by a generator, are held read-only on disk to prevent hand editing, and any direct edit would be lost on the next generation and would break the generated-versus-schema synchronization check. Problems found in generated comments SHALL be recorded as generator work items.

#### Scenario: Generated comment problem is recorded

- **WHEN** the audit finds a comment problem inside a generated file
- **THEN** it is recorded as a generator work item and the generated file is left unmodified

#### Scenario: Generated files remain synchronized

- **WHEN** the audit completes
- **THEN** the generated-versus-schema synchronization check still passes, because no generated file was hand edited


<!-- @trace
source: documentation-consistency-audit
updated: 2026-07-23
code:
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneNeutralOnIndicator.colorset/Contents.json
  - apps/ios/BuyLedgerTests/CampaignReminderFailureTests.swift
  - apps/ios/BuyLedgerTests/OrdersLoadStateTests.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignListView.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/TextFields/BLSearchField.swift
  - apps/ios/BuyLedgerUITests/KeyboardDismissTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/SegmentedControls/BLSegmentedControl.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OptionPickerSheet.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignFeature.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderDetailCostBreakdownBaseline.1.png
  - apps/ios/BuyLedgerTests/OrdersSearchCancellationTests.swift
  - apps/ios/BuyLedger/Features/Orders/Components/MergePhotoPickerSheet.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderRowView.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Progress/BLProgressBar.swift
  - apps/ios/BuyLedger/Features/More/MoreView.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderDetailView.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel3Background.colorset/Contents.json
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFilterSheet.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneDestructiveSoftBackground.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneWarningOnIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/TextFields/BLAmountField.swift
  - apps/ios/BuyLedgerUITests/PhotoViewerPagingTests.swift
  - apps/ios/BuyLedger/Features/App/RootSidebarLayout.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLTone.swift
  - apps/ios/CLAUDE.md
  - apps/ios/BuyLedger/Features/Settings/SettingsSnapshot.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsView.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneInformativeOnIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Localizable.xcstrings
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneAccentIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneInformativeSurfaceText.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoThumbnail.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoViewer.swift
  - apps/ios/BuyLedger/Features/FX/FxFeature.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardView.swift
  - apps/ios/BuyLedger/Features/App/RootFeature.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneAccentSoftBackground.colorset/Contents.json
  - apps/ios/BuyLedger/Features/Orders/OrdersView.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersCompactView.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneSuccessOnIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneSuccessSurfaceText.colorset/Contents.json
  - apps/ios/BuyLedger.xcodeproj/xcshareddata/xcschemes/BuyLedgerUITests.xcscheme
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel3Numeral.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Chips/BLFilterChip.swift
  - apps/ios/BuyLedger/Features/FX/FxView.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewBaseline.1.png
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift
  - apps/ios/BuyLedger/Shared/Keyboard/KeyboardDismissOnTap.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeroGradientStart.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Status/BLStatusPill.swift
  - apps/ios/BuyLedgerTests/ColorContrastTests.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupNameEditorSheet.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeroGradientEnd.colorset/Contents.json
  - apps/ios/BuyLedger/Features/AISummary/AISummaryFeature.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel4Background.colorset/Contents.json
  - apps/ios/BuyLedgerTests/OrderEditFeatureTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Cards/BLCard.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel5Numeral.colorset/Contents.json
  - apps/ios/BuyLedgerTests/AISummaryFeatureTests.swift
  - apps/ios/README.md
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLRankBadgeFirstBackground.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLMetrics.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderStatus+Presentation.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel2Background.colorset/Contents.json
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementDestination.swift
  - apps/ios/BuyLedger/Features/App/RootView.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignDetailView.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/States/DelayedProgressView.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneNeutralSurfaceText.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneWarningIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/States/BLLoadFailureView.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneAccentSurfaceText.colorset/Contents.json
  - apps/ios/BuyLedger/Features/Customers/CustomersView.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsStats.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersFeature.swift
  - apps/ios/BuyLedgerTests/ContrastComplianceTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLBarChart.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignEditView.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLDonutSegment.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneWarningSurfaceText.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneNeutralIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Avatar/BLAvatar.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewMergeContextBaseline.1.png
  - apps/ios/BuyLedger/Features/Campaigns/CampaignEditFeature.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLDonutChart.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneInformativeIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Features/Settings/SettingsStorage.swift
  - apps/ios/BuyLedgerTests/CampaignFeatureTests.swift
  - apps/ios/BuyLedgerTests/LookupManagementFeatureTests.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel1Numeral.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneDestructiveSurfaceText.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLBarChartValue.swift
  - apps/ios/BuyLedgerTests/OrderEditFocusTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Buttons/BLButtonStyle.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel4Numeral.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel1Background.colorset/Contents.json
  - apps/ios/BuyLedger/Features/Orders/OrderEditFeature.swift
  - apps/ios/BuyLedger/Features/Quote/QuoteFeature.swift
  - apps/ios/BuyLedgerTests/InsightsStatsTests.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneSuccessIndicator.colorset/Contents.json
  - apps/ios/BuyLedgerTests/SettingsFeatureTests.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementView.swift
  - apps/ios/BuyLedgerTests/ColorContrast.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsView.swift
  - apps/ios/BuyLedger.xcodeproj/xcshareddata/xcschemes/BuyLedger.xcscheme
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/ViewModifiers/BLTypographyModifier.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel5Background.colorset/Contents.json
  - apps/ios/BuyLedger/Features/Customers/CustomerRankBadgeStyle.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneWarningSoftBackground.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneDestructiveIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLSparkline.swift
  - apps/ios/BuyLedger/Features/Settings/AppearancePreference.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsFeature.swift
  - apps/ios/BuyLedger/Shared/Extensions/Bundle+Extensions.swift
  - apps/ios/BuyLedger/Features/Orders/OrderEditView.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/insightsViewBaseline.1.png
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel2Numeral.colorset/Contents.json
  - apps/ios/BuyLedgerTests/SnapshotTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/dashboardViewBaseline.1.png
  - apps/ios/BuyLedger.xcodeproj/project.pbxproj
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneDestructiveOnIndicator.colorset/Contents.json
  - apps/ios/BuyLedgerTests/RootFeatureTests.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneAccentOnIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Core/Dependencies/OpenSettingsClient.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneSuccessSoftBackground.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneNeutralSoftBackground.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLHeatmapDepth.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Lists/BLListRow.swift
  - apps/ios/BuyLedger/Features/Quote/QuoteView.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewBaseline.1.png
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneInformativeSoftBackground.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLPalette.swift
  - apps/ios/BuyLedger/Features/Orders/Components/PaymentMethodEditorSheet.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewLongContentBaseline.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/blBarChartThirtyDaysBaseline.1.png
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Badges/BLBadge.swift
-->

---
### Requirement: Comment edits change no executable code

Changes made under this capability SHALL affect comment text only. No executable statement, declaration, or annotation SHALL be altered. This SHALL be verified by inspecting the diff rather than asserted.

#### Scenario: Diff contains only comment lines

- **WHEN** the source changes made by this audit are inspected
- **THEN** every changed line is a comment line

#### Scenario: Project still builds

- **WHEN** the audit's source changes are complete
- **THEN** the project builds for both supported platform targets


<!-- @trace
source: documentation-consistency-audit
updated: 2026-07-23
code:
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneNeutralOnIndicator.colorset/Contents.json
  - apps/ios/BuyLedgerTests/CampaignReminderFailureTests.swift
  - apps/ios/BuyLedgerTests/OrdersLoadStateTests.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignListView.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/TextFields/BLSearchField.swift
  - apps/ios/BuyLedgerUITests/KeyboardDismissTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/SegmentedControls/BLSegmentedControl.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OptionPickerSheet.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignFeature.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderDetailCostBreakdownBaseline.1.png
  - apps/ios/BuyLedgerTests/OrdersSearchCancellationTests.swift
  - apps/ios/BuyLedger/Features/Orders/Components/MergePhotoPickerSheet.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderRowView.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Progress/BLProgressBar.swift
  - apps/ios/BuyLedger/Features/More/MoreView.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderDetailView.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel3Background.colorset/Contents.json
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFilterSheet.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneDestructiveSoftBackground.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneWarningOnIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/TextFields/BLAmountField.swift
  - apps/ios/BuyLedgerUITests/PhotoViewerPagingTests.swift
  - apps/ios/BuyLedger/Features/App/RootSidebarLayout.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLTone.swift
  - apps/ios/CLAUDE.md
  - apps/ios/BuyLedger/Features/Settings/SettingsSnapshot.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsView.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneInformativeOnIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Localizable.xcstrings
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneAccentIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneInformativeSurfaceText.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoThumbnail.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoViewer.swift
  - apps/ios/BuyLedger/Features/FX/FxFeature.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardView.swift
  - apps/ios/BuyLedger/Features/App/RootFeature.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneAccentSoftBackground.colorset/Contents.json
  - apps/ios/BuyLedger/Features/Orders/OrdersView.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersCompactView.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneSuccessOnIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneSuccessSurfaceText.colorset/Contents.json
  - apps/ios/BuyLedger.xcodeproj/xcshareddata/xcschemes/BuyLedgerUITests.xcscheme
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel3Numeral.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Chips/BLFilterChip.swift
  - apps/ios/BuyLedger/Features/FX/FxView.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewBaseline.1.png
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift
  - apps/ios/BuyLedger/Shared/Keyboard/KeyboardDismissOnTap.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeroGradientStart.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Status/BLStatusPill.swift
  - apps/ios/BuyLedgerTests/ColorContrastTests.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupNameEditorSheet.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeroGradientEnd.colorset/Contents.json
  - apps/ios/BuyLedger/Features/AISummary/AISummaryFeature.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel4Background.colorset/Contents.json
  - apps/ios/BuyLedgerTests/OrderEditFeatureTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Cards/BLCard.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel5Numeral.colorset/Contents.json
  - apps/ios/BuyLedgerTests/AISummaryFeatureTests.swift
  - apps/ios/README.md
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLRankBadgeFirstBackground.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLMetrics.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderStatus+Presentation.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel2Background.colorset/Contents.json
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementDestination.swift
  - apps/ios/BuyLedger/Features/App/RootView.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignDetailView.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/States/DelayedProgressView.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneNeutralSurfaceText.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneWarningIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/States/BLLoadFailureView.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneAccentSurfaceText.colorset/Contents.json
  - apps/ios/BuyLedger/Features/Customers/CustomersView.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsStats.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersFeature.swift
  - apps/ios/BuyLedgerTests/ContrastComplianceTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLBarChart.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignEditView.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLDonutSegment.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneWarningSurfaceText.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneNeutralIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Avatar/BLAvatar.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewMergeContextBaseline.1.png
  - apps/ios/BuyLedger/Features/Campaigns/CampaignEditFeature.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLDonutChart.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneInformativeIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Features/Settings/SettingsStorage.swift
  - apps/ios/BuyLedgerTests/CampaignFeatureTests.swift
  - apps/ios/BuyLedgerTests/LookupManagementFeatureTests.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel1Numeral.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneDestructiveSurfaceText.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLBarChartValue.swift
  - apps/ios/BuyLedgerTests/OrderEditFocusTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Buttons/BLButtonStyle.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel4Numeral.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel1Background.colorset/Contents.json
  - apps/ios/BuyLedger/Features/Orders/OrderEditFeature.swift
  - apps/ios/BuyLedger/Features/Quote/QuoteFeature.swift
  - apps/ios/BuyLedgerTests/InsightsStatsTests.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneSuccessIndicator.colorset/Contents.json
  - apps/ios/BuyLedgerTests/SettingsFeatureTests.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementView.swift
  - apps/ios/BuyLedgerTests/ColorContrast.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsView.swift
  - apps/ios/BuyLedger.xcodeproj/xcshareddata/xcschemes/BuyLedger.xcscheme
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/ViewModifiers/BLTypographyModifier.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel5Background.colorset/Contents.json
  - apps/ios/BuyLedger/Features/Customers/CustomerRankBadgeStyle.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneWarningSoftBackground.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneDestructiveIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLSparkline.swift
  - apps/ios/BuyLedger/Features/Settings/AppearancePreference.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsFeature.swift
  - apps/ios/BuyLedger/Shared/Extensions/Bundle+Extensions.swift
  - apps/ios/BuyLedger/Features/Orders/OrderEditView.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/insightsViewBaseline.1.png
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel2Numeral.colorset/Contents.json
  - apps/ios/BuyLedgerTests/SnapshotTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/dashboardViewBaseline.1.png
  - apps/ios/BuyLedger.xcodeproj/project.pbxproj
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneDestructiveOnIndicator.colorset/Contents.json
  - apps/ios/BuyLedgerTests/RootFeatureTests.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneAccentOnIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Core/Dependencies/OpenSettingsClient.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneSuccessSoftBackground.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneNeutralSoftBackground.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLHeatmapDepth.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Lists/BLListRow.swift
  - apps/ios/BuyLedger/Features/Quote/QuoteView.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewBaseline.1.png
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneInformativeSoftBackground.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLPalette.swift
  - apps/ios/BuyLedger/Features/Orders/Components/PaymentMethodEditorSheet.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewLongContentBaseline.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/blBarChartThirtyDaysBaseline.1.png
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Badges/BLBadge.swift
-->

---
### Requirement: Widely applicable knowledge in comments is identified for promotion

Where a comment records knowledge whose applicability extends beyond the file it sits in — a pitfall confirmed by testing, or a constraint that now governs several call sites — the audit SHALL identify it and record whether it warrants promotion to a documented project rule. The audit SHALL NOT perform the promotion, because wording and placement within the documentation hierarchy are separate decisions.

#### Scenario: Cross-cutting pitfall is identified

- **WHEN** a comment records a pitfall that now applies to multiple call sites rather than only its own
- **THEN** it is recorded as a candidate for promotion to a project rule, and the comment itself is left in place

<!-- @trace
source: documentation-consistency-audit
updated: 2026-07-23
code:
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneNeutralOnIndicator.colorset/Contents.json
  - apps/ios/BuyLedgerTests/CampaignReminderFailureTests.swift
  - apps/ios/BuyLedgerTests/OrdersLoadStateTests.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignListView.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/TextFields/BLSearchField.swift
  - apps/ios/BuyLedgerUITests/KeyboardDismissTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/SegmentedControls/BLSegmentedControl.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OptionPickerSheet.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignFeature.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderDetailCostBreakdownBaseline.1.png
  - apps/ios/BuyLedgerTests/OrdersSearchCancellationTests.swift
  - apps/ios/BuyLedger/Features/Orders/Components/MergePhotoPickerSheet.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderRowView.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Progress/BLProgressBar.swift
  - apps/ios/BuyLedger/Features/More/MoreView.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderDetailView.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel3Background.colorset/Contents.json
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFilterSheet.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneDestructiveSoftBackground.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneWarningOnIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/TextFields/BLAmountField.swift
  - apps/ios/BuyLedgerUITests/PhotoViewerPagingTests.swift
  - apps/ios/BuyLedger/Features/App/RootSidebarLayout.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLTone.swift
  - apps/ios/CLAUDE.md
  - apps/ios/BuyLedger/Features/Settings/SettingsSnapshot.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsView.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneInformativeOnIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Localizable.xcstrings
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneAccentIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneInformativeSurfaceText.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoThumbnail.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoViewer.swift
  - apps/ios/BuyLedger/Features/FX/FxFeature.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardView.swift
  - apps/ios/BuyLedger/Features/App/RootFeature.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneAccentSoftBackground.colorset/Contents.json
  - apps/ios/BuyLedger/Features/Orders/OrdersView.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersCompactView.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneSuccessOnIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneSuccessSurfaceText.colorset/Contents.json
  - apps/ios/BuyLedger.xcodeproj/xcshareddata/xcschemes/BuyLedgerUITests.xcscheme
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel3Numeral.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Chips/BLFilterChip.swift
  - apps/ios/BuyLedger/Features/FX/FxView.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewBaseline.1.png
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift
  - apps/ios/BuyLedger/Shared/Keyboard/KeyboardDismissOnTap.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeroGradientStart.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Status/BLStatusPill.swift
  - apps/ios/BuyLedgerTests/ColorContrastTests.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupNameEditorSheet.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeroGradientEnd.colorset/Contents.json
  - apps/ios/BuyLedger/Features/AISummary/AISummaryFeature.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel4Background.colorset/Contents.json
  - apps/ios/BuyLedgerTests/OrderEditFeatureTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Cards/BLCard.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel5Numeral.colorset/Contents.json
  - apps/ios/BuyLedgerTests/AISummaryFeatureTests.swift
  - apps/ios/README.md
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLRankBadgeFirstBackground.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLMetrics.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderStatus+Presentation.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel2Background.colorset/Contents.json
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementDestination.swift
  - apps/ios/BuyLedger/Features/App/RootView.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignDetailView.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/States/DelayedProgressView.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneNeutralSurfaceText.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneWarningIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/States/BLLoadFailureView.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneAccentSurfaceText.colorset/Contents.json
  - apps/ios/BuyLedger/Features/Customers/CustomersView.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsStats.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersFeature.swift
  - apps/ios/BuyLedgerTests/ContrastComplianceTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLBarChart.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignEditView.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLDonutSegment.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneWarningSurfaceText.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneNeutralIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Avatar/BLAvatar.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewMergeContextBaseline.1.png
  - apps/ios/BuyLedger/Features/Campaigns/CampaignEditFeature.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLDonutChart.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneInformativeIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Features/Settings/SettingsStorage.swift
  - apps/ios/BuyLedgerTests/CampaignFeatureTests.swift
  - apps/ios/BuyLedgerTests/LookupManagementFeatureTests.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel1Numeral.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneDestructiveSurfaceText.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLBarChartValue.swift
  - apps/ios/BuyLedgerTests/OrderEditFocusTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Buttons/BLButtonStyle.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel4Numeral.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel1Background.colorset/Contents.json
  - apps/ios/BuyLedger/Features/Orders/OrderEditFeature.swift
  - apps/ios/BuyLedger/Features/Quote/QuoteFeature.swift
  - apps/ios/BuyLedgerTests/InsightsStatsTests.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneSuccessIndicator.colorset/Contents.json
  - apps/ios/BuyLedgerTests/SettingsFeatureTests.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementView.swift
  - apps/ios/BuyLedgerTests/ColorContrast.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsView.swift
  - apps/ios/BuyLedger.xcodeproj/xcshareddata/xcschemes/BuyLedger.xcscheme
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/ViewModifiers/BLTypographyModifier.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel5Background.colorset/Contents.json
  - apps/ios/BuyLedger/Features/Customers/CustomerRankBadgeStyle.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneWarningSoftBackground.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneDestructiveIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLSparkline.swift
  - apps/ios/BuyLedger/Features/Settings/AppearancePreference.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsFeature.swift
  - apps/ios/BuyLedger/Shared/Extensions/Bundle+Extensions.swift
  - apps/ios/BuyLedger/Features/Orders/OrderEditView.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/insightsViewBaseline.1.png
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLHeatmapLevel2Numeral.colorset/Contents.json
  - apps/ios/BuyLedgerTests/SnapshotTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/dashboardViewBaseline.1.png
  - apps/ios/BuyLedger.xcodeproj/project.pbxproj
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneDestructiveOnIndicator.colorset/Contents.json
  - apps/ios/BuyLedgerTests/RootFeatureTests.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneAccentOnIndicator.colorset/Contents.json
  - apps/ios/BuyLedger/Core/Dependencies/OpenSettingsClient.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneSuccessSoftBackground.colorset/Contents.json
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneNeutralSoftBackground.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLHeatmapDepth.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Lists/BLListRow.swift
  - apps/ios/BuyLedger/Features/Quote/QuoteView.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewBaseline.1.png
  - apps/ios/BuyLedger/Resources/Assets.xcassets/BLToneInformativeSoftBackground.colorset/Contents.json
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLPalette.swift
  - apps/ios/BuyLedger/Features/Orders/Components/PaymentMethodEditorSheet.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewLongContentBaseline.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/blBarChartThirtyDaysBaseline.1.png
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Badges/BLBadge.swift
-->