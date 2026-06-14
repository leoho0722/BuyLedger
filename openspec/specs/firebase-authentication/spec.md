# firebase-authentication Specification

## Purpose

TBD - created by archiving change 'firebase-auth-multiuser-sync'. Update Purpose after archive.

## Requirements

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


<!-- @trace
source: firebase-auth-multiuser-sync
updated: 2026-06-14
code:
  - apps/web/Dockerfile
  - apps/backend/src/app.module.ts
  - apps/backend/src/settings/settings.controller.ts
  - apps/backend/src/auth/public.decorator.ts
  - apps/web/src/lib/firebase.ts
  - apps/web/src/lib/providers.tsx
  - apps/backend/src/campaigns/campaigns.controller.ts
  - apps/web/package.json
  - apps/backend/src/firebase/firebase.service.ts
  - deploy/docker-compose.yml
  - README.md
  - apps/backend/src/lookups/lookups.controller.ts
  - apps/apple/BuyLedger/Features/App/AppRootView.swift
  - apps/backend/CLAUDE.md
  - apps/web/README.md
  - apps/backend/src/app.controller.ts
  - apps/backend/jest.config.js
  - apps/backend/src/settings/settings.service.ts
  - apps/backend/src/ai-summary/ai-summary.service.ts
  - apps/apple/BuyLedger/Features/App/CloudSync.swift
  - apps/backend/src/orders/orders.service.ts
  - apps/backend/src/campaigns/campaigns.service.ts
  - apps/backend/.env.example
  - apps/apple/BuyLedger/App/CloudSyncFeatureFlag.swift
  - apps/backend/src/ai-summary/ai-summary.controller.ts
  - deploy/backend.env.example
  - apps/backend/src/auth/firebase-auth.guard.ts
  - apps/apple/BuyLedger/Features/Settings/SettingsMacView.swift
  - apps/backend/prisma/seed.ts
  - apps/backend/src/firebase/firebase.config.ts
  - apps/backend/src/firebase/firebase.module.ts
  - apps/backend/.dockerignore
  - apps/apple/CLAUDE.md
  - apps/backend/README.md
  - apps/apple/BuyLedger.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
  - apps/apple/BuyLedger/Features/Settings/SettingsView.swift
  - apps/backend/src/auth/auth.module.ts
  - apps/backend/src/firebase/firestore-mirror.service.ts
  - apps/backend/prisma/schema.prisma
  - deploy/web.env.example
  - apps/backend/src/lookups/lookups.service.ts
  - apps/web/src/lib/auth.tsx
  - apps/apple/BuyLedger.xcodeproj/project.pbxproj
  - apps/backend/src/orders/orders.controller.ts
  - apps/web/src/app/more/settings/page.tsx
  - apps/apple/BuyLedger/Features/App/CloudAuth.swift
  - apps/apple/BuyLedger/Features/App/CloudAccountSettingsSection.swift
  - apps/backend/package.json
  - apps/web/src/lib/api.ts
  - apps/apple/BuyLedger/App/BuyLedgerApp.swift
  - apps/apple/BuyLedger/Features/App/CloudSignInView.swift
  - deploy/common.env.example
  - Makefile
  - apps/backend/src/auth/current-user.decorator.ts
tests:
  - apps/backend/src/orders/orders.service.spec.ts
  - apps/backend/src/auth/global-auth-guard.spec.ts
  - apps/backend/src/auth/firebase-auth.guard.spec.ts
  - apps/backend/src/firebase/firebase.service.spec.ts
  - apps/backend/src/lookups/lookups.service.spec.ts
  - apps/backend/src/settings/settings.service.spec.ts
  - apps/backend/src/auth/current-user.decorator.spec.ts
  - apps/backend/src/firebase/firestore-mirror.service.spec.ts
  - apps/backend/src/firebase/firebase.config.spec.ts
-->

---
### Requirement: Authenticated request context exposes the caller uid

When token verification succeeds, the resolved uid SHALL be available to service-layer logic for the duration of that request, so that ownership and scoping can be enforced.

