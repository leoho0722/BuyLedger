## REMOVED Requirements

### Requirement: Concurrent writes to the same entity are serialized through one context

**Reason**: The single long-lived persistence instance and its shared data context are replaced by one database actor that gives every transaction a fresh context; the shared context is what let a failed write's pending changes leak into later writes.

**Migration**: Serialization is now guaranteed by the requirement "Concurrent writes to the same entity are serialized through one database"; callers obtain the database through the dependency system instead of the order persistence instance provider.

## ADDED Requirements

### Requirement: Concurrent writes to the same entity are serialized through one database

Because the data tables deliberately carry no uniqueness constraint, two concurrent writes must not each observe an empty result and each insert a row. All writes SHALL be serialized through a single database instance per process. The database's write operation SHALL run each transaction body synchronously to completion on the database's actor, so that a check for an existing identifier and the insert that depends on it happen without another transaction in between. Each transaction SHALL use a fresh data context that is saved once or discarded, rather than a long-lived context shared across transactions, and the collision check SHALL therefore observe the stored state.

#### Scenario: Concurrent same-identifier writes yield one row

- **WHEN** two writes carrying the same identifier are issued concurrently
- **THEN** exactly one row exists afterwards and the later write resolves through the create-collision path rather than inserting a duplicate

##### Example: Twenty concurrent creates

- **GIVEN** an empty store
- **WHEN** 20 tasks call `OrderService.createOrder` concurrently with orders that all use identifier `order-001`
- **THEN** exactly one row with identifier `order-001` exists
- **AND** 19 of the calls throw `OrderPersistenceError.identifierCollision(id: "order-001")`

#### Scenario: Database instance is reused

- **WHEN** the database dependency is resolved more than once in the live dependency context
- **THEN** the same database instance is returned

#### Scenario: A transaction does not inherit another transaction's context

- **WHEN** two write transactions run one after the other
- **THEN** each receives its own data context
- **AND** the second transaction's context holds no object state left by the first

### Requirement: A failed write leaves nothing behind for later writes

When a database write fails, either inside its transaction body or when saving, none of its changes SHALL reach the store, including through any later successful write that touches the same row. A deletion that failed SHALL NOT be treated as done by a later operation, and field changes that failed SHALL NOT be persisted by a later write that changes other fields of the same row. The test suite SHALL include a guard that injects a real save failure into the failing transaction's own context, and that guard SHALL fail when transactions are changed to share a long-lived context.

#### Scenario: A later operation on the same row does not persist a failed change

- **GIVEN** a stored order and a write to that order that fails during save
- **WHEN** a later write to the same order succeeds
- **THEN** the store reflects only the later write applied to the state before the failed write

##### Example: Follow-up operations after a failed write

| Failed write | Later operation on the same order | Required stored outcome |
| ------------ | --------------------------------- | ----------------------- |
| `removeOrder` of `order-001` | `removeOrder` of `order-001` | no row with identifier `order-001` remains |
| `removeOrder` of `order-001` | `createOrder` with identifier `order-001` | the create throws `identifierCollision(id: "order-001")` and exactly one row remains |
| `removeOrder` of `order-001` | `saveOrder` of `order-001` | exactly one row with identifier `order-001` remains |
| `saveOrder` changing notes, payment method, and charged amount of `order-001` | `renameOrderCampaign` renaming a campaign that `order-001` belongs to | the row keeps its notes, payment method, and charged amount from before the failed save and carries the new campaign name |

#### Scenario: Reintroducing a shared context is caught

- **WHEN** the database is changed so that write transactions reuse one long-lived context
- **THEN** at least one follow-up scenario in the guard fails
