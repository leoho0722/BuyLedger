## ADDED Requirements

### Requirement: Order write paths update presented state only after persistence resolves

Every order write path SHALL update the presented state only after the persistence operation succeeds. This covers changing a single order's status, applying a batch status change, changing a receipt status, deleting an order, and saving an edited order. Optimistic mutation followed by an error message SHALL NOT be used on any of these paths, because it leaves the presented ledger disagreeing with the stored ledger until the next cold launch.

**Exception:** Saving an edited order that merges one or more source orders into a new order (a non-empty merge source set) is a deliberate, pre-existing exception to this rule. A merge write couples two mutations that must succeed or fail together — inserting the new merged order and marking each source order as merged — so the presented state applies both optimistically and rolls back to a pre-merge snapshot if the single persistence call fails. This exception SHALL NOT be extended to any other order write path.

#### Scenario: Merge is a deliberate exception to write-then-update ordering

- **WHEN** the user saves an edited order with a non-empty merge source set and persistence fails
- **THEN** the presented state, which was optimistically updated to reflect the merge, is rolled back to the pre-merge snapshot, unlike every other write path where the mutation is never applied until persistence succeeds

#### Scenario: Failed single status change leaves the order untouched

- **WHEN** the user changes an order's status and persistence fails
- **THEN** the order retains its previous status in the list and no partial change is visible

#### Scenario: Failed receipt status change leaves the order untouched

- **WHEN** the user changes an order's receipt status and persistence fails
- **THEN** the order retains its previous receipt status in the list

#### Scenario: Failed save leaves the order untouched

- **WHEN** the user saves an edited order and persistence fails
- **THEN** the order retains its previous values in the list

#### Scenario: Presented ledger survives a relaunch unchanged

- **WHEN** any write path fails and the orders are subsequently reloaded from storage
- **THEN** the reloaded list is identical to what was presented immediately after the failure

#### Scenario: Successful write updates the list

- **WHEN** any write path succeeds
- **THEN** the list reflects the new values

### Requirement: One-shot operation failures are presented separately from load failures

A failure of a single user-initiated operation SHALL be presented as a transient confirmation dialog that the user dismisses. It SHALL NOT be rendered as persistent text attached to the list. A failure to load the orders SHALL keep its existing persistent failure state with a retry control. The two SHALL NOT share a single message field, so that dismissing one cannot depend on the lifecycle of the other.

#### Scenario: Operation failure is dismissible and leaves no residue

- **WHEN** a write operation fails and the user dismisses the resulting dialog
- **THEN** no error text remains anywhere in the list presentation

#### Scenario: Later success is not shadowed by an earlier failure

- **WHEN** a write operation fails and a subsequent write operation succeeds
- **THEN** no residue of the earlier failure is presented

#### Scenario: Load failure keeps its persistent presentation

- **WHEN** loading the orders fails
- **THEN** the screen shows its persistent failure state with a retry control rather than a transient dialog

##### Example: failure presentation by kind

| Failure kind | Presentation | Cleared by |
| ------------ | ------------ | ---------- |
| order load failed | persistent failure state with retry | a successful retry |
| single write failed | transient dialog | user dismissal |
| batch write failed | transient dialog | user dismissal |
