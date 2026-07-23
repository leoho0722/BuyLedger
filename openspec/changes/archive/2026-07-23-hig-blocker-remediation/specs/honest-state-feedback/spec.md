## ADDED Requirements

### Requirement: Controls without backing behavior are not presented

The interface SHALL NOT present a control whose state has no effect on system behavior. A preference toggle SHALL only be shown when changing it produces an observable outcome. Where no such behavior exists, the control and its underlying preference field SHALL both be removed, so that a later implementer does not mistake a leftover field for existing functionality.

#### Scenario: Order reminder toggle is removed

- **WHEN** the settings screen is presented
- **THEN** no notification section or order reminder toggle appears, because no notification authorization or scheduling exists to back it

#### Scenario: Preference field is removed alongside the control

- **WHEN** the settings state, its snapshot type, and its preference storage are inspected after the change
- **THEN** none of them retains a field for the removed toggle

#### Scenario: Removing the field does not disturb other preferences

- **WHEN** an existing installation that previously stored the removed preference launches the updated app
- **THEN** all remaining preferences load with their previously stored values

### Requirement: Load failure is surfaced with a reason and a recovery path

When a screen depends on data that fails to load, the screen SHALL display an explanation of the failure together with a control that retries the load. It SHALL NOT remain in a loading state indefinitely. Screens SHALL distinguish three states — loaded, failed, and loading — rather than inferring failure from the absence of a loaded flag.

#### Scenario: Dashboard surfaces an order load failure

- **WHEN** order loading fails and the dashboard is presented
- **THEN** the dashboard shows a failure message carrying the underlying error text, together with a retry control, instead of a spinner

#### Scenario: Insights surfaces an order load failure

- **WHEN** order loading fails and the insights screen is presented
- **THEN** the insights screen shows a failure message carrying the underlying error text, together with a retry control, instead of a spinner

#### Scenario: Retry restores normal content

- **WHEN** the user activates the retry control and the subsequent load succeeds
- **THEN** the screen replaces the failure state with its normal content

#### Scenario: Repeated failure does not loop

- **WHEN** the user activates the retry control and the subsequent load fails again
- **THEN** the screen shows the failure state again without entering an automatic retry loop and without clearing the error message

##### Example: state resolution order

| Loaded | Error present | Resulting screen state |
| ------ | ------------- | ---------------------- |
| yes | no | normal content |
| no | yes | failure message with retry |
| no | no | loading indicator |

### Requirement: Error messages describe the actual failure

An error message SHALL describe the failure that actually occurred. A message SHALL NOT attribute a failure to a cause that was not the cause, and SHALL NOT instruct the user to take a corrective action that cannot resolve the stated failure.

#### Scenario: Failure unrelated to permission does not mention permission

- **WHEN** an operation fails for a reason other than a denied permission
- **THEN** the message describes that failure and does not direct the user to change permission settings
