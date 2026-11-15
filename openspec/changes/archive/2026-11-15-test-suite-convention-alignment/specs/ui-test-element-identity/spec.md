## MODIFIED Requirements

### Requirement: Accessibility identifier is the sole locator for UI tests

UI tests SHALL locate app content exclusively by accessibility identifier. UI tests SHALL NOT locate app content or system controls by displayed text, by accessibility label, or by positional index within a query result. Checking whether a system container (alert, keyboard, window, tab bar, status bar, navigation bar) is present and reading its frame do not locate app content and are permitted in test files; reading a navigation bar's title still goes through the shared helper. Every element that a UI test interacts with or asserts on SHALL carry an accessibility identifier, and a control that the app itself can tag, including a button inside a custom alert, SHALL be tagged and located by its identifier. Locating an element and comparing its content are separate: once an element is located by identifier, a test SHALL compare its content against a literal written for the plan's locked language. Where the app exposes the state under test as the accessibility value of a row whose children are combined into one accessibility element, the test SHALL read that value rather than search the row's label for a substring.

Where no identifier can be attached, a lookup by text, label or position is permitted only as one of the following controlled exceptions, and each exception SHALL live in a single shared helper of the support layer or a page object rather than in test files:

- An interacting lookup of system or framework UI that carries no identifier, such as root tab buttons that expose none of the root tab identifiers, segmented control options, options of an inline picker inside a menu, alert buttons built by the reducer's alert state, a text field inside a custom alert, the search field and its built-in clear button, the search field's system end button, system keyboard keys and candidates, and the sheet grabber. When the lookup is positional, the ordering it relies on SHALL be fixed by an enumeration in application code. The helper SHALL confirm the outcome by waiting for an identifier that only the intended result exposes, by the disappearance of the system control it activated, or by reading back the state the action changed through an element located by identifier (its value or frame).
- A read-only lookup that does not interact, such as the title of a navigation bar, the message text of an alert built by the reducer's alert state, whether a system keyboard key or an interactive search field is present, and sampling elements by position to measure frames. The helper SHALL NOT tap or type through such a lookup.
- A row whose identifier is keyed by a value generated at run time, located by the identifier prefix together with user-entered text the row displays, because user-entered text does not change with the app language.

#### Scenario: Locating by identifier survives a language switch

- **WHEN** the same UI test runs with the app language set to Traditional Chinese and again with the app language set to English
- **THEN** every lookup by identifier resolves in both runs; lookups made through a controlled exception are not covered by this scenario

#### Scenario: Positional lookups are rejected

- **WHEN** a UI test needs a specific text field among several on one screen
- **THEN** it resolves that field by its own identifier rather than by its position in the text field query

#### Scenario: Tab bar items have no attachable identifier

- **WHEN** the shared navigation helper switches to a tab on a layout where the platform's tab bar buttons expose none of the root tab identifiers
- **THEN** it selects the button by the position declared in the tab enumeration and then waits for that tab's destination root identifier, so a change in tab order fails the test instead of silently selecting the wrong tab

#### Scenario: The currency of a new order is read from the row's value

- **GIVEN** a new order whose default currency is Japanese yen
- **WHEN** a test checks the currency row of the order editor
- **THEN** the row located by its identifier exposes the ISO currency code `JPY` as its accessibility value, and the test compares that value

#### Scenario: A payment method category is read from the row's value

- **GIVEN** a payment method row in the lookup management list whose cash on delivery category was just enabled
- **WHEN** a test checks that the category badge is shown
- **THEN** the row located by its identifier exposes the enabled category names as its accessibility value, and the test compares the whole value instead of searching the row label for the badge text

#### Scenario: The order shown in the detail is read from the detail root

- **WHEN** a test checks which order the order detail shows
- **THEN** it reads the order identifier that the detail root exposes as its accessibility value, rather than searching the detail's texts for the order number

#### Scenario: A custom alert button is located by its identifier

- **GIVEN** the discard confirmation that the lookup name editor presents through a custom alert
- **WHEN** a test chooses to keep editing or to discard the changes
- **THEN** it activates the button by the identifier the app attached to it, not by its title

#### Scenario: A navigation bar title is read through a shared helper

- **WHEN** a test checks that the regular orders list column shows its fixed title, or that a navigation bar shows a dynamic title such as the selection count
- **THEN** it reads the title through a shared helper that looks up the navigation bar title without interacting with it, and no navigation bar title lookup appears in the test file

#### Scenario: A system container check stays in the test

- **WHEN** a test checks that the keyboard is shown, that an alert is presented, or measures the window frame
- **THEN** it queries the system container directly or through an existing support helper, and this does not count as locating app content
