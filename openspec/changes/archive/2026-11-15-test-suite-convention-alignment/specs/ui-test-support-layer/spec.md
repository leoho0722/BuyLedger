## MODIFIED Requirements

### Requirement: Reusable interaction helpers

The support layer SHALL provide reusable functions for the interactions that recur across screens: condition-based waiting, scrolling an off-screen element into a hittable position (vertically and horizontally), clearing and retyping field contents, dismissing the numeric keyboard, opening menus and selecting their items, dismissing sheets including the unsaved-changes path, activating alert buttons, returning from a pushed destination, and shared assertions. A behaviour that needs more than one strategy (for example a gentle drag for an element that is almost visible and a stepwise swipe for a lazily created row) SHALL implement each strategy exactly once in the support layer. UI tests and page objects SHALL call these functions rather than reimplementing them. A support function that has no caller anywhere in the UI test target SHALL be removed.

#### Scenario: Waiting is condition-based

- **WHEN** a test waits for a screen to become ready
- **THEN** it waits through the system waiting API or the shared polling function until a timeout, instead of sleeping for a fixed duration or writing its own deadline loop

#### Scenario: Off-screen element is scrolled into reach

- **WHEN** a test targets a control that is below the visible area of a scrollable form, or beyond the visible width of a horizontal scroll container
- **THEN** the scrolling helper brings it into a hittable position before the interaction, and fails with diagnostics if it cannot

##### Example: date chip outside the visible width

- **GIVEN** the regular orders list at the largest accessibility text size, where the "this month" date chip lies beyond the visible width of the chip row
- **WHEN** a test selects that date chip
- **THEN** the chip row is scrolled horizontally until the chip is hittable, and the chip is selected

#### Scenario: Numeric keyboard is dismissed through the toolbar

- **WHEN** a test finishes typing into a field that presents a keyboard without a return key
- **THEN** it dismisses the keyboard through the keyboard toolbar's done control

#### Scenario: Dirty sheet dismissal is handled once

- **WHEN** a test cancels an edit sheet that has unsaved changes
- **THEN** the sheet helper handles the discard confirmation and returns only after the sheet is gone

#### Scenario: Expected text is written for the locked plan language

- **GIVEN** a UI test plan that locks the app language and region
- **WHEN** a test asserts on displayed text or a displayed amount
- **THEN** it compares against a literal expected value written in that language and region, and does not derive the expected value from production formatting code

#### Scenario: Returning from a pushed destination uses the shared helper

- **GIVEN** a pushed destination inside a split view on iPad
- **WHEN** a page object returns to the previous screen
- **THEN** it activates the back button through one of the two shared strategies: the single hittable system back button, or the back button of the navigation bar that contains an element identified by the app

### Requirement: Page object contract

A screen exercised by more than one UI test type, or by a multi-step flow, SHALL be represented by a page object conforming to a shared contract. The contract SHALL require a root identifier used to decide readiness and SHALL provide readiness waiting and diagnostics. A screen reachable from root navigation SHALL expose a static entry point that navigates to it and returns its page object only after the destination is in the foreground, showing its content, its empty state, its load failure, or a destination already pushed onto it; a test that needs the content then waits for the screen's root identifier. A screen that another screen presents or pushes SHALL be returned by the presenting page object's action, and that action SHALL return only after the new screen is ready. Both SHALL fail with diagnostics when the screen does not become ready. A test SHALL NOT reimplement navigation that a page object entry point or presenting action provides; a private helper of a single test type that only chains page object calls to set up its Given step is permitted. A test whose subject is not root navigation itself SHALL enter a root destination only through that destination's entry point. A page object SHALL NOT host helpers that other page objects or unrelated screens depend on; such helpers SHALL live in the support layer. Page objects SHALL expose semantic operations and assertions; a test SHALL query app elements directly by identifier only on a screen that has no page object. Checking whether a system container (alert, keyboard, window, tab bar, status bar, navigation bar) is present and reading its frame are not element queries of a screen; passing an identifier or identifier prefix to a shared support assertion is not a direct query either.

#### Scenario: Screen readiness is uniform

- **WHEN** a test navigates to any screen represented by a page object
- **THEN** readiness is decided by that screen's root identifier through the shared contract

#### Scenario: Tests read as flows

- **WHEN** a test exercises a multi-step flow
- **THEN** each step is a semantic call on a page object or a shared support function, and no element query of a screen that has a page object appears in the test file

#### Scenario: Entering a root destination has one shape

- **GIVEN** two test types in different folders that both start from the orders list
- **WHEN** each test opens the orders list
- **THEN** both call the orders page object's static entry point, which switches to the orders tab, waits until the orders destination shows its list, its empty state or its load failure, and returns the orders page object

#### Scenario: A presented screen is returned when ready

- **GIVEN** the orders list page object
- **WHEN** a test taps the add-order action on it
- **THEN** the action returns the order editor page object after the editor's root identifier is ready, or fails with diagnostics

#### Scenario: A Given step chains page object calls in a private helper

- **GIVEN** a test type whose tests all start from a saved order that has no card
- **WHEN** the test type sets up that order
- **THEN** a private helper of that type calls the page object entry point and its actions in sequence, and does not reimplement the tab switch or the readiness wait that the entry point provides

### Requirement: Failures are never masked

