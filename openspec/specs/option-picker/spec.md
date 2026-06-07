# option-picker Specification

## Purpose

TBD - created by archiving change 'option-picker-sheet-macos-card-style'. Update Purpose after archive.

## Requirements

### Requirement: Platform-adaptive option picker presentation

The single-select option picker (used for order source, category, payment method, currency, and tool-page selections) SHALL render a Design System card layout on macOS and SHALL render a system List on iOS and iPadOS. The choice of layout MUST NOT change the available actions or the selectable options.

#### Scenario: macOS renders the card layout

- **WHEN** the option picker is presented on macOS
- **THEN** the picker presents a scrolling view with the options inside a Design System card with separators between rows, consistent with the customer list and lookup management screens
- **AND** in light mode the content background uses the same light-gray grouped color as the form List so the white card rows have contrast, while in dark mode it keeps the sheet's default material rather than a deep black background, so it never introduces a jarring block

#### Scenario: iOS and iPadOS keep the system List

- **WHEN** the option picker is presented on iOS or iPadOS
- **THEN** the picker presents the system List with the add section, option rows, and empty state, unchanged from before this change


<!-- @trace
source: option-picker-sheet-macos-card-style
updated: 2026-05-24
code:
  - BuyLedger/BuyLedger/Features/Orders/Components/OptionPickerSheet.swift
-->

---
### Requirement: Option selection is preserved across platforms

The picker SHALL let the user select one option on every platform. Selecting an option SHALL invoke the selection callback with that option and then dismiss the picker. The currently selected option SHALL be marked with a checkmark.

#### Scenario: Select an option

- **WHEN** the user taps an option row
- **THEN** the selection callback is invoked with that option and the picker dismisses

#### Scenario: Selected option is marked

- **WHEN** the picker is presented and an option equals the current selection
- **THEN** that option row displays a checkmark


<!-- @trace
source: option-picker-sheet-macos-card-style
updated: 2026-05-24
code:
  - BuyLedger/BuyLedger/Features/Orders/Components/OptionPickerSheet.swift
-->

---
### Requirement: Add-option flows are preserved across platforms

When adding is allowed, the picker SHALL provide an add control on every platform. The add control SHALL select its presentation by handler precedence:

1. When a payment-method add handler is provided, the add control SHALL present the payment method editor, collecting a name plus the cardless and bank-transfer flags.
2. Otherwise, when a name-sheet add handler is provided, the add control SHALL present a medium-height name editor sheet collecting a single name.
3. Otherwise, the add control SHALL present the add alert collecting a name.

Confirming an add SHALL invoke the corresponding add callback with the collected values and dismiss the picker. When no add handler is provided, the existing alert behavior SHALL be unchanged for all callers.

#### Scenario: Add via the general alert

- **WHEN** adding is allowed, neither a payment-method add handler nor a name-sheet add handler is provided, and the user confirms a non-empty trimmed name in the add alert
- **THEN** the add callback is invoked with that name and the picker dismisses

#### Scenario: Add a payment method via the editor sheet

- **WHEN** adding is allowed and a payment-method add handler is provided and the user confirms the editor sheet
- **THEN** the payment-method add callback is invoked with the name, cardless flag, and bank-transfer flag, and the picker dismisses

#### Scenario: Add via the name editor sheet

- **WHEN** adding is allowed, no payment-method add handler is provided, a name-sheet add handler is provided, and the user confirms a non-empty trimmed name in the medium-height name editor sheet
- **THEN** the name-sheet add callback is invoked with that name and the picker dismisses


<!-- @trace
source: order-reconciliation-status
updated: 2026-05-29
code:
  - BuyLedger/BuyLedger/Features/Lookups/LookupManagementFeature.swift
  - BuyLedger/BuyLedger/Core/Persistence/PaymentMethodPersistence.swift
  - BuyLedger/BuyLedger/Features/Orders/Components/OptionPickerSheet.swift
  - BuyLedger/BuyLedger/Core/Dependencies/OrderRepository.swift
  - BuyLedger/BuyLedger/Features/More/MoreView.swift
  - BuyLedger/BuyLedger/Features/Orders/Components/PaymentMethodEditorSheet.swift
  - BuyLedger/BuyLedger/Features/Orders/OrdersFeature.swift
  - BuyLedger/BuyLedger/Core/Dependencies/PaymentMethodRepository.swift
  - BuyLedger/BuyLedger/Core/Persistence/PaymentMethodRecord.swift
  - BuyLedger/BuyLedger/Features/Lookups/LookupKind.swift
  - BuyLedger/BuyLedger/Core/Persistence/OrderRecord.swift
  - BuyLedger/BuyLedger/Core/Domain/LedgerOrder+Samples.swift
  - BuyLedger/BuyLedgerTests/PaymentMethodPersistenceTests.swift
  - BuyLedger/BuyLedger/Core/Domain/PaymentMethodInfo.swift
  - BuyLedger/BuyLedger/Core/Persistence/BuyLedgerSchema.swift
  - BuyLedger/BuyLedger/Features/Lookups/LookupManagementView.swift
  - BuyLedger/BuyLedger/Core/Persistence/PersistenceContainer.swift
  - BuyLedger/BuyLedger/Core/Domain/LedgerOrder.swift
  - BuyLedger/BuyLedger/Features/Orders/Components/LookupItemEditorSheet.swift
  - BuyLedger/BuyLedgerTests/OrderEditFeatureTests.swift
  - BuyLedger/BuyLedger/Features/Orders/OrderEditView.swift
  - BuyLedger/BuyLedgerTests/RootFeatureTests.swift
  - BuyLedger/BuyLedgerTests/SnapshotTests.swift
  - BuyLedger/BuyLedger/Features/Orders/OrderEditFeature.swift
  - BuyLedger/BuyLedgerTests/OrderPersistenceTests.swift
  - BuyLedger/BuyLedger/Core/Persistence/OrderPersistence.swift
  - BuyLedger/BuyLedgerTests/OrderCalculationTests.swift
  - BuyLedger/BuyLedger/Core/Dependencies/VerificationStatusRepository.swift
  - BuyLedger/BuyLedgerTests/OrdersFeaturePerformanceTests.swift
  - BuyLedger/BuyLedger/Features/App/RootFeature.swift
  - BuyLedger/BuyLedgerTests/LookupManagementFeatureTests.swift
  - BuyLedger/BuyLedger/Core/Persistence/VerificationStatusRecord.swift
  - BuyLedger/BuyLedgerTests/OrdersFeatureTests.swift
  - BuyLedger/BuyLedger/Core/Persistence/VerificationStatusPersistence.swift
