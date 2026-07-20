## ADDED Requirements

### Requirement: Destructive actions are confirmed consistently across the app

A destructive action that is uncommon and not reversible SHALL require confirmation before it proceeds. The requirement SHALL apply consistently regardless of which feature module the action lives in. Deleting a lookup item cascades into existing orders and is therefore at least as destructive as deleting a single order, which already requires confirmation.

#### Scenario: Deleting a lookup item requires confirmation

- **WHEN** the user invokes delete on a lookup item, whether from the context menu or the swipe action
- **THEN** a confirmation is presented before anything is removed, and its message states that existing orders referencing the item are affected

#### Scenario: Cancelling the confirmation changes nothing

- **WHEN** the user dismisses the deletion confirmation without confirming
- **THEN** the item remains present and no persistence operation occurs

### Requirement: Deletion updates state only after persistence succeeds

A deletion SHALL update the presented state only after the persistence operation succeeds. Optimistic removal followed by an error message SHALL NOT be used, because it leaves the user seeing a failure message alongside an item that has already disappeared.

#### Scenario: Failed deletion leaves the item visible

- **WHEN** the user confirms deletion and the persistence operation fails
- **THEN** the item remains visible in the list and a failure message is shown

#### Scenario: Successful deletion removes the item

- **WHEN** the user confirms deletion and the persistence operation succeeds
- **THEN** the item is removed from the list and from any in-memory copies held elsewhere
