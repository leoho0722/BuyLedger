## MODIFIED Requirements

### Requirement: Every keyboard type has an identifiable dismissal path

Each keyboard presentation SHALL have a dismissal path that can be named and verified, rather than relying on a global fallback. A standard keyboard SHALL be dismissible through its return key, a numeric keyboard through a keyboard toolbar action, and a scrollable screen through scrolling. Every screen that accepts text input SHALL provide at least two of these paths.

A screen whose only text input is a system `.searchable` search field is exempt from adding an explicit second path: `.searchable` already provides its own Cancel button and its own scroll-to-dismiss behavior, so the pairing is satisfied by system-provided behavior without any additional modifier.

Tapping a screen's empty background is NOT a dismissal path in this project. It was implemented and removed after testing showed that Form, List, and ScrollView consume blank-area touches without forwarding them, including when the Form's scroll background is hidden.

#### Scenario: Standard keyboard dismisses on return

- **WHEN** the user is editing a field presenting a standard keyboard and activates the return key
- **THEN** the keyboard dismisses

#### Scenario: Numeric keyboard dismisses through the toolbar

- **WHEN** the user is editing a field presenting a numeric keyboard and activates the done action in the keyboard toolbar
- **THEN** the keyboard dismisses and the entered value is retained

#### Scenario: Scrollable screen dismisses on scroll

- **WHEN** the user scrolls a scrollable screen while a keyboard is presented
- **THEN** the keyboard dismisses

#### Scenario: Every input screen offers at least two paths

- **WHEN** a screen that accepts text input is inspected
- **THEN** at least two of the named dismissal paths are available on it, and a screen whose only text input is a `.searchable` search field satisfies this through the search field's own Cancel button and scroll-to-dismiss behavior rather than an explicit modifier

### Requirement: Keyboard dismissal does not intercept touches globally

Keyboard dismissal SHALL NOT be implemented by attaching a gesture at the window level and excluding the touches that must not trigger it. Such an implementation requires enumerating every interface that must be excluded, which cannot account for interfaces the system introduces later, and whose failure is silent.

Dismissal SHALL instead be provided by the per-screen paths named above. Attaching dismissal to a screen's background layer is a rejected approach: testing showed that Form, List, and ScrollView consume blank-area touches and do not forward them, so a background layer never receives the tap. The implementation SHALL NOT depend on matching non-public type names. The two scenarios below in which a touch must not dismiss the keyboard are each asserted by a regression test, so that a regression here becomes visible rather than silent.

#### Scenario: System text menu does not dismiss the keyboard

- **WHEN** the user selects text and taps an item in the system text menu, such as paste
- **THEN** the keyboard remains presented and the menu action is performed

#### Scenario: Interactive controls are unaffected

- **WHEN** the user taps a button, toggle, or picker while a keyboard is presented
- **THEN** that control performs its normal action and the keyboard remains presented

#### Scenario: No non-public identifier matching remains

- **WHEN** the codebase is inspected for keyboard dismissal logic
- **THEN** no window-level gesture and no matching against non-public type names remain

#### Scenario: No background-layer dismissal remains

- **WHEN** the codebase is inspected for keyboard dismissal logic
- **THEN** no dismissal gesture is attached to a screen's background layer

### Requirement: Dismissal clears the focus state

Dismissing the keyboard SHALL clear the focus state rather than instructing the view hierarchy to end editing, so that the keyboard's presentation and the focus state cannot disagree. Focus SHALL also be cleared when a screen is dismissed, so that reopening it does not restore a stale focus and present a keyboard unexpectedly.

#### Scenario: Focus is cleared through a named dismissal path

- **WHEN** the user dismisses the keyboard through the keyboard toolbar done action
- **THEN** the focus state no longer refers to any field

#### Scenario: Focus does not persist across presentations

- **WHEN** the user dismisses a screen while a field is focused and then opens that screen again
- **THEN** no field is focused and no keyboard is presented
