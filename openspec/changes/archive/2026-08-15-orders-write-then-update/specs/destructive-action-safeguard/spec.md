## MODIFIED Requirements

### Requirement: Deletion updates state only after persistence succeeds

A deletion SHALL update the presented state only after the persistence operation succeeds. Optimistic removal followed by an error message SHALL NOT be used, because it leaves the user seeing a failure message alongside an item that has already disappeared.

The same ordering SHALL apply to every order write path, not only to deletion: status changes, batch status changes, receipt status changes, and saving an edited order SHALL all update the presented state only after persistence succeeds. The reason is identical in each case, so the rule SHALL NOT be limited to the path where it was first applied.

Saving an edited order that merges source orders (a non-empty merge source set) is excluded from this generalization; it is a deliberate, pre-existing exception documented in the `order-write-ordering` capability's "Merge is a deliberate exception to write-then-update ordering" scenario, not a violation of this rule.

#### Scenario: Failed deletion leaves the item visible

- **WHEN** the user confirms deletion and the persistence operation fails
- **THEN** the item remains visible in the list and a failure message is shown

#### Scenario: Successful deletion removes the item

- **WHEN** the user confirms deletion and the persistence operation succeeds
- **THEN** the item is removed from the list and from any in-memory copies held elsewhere

#### Scenario: Non-deletion write paths follow the same ordering

- **WHEN** a non-deletion order write fails
- **THEN** the presented order is unchanged, exactly as a failed deletion leaves the item visible
