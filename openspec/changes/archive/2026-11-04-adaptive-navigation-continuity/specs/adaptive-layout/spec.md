## REMOVED Requirements

### Requirement: The regular layout is used only when both size classes are regular

**Reason**: One window-wide classification incorrectly couples root navigation, navigation columns and content arrangements.
**Migration**: Use the system adaptive root, feature-owned navigation containers and local content adaptation defined below.

### Requirement: Layout selection has a single entry point

**Reason**: Prohibiting local size-class reads prevents a column from adapting to its actual environment.
**Migration**: Remove the single-file size-class policy and its dedicated assertions. Retain unrelated source-scan rules and their lexical coverage. Shared content rules remain reusable without deciding every screen's arrangement.

### Requirement: The layout decision follows the window rather than a split view column

**Reason**: A root override hides the available space and traits of descendant columns.
**Migration**: Remove the root layout override after migrating its consumers. Each feature reads its local environment and delegates navigation collapse to its system container.

## MODIFIED Requirements

### Requirement: Layout-distinguishing platform wording maps to the selected layout

Existing layout-specific wording in orders filtering capabilities SHALL name the orders list's local control presentation rather than a device or root navigation style. Compact-side wording, including "iPhone Compact", "iOS in the Compact size class", "the Compact horizontal size class", "iPhone (compact)" and "the compact size class", SHALL identify the simplified controls with the unified filter entry. Regular-side wording, including "iPadOS" contrasted with a compact clause, "iPad (regular)" and "the regular size class", SHALL identify the expanded controls with dedicated filter entries. The list SHALL choose between these presentations from its own available content area and environment. This mapping SHALL NOT prescribe dashboard or insights arrangements, root sidebar visibility, or a device-wide layout. Wording naming both platforms and platform capabilities such as persistence SHALL retain its original scope. In order-detail arrangement requirements, compact and regular SHALL identify collapsed and side-by-side detail presentation respectively, independently of root navigation.

#### Scenario: A narrow orders column uses simplified filtering

- **GIVEN** a narrow orders list column inside a window with the root sidebar visible
- **WHEN** its local environment requires simplified controls
- **THEN** it shows the unified filter entry from `order-filter-sheet`
- **AND** all existing filters remain accessible without requiring the dedicated category trigger from the expanded controls

#### Scenario: Available list space controls expanded filtering

- **GIVEN** the root uses tabs and the orders list has sufficient local space for expanded controls
- **WHEN** the list displays expanded filtering
- **THEN** its dedicated category and payment entries remain available independently of the root tab style

#### Scenario: Wording naming both platforms keeps its scope

- **GIVEN** a requirement providing orders multi-select on iOS and iPadOS
- **WHEN** either local filter presentation is displayed
- **THEN** multi-select remains available

### Requirement: The regular orders layout gives the list and the detail their own columns

When the orders navigation container presents columns side by side, the orders list and detail SHALL occupy separate non-overlapping columns with their own system navigation bars. The list's search, inline title, count, more-actions menu, new-order action and multi-select actions SHALL belong to the list column. In side-by-side multi-select presentation the selected count SHALL appear once at the top of the list below search. Ending search SHALL retain the list title and SHALL NOT leave an empty navigation region or displace the detail toolbar when the container geometry is unchanged.

The detail navigation bar SHALL display the selected customer's name and that order's status and more-actions menus, without a duplicate custom title row. With no selection it SHALL display a localized selection prompt without stale customer titles or order-specific actions. Navigation column widths SHALL be flexible preferences, subordinate to available space, system reserved regions and content usability; neither equal halves nor a fixed list width SHALL be mandatory. The system container SHALL be allowed to collapse columns when needed while retaining the current destination. Root sidebar visibility SHALL NOT define the feature's column allocation. Switching to another tab SHALL remove orders columns from that tab's presentation.