-->

---
### Requirement: Search, display name, and empty state are preserved

When search is enabled, the picker SHALL filter options by the search text using the display name and any supplemental search keywords. The picker SHALL render each option using its display name. When no options match, the picker SHALL show an empty state with the configured title and description.

#### Scenario: Filter options by search text

- **WHEN** search is enabled and the user enters text
- **THEN** only options whose display name or supplemental keywords contain the text remain visible

#### Scenario: Empty state when no options match

- **WHEN** there are no options to show
- **THEN** the picker displays the configured empty title and description

<!-- @trace
source: option-picker-sheet-macos-card-style
updated: 2026-05-24
code:
  - BuyLedger/BuyLedger/Features/Orders/Components/OptionPickerSheet.swift
-->

---
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


<!-- @trace
source: orders-category-filter-sheet-picker
updated: 2026-05-29
code:
  - BuyLedger/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewBaseline.1.png
  - BuyLedger/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewLongContentBaseline.1.png
  - BuyLedger/BuyLedger/Features/Orders/OrdersCompactView.swift
  - BuyLedger/BuyLedger/Features/Orders/OrdersMacView.swift
  - BuyLedger/BuyLedger/Features/Orders/OrdersView.swift
  - BuyLedger/BuyLedger/Features/Orders/Components/OptionPickerSheet.swift
-->

---
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

<!-- @trace
source: orders-category-filter-sheet-picker
updated: 2026-05-29
code:
  - BuyLedger/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewBaseline.1.png
  - BuyLedger/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewLongContentBaseline.1.png
  - BuyLedger/BuyLedger/Features/Orders/OrdersCompactView.swift
  - BuyLedger/BuyLedger/Features/Orders/OrdersMacView.swift
  - BuyLedger/BuyLedger/Features/Orders/OrdersView.swift
  - BuyLedger/BuyLedger/Features/Orders/Components/OptionPickerSheet.swift
-->

---
### Requirement: Optional multi-select mode

The option picker SHALL support an opt-in multi-select mode driven by a set of selected option strings. In this mode, tapping an option row SHALL toggle that option's membership in the selection without dismissing the sheet, every selected row SHALL show the selection indicator simultaneously, and the sheet SHALL provide an explicit done action that dismisses it. Search and the add-option flows SHALL behave identically to single-select mode. When multi-select mode is not requested, the picker SHALL preserve the existing single-select behavior unchanged.

#### Scenario: Toggling rows keeps the sheet open

- **WHEN** the picker is presented in multi-select mode and the user taps the rows "beauty" and "snacks"
- **THEN** both rows show the selection indicator and the sheet remains presented

#### Scenario: Deselecting a selected row

- **WHEN** the user taps an already-selected row in multi-select mode
- **THEN** that row's selection indicator is removed while the other selections are kept

#### Scenario: Done dismisses with the final selection

- **WHEN** the user taps the done action in multi-select mode
- **THEN** the sheet dismisses and the caller receives the final selected set

#### Scenario: Single-select callers are unaffected

- **WHEN** the picker is presented without multi-select mode
- **THEN** tapping a row selects exactly that option and dismisses the sheet, identical to the existing behavior

<!-- @trace
source: add-order-merge
updated: 2026-06-07
code:
  - BuyLedger/BuyLedger/Features/Orders/OrdersView.swift
  - BuyLedger/BuyLedger/Features/Orders/OrdersCompactView.swift
  - BuyLedger/BuyLedger/Features/Orders/OrdersMacView.swift
  - BuyLedger/BuyLedgerTests/OrderMergeFeatureTests.swift
  - BuyLedger/BuyLedger/Features/Orders/OrdersFeature.swift
  - BuyLedger/BuyLedger/Features/Orders/Components/OrderRowView.swift
  - BuyLedger/BuyLedger/Features/Orders/Components/OrderMergeCandidateSheet.swift
  - BuyLedger/BuyLedger/Features/Orders/OrderMergeFeature.swift
-->