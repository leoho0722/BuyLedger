## ADDED Requirements

### Requirement: Controls are not placed where the window edge can hide them

Controls and essential information SHALL NOT be placed in a bottom bar on a platform where the user can drag the window such that its lower edge leaves the screen. Batch operations and selection counts SHALL use a top placement, with counts carried by the navigation title.

#### Scenario: Batch operations remain reachable when the window is dragged

- **WHEN** the user enters multiple selection on iPad and drags the window so its lower edge extends beyond the screen
- **THEN** the batch operation controls remain visible and usable

#### Scenario: Selection count appears in the navigation title

- **WHEN** the user selects orders in either size class
- **THEN** the number of selected orders appears in the navigation title, consistently across both size classes

### Requirement: System back navigation is preserved

A pushed screen SHALL retain the system back button and the interactive pop gesture. A screen SHALL NOT hide the system back button and substitute a custom control, because doing so also disables the edge swipe that users rely on across the entire system.

#### Scenario: Settings supports edge swipe back

- **WHEN** the user swipes from the leading screen edge on the settings screen
- **THEN** the screen pops back to the previous screen

#### Scenario: Back button does not show a stale title

- **WHEN** the user changes the in-app language and then navigates to settings
- **THEN** the back button does not display a title cached from the previous language

### Requirement: Alerts are not used to host forms

An alert SHALL be reserved for information requiring an immediate decision. Data entry SHALL be presented in a sheet containing a form, with explicit cancel and confirm actions. An alert SHALL NOT contain a text field together with explanatory body text, because at large text sizes such an alert approaches requiring scrolling and because the pattern silently drops non-text controls.

#### Scenario: Adding a lookup item uses a form sheet

- **WHEN** the user chooses to add a lookup item
- **THEN** a sheet containing a form is presented, with cancel and save actions

#### Scenario: Renaming a lookup item uses a form sheet

- **WHEN** the user chooses to rename a lookup item
- **THEN** a sheet containing a form is presented, prefilled with the current name

### Requirement: Search scope is disclosed accurately

A search field's prompt SHALL describe the scope actually searched. It SHALL NOT name a narrower scope than the one the query filters.

#### Scenario: Filter sheet prompt covers all searched sections

- **WHEN** the filter sheet presents its search field, and the query filters both categories and payment methods
- **THEN** the prompt names both, or the search is narrowed with an explicit scope control so that the stated scope matches the actual scope
