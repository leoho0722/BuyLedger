## MODIFIED Requirements

### Requirement: Payment method editing via the editor sheet

For the payment method kind, the per-item edit action SHALL be labeled "編輯" and SHALL present the payment method editor pre-filled with the item's current name, cardless flag, and bank-transfer flag. Confirming SHALL apply the edited name and flags authoritatively: changing the name SHALL rename the item and cascade to orders referencing the old name, and the cardless and bank-transfer flags SHALL be set to exactly the user's selection — including clearing a previously-set flag. The edit action SHALL be available from every per-item entry point that previously offered rename (iOS swipe, iOS context menu). Other lookup kinds (order source, category, reconciliation status) SHALL retain the rename-only action labeled "重新命名".

Applying flags authoritatively SHALL extend to orders already using the payment method. The flags govern how an order's finances are computed, so leaving existing orders on the previous flags would keep computing them from a state the user has just corrected. Existing orders SHALL therefore be recomputed using the same normalization the order editor applies, and SHALL be written together with the lookup update so that a failure applies neither.

Because recomputation rewrites stored values of existing orders and cannot be undone, it SHALL be confirmed before it runs. The confirmation SHALL state how many orders will be affected. Declining SHALL leave both the orders and the lookup flags unchanged, so that the lookup and the orders never disagree.

#### Scenario: Edit a payment method's name and flags

- **WHEN** the user activates "編輯" on a payment method, changes its name, and confirms
- **THEN** the payment method is renamed, orders referencing the old name are updated, and its cardless and bank-transfer flags reflect the user's selection

#### Scenario: Correcting a missed cash-on-delivery flag fixes existing profit

- **WHEN** the user sets the cash-on-delivery flag on a payment method that orders already use, and confirms the recomputation
- **THEN** those orders are recomputed so that the three shipping amounts are included in their cost, and their reported profit changes accordingly

#### Scenario: Confirmation states the blast radius

- **WHEN** a flag change would affect existing orders
- **THEN** the confirmation states the number of orders that will be recomputed

#### Scenario: Declining leaves everything unchanged

- **WHEN** the user declines the recomputation confirmation
- **THEN** neither the orders nor the payment method's flags are changed

#### Scenario: Recomputation and lookup update are atomic

- **WHEN** persistence fails while recomputing affected orders
- **THEN** neither the orders nor the payment method's flags are changed

#### Scenario: Clearing the cardless flag clears dependent amounts

- **WHEN** the user clears the cardless flag on a payment method that orders already use, and confirms
- **THEN** those orders' cardless deduction and supplement amounts become zero, matching what the order editor would produce
