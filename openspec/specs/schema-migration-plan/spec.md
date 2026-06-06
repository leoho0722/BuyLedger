# schema-migration-plan Specification

## Purpose

TBD - created by archiving change 'prune-legacy-schema-versions'. Update Purpose after archive.

## Requirements

### Requirement: Contiguous migration chain from floor to target

The migration plan SHALL declare its versioned schemas as a contiguous, totally-ordered chain from the lowest supported store version (the floor) up to and including the current target schema, and SHALL provide exactly one migration stage bridging each adjacent version pair. The ModelContainer SHALL be constructed against the target schema together with this migration plan.

#### Scenario: Store at the floor version migrates to the target

- **WHEN** an on-disk store persisted at the floor schema version is opened with the migration plan
- **THEN** the bridging stage runs and the store is migrated to the target version

#### Scenario: Store already at the target opens without migration

- **WHEN** an on-disk store already at the target schema version is opened
- **THEN** no migration stage runs and the store opens unchanged


<!-- @trace
source: prune-legacy-schema-versions
updated: 2026-05-30
code:
  - BuyLedger/BuyLedger/Core/Persistence/BuyLedgerSchema.swift
  - BuyLedger/BuyLedgerTests/SchemaMigrationTests.swift
  - CLAUDE.md
-->

---
### Requirement: Data preservation across retained migrations

Opening a store at any retained version SHALL preserve every persisted record and its field values through migration to the target. No retained migration stage SHALL drop or corrupt existing rows.

#### Scenario: Orders survive floor-to-target migration

- **WHEN** a store written at the floor version contains order records and their related master data
- **THEN** after opening with the plan, all order records and their fields remain intact at the target version

##### Example: three orders survive V7 to V8 migration

- **GIVEN** an on-disk store at the floor version (V7) containing 3 order records with currency, orderSource, notes, and verificationStatus set
- **WHEN** the store is reopened with the collapsed migration plan targeting V8
- **THEN** all 3 order records are present and each preserves its currency, orderSource, notes, and verificationStatus values


<!-- @trace
source: prune-legacy-schema-versions
updated: 2026-05-30
code:
  - BuyLedger/BuyLedger/Core/Persistence/BuyLedgerSchema.swift
  - BuyLedger/BuyLedgerTests/SchemaMigrationTests.swift
  - CLAUDE.md
-->

---
### Requirement: Removing pre-floor schema versions is a one-way operation

Removing the oldest versioned schemas and their stages SHALL raise the floor to the lowest retained version. After removal, a store persisted at a version below the new floor SHALL have no migration path, and ModelContainer initialization SHALL fail for such a store. Schema-version removal SHALL only be performed when no installed store can be at or below the removed versions.

#### Scenario: Store below the floor has no migration path

- **WHEN** an on-disk store at a version below the floor is opened with the collapsed plan
- **THEN** ModelContainer initialization throws because no migration path exists

#### Scenario: Persistence fallback wipes an unmigratable store

- **WHEN** ModelContainer initialization throws because the store predates the floor
- **THEN** the app-level container factory resets the store files and rebuilds an empty store, which is the documented and accepted recovery behavior during pre-release


<!-- @trace
source: prune-legacy-schema-versions
updated: 2026-05-30
code:
  - BuyLedger/BuyLedger/Core/Persistence/BuyLedgerSchema.swift
  - BuyLedger/BuyLedgerTests/SchemaMigrationTests.swift
  - CLAUDE.md
-->

---
### Requirement: Schema-version removal preserves the target fingerprint

Removing legacy versioned schemas SHALL NOT alter the attribute fingerprint of the retained target schema or the floor schema. The top-level model types and any frozen shadow types still referenced by the retained versions MUST remain byte-identical after removal, so that stores already at the target continue to open without triggering migration.

#### Scenario: Target store unaffected by removal

- **WHEN** legacy versions are removed without altering the target or floor schema definitions
- **THEN** a store already at the target opens with zero migration, identically to before the removal


<!-- @trace
source: prune-legacy-schema-versions
updated: 2026-05-30
code:
  - BuyLedger/BuyLedger/Core/Persistence/BuyLedgerSchema.swift
  - BuyLedger/BuyLedgerTests/SchemaMigrationTests.swift
  - CLAUDE.md
