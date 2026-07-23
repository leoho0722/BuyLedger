## ADDED Requirements

### Requirement: Animations honor the reduce motion preference

Animation SHALL read the reduce motion preference from the environment and SHALL be suppressed or replaced with a non-moving equivalent when the preference is enabled. The check SHALL be applied at the point where animation is declared, so that the pattern is established for animations added later rather than requiring each new site to rediscover it.

#### Scenario: Press feedback animation is suppressed

- **WHEN** the reduce motion preference is enabled and the user presses a button using the custom style
- **THEN** the button reaches its pressed appearance without an animated transition

#### Scenario: Animation is unchanged when the preference is off

- **WHEN** the reduce motion preference is disabled
- **THEN** the press feedback animates exactly as it did before this change
