## MODIFIED Requirements

### Requirement: Orders list provides a multi-select mode

The orders list SHALL provide a multi-select mode on iOS and iPadOS. The system SHALL provide a control to enter and exit multi-select mode. While in multi-select mode, tapping or clicking an order row SHALL toggle that order's selection instead of navigating to its detail. The system SHALL provide a way to select all orders in the current filtered list and to clear the current selection, and SHALL display the count of currently selected orders. Exiting multi-select mode SHALL clear the current selection.

The selectable row and the multi-select toolbar SHALL be provided by a single implementation shared by both size classes, so that their behaviour and their presentation to assistive technology cannot differ between compact and regular layouts.

#### Scenario: Enter multi-select and toggle selection

- **WHEN** the user enters multi-select mode and taps two order rows
- **THEN** both rows show as selected, the selected count shows 2, and neither tap navigates to order detail

#### Scenario: Select all then clear

- **WHEN** the user taps "select all" with a filtered list of 5 orders, then taps "clear selection"
- **THEN** the selected count goes to 5 and then to 0

#### Scenario: Exiting clears selection

- **WHEN** the user has selected orders and exits multi-select mode
- **THEN** the selection is empty and rows return to navigating to detail on tap

#### Scenario: Both size classes present selection identically

- **WHEN** the selectable row is inspected in the compact and the regular layout
- **THEN** in both, a selected row exposes the selected accessibility trait, and in both the selection glyph is excluded from the accessibility tree
