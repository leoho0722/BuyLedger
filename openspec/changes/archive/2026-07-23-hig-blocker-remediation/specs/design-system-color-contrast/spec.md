## ADDED Requirements

### Requirement: Semantic tones expose separate text and graphic colors

The semantic tone type SHALL expose distinct colors for text usage and for graphic usage, and SHALL NOT expose a single color that serves both. Specifically it SHALL provide: a surface text color for text drawn on a card or row background, a soft background color paired with that text color, an indicator color for purely graphic elements such as status dots and progress bars, and an on-indicator text color for text drawn on top of a filled indicator background. The previously combined foreground accessor SHALL be removed so that existing call sites fail to compile until each one is explicitly reassigned to the correct track.

#### Scenario: Status pill draws text and dot from different tracks

- **WHEN** a status pill renders a tone with both a label and a status dot
- **THEN** the label color comes from the surface text track, the dot color comes from the indicator track, and the pill background comes from the soft background track

#### Scenario: Count badge draws text on a filled background

- **WHEN** a count badge renders with a filled tone background
- **THEN** the background comes from the indicator track and the numeral color comes from the on-indicator track

#### Scenario: Combined foreground accessor is gone

- **WHEN** the codebase is searched for the removed combined foreground accessor
- **THEN** no call site remains, and the project builds for both iOS and iPadOS

### Requirement: Informational text meets the 4.5:1 contrast floor

All text that carries information SHALL reach a contrast ratio of at least 4.5:1 against the background it is actually composited over, in light appearance, dark appearance, and each appearance's increased-contrast variant. Text color SHALL NOT be dimmed with opacity as a means of expressing visual hierarchy where doing so drops the result below the floor.

A graphic element SHALL reach at least 3:1 only when it is the sole carrier of its meaning — progress bar fills and chart marks are such elements. A graphic that merely restates information already given by an adjacent text label is decorative, SHALL NOT be held to the 3:1 floor, and SHALL be hidden from assistive technology. The status dot inside a status pill is decorative in this sense: the pill always renders a text label naming the same state, which is itself the non-color indicator that the platform guidelines require.

#### Scenario: Decorative status dot is exempt and hidden

- **WHEN** a status pill renders its indicator dot alongside its text label
- **THEN** the dot is not held to the 3:1 floor, and it is hidden from assistive technology so that the label alone is announced

#### Scenario: Status pill label is legible in light appearance

- **WHEN** a status pill renders any of the six tones in light appearance
- **THEN** the label contrast against the pill background is at least 4.5:1

##### Example: measured tones before and after

| Tone | Before (light) | Required |
| ---- | -------------- | -------- |
| success | 1.98:1 | at least 4.5:1 |
| warning | 1.96:1 | at least 4.5:1 |
| destructive | 2.69:1 | at least 4.5:1 |
| accent | 3.35:1 | at least 4.5:1 |
| informative | 4.60:1 | at least 4.5:1 |
| neutral | 5.50:1 | at least 4.5:1 |

#### Scenario: Customer rank badge is legible at every rank

- **WHEN** the customer list renders rank badges for first, second, and third-or-later positions
- **THEN** each badge's numeral reaches at least 4.5:1 against that badge's own background

#### Scenario: Increased contrast is honored

- **WHEN** the system increased-contrast setting is enabled in either appearance
- **THEN** every tone resolves to its increased-contrast variant and still meets the applicable floor

### Requirement: Tone colors are defined as named asset catalog resources

Each semantic tone's four color roles SHALL be defined as named color resources in the asset catalog rather than derived at runtime by applying opacity to another color. Each resource SHALL define both a default and a dark appearance, and each SHALL carry an increased-contrast variant. Color resource additions SHALL land together with the code that references them, because a missing named color resolves silently to a system default rather than failing.

#### Scenario: Soft background is no longer derived from the text color

- **WHEN** a tone's soft background color is requested
- **THEN** the value comes from a named asset catalog resource, and is not computed by applying opacity to that tone's text color

#### Scenario: Every tone resource covers all required variants

- **WHEN** the asset catalog is inspected for a given tone
- **THEN** resources exist for surface text, soft background, indicator, and on-indicator, each defining default and dark appearances plus an increased-contrast variant

### Requirement: Avatar initials remain legible across all generated hues

Avatar background colors SHALL continue to be derived from the customer name so that each customer keeps a stable distinct color, and the initials SHALL reach at least 4.5:1 against that generated background for every possible hue. The hue derivation SHALL NOT change; only the saturation and brightness of the generated gradient SHALL be adjusted to satisfy the floor.

#### Scenario: Initials are legible at the worst-case hue

- **WHEN** an avatar is generated for a name whose derived hue falls in the yellow-green range, previously the lowest-contrast case at 1.64:1
- **THEN** the initials reach at least 4.5:1 against the generated gradient

#### Scenario: Distinct customers keep distinct colors

- **WHEN** avatars are generated for two customers with different names
- **THEN** their background hues differ exactly as they did before this change

### Requirement: Heatmap cells use discrete depth levels with paired colors

The order heatmap SHALL express density using a fixed set of discrete depth levels rather than a continuous opacity ramp. Each depth level SHALL have a background color and a paired numeral color defined together as named asset catalog resources, and each pair SHALL meet the 4.5:1 floor in both appearances. The continuous opacity ramp SHALL be removed because neither end of it can satisfy the floor with a fixed numeral color.

#### Scenario: Both the lightest and darkest cells are legible

- **WHEN** the heatmap renders its lightest and darkest depth levels in either appearance
- **THEN** the cell numeral reaches at least 4.5:1 against that cell's background

##### Example: failing values under the previous continuous ramp

| Cell opacity | Composited background | Contrast with white numeral |
| ------------ | --------------------- | --------------------------- |
| 0.2 | very light blue | 1.30:1 |
| 0.6 | mid blue | 2.29:1 |
| 1.0 | full accent blue | 4.02:1 |

#### Scenario: Adjacent density levels are distinguishable

- **WHEN** two heatmap cells hold order counts that map to adjacent depth levels
- **THEN** their background colors are visibly distinct from one another

### Requirement: Tertiary label color is reserved for non-informational text

The tertiary label color SHALL be used only for disabled states and placeholder text. Text that carries information — including section headings, chart axis labels, units, and explanatory captions — SHALL use the secondary label color or stronger, because the tertiary color's 30 percent opacity yields approximately 2.09:1 in light appearance.

#### Scenario: Chart axis labels are legible

- **WHEN** a bar chart renders its axis labels
- **THEN** the labels use the secondary label color or stronger and reach at least 4.5:1

#### Scenario: Section headings are legible

- **WHEN** a list renders a section heading that previously used the tertiary label color
- **THEN** the heading uses the secondary label color or stronger and reaches at least 4.5:1
