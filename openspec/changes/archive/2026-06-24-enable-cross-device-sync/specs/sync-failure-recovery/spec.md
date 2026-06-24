## ADDED Requirements

### Requirement: Bounded client retry then observable pending or failed state

A client write that fails because of being offline, a network error, or a 5xx response SHALL retry up to 3 times with backoff. If the write still fails, the affected record SHALL show an observable pending or failed state, SHALL remain in a durable local queue, and SHALL auto-resend on reconnect or next launch. The client SHALL NOT drop the user's input on failure and SHALL NOT render fake or hardcoded data in place of the failed record.

#### Scenario: Failed write surfaces and auto-resends

- **WHEN** a push fails 3 times
- **THEN** the record SHALL show a pending or failed indication, SHALL stay queued, and SHALL auto-resend on reconnect or relaunch

#### Scenario: Offline edits drain in order on reconnect

- **WHEN** several edits are queued while offline and connectivity returns
- **THEN** the queued patches SHALL be resent and merged at the backend, and the records SHALL transition to a synced state

### Requirement: Resends are idempotent and side effects are clock-guarded

Resends SHALL be idempotent through client-generated UUID upsert and a deterministic server clock, so that a redelivered patch is a no-op. Cross-entity merge side effects, such as flipping source orders to merged status, MUST be clock-guarded and MUST short-circuit when the merged entity already exists, so that a resend cannot revert a concurrent later edit. The system SHALL NOT rely on a persistent server-side payload outbox.

#### Scenario: Lost-ack resend does not duplicate or revert

- **WHEN** the first push lands but its response is lost and the client resends the same create or patch
- **THEN** no duplicate entity SHALL be created and no concurrent later edit on a source order SHALL be reverted

##### Example: idempotent merge-create resend

- **GIVEN** an order merge that creates M and flips sources A and B to merged at mergeClock 10, and a later concurrent edit sets A back to active at clock 12
- **WHEN** the merge-create patch is redelivered
- **THEN** the transaction SHALL short-circuit because M exists, and A SHALL remain active at clock 12

### Requirement: A lost ack does not pin a field dirty forever

When a push lands but its acknowledgement is lost, a client SHALL clear the field's dirty flag by reconciling against the projection on resubscribe rather than re-pushing indefinitely. When the projection already reflects the device's value at a clock greater than or equal to the local dirty clock, the client SHALL clear the dirty flag even though the original acknowledgement was lost.

#### Scenario: Dirty clears via projection reconciliation

- **WHEN** an iOS push lands but its ack is lost
- **THEN** on resubscribe the device SHALL detect its value in the projection at a clock greater than or equal to the local dirty clock and SHALL clear the dirty flag, and the queue SHALL NOT remain wedged
