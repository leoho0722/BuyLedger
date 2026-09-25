## ADDED Requirements

### Requirement: The same capability is not maintained twice for different size classes

Where a screen provides separate layouts for compact and regular size classes, any component that is equivalent in both SHALL have a single definition shared by them. Maintaining an equivalent copy per layout SHALL NOT be treated as acceptable duplication on the grounds that the layouts differ overall, because the copies drift and the drift is invisible: each layout looks correct in isolation and only one is exercised at a time.

Layout structure that genuinely differs between size classes remains separate; this requirement applies to the parts that are equivalent.

#### Scenario: Equivalent components have one definition

- **WHEN** a component's implementation is equivalent across the compact and regular layouts
- **THEN** it is defined once and both layouts use that definition

#### Scenario: Drift becomes impossible rather than corrected

- **WHEN** a behaviour or assistive-technology attribute is added to a shared component
- **THEN** both size classes receive it, because there is only one place it can be written

#### Scenario: Genuinely different structure stays separate

- **WHEN** the two layouts differ in structure rather than in an equivalent component
- **THEN** they remain separate implementations
