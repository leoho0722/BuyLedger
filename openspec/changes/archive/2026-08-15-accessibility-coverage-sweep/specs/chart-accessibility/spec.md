## ADDED Requirements

### Requirement: Charts expose a native chart description for structured navigation

Every chart SHALL provide the platform's native chart description in addition to its per-point announcements and its summary, so that assistive technology can navigate it as a chart rather than as a list of labelled elements. The description SHALL name the axes and the data series and SHALL expose the values in their plotted order.

Per-point labels answer "what is this element"; the chart description answers "what shape is this data", which is what a chart exists to convey.

#### Scenario: A chart is navigable as a chart

- **WHEN** assistive technology focuses a chart
- **THEN** the platform's chart navigation is available, exposing the axes, the series, and the values in plotted order

#### Scenario: Existing announcements are unchanged

- **WHEN** a chart provides its native description
- **THEN** its per-point labels and its overall summary remain as they were

#### Scenario: Every chart component is covered

- **WHEN** the chart components are inspected
- **THEN** each provides a native chart description
