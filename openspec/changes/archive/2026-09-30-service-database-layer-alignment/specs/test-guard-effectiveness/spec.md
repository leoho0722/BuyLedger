## ADDED Requirements

### Requirement: A service a test does not override fails the test that calls it

When a unit test exercises code that calls a service closure the test did not override, the test SHALL fail at that call rather than receiving an empty or default value. A test SHALL override only the closures it expects to be called, and overriding one closure of a service SHALL leave that service's other closures failing when called. A test SHALL NOT disable exhaustive state checking to avoid overriding a closure.

#### Scenario: A missing override fails the test

- **GIVEN** a reducer whose load action calls `OrderService.fetchOrders`
- **WHEN** a test sends that action without overriding `fetchOrders`
- **THEN** the test fails and the failure names `OrderService.fetchOrders`

#### Scenario: Overriding one closure keeps the others strict

- **GIVEN** a test that overrides only `OrderService.saveOrder`
- **WHEN** the code under test also calls `OrderService.removeOrder`
- **THEN** the test fails and the failure names `OrderService.removeOrder`

### Requirement: The unit test host does not run the app launch flow

When the app process runs as the host of unit tests, it SHALL NOT create the root feature store, resolve the production persistence bootstrap, read stored settings, or configure telemetry, so that no service is called outside a running test and the production store is not opened by the host. When the app is launched normally or by UI tests, the launch flow SHALL run unchanged.

#### Scenario: The unit test host shows an empty scene

- **WHEN** the app launches as the host of the unit test bundle
- **THEN** no root feature store is created and no service closure is called during launch

#### Scenario: UI test launches keep the normal flow

- **WHEN** the app is launched by a UI test with the UI test launch argument
- **THEN** the root interface appears with the injected test dependencies as before
