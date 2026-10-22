## ADDED Requirements

### Requirement: Unified filter sheet exposes date period, category, and payment method sections

The unified filter sheet SHALL render three sections in order: a date-period section, a category section, and a payment-method section. The date-period section SHALL list every entry of the orders-browsing date-period set (`OrderDatePeriod.orderBrowsingCases`) — namely `.all`, `.thisWeek`, `.thisMonth`, and `.lastMonth` — as one row per case. The category section SHALL render an "all categories" clear row followed by one row per entry of the available categories list. The payment-method section SHALL render an "all payment methods" clear row followed by one row per entry of the available payment methods list.

The pending selection for each section SHALL be held by the orders feature rather than by the sheet view, so that it is observable and assertable outside the view layer. When the sheet is presented, each pending selection SHALL be seeded from the orders feature's corresponding committed filter value, and the sheet's search text SHALL be reset to empty.

Selecting any row SHALL update the corresponding pending selection without changing any committed filter value and without dismissing the sheet:

- Selecting a date-period row SHALL update the pending date-period to that period.
- Selecting a clear row SHALL update the corresponding pending selection to "no specific value".
- Selecting a category or payment-method row SHALL update the corresponding pending selection to that row's name.

The sheet SHALL only commit the pending selections when the user taps the apply control; see the "Apply control commits pending changes and dismisses the sheet" requirement.

Exactly one row SHALL be marked as the currently selected row in each section based on the pending selection, not the committed state. In the category and payment-method sections, the clear row SHALL be marked when the pending selection is "no specific value", otherwise the row whose name equals the pending selection SHALL be marked.

Every row SHALL support multi-line text wrapping when its label exceeds the available single-line width — the row SHALL grow vertically to fit the wrapped text. The trailing selection-state checkmark SHALL align to the first text baseline so it stays near the top of the wrapped text.

#### Scenario: Presenting the sheet seeds pending selections from committed values

- **GIVEN** the orders list has committed date period `.thisMonth`, committed category `beauty`, and no committed payment method
- **WHEN** the unified filter sheet is presented
- **THEN** the pending date period is `.thisMonth`, the pending category is `beauty`, and the pending payment method is "no specific value"
- **AND** the sheet's search text is empty

#### Scenario: Selecting a date row updates the pending selection without dismissing

- **GIVEN** the unified filter sheet is open with the pending date period being `.all` and no pending category
- **WHEN** the user taps the `本月` row in the date-period section
- **THEN** the pending date period becomes `.thisMonth`
- **AND** the committed date period is unchanged
- **AND** the sheet remains open
- **AND** the `本月` row is now marked as currently selected and the `全部時間` row is no longer marked

#### Scenario: Selecting the clear row in the category section updates the pending selection

- **GIVEN** the unified filter sheet is open with a specific pending category set
- **WHEN** the user taps the `全部` clear row in the category section
- **THEN** the pending category becomes "no specific category"
- **AND** the committed category is unchanged
- **AND** the sheet remains open
- **AND** the `全部` clear row is now marked as currently selected and the previously selected category row is no longer marked

#### Scenario: Selecting a payment-method row updates the pending selection

- **GIVEN** the unified filter sheet is open with no specific pending payment method and the available payment methods include `轉帳`
- **WHEN** the user taps the `轉帳` row in the payment-method section
- **THEN** the pending payment method becomes `轉帳`
- **AND** the committed payment method is unchanged
- **AND** the sheet remains open

#### Scenario: Multiple selections in the same sheet session are tracked together

- **GIVEN** the unified filter sheet is open with pending date period `.all` and no pending category, and the available categories include `beauty`
- **WHEN** the user taps the `本月` row, then taps the `beauty` row
- **THEN** the pending date period is `.thisMonth` and the pending category is `beauty`
- **AND** no committed filter value has changed
- **AND** the sheet remains open
- **AND** the `本月` row is marked as currently selected in the date-period section
- **AND** the `beauty` row is marked as currently selected in the category section

#### Scenario: Currently selected rows reflect the pending selection

- **GIVEN** the orders list filter state has date period `.thisMonth` and category `beauty`, and the unified filter sheet has just been opened
- **WHEN** the sheet content is displayed
- **THEN** in the date-period section, the `本月` row is marked as currently selected and no other date row is marked
- **AND** in the category section, the `beauty` row is marked as currently selected
- **AND** the `全部` clear row in the category section is not marked

### Requirement: Search in the unified filter sheet filters the category and payment method sections

The unified filter sheet SHALL provide a search input that filters category rows and payment-method rows in real time. The search input SHALL NOT affect the date-period section in any way — every date-period row SHALL remain visible regardless of the search text. Each clear row SHALL remain visible regardless of the search text, including when the search produces no matching rows in that section.

When the search text (after trimming whitespace) is non-empty, the displayed rows in the category and payment-method sections SHALL be limited to entries whose name, compared case-insensitively, contains the search text.

When the search produces no matching rows in a section, that section SHALL display an empty-state row beneath its clear row, indicating that nothing matches the current search.

The search text and the resulting filtered lists SHALL be held by the orders feature rather than computed inside the sheet view.

