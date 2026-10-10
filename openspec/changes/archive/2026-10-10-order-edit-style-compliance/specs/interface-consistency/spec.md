## MODIFIED Requirements

### Requirement: Status colors match the meaning of the status

A status SHALL be assigned a semantic color that matches its meaning. A status representing normal forward progress SHALL NOT be assigned a warning color, because doing so signals that attention is required when none is.

Order status colors SHALL come from one semantic tone track, which expresses how much attention a state warrants. The track has six values, SHALL have exactly one source of truth, and SHALL be used wherever a status is presented with an accompanying label, such as a status pill. The track SHALL NOT be inlined at a call site; a surface SHALL obtain its status color from the track.

#### Scenario: Purchased status reads as progress, not warning

- **WHEN** an order in the purchased status is displayed
- **THEN** its status indicator uses an informational semantic color rather than a warning color

#### Scenario: Statuses genuinely needing attention keep the warning color

- **WHEN** an order in the partially arrived status is displayed
- **THEN** its status indicator retains the warning color

#### Scenario: The status color has a single source

- **WHEN** a surface needs a status color
- **THEN** it obtains it from the semantic tone track, and no mapping from status to color is written inline at the call site

#### Scenario: Adding a status forces the track to be updated

- **WHEN** a new order status is introduced
- **THEN** the semantic tone track fails to compile until the new status is given a value, because it is written as an exhaustive mapping rather than falling back to a default
