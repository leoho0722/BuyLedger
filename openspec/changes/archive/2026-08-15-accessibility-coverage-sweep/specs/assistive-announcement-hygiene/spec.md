## MODIFIED Requirements

### Requirement: Selection state is expressed through the standard trait

A row representing a selectable option SHALL express its selected state using the standard selected trait, so that assistive technology, the rotor, and switch control recognize it. A conditionally displayed checkmark SHALL NOT be the sole indication, and where such a checkmark is shown it SHALL be excluded from announcement to avoid it being read as a symbol name.

Conformance SHALL be enforced by a scan rather than by review, within the scan's structural scope: a row styled with the plain button style that structurally renders a checkmark conditionally (as an inline ternary inside the checkmark call, or inside an `if` block) SHALL fail that scan if it adds no selected trait. The scan matches this shape rather than any variable or condition name, so renaming the underlying state does not evade it. Spot-applying the rule at the sites someone happened to touch is what allows a size-class variant or a newly added picker to diverge unnoticed; the scan closes that specific gap.

The scan is a textual heuristic over source shape, not a full analysis of arbitrary Swift. A selectable row built without the plain button style, or a conditional checkmark rendered through a shape other than the two named above, is outside what the scan can detect and remains a review-time responsibility.

#### Scenario: Selected filter row is recognized as selected

- **WHEN** assistive technology focuses a filter row that is currently selected
- **THEN** the row is announced as selected

#### Scenario: Checkmark symbol is not announced separately

- **WHEN** a selected filter row displays its checkmark
- **THEN** the checkmark contributes no separate announcement

#### Scenario: A missing trait fails the scan

- **WHEN** a row within the scan's structural scope renders a conditional selection indicator without adding the selected trait
- **THEN** the scan fails and names that site

### Requirement: Decorative indicators are excluded from announcements

A symbol that conveys nothing beyond what an element's accessibility trait or adjacent content already conveys SHALL be excluded from the accessibility tree. Trailing disclosure indicators inside buttons SHALL be excluded, because the button trait already conveys that the row is actionable. Decorative illustrations SHALL be excluded, because the system would otherwise derive an announcement from the symbol name.

A selection indicator rendered alongside the standard selected trait is decorative in this sense and SHALL be excluded, because the trait already conveys the state the symbol restates.

#### Scenario: Row disclosure indicator is not announced

- **WHEN** assistive technology announces a row button that displays a trailing disclosure indicator
- **THEN** the announcement conveys the row content and its button trait, without naming the indicator

#### Scenario: Onboarding illustration is not announced

- **WHEN** assistive technology traverses the onboarding empty state
- **THEN** the decorative illustration is skipped rather than announced by its symbol name

#### Scenario: Selection indicator is not announced

- **WHEN** assistive technology focuses a selected row that displays a selection symbol
- **THEN** the row is announced as selected and the symbol contributes no separate announcement
