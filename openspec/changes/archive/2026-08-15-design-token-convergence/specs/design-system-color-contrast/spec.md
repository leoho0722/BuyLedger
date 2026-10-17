## MODIFIED Requirements

### Requirement: Informational text meets the 4.5:1 contrast floor

All text that carries information SHALL reach a contrast ratio of at least 4.5:1 against the background it is actually composited over, in light appearance, dark appearance, and each appearance's increased-contrast variant. Text color SHALL NOT be dimmed with opacity as a means of expressing visual hierarchy where doing so drops the result below the floor.

Informational secondary text SHALL obtain its color from the palette's secondary label rather than from the system secondary color. The system value reaches only about 3.4:1 in light appearance and therefore does not meet this floor. This applies to the explanatory footers of forms and lists as well: a footer that states a rule, such as how a total is computed, carries information and is not exempt. The palette's secondary label SHALL be reachable through a single shorthand so that call sites inside view builders can adopt it without obtaining a palette instance.

A graphic element SHALL reach at least 3:1 only when it is the sole carrier of its meaning — progress bar fills and chart marks are such elements. A graphic that merely restates information already given by an adjacent text label is decorative, SHALL NOT be held to the 3:1 floor, and SHALL be hidden from assistive technology. The status dot inside a status pill is decorative in this sense: the pill always renders a text label naming the same state, which is itself the non-color indicator that the platform guidelines require.

Non-informational glyphs, such as a disclosure indicator, are not held to this floor and MAY keep their system color.

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

#### Scenario: Secondary informational text uses the palette, not the system value

- **WHEN** the sources are searched for the system secondary color applied to text
- **THEN** none is found, because every such call site uses the palette's secondary label shorthand

#### Scenario: Form and list footers are held to the floor

- **WHEN** a form or list section footer states a rule such as how a total is computed
- **THEN** its text reaches at least 4.5:1, using the palette's secondary label rather than the system value

#### Scenario: The shorthand cannot drift from the palette

- **WHEN** the secondary label shorthand is resolved in each of the four appearances
- **THEN** it produces the same color components as the palette's secondary label, so it cannot be changed to bypass the contrast assertions
