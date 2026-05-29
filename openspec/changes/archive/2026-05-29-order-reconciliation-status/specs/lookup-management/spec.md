## ADDED Requirements

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

### Requirement: Payment method bank-transfer indicator

For the payment method kind, the screen SHALL display a "bank transfer" (銀行匯款) badge on each item flagged as bank transfer, in addition to the existing cardless badge. A payment method flagged as both cardless and bank transfer SHALL display both badges. The badges SHALL be present on all platforms.

#### Scenario: Bank-transfer payment method shows the badge

- **WHEN** the payment method management screen is shown and at least one method is flagged bank transfer
- **THEN** each bank-transfer method row displays the "銀行匯款" badge

#### Scenario: A method flagged both cardless and bank transfer shows both badges

- **WHEN** a payment method is flagged both cardless and bank transfer
- **THEN** its row displays both the "無卡" and "銀行匯款" badges

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
