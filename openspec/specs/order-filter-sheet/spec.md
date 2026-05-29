# order-filter-sheet Specification

## Purpose

TBD - created by archiving change 'orders-unified-filter-sheet'. Update Purpose after archive.

## Requirements

### Requirement: Unified filter sheet on iPhone Compact

On iPhone Compact size class, the orders list SHALL replace the separate date-period chip row and category filter trigger with a single unified filter trigger button. The trigger button SHALL open a unified filter sheet that hosts both the date-period selection and the category selection in one place. The status filter chip row SHALL remain unchanged above the trigger so that status selection retains its single-tap behavior.

The unified filter trigger button SHALL:
1. Render as a single capsule-shaped button that occupies the full available horizontal width of the orders filter area, with its left and right edges aligned to the search field above it.
2. Display a leading filter icon (the SF Symbol `line.3.horizontal.decrease` or an equivalent filter glyph).
3. Display a text label of the form `篩選：<summary>`, where `<summary>` describes the currently active date and category filters. The text segment SHALL support multi-line wrapping when the summary exceeds the available single-line width — the capsule SHALL grow vertically to fit the wrapped text rather than truncating it.
4. Display a trailing chevron-down indicator that communicates the control opens a sheet.
5. Apply a filled capsule background whose fill style indicates whether any non-default filter is currently applied. The active-selection style SHALL be applied when the date period is anything other than "all time" or when a specific category is selected; the inactive-selection style SHALL be applied otherwise.

When the label wraps to multiple lines, the leading filter icon and the trailing chevron-down icon SHALL align to the first text baseline rather than the vertical center of the capsule.

The trigger SHALL be rendered regardless of whether the available categories list is empty — the trigger continues to expose the date filter even when no categories exist.

#### Scenario: Trigger label summarizes the active filters

- **GIVEN** the orders list on iPhone Compact has at least one available category
- **WHEN** the trigger label is computed for the current filter state
- **THEN** the label reads `篩選：<summary>` where `<summary>` follows the rules below

##### Example: summary under different filter combinations

| Date period | Selected category | Summary | Capsule fill |
| --- | --- | --- | --- |
| `.all` | nil | `全部` | inactive |
| `.all` | "美妝" | `美妝` | active |
| `.thisMonth` | nil | `本月` | active |
| `.thisMonth` | "美妝" | `本月 · 美妝` | active |
| `.lastMonth` | "3C" | `上月 · 3C` | active |

#### Scenario: Tapping the trigger opens the unified filter sheet

- **WHEN** the user taps the unified filter trigger button on iPhone Compact
- **THEN** a sheet is presented with a navigation title `篩選`
- **AND** the sheet's medium detent is the default presentation size
- **AND** the sheet allows expansion to the large detent
- **AND** the sheet displays a drag indicator
- **AND** the sheet contains a leading cancellation control in its toolbar

#### Scenario: Trigger remains visible when no categories exist

- **GIVEN** the orders list on iPhone Compact has no available categories
- **WHEN** the orders list is displayed
- **THEN** the unified filter trigger button is still rendered
- **AND** the trigger label and capsule fill follow the same rules based on the active date period


<!-- @trace
source: orders-unified-filter-sheet
updated: 2026-05-29
code:
  - BuyLedger/BuyLedger/Features/Orders/OrdersMacView.swift
  - BuyLedger/BuyLedger/Features/Orders/Components/OptionPickerSheet.swift
  - BuyLedger/BuyLedger/Features/Orders/OrdersCompactView.swift
  - BuyLedger/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewBaseline.1.png
  - BuyLedger/BuyLedger/Features/Orders/Components/OrderFilterSheet.swift
  - BuyLedger/BuyLedger/Features/Orders/OrdersView.swift
  - BuyLedger/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewLongContentBaseline.1.png
-->

---
### Requirement: Unified filter sheet exposes date period and category sections

The unified filter sheet SHALL render two sections in order: a date-period section and a category section. The date-period section SHALL list every entry of the orders-browsing date-period set (`OrderDatePeriod.orderBrowsingCases`) — namely `.all`, `.thisWeek`, `.thisMonth`, and `.lastMonth` — as one row per case. The category section SHALL render an "all categories" clear row followed by one row per entry of the available categories list.

The sheet SHALL track a pending selection for each section that is independent of the orders feature's committed filter state. When the sheet is first presented, the pending date-period SHALL equal the orders feature's currently active date period and the pending category SHALL equal the orders feature's currently active category. Selecting any row SHALL update the corresponding pending selection without dispatching an orders-feature action and without dismissing the sheet:
- Selecting a date-period row SHALL update the pending date-period to that period.
- Selecting the "all categories" clear row SHALL update the pending category to "no specific category".
- Selecting a category row SHALL update the pending category to that category's name.

