## MODIFIED Requirements

### Requirement: Campaign-to-event link with timestamp is stored in local SwiftData

The system SHALL persist, per campaign, the calendar event identifier together with the user-chosen reminder timestamp in a dedicated local SwiftData record, separate from the Campaign domain type. The Campaign domain type MUST NOT carry the calendar event identifier or the reminder timestamp, because both are device-local data.

The link record SHALL NOT outlive its campaign: deleting a campaign SHALL remove its link record in the same persistence operation that removes the campaign. A link record SHALL NOT be left pointing at an event identifier that has already been deleted; when a reminder is rebuilt, the new event SHALL be created and the link updated before the previous event is removed, so that an interruption leaves at worst a duplicate calendar entry rather than a link pointing at nothing.

#### Scenario: Link and timestamp persist across launches in SwiftData

- **WHEN** a reminder is created for a campaign
- **THEN** the campaign's event identifier and reminder timestamp are stored in their own SwiftData record and are available after relaunch, without adding any field to the Campaign domain type

#### Scenario: Deleting the campaign removes its link

- **WHEN** a campaign that has a reminder is deleted
- **THEN** its link record no longer exists

#### Scenario: Interrupted rebuild leaves a resolvable link

- **WHEN** a reminder is rebuilt and removal of the previous event fails after the new event has been created
- **THEN** the link record refers to the newly created event and the failure is reported
