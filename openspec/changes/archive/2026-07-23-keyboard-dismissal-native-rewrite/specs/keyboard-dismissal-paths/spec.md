## ADDED Requirements

### Requirement: Every keyboard type has an identifiable dismissal path

Each keyboard presentation SHALL have a dismissal path that can be named and verified, rather than relying on a global fallback. A standard keyboard SHALL be dismissible through its return key, a numeric keyboard through a keyboard toolbar action, a scrollable screen through scrolling, and a non-scrollable screen through tapping its background.

#### Scenario: Standard keyboard dismisses on return

- **WHEN** the user is editing a field presenting a standard keyboard and activates the return key
- **THEN** the keyboard dismisses

#### Scenario: Numeric keyboard dismisses through the toolbar

- **WHEN** the user is editing a field presenting a numeric keyboard and activates the done action in the keyboard toolbar
- **THEN** the keyboard dismisses and the entered value is retained

#### Scenario: Scrollable screen dismisses on scroll

- **WHEN** the user scrolls a scrollable screen while a keyboard is presented
- **THEN** the keyboard dismisses

#### Scenario: Background tap dismisses the keyboard

- **WHEN** the user taps the empty background of a screen while a keyboard is presented
- **THEN** the keyboard dismisses

### Requirement: Keyboard dismissal does not intercept touches globally

Keyboard dismissal SHALL NOT be implemented by attaching a gesture at the window level and excluding the touches that must not trigger it. Such an implementation requires enumerating every interface that must be excluded, which cannot account for interfaces the system introduces later, and whose failure is silent.

Dismissal SHALL instead be attached to a screen's background layer, so that system text interfaces are outside its hit-testing area and require no exclusion. The implementation SHALL NOT depend on matching non-public type names.

#### Scenario: System text menu does not dismiss the keyboard

- **WHEN** the user selects text and taps an item in the system text menu, such as paste
- **THEN** the keyboard remains presented and the menu action is performed

#### Scenario: Interactive controls are unaffected

- **WHEN** the user taps a button, toggle, or picker while a keyboard is presented
- **THEN** that control performs its normal action and the keyboard is not dismissed by the background layer

#### Scenario: No non-public identifier matching remains

- **WHEN** the codebase is inspected for keyboard dismissal logic
- **THEN** no window-level gesture and no matching against non-public type names remain

### Requirement: Dismissal clears the focus state

Dismissing the keyboard SHALL clear the focus state rather than instructing the view hierarchy to end editing, so that the keyboard's presentation and the focus state cannot disagree. Focus SHALL also be cleared when a screen is dismissed, so that reopening it does not restore a stale focus and present a keyboard unexpectedly.

#### Scenario: Focus is cleared on background tap

- **WHEN** the user taps the background to dismiss the keyboard
- **THEN** the focus state no longer refers to any field

#### Scenario: Focus does not persist across presentations

- **WHEN** the user dismisses a screen while a field is focused and then opens that screen again
- **THEN** no field is focused and no keyboard is presented

### Requirement: Focus state placement follows the existing project convention

A screen bound to a store SHALL hold its focus field in the corresponding feature state and connect it through a binding, consistent with the convention that store-bound views hold no presentation state. A reusable component that communicates with its caller through closures rather than a store SHALL hold its focus state locally, consistent with the existing exception for such components.

#### Scenario: Store-bound screen holds focus in feature state

- **WHEN** a store-bound editing screen declares its focus field
- **THEN** the field resides in that feature's state and the view connects to it through a binding

#### Scenario: Closure-based component holds focus locally

- **WHEN** a reusable picker or editor component that communicates through closures declares its focus state
- **THEN** the state resides in the component itself
