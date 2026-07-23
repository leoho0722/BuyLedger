## ADDED Requirements

### Requirement: Tappable controls provide a 44 point minimum hit region

Every tappable control SHALL provide a hit region measuring at least 44 by 44 points in both dimensions. The hit region SHALL be independent of the control's visible size, so that a control with a smaller icon still satisfies the minimum. The hit region SHALL be established on the control's own label content so that it expands the tappable area, and SHALL NOT be established by padding applied to an enclosing container, which only adds layout spacing without enlarging the control.

#### Scenario: Photo thumbnail delete control is reachable

- **WHEN** the order edit form renders a photo thumbnail with its delete control
- **THEN** the delete control's hit region measures at least 44 by 44 points while its icon keeps its current visible size

#### Scenario: Search field clear control is reachable

- **WHEN** a search field renders its clear control because text has been entered
- **THEN** the clear control's hit region measures at least 44 by 44 points

Note: the current hand-built search field is scheduled for replacement by the system search presentation in a later change, which supplies a compliant clear control. This requirement states the contract that the replacement SHALL satisfy; it SHALL NOT be discharged by enlarging the hit region of the component being removed.

#### Scenario: Enlarged hit region does not alter layout

- **WHEN** a control's hit region is enlarged to meet the minimum
- **THEN** the surrounding layout, including the control's position relative to its container, matches the layout before the change

##### Example: measured controls

| Control | Measured before | Required |
| ------- | --------------- | -------- |
| Photo thumbnail delete | about 20 by 20 points | at least 44 by 44 points |
| Search field clear | about 17 by 17 points | at least 44 by 44 points |

### Requirement: Destructive controls are not undersized

A control that performs a destructive action without a confirmation step SHALL meet the minimum hit region, because an accidental activation cannot be undone. The photo delete control removes a photo from the draft with no confirmation and no undo, and therefore SHALL meet the minimum.

#### Scenario: Accidental deletion is not invited by an undersized target

- **WHEN** the delete control is overlaid on a photo thumbnail
- **THEN** its hit region meets the minimum and remains distinguishable from a tap on the thumbnail itself, which opens the photo viewer
