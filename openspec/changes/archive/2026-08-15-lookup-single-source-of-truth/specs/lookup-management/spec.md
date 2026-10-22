## ADDED Requirements

### Requirement: Lookup data has a single source shared by every consumer

The four lookup kinds — order source, category, payment method, and reconciliation status — SHALL be held in one store shared by every consumer, rather than copied into each feature that reads them. A consumer SHALL derive its view of a lookup kind from that store rather than maintaining its own collection.

Adding, renaming, or deleting a lookup item SHALL become visible to every consumer within the same state update, without requiring a separate action to propagate it and without depending on a root-level interception for each operation.

Consistency SHALL NOT depend on hand-written synchronization between copies. Where a lookup change must also rewrite stored orders, that rewrite SHALL happen in the same update as the lookup change, so that a derived list that unions lookup values with values used by orders can never briefly show the old name.

#### Scenario: Renaming reaches every consumer in one update

- **WHEN** a lookup item of any kind is renamed
- **THEN** the management list, the order editor's selectable values for that kind, and the orders referencing the old value are all updated in the same state update, with no further action sent

#### Scenario: A rename never leaves the old name reachable

- **WHEN** a lookup item is renamed and a selectable list unions lookup values with values already used by orders
- **THEN** that list does not contain the old name at any point after the update

#### Scenario: Adding inside the order editor is visible in management

- **WHEN** the user adds a lookup item from within the order editor
- **THEN** the item appears on that kind's management screen without relaunching the app

#### Scenario: Deleting removes the value from every consumer

- **WHEN** a lookup item is deleted
- **THEN** the order editor no longer offers it as a selectable value

### Requirement: Adding a lookup kind is a compile-time obligation

The differences between lookup kinds — how an order references a value of that kind, and how an order is rewritten when that value is renamed — SHALL be expressed on the lookup-kind type itself as exhaustive mappings, so that introducing a new kind fails to compile until those differences are supplied.

Consumers SHALL NOT branch on lookup kind to perform these operations; they SHALL delegate to the kind. Introducing a new kind SHALL NOT require adding a parallel property, action case, or scope in the root feature.

#### Scenario: A new kind does not compile until its differences are supplied

- **WHEN** a new lookup kind is added to the lookup-kind type
- **THEN** compilation fails until that kind supplies how orders reference it and how orders are rewritten on rename

#### Scenario: Compilation errors are confined to the kind and the shared store

- **WHEN** a new lookup kind is added and the project is built
- **THEN** the errors appear only in the lookup-kind type and the shared lookup store, not in the root feature or the orders feature

#### Scenario: Cascade contains no per-kind branching at the call site

- **WHEN** the cascade that rewrites orders after a rename is inspected
- **THEN** it delegates to the lookup kind and contains no branch over the set of kinds

## MODIFIED Requirements

### Requirement: Lookup item management operations are preserved across platforms

The screen SHALL allow the user to add, rename, and delete lookup items on iOS and iPadOS. The add, rename, and delete operations and their validation SHALL behave identically on both, and SHALL write through the same management feature as before this change.

Each operation SHALL take effect for every consumer of that lookup kind as part of the same state update, rather than through separate synchronization performed by the root feature. Persistence behavior is unchanged: the operation is written to the store, and the destructive path continues to update state only after the write succeeds.

When a lookup management screen cannot be resolved for a requested kind, the screen SHALL present the existing load-failure view rather than rendering blank, so that a resolution failure is visible rather than silent.

#### Scenario: Add a lookup item

- **WHEN** the user activates the toolbar add control and confirms a non-empty, trimmed name
- **THEN** the item is added through the management feature and appears in the list

#### Scenario: Rename a lookup item

- **WHEN** the user triggers rename on an item and confirms a non-empty name different from the original
- **THEN** the item is renamed through the management feature and orders referencing the old name are updated

#### Scenario: Delete a lookup item

- **WHEN** the user triggers delete on an item
- **THEN** the item is removed through the management feature

#### Scenario: iOS swipe-to-delete is retained

- **WHEN** the user swipes an item row on iOS or iPadOS
- **THEN** the swipe actions for delete and rename are available, unchanged from before this change

#### Scenario: An unresolvable management screen is visibly failed, not blank

- **WHEN** the management screen for a requested lookup kind cannot be resolved
- **THEN** the load-failure view is shown instead of an empty screen
