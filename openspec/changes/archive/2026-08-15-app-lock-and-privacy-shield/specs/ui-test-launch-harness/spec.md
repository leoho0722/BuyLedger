## MODIFIED Requirements

### Requirement: External dependency doubles in UI test mode

In UI test mode the app SHALL replace the photo import, calendar reminder, exchange rate, and local authentication dependencies with doubles that never present system UI and never perform network requests. The calendar double's authorisation outcome SHALL be selectable through a launch argument.

The local authentication double SHALL never present a system biometric prompt, and its outcome SHALL be selectable through a launch argument so that both the success and the failure paths of ledger protection can be exercised. Whether protection starts enabled SHALL likewise be selectable, so that the locked launch state can be reached without first driving the settings screen.

#### Scenario: Photo import does not present the system picker

- **WHEN** the user taps the add-photos control in UI test mode
- **THEN** the built-in test images are attached directly and no out-of-process picker appears

#### Scenario: Calendar reminder does not prompt for permission

- **WHEN** the user saves a campaign with a reminder in UI test mode
- **THEN** no system permission dialog appears and no event is written to the device calendar

#### Scenario: Calendar authorisation denial is selectable

- **WHEN** the app launches in UI test mode with the calendar denial argument and the user saves a campaign with a reminder
- **THEN** the app shows its permission-denied handling without presenting a system dialog

#### Scenario: Authentication never prompts and its outcome is selectable

- **WHEN** the app launches in UI test mode with an authentication outcome argument and protection is engaged
- **THEN** no system biometric prompt appears and the app follows the selected outcome

#### Scenario: The locked launch state is reachable directly

- **WHEN** the app launches in UI test mode with protection preset to enabled
- **THEN** the app starts in its locked state without the test having to enable protection through the settings screen
