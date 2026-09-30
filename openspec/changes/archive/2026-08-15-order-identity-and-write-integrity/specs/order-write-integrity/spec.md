## ADDED Requirements

### Requirement: Order identifiers are generated at full strength

A newly created order SHALL receive a full-length random identifier. The identifier SHALL NOT be truncated before storage. When a shortened form is wanted for display, the display layer SHALL derive it from the stored identifier rather than the stored value being shortened.

#### Scenario: New orders receive full-length identifiers

- **WHEN** a new order draft is created
- **THEN** its identifier is a full-length random identifier rather than a truncated prefix

#### Scenario: Existing short identifiers remain valid

- **WHEN** an order stored with a previously generated short identifier is read, edited, and saved
- **THEN** it behaves exactly as before and its identifier is not rewritten

### Requirement: Writes declare create or update intent, and create never overwrites

The persistence layer SHALL distinguish a create intent from an update intent. A create intent that encounters an existing row with the same identifier SHALL fail and SHALL NOT modify the existing row. Only an update intent SHALL replace an existing row. Silent overwrite on identifier collision SHALL NOT be possible.

#### Scenario: Create intent refuses to overwrite

- **WHEN** a create intent is issued for an order whose identifier already exists
- **THEN** the operation fails with a distinguishable error and every field of the existing row is unchanged

#### Scenario: Update intent still replaces

- **WHEN** an update intent is issued for an existing order
- **THEN** the existing row is replaced with the supplied values

#### Scenario: Create intent inserts when there is no collision

- **WHEN** a create intent is issued for an order whose identifier is not present
- **THEN** the order is inserted

### Requirement: Concurrent writes to the same entity are serialized through one context

Because the data tables deliberately carry no uniqueness constraint, two concurrent writes must not each observe an empty result and each insert a row. All writes for a given entity SHALL be serialized through a single long-lived persistence instance and its data context, rather than each operation constructing its own.

#### Scenario: Concurrent same-identifier writes yield one row

- **WHEN** two writes carrying the same identifier are issued concurrently
- **THEN** exactly one row exists afterwards and the later write resolves through the create-collision path rather than inserting a duplicate

#### Scenario: Persistence instance is reused

- **WHEN** the order persistence is obtained more than once
- **THEN** the same instance is returned

### Requirement: Field mapping is protected by whole-value round-trip coverage

The tests that cover writing and reading an order SHALL assert equality of the entire domain value, not a subset of fields. The fixture used SHALL have every field set to a non-default value, so that a mapping that omits a field cannot pass by coincidence.

#### Scenario: Whole-value equality is asserted

- **WHEN** an order whose every field holds a non-default value is written and read back
- **THEN** the read value equals the written value in its entirety

#### Scenario: A dropped field fails the test

- **WHEN** the mapping is modified to omit any single field
- **THEN** the round-trip test fails
