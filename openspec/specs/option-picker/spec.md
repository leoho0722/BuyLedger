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

When adding is allowed, the picker SHALL provide an add control on every platform. When a payment-method add handler is provided, the add control SHALL present the payment method editor (collecting name and cardless flag); otherwise it SHALL present the add alert collecting a name. Confirming an add SHALL invoke the corresponding add callback and dismiss the picker.

#### Scenario: Add via the general alert

- **WHEN** adding is allowed, no payment-method add handler is provided, and the user confirms a non-empty trimmed name in the add alert
- **THEN** the add callback is invoked with that name and the picker dismisses

#### Scenario: Add a payment method via the editor sheet

- **WHEN** adding is allowed and a payment-method add handler is provided and the user confirms the editor sheet
- **THEN** the payment-method add callback is invoked with the name and cardless flag and the picker dismisses


<!-- @trace
source: option-picker-sheet-macos-card-style
updated: 2026-05-24
code:
  - BuyLedger/BuyLedger/Features/Orders/Components/OptionPickerSheet.swift
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