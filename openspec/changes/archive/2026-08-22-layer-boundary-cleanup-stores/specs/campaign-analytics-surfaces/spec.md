## MODIFIED Requirements

### Requirement: Insights analysis range is owned by feature state and persists

The insights view's selected analysis range (for example, the trailing-twelve-months selection) SHALL be owned by the insights feature's own state, not by the root feature and not by transient view-local state. While the app is running, the selected range SHALL persist when the user leaves the insights surface and returns, including switching tabs on iPhone and switching the selected sidebar destination on iPad, and SHALL NOT reset to its default on return. Changing the range SHALL update feature state through a dedicated action.

#### Scenario: Range persists across navigating away and back

- **WHEN** the user selects a non-default analysis range on the insights view, leaves the insights surface, and returns to it
- **THEN** the insights view shows the previously selected range rather than the default

#### Scenario: Range persists across iPad sidebar switches

- **WHEN** on iPad the user selects a non-default analysis range, switches the sidebar to another destination, and switches back to insights
- **THEN** the insights view still shows the previously selected range

#### Scenario: The range lives with the surface that owns it

- **WHEN** the analysis range is located in the state tree
- **THEN** it is held by the insights feature rather than by the root feature
