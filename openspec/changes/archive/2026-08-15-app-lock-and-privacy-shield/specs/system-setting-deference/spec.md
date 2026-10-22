## MODIFIED Requirements

### Requirement: System-level settings are not duplicated in the app

The app SHALL NOT provide its own control for a setting the system already manages at the system level, because a duplicate control leaves the user unsure whether the system setting applies. Appearance SHALL follow the system setting. The duplicate control and its stored preference SHALL both be removed.

The same deference applies to mechanisms, not only to settings. Where the system provides an authentication mechanism, the app SHALL use it rather than implementing its own passcode or credential flow, so that the user's existing biometric enrolment and device passcode apply without a second secret to manage.

#### Scenario: Appearance follows the system

- **WHEN** the user changes the system appearance between light and dark
- **THEN** the app follows the change, and no in-app appearance control exists in settings

#### Scenario: Removing the preference preserves other settings

- **WHEN** an existing installation that previously stored an appearance preference launches the updated app
- **THEN** all remaining preferences load with their previously stored values

#### Scenario: Authentication uses the system mechanism

- **WHEN** the app requires the user to authenticate
- **THEN** it invokes the system's local authentication rather than presenting its own passcode entry
