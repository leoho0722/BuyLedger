# multi-user-data-ownership Specification

## Purpose

TBD - created by archiving change 'firebase-auth-multiuser-sync'. Update Purpose after archive.

## Requirements

### Requirement: Domain entities are owned by a single user

Every order, campaign, and lookup record SHALL carry an owner identifier that corresponds to a Firebase uid. On creation, the owner SHALL be set to the authenticated caller's uid.

#### Scenario: Creating a record assigns ownership to the caller

- **WHEN** an authenticated user creates an order
- **THEN** the stored record SHALL have the caller's uid as its owner


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
### Requirement: Reads are scoped to the caller's uid

Read operations SHALL return only records owned by the authenticated caller and SHALL NOT expose records owned by any other user.

#### Scenario: Cross-user isolation on read

- **WHEN** user A requests their orders
- **THEN** the response SHALL contain only records owned by A and SHALL NOT contain any record owned by another user

##### Example: two users with separate orders

- **GIVEN** order O1 owned by user A and order O2 owned by user B
- **WHEN** user A lists orders
- **THEN** the result contains O1 and does not contain O2


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
### Requirement: Writes target only records owned by the caller

Update and delete operations SHALL only affect records owned by the authenticated caller. An attempt to modify a record owned by another user SHALL NOT mutate that record.

#### Scenario: Writing another user's record is rejected

- **WHEN** user A attempts to update or delete a record owned by user B
- **THEN** the backend SHALL NOT modify the record and SHALL respond as not found within A's scope


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
### Requirement: Settings are per-user

Settings SHALL be stored and retrieved per user, keyed by uid, replacing the previous global singleton. Each user SHALL have an independent settings record.

#### Scenario: Each user reads their own settings

- **WHEN** user A and user B each read settings
- **THEN** each SHALL receive their own settings record, and a change by A SHALL NOT affect B's settings


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
### Requirement: Seeded development data carries explicit ownership

The system SHALL NOT assume pre-existing unowned data. When the development database is seeded, every seeded domain record SHALL be assigned an explicit owner uid.

#### Scenario: Seed assigns owners

- **WHEN** the development database is seeded
- **THEN** every seeded order, campaign, and lookup record SHALL have an owner uid

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