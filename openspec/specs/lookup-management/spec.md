# lookup-management Specification

## Purpose

TBD - created by archiving change 'lookup-management-macos-card-style'. Update Purpose after archive.

## Requirements

### Requirement: Platform-adaptive lookup management presentation

The lookup management screen (used for order source, category, and payment method) SHALL render a Design System card layout on macOS and SHALL render a system List on iOS and iPadOS. The choice of layout MUST NOT change the available operations or the underlying data.

#### Scenario: macOS renders the card layout

- **WHEN** the order source, category, or payment method management screen is shown on macOS
- **THEN** the screen presents a scrolling view with the Design System background and the items inside a single card with separators between rows, visually consistent with the customer list screen

#### Scenario: iOS and iPadOS keep the system List

- **WHEN** the order source, category, or payment method management screen is shown on iOS or iPadOS
- **THEN** the screen presents the system List with a section header, trailing swipe actions for delete and rename, and the existing footer, unchanged from before this change


<!-- @trace
source: lookup-management-macos-card-style
updated: 2026-05-24
code:
  - .agents/skills/spectra-discuss/SKILL.md
  - .agents/skills/spectra-drift/SKILL.md
  - .agents/skills/spectra-ingest/SKILL.md
  - .agents/skills/spectra-apply/SKILL.md
  - .agents/skills/spectra-propose/SKILL.md
  - BuyLedger/BuyLedger/Features/Lookups/LookupManagementView.swift
-->

---
### Requirement: Lookup item management operations are preserved across platforms

The screen SHALL allow the user to add, rename, and delete lookup items on every platform. The add, rename, and delete operations and their validation SHALL behave identically regardless of the platform layout, and SHALL write through the same management feature as before this change.

#### Scenario: Add a lookup item

- **WHEN** the user activates the toolbar add control and confirms a non-empty, trimmed name
- **THEN** the item is added through the management feature and appears in the list

#### Scenario: Rename a lookup item

- **WHEN** the user triggers rename on an item and confirms a non-empty name different from the original
- **THEN** the item is renamed through the management feature and orders referencing the old name are updated

#### Scenario: Delete a lookup item

- **WHEN** the user triggers delete on an item
- **THEN** the item is removed through the management feature

#### Scenario: macOS rename and delete use the context menu

- **WHEN** the user opens the context menu on an item row on macOS
- **THEN** the menu offers rename and delete, matching the behavior available before this change

#### Scenario: iOS swipe-to-delete is retained

- **WHEN** the user swipes an item row on iOS or iPadOS
- **THEN** the swipe actions for delete and rename are available, unchanged from before this change


<!-- @trace
source: lookup-management-macos-card-style
updated: 2026-05-24
code:
  - .agents/skills/spectra-discuss/SKILL.md
  - .agents/skills/spectra-drift/SKILL.md
  - .agents/skills/spectra-ingest/SKILL.md
  - .agents/skills/spectra-apply/SKILL.md
  - .agents/skills/spectra-propose/SKILL.md
  - BuyLedger/BuyLedger/Features/Lookups/LookupManagementView.swift
-->

---
### Requirement: Payment method cardless indicator

For the payment method kind, the screen SHALL display a "cardless" badge on each item flagged as cardless and SHALL display an explanatory note describing the cardless behavior. The badge and note SHALL be present on all platforms.

#### Scenario: Cardless payment method shows badge and note

- **WHEN** the payment method management screen is shown and at least one method is flagged cardless
- **THEN** each cardless method row displays the "無卡" badge and the screen displays the explanatory note about the cardless discount and top-up fields


<!-- @trace
source: lookup-management-macos-card-style
updated: 2026-05-24
code:
  - .agents/skills/spectra-discuss/SKILL.md
  - .agents/skills/spectra-drift/SKILL.md
  - .agents/skills/spectra-ingest/SKILL.md
  - .agents/skills/spectra-apply/SKILL.md
  - .agents/skills/spectra-propose/SKILL.md
  - BuyLedger/BuyLedger/Features/Lookups/LookupManagementView.swift
-->

---
### Requirement: Lookup item count and empty state

The screen SHALL display the count of created items, and SHALL display an empty state with the kind-specific title and description when no items exist.

#### Scenario: Count is displayed

- **WHEN** the management screen is shown with one or more items
- **THEN** the screen displays the number of created items

#### Scenario: Empty state when no items exist

- **WHEN** the management screen is shown with no items
- **THEN** the screen displays the kind-specific empty title and description

