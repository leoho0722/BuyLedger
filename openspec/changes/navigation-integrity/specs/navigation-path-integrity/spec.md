## ADDED Requirements

### Requirement: Each destination is reachable through a single path

A destination SHALL be reachable through exactly one navigation path, so that the back path always reflects the true hierarchy. Where a destination can be opened both from a list and from a deep link, both SHALL write into the same navigation stack rather than using independent presentation mechanisms. A deep link SHALL reset the stack before pushing, and the reset and push SHALL occur within a single state update so that no intermediate state presents two copies.

#### Scenario: Deep link does not stack a second copy

- **WHEN** the user has already navigated to settings from the list, and a deep link to settings is then triggered
- **THEN** exactly one settings screen exists, and navigating back once returns to the root of that tab

#### Scenario: Back path reflects the true hierarchy

- **WHEN** the user reaches settings by any available path
- **THEN** navigating back returns to the tab root rather than to an unrelated sibling screen

### Requirement: Selection has a single source of truth

A list that supports selection SHALL express all of its selectable items through one selection model. Two selection mechanisms SHALL NOT coexist in the same list, because their independent states allow two rows to appear selected at once.

#### Scenario: Sidebar highlights exactly one row

- **WHEN** the user selects a smart group in the sidebar
- **THEN** exactly one row appears selected, and the tab row for the destination the smart group leads to does not also appear selected

#### Scenario: Selecting a smart group preserves existing filters

- **WHEN** the user has set a date period and a category filter, and then selects a smart group
- **THEN** the previously chosen date period and category filter remain unchanged

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
