## ADDED Requirements

### Requirement: Features reach storage and the network only through services

Feature types and views SHALL obtain persistence, network, preference, and configuration access only through service dependencies. Outside the Data folder of a feature, no source file under Features SHALL reference the database, HTTP client, user defaults store, or app configuration store dependencies, and none SHALL reference SwiftData context or container types. No service SHALL obtain another service as a dependency. Client, store, and database types SHALL expose only technical operations, so that an operation whose signature carries a business term belongs to a service instead.

A source scan SHALL enforce the feature and service rules across the whole source tree. Before matching, the scan SHALL strip line, documentation, and block comments. Failures SHALL name the file, the line, and the offending reference. When the scan cannot locate the source root, it SHALL fail rather than skip.

#### Scenario: A feature reducer that reads the database directly fails the scan

- **WHEN** a reducer under Features outside a Data folder declares a dependency on the database
- **THEN** the scan fails, naming the file, the line, and the database reference

#### Scenario: A service inside a feature's Data folder may use the database

- **WHEN** a service file under a feature's Data folder declares a dependency on the database
- **THEN** the scan does not flag it

#### Scenario: A service that depends on another service fails the scan

- **WHEN** a service's live value declares a dependency on another service
- **THEN** the scan fails, naming the file, the line, and the service reference

#### Scenario: A missing source root fails rather than skips

- **WHEN** the scan cannot resolve the source root
- **THEN** it reports a failure instead of skipping

### Requirement: Dependencies are accessed through dependency value properties

Every dependency SHALL be registered with a dependency key and accessed through a DependencyValues property, in production code and in tests alike. Type-subscript access to a dependency SHALL NOT appear anywhere except inside the DependencyValues property accessors of a file whose name ends in `+Dependency.swift`. Every service SHALL declare a test value whose closures are all unimplemented; client, store, and database registrations SHALL NOT declare a test value. No source file SHALL reference a shared static persistence container accessor. A source scan SHALL enforce these rules across the app and unit test sources, with the same comment stripping and missing-root behavior as the feature scan.

#### Scenario: Type-subscript access outside a dependency accessor fails the scan

- **WHEN** a reducer or a test reads or overrides a dependency by subscripting with the dependency type
- **THEN** the scan fails, naming the file, the line, and the dependency type

##### Example: What the subscript rule matches

| Source text | Location | Scan result |
| ----------- | -------- | ----------- |
| `@Dependency(OrderService.self) private var orderService` | a reducer | fails |
| `$0[OrderService.self].fetchOrders = { [] }` | a test | fails |
| `get { self[OrderService.self] }` | `OrderService+Dependency.swift` | passes |
| `Schema([OrderRecord.self, CampaignRecord.self])` | a persistence file | passes |

#### Scenario: A service test value with a working default fails the scan

- **WHEN** a service's test value supplies a closure that is not unimplemented
- **THEN** the scan fails, naming the service and the closure

#### Scenario: A client registration that declares a test value fails the scan

- **WHEN** a client, store, or database dependency file declares a test value
- **THEN** the scan fails, naming the file

#### Scenario: A shared container accessor fails the scan

- **WHEN** a source file references a shared static persistence container accessor
- **THEN** the scan fails, naming the file and the line
