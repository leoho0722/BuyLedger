## ADDED Requirements

### Requirement: Detail screens are titled by the entity they show

A detail screen SHALL be titled with the name of the entity it presents rather than a generic category name, so that the title and the back affordance identify which record is open. Where no entity is available, a generic title SHALL be used as a fallback.

#### Scenario: Campaign detail shows the campaign name

- **WHEN** the user opens a campaign from the list
- **THEN** the navigation title displays that campaign's name

#### Scenario: Missing campaign falls back to a generic title

- **WHEN** the campaign detail screen is presented without a resolvable campaign
- **THEN** a generic title is displayed instead

### Requirement: Status colors match the meaning of the status

A status SHALL be assigned a semantic color that matches its meaning. A status representing normal forward progress SHALL NOT be assigned a warning color, because doing so signals that attention is required when none is.

#### Scenario: Purchased status reads as progress, not warning

- **WHEN** an order in the purchased status is displayed
- **THEN** its status indicator uses an informational semantic color rather than a warning color

#### Scenario: Statuses genuinely needing attention keep the warning color

- **WHEN** an order in the partially arrived status is displayed
- **THEN** its status indicator retains the warning color

### Requirement: Confirmation messages are written for the user

A confirmation message SHALL use active voice and SHALL refer to records by names the user recognizes. It SHALL NOT include internal identifiers, because they carry no meaning for the user and add reading burden.

#### Scenario: Order deletion confirmation names the customer

- **WHEN** the deletion confirmation for an order is presented
- **THEN** it identifies the order by its customer name and contains no internal identifier

### Requirement: The app reopens on the tab last used

The app SHALL restore the tab the user last selected when it relaunches, rather than always returning to a fixed default. Restoration SHALL cover the tab selection; navigation stacks and scroll positions are out of scope.

#### Scenario: Last tab is restored

- **WHEN** the user selects the orders tab, terminates the app, and launches it again
- **THEN** the orders tab is selected on launch

#### Scenario: First launch uses the default tab

- **WHEN** the app launches with no previously stored tab selection
- **THEN** the default tab is selected

### Requirement: Empty states center within their visible area

An empty state presented inside a scrollable container SHALL be centered within the visible area rather than aligned to its top. Filling the available height SHALL NOT be relied upon inside a scroll container, because the container proposes an unbounded size along its scroll axis and the fill collapses to the content's own height.

#### Scenario: Customer list empty state is centered

- **WHEN** the customer list has no content to display
- **THEN** the empty state appears centered in the visible area rather than at the top

#### Scenario: Order list empty state is centered

- **WHEN** the order list has no matching orders
- **THEN** the empty state appears centered in the visible area

### Requirement: Dismissal is not placed in the primary action position

A dismissal control SHALL be placed in the cancellation position rather than the trailing primary action position, which is reserved for the screen's principal action.

#### Scenario: Photo viewer close is in the cancellation position

- **WHEN** the full screen photo viewer is presented
- **THEN** its close control occupies the cancellation position
