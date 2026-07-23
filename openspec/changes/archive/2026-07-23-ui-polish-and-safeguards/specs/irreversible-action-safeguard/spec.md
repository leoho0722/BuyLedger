## ADDED Requirements

### Requirement: Irreversible state transitions require confirmation

A state transition that cannot be undone from within the app SHALL require confirmation before it proceeds, and the confirmation SHALL state that the action cannot be reversed. This applies regardless of whether the transition deletes data, because an irreversible write is no more recoverable than a deletion.

#### Scenario: Campaign settlement is confirmed

- **WHEN** the user activates campaign settlement
- **THEN** a confirmation is presented stating that settlement cannot be undone, and no settlement date is written until it is confirmed

#### Scenario: Declining settlement writes nothing

- **WHEN** the user dismisses the settlement confirmation without confirming
- **THEN** the campaign remains unsettled and its settlement action remains available

### Requirement: Sheets holding uncommitted changes resist accidental dismissal

A sheet that stages changes and commits them only on an explicit action SHALL prevent interactive dismissal while uncommitted changes exist, and its cancel action SHALL present a discard confirmation. This matches the protection already applied to editing sheets elsewhere in the app.

#### Scenario: Filter sheet resists dismissal with pending changes

- **WHEN** the user has changed a pending filter value and attempts to dismiss the sheet by dragging
- **THEN** the sheet does not dismiss

#### Scenario: Cancelling with pending changes asks first

- **WHEN** the user has changed a pending filter value and activates cancel
- **THEN** a discard confirmation is presented, offering to discard the changes or continue editing

#### Scenario: Unchanged sheet dismisses freely

- **WHEN** the user has made no changes to pending filter values and drags to dismiss
- **THEN** the sheet dismisses without confirmation

### Requirement: Multi-selection pickers offer a way out that is not completion

A picker presented as its own sheet SHALL provide a cancellation action alongside its completion action, so that completing the task is not the only exit. Where the picker is embedded within a host navigation stack, the host's back affordance SHALL serve as the exit and no duplicate cancellation SHALL be added.

#### Scenario: Standalone multi-selection picker offers cancel

- **WHEN** a multi-selection picker is presented as its own sheet rather than embedded
- **THEN** both a cancellation action and a completion action are available

#### Scenario: Embedded picker relies on the host back affordance

- **WHEN** a multi-selection picker is embedded within a host navigation stack
- **THEN** it presents no cancellation action of its own, and the host back affordance returns the user to the previous screen
