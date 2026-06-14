## ADDED Requirements

### Requirement: Backend verifies Firebase ID tokens on protected endpoints

The backend SHALL require a valid Firebase ID token on every protected API endpoint. The token SHALL be supplied in the HTTP `Authorization` header using the `Bearer` scheme. Requests without a valid token SHALL be rejected.

#### Scenario: Request without a token is rejected

- **WHEN** a request to a protected endpoint arrives with no `Authorization: Bearer` token
- **THEN** the backend SHALL respond with HTTP 401 and SHALL NOT process the request

#### Scenario: Request with an invalid or expired token is rejected

- **WHEN** a request carries a Firebase ID token that fails verification
- **THEN** the backend SHALL respond with HTTP 401 without disclosing internal verification details

#### Scenario: Request with a valid token is processed as that user

- **WHEN** a request carries a Firebase ID token that verifies successfully
- **THEN** the backend SHALL resolve the token's uid and process the request as that user

### Requirement: Authenticated request context exposes the caller uid

When token verification succeeds, the resolved uid SHALL be available to service-layer logic for the duration of that request, so that ownership and scoping can be enforced.

#### Scenario: Resolved uid is available to services

- **WHEN** token verification succeeds for a request
- **THEN** the service layer handling that request SHALL be able to read the caller's uid

### Requirement: Supported sign-in providers are Google and Apple only

The system SHALL offer Google and Apple as the sign-in providers on web and iOS, and SHALL NOT offer email/password or other providers.

#### Scenario: Sign-in surface lists only Google and Apple

- **WHEN** a user reaches the sign-in surface on web or on iOS with the feature enabled
- **THEN** the only available sign-in options SHALL be Google and Apple

### Requirement: Missing Firebase credentials fail closed

If the backend is configured without Firebase service account credentials, it SHALL NOT serve protected endpoints as if requests were authenticated. It SHALL fail closed.

#### Scenario: Backend without credentials refuses unauthenticated access

- **WHEN** the backend runs without Firebase service account credentials
- **THEN** it SHALL fail to start or reject protected requests, and SHALL NOT silently allow unauthenticated access

### Requirement: iOS sign-in is gated behind a default-off feature flag

On iOS the sign-in capability SHALL be controlled by a feature flag that is disabled by default. With the flag disabled, iOS SHALL operate on local SwiftData without presenting sign-in.

#### Scenario: iOS with flag disabled shows no sign-in

- **WHEN** iOS launches with the sign-in/sync feature flag disabled
- **THEN** no sign-in SHALL be presented and the app SHALL operate on local SwiftData

#### Scenario: iOS with flag enabled offers sign-in

- **WHEN** the iOS feature flag is enabled
- **THEN** Google and Apple sign-in SHALL become available
