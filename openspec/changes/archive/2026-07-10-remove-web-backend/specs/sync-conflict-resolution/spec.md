## REMOVED Requirements

### Requirement: Field-level merge with strict-greater clock acceptance

**Reason**: Field-level merge executed on the backend as the linearization point; with the backend removed there are no concurrent writers to merge.
**Migration**: None. Local single-writer edits need no conflict resolution.

### Requirement: HLC operations are identical across platforms and clamped by the backend

**Reason**: HLC existed to order cross-platform sync writes; removed with sync.
**Migration**: None. The iOS HLC primitives and their conformance vectors are removed.

### Requirement: Delete is a clocked tombstone with non-lossy resurrection

**Reason**: Clocked tombstones existed for sync convergence; removed with sync.
**Migration**: None. Local deletes are plain SwiftData deletes.
