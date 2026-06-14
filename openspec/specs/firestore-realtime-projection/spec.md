# firestore-realtime-projection Specification

## Purpose

TBD - created by archiving change 'firebase-auth-multiuser-sync'. Update Purpose after archive.

## Requirements

### Requirement: Backend is the sole writer of Firestore

Only the backend SHALL write Firestore documents that mirror domain data. Clients SHALL NOT write these Firestore documents directly.

#### Scenario: Client writes go through the backend

- **WHEN** a client needs to create, update, or delete domain data
- **THEN** the client SHALL call the backend API, and the backend SHALL be the only writer of the corresponding Firestore documents


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
### Requirement: Authoritative writes are mirrored to per-user Firestore collections

After the backend commits a create or update to PostgreSQL, it SHALL upsert a matching Firestore document under the owning user's collection, reflecting the same data including the backend-computed summary. On delete, it SHALL remove the corresponding document.

#### Scenario: Create is mirrored

- **WHEN** the backend commits a new order for user with uid U
- **THEN** the backend SHALL upsert a Firestore document for that order under user U's orders collection, containing the same fields and the backend-computed summary

#### Scenario: Delete is mirrored

- **WHEN** the backend deletes an order owned by user U
- **THEN** the backend SHALL delete the corresponding Firestore document

##### Example: per-user document path

- **GIVEN** an order with id ORD1 owned by uid U1
- **WHEN** the backend mirrors it
- **THEN** the document path SHALL be `users/U1/orders/ORD1`


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
### Requirement: Firestore is non-authoritative

PostgreSQL SHALL remain the source of truth. A Firestore mirroring failure SHALL NOT roll back an already-committed PostgreSQL write or fail the API response; the failure SHALL be recorded so it can be retried.

#### Scenario: Mirror failure does not fail the write

- **WHEN** a PostgreSQL write commits successfully but the subsequent Firestore mirror fails
- **THEN** the API response SHALL reflect the successful PostgreSQL write, and the mirror failure SHALL be recorded for retry


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
### Requirement: Mirror covers all mirrored collections

The backend SHALL mirror all domain collections — orders, campaigns, lookups, and per-user settings — to Firestore.

#### Scenario: Each collection is mirrored

- **WHEN** a record in orders, campaigns, lookups, or settings is created or updated
- **THEN** the backend SHALL mirror that record to the corresponding Firestore collection


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
### Requirement: Mirrored documents stay within the Firestore document size limit

Mirrored documents SHALL stay within Firestore's per-document size limit. The backend SHALL NOT embed raw base64 order-photo payloads inside Firestore documents. Instead, the backend SHALL upload each order photo to Firebase Storage and store only a reference (path or download URL) in the Firestore document.

#### Scenario: Order photo is uploaded to Storage and referenced

- **WHEN** the backend mirrors an order that has an embedded base64 photo
- **THEN** the backend SHALL upload the photo to Firebase Storage, and the Firestore document SHALL contain only a Storage reference (path or URL), SHALL NOT contain the raw base64 payload, and SHALL stay within the per-document size limit


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
### Requirement: iOS Firestore sync is gated behind a default-off feature flag

On iOS, Firestore reads and writes SHALL be controlled by a feature flag that is disabled by default. With the flag disabled, iOS SHALL rely on local SwiftData and SHALL NOT access Firestore.

#### Scenario: iOS with flag disabled does not access Firestore

- **WHEN** iOS runs with the sync feature flag disabled
- **THEN** iOS SHALL NOT read from or write to Firestore and SHALL rely on local SwiftData

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