#### Scenario: Resolved uid is available to services

- **WHEN** token verification succeeds for a request
- **THEN** the service layer handling that request SHALL be able to read the caller's uid


<!-- @trace
source: firebase-auth-multiuser-sync
updated: 2026-06-14
code:
  - apps/web/Dockerfile
  - apps/backend/src/app.module.ts
  - apps/backend/src/settings/settings.controller.ts
  - apps/backend/src/auth/public.decorator.ts
  - apps/web/src/lib/firebase.ts
  - apps/web/src/lib/providers.tsx
  - apps/backend/src/campaigns/campaigns.controller.ts
  - apps/web/package.json
  - apps/backend/src/firebase/firebase.service.ts
  - deploy/docker-compose.yml
  - README.md
  - apps/backend/src/lookups/lookups.controller.ts
  - apps/apple/BuyLedger/Features/App/AppRootView.swift
  - apps/backend/CLAUDE.md
  - apps/web/README.md
  - apps/backend/src/app.controller.ts
  - apps/backend/jest.config.js
  - apps/backend/src/settings/settings.service.ts
  - apps/backend/src/ai-summary/ai-summary.service.ts
  - apps/apple/BuyLedger/Features/App/CloudSync.swift
  - apps/backend/src/orders/orders.service.ts
  - apps/backend/src/campaigns/campaigns.service.ts
  - apps/backend/.env.example
  - apps/apple/BuyLedger/App/CloudSyncFeatureFlag.swift
  - apps/backend/src/ai-summary/ai-summary.controller.ts
  - deploy/backend.env.example
  - apps/backend/src/auth/firebase-auth.guard.ts
  - apps/apple/BuyLedger/Features/Settings/SettingsMacView.swift
  - apps/backend/prisma/seed.ts
  - apps/backend/src/firebase/firebase.config.ts
  - apps/backend/src/firebase/firebase.module.ts
  - apps/backend/.dockerignore
  - apps/apple/CLAUDE.md
  - apps/backend/README.md
  - apps/apple/BuyLedger.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
  - apps/apple/BuyLedger/Features/Settings/SettingsView.swift
  - apps/backend/src/auth/auth.module.ts
  - apps/backend/src/firebase/firestore-mirror.service.ts
  - apps/backend/prisma/schema.prisma
  - deploy/web.env.example
  - apps/backend/src/lookups/lookups.service.ts
  - apps/web/src/lib/auth.tsx
  - apps/apple/BuyLedger.xcodeproj/project.pbxproj
  - apps/backend/src/orders/orders.controller.ts
  - apps/web/src/app/more/settings/page.tsx
  - apps/apple/BuyLedger/Features/App/CloudAuth.swift
  - apps/apple/BuyLedger/Features/App/CloudAccountSettingsSection.swift
  - apps/backend/package.json
  - apps/web/src/lib/api.ts
  - apps/apple/BuyLedger/App/BuyLedgerApp.swift
  - apps/apple/BuyLedger/Features/App/CloudSignInView.swift
  - deploy/common.env.example
  - Makefile
  - apps/backend/src/auth/current-user.decorator.ts
tests:
  - apps/backend/src/orders/orders.service.spec.ts
  - apps/backend/src/auth/global-auth-guard.spec.ts
  - apps/backend/src/auth/firebase-auth.guard.spec.ts
  - apps/backend/src/firebase/firebase.service.spec.ts
  - apps/backend/src/lookups/lookups.service.spec.ts
  - apps/backend/src/settings/settings.service.spec.ts
  - apps/backend/src/auth/current-user.decorator.spec.ts
  - apps/backend/src/firebase/firestore-mirror.service.spec.ts
  - apps/backend/src/firebase/firebase.config.spec.ts
-->

---
### Requirement: Supported sign-in providers are Google and Apple only

The system SHALL offer Google and Apple as the sign-in providers on web and iOS, and SHALL NOT offer email/password or other providers.

