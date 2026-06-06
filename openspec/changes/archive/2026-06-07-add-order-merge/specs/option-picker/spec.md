## ADDED Requirements

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
