## ADDED Requirements

### Requirement: Every order carries a payment receipt status

The system SHALL provide a payment receipt status on every order with exactly two values: pending ("待收款") and received ("已收款"). New orders and existing orders migrated from earlier schema versions SHALL default to pending.

#### Scenario: Default receipt status

- **WHEN** an order is created without an explicit receipt status
- **THEN** the order's receipt status is pending

### Requirement: Receipt status is editable for all orders

The system SHALL let the user set an order's payment receipt status in the order editor regardless of the order's payment method.

#### Scenario: Set an order to received

- **WHEN** the user sets an order's receipt status to received and saves
- **THEN** the order persists with receipt status received

### Requirement: Receipt status is the source of truth for received amounts

The payment receipt status SHALL be the sole source of truth for the "received" determination in campaign distribution and settlement. An order's charged amount SHALL contribute to a campaign's received amount only when that order's receipt status is received.

#### Scenario: Received order contributes to received amount

- **WHEN** an order belonging to a campaign has receipt status received
- **THEN** its charged amount is included in that campaign's received amount

#### Scenario: Pending order does not contribute to received amount

- **WHEN** an order belonging to a campaign has receipt status pending
- **THEN** its charged amount is excluded from that campaign's received amount but included in receivables
