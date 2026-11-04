## MODIFIED Requirements

### Requirement: Layouts change structure at accessibility text sizes

Content layouts SHALL read the text size environment and change structure when it reaches an accessibility level rather than preserving a fixed structure and truncating content. Multi-column content grids SHALL collapse to a single column and horizontally arranged row content SHALL stack vertically. The decision SHALL use whether the size is an accessibility size rather than enumerating individual steps. System navigation columns SHALL adapt through their own containers and available space; this content rule SHALL NOT impose an unconditional single navigation column. Content width preferences SHALL yield when needed to preserve scaled text and usable controls.

#### Scenario: Key metric grid collapses to one column

- **GIVEN** dashboard displays its four metrics
- **WHEN** the user selects an accessibility text size
- **THEN** one metric appears per row and every amount remains fully readable
- **AND** cost remains present on both narrow and wide screens

#### Scenario: Order row stacks its trailing column

- **GIVEN** the orders list contains status and amount in a trailing row column
- **WHEN** an accessibility text size is applied
- **THEN** status and amount appear below the leading content without unreadable compression

#### Scenario: Standard sizes use the common content arrangements

- **GIVEN** a non-accessibility text size
- **WHEN** dashboard or insights renders in any supported window size
- **THEN** dashboard uses the same two-column metric grid below its summary and insights retains its common vertical sequence

#### Scenario: Navigation columns preserve readable content

- **GIVEN** a system split container retains list and detail columns at an accessibility text size
- **WHEN** content renders in each column
- **THEN** its grids and rows adapt within that column without clipping text or overlapping controls
- **AND** the system retains the ability to collapse navigation when its available region requires it
