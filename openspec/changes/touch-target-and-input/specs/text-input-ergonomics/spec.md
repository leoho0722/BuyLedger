## ADDED Requirements

### Requirement: Fillable fields declare their content type

Text fields whose content the system can supply SHALL declare their content type so that autofill and refined keyboard suggestions become available. Free-form fields that the system cannot meaningfully fill SHALL declare that explicitly rather than leaving the content type unset, so that the system does not misclassify them.

#### Scenario: Customer name offers autofill

- **WHEN** the user focuses the customer name field and contact data is available on the device
- **THEN** the system offers a fill suggestion for the field

#### Scenario: Free-form fields are not misclassified

- **WHEN** the user focuses a free-form name field such as a lookup item or campaign name
- **THEN** the system does not offer unrelated suggestions such as addresses

### Requirement: Numeric keyboards provide a dismissal path

A form presenting a numeric keyboard SHALL provide a visible way to dismiss it, because numeric keyboards have no return key. The form SHALL provide a keyboard toolbar carrying a done action, and SHALL additionally dismiss the keyboard on scroll. Dismissal SHALL NOT depend solely on tapping empty space.

#### Scenario: Done button dismisses the keyboard

- **WHEN** a numeric keyboard is presented and the user activates the done action in the keyboard toolbar
- **THEN** the keyboard dismisses and the entered value is retained

#### Scenario: Scrolling dismisses the keyboard

- **WHEN** a numeric keyboard is presented and the user scrolls the form
- **THEN** the keyboard dismisses

#### Scenario: Toolbar appears only for numeric input

- **WHEN** the user focuses a field that presents a standard keyboard with a return key
- **THEN** no redundant done toolbar is shown

### Requirement: Form value fields meet the minimum hit region

A value field inside a form row SHALL provide a hit region of at least 44 points in height, so that tapping anywhere within the row's vertical extent focuses the field. The row's own inset SHALL NOT be relied upon, because it belongs to the row rather than to the field.

#### Scenario: Tapping the row edge focuses the field

- **WHEN** the user taps near the top or bottom edge of a form row containing a numeric field
- **THEN** that field receives focus

##### Example: measured fields

| Field | Measured height before | Required |
| ----- | ---------------------- | -------- |
| Line item unit price | about 22 points | at least 44 points |
| Decimal value fields | about 22 points | at least 44 points |
| Percentage fields | about 22 points | at least 44 points |

### Requirement: Long forms manage focus order

A form with many input fields SHALL manage focus so that fields can be traversed in visual order, and the focus state SHALL live in the feature state rather than in view-local state, consistent with the project convention that store-bound views hold no presentation state. Opening a blank order SHALL focus the first field. Focus SHALL be cleared when the form is dismissed so that reopening it does not restore a stale focus.

#### Scenario: New order focuses the first field

- **WHEN** the user opens the order edit form for a new order
- **THEN** the first input field receives focus

#### Scenario: Focus does not persist across presentations

- **WHEN** the user dismisses the order edit form while a field is focused, then opens the form again
- **THEN** focus is not restored to the previously focused field

#### Scenario: Focus follows visual order

- **WHEN** the user advances focus from a field using an external keyboard
- **THEN** focus moves to the next field in visual order
