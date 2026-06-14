## ADDED Requirements

### Requirement: Domain entities are owned by a single user

Every order, campaign, and lookup record SHALL carry an owner identifier that corresponds to a Firebase uid. On creation, the owner SHALL be set to the authenticated caller's uid.

#### Scenario: Creating a record assigns ownership to the caller

- **WHEN** an authenticated user creates an order
- **THEN** the stored record SHALL have the caller's uid as its owner

### Requirement: Reads are scoped to the caller's uid

Read operations SHALL return only records owned by the authenticated caller and SHALL NOT expose records owned by any other user.

#### Scenario: Cross-user isolation on read

- **WHEN** user A requests their orders
- **THEN** the response SHALL contain only records owned by A and SHALL NOT contain any record owned by another user

##### Example: two users with separate orders

- **GIVEN** order O1 owned by user A and order O2 owned by user B
- **WHEN** user A lists orders
- **THEN** the result contains O1 and does not contain O2

### Requirement: Writes target only records owned by the caller

Update and delete operations SHALL only affect records owned by the authenticated caller. An attempt to modify a record owned by another user SHALL NOT mutate that record.

#### Scenario: Writing another user's record is rejected

- **WHEN** user A attempts to update or delete a record owned by user B
- **THEN** the backend SHALL NOT modify the record and SHALL respond as not found within A's scope

### Requirement: Settings are per-user

Settings SHALL be stored and retrieved per user, keyed by uid, replacing the previous global singleton. Each user SHALL have an independent settings record.

#### Scenario: Each user reads their own settings

- **WHEN** user A and user B each read settings
- **THEN** each SHALL receive their own settings record, and a change by A SHALL NOT affect B's settings

### Requirement: Seeded development data carries explicit ownership

The system SHALL NOT assume pre-existing unowned data. When the development database is seeded, every seeded domain record SHALL be assigned an explicit owner uid.

#### Scenario: Seed assigns owners

- **WHEN** the development database is seeded
- **THEN** every seeded order, campaign, and lookup record SHALL have an owner uid
