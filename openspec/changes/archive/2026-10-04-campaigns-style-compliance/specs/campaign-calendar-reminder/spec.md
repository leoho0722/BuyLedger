## MODIFIED Requirements

### Requirement: Add/edit form defers reminder writes until save

On the campaign add/edit form, choosing or clearing a reminder SHALL only update in-memory intent and timestamp and MUST NOT touch the calendar while editing. For a new campaign the intent SHALL start unset; for an existing campaign the intent SHALL start set to whether that campaign currently has a reminder, and the timestamp SHALL start at the existing reminder's timestamp or the default. When the user saves, the system SHALL reconcile the calendar against the intent: create a reminder when intent is set and none exists, remove the reminder when intent is unset and one exists, and rebuild the reminder when intent is set, one exists, and the campaign name or the reminder timestamp changed. A rebuild SHALL create the new event and update the stored link before removing the previous event, consistent with the requirement that a link never points at a deleted event. When the user cancels, the system MUST NOT make any calendar change.

#### Scenario: New campaign with intent set creates the reminder on save

- **WHEN** the user sets a reminder timestamp for a new campaign and taps save with calendar access granted
- **THEN** the system creates the all-day event at the chosen timestamp and stores the campaign-to-event link as part of saving the campaign

#### Scenario: Canceling the form makes no calendar change

- **WHEN** the user configures a reminder and then cancels the form
- **THEN** the system makes no change to the calendar

#### Scenario: Changing name or timestamp rebuilds an existing reminder on save

- **WHEN** an existing campaign already has a reminder, its intent stays set, and the user changes the campaign name or the reminder timestamp and saves
- **THEN** the system creates a new event reflecting the updated name and timestamp, updates the stored link to it, and then removes the old event

##### Example: rebuild order

- **GIVEN** campaign "四月韓國團" links to event "E-OLD" and the user renames it to "五月韓國團"
- **WHEN** the user saves and the new event "E-NEW" is created successfully
- **THEN** the stored link refers to "E-NEW" before the system asks the calendar to remove "E-OLD"

#### Scenario: A failed new event keeps the old reminder

- **WHEN** a rebuild is required and creating the new event fails
- **THEN** the stored link still refers to the old event, the old event is not removed, and the failure is reported

##### Example: calendar refuses the new event

- **GIVEN** campaign "四月韓國團" links to event "E-OLD", the user changes the reminder time, and creating the new event fails because no writable calendar exists
- **WHEN** the user saves
- **THEN** the stored link still refers to "E-OLD", the calendar is never asked to remove "E-OLD", and the dialog "找不到可寫入的行事曆" is shown

#### Scenario: Clearing intent removes an existing reminder on save

- **WHEN** an existing campaign has a reminder, the user clears the reminder intent, and saves
- **THEN** the system deletes the linked event and clears the stored link
