## MODIFIED Requirements

### Requirement: Order merge entry points

The system SHALL provide a "merge order" action on the orders list row context menu and in the order detail page's "more" actions menu, on iOS and iPadOS. On the order detail page, the merge, edit, and delete actions SHALL be grouped into a single "more" menu (ellipsis label) — ordered as merge, edit, then delete, with delete presented as a destructive action separated from the others by a divider — while the status update control SHALL remain a separate control outside that menu. Both entry points SHALL open the same merge candidate sheet, with the originating order as the primary order. The merge action SHALL NOT be offered for orders whose status is merged or cancelled.

#### Scenario: Entry from the orders list context menu

- **WHEN** the user opens the context menu of an order row whose status is neither merged nor cancelled and selects the merge action
- **THEN** the merge candidate sheet opens with that order as the primary order

#### Scenario: Entry from the order detail page

- **WHEN** the user opens the "more" menu on the detail page of an order whose status is neither merged nor cancelled and selects the merge action
- **THEN** the merge candidate sheet opens with that order as the primary order

#### Scenario: Detail page actions are consolidated into a more menu

- **WHEN** the user views the detail page of any order
- **THEN** the action area shows exactly two controls: the status update menu and a "more" menu that contains the merge action (when the order is eligible), the edit action, and the destructive delete action separated by a divider

#### Scenario: Entry hidden for merged and cancelled orders

- **WHEN** an order's status is merged or cancelled
- **THEN** neither the context menu nor the detail page "more" menu offers the merge action, while the "more" menu still offers edit and delete