UI tests SHALL fail when an element belonging to the app under test cannot be found. Skipping SHALL be reserved for genuine external environment differences and for layout-scoped tests, and every skip SHALL state its cause. A shared assertion helper SHALL attach the screenshot and the accessibility hierarchy when its comparison fails, not only when its element is missing. A single failure SHALL be recorded once: a caller SHALL NOT report again a failure that the helper it called has already reported.

#### Scenario: Missing app element fails the test

- **WHEN** a control that the app is expected to present cannot be found
- **THEN** the test fails with diagnostics attached rather than being skipped

#### Scenario: External difference may skip with a stated reason

- **WHEN** a test depends on out-of-process system UI that the environment does not provide
- **THEN** it skips with a message naming the external cause

#### Scenario: A mismatched alert message carries diagnostics

- **GIVEN** an alert that is presented with a message different from the expected text
- **WHEN** a test asserts the alert message through the shared alert assertion
- **THEN** the test fails with the expected text in the message and the screenshot and accessibility hierarchy attached

#### Scenario: A failed navigation is recorded once

- **GIVEN** a page object entry point that fails with diagnostics when the destination does not become ready
- **WHEN** the destination does not become ready
- **THEN** the test result records exactly one failure for that navigation, located at the line of the test that called the entry point

### Requirement: Helpers cannot silently absorb a missing element

Support layer and page object functions that can fail the test SHALL NOT allow a caller to ignore the failure and continue. Every such function, including actions, navigation entry points, assertion helpers and layout determinations, SHALL, when its element or condition is not available within the timeout, record the failure with a screenshot and the accessibility hierarchy attached and throw, so that the calling test stops at that call; it SHALL NOT report its outcome through a `Bool` return value. Within the support layer and page objects, a failure SHALL be recorded only through the throwing stop function; the non-throwing diagnostics recorder SHALL be called only by the stop function itself and by test types, and by test types only to report an outcome in a Then step; assertions of a folder's test support type follow the support layer rule, while a Given or When step SHALL establish its preconditions through the throwing requirement helpers. The thrown error is a stop signal: neither a test nor a helper SHALL catch it to continue, except inside an expected-failure block, and a helper with a fallback path SHALL try the alternatives through waits and queries that do not fail, failing only after the last alternative. A layout determination SHALL return the determined layout as a value and fail when the layout cannot be determined; the calling test compares the value and declares its skip. A function that only answers a question SHALL be named as an assertion of fact (`is`, `has`, or a verb such as `contains`) and SHALL NOT perform actions. A waiting function that mirrors the system waiting API is permitted to return `Bool`, and that result SHALL NOT be discardable. A property SHALL NOT wait or fail; such work SHALL be a method. Value queries SHALL distinguish an element that cannot be found from an element whose value is empty.

#### Scenario: A tap on a missing element fails at the interaction

- **GIVEN** a page object operation that taps an element through the support layer
- **WHEN** the element does not become hittable within the timeout
- **THEN** the test fails at that operation with the element identifier in the message and diagnostics attached, and the operation throws so the test does not continue

#### Scenario: A missing value element is distinguishable from an empty value

- **GIVEN** a page object query that reads an element's accessibility value
- **WHEN** the element does not exist within the timeout
- **THEN** the query reports the element as absent, and the caller can report it differently from an empty value

#### Scenario: Text entry into a missing field fails

- **GIVEN** a text entry helper targeting a field
- **WHEN** the field does not exist within the timeout
- **THEN** the test fails with diagnostics attached instead of returning without typing

#### Scenario: A waiting result cannot be dropped

- **GIVEN** a waiting helper that returns whether a condition became true before its timeout
- **WHEN** a caller invokes it without using the result
- **THEN** the compiler reports the unused result

#### Scenario: An undeterminable layout fails instead of answering false

- **GIVEN** a layout determination for the orders tab
- **WHEN** neither the regular nor the compact arrangement can be recognised within the timeout
- **THEN** the determination fails with diagnostics and throws, rather than returning a value the test would read as the other layout

#### Scenario: An expected failure is caught inside the expectation

- **GIVEN** a test that expects a navigation helper to fail while the app is locked
- **WHEN** the test allows execution to continue after a failure only for the expected-failure block, and the helper records its failure and throws inside that block
- **THEN** the test catches the thrown error inside the block, the recorded failure satisfies the expectation, stopping after a failure is restored, and the test continues to its Then step

#### Scenario: A fallback does not record the failed first attempt

- **GIVEN** a menu item helper that first looks the item up by identifier and falls back to its visible label
- **WHEN** the item has no identifier but its label is present
- **THEN** the helper selects the item through the label without recording any failure, because the identifier lookup used a wait that does not fail

#### Scenario: An unmet precondition in a Given step stops the test

- **GIVEN** a test whose Given step requires the orders list to show a seeded order
- **WHEN** the order is missing
- **THEN** the Given step fails through the throwing requirement helper with diagnostics attached, and the When step does not run

#### Scenario: Entering a destination with no data does not wait for content

- **GIVEN** the campaigns destination seeded with no campaigns, which shows its empty state and no campaign list
- **WHEN** a test enters it through the campaigns page object's entry point
- **THEN** the entry point returns once the empty state is in the foreground, without waiting for the campaign list root identifier
