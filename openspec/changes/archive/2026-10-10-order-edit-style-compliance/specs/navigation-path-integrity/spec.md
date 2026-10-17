## MODIFIED Requirements

### Requirement: Selection has a single source of truth

A list that supports selection SHALL express all of its selectable items through one selection model. Two selection mechanisms SHALL NOT coexist in the same list, because their independent states allow two rows to appear selected at once.

#### Scenario: Sidebar highlights exactly one row

- **WHEN** the user selects the orders row in the sidebar while the campaigns row was selected
- **THEN** exactly one row appears selected, and it is the orders row

## ADDED Requirements

### Requirement: The sidebar lists destinations only

In the regular layout the sidebar SHALL list the app's destinations and tools and SHALL NOT offer order status shortcuts. Orders in a particular status are reached through the orders list's status filter. The orders row SHALL keep its badge showing the number of active orders.

#### Scenario: No status shortcuts in the sidebar

- **WHEN** the app shows the sidebar in the regular layout
- **THEN** the sidebar lists the dashboard, orders, campaigns, insights and more rows, and no section of order status rows appears
