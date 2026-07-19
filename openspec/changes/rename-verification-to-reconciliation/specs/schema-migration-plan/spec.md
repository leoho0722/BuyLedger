## MODIFIED Requirements

### Requirement: Data preservation across retained migrations

Opening a store at any retained version SHALL preserve every persisted record and its field values through migration to the target. No retained migration stage SHALL drop or corrupt existing rows. When a persisted field or master-data entity is renamed, the bridging migration SHALL preserve existing values under the new name rather than dropping them.

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
