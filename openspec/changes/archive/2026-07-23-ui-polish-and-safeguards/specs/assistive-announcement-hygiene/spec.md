## ADDED Requirements

### Requirement: Decorative indicators are excluded from announcements

A symbol that conveys nothing beyond what an element's accessibility trait or adjacent content already conveys SHALL be excluded from the accessibility tree. Trailing disclosure indicators inside buttons SHALL be excluded, because the button trait already conveys that the row is actionable. Decorative illustrations SHALL be excluded, because the system would otherwise derive an announcement from the symbol name.

#### Scenario: Row disclosure indicator is not announced

- **WHEN** assistive technology announces a row button that displays a trailing disclosure indicator
- **THEN** the announcement conveys the row content and its button trait, without naming the indicator

#### Scenario: Onboarding illustration is not announced

- **WHEN** assistive technology traverses the onboarding empty state
- **THEN** the decorative illustration is skipped rather than announced by its symbol name

### Requirement: Selection state is expressed through the standard trait

A row representing a selectable option SHALL express its selected state using the standard selected trait, so that assistive technology, the rotor, and switch control recognize it. A conditionally displayed checkmark SHALL NOT be the sole indication, and where such a checkmark is shown it SHALL be excluded from announcement to avoid it being read as a symbol name.

#### Scenario: Selected filter row is recognized as selected

- **WHEN** assistive technology focuses a filter row that is currently selected
- **THEN** the row is announced as selected

#### Scenario: Checkmark symbol is not announced separately

- **WHEN** a selected filter row displays its checkmark
- **THEN** the checkmark contributes no separate announcement
