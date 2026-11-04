## MODIFIED Requirements

### Requirement: A store-bound view only receives its own feature's store

A view that binds to a feature store SHALL receive the store of the feature it belongs to, not the root store. Reading another feature's state or sending another feature's action from a view SHALL NOT be done.

Data a view needs from another feature SHALL be supplied as a read-only projection held in its own feature's state and synchronized in one direction by the root feature. A feature SHALL NOT write its own projections, so that the projected data has exactly one writer.

An intent that concerns another feature SHALL be expressed as a delegate action, which the root feature handles by calling a shared navigation operation, the same one that every other source of that intent uses, rather than by sending itself a root action. Handling a delegated intent SHALL NOT introduce a parallel root action for an intent the root already handles.

Root navigation hosts are the exception: RootView and RootNavigationLayout SHALL be the exact final set of views declaring the root store. Their role SHALL be root destination selection and scoping child stores. Feature-owned split navigation SHALL receive only its own feature store. The source guard SHALL compare the actual hosts with an exact enumerated whitelist and fail on either an addition or a removal. During staged migration the reviewed whitelist SHALL name the actual old and new hosts explicitly; once migration finishes it SHALL contain only RootView and RootNavigationLayout.

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

#### Scenario: Feature split navigation does not receive the root store

- **GIVEN** orders, campaigns and More each own a split navigation container
- **WHEN** their navigation views are inspected
- **THEN** each view declares only its own feature store and sends cross-feature intents through delegates
- **AND** the final root-host whitelist contains exactly RootView and RootNavigationLayout
