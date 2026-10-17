# adaptive-layout Specification

## Purpose

涵蓋 App 在 compact 版面 (底部分頁列、內容上下堆疊) 與 regular 版面 (側邊欄、內容並排) 之間的選擇規則、單一判斷入口，以及其他規格中用平台或尺寸分類措辭區分兩種版面時的對應方式。各版面內的畫面內容不在本規格範圍，例如訂單整合篩選表單由 `order-filter-sheet` 規範，字級調整由 `dynamic-type-adaptation` 規範。

## Requirements

### Requirement: The regular layout is used only when both size classes are regular

The app SHALL present one of two layouts on every screen that adapts to its window. In the regular layout the root navigation shows a sidebar, the orders list and the order detail are side by side, the dashboard places its key figures beside the hero card, and the insights category ranking and cost structure cards are side by side. In the compact layout the root navigation shows a bottom tab bar, the orders list is a single column whose detail is pushed, the dashboard places its key-figure grid below the hero card, and the insights category ranking and cost structure cards are stacked vertically. The app SHALL use the regular layout only when both the horizontal and the vertical size class of the window are regular. For every other combination, including an environment that provides no size class, the app SHALL use the compact layout. Rotating an iPhone of any model SHALL therefore keep the compact layout and only widen its content.

#### Scenario: Large iPhone rotated to landscape keeps the compact layout

- **GIVEN** an iPhone whose landscape orientation reports a regular horizontal size class and a compact vertical size class
- **WHEN** the user rotates the device from portrait to landscape
- **THEN** the root navigation keeps the bottom tab bar and shows no sidebar
- **AND** the orders tab shows the single-column orders list with the unified filter trigger and no side-by-side detail pane
- **AND** the dashboard keeps its key-figure grid below the hero card and the insights keeps its category ranking and cost structure cards stacked vertically

#### Scenario: iPad in full screen uses the regular layout in both orientations

- **GIVEN** an iPad running the app in full screen
- **WHEN** the app is displayed in portrait and then in landscape
- **THEN** the root navigation shows the sidebar in both orientations
- **AND** the orders tab shows the orders list and order detail side by side in both orientations

#### Scenario: A window whose size classes change switches layout accordingly

- **GIVEN** the app is displayed with a regular horizontal and a regular vertical size class
- **WHEN** either size class of the same window changes to compact and later back to regular
- **THEN** the screen switches to the compact layout while either size class is compact
- **AND** the screen returns to the regular layout once both size classes are regular again

##### Example: layout chosen for each size class combination

| Horizontal size class | Vertical size class | Layout | Typical window |
| --- | --- | --- | --- |
| compact | regular | compact | iPhone in portrait; narrow iPad multitasking window |
| regular | compact | compact | large iPhone in landscape; any window reporting a compact height |
| compact | compact | compact | standard iPhone in landscape |
| regular | regular | regular | iPad in full screen, either orientation |
| none provided | regular | compact | environment without a horizontal size class |
| regular | none provided | compact | environment without a vertical size class |


