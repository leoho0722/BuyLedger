## ADDED Requirements

### Requirement: A feature-owned service is used only by its feature

A service whose data belongs to one feature SHALL live in that feature's Data folder and SHALL be obtained only by that feature's own types. Each feature SHALL have at most one service that is built on the database; the stored records of one feature belong to that service even when they are of several types. The four lookup kinds SHALL therefore be read and written through one lookup service owned by the lookups feature, and campaign reminder links through the campaign service. Services that wrap a system framework rather than the database are not counted. A feature that needs another feature's data or writes SHALL NOT obtain that feature's service: it SHALL read the root feature's projection, or ask the root feature through a delegate action so that the owning feature performs the work and reports the outcome. Services that do not belong to any single feature remain in the Core layer. The composition root and the test support are not subject to this rule, because wiring and overriding every service is their purpose.

A source scan SHALL enforce these rules. It SHALL map each service dependency to the folder that declares it, and SHALL fail when a source file under another feature's folder references that dependency, naming the file, the line, and the service. It SHALL also fail when a feature's Data folder declares more than one service built on the database, naming the feature and the services. Before matching, the scan SHALL strip comments and string literals, and when it cannot locate the source root or finds no service declaration it SHALL fail rather than skip.

#### Scenario: A feature that obtains another feature's service fails the scan

- **WHEN** a reducer under the campaigns feature declares a dependency on the order service
- **THEN** the scan fails, naming the file, the line, and the order service

#### Scenario: A feature obtains its own service

- **WHEN** a reducer under the lookups feature declares a dependency on the lookup service
- **THEN** the scan does not flag it

#### Scenario: Core services stay available to every feature

- **WHEN** a feature declares a dependency on a service declared under the Core layer, such as the currency metadata service
- **THEN** the scan does not flag it

#### Scenario: Cross-feature work goes through the root feature

- **WHEN** the order editor adds a new category
- **THEN** the order features ask the root feature through a delegate action, and the category is written by the lookup side's service rather than by an order feature

#### Scenario: A second database-backed service in a feature fails the scan

- **WHEN** a feature's Data folder declares two services whose live values obtain the database
- **THEN** the scan fails, naming the feature and both services

##### Example: database-backed services per feature after this change

| Feature | Database-backed services |
| ------- | ------------------------ |
| Campaigns | campaign service |
| Lookups | lookup service |
| Orders | order service |
| App | persistence recovery service |

#### Scenario: The lookup kinds share one service

- **WHEN** the lookups feature's stored data is inspected
- **THEN** order sources, categories, payment methods and reconciliation statuses are read and written through the single lookup service
