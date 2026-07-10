## REMOVED Requirements

### Requirement: Backend is the sole writer of Firestore

**Reason**: The backend is removed; no component writes Firestore.
**Migration**: None. Firestore is no longer used by the product.

### Requirement: Authoritative writes are mirrored to per-user Firestore collections

**Reason**: The backend mirror service is removed with the backend.
**Migration**: None. Authoritative data lives only in on-device SwiftData.

### Requirement: Firestore is non-authoritative

**Reason**: Firestore is no longer read or written by any platform.
**Migration**: None. SwiftData is the sole source of truth.

### Requirement: Mirror covers all mirrored collections

**Reason**: The mirror service is removed.
**Migration**: None. No collections are mirrored.

### Requirement: Mirrored documents stay within the Firestore document size limit

**Reason**: No documents are written to Firestore after the mirror is removed.
**Migration**: None.

### Requirement: iOS Firestore sync is gated behind a default-off feature flag

**Reason**: The iOS Firestore listener and its feature flag are removed; there is nothing to gate.
**Migration**: None. The flag was default-off, so removal keeps behavior identical.

### Requirement: Projection carries clocks, tombstones, and photo references

**Reason**: The projection document shape is removed with Firestore usage.
**Migration**: None. HLC clocks, tombstones, and Storage photo references are no longer produced or consumed.

### Requirement: A permanently failed mirror still converges

**Reason**: There is no mirror to converge after the backend is removed.
**Migration**: None.