<!-- @trace
source: iphone-landscape-compact-layout
updated: 2026-10-06
code:
  - apps/ios/BuyLedgerTests/SnapshotTests+OrderDetail.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Insights/insightsView_寬版_並排顯示類別排行與成本結構.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Dashboard/dashboardView_含進行中開團_顯示進行中的開團區段.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrderEdit/orderEditView_一般既有訂單_符合基準圖.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Orders/ordersView_寬版多選模式_顯示選取列.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Dashboard/dashboardView_大尺寸iPhone橫向_KPI維持在hero下方.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Tools/fxView_匯率載入失敗_顯示錯誤橫幅與重試鍵.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactView_一般訂單清單_符合基準圖.1.png
  - apps/ios/BuyLedger/Features/Orders/OrdersView.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/persistenceFailureView_持久化錯誤_符合基準圖.1.png
  - apps/ios/BuyLedgerTests/SnapshotTests.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardKPITiles.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Orders/ordersView_大尺寸iPhone橫向_顯示單欄清單與整合篩選鈕.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/quoteView_沒有可用匯率_顯示錯誤狀態.1.png
  - apps/ios/BuyLedgerTests/SnapshotTests+Shared.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardRecentOrdersSection.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Insights/insightsView_一般洞察資料_符合基準圖.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Dashboard/dashboardView_寬版_並排顯示hero與KPI.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrderEdit/orderEditView_長訂單識別碼_顯示短識別碼.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/insightsView_一般洞察資料_符合基準圖.1.png
  - apps/ios/BuyLedger/Features/Insights/InsightsHeatmapCard.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsCostStructureCard.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Tools/fxView_已載入匯率快照_顯示連線狀態.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Shared/blBarChart_近三十天資料_捲動停在最新日期.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/fxView_匯率載入失敗_顯示錯誤橫幅與重試鍵.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Dashboard/dashboardView_一般儀表板資料_符合基準圖.1.png
  - apps/ios/BuyLedger/Features/Insights/InsightsCategoryCard.swift
  - apps/ios/BuyLedgerTests/SnapshotTests+OrderEdit.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/fxView_已載入匯率快照_顯示連線狀態.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Insights/insightsView_大尺寸iPhone橫向_類別排行與成本結構上下堆疊.1.png
  - apps/ios/BuyLedgerUITests/Tests/Smoke/OrientationLayoutTests.swift
  - apps/ios/BuyLedgerTests/SnapshotTests+Orders.swift
  - apps/ios/BuyLedgerTests/BLLayoutClassEnvironmentTests.swift
  - apps/ios/BuyLedgerTests/DesignSystemSourceScanTests+Lexer.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardSummarySection.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Tools/quoteView_沒有可用匯率_顯示錯誤狀態.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+CampaignDetail/campaignEditView_編輯既有開團_符合基準圖.1.png
  - apps/ios/BuyLedgerTests/SnapshotTests+Tools.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardView.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsView.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Tools/quoteView_非零試算輸入_顯示成本與建議售價.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderDetailView_成本明細內容_符合基準圖.1.png
  - apps/ios/BuyLedger/Features/Dashboard/DashboardOngoingCampaignsSection.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersView_寬版多選模式_顯示選取列.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Orders/ordersCompactView_一般訂單清單_符合基準圖.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/quoteView_非零試算輸入_顯示成本與建議售價.1.png
  - apps/ios/BuyLedger/Features/Insights/InsightsCampaignProfitCard.swift
  - apps/ios/BuyLedger/Features/App/RootView.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrderDetail/orderDetailView_成本明細內容_符合基準圖.1.png
  - apps/ios/BuyLedgerTests/DesignSystemSourceScanTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLLayoutClass.swift
  - apps/ios/BuyLedgerTests/DesignSystemSourceScanTests+Patterns.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Shared/persistenceFailureView_持久化錯誤_符合基準圖.1.png
  - apps/ios/BuyLedger/Features/Orders/OrdersRegularDetailColumn.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/dashboardView_一般儀表板資料_符合基準圖.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditView_長訂單識別碼_顯示短識別碼.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Orders/ordersCompactView_多選模式_顯示勾選與工具列.1.png
  - apps/ios/BuyLedgerTests/SnapshotTests+Insights.swift
  - apps/ios/CLAUDE.md
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/blBarChart_近三十天資料_捲動停在最新日期.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactView_長內容訂單清單_避免撐寬版面.1.png
  - apps/ios/README.md
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactView_多選模式_顯示勾選與工具列.1.png
  - apps/ios/BuyLedgerTests/DesignSystemSourceScanTests+Scanner.swift
  - apps/ios/BuyLedgerTests/BLLayoutClassTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditView_合併訂單情境_符合基準圖.1.png
  - apps/ios/BuyLedger/Features/Dashboard/DashboardHeroCard.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditView_一般既有訂單_符合基準圖.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrderEdit/orderEditView_合併訂單情境_符合基準圖.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Orders/ordersCompactView_長內容訂單清單_避免撐寬版面.1.png
  - apps/ios/BuyLedger/Features/Orders/OrdersRegularListColumn.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsTrendCard.swift
  - apps/ios/BuyLedgerTests/SnapshotTests+Dashboard.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardKPITile.swift
