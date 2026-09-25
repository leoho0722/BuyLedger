## ADDED Requirements

### Requirement: Unparsable stored raw values fail the read

A persistence record SHALL NOT substitute a default domain value when a stored raw value does not match any known case. When OrderRecord cannot resolve its stored payment receipt status, or CampaignRecord cannot resolve its stored campaign status, the conversion SHALL throw PersistenceError.fetchFailed and the enclosing read SHALL fail with that error.

The thrown error SHALL carry a dedicated record decoding error as its underlying value. That decoding error SHALL conform to Error and Sendable and SHALL carry four string values: the record type name, the identifier of the record that failed, the field name whose raw value could not be resolved, and the unresolved raw value itself. Because the application defines it, it SHALL be carried as the underlying value without being bridged to NSError, so that a caller can read those four values directly. PersistenceError SHALL NOT gain a new case for this failure.

#### Scenario: An unknown payment receipt status fails the read

- **GIVEN** a stored order row whose payment receipt status raw value matches no known case
- **WHEN** a caller fetches orders
- **THEN** the fetch throws PersistenceError.fetchFailed whose underlying value is the record decoding error
- **AND** that decoding error names the order record type, the identifier of that order, the payment receipt status field, and the unresolved raw value
- **AND** no order is returned with a substituted pending status

##### Example: Order row with a retired status string

- **GIVEN** an order row with identifier `order-001` stores `"legacy-status"` as its payment receipt status
- **WHEN** `OrderPersistence.fetchAll` performs the fetch
- **THEN** it throws `PersistenceError.fetchFailed` whose underlying decoding error carries record type `"OrderRecord"`, identifier `"order-001"`, field `"paymentReceiptStatus"`, and raw value `"legacy-status"`

#### Scenario: An unknown campaign status fails the read

- **GIVEN** a stored campaign row whose status raw value matches no known case
- **WHEN** a caller fetches campaigns
- **THEN** the fetch throws PersistenceError.fetchFailed whose underlying value is the record decoding error
- **AND** that decoding error names the campaign record type, the identifier of that campaign, the status field, and the unresolved raw value
- **AND** no campaign is returned with a substituted ongoing status

#### Scenario: Known raw values convert unchanged

- **WHEN** every stored raw value in a row matches a known case
- **THEN** the conversion returns the same domain value as before this change

##### Example: conversion outcome by stored raw value

| Stored raw value | Result |
| ---------------- | ------ |
| `"pending"` | converts to the pending case |
| `"received"` | converts to the received case |
| `"legacy-status"` | read throws `PersistenceError.fetchFailed` carrying the decoding error |
| `""` | read throws `PersistenceError.fetchFailed` carrying the decoding error |

## MODIFIED Requirements

### Requirement: Persistence storage failures use a shared typed error

The persistence layer SHALL expose PersistenceError as an Error and Sendable enum with fetchFailed, saveFailed, and containerCreationFailed cases. PersistenceError SHALL NOT conform to Equatable. Each case that wraps a failure SHALL carry that failure under an underlying label whose type is constrained to Error and Sendable, rather than only its localized description. A framework error SHALL be bridged to NSError when it is wrapped, so that its domain, code, and user info survive the boundary. An error type the application itself defines SHALL be carried without bridging, so that a caller can pattern-match its fields. SwiftData fetch failures SHALL map to fetchFailed, save failures SHALL map to saveFailed, and ModelContainer creation failures SHALL map to containerCreationFailed. Callers that need to distinguish cases SHALL pattern-match the case rather than compare whole values.

#### Scenario: A fetch failure is classified as a fetch failure

- **WHEN** a persistence actor cannot complete a SwiftData fetch
- **THEN** the actor throws PersistenceError.fetchFailed carrying the bridged source error

##### Example: Fetching an unreadable store

- **GIVEN** SwiftData reports a store-unavailable error
- **WHEN** `OrderPersistence.fetchAll` performs the fetch
- **THEN** it throws `PersistenceError.fetchFailed(underlying:)` whose underlying error has the same domain, code, and localized description as the error SwiftData reported

#### Scenario: A save failure is classified as a save failure

- **WHEN** a persistence actor cannot complete a SwiftData save
- **THEN** the actor throws PersistenceError.saveFailed carrying the bridged source error

##### Example: Saving a read-only store

- **GIVEN** SwiftData reports a read-only-store error
- **WHEN** `CampaignPersistence.upsert` saves a campaign
- **THEN** it throws `PersistenceError.saveFailed(underlying:)` whose underlying error has the same domain, code, and localized description as the error SwiftData reported

