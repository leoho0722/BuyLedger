## MODIFIED Requirements

### Requirement: Saving a merged draft commits atomically

When the user saves the prefilled merge form, the system SHALL, in a single persistence operation: insert the new merged order with both source order IDs recorded in its merged-source list, and set the status of both source orders to merged. The in-memory orders list SHALL reflect the new order and both source-status changes together. When persistence fails, neither the new order nor any source-status change SHALL be applied, and the failure SHALL surface through the existing persistence error path. An order not produced by a merge SHALL have an empty merged-source list.

The merged order SHALL be written with create intent. When its identifier collides with an existing order, the whole operation SHALL fail and SHALL NOT overwrite the existing order, so that a merge can never consume an unrelated order.

#### Scenario: Save commits the merge

- **WHEN** the user saves the merge form
- **THEN** the orders list contains the new merged order carrying both source order IDs, and both source orders with status merged, and the same state is persisted

#### Scenario: Persistence failure leaves no partial merge

- **WHEN** persistence fails while saving the merge
- **THEN** no new order exists, both source orders keep their previous status, and the failure surfaces through the existing persistence error path

#### Scenario: Identifier collision aborts the merge

- **WHEN** the merged order's identifier already belongs to an existing order
- **THEN** the operation fails, the existing order is unchanged in every field, and neither source order's status is modified