The sheet SHALL only commit the pending selections to the orders feature when the user taps an apply control in the navigation bar; see the "Apply control commits pending changes and dismisses the sheet" requirement.

Exactly one row SHALL be marked as the currently selected row in each section based on the pending selection (not the committed orders-feature state):
- In the date-period section, the row whose period equals the pending date-period SHALL be marked.
- In the category section, the "all categories" clear row SHALL be marked when the pending category is "no specific category", otherwise the row whose name equals the pending category SHALL be marked.

Every row SHALL support multi-line text wrapping when its label exceeds the available single-line width — the row SHALL grow vertically to fit the wrapped text. The trailing selection-state checkmark SHALL align to the first text baseline so it stays near the top of the wrapped text.

#### Scenario: Selecting a date row updates the pending selection without dismissing

- **GIVEN** the unified filter sheet is open with the pending date period being `.all` and no pending category
- **WHEN** the user taps the `本月` row in the date-period section
- **THEN** the pending date period becomes `.thisMonth`
- **AND** the date-period selection action is NOT dispatched
- **AND** the sheet remains open
- **AND** the `本月` row is now marked as currently selected and the `全部時間` row is no longer marked

#### Scenario: Selecting the clear row in the category section updates the pending selection

- **GIVEN** the unified filter sheet is open with a specific pending category set
- **WHEN** the user taps the `全部` clear row in the category section
- **THEN** the pending category becomes "no specific category"
- **AND** the category-filter action is NOT dispatched
- **AND** the sheet remains open
- **AND** the `全部` clear row is now marked as currently selected and the previously selected category row is no longer marked

#### Scenario: Selecting a category row updates the pending selection without dismissing

- **GIVEN** the unified filter sheet is open with no specific pending category and the available categories include `beauty`
- **WHEN** the user taps the `beauty` row in the category section
- **THEN** the pending category becomes `beauty`
- **AND** the category-filter action is NOT dispatched
- **AND** the sheet remains open
- **AND** the `beauty` row is now marked as currently selected and the `全部` clear row is no longer marked

#### Scenario: Multiple selections in the same sheet session are tracked together

- **GIVEN** the unified filter sheet is open with pending date period `.all` and no pending category, and the available categories include `beauty`
- **WHEN** the user taps the `本月` row, then taps the `beauty` row
- **THEN** the pending date period is `.thisMonth` and the pending category is `beauty`
- **AND** the date-period selection action and the category-filter action are both NOT yet dispatched
- **AND** the sheet remains open
- **AND** the `本月` row is marked as currently selected in the date-period section
- **AND** the `beauty` row is marked as currently selected in the category section

#### Scenario: Currently selected rows reflect the pending selection

- **GIVEN** the orders list filter state has date period `.thisMonth` and category `beauty`, and the unified filter sheet has just been opened
- **WHEN** the sheet content is displayed
- **THEN** in the date-period section, the `本月` row is marked as currently selected and no other date row is marked
- **AND** in the category section, the `beauty` row is marked as currently selected
- **AND** the `全部` clear row in the category section is not marked


<!-- @trace
source: orders-unified-filter-sheet
updated: 2026-05-29
code:
  - BuyLedger/BuyLedger/Features/Orders/OrdersMacView.swift
  - BuyLedger/BuyLedger/Features/Orders/Components/OptionPickerSheet.swift
  - BuyLedger/BuyLedger/Features/Orders/OrdersCompactView.swift
  - BuyLedger/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewBaseline.1.png
  - BuyLedger/BuyLedger/Features/Orders/Components/OrderFilterSheet.swift
  - BuyLedger/BuyLedger/Features/Orders/OrdersView.swift
  - BuyLedger/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewLongContentBaseline.1.png
-->

---
### Requirement: Apply control commits pending changes and dismisses the sheet

The unified filter sheet SHALL present an apply control in the navigation bar (positioned as the primary confirmation action, typically the trailing edge on iOS). The apply control SHALL be labeled with text that clearly conveys "apply the selection" (for example, `套用`).

Tapping the apply control SHALL:
1. For each pending selection that differs from the orders feature's currently committed value, dispatch the corresponding orders-feature action with the pending value. Selections whose pending value equals the committed value SHALL NOT trigger a redundant dispatch.
2. After dispatching, dismiss the sheet.

The sheet SHALL also continue to expose a cancel control in the navigation bar (positioned as the primary cancellation action, typically the leading edge on iOS). The cancel control SHALL dismiss the sheet WITHOUT dispatching any orders-feature action — the pending selections SHALL be discarded.