-->

---
### Requirement: Layout selection has a single entry point

Every screen that differs between the compact and the regular layout SHALL obtain the layout from one shared layout decision. Production code outside the shared decision's source file SHALL NOT reference the horizontal or the vertical size class, whether by reading it from the environment, writing it into the environment, or accessing it as a member. A source scan of the production code SHALL fail when such a reference appears outside the shared decision's source file in ordinary code, and a line-level scan exemption marker SHALL NOT exempt such a reference. The scan's guarantee SHALL be defined by the lexical forms the scan models: line comments, non-nested block comments, and single-line and multi-line string literals with backslash escapes, recognized by their Unicode scalars. Within that guarantee, a string literal whose content contains escaped backslashes, escaped quotes or a leading combining mark SHALL NOT hide a reference that follows the literal, and a block comment placed directly between a reference and the following token SHALL NOT hide that reference. Any other lexical form, including string interpolations, raw strings, extended string delimiters, regular expression literals and nested block comments, SHALL be documented as outside the scan's guarantee, together with the code that follows it; the policy against referencing the size classes outside the shared decision SHALL still apply to such code.

#### Scenario: A direct size class reference outside the shared decision fails the scan

- **GIVEN** a production view that reads the horizontal size class directly to choose its arrangement
- **WHEN** the source scan runs
- **THEN** the scan fails and names the file and line of the reference

#### Scenario: An exemption marker does not exempt a size class reference

- **GIVEN** a production view that reads the vertical size class directly on a line carrying a scan exemption marker with a non-empty reason
- **WHEN** the source scan runs
- **THEN** the scan still fails and names the file and line of the reference

#### Scenario: Screens read the shared decision

- **WHEN** the root navigation, the orders list, the dashboard and the insights choose their arrangement
- **THEN** each of them obtains the layout from the shared layout decision
- **AND** the source scan reports no size class reference outside the shared decision's source file

##### Example: arrangement chosen by each screen from the shared decision

| Screen | Compact layout | Regular layout |
| --- | --- | --- |
| Root navigation | bottom tab bar | sidebar |
| Orders | single-column list, detail pushed | list and detail side by side |
| Dashboard | key-figure grid below the hero card | key figures beside the hero card |
| Insights | category ranking and cost structure stacked | category ranking and cost structure side by side |

##### Example: references the source scan classifies

| Source line outside the shared decision | Scan result |
| --- | --- |
| `@Environment(\.horizontalSizeClass) private var horizontalSizeClass` | fails |
| `.environment(\.verticalSizeClass, .regular)` | fails |
| `horizontalSizeClass == .regular` inside an `EnvironmentValues` extension | fails |
| a size class read followed by `// design-system-scan-exempt: reason` | fails |
| `let pair = ("\\", horizontalSizeClass)` | fails |
| `let separator = "\\"` | passes |
| `horizontalSizeClass/* note */as Any` | fails |
| `/* horizontalSizeClass */` | passes |
| `"""` multi-line literal containing `\"""`, followed later by `horizontalSizeClass` in code | fails |
| `horizontalSizeClass` only inside the content of a `"""` multi-line literal | passes |
| a string literal whose only content is U+0301 COMBINING ACUTE ACCENT, followed by `, horizontalSizeClass` | fails |
| `// horizontalSizeClass` in a comment | passes |
| `"horizontalSizeClass"` as a plain string literal | passes |
| `@Environment(\.blLayoutClass) private var layoutClass` | passes |


