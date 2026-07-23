## ADDED Requirements

### Requirement: The campaign detail keeps a generic title

The campaign detail screen SHALL be titled with the generic screen name; the campaign's name is presented by the info section within the content and SHALL NOT be duplicated into the navigation title.

#### Scenario: Campaign detail keeps the generic title

- **WHEN** the user opens a campaign from any entry point
- **THEN** the navigation title displays the generic screen name, and the campaign name appears in the campaign info section

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

### Requirement: The app launches on the overview tab

The app SHALL always launch on the overview tab; the tab selection SHALL NOT be persisted across launches. Navigation stacks and scroll positions are likewise not restored.

#### Scenario: Relaunch returns to the overview tab

- **WHEN** the user selects any other tab, terminates the app, and launches it again
- **THEN** the overview tab is selected on launch

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

A dismissal control SHALL NOT occupy the trailing primary action position, which is reserved for the screen's principal action; a pushed destination relies on the host stack's back control instead of a separate dismissal control.

#### Scenario: Photo viewer leaves via the host stack back control

- **WHEN** the photo viewer is pushed from the order edit form
- **THEN** no separate close control occupies the primary action position, and leaving the viewer is performed by the host navigation stack's back control
