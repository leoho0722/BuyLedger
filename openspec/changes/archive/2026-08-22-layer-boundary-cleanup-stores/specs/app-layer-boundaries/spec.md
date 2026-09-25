## ADDED Requirements

### Requirement: A store-bound view only receives its own feature's store

A view that binds to a feature store SHALL receive the store of the feature it belongs to, not the root store. Reading another feature's state or sending another feature's action from a view SHALL NOT be done.

Data a view needs from another feature SHALL be supplied as a read-only projection held in its own feature's state and synchronized in one direction by the root feature. A feature SHALL NOT write its own projections, so that the projected data has exactly one writer.

An intent that concerns another feature SHALL be expressed as a delegate action, which the root feature forwards to one of its existing navigation actions. Forwarding SHALL NOT introduce a parallel root action for an intent the root already handles.

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
- **THEN** it sends its own feature's action, whose delegate the root feature forwards to the existing action for that intent

#### Scenario: Forwarding does not add parallel root actions

- **WHEN** a delegate is forwarded for an intent the root feature already handles
- **THEN** it is forwarded to the existing action rather than to a newly added parallel one

#### Scenario: The root-host whitelist is exact

- **WHEN** the set of views declaring the root store is compared against the whitelist
- **THEN** any addition or removal fails the check

#### Scenario: Language is a parameter, not a projection

- **WHEN** a view needs the selected app language
- **THEN** it receives it as an initializer parameter
