# order-reconciliation-status Specification

## Purpose

TBD - created by archiving change 'order-reconciliation-status'. Update Purpose after archive.

## Requirements

### Requirement: Payment method bank-transfer classification

The system SHALL allow a payment method to be flagged as "bank transfer" (`isBankTransfer`), independent of the existing "cardless" (`isCardless`) flag. The new-payment-method editor SHALL collect both flags via separate toggles. The bank-transfer flag SHALL default to false and SHALL persist across app launches. The two flags SHALL be independent — a payment method MAY have neither, either, or both set.

#### Scenario: Add a payment method flagged as bank transfer

- **WHEN** the user adds a payment method and enables the "bank transfer" toggle
- **THEN** the payment method is stored with `isBankTransfer` set to true and `isCardless` reflecting its own toggle

#### Scenario: Bank-transfer flag defaults to false

- **WHEN** the user adds a payment method without enabling the "bank transfer" toggle
- **THEN** the payment method is stored with `isBankTransfer` set to false

#### Scenario: Bank-transfer flag persists across launches

- **WHEN** a payment method flagged as bank transfer is read back after an app relaunch
- **THEN** its `isBankTransfer` flag is still true


<!-- @trace
source: order-reconciliation-status
updated: 2026-05-29
code:
  - apps/apple/BuyLedger/Features/Lookups/LookupManagementFeature.swift
  - apps/apple/BuyLedger/Core/Persistence/PaymentMethodPersistence.swift
  - apps/apple/BuyLedger/Features/Orders/Components/OptionPickerSheet.swift
  - apps/apple/BuyLedger/Core/Dependencies/OrderRepository.swift
  - apps/apple/BuyLedger/Features/More/MoreView.swift
  - apps/apple/BuyLedger/Features/Orders/Components/PaymentMethodEditorSheet.swift
  - apps/apple/BuyLedger/Features/Orders/OrdersFeature.swift
  - apps/apple/BuyLedger/Core/Dependencies/PaymentMethodRepository.swift
  - apps/apple/BuyLedger/Core/Persistence/PaymentMethodRecord.swift
  - apps/apple/BuyLedger/Features/Lookups/LookupKind.swift
  - apps/apple/BuyLedger/Core/Persistence/OrderRecord.swift
  - apps/apple/BuyLedger/Core/Domain/LedgerOrder+Samples.swift
  - apps/apple/BuyLedgerTests/PaymentMethodPersistenceTests.swift
  - apps/apple/BuyLedger/Core/Domain/PaymentMethodInfo.swift
  - apps/apple/BuyLedger/Core/Persistence/BuyLedgerSchema.swift
  - apps/apple/BuyLedger/Features/Lookups/LookupManagementView.swift
  - apps/apple/BuyLedger/Core/Persistence/PersistenceContainer.swift
  - apps/apple/BuyLedger/Core/Domain/LedgerOrder.swift
  - apps/apple/BuyLedger/Features/Orders/Components/LookupItemEditorSheet.swift
  - apps/apple/BuyLedgerTests/OrderEditFeatureTests.swift
  - apps/apple/BuyLedger/Features/Orders/OrderEditView.swift
  - apps/apple/BuyLedgerTests/RootFeatureTests.swift
  - apps/apple/BuyLedgerTests/SnapshotTests.swift
  - apps/apple/BuyLedger/Features/Orders/OrderEditFeature.swift
  - apps/apple/BuyLedgerTests/OrderPersistenceTests.swift
  - apps/apple/BuyLedger/Core/Persistence/OrderPersistence.swift
  - apps/apple/BuyLedgerTests/OrderCalculationTests.swift
  - apps/apple/BuyLedger/Core/Dependencies/VerificationStatusRepository.swift
  - apps/apple/BuyLedgerTests/OrdersFeaturePerformanceTests.swift
  - apps/apple/BuyLedger/Features/App/RootFeature.swift
  - apps/apple/BuyLedgerTests/LookupManagementFeatureTests.swift
  - apps/apple/BuyLedger/Core/Persistence/VerificationStatusRecord.swift
  - apps/apple/BuyLedgerTests/OrdersFeatureTests.swift
  - apps/apple/BuyLedger/Core/Persistence/VerificationStatusPersistence.swift
