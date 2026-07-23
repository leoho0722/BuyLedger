## ADDED Requirements

### Requirement: Dimensions shared across files derive from a single source

A dimension used in more than one file SHALL be defined once and derived from that definition, rather than transcribed as a literal at each site. Separator insets that align to an avatar's trailing edge SHALL derive from the avatar's own size definition, so that changing the avatar size does not silently misalign the separators.

#### Scenario: Separator inset follows the avatar size

- **WHEN** the avatar size definition changes
- **THEN** every separator that aligns to an avatar's trailing edge remains aligned without further edits

#### Scenario: No transcribed literals remain

- **WHEN** the codebase is searched for the previous hand-computed inset expressions
- **THEN** no site retains a transcribed avatar size, because a remaining site would misalign while the others stayed correct and would therefore be harder to notice

### Requirement: Component padding and indicators scale with text size

Padding and indicator dimensions inside text-bearing components SHALL scale with the text size, so that the component grows with its content rather than compressing it. Status pills and count badges SHALL scale their internal padding and their status dot.

#### Scenario: Status pill grows with its label

- **WHEN** a status pill renders at an accessibility text size
- **THEN** its internal padding scales accordingly and its label is not compressed against the pill edge

#### Scenario: Status dot remains proportionate

- **WHEN** a status pill renders its status dot at an accessibility text size
- **THEN** the dot scales with the text rather than remaining at its baseline size

### Requirement: Ineffective and unreferenced code is removed

Modifiers that have no effect, and components with no call sites, SHALL be removed rather than retained. An unreferenced component in the design system carries an implicit endorsement, and a component whose preview demonstrates a discouraged construction actively propagates it.

#### Scenario: Zero-width tracking modifier is removed

- **WHEN** the typography modifier is inspected
- **THEN** it applies no zero-width tracking, because doing so overrides the optical tracking the system font applies per size

#### Scenario: Unreferenced components are removed

- **WHEN** the design system is inspected for components with no call sites outside their own preview
- **THEN** the list row component and the amount field component no longer exist

### Requirement: Mechanisms depending on non-public identifiers are covered by regression tests

A mechanism whose correctness depends on matching non-public type names or other undocumented identifiers SHALL be covered by a regression test asserting the behavior it protects, so that failure becomes observable rather than silent. Where no public API exists to replace such matching, the matching is permitted to remain; the test is what converts a silent regression into a visible one.

#### Scenario: Keyboard dismissal filtering is covered

- **WHEN** the user selects text and taps the system text menu
- **THEN** the keyboard does not dismiss, and this behavior is asserted by a test that fails if the underlying identifier matching stops working

#### Scenario: Scroll dismissal still works

- **WHEN** the user scrolls a view containing an active text field
- **THEN** the keyboard dismisses, because the gesture still recognizes simultaneously with known scroll recognizers

