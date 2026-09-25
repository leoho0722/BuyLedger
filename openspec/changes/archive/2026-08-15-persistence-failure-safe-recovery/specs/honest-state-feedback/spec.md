## ADDED Requirements

### Requirement: Total data-layer failure is surfaced at launch rather than silently absorbed

When the persistence layer cannot be opened at all, the app SHALL NOT present an apparently working interface backed by volatile storage. It SHALL block the interface, state that the data cannot be opened, state that the existing data remains intact on the device, and instruct the user not to enter data. This is distinct from a per-screen load failure, which retains its retry affordance.

#### Scenario: Volatile fallback is never presented as normal operation

- **WHEN** the persistence layer falls back to an in-memory container because the on-disk store cannot be opened
- **THEN** the app presents the blocking failure state instead of the normal interface, so that no user input is accepted into storage that will be discarded at next launch

#### Scenario: Launch failure is distinguished from screen load failure

- **WHEN** a screen's data query fails while the persistence layer itself opened successfully
- **THEN** the screen shows its own failure state with a retry control and the app remains usable

##### Example: failure scope resolution

| Persistence layer opened | Screen query succeeded | Resulting presentation |
| ------------------------ | ---------------------- | ---------------------- |
| no | not reached | blocking launch failure screen, no navigation |
| yes | no | per-screen failure state with retry control |
| yes | yes | normal content |

#### Scenario: Recovery instruction is actionable

- **WHEN** the blocking failure state is presented
- **THEN** it offers a confirmed recovery action and states what the user must do next, rather than only reporting that something went wrong
