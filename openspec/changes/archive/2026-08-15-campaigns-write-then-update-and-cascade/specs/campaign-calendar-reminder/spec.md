## MODIFIED Requirements

### Requirement: Campaign-to-event link with timestamp is stored in local SwiftData

The system SHALL persist, per campaign, the calendar event identifier together with the user-chosen reminder timestamp in a dedicated local SwiftData record, separate from the cross-platform Campaign data model. The cross-platform Campaign type MUST NOT carry the calendar event identifier or the reminder timestamp.

The link record SHALL NOT outlive its campaign: deleting a campaign SHALL remove its link record in the same persistence operation that removes the campaign. A link record SHALL NOT be left pointing at an event identifier that has already been deleted; when a reminder is rebuilt, the new event SHALL be created and the link updated before the previous event is removed, so that an interruption leaves at worst a duplicate calendar entry rather than a link pointing at nothing.

#### Scenario: Link and timestamp persist across launches in SwiftData

- **WHEN** a reminder is created for a campaign
- **THEN** the campaign's event identifier and reminder timestamp are stored in their own SwiftData record and are available after relaunch, without adding any field to the cross-platform Campaign type

#### Scenario: Deleting the campaign removes its link

- **WHEN** a campaign that has a reminder is deleted
- **THEN** its link record no longer exists

#### Scenario: Interrupted rebuild leaves a resolvable link

- **WHEN** a reminder is rebuilt and removal of the previous event fails after the new event has been created
- **THEN** the link record refers to the newly created event and the failure is reported

### Requirement: Calendar access is requested lazily and denial is surfaced

The system SHALL request full calendar access only at the moment a reminder is created or removed (during save reconcile), not at app launch. When calendar access is denied, the system MUST NOT create the event, MUST NOT record a link, and SHALL surface an explanatory alert rather than failing silently. Removing an event whose identifier no longer exists in the calendar SHALL be treated as a no-op without error.

The denial path SHALL be entered only when the access request itself reports that access was not granted. Failures that occur after access has been granted — including event save failure, a missing event identifier, and link persistence failure — SHALL NOT be reported through the denial path, because directing a user to change a permission that is already granted cannot resolve the failure.

Access unavailability SHALL be reported in the terms the user can act on. Access restricted by device policy SHALL be distinguished from access declined by the user, because only the latter can be changed in settings. The absence of any writable calendar SHALL have its own message and SHALL NOT be reported as a permission problem, because opening settings cannot resolve it.

#### Scenario: Access denied surfaces an alert

- **WHEN** saving would create a reminder but calendar access is denied
- **THEN** the system creates no event, records no link, and shows an alert explaining that calendar access is required

#### Scenario: Granted access does not route to the denial path

- **WHEN** calendar access has been granted and reminder creation subsequently fails
- **THEN** the denial alert is not shown

#### Scenario: Restricted access is distinguished from declined access

- **WHEN** calendar access is unavailable because device policy restricts it
- **THEN** the message differs from the one shown when the user declined access, and it does not direct the user to change a setting they cannot change

#### Scenario: No writable calendar is not a permission message

- **WHEN** access is granted but no writable calendar exists
- **THEN** the message states that no writable calendar was found rather than describing a permission problem