<!-- @trace
source: lookup-management-macos-card-style
updated: 2026-05-24
code:
  - .agents/skills/spectra-discuss/SKILL.md
  - .agents/skills/spectra-drift/SKILL.md
  - .agents/skills/spectra-ingest/SKILL.md
  - .agents/skills/spectra-apply/SKILL.md
  - .agents/skills/spectra-propose/SKILL.md
  - BuyLedger/BuyLedger/Features/Lookups/LookupManagementView.swift
-->

---
### Requirement: Reconciliation status is a managed lookup kind

The lookup management screen SHALL support reconciliation status as a managed kind, with the same add, rename, and delete operations and the same platform-adaptive presentation (Design System card on macOS, system List on iOS and iPadOS) as the existing order source, category, and payment method kinds. Adding a reconciliation status SHALL use a medium-height name editor sheet on all platforms (matching the add-payment-method interaction), not a plain alert. Renaming a reconciliation status SHALL update orders that reference the old value.

#### Scenario: Add a reconciliation status via the medium sheet

- **WHEN** the user activates the add control on the reconciliation status management screen and confirms a non-empty, trimmed name in the medium-height sheet
- **THEN** the status is added through the management feature and appears in the list

#### Scenario: Rename a reconciliation status cascades to orders

- **WHEN** the user renames a reconciliation status to a non-empty name different from the original
- **THEN** the status is renamed through the management feature and orders referencing the old status value are updated to the new value

#### Scenario: Delete a reconciliation status

- **WHEN** the user triggers delete on a reconciliation status
- **THEN** the status is removed through the management feature

#### Scenario: Empty state when no reconciliation statuses exist

- **WHEN** the reconciliation status management screen is shown with no items
- **THEN** the screen displays the reconciliation-status empty title and description


<!-- @trace
source: order-reconciliation-status
updated: 2026-05-29
code:
  - BuyLedger/BuyLedger/Features/Lookups/LookupManagementFeature.swift
  - BuyLedger/BuyLedger/Core/Persistence/PaymentMethodPersistence.swift
  - BuyLedger/BuyLedger/Features/Orders/Components/OptionPickerSheet.swift
  - BuyLedger/BuyLedger/Core/Dependencies/OrderRepository.swift
  - BuyLedger/BuyLedger/Features/More/MoreView.swift
  - BuyLedger/BuyLedger/Features/Orders/Components/PaymentMethodEditorSheet.swift
  - BuyLedger/BuyLedger/Features/Orders/OrdersFeature.swift
  - BuyLedger/BuyLedger/Core/Dependencies/PaymentMethodRepository.swift
  - BuyLedger/BuyLedger/Core/Persistence/PaymentMethodRecord.swift
  - BuyLedger/BuyLedger/Features/Lookups/LookupKind.swift
  - BuyLedger/BuyLedger/Core/Persistence/OrderRecord.swift
  - BuyLedger/BuyLedger/Core/Domain/LedgerOrder+Samples.swift
  - BuyLedger/BuyLedgerTests/PaymentMethodPersistenceTests.swift
  - BuyLedger/BuyLedger/Core/Domain/PaymentMethodInfo.swift
  - BuyLedger/BuyLedger/Core/Persistence/BuyLedgerSchema.swift
  - BuyLedger/BuyLedger/Features/Lookups/LookupManagementView.swift
  - BuyLedger/BuyLedger/Core/Persistence/PersistenceContainer.swift
  - BuyLedger/BuyLedger/Core/Domain/LedgerOrder.swift
  - BuyLedger/BuyLedger/Features/Orders/Components/LookupItemEditorSheet.swift
  - BuyLedger/BuyLedgerTests/OrderEditFeatureTests.swift
  - BuyLedger/BuyLedger/Features/Orders/OrderEditView.swift
  - BuyLedger/BuyLedgerTests/RootFeatureTests.swift
  - BuyLedger/BuyLedgerTests/SnapshotTests.swift
  - BuyLedger/BuyLedger/Features/Orders/OrderEditFeature.swift
  - BuyLedger/BuyLedgerTests/OrderPersistenceTests.swift
  - BuyLedger/BuyLedger/Core/Persistence/OrderPersistence.swift
  - BuyLedger/BuyLedgerTests/OrderCalculationTests.swift
  - BuyLedger/BuyLedger/Core/Dependencies/VerificationStatusRepository.swift
  - BuyLedger/BuyLedgerTests/OrdersFeaturePerformanceTests.swift
  - BuyLedger/BuyLedger/Features/App/RootFeature.swift
  - BuyLedger/BuyLedgerTests/LookupManagementFeatureTests.swift
  - BuyLedger/BuyLedger/Core/Persistence/VerificationStatusRecord.swift
  - BuyLedger/BuyLedgerTests/OrdersFeatureTests.swift
  - BuyLedger/BuyLedger/Core/Persistence/VerificationStatusPersistence.swift
