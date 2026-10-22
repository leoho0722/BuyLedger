## ADDED Requirements

### Requirement: Helpers cannot silently absorb a missing element

Waiting, tapping, menu and text entry helpers SHALL NOT allow a caller to ignore a failed wait and continue interacting. When the element does not become available within the timeout, the helper SHALL fail the test with a screenshot and the accessibility hierarchy attached, or SHALL return a result that the compiler requires the caller to handle. Value queries SHALL distinguish an element that cannot be found from an element whose value is empty.

#### Scenario: A tap on a missing element fails at the interaction

- **GIVEN** a page object operation that taps an element through the support layer
- **WHEN** the element does not become hittable within the timeout
- **THEN** the test fails at that operation with the element identifier in the message and diagnostics attached

#### Scenario: A missing value element is distinguishable from an empty value

- **GIVEN** a page object query that reads an element's accessibility value
- **WHEN** the element does not exist within the timeout
- **THEN** the query reports the element as absent, and the caller can report it differently from an empty value

#### Scenario: Text entry into a missing field fails

- **GIVEN** a text entry helper targeting a field
- **WHEN** the field does not exist within the timeout
- **THEN** the test fails with diagnostics attached instead of returning without typing

### Requirement: Retyping a field leaves exactly the requested content

Text and amount entry helpers SHALL leave the target field containing exactly the requested text, whatever the field contained before the helper ran.

#### Scenario: Entering an amount replaces any prior content

- **GIVEN** a numeric field that already contains a value
- **WHEN** a test enters an amount through the support layer
- **THEN** the field contains exactly the entered amount

##### Example: prior field contents

| Prior content | Entered amount | Resulting content |
| ------------- | -------------- | ----------------- |
| (empty) | 1000 | 1000 |
| 500 | 1000 | 1000 |
| 1000 | 1000 | 1000 |

### Requirement: UI assertions observe the outcome under test

A UI test assertion SHALL observe the specific outcome the test names rather than a condition that holds regardless of that outcome. A presence or non-empty check SHALL NOT stand in for a result that the app renders with a placeholder when absent. A confirmation check SHALL identify the specific confirmation rather than any alert. A disappearance assertion SHALL first establish that the target was present. A test's preconditions SHALL be able to trigger the behaviour it verifies.

#### Scenario: A placeholder does not satisfy a result assertion

- **GIVEN** a screen that renders a placeholder when a computed result is unavailable
- **WHEN** a test asserts that the result was computed
- **THEN** the assertion compares against the expected value for the test data, and the placeholder fails it

##### Example: converted and suggested amounts

| Screen state | Rendered value | Satisfies the result assertion |
| ------------ | -------------- | ------------------------------ |
| No usable rate | — | no |
| Rate available, amount not entered | NT$0 | no |
| Rate available, amount entered | the amount computed from the seeded rate | yes |

#### Scenario: A disappearance is asserted only after presence

- **GIVEN** a test that expects a list row to be filtered out
- **WHEN** the test applies the filter
- **THEN** it has first asserted that the row was present before the filter was applied

#### Scenario: A confirmation is identified by its own control

- **GIVEN** a flow that presents a settle or delete confirmation
- **WHEN** the test asserts that the confirmation appeared
- **THEN** it identifies the confirmation by that confirmation's own button rather than by the presence of any alert

#### Scenario: A precondition triggers the dependency under test

- **GIVEN** a self-check that verifies a stubbed dependency or injected launch value
- **WHEN** the test sets up its precondition
- **THEN** the flow reaches the code that consumes the dependency or value, and the injected value differs from the app's default
