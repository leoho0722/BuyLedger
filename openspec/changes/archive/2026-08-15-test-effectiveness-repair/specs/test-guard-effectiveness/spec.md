## ADDED Requirements

### Requirement: Exhaustive state checking is the default and exceptions are justified in place

Reducer tests SHALL assert the complete resulting state by default, so that an unintended mutation of any field fails the test. Relaxing the check SHALL be an exception, permitted only where a concurrent effect makes the full state unpredictable, and each relaxation SHALL carry an adjacent comment naming the concurrent effect that requires it.

The number of relaxations SHALL be bounded by a guard that fails when it increases, so that the count can fall over time but cannot silently grow.

#### Scenario: An unintended mutation fails the test

- **WHEN** a reducer changes a field that a test does not assert, and the test does not relax exhaustive checking
- **THEN** the test fails

#### Scenario: A relaxation names its reason

- **WHEN** a test relaxes exhaustive checking
- **THEN** an adjacent comment names the concurrent effect that makes the full state unpredictable

#### Scenario: The relaxation count cannot grow

- **WHEN** a change adds a relaxation beyond the recorded bound
- **THEN** the guard fails

### Requirement: A measurement test without a comparison baseline is not a guard

A test that measures performance SHALL have a recorded baseline to compare against. Without a baseline the measurement cannot fail and therefore guards nothing. Measurement tests SHALL NOT run in the main regression suite, because their timing is sensitive to machine load in a way that functional tests are not.

#### Scenario: A regression against the baseline fails

- **WHEN** a measured operation becomes materially slower than its recorded baseline
- **THEN** the measurement test fails

#### Scenario: Measurement tests stay out of the main suite

- **WHEN** the main regression suite runs
- **THEN** no measurement test is executed

### Requirement: A guard whose subject no longer exists is repaired, not left passing

A test SHALL NOT continue to pass by virtue of the mechanism it guards having been removed. When the implementation a test was written against is deleted, the test SHALL either be rewritten to assert the replacement behaviour or removed together with the mechanism. Documentation attached to a test SHALL NOT describe an implementation that no longer exists.

#### Scenario: A removed mechanism does not leave a vacuously passing test

- **WHEN** the implementation a test was written against is removed
- **THEN** the test is rewritten against the replacement behaviour or removed, rather than left asserting a condition that can no longer fail

#### Scenario: Test documentation matches the current implementation

- **WHEN** a test's documentation is read
- **THEN** it describes a mechanism that exists in the codebase

### Requirement: Guards that must be complete are scan based, not list based

A guard whose purpose is to prove the absence of a class of defect SHALL derive its subjects by scanning, not from a hand maintained list. A list only protects the entries someone remembered to add, which is precisely the failure mode such a guard exists to detect.

This applies to the localization guard, which SHALL detect strings used in code but absent from the catalog, and to the contrast guard, whose subjects SHALL include colour combinations composed directly in views rather than only those defined as named colour resources.

#### Scenario: A string used in code but missing from the catalog is detected

- **WHEN** a user-facing string literal exists in code with no corresponding catalog entry
- **THEN** the localization guard fails and names the string

#### Scenario: A gradient composed from system colours is in scope

- **WHEN** a view composes a gradient directly from system colours and places text on it
- **THEN** the contrast guard evaluates that combination against the same floor as one defined by named colour resources

#### Scenario: Enumerated guards remain acceptable where completeness is not the claim

- **WHEN** a guard asserts a specific documented behaviour rather than the absence of a class of defect
- **THEN** enumerating its subjects remains acceptable
