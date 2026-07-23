## ADDED Requirements

### Requirement: Custom controls express disabled state visually

A custom control style SHALL read the enabled state from the environment and render a visually distinguishable disabled appearance. A disabled control SHALL NOT be visually identical to its enabled counterpart, because a control that does not respond while looking actionable gives the user no explanation.

#### Scenario: Disabled button is visually distinct

- **WHEN** a button using the custom style is disabled
- **THEN** its appearance differs recognizably from the same button in its enabled state

#### Scenario: Enabled button is unaffected

- **WHEN** a button using the custom style is enabled
- **THEN** its appearance matches the appearance before this change, including its pressed state

### Requirement: Custom tappable elements provide press feedback

Any element that behaves as a button SHALL be implemented as a button so that it receives a pressed state and remains reachable by assistive interaction methods. A tap gesture combined with a button accessibility trait SHALL NOT be used as a substitute, because it provides neither press feedback nor support for switch and keyboard activation.

#### Scenario: Photo thumbnail responds to press

- **WHEN** the user presses a photo thumbnail
- **THEN** the thumbnail shows a pressed state before the photo viewer opens

#### Scenario: Photo thumbnail is reachable by assistive interaction

- **WHEN** the user activates the photo thumbnail using switch control or an external keyboard
- **THEN** the photo viewer opens, matching the behavior of a direct tap

### Requirement: Destructive actions are expressed through button role

A destructive action SHALL be expressed using the system button role rather than by applying a visual style that imitates it. The role determines the system-managed color across appearances, the assistive technology announcement, and the presentation inside menus and confirmation dialogs; a visual imitation provides none of these.

#### Scenario: Destructive button is announced as destructive

- **WHEN** assistive technology focuses a destructive button
- **THEN** the announcement conveys that the action is destructive

#### Scenario: Destructive styling variant is gone

- **WHEN** the codebase is searched for the destructive variant of the custom button style
- **THEN** no definition and no call site remain, and every previously affected button still renders in the system destructive color