<!-- @trace
source: iphone-landscape-compact-layout
updated: 2026-10-06
code:
  - apps/ios/BuyLedgerTests/SnapshotTests+OrderDetail.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Insights/insightsView_寬版_並排顯示類別排行與成本結構.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Dashboard/dashboardView_含進行中開團_顯示進行中的開團區段.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrderEdit/orderEditView_一般既有訂單_符合基準圖.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Orders/ordersView_寬版多選模式_顯示選取列.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Dashboard/dashboardView_大尺寸iPhone橫向_KPI維持在hero下方.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Tools/fxView_匯率載入失敗_顯示錯誤橫幅與重試鍵.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactView_一般訂單清單_符合基準圖.1.png
  - apps/ios/BuyLedger/Features/Orders/OrdersView.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/persistenceFailureView_持久化錯誤_符合基準圖.1.png
  - apps/ios/BuyLedgerTests/SnapshotTests.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardKPITiles.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Orders/ordersView_大尺寸iPhone橫向_顯示單欄清單與整合篩選鈕.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/quoteView_沒有可用匯率_顯示錯誤狀態.1.png
  - apps/ios/BuyLedgerTests/SnapshotTests+Shared.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardRecentOrdersSection.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Insights/insightsView_一般洞察資料_符合基準圖.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Dashboard/dashboardView_寬版_並排顯示hero與KPI.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrderEdit/orderEditView_長訂單識別碼_顯示短識別碼.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/insightsView_一般洞察資料_符合基準圖.1.png
  - apps/ios/BuyLedger/Features/Insights/InsightsHeatmapCard.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsCostStructureCard.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Tools/fxView_已載入匯率快照_顯示連線狀態.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Shared/blBarChart_近三十天資料_捲動停在最新日期.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/fxView_匯率載入失敗_顯示錯誤橫幅與重試鍵.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Dashboard/dashboardView_一般儀表板資料_符合基準圖.1.png
  - apps/ios/BuyLedger/Features/Insights/InsightsCategoryCard.swift
  - apps/ios/BuyLedgerTests/SnapshotTests+OrderEdit.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/fxView_已載入匯率快照_顯示連線狀態.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Insights/insightsView_大尺寸iPhone橫向_類別排行與成本結構上下堆疊.1.png
  - apps/ios/BuyLedgerUITests/Tests/Smoke/OrientationLayoutTests.swift
  - apps/ios/BuyLedgerTests/SnapshotTests+Orders.swift
  - apps/ios/BuyLedgerTests/BLLayoutClassEnvironmentTests.swift
  - apps/ios/BuyLedgerTests/DesignSystemSourceScanTests+Lexer.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardSummarySection.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Tools/quoteView_沒有可用匯率_顯示錯誤狀態.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+CampaignDetail/campaignEditView_編輯既有開團_符合基準圖.1.png
  - apps/ios/BuyLedgerTests/SnapshotTests+Tools.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardView.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsView.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Tools/quoteView_非零試算輸入_顯示成本與建議售價.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderDetailView_成本明細內容_符合基準圖.1.png
  - apps/ios/BuyLedger/Features/Dashboard/DashboardOngoingCampaignsSection.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersView_寬版多選模式_顯示選取列.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Orders/ordersCompactView_一般訂單清單_符合基準圖.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/quoteView_非零試算輸入_顯示成本與建議售價.1.png
  - apps/ios/BuyLedger/Features/Insights/InsightsCampaignProfitCard.swift
  - apps/ios/BuyLedger/Features/App/RootView.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrderDetail/orderDetailView_成本明細內容_符合基準圖.1.png
  - apps/ios/BuyLedgerTests/DesignSystemSourceScanTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLLayoutClass.swift
  - apps/ios/BuyLedgerTests/DesignSystemSourceScanTests+Patterns.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Shared/persistenceFailureView_持久化錯誤_符合基準圖.1.png
  - apps/ios/BuyLedger/Features/Orders/OrdersRegularDetailColumn.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/dashboardView_一般儀表板資料_符合基準圖.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditView_長訂單識別碼_顯示短識別碼.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Orders/ordersCompactView_多選模式_顯示勾選與工具列.1.png
  - apps/ios/BuyLedgerTests/SnapshotTests+Insights.swift
  - apps/ios/CLAUDE.md
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/blBarChart_近三十天資料_捲動停在最新日期.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactView_長內容訂單清單_避免撐寬版面.1.png
  - apps/ios/README.md
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactView_多選模式_顯示勾選與工具列.1.png
  - apps/ios/BuyLedgerTests/DesignSystemSourceScanTests+Scanner.swift
  - apps/ios/BuyLedgerTests/BLLayoutClassTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditView_合併訂單情境_符合基準圖.1.png
  - apps/ios/BuyLedger/Features/Dashboard/DashboardHeroCard.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditView_一般既有訂單_符合基準圖.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrderEdit/orderEditView_合併訂單情境_符合基準圖.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Orders/ordersCompactView_長內容訂單清單_避免撐寬版面.1.png
  - apps/ios/BuyLedger/Features/Orders/OrdersRegularListColumn.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsTrendCard.swift
  - apps/ios/BuyLedgerTests/SnapshotTests+Dashboard.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardKPITile.swift
