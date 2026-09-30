## ADDED Requirements

### Requirement: Core and Shared do not reference Feature types

The app's Core and Shared layers SHALL NOT reference any type declared under Features. Dependencies SHALL point downward only: a feature may use Core and Shared, and neither Core nor Shared may know that any particular feature exists.

When a type currently declared under a feature is needed by Core or Shared, it SHALL be moved down to the layer that needs it rather than referenced upward. An API client that a Core repository composes belongs in Core's networking layer; a fallback data table that a Core domain type reads belongs in Core's domain layer.

A composition root (the one place that wires every feature's dependencies to test doubles at launch) legitimately knows all features and therefore SHALL NOT live under Core. It SHALL live alongside the launch configuration it serves.

Documentation comments that name a feature type by symbol reference are not dependencies and SHALL NOT be treated as violations.

#### Scenario: A Core repository does not name a feature type

- **WHEN** a Core repository needs an API client that currently lives under a feature
- **THEN** the client is moved into Core's networking layer, and the repository's signature names no feature type

#### Scenario: A Core domain type does not read a feature-owned table

- **WHEN** a Core domain type reads a fallback table declared under a feature
- **THEN** the table is moved into Core's domain layer

#### Scenario: The test composition root lives outside Core

- **WHEN** the launch-time dependency-override harness is located
- **THEN** it sits alongside the launch configuration that calls it, not under Core, because it is a composition root rather than a Core concern

#### Scenario: Symbol references in documentation are not violations

- **WHEN** a Core or Shared file names a feature type inside a documentation comment
- **THEN** it is not reported, because a comment creates no dependency

### Requirement: Shared-layer membership has explicit criteria

A UI component SHALL be placed in the shared design system only when all three of the following hold: it does not bind to a feature store, it communicates with its caller through closures, and it references no Feature type. A component that fails any of the three SHALL stay with the feature that owns it.

A component that is used by more than one feature and meets all three criteria SHALL be moved to the shared layer rather than left under one feature's directory, because its location otherwise implies an ownership that does not exist.

A component carrying domain vocabulary in its parameters MAY still qualify, provided the vocabulary is expressed as plain parameters whose meaning is decided by the caller. Such a component SHALL state that in its file header, so that its presence is not read as license to move domain components into the shared layer.

A type used across features that depends on nothing from any feature, such as the app's language type and the view modifier built on it, SHALL live in the shared layer as a whole. Splitting the modifier from its type SHALL NOT be done, because the modifier's signature names the type and the split would only relocate the upward dependency from Core to Shared.

#### Scenario: A multi-feature picker moves to the shared layer

- **WHEN** a picker component is used by four features, binds to no store, communicates through closures, and references no feature type
- **THEN** it lives in the shared design system rather than under one feature's component directory

#### Scenario: A store-bound component stays with its feature

- **WHEN** a component binds to a feature store
- **THEN** it stays with that feature regardless of how many callers it has

#### Scenario: A type and the modifier built on it move together

- **WHEN** a cross-feature type and a view modifier taking that type as a parameter are relocated
- **THEN** both move to the shared layer together, and the modifier is not separated from its type

### Requirement: The layering direction is enforced by a source scan

The test suite SHALL include a scan that enumerates every top-level declaration under Features and fails when any of those names appears in a source file under Core or Shared. The scan SHALL enumerate the whole tree rather than checking a fixed list of known cases, so that a newly introduced violation is caught rather than only the ones already known.

Before comparing, the scan SHALL strip line comments, documentation comments, and block comments. It SHALL consider only declarations at zero indentation, so that names nested inside a type (which repeat across features) are not matched.

Failures SHALL name the file, the line, and the offending type. When the scan cannot locate the source root, it SHALL fail rather than skip, so that a path change cannot silently disable it.

The scan's coverage SHALL be bounded to Core and Shared; files under App are not scanned. This is a deliberate scope rather than an oversight: the composition root is a legitimate exception (see above) that references every feature and lives under App, so App has no reference boundary to enforce.

#### Scenario: A newly introduced upward reference fails the scan

- **WHEN** a file under Core or Shared starts referencing a type declared under Features
- **THEN** the scan fails, naming the file, the line, and the type

#### Scenario: Nested type names shared across features are not matched

- **WHEN** several features each declare a nested type with the same common name
- **THEN** the scan does not match those names, because it considers only declarations at zero indentation

#### Scenario: A missing source root fails rather than skips

- **WHEN** the scan cannot resolve the source root
- **THEN** it reports a failure instead of skipping

#### Scenario: Files under App are outside the scan's coverage

- **WHEN** a file under App references a Features type
- **THEN** the scan does not flag it, because App is outside the scan's bounded scope
