## MODIFIED Requirements

### Requirement: Animations honor the reduce motion preference

Animation SHALL read the reduce motion preference from the environment and SHALL be suppressed or replaced with a non-moving equivalent when the preference is enabled. The check SHALL be applied at the point where animation is declared, so that the pattern is established for animations added later rather than requiring each new site to rediscover it.

Establishing the pattern is not sufficient on its own, because a later animation can be added without following it and nothing will report the omission. Conformance SHALL therefore be enforced by a scan, within the scan's structural scope: an `.animation(...)` declaration that does not consult the preference, either directly at the call site or through a same-file property or function it references, SHALL fail that scan.

The scan's scope is limited to the `.animation(...)` API; it does not cover `withAnimation`, `.transition`, or `.symbolEffect`. This matches the codebase's current animation sources, all three of which use `.animation(...)`; extending the scan to the other APIs is future work, not a present guarantee.

#### Scenario: Press feedback animation is suppressed

- **WHEN** the reduce motion preference is enabled and the user presses a button using the custom style
- **THEN** the button reaches its pressed appearance without an animated transition

#### Scenario: Animation is unchanged when the preference is off

- **WHEN** the reduce motion preference is disabled
- **THEN** the press feedback animates exactly as it did before this change

#### Scenario: Zoom animation honors the preference

- **WHEN** the reduce motion preference is enabled and the user zooms in the photo viewer
- **THEN** the zoom reaches its target scale without an animated transition

#### Scenario: An unguarded animation fails the scan

- **WHEN** an `.animation(...)` declaration is added without consulting the reduce motion preference, directly or through a same-file declaration it references
- **THEN** the scan fails and names that site
