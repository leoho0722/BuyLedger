## REMOVED Requirements

### Requirement: Domain entities are owned by a single user

**Reason**: Ownership was a backend persistence concept for multi-user isolation; the app becomes single-user and local-only.
**Migration**: None. iOS domain models never carried ownerUid; local data has no ownership dimension.

### Requirement: Reads are scoped to the caller's uid

**Reason**: Removed with the backend request pipeline.
**Migration**: None. A local single-user app reads all of its own data unconditionally.

### Requirement: Writes target only records owned by the caller

**Reason**: Removed with the backend request pipeline.
**Migration**: None. Local writes are unscoped.

### Requirement: Settings are per-user

**Reason**: Per-user settings were a backend concept; settings become device-local.
**Migration**: None. Settings persist locally as before the multi-user work.

### Requirement: Seeded development data carries explicit ownership

**Reason**: Backend seeding is removed with the backend.
**Migration**: None. iOS seeds no ownership metadata.
