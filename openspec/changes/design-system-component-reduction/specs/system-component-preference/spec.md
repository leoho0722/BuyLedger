## ADDED Requirements

### Requirement: System-provided capabilities are not reimplemented

An interface component SHALL NOT reimplement a capability that a system component already provides, unless the system component demonstrably cannot meet a stated requirement. Where a hand-built component exists for a capability the system provides, it SHALL be replaced by the system component and its source removed, so that it cannot be adopted again by a later implementer.

#### Scenario: Hand-built search field is replaced by the system presentation

- **WHEN** a screen presents a search entry point
- **THEN** it uses the system search presentation, and the hand-built search field type no longer exists in the codebase

#### Scenario: Hand-built segmented control is removed

- **WHEN** the codebase is searched for the hand-built segmented control type
- **THEN** no definition and no call site remain, and screens offering mutually exclusive view switching use the system segmented picker

#### Scenario: Hand-built progress bar is replaced by the system progress view

- **WHEN** a screen displays determinate progress
- **THEN** it uses the system progress view, and the progress value is exposed to assistive technology

### Requirement: Replaced components restore the behaviors their hand-built versions lacked

Replacing a hand-built component with its system counterpart SHALL restore the behaviors that the hand-built version did not provide. The replacement SHALL NOT be considered complete while any of those behaviors remains absent.

#### Scenario: Search presentation restores its full behavior set

- **WHEN** the user interacts with a search entry point
- **THEN** a cancel affordance is available, the return key reads as a search action, dictation is available, and the search field collapses and expands with scrolling

#### Scenario: Progress view announces its value

- **WHEN** assistive technology focuses a progress indicator
- **THEN** the announcement includes the current progress value rather than only the surrounding text

#### Scenario: Settings rows restore press feedback

- **WHEN** the user presses a tappable row in settings
- **THEN** the row shows the standard press highlight and displays the system disclosure indicator

### Requirement: Search state remains consistent when search is cancelled

When the search presentation is cancelled, the screen's filter state SHALL be reset so that the full result set is shown. The screen SHALL NOT remain filtered by a query that is no longer visible to the user.

#### Scenario: Cancelling search clears the filter

- **WHEN** the user has entered a query, results are filtered, and the user then cancels the search
- **THEN** the query is cleared and the unfiltered result set is shown

### Requirement: Deliberately retained hand-built structures provide the behaviors they forgo

Where a hand-built structure is deliberately retained instead of adopting its system counterpart, it SHALL provide the essential behaviors that the system counterpart would have supplied, except those explicitly recorded as accepted losses. A long scrollable collection SHALL build its rows lazily, so that presentation cost does not grow linearly with the number of items.

#### Scenario: Order sections are built lazily

- **WHEN** the order list renders a data set containing many date sections
- **THEN** sections outside the visible region are not built until they approach the viewport

#### Scenario: Card backgrounds remain intact

- **WHEN** a date section renders its card containing that day's order rows
- **THEN** the card's corner radius, border, and background enclose all of its rows completely, because the rows within a single card are not built lazily

#### Scenario: Accepted losses remain out of scope

- **WHEN** the order list is reviewed against the behaviors a system list would provide
- **THEN** swipe actions and automatic separator alignment remain absent by decision, and their absence is not treated as a defect of this change