-->

---
### Requirement: Conditional reconciliation status row in order editing

WHEN the payment method currently selected in the order edit form is flagged cardless OR bank-transfer, the form SHALL display a "reconciliation status" (對帳狀態) row directly below the payment method row. WHEN the selected payment method is neither cardless nor bank-transfer, the form SHALL NOT display the reconciliation status row. The visibility SHALL update immediately when the selected payment method changes.

#### Scenario: Cardless payment method reveals the row

- **WHEN** the selected payment method is flagged cardless
- **THEN** the order edit form displays the reconciliation status row below the payment method row

#### Scenario: Bank-transfer payment method reveals the row

- **WHEN** the selected payment method is flagged bank transfer
- **THEN** the order edit form displays the reconciliation status row below the payment method row

#### Scenario: Other payment method hides the row

- **WHEN** the selected payment method is neither cardless nor bank transfer
- **THEN** the order edit form does not display the reconciliation status row


<!-- @trace
source: order-reconciliation-status
updated: 2026-05-29
code:
  - apps/apple/BuyLedger/Features/Lookups/LookupManagementFeature.swift
  - apps/apple/BuyLedger/Core/Persistence/PaymentMethodPersistence.swift
  - apps/apple/BuyLedger/Features/Orders/Components/OptionPickerSheet.swift
  - apps/apple/BuyLedger/Core/Dependencies/OrderRepository.swift
  - apps/apple/BuyLedger/Features/More/MoreView.swift
  - apps/apple/BuyLedger/Features/Orders/Components/PaymentMethodEditorSheet.swift
  - apps/apple/BuyLedger/Features/Orders/OrdersFeature.swift
  - apps/apple/BuyLedger/Core/Dependencies/PaymentMethodRepository.swift
  - apps/apple/BuyLedger/Core/Persistence/PaymentMethodRecord.swift
  - apps/apple/BuyLedger/Features/Lookups/LookupKind.swift
  - apps/apple/BuyLedger/Core/Persistence/OrderRecord.swift
  - apps/apple/BuyLedger/Core/Domain/LedgerOrder+Samples.swift
  - apps/apple/BuyLedgerTests/PaymentMethodPersistenceTests.swift
  - apps/apple/BuyLedger/Core/Domain/PaymentMethodInfo.swift
  - apps/apple/BuyLedger/Core/Persistence/BuyLedgerSchema.swift
  - apps/apple/BuyLedger/Features/Lookups/LookupManagementView.swift
  - apps/apple/BuyLedger/Core/Persistence/PersistenceContainer.swift
  - apps/apple/BuyLedger/Core/Domain/LedgerOrder.swift
  - apps/apple/BuyLedger/Features/Orders/Components/LookupItemEditorSheet.swift
  - apps/apple/BuyLedgerTests/OrderEditFeatureTests.swift
  - apps/apple/BuyLedger/Features/Orders/OrderEditView.swift
  - apps/apple/BuyLedgerTests/RootFeatureTests.swift
  - apps/apple/BuyLedgerTests/SnapshotTests.swift
  - apps/apple/BuyLedger/Features/Orders/OrderEditFeature.swift
  - apps/apple/BuyLedgerTests/OrderPersistenceTests.swift
  - apps/apple/BuyLedger/Core/Persistence/OrderPersistence.swift
  - apps/apple/BuyLedgerTests/OrderCalculationTests.swift
  - apps/apple/BuyLedger/Core/Dependencies/VerificationStatusRepository.swift
  - apps/apple/BuyLedgerTests/OrdersFeaturePerformanceTests.swift
  - apps/apple/BuyLedger/Features/App/RootFeature.swift
  - apps/apple/BuyLedgerTests/LookupManagementFeatureTests.swift
  - apps/apple/BuyLedger/Core/Persistence/VerificationStatusRecord.swift
  - apps/apple/BuyLedgerTests/OrdersFeatureTests.swift
  - apps/apple/BuyLedger/Core/Persistence/VerificationStatusPersistence.swift
-->

---
### Requirement: Selecting and adding a reconciliation status during order editing

