## ADDED Requirements

### Requirement: Optional clear-selection row

The option picker SHALL support an optional clear-selection row, configured by the caller through an opt-in parameter. When the caller does not configure a clear-selection row, the picker SHALL behave exactly as before this requirement was added — no clear row SHALL appear and the selection contract SHALL be unchanged for all existing callers.

When the caller configures a clear-selection row, the picker SHALL:
1. Render an additional row at the top of the option list on all platforms (above the existing option rows). The row SHALL display a caller-supplied title.
2. Treat the empty string as the sentinel for "no specific selection" — when the current selection is the empty string, the clear-selection row SHALL be marked as the currently selected row; when the current selection equals any concrete option, that option row SHALL be marked instead and the clear-selection row SHALL NOT be marked.
3. Invoke a caller-supplied clear callback when the user taps the clear-selection row, then dismiss the picker. The clear callback SHALL be distinct from the regular option-selection callback, so the caller can distinguish "user chose nothing" from "user chose option X".
4. Exclude the clear-selection row from search filtering — the row SHALL remain visible regardless of the search text, including when the search produces no matching option rows.

The clear-selection row SHALL be composable with the existing add-option control. When both are configured, the rendering order on each platform SHALL be: add control first (if present), then the clear-selection row, then the option rows.

#### Scenario: No clear option configured preserves existing behavior

- **GIVEN** a caller presents the picker without configuring a clear-selection row, with options `["A", "B", "C"]` and current selection `"B"`
- **WHEN** the picker is displayed
- **THEN** no clear-selection row is rendered
- **AND** the `B` row is marked as the currently selected row
- **AND** tapping any option row invokes the existing selection callback with that option and dismisses the picker

#### Scenario: Clear option configured renders a clear row above the option list

- **GIVEN** a caller presents the picker with a clear-selection row titled `全部`, options `["beauty", "snacks", "books"]`, and current selection `"snacks"`
- **WHEN** the picker is displayed
- **THEN** the picker renders rows in order: clear row labeled `全部`, then `beauty`, `snacks`, `books`
- **AND** the `snacks` row is marked as the currently selected row
- **AND** the clear row is not marked as the currently selected row

#### Scenario: Empty-string selection marks the clear row

- **GIVEN** a caller presents the picker with a clear-selection row titled `全部`, options `["beauty", "snacks"]`, and current selection `""` (empty string)
- **WHEN** the picker is displayed
- **THEN** the clear row labeled `全部` is marked as the currently selected row
- **AND** neither the `beauty` row nor the `snacks` row is marked

#### Scenario: Tapping the clear row invokes the clear callback and dismisses

- **GIVEN** a caller presents the picker with a configured clear-selection row and a clear callback
- **WHEN** the user taps the clear row
- **THEN** the clear callback is invoked
- **AND** the regular option-selection callback is not invoked
- **AND** the picker dismisses

#### Scenario: Search filters option rows but preserves the clear row

- **GIVEN** a caller presents the picker with a clear-selection row titled `全部`, options `["beauty", "snacks", "books"]`, and search enabled
- **WHEN** the user types `boo` into the search field
- **THEN** the picker still renders the clear row at the top
- **AND** the picker renders only the `books` option row below the clear row
- **AND** the `beauty` and `snacks` rows are hidden

#### Scenario: Search yielding no option matches still shows the clear row

- **GIVEN** a caller presents the picker with a clear-selection row titled `全部`, options `["beauty", "snacks"]`, and search enabled
- **WHEN** the user types text that matches no option
- **THEN** the picker still renders the clear row at the top
- **AND** the picker renders the empty-state view below the clear row

#### Scenario: Clear option composes with the add control

- **GIVEN** a caller presents the picker with both an add control and a configured clear-selection row, with options `["A", "B"]`
- **WHEN** the picker is displayed
- **THEN** the picker renders, in order: the add control, the clear row, the `A` row, the `B` row

### Requirement: Option rows support multi-line text wrapping

Every option row in the picker (including the clear-selection row when configured) SHALL support multi-line wrapping when its label text exceeds the available single-line width. The row SHALL grow vertically to fit the wrapped text rather than truncating it with an ellipsis or clipping it behind a trailing accessory such as a checkmark.

When a row wraps to multiple lines, the trailing selection-state accessory (for example, a checkmark glyph) SHALL align to the first text baseline so it stays near the top of the wrapped text rather than centering vertically across the multi-line row.

#### Scenario: A long option label wraps to multiple lines

- **GIVEN** a caller presents the picker with an option whose label is significantly longer than the row's available horizontal width — for example, `"aespa Lemonade QQ 音樂限定禮包"`
- **WHEN** the picker is displayed and the row is rendered
- **THEN** the option label is fully visible across multiple lines (no ellipsis, no horizontal scroll, no clipping)
- **AND** the row's height grows to accommodate the wrapped text
- **AND** the trailing checkmark accessory, when present, aligns to the first text baseline

#### Scenario: A long clear-row title wraps to multiple lines

- **GIVEN** a caller presents the picker with a configured clear-selection row whose title is significantly longer than the row's available horizontal width
- **WHEN** the picker is displayed and the clear row is rendered
- **THEN** the clear row's title is fully visible across multiple lines (no ellipsis, no clipping)
- **AND** the row's height grows to accommodate the wrapped text
