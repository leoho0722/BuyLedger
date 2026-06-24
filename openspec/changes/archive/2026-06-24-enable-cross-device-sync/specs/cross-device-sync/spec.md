## ADDED Requirements

### Requirement: Opt-in cross-device propagation between same-account platforms

The system SHALL propagate Order and Campaign changes between any two clients signed into the same account (iOS↔web, iOS↔Android, Android↔web) using Postgres as the server source of truth and the per-user Firestore projection as the live read path. On iOS, cross-device sync SHALL be opt-in and OFF by default; when OFF, the iOS app SHALL remain fully offline-capable for create, edit, and delete, with byte-for-byte unchanged on-disk behavior and with no sync engine, no listener, no backend API client, and no schema migration instantiated.

#### Scenario: Sync off keeps the app offline-first and unchanged

- **WHEN** the iOS sync flag is OFF and the user creates, edits, or deletes an order with no network
- **THEN** the operation SHALL complete locally against SwiftData exactly as before, and no network call, listener, or schema migration SHALL occur

#### Scenario: Edit on device A appears on device B

- **WHEN** sync is ON on both devices and device A edits an order field while online
- **THEN** device B SHALL receive the change live through its Firestore projection listener and SHALL reflect the merged value without a manual refresh

#### Scenario: Offline edit propagates on reconnect

- **WHEN** device A edits an order while offline and later reconnects
- **THEN** the queued change SHALL be pushed, merged at the backend, mirrored, and observed by device B

### Requirement: Clients write through the backend and read the projection

Clients SHALL perform domain writes by sending a partial patch to the backend API and SHALL NOT write Firestore or Firebase Storage directly. Clients SHALL obtain cross-device updates by consuming the per-user Firestore projection. The web client SHALL subscribe with real-time listeners and SHALL continue to perform writes through the backend REST API; it SHALL show an empty state and SHALL NOT render placeholder or hardcoded data when the projection has no documents.

#### Scenario: Web subscribes and reflects an external change

- **WHEN** the web client is subscribed to its per-user collections and the backend mirrors a change made by another device
- **THEN** the web client SHALL update its cached data from the snapshot and re-render without a manual refresh

#### Scenario: iOS local-first write then push

- **WHEN** sync is ON and the user edits an order on iOS
- **THEN** iOS SHALL write the change to local SwiftData immediately and SHALL push the changed fields to the backend, never writing Firestore or Storage directly
