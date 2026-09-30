## ADDED Requirements

### Requirement: Feature actions are grouped by who is allowed to send them

A feature's actions SHALL be grouped by their sender. User interactions SHALL form one group that only the feature's own views send. Results meant for the parent SHALL form a delegate group that only the feature's own reducer sends. Responses from the feature's own effects SHALL be separate cases that only those effects send, and one request's success and failure SHALL be a single response case carrying the outcome rather than two cases.

A parent feature SHALL NOT send a child feature's user-interaction actions and SHALL NOT react to them; it SHALL react only to the child's delegate actions. When a parent needs a child to hold data from the moment it exists, such as settings read at launch, that data SHALL be supplied when the child's state is constructed rather than by sending the child an action afterwards. When a child needs the parent to do something, such as loading orders its screen depends on, it SHALL ask through a delegate action that the parent forwards.

This convention SHALL be enforced by a source scan over the features that have adopted it. The set of adopted features SHALL be listed explicitly and SHALL only grow; an adopted view SHALL NOT be exempted except through a named allowlist entry that states why and when it is removed.

#### Scenario: A view only sends user-interaction actions

- **WHEN** a view of an adopted feature sends an action to its store
- **THEN** the action is in the feature's user-interaction group, and form values and focus are written through the store's bindings rather than by constructing binding actions by hand

##### Example: dismissing the keyboard on the exchange rate screen

- **GIVEN** the amount field has focus
- **WHEN** the user taps the keyboard's done button
- **THEN** the view writes `false` to the store's focus binding and sends no hand-built binding action

#### Scenario: A retry is its own user interaction

- **WHEN** the user taps a retry control on a screen whose initial load failed
- **THEN** the view sends a retry interaction, not the action that represents the screen appearing

##### Example: exchange rate retry

- **GIVEN** the latest-rate request failed and the retry control is shown
- **WHEN** the user taps retry
- **THEN** the exchange rate feature receives `.view(.retryTapped)`, not `.view(.task)`

#### Scenario: A parent does not send a child's user-interaction action

- **WHEN** the root feature needs the settings feature to hold the persisted settings at launch
- **THEN** the persisted settings are supplied when the settings state is constructed, and the root feature sends the settings feature no action to load them

##### Example: launch with stored settings

- **GIVEN** English is stored as the interface language
- **WHEN** the root feature handles its launch action
- **THEN** no settings action is received, and the settings state already holds English

#### Scenario: A child asks its parent through a delegate

- **WHEN** the customers screen appears and needs the orders it summarizes to be loaded
- **THEN** the customers feature emits a delegate action and the root feature forwards it to the existing orders load, without intercepting the customers feature's appearance action

##### Example: customers screen appears

- **GIVEN** the customers screen is pushed from the More tab
- **WHEN** it sends `.view(.task)`
- **THEN** the customers feature emits `.delegate(.ordersLoadRequested)` and the root feature sends the orders load once

#### Scenario: One request has one response case

- **WHEN** an exchange rate request completes, successfully or not
- **THEN** a single response action carrying the result is received, and the failure message is derived from the error inside the reducer

##### Example: transport failure

- **GIVEN** the exchange rate client fails with a transport error
- **WHEN** the screen loads
- **THEN** `.ratesResponse(.failure)` is received and the error message shown is the existing transport-failure text

#### Scenario: The scan detects a view sending a non-interaction action

- **WHEN** an adopted feature's view is temporarily changed to send a binding action it constructs by hand
- **THEN** the scan fails, naming the file and the offending send, and it passes again once the change is reverted

#### Scenario: The scan detects a parent sending a child's interaction

- **WHEN** a reducer is temporarily changed to send a child feature's user-interaction action
- **THEN** the scan fails, and it passes again once the change is reverted

##### Example: sends the scan classifies

| Source fragment | Checked as | Result |
| --------------- | ---------- | ------ |
| `await store.send(.view(.task)).finish()` in an adopted view | view send | allowed |
| `store.send(` followed on the next line by `.view(.retryTapped))` | view send | allowed |
| `store.send(.binding(.set(\.isFocused, false)))` in an adopted view | view send | violation |
| `store.send(.delegate(.customerSelected(name)))` in an adopted view | view send | violation |
| `return .send(.view(.task))` inside a feature's own reducer | reducer send | allowed |
| `.send(.settings(.view(.task)))` inside the root reducer | reducer send | violation |
| `case .customers(.view(.task)):` inside the root reducer | reducer match | violation |

#### Scenario: An exemption is explicit and temporary

- **WHEN** an adopted view still sends a child action whose owner has not yet adopted the convention
- **THEN** that send is permitted only by an allowlist entry naming the view, the action, and the step that removes it

#### Scenario: An unused exemption fails the scan

- **WHEN** an allowlist entry no longer matches any send in its view
- **THEN** the scan fails, so that a stale exemption cannot remain as a loophole
