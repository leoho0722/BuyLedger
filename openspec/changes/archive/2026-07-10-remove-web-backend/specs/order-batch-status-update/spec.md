## REMOVED Requirements

### Requirement: Backend batch status endpoint is owner-scoped and re-mirrors Firestore

**Reason**: The NestJS backend is removed; there is no batch status endpoint to expose and no Firestore projection to re-mirror.
**Migration**: None. Batch status updates persist locally on Apple via SwiftData; the four Apple-local requirements of this capability are unchanged.

### Requirement: Web batch status update invalidates orders and campaigns

**Reason**: The Web frontend is removed; there is no web query cache to invalidate.
**Migration**: None. The feature exists only on Apple platforms, where batch status persistence remains atomic.
