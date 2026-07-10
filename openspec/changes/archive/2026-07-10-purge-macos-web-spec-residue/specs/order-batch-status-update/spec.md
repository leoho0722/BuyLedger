## MODIFIED Requirements

### Requirement: Orders list provides a multi-select mode

The orders list SHALL provide a multi-select mode on iOS and iPadOS. The system SHALL provide a control to enter and exit multi-select mode. While in multi-select mode, tapping or clicking an order row SHALL toggle that order's selection instead of navigating to its detail. The system SHALL provide a way to select all orders in the current filtered list and to clear the current selection, and SHALL display the count of currently selected orders. Exiting multi-select mode SHALL clear the current selection.

#### Scenario: Enter multi-select and toggle selection

- **WHEN** the user enters multi-select mode and taps two order rows
- **THEN** both rows show as selected, the selected count shows 2, and neither tap navigates to order detail

#### Scenario: Select all then clear

- **WHEN** the user taps "select all" with a filtered list of 5 orders, then taps "clear selection"
- **THEN** the selected count goes to 5 and then to 0

#### Scenario: Exiting clears selection

- **WHEN** the user has selected orders and exits multi-select mode
- **THEN** the selection is empty and rows return to navigating to detail on tap

### Requirement: Batch status persistence is atomic on Apple

On Apple platforms (iOS and iPadOS) where orders persist to the local store, a batch status update SHALL persist all changed orders in a single save operation rather than one save per order.

#### Scenario: Single persistence for a multi-order batch

- **WHEN** a batch status update changes the status of four orders
- **THEN** all four changed orders are written to the local store in one save operation