The reconciliation status row SHALL open a picker listing the reconciliation status master data and SHALL let the user select one. The picker SHALL provide an add control that presents a medium-height sheet collecting a single name. Confirming the add SHALL add the name to the reconciliation status master data and apply it to the current order. When the master data is empty, the picker SHALL show the configured empty state and the row SHALL show a placeholder rather than a value.

#### Scenario: Select an existing reconciliation status

- **WHEN** the user opens the picker and taps a reconciliation status row
- **THEN** that status becomes the order's draft reconciliation status and the picker dismisses

#### Scenario: Add a reconciliation status via the medium sheet

- **WHEN** the user taps the add control, enters a non-empty trimmed name in the medium-height sheet, and confirms
- **THEN** the name is added to the reconciliation status master data and applied to the current order

#### Scenario: Empty master data shows an empty state

- **WHEN** the picker is presented and no reconciliation statuses exist
- **THEN** the picker shows the configured empty title and description and the row shows a placeholder


<!-- @trace
source: order-reconciliation-status
updated: 2026-05-29
code:
  - apps/apple/BuyLedger/Features/Lookups/LookupManagementFeature.swift
  - apps/apple/BuyLedger/Core/Persistence/PaymentMethodPersistence.swift
  - apps/apple/BuyLedger/Features/Orders/Components/OptionPickerSheet.swift
  - apps/apple/BuyLedger/Core/Dependencies/OrderRepository.swift
  - apps/apple/BuyLedger/Features/More/MoreView.swift
  - apps/apple/BuyLedger/Features/Orders/Components/PaymentMethodEditorSheet.swift
  - apps/apple/BuyLedger/Features/Orders/OrdersFeature.swift
  - apps/apple/BuyLedger/Core/Dependencies/PaymentMethodRepository.swift
  - apps/apple/BuyLedger/Core/Persistence/PaymentMethodRecord.swift
  - apps/apple/BuyLedger/Features/Lookups/LookupKind.swift
  - apps/apple/BuyLedger/Core/Persistence/OrderRecord.swift
  - apps/apple/BuyLedger/Core/Domain/LedgerOrder+Samples.swift
  - apps/apple/BuyLedgerTests/PaymentMethodPersistenceTests.swift
  - apps/apple/BuyLedger/Core/Domain/PaymentMethodInfo.swift
  - apps/apple/BuyLedger/Core/Persistence/BuyLedgerSchema.swift
  - apps/apple/BuyLedger/Features/Lookups/LookupManagementView.swift
  - apps/apple/BuyLedger/Core/Persistence/PersistenceContainer.swift
  - apps/apple/BuyLedger/Core/Domain/LedgerOrder.swift
  - apps/apple/BuyLedger/Features/Orders/Components/LookupItemEditorSheet.swift
  - apps/apple/BuyLedgerTests/OrderEditFeatureTests.swift
  - apps/apple/BuyLedger/Features/Orders/OrderEditView.swift
  - apps/apple/BuyLedgerTests/RootFeatureTests.swift
  - apps/apple/BuyLedgerTests/SnapshotTests.swift
  - apps/apple/BuyLedger/Features/Orders/OrderEditFeature.swift
  - apps/apple/BuyLedgerTests/OrderPersistenceTests.swift
  - apps/apple/BuyLedger/Core/Persistence/OrderPersistence.swift
  - apps/apple/BuyLedgerTests/OrderCalculationTests.swift
  - apps/apple/BuyLedger/Core/Dependencies/VerificationStatusRepository.swift
  - apps/apple/BuyLedgerTests/OrdersFeaturePerformanceTests.swift
  - apps/apple/BuyLedger/Features/App/RootFeature.swift
  - apps/apple/BuyLedgerTests/LookupManagementFeatureTests.swift
  - apps/apple/BuyLedger/Core/Persistence/VerificationStatusRecord.swift
  - apps/apple/BuyLedgerTests/OrdersFeatureTests.swift
  - apps/apple/BuyLedger/Core/Persistence/VerificationStatusPersistence.swift
-->

---
### Requirement: Reconciliation status persistence and clearing rule

An order SHALL persist a reconciliation status string. WHEN an order is saved, if its payment method is neither cardless nor bank-transfer, the system SHALL store an empty reconciliation status; otherwise it SHALL store the selected reconciliation status. The stored value SHALL survive a persistence round-trip.

