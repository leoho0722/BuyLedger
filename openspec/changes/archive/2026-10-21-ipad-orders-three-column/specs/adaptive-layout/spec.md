## MODIFIED Requirements

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
- **THEN** the root navigation uses the sidebar navigation rather than the bottom tab bar in both orientations
- **AND** the orders tab shows the orders list and order detail side by side in both orientations
- **AND** in portrait, while the orders destination is selected, the sidebar follows the placement defined by the "The regular orders layout gives the list and the detail their own columns" requirement

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

## ADDED Requirements

### Requirement: The regular orders layout gives the list and the detail their own columns

In the regular layout, while the orders destination is selected, the root navigation SHALL present the orders list column and the order detail column side by side without overlapping, together with the sidebar. The orders list column and the order detail column SHALL each have their own navigation bar. The orders search field, the orders title, the order count, the more-actions menu and the new-order action, and in multi-select mode the select-all, batch status and done controls, SHALL appear only within the horizontal extent of the orders list column. The orders list column's navigation bar SHALL show the orders title inline, and in multi-select mode the orders list column SHALL show the number of selected orders at its top, below the search field, in both orientations; ending a search by dismissing the keyboard or by clearing the search text SHALL keep that title visible and SHALL NOT move the search field or the order detail column's navigation bar from the vertical positions they had before the search. While the sidebar is shown beside the orders columns, the orders list column and the order detail column SHALL share the width beside the sidebar equally. While the sidebar is collapsed or overlays the orders columns, the orders list column SHALL keep a width of 320 points and the order detail column SHALL take the remaining width. Rotating the device SHALL keep both orders columns shown. The order detail column's navigation bar SHALL show the selected order's customer name as its title and SHALL carry that order's status menu and more-actions menu; no hand-drawn title row SHALL repeat them inside the detail content. When no order is selected, the order detail column SHALL show the select-an-order empty state and SHALL NOT show the order menus or a previously selected order's customer name. While any other destination is selected, the root navigation SHALL present only the sidebar and that destination's content, without an orders list column or an empty extra column. In landscape the sidebar SHALL be shown beside the orders columns without overlapping them. In portrait the sidebar placement SHALL follow the system's column presentation: the system either keeps the sidebar beside the orders columns without overlapping them or collapses it behind the system sidebar toggle, and when it is collapsed the system sidebar toggle or a swipe from the leading edge SHALL reveal the sidebar, overlaying the orders columns as the system presents it, so that another destination can be chosen. These navigation columns are managed by the system split view; the rule that multi-column arrangements collapse to a single column at accessibility text sizes applies to the content arranged within each column, not to these navigation columns, and the widths of these navigation columns follow the allocation above rather than scaling with the text size. At accessibility text sizes the filter controls of the orders list column SHALL remain fully readable without overlapping one another, scrolling together with the orders list instead of being compressed above it. The compact layout SHALL NOT change.

#### Scenario: Search field and list actions stay within the orders list column

- **GIVEN** an iPad in full screen showing the orders destination with an order selected
- **WHEN** the orders screen is displayed in portrait and then in landscape
- **THEN** the search field, the order count, the more-actions menu and the new-order action lie entirely within the horizontal extent of the orders list column
- **AND** none of them extends above the sidebar or the order detail column

#### Scenario: Multi-select controls stay within the orders list column

- **GIVEN** an iPad in full screen showing the orders destination with an order selected
- **WHEN** the user enters multi-select mode from the more-actions menu
- **THEN** the select-all, batch status and done controls lie within the horizontal extent of the orders list column
- **AND** the order detail column keeps its own navigation bar with the selected order's menus

#### Scenario: Selected count stays visible in multi-select

- **GIVEN** an iPad in full screen showing the orders destination in multi-select mode
- **WHEN** the user selects one order and the orders screen is displayed in portrait and then in landscape
- **THEN** the orders list column shows the number of selected orders below the search field
- **AND** the selected count lies within the horizontal extent of the orders list column in both orientations

#### Scenario: Detail column navigation bar carries the customer name and order menus

- **GIVEN** an iPad in full screen showing the orders destination
- **WHEN** the user selects an order whose customer is `林書宇`
- **THEN** the order detail column's navigation bar shows `林書宇` as its title
- **AND** the status menu and the more-actions menu of that order lie within that navigation bar
- **AND** the detail content does not contain a second row repeating the customer name and those menus

#### Scenario: Detail column without a selection shows only the empty state

- **GIVEN** an iPad in full screen showing the orders destination with an order selected
- **WHEN** no order is selected any more because the filtered orders list becomes empty
- **THEN** the order detail column shows the select-an-order empty state
- **AND** neither the status menu nor the order more-actions menu is shown
- **AND** the order detail column's navigation bar no longer shows the previously selected customer name

#### Scenario: Other destinations keep two columns

