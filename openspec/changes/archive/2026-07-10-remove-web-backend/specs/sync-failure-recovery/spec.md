## REMOVED Requirements

### Requirement: Bounded client retry then observable pending or failed state

**Reason**: The client send queue targeted the backend; removed with sync.
**Migration**: None. Local writes commit synchronously to SwiftData with no send queue.

### Requirement: Resends are idempotent and side effects are clock-guarded

**Reason**: Idempotent resend applied to backend PATCH delivery; removed with sync.
**Migration**: None. There are no resends in a local-only app.

### Requirement: A lost ack does not pin a field dirty forever

**Reason**: The dirty-field bookkeeping existed for push acknowledgement reconciliation; removed with sync.
**Migration**: None. No dirty-field tracking exists after the SyncMeta sidecar is removed.
