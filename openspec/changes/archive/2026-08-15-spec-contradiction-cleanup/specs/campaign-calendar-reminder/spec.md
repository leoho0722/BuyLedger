## REMOVED Requirements

### Requirement: Reminder is configured via a date-and-time popup on the add/edit form

**Reason**: The popup design was rejected twice during implementation and replaced by an inline DatePicker inside the form. The requirement described a button, a presented popup, and a destructive remove button that no longer exist in the codebase, and it contradicted the inline wording already recorded in the sheet-nested-presentation capability.

**Migration**: Replaced by the requirement "Reminder is configured inline on the add/edit form" in this same capability. No data shape changes: the reminder intent and its timestamp are still form draft state that lands on save.

## ADDED Requirements

### Requirement: Reminder is configured inline on the add/edit form

On the campaign add/edit form, the campaign-info section SHALL express reminder intent through a toggle. When the toggle is on, the same form SHALL show an inline date-and-time picker row, visually identical to the open-date and close-date rows, which opens the system's native calendar and time popover on tap. The picker SHALL default to the campaign's close date, or today when there is no close date, at 09:00. The chosen timestamp SHALL be form draft state that lands when the whole form is saved and is discarded when the form is cancelled. The reminder SHALL NOT be configured through a separate sheet, a pushed destination, or a custom dialog.

#### Scenario: Enabling the toggle reveals the inline picker

- **WHEN** the campaign has no reminder intent and the user turns the reminder toggle on
- **THEN** an inline date-and-time picker row appears within the same form, defaulting to the close date or today at 09:00, and no sheet, pushed destination, or custom dialog is presented

#### Scenario: Disabling the toggle clears the reminder intent

- **WHEN** the reminder toggle is on and the user turns it off
- **THEN** the inline picker row is hidden and the form no longer carries reminder intent

#### Scenario: Chosen timestamp is draft state until save

- **WHEN** the user selects a reminder date and time and then cancels the form
- **THEN** no reminder is created and the previously stored reminder state is unchanged

##### Example: default timestamp resolution

| Campaign close date | Resulting picker default |
| ------------------- | ------------------------ |
| 2026-04-26 | 2026-04-26 09:00 |
| none | today at 09:00 |
