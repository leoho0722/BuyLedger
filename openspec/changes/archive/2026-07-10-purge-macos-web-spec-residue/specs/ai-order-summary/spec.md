## MODIFIED Requirements

### Requirement: AI summary entry point gated by setting

The orders list SHALL present an "AI summary" toolbar action on iOS and iPadOS, placed alongside the existing new-order action. The action SHALL be disabled when the currently filtered orders list is empty. When activated, the system SHALL read the `useAiSummary` setting and branch: if enabled, it SHALL present the streaming summary sheet; if disabled, it SHALL present a prompt alert.

#### Scenario: Activate with AI summary enabled

- **WHEN** the user activates the AI summary action and `useAiSummary` is enabled
- **THEN** the system presents the streaming summary sheet and begins summarizing the filtered list's product details

#### Scenario: Activate with AI summary disabled

- **WHEN** the user activates the AI summary action and `useAiSummary` is disabled
- **THEN** the system presents a prompt alert instead of the sheet, and does not call the AI service

#### Scenario: Empty filtered list

- **WHEN** the currently filtered orders list contains no orders
- **THEN** the AI summary action is disabled

### Requirement: Disabled-state prompt alert with deep link to settings

When AI summary is disabled, the prompt alert SHALL present two actions: a left "close" action that dismisses the alert, and a right "go to settings" action. Activating the right action SHALL navigate the user to the settings page where the toggle lives. On iOS and iPadOS this SHALL switch to the more tab and push the settings page.

#### Scenario: Close the prompt

- **WHEN** the user activates the left "close" action
- **THEN** the alert is dismissed and no navigation occurs

#### Scenario: Navigate to settings (iOS / iPadOS)

- **WHEN** the user activates the right "go to settings" action on iOS or iPadOS
- **THEN** the app switches to the more tab and pushes the settings page
