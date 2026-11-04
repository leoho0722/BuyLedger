## MODIFIED Requirements

### Requirement: Apply control commits pending changes and dismisses the sheet

The unified filter sheet SHALL present an apply control in the navigation bar (positioned as the primary confirmation action, typically the trailing edge on iOS). The apply control SHALL be labeled with text that clearly conveys "apply the selection" (for example, `套用`).

Tapping the apply control SHALL commit every pending selection whose value differs from the corresponding committed value, leave unchanged those whose pending value already equals the committed value, and then dismiss the sheet. The pending category selection is a set; it differs from the committed set when the two sets do not contain exactly the same names. When at least one filter value changed, the current destination SHALL be checked once against the final filtered result after all changes are committed, rather than once per changed filter. A matching destination SHALL retain its identity and detail state; an excluded destination SHALL be cleared. An unselected list SHALL remain unselected, and the first result SHALL NOT be selected automatically.

The sheet SHALL also continue to expose a cancel control in the navigation bar (positioned as the primary cancellation action, typically the leading edge on iOS). Cancelling SHALL never commit a pending selection. When pending selections differ from the committed values, cancelling SHALL first ask the user to confirm discarding them; see the "Guard edit sheets against silent data loss on dismissal" and "Confirm discarding unsaved changes when cancelling" requirements of the sheet-dismissal-safeguard capability.

Dismissal SHALL be driven by the orders feature rather than by the sheet view, so that every path that closes the sheet is observable outside the view layer.

#### Scenario: Apply commits both pending changes and dismisses

- **GIVEN** the unified filter sheet is open with the committed orders state being date period `.all` and no selected category, and the user has set the pending date period to `.thisMonth` and the pending categories to {`beauty`}
- **WHEN** the user taps the apply control
- **THEN** the committed date period becomes `.thisMonth` and the committed categories become {`beauty`}
- **AND** the sheet dismisses
- **AND** the trigger label reads `篩選：本月 · beauty`

#### Scenario: Apply commits all three pending selections

- **GIVEN** the unified filter sheet is open with committed date period `.all`, no committed category, and no committed payment method, and the user has set the pending date period to `.thisMonth`, the pending categories to {`beauty`}, and the pending payment method to `轉帳`
- **WHEN** the user taps the apply control
- **THEN** the committed date period becomes `.thisMonth`, the committed categories become {`beauty`}, and the committed payment method becomes `轉帳`
- **AND** the trigger label reads `篩選：本月 · beauty · 轉帳`

#### Scenario: Apply commits only the changed pending selection

- **GIVEN** the unified filter sheet is open with the committed orders state being date period `.thisMonth` and no selected category, and the user has set the pending categories to {`beauty`, `snacks`} without changing the pending date period (still `.thisMonth`)
- **WHEN** the user taps the apply control
- **THEN** the committed date period is left untouched (no change)
- **AND** the committed categories become {`beauty`, `snacks`}
- **AND** the sheet dismisses
- **AND** the trigger label reads `篩選：本月 · 2 項類別`

#### Scenario: Apply with no pending changes still dismisses and changes nothing

- **GIVEN** the unified filter sheet is open and the user has not changed any pending selection (or toggled a category on and off again so that the pending set equals the committed set)
- **WHEN** the user taps the apply control
- **THEN** no committed filter value changes and the currently selected order is unchanged
- **AND** the sheet dismisses

#### Scenario: Apply validates the selected order once

- **GIVEN** the unified filter sheet is open and the user has changed all three pending selections
- **WHEN** the user taps the apply control
- **THEN** the current destination retains its existing state if it matches all three committed values, and is cleared otherwise
- **AND** a list without a destination remains unselected
- **AND** that validity check happens once against the final result, not once per changed filter

#### Scenario: Cancel discards pending changes without committing

- **GIVEN** the unified filter sheet is open with the committed orders state being date period `.all` and no selected category, and the user has set the pending date period to `.thisMonth` and the pending categories to {`beauty`}
- **WHEN** the user cancels and confirms discarding the pending changes
- **THEN** no committed filter value changes
- **AND** the pending selections are reset to the committed values
- **AND** the sheet dismisses
- **AND** the trigger label remains `篩選：全部`

### Requirement: Clear filters control restores default filter values

The orders list SHALL offer a clear-filters control labeled `清除篩選` that restores the date period to `.all`, the payment method to "no specific value", and the category set to empty. The control SHALL NOT change the status filter or the search text. The control SHALL be disabled, and SHALL expose the disabled state to accessibility, whenever all three values it restores are already at their defaults.

In the simplified orders control presentation the control SHALL be rendered in the filter-conditions header row of the unified filter sheet. It SHALL act on the pending selections only: it SHALL NOT commit any value and SHALL NOT dismiss the sheet; the user commits the cleared values with the apply control or discards them with cancel. Its enabled state SHALL be derived from the pending selections.

In the expanded orders control presentation the control SHALL be rendered in the orders filter area below the payment-method and category filter triggers. It SHALL act on the committed filters immediately and check the current destination once against the final result. A matching destination SHALL retain its state; an excluded destination SHALL be cleared; no destination SHALL be selected automatically. Its enabled state SHALL be derived from the committed filters.

#### Scenario: Clearing inside the unified sheet resets pending values only

- **GIVEN** the unified filter sheet is open with pending date period `.thisMonth`, pending payment method `信用卡`, and pending categories {`beauty`, `books`}, and the committed values are the same
- **WHEN** the user taps `清除篩選`
- **THEN** the pending date period is `.all`, the pending payment method is "no specific value", and the pending category set is empty
- **AND** the committed values are unchanged and the sheet remains open
- **AND** the clear-filters control becomes disabled
- **AND** tapping the apply control afterwards commits the default values and the trigger label reads `篩選：全部`

#### Scenario: The unified sheet control is disabled when the pending values are already default

- **GIVEN** the unified filter sheet is open with pending date period `.all`, no pending payment method, and an empty pending category set
- **WHEN** the sheet content is displayed
- **THEN** the clear-filters control is disabled

#### Scenario: Clearing in expanded controls applies immediately

- **GIVEN** the orders list with expanded controls has committed status filter `purchased`, search text `Alice`, date period `.thisMonth`, payment method `現金`, and categories {`beauty`}
- **WHEN** the user taps `清除篩選`
- **THEN** the committed date period becomes `.all`, the committed payment method becomes "no specific value", and the committed category set becomes empty
- **AND** the status filter remains `purchased` and the search text remains `Alice`
- **AND** the current destination is checked once against the final result, retaining its state if it matches and clearing it otherwise
- **AND** no destination is selected if the list was unselected before clearing
- **AND** the clear-filters control becomes disabled
