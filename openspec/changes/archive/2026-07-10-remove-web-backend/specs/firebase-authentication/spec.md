## REMOVED Requirements

### Requirement: Backend verifies Firebase ID tokens on protected endpoints

**Reason**: The backend is removed; there are no protected endpoints to guard.
**Migration**: None. No server-side authentication exists in a local-only iOS app.

### Requirement: Authenticated request context exposes the caller uid

**Reason**: Removed with the backend request pipeline.
**Migration**: None. There is no per-request caller identity in a single-user local app.

### Requirement: Supported sign-in providers are Google and Apple only

**Reason**: Firebase Auth and GoogleSignIn are removed; the app no longer signs users in.
**Migration**: None. The sign-in surface is removed entirely.

### Requirement: Missing Firebase credentials fail closed

**Reason**: The backend that held the fail-closed admin credential requirement is removed.
**Migration**: None. No admin credential is loaded by any component.

### Requirement: iOS sign-in is gated behind a default-off feature flag

**Reason**: The sign-in surface and its feature flag are removed; there is nothing to gate.
**Migration**: None. The default-off flag guaranteed zero user impact; removal keeps behavior identical.
