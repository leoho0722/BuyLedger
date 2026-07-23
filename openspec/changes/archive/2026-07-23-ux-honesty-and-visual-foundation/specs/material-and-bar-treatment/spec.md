## ADDED Requirements

### Requirement: Bars are not imitated with opaque backgrounds

A region carrying navigation or controls SHALL NOT be given an opaque background color and a separator line in imitation of a system bar. Scrollable content SHALL extend beneath such a region rather than stopping at its edge. Where a hand-drawn bar exists, it SHALL either be replaced by the system bar that carries its title and actions, or be given a system material so that content passes beneath it.

#### Scenario: Order detail content extends beneath its title region

- **WHEN** the user scrolls the order detail content
- **THEN** the content passes beneath the title region rather than stopping at a separator line

#### Scenario: Title and actions are carried by system presentation

- **WHEN** the order detail pane presents the customer name and its action menus
- **THEN** they are carried by the system navigation presentation, or by a region using a system material, and not by an opaque hand-drawn bar

### Requirement: Materials are not imitated with translucent color values

Translucent color values SHALL NOT be defined to imitate a system material. Such values do not refract, do not adjust luminosity, and do not respond to reduced transparency or increased contrast settings. Where such definitions exist without call sites, they SHALL be removed rather than retained for possible future use.

#### Scenario: Imitation material definitions are removed

- **WHEN** the palette is inspected after this change
- **THEN** it defines no translucent color intended to imitate a glass or material appearance

#### Scenario: Future material needs use system materials

- **WHEN** a component requires a material appearance
- **THEN** it uses a system material, falling back to a system material on deployment versions where newer material APIs are unavailable
