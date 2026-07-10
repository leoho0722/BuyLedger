## REMOVED Requirements

### Requirement: Opt-in cross-device propagation between same-account platforms

**Reason**: The Web frontend and NestJS backend are removed; cross-device sync was a client-server capability with the backend as the sole Firestore writer, so it cannot survive as an iOS-only feature.
**Migration**: None. iOS becomes a local-only app whose sole source of truth is on-device SwiftData. Sync was opt-in and default-off, so no user-facing behavior changes.

### Requirement: Clients write through the backend and read the projection

**Reason**: The backend write endpoint and the Firestore projection it maintained are both removed with the backend.
**Migration**: None. iOS no longer performs any remote write or projection read; all domain writes persist locally to SwiftData.
