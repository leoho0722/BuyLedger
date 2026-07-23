## ADDED Requirements

### Requirement: Chart data points are announced with name and value

Every chart mark that represents a data point SHALL carry an accessibility label naming what the point represents and an accessibility value stating its magnitude, so that assistive technology can announce both. A chart SHALL NOT rely on color alone to convey which segment or bar corresponds to which category.

#### Scenario: Bar chart announces each bar

- **WHEN** VoiceOver focus moves across the bars of the trend chart
- **THEN** each bar announces the period it represents and its amount

#### Scenario: Donut chart announces each segment

- **WHEN** VoiceOver focus moves across the segments of the cost breakdown chart
- **THEN** each segment announces its category name and its amount

### Requirement: Donut segments carry category identity through the chart framework

Donut chart segments SHALL be styled by a category dimension derived from the segment name rather than by directly supplying a raw color, so that the charting framework receives the category identity and can surface it to assistive technology. The existing visual palette SHALL be preserved by mapping categories to the current colors through a style scale.

#### Scenario: Segment names reach the accessibility tree

- **WHEN** the donut chart renders segments whose names are already present in its data model
- **THEN** those names are available to assistive technology without requiring a separate visible legend

#### Scenario: Existing colors are unchanged

- **WHEN** the donut chart renders after this change
- **THEN** each category keeps the same color it had before the change

### Requirement: Every chart provides a summary for assistive technology

Each of the three chart components SHALL provide a chart-level summary that states what the chart shows, so that a user can understand the chart without traversing every data point. A chart that is purely decorative because the same information already appears as adjacent text SHALL instead be explicitly hidden from assistive technology. A chart SHALL NOT remain in its current state of having neither a label nor an explicit exclusion.

#### Scenario: Sparkline is either described or hidden

- **WHEN** the sparkline renders inside the dashboard summary card
- **THEN** it either announces a trend summary describing its direction and range, or it is explicitly hidden from assistive technology because the same figure appears as adjacent text

#### Scenario: Empty chart announces absence of data

- **WHEN** a chart has no data to display
- **THEN** its summary describes that there is no data, rather than announcing zero values

#### Scenario: Chart summary does not duplicate the visible title

- **WHEN** a chart sits beneath a visible heading that already names it
- **THEN** the chart summary adds the shape of the data rather than repeating the heading text verbatim
