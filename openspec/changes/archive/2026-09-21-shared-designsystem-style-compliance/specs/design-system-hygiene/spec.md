## MODIFIED Requirements

### Requirement: Dimensions shared across files derive from a single source

A dimension used in more than one file SHALL be defined once and derived from that definition, rather than transcribed as a literal at each site. Separator insets that align to an avatar's trailing edge SHALL derive from the avatar's own size definition, so that changing the avatar size does not silently misalign the separators.

The same applies to presentation rules, not only to dimensions. A rule that determines how a value is rendered — such as the currency, precision, and locale used to format an amount, or the language-dependent display name shown for a currency — SHALL be defined once and called from each site, rather than reimplemented per screen. Equivalent copies do not misbehave, but they make consistency depend on someone remembering every copy, and a divergence between them is not detectable by any test.

A presentation rule that depends on the App's language preference SHALL derive that preference through the single language type the App already uses, rather than each screen re-deriving it from the locale with its own condition. Two screens that disagree on how the language is detected can render the same value differently, and no test compares them.

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

#### Scenario: Currency display names have one definition

- **WHEN** a screen renders the display name of a currency
- **THEN** it calls the shared currency display entry point, and no screen defines its own equivalent name lookup

##### Example: the same currency renders identically on every screen

| App language | Currency code | Rendered name, on every screen and in every picker |
| ------------ | ------------- | -------------------------------------------------- |
| Traditional Chinese | TWD | the localized currency name resolved for that code |
| Traditional Chinese | a code the system cannot name | the code itself, unchanged |
| English | TWD | TWD |

"The same entry point" means one shared declaration that every call site routes through, not one single function: a search-keyword lookup that deliberately ignores the language preference, so that a name remains findable when the displayed text is the code, belongs to that same declaration and is not a second implementation.

#### Scenario: Picker rows and other screens show the same name for a currency

- **WHEN** the same currency appears in a selection picker and elsewhere on a screen
- **THEN** both show the same text, because a picker that appends the code or wraps the name in punctuation is a second rendering of the same rule

#### Scenario: Language detection for presentation is not re-derived per screen

- **WHEN** a screen needs to know the current App language in order to render a value
- **THEN** it obtains it through the shared language type rather than comparing the locale's language code inline
