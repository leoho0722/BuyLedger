## ADDED Requirements

### Requirement: Locking and unlocking do not drive data loading

Replacing the content with the lock screen and revealing the content after authentication SHALL only switch what is displayed. Neither transition SHALL start, cancel, or retry a data load by itself. A load in progress when either transition happens SHALL continue and deliver its result to the screens that depend on it. A screen displayed after authentication SHALL load according to the same rules it follows whenever it appears, so a load that failed while the content was locked SHALL be retried only through those rules or through the retry controls of the screens that depend on it.

#### Scenario: Authentication success only reveals the content

- **GIVEN** ledger protection is on and the content is locked
- **WHEN** authentication succeeds
- **THEN** the lock screen is replaced with the content, and the lock feature issues no data load request and no request to the root of the App beyond its existing foreground notification

#### Scenario: Switching between the lock screen and the content keeps a load in progress

- **GIVEN** ledger protection is on and a launch data load is in progress while the lock screen is displayed
- **WHEN** authentication succeeds and the content replaces the lock screen before the load finishes
- **THEN** the load is neither cancelled nor restarted, and its result reaches the screens that depend on it

##### Example: delayed order read failure during a cold-start unlock

- **GIVEN** ledger protection is on, authentication succeeds after 4 seconds, and every order read fails after 8 seconds
- **WHEN** the App is launched and the content replaces the lock screen after authentication
- **THEN** the dashboard shows its loading indicator until the read finishes, then shows the order load failure message with a retry control and does not return to the loading indicator

#### Scenario: Locking in the background and unlocking keeps a load in progress

- **GIVEN** ledger protection is on, the content is displayed, and a launch data load is in progress
- **WHEN** the App moves to the background, which locks the content, and authentication succeeds after the App returns to the foreground, before the load finishes
- **THEN** the load is neither cancelled nor restarted, and its result reaches the screens that depend on it

##### Example: delayed order read failure across a background lock

- **GIVEN** ledger protection is on, authentication succeeds immediately, and every order read fails after 8 seconds
- **WHEN** the dashboard shows its loading indicator after launch, the App moves to the background, and it returns to the foreground 3 seconds after the loading indicator appeared
- **THEN** the dashboard shows its loading indicator after unlocking, then shows the order load failure message with a retry control when the read started before locking fails, and does not return to the loading indicator
