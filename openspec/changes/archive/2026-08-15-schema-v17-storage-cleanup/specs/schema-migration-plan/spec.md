## ADDED Requirements

### Requirement: Entities dropped from the target schema stay frozen in retained versions

When an entity is removed from the target schema, every retained schema version that previously declared it SHALL continue to declare it as a frozen shadow type whose shape matches what that version originally persisted, and that version's model list SHALL reference the shadow rather than a top-level type. Removal SHALL be limited to entities that hold no rows in any installed store. The removed entity's top-level declaration MAY be deleted from the codebase once the shadows exist.

#### Scenario: Retained versions still declare the dropped entity

- **WHEN** the model lists of the retained schema versions are inspected after an entity is dropped from the target
- **THEN** every retained version that previously declared the entity still declares it, and the target version does not

#### Scenario: A store at a retained version migrates past the dropped entity

- **WHEN** an on-disk store persisted at a retained version that contains the dropped entity's table is opened with the plan targeting the version that omits it
- **THEN** migration succeeds and every record of every other entity is preserved with its field values intact

#### Scenario: Deleting a shadow breaks the chain visibly

- **WHEN** a frozen shadow for a dropped entity is removed from a retained version
- **THEN** the on-disk migration regression tests fail, rather than the breakage surfacing only on a user's device

## MODIFIED Requirements

### Requirement: Data preservation across retained migrations

Opening a store at any retained version SHALL preserve every persisted record and its field values through migration to the target. No retained migration stage SHALL drop or corrupt existing rows. When a persisted field or master-data entity is renamed, the bridging migration SHALL preserve existing values under the new name rather than dropping them. When an attribute's storage location changes — for example when binary payloads move out of the record row into adjacent external storage — the bridging migration SHALL preserve the stored values byte for byte, and SHALL NOT require existing rows to be rewritten in order to remain readable.

The stage kind bridging a version pair SHALL be chosen on the evidence of an on-disk migration test rather than assumed from the shape of the change.

#### Scenario: Orders survive floor-to-target migration

- **WHEN** a store written at the floor version contains order records and their related master data
- **THEN** after opening with the plan, all order records and their fields remain intact at the target version

##### Example: three orders survive V7 to V8 migration

- **GIVEN** an on-disk store at the floor version (V7) containing 3 order records with currency, orderSource, notes, and reconciliation status set
- **WHEN** the store is reopened with the collapsed migration plan targeting V8
- **THEN** all 3 order records are present and each preserves its currency, orderSource, notes, and reconciliation status values

#### Scenario: Reconciliation-status rename migration preserves values

- **WHEN** a store persisted before the reconciliation-status rename (the order field and master table previously named with the "verification" identifier) is opened with the migration plan
- **THEN** every order's reconciliation-status value and every reconciliation-status master entry is preserved under the renamed field and table, with no rows dropped

#### Scenario: Relocating binary payloads preserves them byte for byte

- **WHEN** a store persisted before an attribute's binary payloads moved to external storage is opened with the plan targeting the version that relocates them
- **THEN** every record retains its payloads with identical bytes, and records written before the change remain readable without being rewritten

#### Scenario: Stage kind is settled by test evidence

- **WHEN** a new version pair is bridged and it is unclear whether a lightweight stage suffices
- **THEN** an on-disk migration test decides it, and a custom stage is adopted only after a lightweight stage is observed to fail
