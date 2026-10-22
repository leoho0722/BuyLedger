# progress-indicator Specification

## Purpose

Defines how a progress indicator with a title and a current value is presented and announced, so that every render shows the title, assistive technologies read the title followed by the current value, and bar-only progress indicators keep their compact appearance.

## Requirements

### Requirement: A labeled progress indicator renders its title on every render

A progress indicator that the caller gives a title SHALL draw that title, its current value text and its progress bar together on every render, including off-screen snapshot rendering performed while the full snapshot test class runs as one batch. Whether the title appears SHALL NOT depend on which other views were rendered earlier in the same process. A progress indicator without a title or current value SHALL draw only its progress bar, with no empty label row above it.

#### Scenario: Batch snapshot run draws every progress title

- **GIVEN** the full snapshot test class runs as one batch on the reference simulator
- **WHEN** a screen containing labeled progress indicators is rendered and compared with its approved baseline
- **THEN** every progress title in the rendered image matches the baseline and the comparison passes without re-running the test alone

##### Example: snapshots whose progress titles went missing in batch runs before the fix

| Snapshot test | Labeled progress indicators on screen |
| --- | --- |
| `campaignListView_依月分組_符合基準圖` | campaign rows with 到貨 and 收款 progress |
| `campaignListView_依日分組含今天與昨天_符合基準圖` | campaign rows with 到貨 and 收款 progress |
| `dashboardView_含進行中開團_顯示進行中的開團區段` | ongoing campaign rows with 到貨 and 收款 progress |
| `quoteView_非零試算輸入_顯示成本與建議售價` | cost breakdown rows, one per cost component |
| `campaignListView_依年分組_符合基準圖` | campaign rows with 到貨 and 收款 progress |

Which of these tests lost a title before the fix varied with the simulator state, while a given state reproduced the same missing title on every run; every snapshot that contains a labeled progress indicator is therefore covered by this scenario.

#### Scenario: Bar-only progress keeps a single bar

- **WHEN** a progress indicator is created with a value but without a title or current value, such as the dashboard monthly goal bar and the insights category ranking bar
- **THEN** it draws only the progress bar, and the rendered image is identical to the approved baseline

##### Example: bar-only progress indicators and the snapshots that show them

| Bar-only progress indicator | Snapshot test that renders it |
| --- | --- |
| dashboard monthly goal bar in the hero card | `dashboardView_一般儀表板資料_符合基準圖` |
| insights category ranking bar | `insightsView_一般洞察資料_符合基準圖` |


<!-- @trace
source: order-detail-single-layout
updated: 2026-10-22
code:
  - apps/ios/BuyLedger/Features/Orders/OrderCostBreakdown.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderDetailContentView.swift
  - apps/ios/CLAUDE.md
  - apps/ios/BuyLedger/Features/Orders/Components/OrderCompactDetailView.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersRegularDetailColumn.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrdersBaseline/ordersRegularDetailColumn_寬版詳情欄選取含成本明細訂單_符合基準圖.1.png
  - apps/ios/BuyLedger.xcodeproj/project.pbxproj
  - apps/ios/BuyLedger/Features/Orders/Components/OrderDetailNotesView.swift
  - apps/ios/README.md
  - apps/ios/BuyLedger/Features/Orders/Components/OrderDetailItemsView.swift
  - apps/ios/BuyLedgerTests/SnapshotTests+OrdersBaseline.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderDetailCostView.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersCompactView.swift
  - apps/ios/BuyLedgerTests/ActionGroupingScanTests.swift
  - apps/ios/BuyLedgerTests/OrderCostBreakdownTests.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderDetailView.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderDetailSummaryView.swift
-->

---
### Requirement: A labeled progress indicator is announced as its title followed by its current value

A labeled progress indicator SHALL expose its title and its current value text to assistive technologies, in that order, so that a container that combines its children reads the title immediately followed by the current value. The title SHALL be presented in the app language selected in settings, while the current value text SHALL be read as displayed.

#### Scenario: Campaign row reads each progress title followed by its value

- **GIVEN** the app is launched with the seeded campaigns and orders and the default reference date, in Traditional Chinese
- **WHEN** the campaigns tab lists the April Korea campaign
- **THEN** the row's accessibility label contains `到貨、0/3、收款、$11,800`

#### Scenario: Progress titles follow the app language

- **GIVEN** the same seeded data with the app language set to English
- **WHEN** the campaigns tab lists the April Korea campaign
- **THEN** the row's accessibility label contains the English titles `Arrived` and `Payment`, each followed by its current value text

<!-- @trace
source: progress-title-render-reliability
updated: 2026-10-06
code:
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Progress/BLProgressView.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Progress/BLProgressViewStyle.swift
  - apps/ios/BuyLedgerTests/SnapshotTests+Dashboard.swift
  - apps/ios/BuyLedgerUITests/Tests/Campaigns/CampaignProgressAccessibilityTests.swift
-->