## MODIFIED Requirements

### Requirement: Dimensions shared across files derive from a single source

A dimension used in more than one file SHALL be defined once and derived from that definition, rather than transcribed as a literal at each site. Separator insets that align to an avatar's trailing edge SHALL derive from the avatar's own size definition, so that changing the avatar size does not silently misalign the separators.

The same applies to presentation rules, not only to dimensions. A rule that determines how a value is rendered — such as the currency, precision, and locale used to format an amount — SHALL be defined once and called from each site, rather than reimplemented per screen. Equivalent copies do not misbehave, but they make consistency depend on someone remembering every copy, and a divergence between them is not detectable by any test.

#### Scenario: Separator inset follows the avatar size

- **WHEN** the avatar size definition changes
- **THEN** every separator that aligns to an avatar's trailing edge remains aligned without further edits

#### Scenario: No transcribed literals remain

- **WHEN** the codebase is searched for the previous hand-computed inset expressions
- **THEN** no site retains a transcribed avatar size, because a remaining site would misalign while the others stayed correct and would therefore be harder to notice

#### Scenario: Amount formatting has one definition

- **WHEN** a screen renders a monetary amount
- **THEN** it calls the shared formatting entry point, and no screen defines its own equivalent formatting

#### Scenario: A formatting change takes effect everywhere at once

- **WHEN** the shared formatting rule changes
- **THEN** every screen's rendering changes with it, without further edits
