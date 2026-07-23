## ADDED Requirements

### Requirement: System-level settings are not duplicated in the app

The app SHALL NOT provide its own control for a setting the system already manages at the system level, because a duplicate control leaves the user unsure whether the system setting applies. Appearance SHALL follow the system setting. The duplicate control and its stored preference SHALL both be removed.

#### Scenario: Appearance follows the system

- **WHEN** the user changes the system appearance between light and dark
- **THEN** the app follows the change, and no in-app appearance control exists in settings

#### Scenario: Removing the preference preserves other settings

- **WHEN** an existing installation that previously stored an appearance preference launches the updated app
- **THEN** all remaining preferences load with their previously stored values

### Requirement: Prompts directing users to system settings provide a way there

When a message instructs the user to change a setting in the system Settings app, it SHALL provide a control that opens the relevant settings destination. The user SHALL NOT be required to locate the destination unaided.

#### Scenario: Calendar permission prompt offers a shortcut

- **WHEN** the calendar permission denial message is shown
- **THEN** it offers a control that opens this app's system settings page, alongside the existing dismissal action

#### Scenario: Prompt remains dismissible if settings cannot open

- **WHEN** the settings destination cannot be opened
- **THEN** the message remains dismissible through its existing dismissal action
