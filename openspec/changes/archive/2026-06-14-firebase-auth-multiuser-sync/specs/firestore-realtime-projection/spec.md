## ADDED Requirements

### Requirement: Backend is the sole writer of Firestore

Only the backend SHALL write Firestore documents that mirror domain data. Clients SHALL NOT write these Firestore documents directly.

#### Scenario: Client writes go through the backend

- **WHEN** a client needs to create, update, or delete domain data
- **THEN** the client SHALL call the backend API, and the backend SHALL be the only writer of the corresponding Firestore documents

### Requirement: Authoritative writes are mirrored to per-user Firestore collections

After the backend commits a create or update to PostgreSQL, it SHALL upsert a matching Firestore document under the owning user's collection, reflecting the same data including the backend-computed summary. On delete, it SHALL remove the corresponding document.

#### Scenario: Create is mirrored

- **WHEN** the backend commits a new order for user with uid U
- **THEN** the backend SHALL upsert a Firestore document for that order under user U's orders collection, containing the same fields and the backend-computed summary

#### Scenario: Delete is mirrored

- **WHEN** the backend deletes an order owned by user U
- **THEN** the backend SHALL delete the corresponding Firestore document

##### Example: per-user document path

- **GIVEN** an order with id ORD1 owned by uid U1
- **WHEN** the backend mirrors it
- **THEN** the document path SHALL be `users/U1/orders/ORD1`

### Requirement: Firestore is non-authoritative

PostgreSQL SHALL remain the source of truth. A Firestore mirroring failure SHALL NOT roll back an already-committed PostgreSQL write or fail the API response; the failure SHALL be recorded so it can be retried.

#### Scenario: Mirror failure does not fail the write

- **WHEN** a PostgreSQL write commits successfully but the subsequent Firestore mirror fails
- **THEN** the API response SHALL reflect the successful PostgreSQL write, and the mirror failure SHALL be recorded for retry

### Requirement: Mirror covers all mirrored collections

The backend SHALL mirror all domain collections — orders, campaigns, lookups, and per-user settings — to Firestore.

#### Scenario: Each collection is mirrored

- **WHEN** a record in orders, campaigns, lookups, or settings is created or updated
- **THEN** the backend SHALL mirror that record to the corresponding Firestore collection

### Requirement: Mirrored documents stay within the Firestore document size limit

Mirrored documents SHALL stay within Firestore's per-document size limit. The backend SHALL NOT embed raw base64 order-photo payloads inside Firestore documents. Instead, the backend SHALL upload each order photo to Firebase Storage and store only a reference (path or download URL) in the Firestore document.

#### Scenario: Order photo is uploaded to Storage and referenced

- **WHEN** the backend mirrors an order that has an embedded base64 photo
- **THEN** the backend SHALL upload the photo to Firebase Storage, and the Firestore document SHALL contain only a Storage reference (path or URL), SHALL NOT contain the raw base64 payload, and SHALL stay within the per-document size limit

### Requirement: iOS Firestore sync is gated behind a default-off feature flag

On iOS, Firestore reads and writes SHALL be controlled by a feature flag that is disabled by default. With the flag disabled, iOS SHALL rely on local SwiftData and SHALL NOT access Firestore.

#### Scenario: iOS with flag disabled does not access Firestore

- **WHEN** iOS runs with the sync feature flag disabled
- **THEN** iOS SHALL NOT read from or write to Firestore and SHALL rely on local SwiftData
