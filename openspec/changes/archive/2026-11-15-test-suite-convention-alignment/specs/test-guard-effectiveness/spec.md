## ADDED Requirements

### Requirement: Feature reducer tests run through TestStore

A unit test that drives a TCA feature reducer SHALL drive it through `TestStore`, so that every state change and every received action is checked. A test of a binding SHALL send the binding action that the view actually sends: a top-level field or a writable computed property sends its own key path, and a nested field sends the whole enclosing value. Creating a `Store` SHALL be limited to snapshot tests, whose views accept only a `Store`. A source scan SHALL fail when a `Store` is created outside the snapshot test directory in a form the scan recognises (`Store(`, `Store<…>(`, `StoreOf<…>(`), SHALL report the original file and line of each finding, and SHALL fail when it reads no source files; other construction forms are reviewed by hand.

#### Scenario: A nested binding sends the whole draft

- **GIVEN** the order editor test that changes the customer name
- **WHEN** the test drives the binding the editor view uses for the customer name
- **THEN** it sends the binding action for the whole draft with the changed name, and asserts the resulting state

#### Scenario: A Store outside snapshot tests is rejected by the scan

- **WHEN** a unit test outside the snapshot test directory contains `_ = Store(initialState: SettingsFeature.State()) { SettingsFeature() }`
- **THEN** the source scan fails and names that file and the line of the statement as it appears in the source file

#### Scenario: Snapshot tests keep their Store

- **WHEN** a snapshot test creates a `Store` for the view it renders
- **THEN** the source scan does not report it

#### Scenario: An empty scan does not pass

- **WHEN** the unit test directory resolves to no readable source files
- **THEN** the scan fails instead of passing with zero findings

### Requirement: UI test conventions that must hold everywhere are scan guarded

The UI test target's file naming and helper result conventions SHALL be enforced by source scans in the unit test target rather than by a one-time search. A scan SHALL fail when a file under the UI test directory for test types is named other than `<Name>UITests.swift` or `<Name>TestSupport.swift`, except the files the scan lists by name with the reason for each. A scan SHALL fail when any function in the UI test target is marked `@discardableResult` and returns `Bool`, matching the whole declaration up to its opening brace because signatures span several lines. A scan SHALL fail when code under the support and page object directories or in a folder's test support file, other than the two diagnostics files, calls the non-throwing diagnostics recorder, `XCTFail` or an `XCTAssert` function. Each scan SHALL report the file and line of every finding and SHALL fail when it reads no source files, and SHALL NOT match its own patterns.

#### Scenario: A test file with the old suffix is rejected

- **WHEN** a file named `OrderFilterSheetTests.swift` is added under the UI test directory for test types
- **THEN** the naming scan fails and names that file

#### Scenario: The listed exceptions keep their names

- **WHEN** the scan reads the launch performance test file and the pure value self-check file that the scan lists by name
- **THEN** it does not report them

#### Scenario: A discardable Bool helper is rejected

- **WHEN** a support helper declares `@discardableResult` followed by a function whose parameters span several lines and that returns `Bool`
- **THEN** the helper result scan fails and names the file and line of the declaration

#### Scenario: A page object that records a failure without throwing is rejected

- **WHEN** a page object method calls the non-throwing diagnostics recorder instead of the throwing stop function
- **THEN** the diagnostics scan fails and names the file and line of the call