-->

---
### Requirement: Layout-distinguishing platform wording maps to the selected layout

Where another capability distinguishes the root navigation, orders list, dashboard or insights presentation between the two layouts by platform or size class wording, the wording SHALL be read as naming a layout rather than a device. Wording on the compact side, such as "iPhone Compact", "iOS in the Compact size class", "the Compact horizontal size class", "iPhone (compact)" or "the compact size class", SHALL apply whenever the compact layout is used. Wording on the regular side, such as "iPadOS" set against an iPhone or compact clause, "iPad (regular)" or "the regular size class", SHALL apply whenever the regular layout is used. This mapping SHALL NOT apply to wording that names both platforms together, such as "on iOS and iPadOS", which keeps covering both layouts, nor to requirements about platform capabilities rather than layout presentation, such as local persistence on Apple platforms.

#### Scenario: Large iPhone in landscape follows the compact-layout requirements

- **GIVEN** a large iPhone in landscape that reports a regular horizontal size class and a compact vertical size class
- **WHEN** the orders list filter area is displayed
- **THEN** the unified filter trigger defined for "iPhone Compact" by the `order-filter-sheet` capability is shown
- **AND** the dedicated category trigger defined for "iPadOS" by the `order-category-filter` capability is not shown

#### Scenario: Narrow iPad window follows the compact-layout requirements

- **GIVEN** an iPad multitasking window that reports a compact horizontal size class
- **WHEN** the orders list filter area is displayed
- **THEN** the unified filter trigger defined for "iPhone Compact" is shown
- **AND** the dedicated category trigger defined for "iPadOS" is not shown

#### Scenario: Wording that names both platforms keeps covering both layouts

- **GIVEN** a requirement that provides orders multi-select "on iOS and iPadOS"
- **WHEN** the orders list is displayed in either the compact or the regular layout
- **THEN** the requirement applies in both layouts