#### Scenario: Status is preserved for a cardless or bank-transfer order

- **WHEN** an order with a cardless or bank-transfer payment method is saved with a selected reconciliation status
- **THEN** the saved order retains that reconciliation status

#### Scenario: Status is cleared when payment method does not require reconciliation

- **WHEN** an order is saved with a payment method that is neither cardless nor bank-transfer
- **THEN** the saved order's reconciliation status is an empty string

##### Example: clearing rule by payment method classification

| Payment method classification | Draft reconciliation status | Stored reconciliation status |
| ----------------------------- | --------------------------- | ---------------------------- |
| cardless                      | "對帳成功"                  | "對帳成功"                   |
| bank transfer                 | "待對帳"                    | "待對帳"                     |
| neither (e.g. credit card)    | "待對帳"                    | "" (empty)                   |

#### Scenario: Reconciliation status survives a persistence round-trip

- **WHEN** an order with a non-empty reconciliation status is written to persistence and read back
- **THEN** the reconciliation status of the read-back order equals the written value

<!-- @trace
source: order-reconciliation-status
updated: 2026-05-29
code:
  - apps/apple/BuyLedger/Features/Lookups/LookupManagementFeature.swift
  - apps/apple/BuyLedger/Core/Persistence/PaymentMethodPersistence.swift
  - apps/apple/BuyLedger/Features/Orders/Components/OptionPickerSheet.swift
  - apps/apple/BuyLedger/Core/Dependencies/OrderRepository.swift
  - apps/apple/BuyLedger/Features/More/MoreView.swift
  - apps/apple/BuyLedger/Features/Orders/Components/PaymentMethodEditorSheet.swift
  - apps/apple/BuyLedger/Features/Orders/OrdersFeature.swift
  - apps/apple/BuyLedger/Core/Dependencies/PaymentMethodRepository.swift
  - apps/apple/BuyLedger/Core/Persistence/PaymentMethodRecord.swift
  - apps/apple/BuyLedger/Features/Lookups/LookupKind.swift
  - apps/apple/BuyLedger/Core/Persistence/OrderRecord.swift
  - apps/apple/BuyLedger/Core/Domain/LedgerOrder+Samples.swift
  - apps/apple/BuyLedgerTests/PaymentMethodPersistenceTests.swift
  - apps/apple/BuyLedger/Core/Domain/PaymentMethodInfo.swift
  - apps/apple/BuyLedger/Core/Persistence/BuyLedgerSchema.swift
  - apps/apple/BuyLedger/Features/Lookups/LookupManagementView.swift
  - apps/apple/BuyLedger/Core/Persistence/PersistenceContainer.swift
  - apps/apple/BuyLedger/Core/Domain/LedgerOrder.swift
  - apps/apple/BuyLedger/Features/Orders/Components/LookupItemEditorSheet.swift
  - apps/apple/BuyLedgerTests/OrderEditFeatureTests.swift
  - apps/apple/BuyLedger/Features/Orders/OrderEditView.swift
  - apps/apple/BuyLedgerTests/RootFeatureTests.swift
  - apps/apple/BuyLedgerTests/SnapshotTests.swift
  - apps/apple/BuyLedger/Features/Orders/OrderEditFeature.swift
  - apps/apple/BuyLedgerTests/OrderPersistenceTests.swift
  - apps/apple/BuyLedger/Core/Persistence/OrderPersistence.swift
  - apps/apple/BuyLedgerTests/OrderCalculationTests.swift
  - apps/apple/BuyLedger/Core/Dependencies/VerificationStatusRepository.swift
  - apps/apple/BuyLedgerTests/OrdersFeaturePerformanceTests.swift
  - apps/apple/BuyLedger/Features/App/RootFeature.swift
  - apps/apple/BuyLedgerTests/LookupManagementFeatureTests.swift
  - apps/apple/BuyLedger/Core/Persistence/VerificationStatusRecord.swift
  - apps/apple/BuyLedgerTests/OrdersFeatureTests.swift
  - apps/apple/BuyLedger/Core/Persistence/VerificationStatusPersistence.swift
-->