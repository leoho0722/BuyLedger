## MODIFIED Requirements

### Requirement: A store-bound view only receives its own feature's store

A view that binds to a feature store SHALL receive the store of the feature it belongs to, not the root store. Reading another feature's state or sending another feature's action from a view SHALL NOT be done.

Data a view needs from another feature SHALL be supplied as a read-only projection held in its own feature's state and synchronized in one direction by the root feature. A feature SHALL NOT write its own projections, so that the projected data has exactly one writer.

An intent that concerns another feature SHALL be expressed as a delegate action, which the root feature handles by calling a shared navigation operation, the same one that every other source of that intent uses, rather than by sending itself a root action. Handling a delegated intent SHALL NOT introduce a parallel root action for an intent the root already handles.

Root navigation hosts are the exception: a view whose role is to own a navigation path and to scope child stores for its destinations MAY declare the root store. The set of such hosts SHALL be an exact, enumerated whitelist; adding a host and removing one are both violations, so that the exception cannot quietly widen.

Purely presentational values that are not state, such as the selected app language, SHALL be passed as initializer parameters rather than projected.

#### Scenario: A feature view no longer names the root store

- **WHEN** a view that presents one feature's content is inspected
- **THEN** it declares that feature's store, not the root store

#### Scenario: Cross-feature data arrives as a read-only projection

- **WHEN** a view needs data owned by another feature
- **THEN** it reads a projection held in its own feature's state, and only the root feature writes that projection

#### Scenario: A single upstream change updates every projection

- **WHEN** the orders collection changes once
- **THEN** every feature holding an orders projection is updated in that same change, so no surface can display stale data

#### Scenario: Cross-feature intent travels as a delegate

- **WHEN** a view needs to act on another feature, for example toggling an order's receipt status from a campaign surface
- **THEN** it sends its own feature's action, and the root feature handles that action's delegate directly instead of re-sending the intent as an action of its own

#### Scenario: A delegated intent reuses one navigation operation

- **WHEN** two features delegate the same navigation intent to the root feature
- **THEN** both are handled by the same navigation operation, produce the same navigation state, and cause no further root action to be received

##### Example: two sources open the same campaign

- **GIVEN** a campaign named "四月韓國團" exists and the campaigns tab shows its list
- **WHEN** the overview sends `.delegate(.campaignTapped("四月韓國團"))`, and in a separate run the insights screen sends `.delegate(.campaignTapped("四月韓國團"))`
- **THEN** in both runs the selected tab becomes the campaigns tab, the campaign navigation stack holds exactly one element, the detail of "四月韓國團", and no action is received after the delegate

#### Scenario: The root-host whitelist is exact

- **WHEN** the set of views declaring the root store is compared against the whitelist
- **THEN** any addition or removal fails the check

#### Scenario: Language is a parameter, not a projection

- **WHEN** a view needs the selected app language
- **THEN** it receives it as an initializer parameter

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

- **WHEN** the root feature needs the settings feature to hold the persisted settings
- **THEN** the persisted settings are held by the root state from launch and supplied when the settings state is constructed, and no action is sent to the settings feature to load them

##### Example: launch with stored settings

- **GIVEN** English is stored as the interface language
- **WHEN** the root feature handles its launch action
- **THEN** no settings action is received, the root state's preferences already hold English, and the settings state is built from them when the settings screen is pushed

#### Scenario: A child asks its parent through a delegate

- **WHEN** the customers screen appears and needs the orders it summarizes to be loaded
- **THEN** the customers feature emits a delegate action that its host feature relays, and the root feature forwards it to the existing orders load, without intercepting the customers feature's appearance action

##### Example: customers screen appears

- **GIVEN** the customers screen is pushed from the More tab
- **WHEN** it sends `.view(.task)`
- **THEN** the customers feature emits `.delegate(.ordersLoadRequested)`, the More feature relays it, and the root feature sends the orders load once

#### Scenario: A parent does not react to a child's alert action

- **WHEN** the user chooses an alert button whose effect belongs to another feature
- **THEN** the child feature turns the choice into a delegate action, and the parent reacts only to that delegate, not to the child's alert action

##### Example: opening AI settings from the orders screen

- **GIVEN** the AI summary is turned off and the orders screen shows the alert explaining it
- **WHEN** the user taps the alert button that opens settings
- **THEN** the orders feature emits `.delegate(.aiSettingsRequested)`, and the root feature selects the More tab with exactly one settings screen pushed, without matching the orders feature's alert action

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