<!-- @trace
source: iphone-landscape-compact-layout
updated: 2026-10-06
code:
  - apps/ios/BuyLedgerTests/SnapshotTests+OrderDetail.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Insights/insightsView_寬版_並排顯示類別排行與成本結構.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Dashboard/dashboardView_含進行中開團_顯示進行中的開團區段.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrderEdit/orderEditView_一般既有訂單_符合基準圖.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Orders/ordersView_寬版多選模式_顯示選取列.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Dashboard/dashboardView_大尺寸iPhone橫向_KPI維持在hero下方.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Tools/fxView_匯率載入失敗_顯示錯誤橫幅與重試鍵.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactView_一般訂單清單_符合基準圖.1.png
  - apps/ios/BuyLedger/Features/Orders/OrdersView.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/persistenceFailureView_持久化錯誤_符合基準圖.1.png
  - apps/ios/BuyLedgerTests/SnapshotTests.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardKPITiles.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Orders/ordersView_大尺寸iPhone橫向_顯示單欄清單與整合篩選鈕.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/quoteView_沒有可用匯率_顯示錯誤狀態.1.png
  - apps/ios/BuyLedgerTests/SnapshotTests+Shared.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardRecentOrdersSection.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Insights/insightsView_一般洞察資料_符合基準圖.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Dashboard/dashboardView_寬版_並排顯示hero與KPI.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrderEdit/orderEditView_長訂單識別碼_顯示短識別碼.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/insightsView_一般洞察資料_符合基準圖.1.png
  - apps/ios/BuyLedger/Features/Insights/InsightsHeatmapCard.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsCostStructureCard.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Tools/fxView_已載入匯率快照_顯示連線狀態.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Shared/blBarChart_近三十天資料_捲動停在最新日期.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/fxView_匯率載入失敗_顯示錯誤橫幅與重試鍵.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Dashboard/dashboardView_一般儀表板資料_符合基準圖.1.png
  - apps/ios/BuyLedger/Features/Insights/InsightsCategoryCard.swift
  - apps/ios/BuyLedgerTests/SnapshotTests+OrderEdit.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/fxView_已載入匯率快照_顯示連線狀態.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Insights/insightsView_大尺寸iPhone橫向_類別排行與成本結構上下堆疊.1.png
  - apps/ios/BuyLedgerUITests/Tests/Smoke/OrientationLayoutTests.swift
  - apps/ios/BuyLedgerTests/SnapshotTests+Orders.swift
  - apps/ios/BuyLedgerTests/BLLayoutClassEnvironmentTests.swift
  - apps/ios/BuyLedgerTests/DesignSystemSourceScanTests+Lexer.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardSummarySection.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Tools/quoteView_沒有可用匯率_顯示錯誤狀態.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+CampaignDetail/campaignEditView_編輯既有開團_符合基準圖.1.png
  - apps/ios/BuyLedgerTests/SnapshotTests+Tools.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardView.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsView.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Tools/quoteView_非零試算輸入_顯示成本與建議售價.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderDetailView_成本明細內容_符合基準圖.1.png
  - apps/ios/BuyLedger/Features/Dashboard/DashboardOngoingCampaignsSection.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersView_寬版多選模式_顯示選取列.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Orders/ordersCompactView_一般訂單清單_符合基準圖.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/quoteView_非零試算輸入_顯示成本與建議售價.1.png
  - apps/ios/BuyLedger/Features/Insights/InsightsCampaignProfitCard.swift
  - apps/ios/BuyLedger/Features/App/RootView.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrderDetail/orderDetailView_成本明細內容_符合基準圖.1.png
  - apps/ios/BuyLedgerTests/DesignSystemSourceScanTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLLayoutClass.swift
  - apps/ios/BuyLedgerTests/DesignSystemSourceScanTests+Patterns.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Shared/persistenceFailureView_持久化錯誤_符合基準圖.1.png
  - apps/ios/BuyLedger/Features/Orders/OrdersRegularDetailColumn.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/dashboardView_一般儀表板資料_符合基準圖.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditView_長訂單識別碼_顯示短識別碼.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Orders/ordersCompactView_多選模式_顯示勾選與工具列.1.png
  - apps/ios/BuyLedgerTests/SnapshotTests+Insights.swift
  - apps/ios/CLAUDE.md
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/blBarChart_近三十天資料_捲動停在最新日期.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactView_長內容訂單清單_避免撐寬版面.1.png
  - apps/ios/README.md
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactView_多選模式_顯示勾選與工具列.1.png
  - apps/ios/BuyLedgerTests/DesignSystemSourceScanTests+Scanner.swift
  - apps/ios/BuyLedgerTests/BLLayoutClassTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditView_合併訂單情境_符合基準圖.1.png
  - apps/ios/BuyLedger/Features/Dashboard/DashboardHeroCard.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditView_一般既有訂單_符合基準圖.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrderEdit/orderEditView_合併訂單情境_符合基準圖.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Orders/ordersCompactView_長內容訂單清單_避免撐寬版面.1.png
  - apps/ios/BuyLedger/Features/Orders/OrdersRegularListColumn.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsTrendCard.swift
  - apps/ios/BuyLedgerTests/SnapshotTests+Dashboard.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardKPITile.swift
-->