## ADDED Requirements

### Requirement: Values an editor opens with or re-confirms do not make it dirty

An editor's dirty state SHALL compare against the values it was opened with, including values prefilled by the entry point — such as the fields a merge confirmation prefills from the source orders, or the default currency of a new order — so that opening an editor never makes it dirty by itself. Choosing a value equal to the current one, such as re-selecting the same date and time in the order editor, SHALL leave the draft unchanged and SHALL NOT make the editor dirty. Returning the order editor's date and time to the minute it was opened with, after moving it elsewhere, SHALL restore the opened value exactly and SHALL NOT leave the editor dirty.

#### Scenario: A merge confirmation opens clean

- **WHEN** the user opens the merge confirmation form for two orders
- **THEN** the form is not dirty, swiping down dismisses it, and cancelling closes it without a discard confirmation

#### Scenario: Editing a prefilled merge field makes it dirty

- **WHEN** the user changes the customer name in an open merge confirmation form
- **THEN** the form becomes dirty and resists swipe-to-dismiss

#### Scenario: Re-selecting the same date does not make the order editor dirty

- **GIVEN** an order editor opened with the date 2026-04-26 14:30
- **WHEN** the user picks 2026-04-26 14:30 again in the date picker
- **THEN** the draft date is unchanged and the editor is not dirty

#### Scenario: Moving the order time away and back leaves the editor clean

- **GIVEN** an order editor opened with the date 2026-04-26 14:30:00 and a current time whose seconds are 37
- **WHEN** the user moves the time to 14:31 and then back to 14:30
- **THEN** the draft date is 2026-04-26 14:30:00 again and the editor is not dirty
