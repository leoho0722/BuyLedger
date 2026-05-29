## ADDED Requirements

### Requirement: Category filter is presented as a trigger button with a searchable picker sheet

The orders list category filter SHALL be rendered as a single capsule-shaped trigger button on iOS, iPadOS, and macOS. The trigger button SHALL display the currently active category selection in its label so the user can identify the active selection without opening the picker. The category filter SHALL NOT be rendered as a horizontally scrolling row of capsule chips and SHALL NOT be rendered as an inline Menu.

The trigger button SHALL occupy the full available horizontal width of the orders filter area on every platform, so its left and right edges align with the search field and other full-width controls above it.

The trigger button label SHALL be composed of, in order:
1. A leading tag icon consistent with the icon previously used by the category chips.
2. A text segment of the form `類別：<current>`, where `<current>` is `全部` when no category is selected, and the category name otherwise. The text segment SHALL support multi-line wrapping when the category name exceeds the available single-line width — the capsule SHALL grow vertically to fit the wrapped text rather than truncating it.
3. A trailing chevron-down indicator that communicates the control opens a picker sheet.

When the label wraps to multiple lines, the leading tag icon and the trailing chevron-down icon SHALL align to the first text baseline rather than the vertical center of the capsule.

The trigger button SHALL apply a filled capsule background. The fill SHALL be the active-selection style when a category is selected and the inactive-selection style otherwise, so the user can tell from the trigger alone whether a category filter is currently applied.

The trigger button SHALL only be rendered when the set of available categories is non-empty. When no categories are available, the category filter UI SHALL be hidden, matching the prior behavior.

Tapping the trigger button SHALL present a category picker sheet that:
1. Lists, in order, a "clear" row labeled `全部` (which clears the active category filter when tapped) followed by one row per entry in the available categories list (which sets the active category to that name when tapped).
2. Provides a search field that filters the category rows in real time. The "clear" row SHALL remain visible regardless of the search input.
3. Marks exactly one row as the currently selected row — the "clear" row when no category is selected, or the matching category row otherwise — with a visually distinguishable indicator such as a leading or trailing checkmark glyph.
4. Dismisses itself after the user taps any row.

#### Scenario: Trigger label reflects the active selection

- **GIVEN** the orders list has at least one available category
- **WHEN** the active category filter is "all categories" (no specific category selected)
- **THEN** the trigger button label reads `類別：全部`
- **AND** the trigger background uses the inactive-selection style

##### Example: trigger labels under different selections

| Active selection           | Trigger label  | Trigger background style |
| -------------------------- | -------------- | ------------------------ |
| none ("all categories")    | `類別：全部`   | inactive                 |
| "beauty"                   | `類別：beauty` | active                   |
| "snacks"                   | `類別：snacks` | active                   |

#### Scenario: Picker sheet lists clear row and all categories with a selection indicator

- **GIVEN** the available categories list is `["beauty", "snacks", "books"]` and the active category filter is "snacks"
- **WHEN** the user taps the trigger button and the picker sheet opens
- **THEN** the picker shows rows in order: `全部`, `beauty`, `snacks`, `books`
- **AND** the `snacks` row is marked as the currently selected row
- **AND** no other row is marked as currently selected

#### Scenario: Selecting a category from the picker sheet updates the filter

- **GIVEN** the orders list category filter is currently `全部` (no category selected)
- **WHEN** the user opens the picker sheet and taps the `beauty` row
- **THEN** the active category filter equals "beauty"
- **AND** the picker sheet dismisses
- **AND** the trigger button label reads `類別：beauty` and the trigger background uses the active-selection style
- **AND** the orders list is filtered to orders whose `category` equals "beauty" (combined with any other active filters)
- **AND** reopening the picker sheet shows `beauty` as the currently selected row

#### Scenario: Selecting the clear row from the picker sheet clears the filter

- **WHEN** the user opens the picker sheet while a specific category is active and taps the `全部` row
- **THEN** the active category filter is cleared
- **AND** the picker sheet dismisses
- **AND** the trigger button label reads `類別：全部` and the trigger background uses the inactive-selection style
- **AND** the orders list is no longer narrowed by category

#### Scenario: Search filters the category rows but preserves the clear row

- **GIVEN** the available categories list is `["beauty", "snacks", "books"]` and the picker sheet is open
- **WHEN** the user types `boo` into the search field
- **THEN** the picker shows the `全部` row at the top and the `books` row as the only matching category row
- **AND** the `beauty` and `snacks` rows are not shown

#### Scenario: Category filter is hidden when no categories are available

- **GIVEN** the merged available categories list is empty
- **WHEN** the orders list is displayed
- **THEN** the trigger button is not rendered
- **AND** the active category filter remains cleared

## MODIFIED Requirements

### Requirement: Deep link from analytics applies the category filter

When the user taps a category row in the analytics page's category ranking, the app SHALL navigate to the orders tab and apply the tapped category as the active category filter on the orders list. The active category filter value SHALL drive both the orders list filtering and the visual state of the category filter trigger button and picker sheet (trigger label and picker selected-row indicator compare against the active category filter value). The orders list SHALL be filtered by exact match on each order's `category` field — it SHALL NOT rely on text search to approximate the filter.

#### Scenario: Tapping a category row navigates and applies the filter

- **WHEN** the user is on the analytics page and taps the category row whose name is "beauty"
- **THEN** the active tab changes to "orders"
- **AND** the orders list's active category filter equals "beauty"
- **AND** the category filter trigger button label reads `類別：beauty` and the trigger background uses the active-selection style
- **AND** opening the picker sheet shows the `beauty` row as the currently selected row
- **AND** the orders list contains exactly those orders whose `category` field equals "beauty"

##### Example: deep link with mixed-category data

- **GIVEN** orders: O1(category="beauty", customer="Alice"), O2(category="snacks", customer="Beauty Bob"), O3(category="beauty", customer="Carol")
- **WHEN** the user taps the "beauty" row in the analytics category ranking
- **THEN** the orders list contains exactly { O1, O3 } and excludes O2, even though O2's customer name contains the substring "Beauty"

#### Scenario: Tapping a category row resets unrelated orders-list filters

- **WHEN** the user has the orders list state with status filter "delivered" and date-period filter "this month", then taps a category row on the analytics page
- **THEN** the status filter resets to "all"
- **AND** the date-period filter resets to "all"
- **AND** the search text is cleared
- **AND** the active category filter equals the tapped category