-->

---
### Requirement: Payment method bank-transfer indicator

For the payment method kind, the screen SHALL display a "bank transfer" (銀行匯款) badge on each item flagged as bank transfer, in addition to the existing cardless badge. A payment method flagged as both cardless and bank transfer SHALL display both badges. The badges SHALL be present on all platforms.

#### Scenario: Bank-transfer payment method shows the badge

- **WHEN** the payment method management screen is shown and at least one method is flagged bank transfer
- **THEN** each bank-transfer method row displays the "銀行匯款" badge

#### Scenario: A method flagged both cardless and bank transfer shows both badges

- **WHEN** a payment method is flagged both cardless and bank transfer
- **THEN** its row displays both the "無卡" and "銀行匯款" badges


<!-- @trace
source: order-reconciliation-status
updated: 2026-05-29
code:
  - BuyLedger/BuyLedger/Features/Lookups/LookupManagementFeature.swift
  - BuyLedger/BuyLedger/Core/Persistence/PaymentMethodPersistence.swift
  - BuyLedger/BuyLedger/Features/Orders/Components/OptionPickerSheet.swift
  - BuyLedger/BuyLedger/Core/Dependencies/OrderRepository.swift
  - BuyLedger/BuyLedger/Features/More/MoreView.swift
  - BuyLedger/BuyLedger/Features/Orders/Components/PaymentMethodEditorSheet.swift
  - BuyLedger/BuyLedger/Features/Orders/OrdersFeature.swift
  - BuyLedger/BuyLedger/Core/Dependencies/PaymentMethodRepository.swift
  - BuyLedger/BuyLedger/Core/Persistence/PaymentMethodRecord.swift
  - BuyLedger/BuyLedger/Features/Lookups/LookupKind.swift
  - BuyLedger/BuyLedger/Core/Persistence/OrderRecord.swift
  - BuyLedger/BuyLedger/Core/Domain/LedgerOrder+Samples.swift
  - BuyLedger/BuyLedgerTests/PaymentMethodPersistenceTests.swift
  - BuyLedger/BuyLedger/Core/Domain/PaymentMethodInfo.swift
  - BuyLedger/BuyLedger/Core/Persistence/BuyLedgerSchema.swift
  - BuyLedger/BuyLedger/Features/Lookups/LookupManagementView.swift
  - BuyLedger/BuyLedger/Core/Persistence/PersistenceContainer.swift
  - BuyLedger/BuyLedger/Core/Domain/LedgerOrder.swift
  - BuyLedger/BuyLedger/Features/Orders/Components/LookupItemEditorSheet.swift
  - BuyLedger/BuyLedgerTests/OrderEditFeatureTests.swift
  - BuyLedger/BuyLedger/Features/Orders/OrderEditView.swift
  - BuyLedger/BuyLedgerTests/RootFeatureTests.swift
  - BuyLedger/BuyLedgerTests/SnapshotTests.swift
  - BuyLedger/BuyLedger/Features/Orders/OrderEditFeature.swift
  - BuyLedger/BuyLedgerTests/OrderPersistenceTests.swift
  - BuyLedger/BuyLedger/Core/Persistence/OrderPersistence.swift
  - BuyLedger/BuyLedgerTests/OrderCalculationTests.swift
  - BuyLedger/BuyLedger/Core/Dependencies/VerificationStatusRepository.swift
  - BuyLedger/BuyLedgerTests/OrdersFeaturePerformanceTests.swift
  - BuyLedger/BuyLedger/Features/App/RootFeature.swift
  - BuyLedger/BuyLedgerTests/LookupManagementFeatureTests.swift
  - BuyLedger/BuyLedger/Core/Persistence/VerificationStatusRecord.swift
  - BuyLedger/BuyLedgerTests/OrdersFeatureTests.swift
  - BuyLedger/BuyLedger/Core/Persistence/VerificationStatusPersistence.swift
-->

---
### Requirement: Payment method editing via the editor sheet

