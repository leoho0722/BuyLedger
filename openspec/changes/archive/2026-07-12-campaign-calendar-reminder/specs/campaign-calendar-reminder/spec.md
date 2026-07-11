## ADDED Requirements

### Requirement: Order-reminder as an all-day event at a user-chosen date and time

The system SHALL create an order reminder as an all-day calendar event whose date and alert time come from a user-chosen timestamp. The event SHALL be all-day on the start of day of that timestamp, and SHALL carry a single alert that fires at the time-of-day of that timestamp. The event title SHALL be the campaign name wrapped in corner brackets followed by the words "訂購提醒" (for example, a campaign named "四月團" yields the title "「四月團」訂購提醒"). Deriving the event date and alert offset from the timestamp SHALL use an injected calendar and MUST NOT read the process-wide current calendar.

#### Scenario: All-day event on the chosen date with alert at the chosen time

- **WHEN** the user's chosen reminder timestamp is 2026-04-20 18:00 and the reminder is created
- **THEN** the calendar event is all-day on 2026-04-20 and its alert fires at 18:00 that day, titled the campaign name in corner brackets followed by "訂購提醒"

### Requirement: Reminder is configured via a date-and-time popup on the add/edit form

On the campaign add/edit form, the campaign-info section SHALL show a reminder row. When the campaign has no reminder intent, the row's control SHALL be a blue "新增提醒" button; tapping it SHALL present a popup containing a calendar-and-time picker (date plus hour and minute) defaulting to the campaign's close date, or today when there is no close date, at 09:00. Confirming the popup SHALL set the reminder intent and record the chosen timestamp; canceling the popup SHALL leave the intent unchanged. When the reminder intent is set, the row SHALL show the chosen reminder date and time and a red destructive-role "移除提醒" button that clears the intent, and re-opening the popup SHALL allow editing the timestamp.

#### Scenario: Add button opens the date-and-time popup

- **WHEN** the campaign has no reminder intent and the user taps "新增提醒"
- **THEN** a popup with a date-and-time picker appears, defaulting to the close date (or today) at 09:00

#### Scenario: Confirming the popup sets the intent and timestamp

- **WHEN** the user picks 2026-04-26 18:00 in the popup and confirms
- **THEN** the reminder intent becomes set, the chosen timestamp is recorded, and the row shows the chosen date and time with a red "移除提醒" button

### Requirement: Add/edit form defers reminder writes until save

On the campaign add/edit form, choosing or clearing a reminder SHALL only update in-memory intent and timestamp and MUST NOT touch the calendar while editing. For a new campaign the intent SHALL start unset; for an existing campaign the intent SHALL start set to whether that campaign currently has a reminder, and the timestamp SHALL start at the existing reminder's timestamp or the default. When the user saves, the system SHALL reconcile the calendar against the intent: create a reminder when intent is set and none exists, remove the reminder when intent is unset and one exists, and rebuild the reminder (remove then recreate) when intent is set, one exists, and the campaign name or the reminder timestamp changed. When the user cancels, the system MUST NOT make any calendar change.

#### Scenario: New campaign with intent set creates the reminder on save

- **WHEN** the user sets a reminder timestamp for a new campaign and taps save with calendar access granted
- **THEN** the system creates the all-day event at the chosen timestamp and stores the campaign-to-event link as part of saving the campaign

#### Scenario: Canceling the form makes no calendar change

- **WHEN** the user configures a reminder and then cancels the form
- **THEN** the system makes no change to the calendar

#### Scenario: Changing name or timestamp rebuilds an existing reminder on save

- **WHEN** an existing campaign already has a reminder, its intent stays set, and the user changes the campaign name or the reminder timestamp and saves
- **THEN** the system removes the old event and creates a new event reflecting the updated name and timestamp

#### Scenario: Clearing intent removes an existing reminder on save

- **WHEN** an existing campaign has a reminder, the user clears the reminder intent, and saves
- **THEN** the system deletes the linked event and clears the stored link

### Requirement: Calendar access is requested lazily and denial is surfaced

The system SHALL request full calendar access only at the moment a reminder is created or removed (during save reconcile), not at app launch. When calendar access is denied, the system MUST NOT create the event, MUST NOT record a link, and SHALL surface an explanatory alert rather than failing silently. Removing an event whose identifier no longer exists in the calendar SHALL be treated as a no-op without error.

#### Scenario: Access denied surfaces an alert

- **WHEN** saving would create a reminder but calendar access is denied
- **THEN** the system creates no event, records no link, and shows an alert explaining that calendar access is required

### Requirement: Detail view displays the reminder read-only

The campaign detail view SHALL be read-only with respect to reminders: it MUST NOT provide add or remove controls. When and only when a reminder exists for the campaign, the campaign-info section SHALL display a row showing the reminder's date and time. Managing the reminder (adding, editing the timestamp, or removing) SHALL be done from the add/edit form.

#### Scenario: Detail view shows the reminder when one exists

- **WHEN** a campaign has an order reminder and its detail view is shown
- **THEN** the campaign-info section shows a read-only row with the reminder's date and time and no add/remove control

#### Scenario: Detail view shows no reminder row when none exists

- **WHEN** a campaign has no order reminder and its detail view is shown
- **THEN** the campaign-info section shows no reminder row

### Requirement: Campaign-to-event link with timestamp is stored in local SwiftData

The system SHALL persist, per campaign, the calendar event identifier together with the user-chosen reminder timestamp in a dedicated local SwiftData record, separate from the cross-platform Campaign data model. The cross-platform Campaign type MUST NOT carry the calendar event identifier or the reminder timestamp.

#### Scenario: Link and timestamp persist across launches in SwiftData

- **WHEN** a reminder is created for a campaign
- **THEN** the campaign's event identifier and reminder timestamp are stored in their own SwiftData record and are available after relaunch, without adding any field to the cross-platform Campaign type
