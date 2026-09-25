## MODIFIED Requirements

### Requirement: Removing pre-floor schema versions is a one-way operation

Removing the oldest versioned schemas and their stages SHALL raise the floor to the lowest retained version. After removal, a store persisted at a version below the new floor SHALL have no migration path, and ModelContainer initialization SHALL fail for such a store. Schema-version removal SHALL only be performed when no installed store can be at or below the removed versions. A store that cannot be migrated SHALL be preserved in place rather than reset, so that a later release which restores the missing migration path can still open it.

#### Scenario: Store below the floor has no migration path

- **WHEN** an on-disk store at a version below the floor is opened with the collapsed plan
- **THEN** ModelContainer initialization throws because no migration path exists

#### Scenario: Persistence fallback preserves an unmigratable store

- **WHEN** ModelContainer initialization throws because the store predates the floor
- **THEN** the app-level persistence bootstrap leaves every store file untouched, falls back to an in-memory container, and reports a degraded launch outcome that the app surfaces to the user

#### Scenario: A later release can still open the preserved store

- **WHEN** a subsequent release restores a migration path that covers the preserved store version
- **THEN** the preserved store opens and migrates normally, because it was never reset
