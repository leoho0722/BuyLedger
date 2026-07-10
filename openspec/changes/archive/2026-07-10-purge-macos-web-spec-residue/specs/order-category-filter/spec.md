## MODIFIED Requirements

### Requirement: Category filter on the orders list

The orders list SHALL provide a product-category filter that coexists with the existing status, date-period, and search filters on iOS and iPadOS. The filter SHALL offer an "all categories" option plus one option per available category. The available categories SHALL be sourced from the existing merged category options (category master plus categories used by orders). Selecting "all categories" SHALL clear the category constraint.

#### Scenario: Select a specific category

- **WHEN** the user selects a specific category in the filter
- **THEN** the orders list shows only orders whose category list contains the selected category, while still honoring the active status, date-period, and search filters

#### Scenario: Select all categories

- **WHEN** the user selects the "all categories" option
- **THEN** the category constraint is cleared and the orders list is no longer narrowed by category

### Requirement: Category filter is presented as a trigger button with a searchable picker sheet

On iPadOS the orders list category filter SHALL be rendered as a single capsule-shaped trigger button. The trigger button SHALL display the currently active category selection in its label so the user can identify the active selection without opening the picker. The category filter SHALL NOT be rendered as a horizontally scrolling row of capsule chips and SHALL NOT be rendered as an inline Menu.

On iOS in the Compact size class the orders list category filter SHALL instead be folded into the unified filter sheet defined by the `order-filter-sheet` capability. The dedicated category trigger described in this requirement SHALL NOT be rendered in that size class.

The trigger button SHALL occupy the full available horizontal width of the orders filter area on every platform where it is rendered, so its left and right edges align with the search field and other full-width controls above it.

The trigger button label SHALL be composed of, in order:
1. A leading tag icon consistent with the icon previously used by the category chips.
2. A text segment of the form `類別：<current>`, where `<current>` is `全部` when no category is selected, and the category name otherwise. The text segment SHALL support multi-line wrapping when the category name exceeds the available single-line width — the capsule SHALL grow vertically to fit the wrapped text rather than truncating it.
3. A trailing chevron-down indicator that communicates the control opens a picker sheet.

When the label wraps to multiple lines, the leading tag icon and the trailing chevron-down icon SHALL align to the first text baseline rather than the vertical center of the capsule.

The trigger button SHALL apply a filled capsule background. The fill SHALL be the active-selection style when a category is selected and the inactive-selection style otherwise, so the user can tell from the trigger alone whether a category filter is currently applied.

The trigger button SHALL only be rendered when the set of available categories is non-empty. When no categories are available, the category filter UI on iPadOS SHALL be hidden, matching the prior behavior.

Tapping the trigger button SHALL present a category picker sheet that:
1. Lists, in order, a "clear" row labeled `全部` (which clears the active category filter when tapped) followed by one row per entry in the available categories list (which sets the active category to that name when tapped).
2. Provides a search field that filters the category rows in real time. The "clear" row SHALL remain visible regardless of the search input.
3. Marks exactly one row as the currently selected row — the "clear" row when no category is selected, or the matching category row otherwise — with a visually distinguishable indicator such as a leading or trailing checkmark glyph.
4. Dismisses itself after the user taps any row.

#### Scenario: Trigger label reflects the active selection on iPadOS

- **GIVEN** the orders list is displayed on iPadOS and has at least one available category
- **WHEN** the active category filter is "all categories" (no specific category selected)
- **THEN** the trigger button label reads `類別：全部`
- **AND** the trigger background uses the inactive-selection style

##### Example: trigger labels under different selections

| Active selection           | Trigger label  | Trigger background style |
| -------------------------- | -------------- | ------------------------ |
| none ("all categories")    | `類別：全部`   | inactive                 |
| "beauty"                   | `類別：beauty` | active                   |
| "snacks"                   | `類別：snacks` | active                   |

#### Scenario: Dedicated category trigger is not rendered on iOS Compact

- **GIVEN** the orders list is displayed on iOS in the Compact horizontal size class
- **WHEN** the orders list filter area is rendered
- **THEN** the dedicated category trigger described in this requirement is not rendered
- **AND** the category filter is exposed instead through the unified filter sheet defined by the `order-filter-sheet` capability

#### Scenario: Picker sheet lists clear row and all categories with a selection indicator

- **GIVEN** the orders list is displayed on iPadOS with available categories `["beauty", "snacks", "books"]` and the active category filter is "snacks"
- **WHEN** the user taps the trigger button and the picker sheet opens
- **THEN** the picker shows rows in order: `全部`, `beauty`, `snacks`, `books`
- **AND** the `snacks` row is marked as the currently selected row
- **AND** no other row is marked as currently selected

#### Scenario: Selecting a category from the picker sheet updates the filter

- **GIVEN** the orders list is displayed on iPadOS with the category filter currently `全部` (no category selected)
- **WHEN** the user opens the picker sheet and taps the `beauty` row
- **THEN** the active category filter equals "beauty"
- **AND** the picker sheet dismisses
- **AND** the trigger button label reads `類別：beauty` and the trigger background uses the active-selection style
- **AND** the orders list is filtered to orders whose category list contains "beauty" (combined with any other active filters)
- **AND** reopening the picker sheet shows `beauty` as the currently selected row

#### Scenario: Selecting the clear row from the picker sheet clears the filter

- **GIVEN** the orders list is displayed on iPadOS
- **WHEN** the user opens the picker sheet while a specific category is active and taps the `全部` row
- **THEN** the active category filter is cleared
- **AND** the picker sheet dismisses
- **AND** the trigger button label reads `類別：全部` and the trigger background uses the inactive-selection style
- **AND** the orders list is no longer narrowed by category

#### Scenario: Search filters the category rows but preserves the clear row

- **GIVEN** the orders list is displayed on iPadOS with available categories `["beauty", "snacks", "books"]` and the picker sheet is open
- **WHEN** the user types `boo` into the search field
- **THEN** the picker shows the `全部` row at the top and the `books` row as the only matching category row
- **AND** the `beauty` and `snacks` rows are not shown

#### Scenario: Category filter is hidden when no categories are available on iPadOS

- **GIVEN** the orders list is displayed on iPadOS and the merged available categories list is empty
- **WHEN** the orders list is displayed
- **THEN** the trigger button is not rendered
- **AND** the active category filter remains cleared