-->

---
### Requirement: On-disk migration regression coverage

The test suite SHALL include an on-disk regression test, distinct from in-memory tests, that persists a store at the floor version, reopens it with the current migration plan, and asserts all records survive with correct field values. This test SHALL also act as a guard that the target schema fingerprint is unchanged.

#### Scenario: Regression test detects a broken chain or perturbed fingerprint

- **WHEN** the migration chain is broken or the target schema fingerprint changes
- **THEN** the on-disk migration test fails, because records are missing or opening triggers an unexpected migration or throw


<!-- @trace
source: prune-legacy-schema-versions
updated: 2026-05-30
code:
  - BuyLedger/BuyLedger/Core/Persistence/BuyLedgerSchema.swift
  - BuyLedger/BuyLedgerTests/SchemaMigrationTests.swift
  - CLAUDE.md
-->

---
### Requirement: CloudKit sync invalidates per-device removal safety

The plan SHALL record that the per-device safety of removing pre-floor versions holds only while CloudKit sync is disabled. When sync is enabled, a destructive fallback on one device can propagate across the account, so schema-version removal MUST be re-evaluated before sync is turned on.

#### Scenario: Enabling sync requires re-evaluation

- **WHEN** CloudKit sync is enabled in the persistence configuration
- **THEN** schema-version removal decisions are re-evaluated before release, because the per-device "already at target is safe" reasoning no longer applies account-wide

<!-- @trace
source: prune-legacy-schema-versions
updated: 2026-05-30
code:
  - BuyLedger/BuyLedger/Core/Persistence/BuyLedgerSchema.swift
  - BuyLedger/BuyLedgerTests/SchemaMigrationTests.swift
  - CLAUDE.md
-->

---
### Requirement: Type-changing migrations preserve values through a custom stage

When a schema version changes the type of an existing attribute, the bridging stage SHALL be a custom (dump-and-restore) stage that maps every persisted value into the new shape without data loss. The V10 → V11 stage SHALL convert each order's single category string into a category list (a non-empty string becomes a one-element list; an empty string becomes an empty list), convert each order's campaign name into a campaign list (a non-empty name becomes a one-element list; the empty unassigned string becomes an empty list), and initialize the new merged-source list to empty for every migrated order. The V10 schema SHALL be frozen as an embedded shadow definition so its attribute fingerprint stays intact.

#### Scenario: Single-select values migrate into lists

- **WHEN** a V10 store is opened with the plan targeting V11
- **THEN** every order's category and campaign values are mapped into lists per the conversion rules and no record is lost

##### Example: V10 to V11 value mapping

| V10 category | V10 campaignName | V11 categories | V11 campaignNames | V11 mergedSourceIDs |
| ------------ | ---------------- | -------------- | ----------------- | ------------------- |
| "beauty"     | "May-JP"         | ["beauty"]     | ["May-JP"]        | []                  |
| "beauty"     | ""               | ["beauty"]     | []                | []                  |
| ""           | ""               | []             | []                | []                  |

#### Scenario: On-disk regression covers the custom stage

- **WHEN** the on-disk migration regression suite runs
- **THEN** it includes a store persisted at V10 that is reopened with the plan, asserting the list conversions above and the survival of every other field