#### Scenario: Sign-in surface lists only Google and Apple

- **WHEN** a user reaches the sign-in surface on web or on iOS with the feature enabled
- **THEN** the only available sign-in options SHALL be Google and Apple


<!-- @trace
source: firebase-auth-multiuser-sync
updated: 2026-06-14
code:
  - apps/web/Dockerfile
  - apps/backend/src/app.module.ts
  - apps/backend/src/settings/settings.controller.ts
  - apps/backend/src/auth/public.decorator.ts
  - apps/web/src/lib/firebase.ts
  - apps/web/src/lib/providers.tsx
  - apps/backend/src/campaigns/campaigns.controller.ts
  - apps/web/package.json
  - apps/backend/src/firebase/firebase.service.ts
  - deploy/docker-compose.yml
  - README.md
  - apps/backend/src/lookups/lookups.controller.ts
  - apps/apple/BuyLedger/Features/App/AppRootView.swift
  - apps/backend/CLAUDE.md
  - apps/web/README.md
  - apps/backend/src/app.controller.ts
  - apps/backend/jest.config.js
  - apps/backend/src/settings/settings.service.ts
  - apps/backend/src/ai-summary/ai-summary.service.ts
  - apps/apple/BuyLedger/Features/App/CloudSync.swift
  - apps/backend/src/orders/orders.service.ts
  - apps/backend/src/campaigns/campaigns.service.ts
  - apps/backend/.env.example
  - apps/apple/BuyLedger/App/CloudSyncFeatureFlag.swift
  - apps/backend/src/ai-summary/ai-summary.controller.ts
  - deploy/backend.env.example
  - apps/backend/src/auth/firebase-auth.guard.ts
  - apps/apple/BuyLedger/Features/Settings/SettingsMacView.swift
  - apps/backend/prisma/seed.ts
  - apps/backend/src/firebase/firebase.config.ts
  - apps/backend/src/firebase/firebase.module.ts
  - apps/backend/.dockerignore
  - apps/apple/CLAUDE.md
  - apps/backend/README.md
  - apps/apple/BuyLedger.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
  - apps/apple/BuyLedger/Features/Settings/SettingsView.swift
  - apps/backend/src/auth/auth.module.ts
  - apps/backend/src/firebase/firestore-mirror.service.ts
  - apps/backend/prisma/schema.prisma
  - deploy/web.env.example
  - apps/backend/src/lookups/lookups.service.ts
  - apps/web/src/lib/auth.tsx
  - apps/apple/BuyLedger.xcodeproj/project.pbxproj
  - apps/backend/src/orders/orders.controller.ts
  - apps/web/src/app/more/settings/page.tsx
  - apps/apple/BuyLedger/Features/App/CloudAuth.swift
  - apps/apple/BuyLedger/Features/App/CloudAccountSettingsSection.swift
  - apps/backend/package.json
  - apps/web/src/lib/api.ts
  - apps/apple/BuyLedger/App/BuyLedgerApp.swift
  - apps/apple/BuyLedger/Features/App/CloudSignInView.swift
  - deploy/common.env.example
  - Makefile
  - apps/backend/src/auth/current-user.decorator.ts
tests:
  - apps/backend/src/orders/orders.service.spec.ts
  - apps/backend/src/auth/global-auth-guard.spec.ts
  - apps/backend/src/auth/firebase-auth.guard.spec.ts
  - apps/backend/src/firebase/firebase.service.spec.ts
  - apps/backend/src/lookups/lookups.service.spec.ts
  - apps/backend/src/settings/settings.service.spec.ts
  - apps/backend/src/auth/current-user.decorator.spec.ts
  - apps/backend/src/firebase/firestore-mirror.service.spec.ts
  - apps/backend/src/firebase/firebase.config.spec.ts
-->

---
### Requirement: Missing Firebase credentials fail closed

If the backend is configured without Firebase service account credentials, it SHALL NOT serve protected endpoints as if requests were authenticated. It SHALL fail closed.