#### Scenario: Apply commits both pending changes and dismisses

- **GIVEN** the unified filter sheet is open with the committed orders state being date period `.all` and no category, and the user has set the pending date period to `.thisMonth` and the pending category to `beauty`
- **WHEN** the user taps the apply control
- **THEN** the date-period selection action is dispatched with `.thisMonth`
- **AND** the category-filter action is dispatched with `beauty`
- **AND** the sheet dismisses
- **AND** the trigger label reads `篩選：本月 · beauty`

#### Scenario: Apply commits only the changed pending selection

- **GIVEN** the unified filter sheet is open with the committed orders state being date period `.thisMonth` and no category, and the user has set the pending category to `beauty` without changing the pending date period (still `.thisMonth`)
- **WHEN** the user taps the apply control
- **THEN** the date-period selection action is NOT dispatched (no change)
- **AND** the category-filter action is dispatched with `beauty`
- **AND** the sheet dismisses

#### Scenario: Apply with no pending changes still dismisses and dispatches nothing

- **GIVEN** the unified filter sheet is open and the user has not changed any pending selection (or selected rows whose values match the committed state)
- **WHEN** the user taps the apply control
- **THEN** no orders-feature action is dispatched
- **AND** the sheet dismisses

#### Scenario: Cancel discards pending changes

- **GIVEN** the unified filter sheet is open with the committed orders state being date period `.all` and no category, and the user has set the pending date period to `.thisMonth` and the pending category to `beauty`
- **WHEN** the user taps the cancel control
- **THEN** no orders-feature action is dispatched
- **AND** the sheet dismisses
- **AND** the orders feature's committed date period remains `.all` and committed category remains "no specific category"
- **AND** the trigger label remains `篩選：全部`


<!-- @trace
source: orders-unified-filter-sheet
updated: 2026-05-29
code:
  - BuyLedger/BuyLedger/Features/Orders/OrdersMacView.swift
  - BuyLedger/BuyLedger/Features/Orders/Components/OptionPickerSheet.swift
  - BuyLedger/BuyLedger/Features/Orders/OrdersCompactView.swift
  - BuyLedger/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewBaseline.1.png
  - BuyLedger/BuyLedger/Features/Orders/Components/OrderFilterSheet.swift
  - BuyLedger/BuyLedger/Features/Orders/OrdersView.swift
  - BuyLedger/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewLongContentBaseline.1.png
-->

---
### Requirement: Search in the unified filter sheet filters only the category section

The unified filter sheet SHALL provide a search input that filters category rows in real time. The search input SHALL NOT affect the date-period section in any way — every date-period row SHALL remain visible regardless of the search text. The "all categories" clear row SHALL remain visible regardless of the search text, including when the search produces no matching category rows.

When the search text (after trimming whitespace) is non-empty, the displayed category rows SHALL be limited to entries whose category name, compared case-insensitively, contains the search text.

When the search produces no matching category rows, the category section SHALL display an empty-state row beneath the "all categories" clear row, indicating that no categories match the current search.

#### Scenario: Search filters category rows but preserves date and clear rows

- **GIVEN** the unified filter sheet is open with available categories `["beauty", "snacks", "books"]`
- **WHEN** the user types `boo` into the search input
- **THEN** the date-period section continues to show all four date rows in their original order
- **AND** the category section shows the `全部` clear row at the top and the `books` row as the only matching category row
- **AND** the `beauty` and `snacks` rows are hidden

#### Scenario: Search with no matches still shows the clear row and an empty state

- **GIVEN** the unified filter sheet is open with available categories `["beauty", "snacks"]`
- **WHEN** the user types text that matches no available category
- **THEN** the date-period section continues to show all four date rows
- **AND** the category section shows the `全部` clear row
- **AND** the category section shows an empty-state row indicating no categories match
- **AND** no category row from the available categories is shown

<!-- @trace
source: orders-unified-filter-sheet
updated: 2026-05-29
code:
  - BuyLedger/BuyLedger/Features/Orders/OrdersMacView.swift
  - BuyLedger/BuyLedger/Features/Orders/Components/OptionPickerSheet.swift
  - BuyLedger/BuyLedger/Features/Orders/OrdersCompactView.swift
  - BuyLedger/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewBaseline.1.png
  - BuyLedger/BuyLedger/Features/Orders/Components/OrderFilterSheet.swift
  - BuyLedger/BuyLedger/Features/Orders/OrdersView.swift
  - BuyLedger/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewLongContentBaseline.1.png
-->