#### Scenario: A container creation failure is classified as a container failure

- **WHEN** PersistenceContainer cannot create a ModelContainer
- **THEN** the container factory maps the source error to PersistenceError.containerCreationFailed carrying the bridged error

##### Example: Invalid model configuration

- **GIVEN** ModelContainer creation reports an invalid-configuration error
- **WHEN** the persistence container factory creates a container
- **THEN** the operation maps it to `PersistenceError.containerCreationFailed(underlying:)` whose underlying error has the same domain and code as the reported error

#### Scenario: The original failure survives the boundary

- **WHEN** a caller inspects a thrown PersistenceError for diagnostics
- **THEN** the underlying value reports the domain, code, and user info of the failure the framework raised, not a message string reconstructed from it

### Requirement: Domain persistence errors preserve semantic failures

OrderPersistence SHALL throw OrderPersistenceError with identifierCollision(id:) when create or mergeOrders finds an existing order identifier. PaymentMethodPersistence SHALL throw PaymentMethodPersistenceError with orderNotFound(id:) when applyEdit receives an order identifier that is not present. Storage failures in those operations SHALL use the storage(PersistenceError) case of the corresponding domain error. These domain error types SHALL NOT conform to Equatable, and their semantic cases SHALL keep carrying the identifier that explains the failure.

#### Scenario: Duplicate order creation remains a semantic error

- **GIVEN** an order with identifier order-001 already exists
- **WHEN** OrderPersistence.create receives another order with identifier order-001
- **THEN** the actor throws OrderPersistenceError.identifierCollision(id: "order-001")
- **AND** the actor does not overwrite the existing record

#### Scenario: Missing order during payment method editing remains a semantic error

- **GIVEN** applyEdit receives an order with identifier order-404 and no matching stored order exists
- **WHEN** PaymentMethodPersistence.applyEdit processes the order
- **THEN** the actor throws PaymentMethodPersistenceError.orderNotFound(id: "order-404")
- **AND** the actor rolls back pending context changes

#### Scenario: A domain write exposes a mapped storage failure

- **WHEN** a save fails during an OrderPersistence or PaymentMethodPersistence operation
- **THEN** the actor throws the corresponding domain error with storage(PersistenceError.saveFailed) carrying the bridged source error
- **AND** the actor rolls back pending context changes for transactional writes

##### Example: Order save failure

- **GIVEN** saving an order reports a disk-full error
- **WHEN** `OrderPersistence.create` attempts the save
- **THEN** it throws `OrderPersistenceError.storage(.saveFailed(underlying:))` whose underlying error has the same domain and code as the reported error
- **AND** it rolls back the pending context changes

### Requirement: Currency metadata preserves cache and API error categories

CurrencyMetadataPersistence SHALL throw CurrencyMetadataPersistenceError.emptyCodeList when replace receives an empty code list and SHALL leave existing records unchanged. Other fetch and save failures SHALL use storage(PersistenceError). CurrencyMetadataRepository SHALL use CurrencyMetadataRepositoryError to distinguish api(APIError) from persistence(CurrencyMetadataPersistenceError). Neither error type SHALL conform to Equatable.

#### Scenario: An empty code list does not clear an existing cache

- **GIVEN** the cache contains TWD and USD
- **WHEN** CurrencyMetadataPersistence.replace receives an empty code list
- **THEN** the actor throws CurrencyMetadataPersistenceError.emptyCodeList
- **AND** the cache still contains TWD and USD

#### Scenario: An API failure is not classified as persistence failure

- **WHEN** CurrencyMetadataRepository cannot fetch supported codes because ExchangeRateClient throws a transport failure
- **THEN** the repository throws CurrencyMetadataRepositoryError.api carrying that transport failure

#### Scenario: A cache failure is not classified as an API failure

- **WHEN** CurrencyMetadataRepository cannot read or write its SwiftData cache
- **THEN** the repository throws CurrencyMetadataRepositoryError.persistence with the corresponding CurrencyMetadataPersistenceError

##### Example: Cache save failure

- **GIVEN** saving the currency cache reports a disk-full error
- **WHEN** `CurrencyMetadataRepository.forceRefresh` writes the fetched codes
- **THEN** it throws `CurrencyMetadataRepositoryError.persistence(.storage(.saveFailed(underlying:)))` whose underlying error has the same domain and code as the reported error