<!-- @trace
source: add-order-merge
updated: 2026-06-07
code:
  - BuyLedger/BuyLedger/Features/Orders/Components/OptionPickerSheet.swift
  - BuyLedger/BuyLedger/Features/Orders/OrdersFeature.swift
  - BuyLedger/BuyLedgerTests/__Snapshots__/SnapshotTests/dashboardViewBaseline.2.png
  - BuyLedger/BuyLedgerTests/OrderEditFeatureTests.swift
  - BuyLedger/BuyLedgerTests/OrdersFeaturePerformanceTests.swift
  - BuyLedger/BuyLedger/Features/Orders/OrdersView.swift
  - BuyLedger/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewBaseline.2.png
  - BuyLedger/BuyLedger/Features/Campaigns/CampaignFeature.swift
  - BuyLedger/BuyLedgerTests/__Snapshots__/SnapshotTests/insightsViewBaseline.1.png
  - BuyLedger/BuyLedgerTests/SnapshotTests.swift
  - BuyLedger/BuyLedgerTests/InsightsAttributionTests.swift
  - BuyLedger/BuyLedgerTests/CampaignSummaryTests.swift
  - BuyLedger/BuyLedger/Features/Insights/InsightsView.swift
  - BuyLedger/BuyLedger/Features/Orders/Components/OrderMergeCandidateSheet.swift
  - BuyLedger/BuyLedgerTests/OrdersFeatureTests.swift
  - BuyLedger/BuyLedgerTests/SchemaMigrationTests.swift
  - BuyLedger/BuyLedger/Core/Persistence/OrderPersistence.swift
  - BuyLedger/BuyLedger/Features/Orders/OrderEditFeature.swift
  - BuyLedger/BuyLedger/Core/Persistence/BuyLedgerSchema.swift
  - BuyLedger/BuyLedger/Core/Persistence/OrderRecord.swift
  - BuyLedger/BuyLedger/Features/Orders/OrderMergeFeature.swift
  - BuyLedger/BuyLedgerTests/OrderStatusTests.swift
  - BuyLedger/BuyLedger/Core/Domain/LedgerOrder.swift
  - BuyLedger/BuyLedger/Features/Orders/OrderEditView.swift
  - BuyLedger/BuyLedgerTests/OrderMergeTests.swift
  - BuyLedger/BuyLedger/Core/Domain/Campaign+Samples.swift
  - BuyLedger/BuyLedgerTests/RootFeatureTests.swift
  - BuyLedger/BuyLedger/Features/Orders/Components/MergePhotoPickerSheet.swift
  - BuyLedger/BuyLedgerTests/__Snapshots__/SnapshotTests/dashboardViewBaseline.1.png
  - BuyLedger/BuyLedger/Core/Domain/LedgerOrder+Samples.swift
  - BuyLedger/BuyLedgerTests/__Snapshots__/SnapshotTests/blBarChartThirtyDaysBaseline.2.png
  - BuyLedger/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewBaseline.2.png
  - BuyLedger/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewLongContentBaseline.2.png
  - BuyLedger/BuyLedger/Features/Campaigns/CampaignSummary.swift
  - BuyLedger/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewMergeContextBaseline.2.png
  - BuyLedger/BuyLedger/Features/Orders/Components/OrderRowView.swift
  - BuyLedger/BuyLedger/Features/Orders/Components/OrderStatus+Presentation.swift
  - BuyLedger/BuyLedger/Features/Dashboard/DashboardView.swift
  - BuyLedger/BuyLedgerTests/CampaignIntegrationTests.swift
  - BuyLedger/BuyLedger/Features/Orders/OrdersCompactView.swift
  - BuyLedger/BuyLedger/Core/Domain/Campaign.swift
  - BuyLedger/BuyLedgerTests/__Snapshots__/SnapshotTests/orderDetailCostBreakdownBaseline.2.png
  - BuyLedger/BuyLedgerTests/OrderPersistenceTests.swift
  - BuyLedger/BuyLedger/Core/Domain/OrderMerge.swift
  - BuyLedger/BuyLedgerTests/__Snapshots__/SnapshotTests/insightsViewBaseline.2.png
  - BuyLedger/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewBaseline.1.png
  - BuyLedger/BuyLedgerTests/OrderMergeFeatureTests.swift
  - BuyLedger/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewMergeContextBaseline.1.png
  - BuyLedger/BuyLedger/Core/Dependencies/OrderRepository.swift
  - BuyLedger/BuyLedger/Features/Orders/OrdersMacView.swift
  - BuyLedger/BuyLedgerTests/__Snapshots__/SnapshotTests/orderDetailCostBreakdownBaseline.1.png
  - BuyLedger/BuyLedgerTests/OrderCalculationTests.swift
  - BuyLedger/BuyLedger/Core/Persistence/PersistenceContainer.swift
  - BuyLedger/BuyLedger/Core/Domain/OrderStatus.swift
  - BuyLedger/BuyLedger/Features/Orders/Components/OrderDetailView.swift
  - BuyLedger/BuyLedger/Features/App/RootFeature.swift
  - BuyLedger/BuyLedger/Features/Orders/OrderStatusFilter.swift
-->