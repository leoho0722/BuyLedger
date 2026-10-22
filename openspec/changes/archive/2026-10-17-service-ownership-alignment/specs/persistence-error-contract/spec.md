## MODIFIED Requirements

### Requirement: Domain persistence errors preserve semantic failures

A feature whose service has semantic failures SHALL name its domain error after the feature. OrderService SHALL throw OrderError with identifierCollision(id:) when createOrder or mergeOrders finds an existing order identifier. Storage failures in those operations SHALL use the storage(PersistenceError) case of OrderError, and OrderError SHALL conform to the storage-failure wrapping protocol through that case so that the database write can wrap its own save failure. OrderError SHALL NOT conform to Equatable, and its semantic cases SHALL keep carrying the identifier that explains the failure.

A service without semantic failures SHALL throw the shared PersistenceError directly rather than a feature-named wrapper. LookupService is such a service: its payment method edit selects the affected orders from storage inside its own transaction, so no caller-supplied order identifier can be missing, and every failure it reports is a storage failure.

#### Scenario: Duplicate order creation remains a semantic error

- **GIVEN** an order with identifier order-001 already exists
- **WHEN** OrderService.createOrder receives another order with identifier order-001
- **THEN** the service throws OrderError.identifierCollision(id: "order-001")
- **AND** the existing record is not overwritten

#### Scenario: A domain write exposes a mapped storage failure

- **WHEN** a save fails during an OrderService write
- **THEN** the service throws OrderError with storage(PersistenceError.saveFailed) carrying the bridged source error
- **AND** the failed transaction's context is discarded without reaching the store

##### Example: Order save failure

- **GIVEN** SwiftData rejects saving an order because a relationship exceeds its maximum count
- **WHEN** `OrderService.createOrder` attempts the save
- **THEN** it throws `OrderError.storage(.saveFailed(underlying:))` whose underlying error has the same domain and code as the reported error
- **AND** a later fetch does not return the order

#### Scenario: A payment method edit reports storage failures directly

- **WHEN** a save fails during LookupService.applyPaymentMethodEdit
- **THEN** the service throws PersistenceError.saveFailed carrying the bridged source error
- **AND** neither the payment method nor any order from that transaction reaches the store