### Requirement: Persistence boundaries use complete typed throws contracts

Every throwing method in a persistence actor, PersistenceContainer throwing helper, PersistenceStoreQuarantine operation, or PersistenceStoreQuarantineClient closure SHALL declare a concrete typed throws contract that includes every error the boundary can emit. Raw SwiftData and Foundation errors SHALL NOT escape those boundaries as the thrown error type; a wrapped source error carried under an underlying label is not an escape, because the caller still receives the declared typed error. Repository dependency closures that only forward one persistence domain SHALL use the corresponding concrete typed error; a repository that combines API and persistence operations SHALL use a concrete wrapper for the complete union.

#### Scenario: A persistence-only repository exposes the persistence error type

- **WHEN** a caller invokes an OrderRepository operation that only forwards a persistence actor operation
- **THEN** the operation signature exposes PersistenceError or the appropriate OrderPersistenceError
- **AND** the operation does not expose any Error

##### Example: Fetching orders through the repository

- **GIVEN** `OrderPersistence.fetchAll` throws `PersistenceError.fetchFailed(underlying:)`
- **WHEN** `OrderRepository.fetchOrders` forwards the operation
- **THEN** its typed signature remains `throws(PersistenceError)`

#### Scenario: A combined repository exposes its complete error union

- **WHEN** a caller invokes CurrencyMetadataRepository.refreshIfStale
- **THEN** the operation signature exposes CurrencyMetadataRepositoryError
- **AND** the caller can distinguish API and persistence cases without inspecting an untyped error

##### Example: Distinguishing API and cache failures

- **GIVEN** the API can throw `.api` and the cache can throw `.persistence`
- **WHEN** the caller invokes `refreshIfStale`
- **THEN** the caller can pattern-match both cases on `CurrencyMetadataRepositoryError`

#### Scenario: Raw framework errors stop at the persistence boundary

- **WHEN** SwiftData or Foundation throws an error inside a persistence operation
- **THEN** the public operation throws one of its declared typed error cases
- **AND** the raw framework error reaches the caller only as the bridged underlying value of that typed case

##### Example: Foundation save error

- **GIVEN** Foundation reports a permission-denied error while writing a store file
- **WHEN** the quarantine operation handles the failure
- **THEN** it throws `PersistenceRecoveryError.fileMoveFailed` with the file name and that bridged error

### Requirement: Store quarantine uses a separate typed recovery error

PersistenceStoreQuarantine SHALL use PersistenceRecoveryError with directoryResolutionFailed, directoryCreationFailed, and fileMoveFailed(fileName:) cases, each carrying the bridged source error under an underlying label whose type is constrained to Error and Sendable. PersistenceRecoveryError SHALL NOT conform to Equatable. The operation SHALL return nil and SHALL NOT create a recovery directory when no known store file exists. PersistenceRecoveryError SHALL keep conforming to LocalizedError because its description is shown in the persistence failure screen, and that description SHALL remain the source error localized description.

#### Scenario: No store files require no recovery directory

- **GIVEN** the store directory contains none of the known store files
- **WHEN** PersistenceStoreQuarantine.quarantine runs
- **THEN** the operation returns nil
- **AND** the backup directory remains absent

#### Scenario: A file move failure identifies the file

- **WHEN** moving a known store file fails
- **THEN** the operation throws PersistenceRecoveryError.fileMoveFailed with that file name and the bridged source error

##### Example: Store sidecar cannot move

- **GIVEN** `BuyLedger.store-wal` cannot be moved and reports a permission-denied error
- **WHEN** quarantine processes the sidecar
- **THEN** it throws `PersistenceRecoveryError.fileMoveFailed(fileName: "BuyLedger.store-wal", underlying:)` whose underlying error has the same domain and code as the reported error

#### Scenario: Application Support resolution failure is classified as recovery failure

- **WHEN** PersistenceStoreQuarantineClient cannot resolve the Application Support directory
- **THEN** the client throws PersistenceRecoveryError.directoryResolutionFailed carrying the bridged source error

##### Example: Application Support lookup fails

- **GIVEN** FileManager reports a location-unavailable error
- **WHEN** the live quarantine client resolves Application Support
- **THEN** it throws `PersistenceRecoveryError.directoryResolutionFailed(underlying:)` whose underlying error has the same domain and code as the reported error

#### Scenario: The failure screen still shows a readable reason

- **WHEN** the persistence failure screen reports a recovery failure
- **THEN** the shown text is the localized description of the source error