System navigation columns SHALL adapt independently of content grids. At accessibility text sizes, expanded orders filters SHALL remain readable without overlap and scroll with the list; at standard sizes their existing above-list placement SHALL remain. In collapsed navigation the list SHALL lead to the same selected detail through system navigation.

#### Scenario: List controls remain scoped to the list

- **GIVEN** the orders list and a selected detail are visible side by side
- **WHEN** the user searches, enters multi-select and rotates or resizes the window
- **THEN** search and list actions remain within the list's visible interactive region
- **AND** the selected count appears once below search while columns remain side by side
- **AND** the detail retains its own order actions

#### Scenario: Detail title and actions match the selection

- **GIVEN** side-by-side orders navigation
- **WHEN** the user selects an order whose customer is `林書宇`
- **THEN** the detail navigation bar displays `林書宇` and that order's menus
- **AND** the content does not duplicate the title or menus

#### Scenario: Clearing selection removes stale detail controls

- **GIVEN** an order is selected
- **WHEN** filtering excludes that order
- **THEN** the expanded detail shows the selection prompt without its previous title or order menus

#### Scenario: Root navigation does not leak orders columns

- **GIVEN** orders has a selected detail with the root sidebar visible
- **WHEN** the user switches to dashboard and then back to orders
- **THEN** dashboard presents no orders column or empty orders placeholder
- **AND** orders restores its selected detail using its current available space

#### Scenario: Columns adapt without a fixed ratio

- **GIVEN** the orders list and detail are side by side
- **WHEN** the user reveals the root sidebar, changes orientation or partially folds the device
- **THEN** the system adjusts widths or collapses navigation without losing the selected order
- **AND** visible list and detail controls remain accessible within their own regions

#### Scenario: Ending search leaves usable navigation

- **GIVEN** side-by-side orders navigation with a selected order
- **WHEN** the user searches for matching text, dismisses the keyboard and clears the search without changing the window geometry
- **THEN** the list's inline title stays visible and no empty search-related navigation region remains
- **AND** the detail toolbar remains in its original column navigation region

#### Scenario: Accessible filters scroll with the list

- **GIVEN** expanded orders controls at the largest accessibility text size
- **WHEN** the user scrolls the list in either supported orientation
- **THEN** status, date, payment, category and clear-filter controls scroll with the list and remain readable without overlapping each other

#### Scenario: Collapsed navigation opens the same detail

- **GIVEN** the system presents orders as collapsed navigation
- **WHEN** the user selects an order
- **THEN** the system presents that order's detail with a native return path to the list

## ADDED Requirements

### Requirement: Root navigation uses one adaptive set of destinations

The app SHALL use a system adaptive tab container for dashboard, orders, campaigns, insights and more. On iPad the initial preferred presentation SHALL be the tab bar, with the system sidebar alternative available. The app SHALL NOT reset the user's sidebar choice on tab switches or resizing. The app SHALL use native bar placement on iPhone including Duo without forcing an iPad-style sidebar when unfolded. Root destination state SHALL remain independent of root bar placement and feature column presentation.

#### Scenario: iPad starts with tabs and permits sidebar navigation

- **GIVEN** a fresh scene without a user-selected sidebar presentation
- **WHEN** the app opens on iPad and the user switches to the system sidebar
- **THEN** the same five destinations remain available
- **AND** subsequent tab switches and resizing do not force the app preference back to tabs

#### Scenario: Unfolding preserves the root destination

- **GIVEN** orders is selected on a closed Duo
- **WHEN** the user unfolds the device
- **THEN** orders stays selected as system bars adapt
- **AND** the app does not substitute a different root navigation hierarchy based on the device name

### Requirement: Each feature adapts to its own available region

