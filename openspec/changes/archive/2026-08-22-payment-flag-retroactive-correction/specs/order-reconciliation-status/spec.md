## MODIFIED Requirements

### Requirement: Reconciliation status persistence and clearing rule

An order's reconciliation status SHALL be persisted only while its payment method is classified as cardless or bank transfer. When the order's payment method changes to one that is neither, the stored reconciliation status SHALL be cleared, so that an order does not retain a status that no longer applies to it.

The same clearing SHALL apply when the payment method itself stops being classified as cardless or bank transfer, rather than only when the order's payment method changes. A flag corrected on the lookup governs every order using that payment method, so leaving those orders with a reconciliation status that no longer applies would preserve exactly the stale state the correction was meant to remove.

#### Scenario: Changing an order to an unclassified payment method clears the status

- **WHEN** an order carrying a reconciliation status is edited to use a payment method that is neither cardless nor bank transfer, and saved
- **THEN** the stored reconciliation status is cleared

#### Scenario: Clearing the flags on the lookup clears the status on existing orders

- **WHEN** a payment method's cardless and bank-transfer flags are both cleared on the lookup and the recomputation is confirmed
- **THEN** every order using that payment method has its reconciliation status cleared

#### Scenario: A still-classified payment method keeps the status

- **WHEN** a payment method's cardless flag is cleared but it remains flagged as bank transfer
- **THEN** orders using it keep their reconciliation status, because the status still applies
