## MODIFIED Requirements

### Requirement: Batch status persistence is atomic on Apple

On Apple platforms (iOS and iPadOS) where orders persist to the local store, a batch status update SHALL persist all changed orders in a single save operation rather than one save per order.

Atomicity SHALL extend to the presented state. When the single save fails, none of the selected orders SHALL change in the presented list, so that a batch can never appear partially applied.

#### Scenario: Single persistence for a multi-order batch

- **WHEN** a batch status update changes the status of four orders
- **THEN** all four changed orders are written to the local store in one save operation

#### Scenario: Failed batch changes nothing

- **WHEN** a batch status update is applied to four orders and the save operation fails
- **THEN** all four orders retain their previous status in the presented list and the failure is surfaced