#### Scenario: Search filters category rows but preserves date and clear rows

- **GIVEN** the unified filter sheet is open with available categories `["beauty", "snacks", "books"]`
- **WHEN** the user types `boo` into the search input
- **THEN** the date-period section continues to show all four date rows in their original order
- **AND** the category section shows the `全部` clear row at the top and the `books` row as the only matching category row
- **AND** the `beauty` and `snacks` rows are hidden

#### Scenario: Search filters payment-method rows the same way

- **GIVEN** the unified filter sheet is open with available payment methods `["轉帳", "貨到付款"]`
- **WHEN** the user types text matching only `轉帳`
- **THEN** the payment-method section shows its clear row and the `轉帳` row only
- **AND** the date-period section is unaffected

#### Scenario: Search with no matches still shows the clear row and an empty state

- **GIVEN** the unified filter sheet is open with available categories `["beauty", "snacks"]`
- **WHEN** the user types text that matches no available category
- **THEN** the date-period section continues to show all four date rows
- **AND** the category section shows the `全部` clear row
- **AND** the category section shows an empty-state row indicating no categories match
- **AND** no category row from the available categories is shown

## MODIFIED Requirements

### Requirement: Apply control commits pending changes and dismisses the sheet

The unified filter sheet SHALL present an apply control in the navigation bar (positioned as the primary confirmation action, typically the trailing edge on iOS). The apply control SHALL be labeled with text that clearly conveys "apply the selection" (for example, `套用`).

Tapping the apply control SHALL commit every pending selection whose value differs from the corresponding committed value, leave unchanged those whose pending value already equals the committed value, and then dismiss the sheet. When at least one filter value changed, the currently selected order SHALL be recomputed once against the newly filtered list rather than once per changed filter.

The sheet SHALL also continue to expose a cancel control in the navigation bar (positioned as the primary cancellation action, typically the leading edge on iOS). Cancelling SHALL never commit a pending selection. When pending selections differ from the committed values, cancelling SHALL first ask the user to confirm discarding them; see the "Sheets holding uncommitted changes resist accidental dismissal" requirement of the irreversible-action-safeguard capability.

Dismissal SHALL be driven by the orders feature rather than by the sheet view, so that every path that closes the sheet is observable outside the view layer.

#### Scenario: Apply commits both pending changes and dismisses

- **GIVEN** the unified filter sheet is open with the committed orders state being date period `.all` and no category, and the user has set the pending date period to `.thisMonth` and the pending category to `beauty`
- **WHEN** the user taps the apply control
- **THEN** the committed date period becomes `.thisMonth` and the committed category becomes `beauty`
- **AND** the sheet dismisses
- **AND** the trigger label reads `篩選：本月 · beauty`

#### Scenario: Apply commits only the changed pending selection

- **GIVEN** the unified filter sheet is open with the committed orders state being date period `.thisMonth` and no category, and the user has set the pending category to `beauty` without changing the pending date period (still `.thisMonth`)
- **WHEN** the user taps the apply control
- **THEN** the committed date period is left untouched (no change)
- **AND** the committed category becomes `beauty`
- **AND** the sheet dismisses

#### Scenario: Apply with no pending changes still dismisses and changes nothing

- **GIVEN** the unified filter sheet is open and the user has not changed any pending selection (or selected rows whose values match the committed state)
- **WHEN** the user taps the apply control
- **THEN** no committed filter value changes and the currently selected order is unchanged
- **AND** the sheet dismisses

#### Scenario: Apply recomputes the selected order once

- **GIVEN** the unified filter sheet is open and the user has changed all three pending selections
- **WHEN** the user taps the apply control
- **THEN** the currently selected order becomes the first order of the list filtered by all three committed values
- **AND** that recomputation happens once, not once per changed filter

#### Scenario: Cancel discards pending changes without committing

- **GIVEN** the unified filter sheet is open with the committed orders state being date period `.all` and no category, and the user has set the pending date period to `.thisMonth` and the pending category to `beauty`
- **WHEN** the user cancels and confirms discarding the pending changes
- **THEN** no committed filter value changes
- **AND** the pending selections are reset to the committed values
- **AND** the sheet dismisses
- **AND** the trigger label remains `篩選：全部`

## REMOVED Requirements

### Requirement: Unified filter sheet exposes date period and category sections

**Reason**: The title states that the sheet exposes only a date-period section and a category section, which has not matched the implementation since the payment-method section was added — a reader scanning requirement titles would conclude that payment method is not filterable here. The requirement is replaced by "Unified filter sheet exposes date period, category, and payment method sections", which additionally relocates the pending selection from the sheet view to the orders feature.

**Migration**: All normative content is carried forward into the replacement requirement, with the payment-method section documented and the pending-selection ownership stated. No behavior is dropped.

### Requirement: Search in the unified filter sheet filters only the category section

**Reason**: The title states that search affects only the category section, which contradicts the implementation — the payment-method list is filtered by the same search text. The requirement is replaced by "Search in the unified filter sheet filters the category and payment method sections".

**Migration**: All normative content is carried forward into the replacement requirement, extended to cover the payment-method section and to state that the search text and filtered lists are held by the orders feature. No behavior is dropped.
