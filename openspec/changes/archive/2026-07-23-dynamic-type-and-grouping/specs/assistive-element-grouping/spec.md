## ADDED Requirements

### Requirement: Composite rows are announced as a single unit

A row composed of multiple child elements SHALL be combined into a single element for assistive technology, so that traversing a list advances one row at a time rather than one child at a time. The combined announcement SHALL follow the visual order of its children, and SHALL be produced by combining the existing children rather than by hand-assembling a separate string, so that content changes are reflected automatically.

#### Scenario: Order row is one traversal stop

- **WHEN** assistive technology traverses the order list
- **THEN** each order row is a single stop announcing the customer, date, items, status, and amounts in visual order

#### Scenario: Campaign row is one traversal stop

- **WHEN** assistive technology traverses the campaign list
- **THEN** each campaign row is a single stop announcing the campaign name, status, count, and progress

#### Scenario: Key metric tile is one traversal stop

- **WHEN** assistive technology traverses the dashboard key metric area
- **THEN** each tile is a single stop announcing its label, value, and change

### Requirement: Decorative and duplicated elements are excluded

Elements that carry no information beyond what an adjacent element already conveys SHALL be excluded from the accessibility tree. This includes purely decorative shapes and an avatar whose label duplicates a name shown beside it. An element that is decorative in one context but informative in another SHALL expose this as a caller-controlled option rather than being unconditionally included or excluded.

#### Scenario: Customer name is announced once

- **WHEN** assistive technology announces an order row containing both an avatar and the customer name
- **THEN** the customer name is announced exactly once

#### Scenario: Standalone avatar retains its label

- **WHEN** an avatar appears without an adjacent name
- **THEN** it still announces the customer name

#### Scenario: Decorative dot is skipped

- **WHEN** assistive technology announces a key metric tile containing a decorative colored dot
- **THEN** the dot contributes nothing to the announcement

### Requirement: Grid cells convey their position

A cell within a grid SHALL announce its position in addition to its value, so that a user traversing the grid can tell where they are. Cells carrying no data SHALL be excluded to reduce noise, and the grid as a whole SHALL provide a summary describing its extent.

#### Scenario: Heatmap cell announces weekday and week

- **WHEN** assistive technology focuses a heatmap cell holding at least one order
- **THEN** the announcement conveys the weekday and the week position along with the order count

#### Scenario: Empty heatmap cells are skipped

- **WHEN** assistive technology traverses the heatmap
- **THEN** cells holding zero orders are not presented as separate stops

#### Scenario: Heatmap provides an overall summary

- **WHEN** assistive technology focuses the heatmap as a whole
- **THEN** a summary describes the number of weeks the grid covers