Orders, campaigns and more SHALL own system split navigation for their list and current detail or tool. Dashboard and insights SHALL retain their own stack navigation. A feature SHALL use its own environment and available safe content region, without inheriting a root-wide compact or regular decision. Horizontal capacity and vertical capacity SHALL be evaluated for their respective content needs, without requiring both size classes to be regular for every wider arrangement. Device model names, fixed physical screen dimensions and hinge-angle tables SHALL NOT select arrangements. Missing size information SHALL use a navigable single-column fallback. Column preferences SHALL yield to system collapse, reserved regions, readability and Dynamic Type.

#### Scenario: Features adapt independently inside the same window

- **GIVEN** a window using root tabs where orders can present list and detail
- **WHEN** the user switches between orders, campaigns, more and dashboard
- **THEN** each feature uses its own content region and navigation needs
- **AND** dashboard keeps its common content order regardless of the other features' column presentation

#### Scenario: Isolated content has a usable fallback

- **GIVEN** a feature is rendered without size-class information
- **WHEN** its navigation is displayed
- **THEN** the list and selected detail remain reachable using single-column navigation and native back navigation

#### Scenario: Selected list rows stay readable in a split column

- **GIVEN** orders, campaigns or more present their list beside the current detail or tool
- **WHEN** the user selects a row, at a standard or accessibility text size and in either language
- **THEN** every text in the selected row keeps readable contrast against the row's own background
- **AND** the row keeps its selected trait for assistive technologies

### Requirement: Dashboard and insights keep one content order across sizes

Dashboard SHALL present date controls, the monthly summary, revenue, cost, gross margin and active-order metrics, ongoing campaigns and recent orders in that sequence. All four metrics SHALL remain present at every supported size, with a two-column grid at standard text sizes and a single column at accessibility sizes. Insights SHALL present period controls, profit trend, category breakdown, cost structure, campaign profit when data exists, and heatmap in that vertical sequence. Wider regions SHALL NOT move dashboard metrics beside the monthly summary or place insights category and cost cards side by side. Equal source data SHALL produce equal displayed values across presentations. Loading, error and empty states SHALL retain their existing meaning.

#### Scenario: Resizing retains dashboard information and order

- **GIVEN** the same dashboard data is loaded
- **WHEN** the window changes between narrow and wide presentations
- **THEN** cost remains available alongside the other three metrics below the monthly summary
- **AND** metric values and the subsequent campaign and recent-order sections remain unchanged

#### Scenario: Insights keeps its sequence with optional campaign data

- **GIVEN** insights is displayed with and without campaign profit data in separate runs
- **WHEN** the window is resized in each run
- **THEN** the period, trend, category, cost and heatmap order stays unchanged
- **AND** campaign profit appears between cost and heatmap only in the run containing its data

### Requirement: Shared readable content adapts within system safe regions

Dashboard, insights, order and campaign details, More tools, and existing create or edit forms SHALL use reusable content-width rules. Narrow safe content regions SHALL use the available width with normal content margins. Wider regions SHALL constrain content to a readable maximum appropriate to text, forms or charts, aligned within that content region rather than the physical display. The limits SHALL adapt to text size and SHALL NOT truncate information or prevent input. These limits SHALL apply inside navigation columns, without constraining the root navigation container or the split container itself. Chart content SHALL retain readable labels and access to its data. Continuous scrolling content SHALL retain its reading sequence during partial folding; necessary control avoidance SHALL NOT relocate the entire scroll surface to the other half.

#### Scenario: Multiple content types adapt in an asymmetric region

- **GIVEN** a detail, a More tool and a form are opened in separate runs with a system bar reserving one side
- **WHEN** each safe content region is narrowed and widened
- **THEN** the common width rules keep text, fields and primary actions readable and reachable within that region
- **AND** narrowing does not retain a wider fixed content frame

#### Scenario: Partial folding preserves continuous reading

- **GIVEN** the user is reading a scrolled order detail or insights report
- **WHEN** the device becomes partially folded
- **THEN** the content retains its sequence and current reading context
- **AND** only controls requiring reserved-region avoidance adjust locally, without moving the entire scrolling surface to the opposite half
