## ADDED Requirements

### Requirement: Shared test case base

Every UI test SHALL derive from a shared base case that owns the application instance, applies the common setup, and attaches diagnostics on failure. The base SHALL stop a test at its first failure, SHALL fix the device orientation before each test, and SHALL expose a single launch entry point that takes the launch options value.

#### Scenario: Common setup is not repeated per test

- **WHEN** a new UI test is added
- **THEN** it declares only its launch options and its flow, and inherits orientation, failure policy, and diagnostics from the base

#### Scenario: Diagnostics are attached on failure

- **WHEN** a UI test fails
- **THEN** a screenshot and the accessibility tree of the failing screen are attached to the test result

### Requirement: Launch options describe preconditions declaratively

A launch options value type SHALL describe one launch's preconditions: seed profile, reference time, app language, calendar authorisation outcome, load failure mode, and initial settings values. It SHALL serialise itself into the launch arguments the app harness parses. Tests SHALL NOT assemble launch argument strings themselves.

#### Scenario: Test declares preconditions in one place

- **WHEN** a test needs a populated store and the English language
- **THEN** it passes a launch options value declaring both, and the base case launches the app accordingly

#### Scenario: Defaults are explicit

- **WHEN** a test passes the default launch options
- **THEN** the app launches in UI test mode with the empty seed profile, the default reference time, and the default language

### Requirement: Layout-agnostic navigation

A navigation helper SHALL absorb the difference between the compact tab-bar layout and the regular sidebar layout. It SHALL determine the active layout at runtime and SHALL expose semantic navigation operations that work in both. Tests and page objects SHALL navigate through this helper rather than querying tab bars or sidebars directly.

#### Scenario: Same test runs on both layouts

- **WHEN** a test asks the navigator to switch to the orders section
- **THEN** the navigator taps the tab bar item on a compact layout and the sidebar row on a regular layout, and the orders screen becomes ready in both cases

#### Scenario: Layout detection needs no test input

- **WHEN** the same test binary runs on an iPhone simulator and on an iPad simulator
- **THEN** the navigator selects the correct control in each case without the test declaring the device kind

### Requirement: Reusable interaction helpers

The support layer SHALL provide reusable functions for the interactions that recur across screens: condition-based waiting, scrolling an off-screen element into a hittable position, clearing and retyping field contents, dismissing the numeric keyboard, opening menus and selecting their items, dismissing sheets including the unsaved-changes path, activating alert buttons, parsing locale-formatted values, and shared assertions. UI tests and page objects SHALL call these functions rather than reimplementing the behaviour.

#### Scenario: Waiting is condition-based

- **WHEN** a test waits for a screen to become ready
- **THEN** it polls the readiness condition until a timeout instead of sleeping for a fixed duration

#### Scenario: Off-screen element is scrolled into reach

- **WHEN** a test targets a control that is below the visible area of a scrollable form
- **THEN** the scrolling helper brings it into a hittable position before the interaction, and fails with diagnostics if it cannot

#### Scenario: Numeric keyboard is dismissed through the toolbar

- **WHEN** a test finishes typing into a field that presents a keyboard without a return key
- **THEN** it dismisses the keyboard through the keyboard toolbar's done control

#### Scenario: Dirty sheet dismissal is handled once

- **WHEN** a test cancels an edit sheet that has unsaved changes
- **THEN** the sheet helper handles the discard confirmation and returns only after the sheet is gone

#### Scenario: Formatted values are compared without hardcoded strings

- **WHEN** a test asserts on a displayed amount
- **THEN** it compares against a value formatted for the run's locale rather than against a hardcoded string

### Requirement: Page object contract

Every screen exercised by UI tests SHALL be represented by a page object conforming to a shared contract. The contract SHALL require a root identifier used to decide readiness and SHALL provide readiness waiting and diagnostics. Page objects SHALL expose semantic operations and assertions and SHALL NOT leak element queries to test files.

#### Scenario: Screen readiness is uniform

- **WHEN** a test navigates to any screen represented by a page object
- **THEN** readiness is decided by that screen's root identifier through the shared contract

#### Scenario: Tests read as flows

- **WHEN** a test exercises a multi-step flow
- **THEN** each step is a semantic call on a page object, and no element query appears in the test file

### Requirement: Failures are never masked

UI tests SHALL fail when an element belonging to the app under test cannot be found. Skipping SHALL be reserved for genuine external environment differences, and every skip SHALL state the external cause.

#### Scenario: Missing app element fails the test

- **WHEN** a control that the app is expected to present cannot be found
- **THEN** the test fails with diagnostics attached rather than being skipped

#### Scenario: External difference may skip with a stated reason

- **WHEN** a test depends on out-of-process system UI that the environment does not provide
- **THEN** it skips with a message naming the external cause

### Requirement: Test plan separation

The UI test target SHALL be driven by a main regression test plan and a separate plan for performance and template tests. The main plan SHALL pin the application language and region, SHALL disable randomised execution order, and SHALL exclude the performance and template tests.

#### Scenario: Regression plan is deterministic

- **WHEN** the main regression plan runs twice in a row
- **THEN** the executed tests and their order are identical in both runs

#### Scenario: Performance tests do not slow the regression loop

- **WHEN** the main regression plan runs
- **THEN** the launch performance measurement is not executed
