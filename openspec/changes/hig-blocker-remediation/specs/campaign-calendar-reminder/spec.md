## MODIFIED Requirements

### Requirement: Calendar access is requested lazily and denial is surfaced

The system SHALL request full calendar access only at the moment a reminder is created or removed (during save reconcile), not at app launch. When calendar access is denied, the system MUST NOT create the event, MUST NOT record a link, and SHALL surface an explanatory alert rather than failing silently. Removing an event whose identifier no longer exists in the calendar SHALL be treated as a no-op without error.

The denial path SHALL be entered only when the access request itself reports that access was not granted. Failures that occur after access has been granted — including event save failure, a missing event identifier, and link persistence failure — SHALL NOT be reported through the denial path, because directing a user to change a permission that is already granted cannot resolve the failure.

#### Scenario: Access denied surfaces an alert

- **WHEN** saving would create a reminder but calendar access is denied
- **THEN** the system creates no event, records no link, and shows an alert explaining that calendar access is required

#### Scenario: Granted access does not route to the denial path

- **WHEN** calendar access has been granted and reminder creation subsequently fails
- **THEN** the denial alert is not shown

## ADDED Requirements

### Requirement: Reminder creation failure is reported distinctly from permission denial

When calendar access has been granted but creating the reminder fails, the system SHALL surface a message describing that the reminder could not be created, and that message SHALL NOT mention permissions or direct the user to system settings. The failure SHALL leave no partially recorded state: no link SHALL be persisted for an event that was not successfully created.

#### Scenario: Event save failure reports a creation failure

- **WHEN** calendar access has been granted and saving the calendar event fails
- **THEN** the system shows a message stating that the reminder could not be created, without mentioning permissions, and records no link

#### Scenario: Missing event identifier reports a creation failure

- **WHEN** the calendar event is saved but no event identifier can be retrieved
- **THEN** the system shows the creation failure message and records no link

#### Scenario: Link persistence failure reports a creation failure

- **WHEN** the calendar event is created but persisting the campaign-to-event link fails
- **THEN** the system shows the creation failure message rather than the permission message

##### Example: failure routing

| Condition | Message shown |
| --------- | ------------- |
| Access request reports not granted | permission explanation, directs to settings |
| Access granted, event save throws | creation failure, no permission mention |
| Access granted, event identifier missing | creation failure, no permission mention |
| Access granted, link persistence throws | creation failure, no permission mention |
