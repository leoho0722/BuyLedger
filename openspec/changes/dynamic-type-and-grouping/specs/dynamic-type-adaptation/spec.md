## ADDED Requirements

### Requirement: Layouts change structure at accessibility text sizes

Layouts SHALL read the text size environment and change their structure when the size reaches an accessibility level, rather than preserving a fixed structure and truncating content. Multi-column arrangements SHALL collapse to a single column, and horizontally arranged row content SHALL stack vertically. The decision SHALL be based on whether the size is an accessibility size rather than on enumerating individual size steps, so that the behavior survives future additions to the size scale.

#### Scenario: Key metric grid collapses to one column

- **WHEN** the dashboard renders its key metric grid at an accessibility text size
- **THEN** the grid presents one metric per row and each amount is fully readable

#### Scenario: Order row stacks its trailing column

- **WHEN** the order list renders a row at an accessibility text size
- **THEN** the status and amount that normally sit in the trailing column appear below the leading column content, and neither is compressed into an unreadably narrow width

#### Scenario: Standard sizes are unaffected

- **WHEN** any adapted layout renders at a non-accessibility text size
- **THEN** its structure matches the structure before this change

### Requirement: Text scaling is not cancelled by shrink-to-fit

Informational text SHALL NOT rely on a minimum scale factor or a single-line limit as its means of fitting at large text sizes, because shrinking text cancels the user's size preference. At accessibility text sizes, such text SHALL be permitted to wrap and its container SHALL grow accordingly. A minimum scale factor is permitted only as a secondary adjustment at non-accessibility sizes, and SHALL NOT be the sole defense against overflow.

#### Scenario: Net profit figure wraps instead of shrinking

- **WHEN** the dashboard renders the net profit figure at an accessibility text size on a narrow device
- **THEN** the figure wraps to additional lines at its scaled size rather than being shrunk or truncated

#### Scenario: Key metric values wrap instead of shrinking

- **WHEN** a key metric tile renders a long amount at an accessibility text size
- **THEN** the amount is fully readable, wrapping if necessary

### Requirement: Fixed point dimensions scale with text size

Dimensions that must accommodate text SHALL scale with the text size rather than being fixed point values. This applies to container widths and heights sized around labels, to chart diameters carrying centered text, and to any font size specified as a raw point value rather than bound to a text style.

#### Scenario: Heatmap weekday column accommodates its label

- **WHEN** the heatmap renders its weekday labels at an accessibility text size
- **THEN** the label column width accommodates the label without clipping

#### Scenario: Heatmap cell accommodates its numeral

- **WHEN** a heatmap cell renders its order count at an accessibility text size
- **THEN** the numeral is not clipped by the cell bounds

#### Scenario: Donut chart center text stays within the inner circle

- **WHEN** the donut chart renders at an accessibility text size
- **THEN** its diameter scales with the text size and the centered title and amount remain within the inner circle

#### Scenario: Raw point font sizes scale

- **WHEN** any element that previously specified a raw point font size renders after the user changes the system text size
- **THEN** its text size changes accordingly