#### Scenario: Backend without credentials refuses unauthenticated access

- **WHEN** the backend runs without Firebase service account credentials
- **THEN** it SHALL fail to start or reject protected requests, and SHALL NOT silently allow unauthenticated access


<!-- @trace
source: firebase-auth-multiuser-sync
updated: 2026-06-14
code:
  - apps/web/Dockerfile
  - apps/backend/src/app.module.ts
  - apps/backend/src/settings/settings.controller.ts
  - apps/backend/src/auth/public.decorator.ts
  - apps/web/src/lib/firebase.ts
  - apps/web/src/lib/providers.tsx
  - apps/backend/src/campaigns/campaigns.controller.ts
  - apps/web/package.json
  - apps/backend/src/firebase/firebase.service.ts
  - deploy/docker-compose.yml
  - README.md
  - apps/backend/src/lookups/lookups.controller.ts
  - apps/apple/BuyLedger/Features/App/AppRootView.swift
  - apps/backend/CLAUDE.md
  - apps/web/README.md
  - apps/backend/src/app.controller.ts
  - apps/backend/jest.config.js
  - apps/backend/src/settings/settings.service.ts
  - apps/backend/src/ai-summary/ai-summary.service.ts
  - apps/apple/BuyLedger/Features/App/CloudSync.swift
  - apps/backend/src/orders/orders.service.ts
  - apps/backend/src/campaigns/campaigns.service.ts
  - apps/backend/.env.example
  - apps/apple/BuyLedger/App/CloudSyncFeatureFlag.swift
  - apps/backend/src/ai-summary/ai-summary.controller.ts
  - deploy/backend.env.example
  - apps/backend/src/auth/firebase-auth.guard.ts
  - apps/apple/BuyLedger/Features/Settings/SettingsMacView.swift
  - apps/backend/prisma/seed.ts
  - apps/backend/src/firebase/firebase.config.ts
  - apps/backend/src/firebase/firebase.module.ts
  - apps/backend/.dockerignore
  - apps/apple/CLAUDE.md
  - apps/backend/README.md
  - apps/apple/BuyLedger.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
  - apps/apple/BuyLedger/Features/Settings/SettingsView.swift
  - apps/backend/src/auth/auth.module.ts
  - apps/backend/src/firebase/firestore-mirror.service.ts
  - apps/backend/prisma/schema.prisma
  - deploy/web.env.example
  - apps/backend/src/lookups/lookups.service.ts
  - apps/web/src/lib/auth.tsx
  - apps/apple/BuyLedger.xcodeproj/project.pbxproj
  - apps/backend/src/orders/orders.controller.ts
  - apps/web/src/app/more/settings/page.tsx
  - apps/apple/BuyLedger/Features/App/CloudAuth.swift
  - apps/apple/BuyLedger/Features/App/CloudAccountSettingsSection.swift
  - apps/backend/package.json
  - apps/web/src/lib/api.ts
  - apps/apple/BuyLedger/App/BuyLedgerApp.swift
  - apps/apple/BuyLedger/Features/App/CloudSignInView.swift
  - deploy/common.env.example
  - Makefile
  - apps/backend/src/auth/current-user.decorator.ts
tests:
  - apps/backend/src/orders/orders.service.spec.ts
  - apps/backend/src/auth/global-auth-guard.spec.ts
  - apps/backend/src/auth/firebase-auth.guard.spec.ts
  - apps/backend/src/firebase/firebase.service.spec.ts
  - apps/backend/src/lookups/lookups.service.spec.ts
  - apps/backend/src/settings/settings.service.spec.ts
  - apps/backend/src/auth/current-user.decorator.spec.ts
  - apps/backend/src/firebase/firestore-mirror.service.spec.ts
  - apps/backend/src/firebase/firebase.config.spec.ts
-->

---
### Requirement: iOS sign-in is gated behind a default-off feature flag

On iOS the sign-in capability SHALL be controlled by a feature flag that is disabled by default. With the flag disabled, iOS SHALL operate on local SwiftData without presenting sign-in.

