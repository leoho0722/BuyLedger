## MODIFIED Requirements

### Requirement: Status colors match the meaning of the status

A status SHALL be assigned a semantic color that matches its meaning. A status representing normal forward progress SHALL NOT be assigned a warning color, because doing so signals that attention is required when none is.

The app maintains two distinct color tracks for order status, and each SHALL have exactly one source of truth and a written statement of which surfaces it serves:

- The semantic tone track expresses how much attention a state warrants. It has six values and SHALL be used wherever a status is presented with an accompanying label, such as a status pill.
- The pipeline hue track expresses which stage of the pipeline a group represents, and exists to keep adjacent groups distinguishable. It has one value per order status and SHALL be used only for the sidebar group indicators.

The pipeline hue track exists because the semantic tone track cannot serve this surface: mapping the eight pipeline groups through six semantic tones collapses them to four colors, and two of the collapsed pairs render as adjacent rows in the sidebar, where identical color reads as a rendering defect rather than as shared meaning. Neither track SHALL be inlined at a call site; a surface SHALL obtain its color from the track that serves it.

#### Scenario: Purchased status reads as progress, not warning

- **WHEN** an order in the purchased status is displayed
- **THEN** its status indicator uses an informational semantic color rather than a warning color

#### Scenario: Statuses genuinely needing attention keep the warning color

- **WHEN** an order in the partially arrived status is displayed
- **THEN** its status indicator retains the warning color

#### Scenario: Sidebar group indicators stay mutually distinguishable

- **WHEN** the sidebar renders its group indicators in any of the four appearances
- **THEN** no two groups resolve to the same color

#### Scenario: Each track has a single source

- **WHEN** a surface needs a status color
- **THEN** it obtains it from the track that serves that surface, and no mapping from status to color is written inline at the call site

#### Scenario: Adding a status forces both tracks to be updated

- **WHEN** a new order status is introduced
- **THEN** both tracks fail to compile until the new status is given a value, because each is written as an exhaustive mapping rather than falling back to a default