- **GIVEN** an iPad in full screen showing the orders destination
- **WHEN** the user selects the dashboard in the sidebar, revealing the sidebar first when it is collapsed, and then selects the orders destination again
- **THEN** the dashboard fills the area beside the sidebar without an orders list column or an empty extra column
- **AND** returning to the orders destination shows the orders list and detail columns with the search field inside the orders list column

#### Scenario: Sidebar placement follows the orientation

- **GIVEN** an iPad in full screen showing the orders destination
- **WHEN** the orders screen is displayed in landscape and then in portrait
- **THEN** in landscape the sidebar, the orders list column and the order detail column are side by side without overlapping
- **AND** in portrait the orders list column and the order detail column are side by side without overlapping, and the sidebar is either beside them without overlapping or collapsed with the system sidebar toggle available
- **AND** revealing a collapsed sidebar in portrait overlays the orders columns instead of narrowing them

#### Scenario: Orders columns share the width beside a tiled sidebar

- **GIVEN** an iPad in full screen showing the orders destination in landscape with the sidebar beside the orders columns
- **WHEN** the orders screen is displayed
- **THEN** the orders list column and the order detail column have the same width within 2 points
- **AND** together they fill the width between the sidebar and the trailing edge of the window

#### Scenario: Portrait keeps the standard list width and rotation keeps both columns

- **GIVEN** an iPad in full screen showing the orders destination in portrait with the sidebar collapsed
- **WHEN** the device is rotated to landscape and back to portrait
- **THEN** in portrait the orders list column is 320 points wide within 1 point and the order detail column takes the remaining width
- **AND** both orders columns are shown after each rotation

##### Example: measured column presentation on iPad Air 11-inch

The values are measurements on iPad Air 11-inch; tests verify the relations they illustrate (equal halves beside a tiled sidebar, 320 points otherwise, columns filling the width) rather than these device-specific numbers.

| Orientation | Window width (pt) | Sidebar | Orders list column (pt) | Order detail column (pt) |
| --- | --- | --- | --- | --- |
| portrait | 820 | collapsed behind the toggle; revealed above the columns | 320 | about 500 |
| landscape | 1180 | beside the columns, 240 to 250 | about 465 | about 465 |

#### Scenario: Ending a search keeps the orders title and the column positions

- **GIVEN** an iPad in full screen showing the orders destination with an order selected
- **WHEN** the user activates the search field, enters text that still matches the selected order, dismisses the keyboard, and then clears the search text
- **THEN** after the keyboard is dismissed and after the text is cleared, the orders title is visible in the orders list column's navigation bar
- **AND** the search field and the order detail column's navigation bar are at the same vertical positions as before the search, within 1 point
- **AND** this holds in portrait and in landscape

#### Scenario: Orders list filter controls stay readable at accessibility text sizes

- **GIVEN** an iPad in full screen with the largest accessibility text size, showing the orders destination
- **WHEN** the orders list column is displayed in portrait and then in landscape
- **THEN** the status chips, the date chips, the payment method menu, the category trigger and the clear filters action lie inside the scrollable orders list area
- **AND** none of them overlaps another vertically
- **AND** at standard text sizes the filter controls stay above the scrollable orders list as before

#### Scenario: Compact layout keeps the single-column orders list

- **GIVEN** an iPhone in portrait or an iPad multitasking window that reports a compact horizontal size class
- **WHEN** the orders destination is displayed
- **THEN** the orders list is a single column with the search field above it and the order detail is pushed

### Requirement: The layout decision follows the window rather than a split view column

The shared layout decision SHALL be resolved once from the window's size classes at the root of the view hierarchy and SHALL be provided to every descendant screen, including a screen hosted in a navigation split view column whose own horizontal size class is compact. When the window's size classes change, the root SHALL resolve the decision again and every descendant screen SHALL receive the new decision. A screen rendered without the root's resolved decision, such as a preview or an isolated snapshot, SHALL derive the layout from the size classes of its own environment. The resolution and the derivation SHALL both live in the shared layout decision's source file, so that production code elsewhere still does not reference the size classes.

#### Scenario: Orders list hosted in a split view column keeps the regular layout

- **GIVEN** an iPad in full screen whose window reports a regular horizontal and a regular vertical size class
- **WHEN** the orders list is hosted in the content column of the root split view, which reports a compact horizontal size class
- **THEN** the orders list column shows the regular filter area with the payment method menu and the category trigger
- **AND** it does not show the unified filter trigger of the compact layout

#### Scenario: Isolated rendering derives the layout from its own size classes

- **GIVEN** a screen rendered without the root's resolved decision
- **WHEN** its environment reports a regular horizontal and a regular vertical size class, and later a compact horizontal size class
- **THEN** the screen uses the regular layout and then the compact layout

#### Scenario: A resolved decision overrides a column's own size class

- **GIVEN** an environment whose resolved decision is regular and whose horizontal size class is compact
- **WHEN** a descendant screen reads the shared layout decision
- **THEN** it receives the regular layout
