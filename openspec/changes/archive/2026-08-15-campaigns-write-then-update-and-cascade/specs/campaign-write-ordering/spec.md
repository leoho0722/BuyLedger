## ADDED Requirements

### Requirement: Campaign write paths update presented state only after persistence resolves

Every campaign write path SHALL update the presented state only after the persistence operation succeeds. This covers saving a campaign, changing its status, settling it, and deleting it from either the list or the detail view. Optimistic mutation SHALL NOT be used on any of these paths.

#### Scenario: Failed settle leaves the campaign unsettled

- **WHEN** the user settles a campaign and persistence fails
- **THEN** the campaign shows no settled date and remains in its previous status

#### Scenario: Failed status change leaves the status unchanged

- **WHEN** the user changes a campaign's status and persistence fails
- **THEN** the campaign retains its previous status in the list

#### Scenario: Failed delete leaves the campaign visible

- **WHEN** the user confirms deleting a campaign and persistence fails
- **THEN** the campaign remains visible in the list

#### Scenario: Presented campaigns survive a relaunch unchanged

- **WHEN** any campaign write fails and the campaigns are subsequently reloaded from storage
- **THEN** the reloaded list is identical to what was presented immediately after the failure

### Requirement: Campaign write failures are visible to the user

A failed campaign write SHALL be presented to the user as a dismissible dialog stating the reason. A failure message SHALL NOT be written to state that no presentation reads, because that leaves the code appearing to handle errors while the user observes nothing. Load failures SHALL keep their existing persistent presentation and SHALL NOT share a carrier with one-shot operation failures.

#### Scenario: Silent failure is not possible

- **WHEN** any campaign write fails
- **THEN** a dialog stating the reason is presented to the user

#### Scenario: Dismissal leaves no residue

- **WHEN** the user dismisses a campaign write failure dialog
- **THEN** no error text remains in the campaign presentation

#### Scenario: No unread failure carrier remains

- **WHEN** the campaign feature state is inspected
- **THEN** it holds no failure message field that no presentation reads

### Requirement: Deleting a campaign removes every trace of it

Deleting a campaign SHALL remove the campaign record, remove its name from the campaign-name list of every order that carries it, and remove its reminder link record. These three SHALL be committed in a single persistence operation, so that a failure leaves none of them applied. After the local commit succeeds, the corresponding calendar event SHALL be removed.

Calendar event removal SHALL NOT roll back the local deletion when it fails, because the user's intent was to delete the campaign and an orphaned calendar entry is visible and removable by the user. Such a failure SHALL nonetheless be reported.

#### Scenario: Deletion clears orders, link, and calendar

- **WHEN** the user deletes a campaign that has member orders and a reminder
- **THEN** the campaign is gone, no order lists its name, its reminder link record is absent, and the calendar event is removed

#### Scenario: Local deletion is all or nothing

- **WHEN** any part of the local deletion fails
- **THEN** the campaign still exists and no order has had the campaign name removed

#### Scenario: Calendar failure does not resurrect the campaign

- **WHEN** the local deletion succeeds and calendar event removal fails
- **THEN** the campaign remains deleted and the calendar failure is reported to the user

### Requirement: Duplicate-name rejection stays ahead of any write

The campaign name uniqueness check SHALL remain the first step of the save flow and SHALL return before any write or calendar reconciliation occurs. Reordering the save flow to write before updating state SHALL NOT move this check after the write, because a duplicate name is fully decidable before any side effect.

#### Scenario: Duplicate name never reaches persistence

- **WHEN** a save is attempted with a name that belongs to another campaign
- **THEN** no persistence call and no calendar call is made
