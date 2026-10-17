## ADDED Requirements

### Requirement: A test fails when the behaviour it names is broken

A test SHALL be able to fail when the behaviour named by its name or documentation is broken. Its assertions SHALL cover that behaviour, its inputs SHALL be chosen so that the intended implementation and a plausible incorrect implementation produce different asserted values, and any state it reads back as evidence of persistence SHALL come from the storage the operation targeted rather than being supplied by the test itself. A test that cannot meet this SHALL be renamed to the behaviour it actually asserts or removed.

#### Scenario: Breaking the named behaviour turns the test red

- **GIVEN** a test whose name or documentation names a behaviour
- **WHEN** the product logic implementing that behaviour is deliberately broken
- **THEN** the test fails

#### Scenario: Inputs distinguish the intended implementation from an incorrect one

- **GIVEN** a test fixture and a plausible incorrect implementation of the behaviour under test
- **WHEN** the fixture is evaluated by both the intended and the incorrect implementation
- **THEN** the two produce different values for at least one assertion in the test

##### Example: merging the injected seconds into a picked date

| Injected now (seconds) | Picked date (seconds) | Intended result (seconds) | Incorrect result that ignores now (seconds) | Distinguishes |
| ---------------------- | --------------------- | ------------------------- | ------------------------------------------- | ------------- |
| 0 | 0 | 0 | 0 | no |
| 42 | 0 | 42 | 0 | yes |

#### Scenario: Reloaded state comes from the storage under test

- **GIVEN** a test that claims a failed write leaves stored data unchanged
- **WHEN** the test reloads the data to check it
- **THEN** the reloaded data is read from the repository or container the write targeted, and is not re-sent by the test

#### Scenario: Claimed side effects and payloads are asserted

- **GIVEN** a test whose name claims a dismissal, a file move, or a delegate payload
- **WHEN** the test runs
- **THEN** it records that the side effect was invoked or compares the payload against the expected value

#### Scenario: A self-referential expectation is not a guard

- **GIVEN** an assertion that compares a value built from literals with an equal value built from the same literals, without calling product code
- **WHEN** the test is reviewed
- **THEN** it is rewritten to exercise the product code path it names, or removed