#### Scenario: iOS with flag disabled shows no sign-in

- **WHEN** iOS launches with the sign-in/sync feature flag disabled
- **THEN** no sign-in SHALL be presented and the app SHALL operate on local SwiftData

#### Scenario: iOS with flag enabled offers sign-in

- **WHEN** the iOS feature flag is enabled
- **THEN** Google and Apple sign-in SHALL become available

<!-- @trace
source: firebase-auth-multiuser-sync
updated: 2026-06-14
code:
  - apps/web/Dockerfile
  - apps/backend/src/app.module.ts
  - apps/backend/src/settings/settings.controller.ts
  - apps/backend/src/auth/public.decorator.ts
  - apps/web/src/lib/firebase.ts
  - apps/web/src/lib/providers.tsx
  - apps/backend/src/campaigns/campaigns.controller.ts
  - apps/web/package.json
  - apps/backend/src/firebase/firebase.service.ts
  - deploy/docker-compose.yml
  - README.md
  - apps/backend/src/lookups/lookups.controller.ts
  - apps/apple/BuyLedger/Features/App/AppRootView.swift
  - apps/backend/CLAUDE.md
  - apps/web/README.md
  - apps/backend/src/app.controller.ts
  - apps/backend/jest.config.js
  - apps/backend/src/settings/settings.service.ts
  - apps/backend/src/ai-summary/ai-summary.service.ts
  - apps/apple/BuyLedger/Features/App/CloudSync.swift
  - apps/backend/src/orders/orders.service.ts
  - apps/backend/src/campaigns/campaigns.service.ts
  - apps/backend/.env.example
  - apps/apple/BuyLedger/App/CloudSyncFeatureFlag.swift
  - apps/backend/src/ai-summary/ai-summary.controller.ts
  - deploy/backend.env.example
  - apps/backend/src/auth/firebase-auth.guard.ts
  - apps/apple/BuyLedger/Features/Settings/SettingsMacView.swift
  - apps/backend/prisma/seed.ts
  - apps/backend/src/firebase/firebase.config.ts
  - apps/backend/src/firebase/firebase.module.ts
  - apps/backend/.dockerignore
  - apps/apple/CLAUDE.md
  - apps/backend/README.md
  - apps/apple/BuyLedger.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
  - apps/apple/BuyLedger/Features/Settings/SettingsView.swift
  - apps/backend/src/auth/auth.module.ts
  - apps/backend/src/firebase/firestore-mirror.service.ts
  - apps/backend/prisma/schema.prisma
  - deploy/web.env.example
  - apps/backend/src/lookups/lookups.service.ts
  - apps/web/src/lib/auth.tsx
  - apps/apple/BuyLedger.xcodeproj/project.pbxproj
  - apps/backend/src/orders/orders.controller.ts
  - apps/web/src/app/more/settings/page.tsx
  - apps/apple/BuyLedger/Features/App/CloudAuth.swift
  - apps/apple/BuyLedger/Features/App/CloudAccountSettingsSection.swift
  - apps/backend/package.json
  - apps/web/src/lib/api.ts
  - apps/apple/BuyLedger/App/BuyLedgerApp.swift
  - apps/apple/BuyLedger/Features/App/CloudSignInView.swift
  - deploy/common.env.example
  - Makefile
  - apps/backend/src/auth/current-user.decorator.ts
tests:
  - apps/backend/src/orders/orders.service.spec.ts
  - apps/backend/src/auth/global-auth-guard.spec.ts
  - apps/backend/src/auth/firebase-auth.guard.spec.ts
  - apps/backend/src/firebase/firebase.service.spec.ts
  - apps/backend/src/lookups/lookups.service.spec.ts
  - apps/backend/src/settings/settings.service.spec.ts
  - apps/backend/src/auth/current-user.decorator.spec.ts
  - apps/backend/src/firebase/firestore-mirror.service.spec.ts
  - apps/backend/src/firebase/firebase.config.spec.ts
-->