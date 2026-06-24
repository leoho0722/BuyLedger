## MODIFIED Requirements

### Requirement: iOS Firestore sync is gated behind a default-off feature flag

On iOS, Firestore reads and writes SHALL be controlled by a feature flag that is disabled by default. With the flag disabled, iOS SHALL rely on local SwiftData and SHALL NOT access Firestore, SHALL NOT call the backend API, and SHALL NOT migrate its on-disk store for sync. With the flag enabled and the user signed in, iOS SHALL consume the per-user projection live, merging it field-wise into local SwiftData, while local SwiftData remains the local source of truth and offline create, edit, and delete continue to work.

#### Scenario: iOS with flag disabled does not access Firestore

- **WHEN** iOS runs with the sync feature flag disabled
- **THEN** iOS SHALL NOT read from or write to Firestore, SHALL NOT call the backend API, and SHALL rely on local SwiftData

#### Scenario: iOS with flag enabled consumes the projection live

- **WHEN** iOS runs with the sync feature flag enabled and the user is signed in
- **THEN** iOS SHALL subscribe to the per-user projection and merge incoming changes field-wise into local SwiftData while keeping local edits offline-capable

## ADDED Requirements

### Requirement: Projection carries clocks, tombstones, and photo references

The per-user Firestore projection SHALL carry per-field HLC clocks, an explicit deleted flag with a deleteClock, and photo references rather than base64 image payloads. Clients SHALL consume the projection live through real-time listeners and SHALL reconcile a full re-read on every subscribe or relaunch. The backend SHALL remain the sole writer of Firestore and Firebase Storage, and Postgres SHALL remain the source of truth.

#### Scenario: Client merges live projection updates

- **WHEN** the backend mirrors a merged order
- **THEN** subscribed clients SHALL receive the document with its field clocks and SHALL merge it field-wise, resolving photo references to bytes before the merge

#### Scenario: Delete is an explicit event

- **WHEN** an order is deleted
- **THEN** the projection SHALL carry an explicit deleted marker with a deleteClock rather than document absence, and the document SHALL be purged only after the bounded retention window

### Requirement: A permanently failed mirror still converges

A mirror failure SHALL do bounded inline retry, then log and return success without rolling back the committed Postgres write. On exhausting inline retries, the backend SHALL stamp a per-row mirror-dirty key, and a background or lazy sweep SHALL re-mirror dirty rows recomputed from Postgres so that the projection self-heals. This mechanism SHALL NOT be a persistent payload outbox.

#### Scenario: Permanently failed mirror is repaired by the sweep

- **WHEN** a mirror exhausts its inline retries and no later write touches the entity
- **THEN** the row SHALL be marked mirror-dirty, the sweep SHALL re-mirror it from Postgres, and an offline device reconnecting SHALL reach the Postgres value rather than a stale document
