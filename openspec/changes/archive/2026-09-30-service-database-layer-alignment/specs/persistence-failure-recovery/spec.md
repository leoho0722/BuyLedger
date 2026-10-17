## MODIFIED Requirements

### Requirement: A single production container is resolved once per process

The app-level persistence bootstrap SHALL be resolved exactly once per process. The database dependency's live value SHALL be the only production consumer of the container from that resolution, and every service SHALL reach storage only through the database dependency. The factory that constructs the production container SHALL NOT be reachable from outside the persistence bootstrap, and the container SHALL NOT be exposed through a shared static accessor.

#### Scenario: Repeated access returns the same container

- **WHEN** the persistence bootstrap is accessed more than once during a process lifetime
- **THEN** every access returns the same container instance

#### Scenario: Services do not construct or share their own production container

- **WHEN** a service needs storage
- **THEN** it performs its work through the database dependency rather than invoking the production container factory
- **AND** no source file references a shared static container accessor

#### Scenario: The app scene does not attach the production container

- **WHEN** the app builds its window scene
- **THEN** it does not attach the production container to the view hierarchy
- **AND** it reads only the bootstrap status to decide whether to block the normal interface
