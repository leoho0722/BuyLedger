## ADDED Requirements

### Requirement: Accessibility identifier is the sole locator for UI tests

UI tests SHALL locate elements exclusively by accessibility identifier. UI tests SHALL NOT locate elements by displayed text, by accessibility label, or by positional index within a query result. Every element that a UI test interacts with or asserts on SHALL carry an accessibility identifier.

Where the platform provides no way to attach an identifier to a control, a positional lookup is permitted only under all of the following conditions: the lookup lives in a single shared helper rather than in test files, the ordering it relies on is fixed by an enumeration in application code, and the helper confirms the outcome by waiting for an identifier that only the intended result exposes.

#### Scenario: Locating by identifier survives a language switch

- **WHEN** the same UI test runs with the app language set to Traditional Chinese and again with the app language set to English
- **THEN** every element lookup resolves in both runs and the test passes in both runs

#### Scenario: Positional lookups are rejected

- **WHEN** a UI test needs a specific text field among several on one screen
- **THEN** it resolves that field by its own identifier rather than by its position in the text field query

#### Scenario: Tab bar items have no attachable identifier

- **WHEN** the shared navigation helper switches to a tab on the compact layout, where the platform's tab bar buttons expose no identifier
- **THEN** it selects the button by the position declared in the tab enumeration and then waits for that tab's destination root identifier, so a change in tab order fails the test instead of silently selecting the wrong tab

### Requirement: Identifier naming scheme

Identifiers SHALL follow the format `feature.screen.element` with an optional fourth qualifier segment, SHALL use only ASCII characters, and SHALL NOT be localised. The feature segment SHALL come from the fixed feature vocabulary. The element segment SHALL name the semantic role rather than the visual appearance. Identifiers SHALL NOT encode transient state that a test can read from the element itself, such as enabled or selected.

#### Scenario: Static control identifier

- **WHEN** the orders list exposes its add-order control
- **THEN** its identifier is composed of the orders feature segment, the list screen segment, and an element segment naming the add action

#### Scenario: Disabled state is read from the element

- **WHEN** a UI test asserts that the save control is unavailable
- **THEN** it reads the element's enabled state rather than looking up a different identifier

### Requirement: Identifiers for dynamic collections

Rows and cells produced from collections SHALL carry identifiers built from a stable key rather than from displayed text or from an unstable position. Enumeration-backed collections SHALL use the case's raw value. Rows backed by user data SHALL append the business key to a fixed prefix, separated by a colon, with the business key kept in its original unlocalised form. Purely ordinal collections SHALL append the zero-based position to a fixed prefix.

#### Scenario: Enumeration-backed chip

- **WHEN** the orders list renders the status filter chip for the shipping status
- **THEN** the chip's identifier ends with the shipping case's raw value

##### Example: identifier shapes by collection kind

| Collection kind | Element | Identifier shape |
| --------------- | ------- | ---------------- |
| Enumeration-backed | Status filter chip for shipping | `orders.list.statusChip.shipping` |
| User-data row | Order row for order `ORD-2026-0007` | `orders.list.row:ORD-2026-0007` |
| Ordinal collection | Third photo thumbnail in the edit form | `orderEdit.photo.thumbnail.index.2` |

#### Scenario: User-data row keeps its key unlocalised

- **WHEN** the app language is switched to English and the orders list re-renders
- **THEN** each order row's identifier is unchanged because the business key is not translated

#### Scenario: Ordinal collection uses position

- **WHEN** the order edit form renders three photo thumbnails
- **THEN** their identifiers end with positions zero, one, and two respectively

### Requirement: Identifier coverage categories

The following categories SHALL carry identifiers: controls without visible text, screen root containers, sheet root containers, alerts together with each of their buttons, empty-state containers, loading containers, load-failure containers together with their retry control, filter chips, rows that merge their children into a single accessibility element, and chart containers together with their primary value element. Navigation bars SHALL NOT be given identifiers, because a SwiftUI navigation bar is not the container the identifier modifier applies to; UI tests SHALL reach a navigation bar through the navigation bar query and confirm the screen through its root identifier instead.

#### Scenario: Icon-only control is reachable

- **WHEN** a toolbar exposes a control whose label is only a symbol
- **THEN** that control carries an identifier and a UI test can activate it without referring to any text

#### Scenario: Merged row exposes its key value

- **WHEN** a list row merges its children into one accessibility element
- **THEN** the row container carries an identifier and also exposes its primary value as that element's accessibility value, so the value can be asserted without splitting the row into separate elements

#### Scenario: Merging is not weakened for testability

- **WHEN** a row already merges its children into a single spoken unit
- **THEN** that merging is preserved, and the row is made testable by adding an identifier and an accessibility value rather than by un-merging its children

#### Scenario: Alert buttons are addressable

- **WHEN** a destructive confirmation alert is presented
- **THEN** the alert container, its confirming button, and its cancelling button each carry an identifier

### Requirement: Single source of identifier constants

Identifier strings SHALL be declared exactly once in a shared constant namespace that both the app target and the UI test target compile. Application code and test code SHALL reference the constants and SHALL NOT write identifier string literals inline.

#### Scenario: Both targets reference the same declaration

- **WHEN** an identifier constant's value is changed
- **THEN** the application code that sets it and the test code that queries it both observe the new value without any other edit

#### Scenario: Inline literals are rejected

- **WHEN** a screen needs a new identifier
- **THEN** the identifier is added to the shared namespace first and both sides reference it by name

### Requirement: Selection state is exposed to assistive technology

Controls whose selected state is conveyed only by colour SHALL additionally expose the selected accessibility trait, so that UI tests can assert selection without inspecting appearance.

#### Scenario: Selected filter chip is detectable

- **WHEN** the user selects a status filter chip
- **THEN** that chip reports the selected trait and the previously selected chip does not
