## MODIFIED Requirements

### Requirement: Load failure is surfaced with a reason and a recovery path

When a screen depends on data that fails to load, the screen SHALL display an explanation of the failure together with a control that retries the load. It SHALL NOT remain in a loading state indefinitely. Screens SHALL distinguish three states (loaded, failed, and loading) rather than inferring failure from the absence of a loaded flag. A screen whose entire content is derived from a shared load SHALL present that load's loading and failed states, and SHALL NOT present its empty state while the load is in progress or after it has failed. A screen moving between its loading and failed states SHALL NOT by itself start another load request. A load whose result is shared with other screens SHALL deliver its result to those screens even when the screen that requested it is no longer displayed, so that leaving a screen during such a load SHALL NOT leave any screen in the loading state indefinitely. Replacing the visible content with the lock screen, or revealing the content after authentication, SHALL NOT cancel such a load either. A screen whose state is kept while the screen is hidden, such as a tool left open under the more tab while the user switches to another tab, SHALL NOT be left in the loading state indefinitely because it was hidden during a load: the load SHALL either deliver its result to that kept state or be started again when the screen is shown again.

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

#### Scenario: Order list failure is not shown as an empty result

- **WHEN** order loading fails and the order list is presented
- **THEN** the order list shows the order load failure message with a retry control, and does not show the empty state that suggests changing the search or filters

##### Example: persistent order read failure

- **GIVEN** the App is launched with every order read failing and no order has ever loaded
- **WHEN** the user opens the orders tab
- **THEN** the order list shows the text of `orders.general.message.ordersLoadedTry` and a retry control, and does not show the text of `orders.list.message.tryChangingSearch`

#### Scenario: Customers screen failure is not shown as an empty result

- **WHEN** order loading fails and the customers screen is presented
- **THEN** the customers screen shows the order load failure message with a retry control, and does not show the empty state that suggests creating an order

##### Example: persistent order read failure on the customers screen

- **GIVEN** the App is launched with every order read failing and no order has ever loaded
- **WHEN** the user opens the customers screen under the more tab
- **THEN** the customers screen shows the text of `orders.general.message.ordersLoadedTry` and a retry control, and does not show the text of `customers.list.message.createOrderSee`

#### Scenario: Customers screen shows loading while orders are still loading

- **GIVEN** every order read fails only after a delay, and the order load failure has already been shown once
- **WHEN** the user opens the customers screen, which starts a new order read, while that read is still in progress
- **THEN** the customers screen shows a loading indicator and does not show its empty state
- **THEN** once the read finishes, the customers screen shows the order load failure message with a retry control

#### Scenario: Switching tabs after a load failure does not start a reload loop

- **GIVEN** every order read fails and the App has been launched with the dashboard as the first tab
- **WHEN** the user switches to the orders tab, then to the more tab, then back to the orders tab, then to the dashboard tab, then to the insights tab
- **THEN** after the order list first shows the order load failure message, it keeps showing that message with a retry control and no loading indicator
- **THEN** the dashboard and the insights screen each keep showing their failure message with a retry control and no loading indicator once their failure first appears

#### Scenario: Leaving a screen during a shared load keeps the load result

- **GIVEN** every order read fails only after a delay, and the order load failure has already been shown once
- **WHEN** the user opens a screen that starts a new order read (the insights tab, or the customers screen under the more tab) and leaves it while the order list still shows its loading indicator
- **THEN** once the read finishes, the order list shows the order load failure message instead of staying in the loading state

#### Scenario: Revealing the content after authentication during a launch load keeps the load result

- **GIVEN** ledger protection is on, authentication succeeds only after a short delay, and every order read fails only after a longer delay
- **WHEN** the App is launched and authentication succeeds while the launch's order read is still in progress
- **THEN** once the read finishes, the dashboard shows the order load failure message with a retry control instead of staying in the loading state

#### Scenario: Switching tabs during a tool's exchange rate read keeps the read result

- **GIVEN** every exchange rate read fails only after a delay
- **WHEN** the user opens a tool that reads exchange rates under the more tab, switches to another root tab while the tool shows its loading indicator, and switches back to the more tab before the read finishes
- **THEN** once the read finishes, the tool shows its exchange rate failure message with a retry control, and does not return to the loading indicator

##### Example: tools that read exchange rates

| Tool | Failure message after the delayed read fails | Retry control |
| ---- | -------------------------------------------- | ------------- |
| exchange rate screen | text of `fx.rates.message.networkErrorOccurred` | shown in the status banner |
| quote screen | text of `quote.calculator.message.networkErrorOccurred` | shown in the status banner |
