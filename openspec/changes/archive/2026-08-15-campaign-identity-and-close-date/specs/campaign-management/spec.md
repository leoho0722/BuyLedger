## MODIFIED Requirements

### Requirement: Campaign entity with two-state lifecycle

The system SHALL provide a Campaign entity with a name, an open date, an optional close date, a lifecycle status, an optional settled date, and notes. The status SHALL be exactly one of two values: ongoing ("開團中") and closed ("已收單"). A newly created campaign SHALL have status ongoing and no settled date.

A campaign name SHALL be unique among campaigns. Because orders relate to campaigns by name rather than by identifier, a duplicate name would let one set of orders count toward two campaigns, would let a rename affect the wrong campaign's orders, and would make name-based navigation reach only one of them. Saving SHALL therefore reject a name that already belongs to another campaign, compared after trimming surrounding whitespace and excluding the campaign being edited. The rejection SHALL happen before any write occurs and SHALL state the reason on the form.

Campaigns that already carry duplicate names from before this rule SHALL remain readable and editable. This capability does not detect, merge, or rename existing duplicates, so the aggregation and navigation consequences described above remain possible for pre-existing data. That is a known limitation, not a closed risk.

#### Scenario: Create a campaign

- **WHEN** the user creates a campaign with a name and an open date
- **THEN** the campaign is persisted with status ongoing and no settled date

#### Scenario: Duplicate name is rejected before any write

- **WHEN** the user saves a campaign whose trimmed name already belongs to another campaign
- **THEN** the save is rejected, the reason is shown on the form, and the stored campaign count is unchanged

#### Scenario: Editing a campaign keeps its own name

- **WHEN** the user edits an existing campaign without changing its name and saves
- **THEN** the save succeeds, because the uniqueness comparison excludes the campaign being edited

#### Scenario: Pre-existing duplicates remain usable

- **WHEN** two campaigns sharing a name existed before this rule and the user opens and saves either one without renaming it
- **THEN** the save succeeds

### Requirement: Automatic transition from ongoing to closed at the close date

The system SHALL automatically transition a campaign from ongoing to closed once the close date's day has passed. The comparison SHALL be made at day granularity using an injected calendar: a campaign whose close date falls on the current day SHALL remain ongoing, and SHALL transition only from the following day onward. Timestamp-level comparison SHALL NOT be used, because the close date is chosen as a date while the stored value carries the time of creation, which would close a campaign within minutes of being created with today's date.

The evaluation SHALL run when the app launches and when the campaign list or orders list is opened, using an injected current date rather than reading the system clock directly. A campaign without a close date SHALL remain ongoing until changed manually. The transition SHALL apply only to campaigns whose status is ongoing.

A campaign that was already transitioned to closed under the previous timestamp-level comparison SHALL NOT automatically revert to ongoing under this day-granularity comparison, because the transition only evaluates campaigns whose status is currently ongoing. Reopening such a campaign requires a manual status change. That is a known limitation, not a closed risk.

#### Scenario: Close date today stays ongoing

- **WHEN** the system evaluates an ongoing campaign whose close date falls on the current day
- **THEN** the campaign status remains ongoing

#### Scenario: Past close date transitions to closed

- **WHEN** the system evaluates an ongoing campaign whose close date fell on an earlier day
- **THEN** the campaign status becomes closed and the change is persisted

#### Scenario: Missing close date stays ongoing

- **WHEN** the system evaluates an ongoing campaign that has no close date
- **THEN** the campaign status remains ongoing

#### Scenario: Previously mis-closed campaign does not auto-revert

- **WHEN** a campaign was already transitioned to closed under the previous timestamp-level comparison, even though its close date falls on the current day under this day-granularity rule
- **THEN** the campaign status remains closed until the user manually changes it

##### Example: transition evaluation at day granularity

| Status before | Close date relative to current day | Status after |
| ------------- | ---------------------------------- | ------------ |
| ongoing       | an earlier day                     | closed       |
| ongoing       | the current day, earlier time      | ongoing      |
| ongoing       | the current day, later time        | ongoing      |
| ongoing       | a later day                        | ongoing      |
| ongoing       | none                               | ongoing      |
| closed        | an earlier day                     | closed       |