For the payment method kind, the per-item edit action SHALL be labeled "編輯" and SHALL present the payment method editor pre-filled with the item's current name, cardless flag, and bank-transfer flag. Confirming SHALL apply the edited name and flags authoritatively: changing the name SHALL rename the item and cascade to orders referencing the old name, and the cardless and bank-transfer flags SHALL be set to exactly the user's selection — including clearing a previously-set flag. The edit action SHALL be available from every per-item entry point that previously offered rename (iOS swipe, iOS context menu, macOS context menu). Other lookup kinds (order source, category, reconciliation status) SHALL retain the rename-only action labeled "重新命名".

#### Scenario: Edit a payment method's name and flags

- **WHEN** the user activates "編輯" on a payment method, changes its name, and confirms
- **THEN** the payment method is renamed, orders referencing the old name are updated, and its cardless and bank-transfer flags reflect the user's selection

#### Scenario: Clearing a flag during edit persists

- **GIVEN** a payment method currently flagged as bank transfer
- **WHEN** the user edits it, unchecks the bank-transfer flag, and confirms (with or without also changing the name)
- **THEN** the payment method's bank-transfer flag becomes false and is not restored by the rename merge

#### Scenario: Non-payment kinds keep the rename-only action

- **WHEN** the user triggers the per-item edit action on an order source, category, or reconciliation status
- **THEN** the action is labeled "重新命名" and presents a name-only rename flow without flag toggles

<!-- @trace
source: order-reconciliation-status
updated: 2026-05-29
code:
  - BuyLedger/BuyLedger/Features/Lookups/LookupManagementFeature.swift
  - BuyLedger/BuyLedger/Core/Persistence/PaymentMethodPersistence.swift
  - BuyLedger/BuyLedger/Features/Orders/Components/OptionPickerSheet.swift
  - BuyLedger/BuyLedger/Core/Dependencies/OrderRepository.swift
  - BuyLedger/BuyLedger/Features/More/MoreView.swift
  - BuyLedger/BuyLedger/Features/Orders/Components/PaymentMethodEditorSheet.swift
  - BuyLedger/BuyLedger/Features/Orders/OrdersFeature.swift
  - BuyLedger/BuyLedger/Core/Dependencies/PaymentMethodRepository.swift
  - BuyLedger/BuyLedger/Core/Persistence/PaymentMethodRecord.swift
  - BuyLedger/BuyLedger/Features/Lookups/LookupKind.swift
  - BuyLedger/BuyLedger/Core/Persistence/OrderRecord.swift
  - BuyLedger/BuyLedger/Core/Domain/LedgerOrder+Samples.swift
  - BuyLedger/BuyLedgerTests/PaymentMethodPersistenceTests.swift
  - BuyLedger/BuyLedger/Core/Domain/PaymentMethodInfo.swift
  - BuyLedger/BuyLedger/Core/Persistence/BuyLedgerSchema.swift
  - BuyLedger/BuyLedger/Features/Lookups/LookupManagementView.swift
  - BuyLedger/BuyLedger/Core/Persistence/PersistenceContainer.swift
  - BuyLedger/BuyLedger/Core/Domain/LedgerOrder.swift
  - BuyLedger/BuyLedger/Features/Orders/Components/LookupItemEditorSheet.swift
  - BuyLedger/BuyLedgerTests/OrderEditFeatureTests.swift
  - BuyLedger/BuyLedger/Features/Orders/OrderEditView.swift
  - BuyLedger/BuyLedgerTests/RootFeatureTests.swift
  - BuyLedger/BuyLedgerTests/SnapshotTests.swift
  - BuyLedger/BuyLedger/Features/Orders/OrderEditFeature.swift
  - BuyLedger/BuyLedgerTests/OrderPersistenceTests.swift
  - BuyLedger/BuyLedger/Core/Persistence/OrderPersistence.swift
  - BuyLedger/BuyLedgerTests/OrderCalculationTests.swift
  - BuyLedger/BuyLedger/Core/Dependencies/VerificationStatusRepository.swift
  - BuyLedger/BuyLedgerTests/OrdersFeaturePerformanceTests.swift
  - BuyLedger/BuyLedger/Features/App/RootFeature.swift
  - BuyLedger/BuyLedgerTests/LookupManagementFeatureTests.swift
  - BuyLedger/BuyLedger/Core/Persistence/VerificationStatusRecord.swift
  - BuyLedger/BuyLedgerTests/OrdersFeatureTests.swift
  - BuyLedger/BuyLedger/Core/Persistence/VerificationStatusPersistence.swift
-->