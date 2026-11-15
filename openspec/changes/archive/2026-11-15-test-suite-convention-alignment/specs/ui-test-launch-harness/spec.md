## MODIFIED Requirements

### Requirement: Load failure injection

The app SHALL accept a launch argument that makes the declared repository read fail, so that the load failure view and its retry control can be exercised. When the argument is absent, reads SHALL succeed normally. When the declared failure delays each read before failing, the delay duration SHALL be supplied by the launch options as a launch argument and the app SHALL wait at least that duration before failing; the app SHALL NOT keep its own copy of the duration, so that the UI test that sets the duration and the timeouts derived from it share a single source.

#### Scenario: Injected failure surfaces the failure view

- **WHEN** the app launches in UI test mode with the load failure argument for the orders repository
- **THEN** the orders screen shows the load failure view together with its retry control

#### Scenario: Retry after injected failure

- **WHEN** the load failure argument declares that only the first read fails and the user taps retry
- **THEN** the orders screen loads the seeded orders successfully

#### Scenario: The read delay comes from the launch options

- **GIVEN** launch options that declare delayed failing reads for the exchange rates with a delay of 8 seconds
- **WHEN** the app launches in UI test mode and the rates screen starts a read
- **THEN** the read stays loading for at least 8 seconds before it fails, and the test's waiting timeouts are computed from the same 8-second value in the launch options

##### Example: launch arguments for a delayed read

| Launch options | Arguments passed to the app | Delay applied by the app |
| -------------- | --------------------------- | ------------------------ |
| delayed failing orders reads, 8 seconds | `-BLUITestLoadFailure ordersDelayed -BLUITestReadDelaySeconds 8` | at least 8 seconds |
| delayed failing exchange rate reads, 12 seconds | `-BLUITestLoadFailure exchangeRatesDelayed -BLUITestReadDelaySeconds 12` | at least 12 seconds |
| no load failure | no delay argument | none |

#### Scenario: A delayed failure without a valid duration applies no built-in delay

- **GIVEN** a delayed failing read argument with the delay duration argument missing, or with a value that is not a positive whole number of seconds
- **WHEN** the UI test configuration parses the launch arguments
- **THEN** it prints a warning naming the delay argument, and the app applies no delay instead of a built-in duration

#### Scenario: A duration without a delayed failure is ignored

- **GIVEN** the delay duration argument while the load failure argument is absent or names a failure that does not delay
- **WHEN** the UI test configuration parses the launch arguments
- **THEN** it prints a warning that the duration has no delayed failure to apply to, and reads behave as the load failure argument alone declares
