## MODIFIED Requirements

### Requirement: Present in-sheet pickers via push navigation

When a picker or sub-editor is opened from within an already-presented sheet, it SHALL be presented by pushing onto the host sheet's navigation stack (gaining a system Back control) rather than by stacking a second sheet on top. This applies to the order editor's selection pickers (order source, category, payment method, reconciliation status, currency, campaign). Only one such picker SHALL be pushed at a time, and its Back control SHALL return to the parent form with no change to the selectable options or the selection outcome. Pushing and popping a picker SHALL NOT change how the host sheet closes: after returning from a pushed picker, the editor's Cancel and Save controls SHALL close the sheet exactly as they do when no picker was opened. The campaign editor's reminder time is instead edited inline in the form (see its scenario) — no separate presentation at all, which trivially avoids stacking a second sheet.

#### Scenario: Selecting from the order editor pushes instead of stacking a sheet

- **WHEN** the user taps a selection picker row inside the order editor sheet
- **THEN** the picker is pushed onto the same navigation stack with a Back control, and no second sheet is stacked over the editor

#### Scenario: Back returns to the editor form

- **WHEN** a pushed picker is showing and the user taps Back
- **THEN** the picker is popped and the editor form is shown, with any completed selection already applied

#### Scenario: Cancel closes the order editor after returning from a picker

- **GIVEN** a new order editor sheet with no unsaved changes
- **WHEN** the user opens the order source picker, taps Back without selecting, and then taps Cancel
- **THEN** the order editor sheet closes and the orders list is shown

#### Scenario: Save closes the order editor after selecting through pickers

- **GIVEN** a new order editor sheet
- **WHEN** the user enters a customer name, selects an order source and a category through their pushed pickers, and taps Save
- **THEN** the order is saved, the order editor sheet closes, and the new order appears in the orders list

#### Scenario: Reminder time is edited inline in the campaign editor

- **WHEN** the user enables the reminder toggle in the campaign editor sheet
- **THEN** the reminder date and time appear as an inline DatePicker row within the form (identical to the open/close date rows, opening the system's native calendar/time popover on tap), with no separate sheet, push, or dialog presented

### Requirement: Add-new sub-editors avoid a third stacked sheet

When the user adds a new item from within a picker that is itself presented inside an editing sheet — specifically adding a payment method from the order editor's payment method picker — the add-new editor SHALL be pushed onto the current navigation stack rather than presented as an additional sheet, so the presentation never exceeds one sheet plus in-sheet navigation. Submitting the add-new editor SHALL return to the picker it was pushed from and SHALL NOT close the host editing sheet.

#### Scenario: Adding a payment method pushes rather than stacking a third sheet

- **WHEN** the user taps "add payment method" from within the order editor's payment method picker
- **THEN** the add-payment-method editor is pushed onto the current navigation stack, and at no point are three sheets stacked

#### Scenario: Submitting a new payment method returns to the picker and keeps the order editor

- **GIVEN** a new order editor sheet with the payment method picker pushed and the add-payment-method editor pushed above it
- **WHEN** the user enters a name and taps the editor's submit control
- **THEN** the add-payment-method editor is popped, the payment method picker shows the new payment method, and after tapping Back the order editor is still presented with the new payment method selected

