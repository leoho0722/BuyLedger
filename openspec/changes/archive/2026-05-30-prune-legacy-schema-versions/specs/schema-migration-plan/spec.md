## ADDED Requirements

### Requirement: Contiguous migration chain from floor to target

The migration plan SHALL declare its versioned schemas as a contiguous, totally-ordered chain from the lowest supported store version (the floor) up to and including the current target schema, and SHALL provide exactly one migration stage bridging each adjacent version pair. The ModelContainer SHALL be constructed against the target schema together with this migration plan.

#### Scenario: Store at the floor version migrates to the target

- **WHEN** an on-disk store persisted at the floor schema version is opened with the migration plan
- **THEN** the bridging stage runs and the store is migrated to the target version

#### Scenario: Store already at the target opens without migration

- **WHEN** an on-disk store already at the target schema version is opened
- **THEN** no migration stage runs and the store opens unchanged

### Requirement: Data preservation across retained migrations

Opening a store at any retained version SHALL preserve every persisted record and its field values through migration to the target. No retained migration stage SHALL drop or corrupt existing rows.

#### Scenario: Orders survive floor-to-target migration

- **WHEN** a store written at the floor version contains order records and their related master data
- **THEN** after opening with the plan, all order records and their fields remain intact at the target version

##### Example: three orders survive V7 to V8 migration

- **GIVEN** an on-disk store at the floor version (V7) containing 3 order records with currency, orderSource, notes, and verificationStatus set
- **WHEN** the store is reopened with the collapsed migration plan targeting V8
- **THEN** all 3 order records are present and each preserves its currency, orderSource, notes, and verificationStatus values

### Requirement: Removing pre-floor schema versions is a one-way operation

Removing the oldest versioned schemas and their stages SHALL raise the floor to the lowest retained version. After removal, a store persisted at a version below the new floor SHALL have no migration path, and ModelContainer initialization SHALL fail for such a store. Schema-version removal SHALL only be performed when no installed store can be at or below the removed versions.

#### Scenario: Store below the floor has no migration path

- **WHEN** an on-disk store at a version below the floor is opened with the collapsed plan
- **THEN** ModelContainer initialization throws because no migration path exists

#### Scenario: Persistence fallback wipes an unmigratable store

- **WHEN** ModelContainer initialization throws because the store predates the floor
- **THEN** the app-level container factory resets the store files and rebuilds an empty store, which is the documented and accepted recovery behavior during pre-release

### Requirement: Schema-version removal preserves the target fingerprint

Removing legacy versioned schemas SHALL NOT alter the attribute fingerprint of the retained target schema or the floor schema. The top-level model types and any frozen shadow types still referenced by the retained versions MUST remain byte-identical after removal, so that stores already at the target continue to open without triggering migration.

#### Scenario: Target store unaffected by removal

- **WHEN** legacy versions are removed without altering the target or floor schema definitions
- **THEN** a store already at the target opens with zero migration, identically to before the removal

### Requirement: On-disk migration regression coverage

The test suite SHALL include an on-disk regression test, distinct from in-memory tests, that persists a store at the floor version, reopens it with the current migration plan, and asserts all records survive with correct field values. This test SHALL also act as a guard that the target schema fingerprint is unchanged.

#### Scenario: Regression test detects a broken chain or perturbed fingerprint

- **WHEN** the migration chain is broken or the target schema fingerprint changes
- **THEN** the on-disk migration test fails, because records are missing or opening triggers an unexpected migration or throw

### Requirement: CloudKit sync invalidates per-device removal safety

The plan SHALL record that the per-device safety of removing pre-floor versions holds only while CloudKit sync is disabled. When sync is enabled, a destructive fallback on one device can propagate across the account, so schema-version removal MUST be re-evaluated before sync is turned on.

#### Scenario: Enabling sync requires re-evaluation

- **WHEN** CloudKit sync is enabled in the persistence configuration
- **THEN** schema-version removal decisions are re-evaluated before release, because the per-device "already at target is safe" reasoning no longer applies account-wide
