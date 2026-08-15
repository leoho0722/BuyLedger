## ADDED Requirements

### Requirement: Persistence storage failures use a shared typed error

The persistence layer SHALL expose PersistenceError as an Error, Equatable, and Sendable enum with fetchFailed(message:), saveFailed(message:), and containerCreationFailed(message:) cases. SwiftData fetch failures SHALL map to fetchFailed, save failures SHALL map to saveFailed, and ModelContainer creation failures SHALL map to containerCreationFailed. Each mapped case SHALL preserve the source error localized description in message.

#### Scenario: A fetch failure is classified as a fetch failure

- **WHEN** a persistence actor cannot complete a SwiftData fetch
- **THEN** the actor throws PersistenceError.fetchFailed with the source localized description

##### Example: Fetching an unreadable store

- **GIVEN** SwiftData reports `"store unavailable"`
- **WHEN** `OrderPersistence.fetchAll` performs the fetch
- **THEN** it throws `PersistenceError.fetchFailed(message: "store unavailable")`

#### Scenario: A save failure is classified as a save failure

- **WHEN** a persistence actor cannot complete a SwiftData save
- **THEN** the actor throws PersistenceError.saveFailed with the source localized description

##### Example: Saving a read-only store

- **GIVEN** SwiftData reports `"read-only store"`
- **WHEN** `CampaignPersistence.upsert` saves a campaign
- **THEN** it throws `PersistenceError.saveFailed(message: "read-only store")`

#### Scenario: A container creation failure is classified as a container failure

- **WHEN** PersistenceContainer cannot create a ModelContainer
- **THEN** the container factory maps the source error to PersistenceError.containerCreationFailed with the source localized description

##### Example: Invalid model configuration

- **GIVEN** ModelContainer creation reports `"invalid configuration"`
- **WHEN** the persistence container factory creates a container
- **THEN** the operation maps it to `PersistenceError.containerCreationFailed(message: "invalid configuration")`

### Requirement: Domain persistence errors preserve semantic failures

OrderPersistence SHALL throw OrderPersistenceError with identifierCollision(id:) when create or mergeOrders finds an existing order identifier. PaymentMethodPersistence SHALL throw PaymentMethodPersistenceError with orderNotFound(id:) when applyEdit receives an order identifier that is not present. Storage failures in those operations SHALL use the storage(PersistenceError) case of the corresponding domain error.

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
- **THEN** the actor throws the corresponding domain error with storage(PersistenceError.saveFailed(message:))
- **AND** the actor rolls back pending context changes for transactional writes

##### Example: Order save failure

- **GIVEN** saving an order reports `"disk full"`
- **WHEN** `OrderPersistence.create` attempts the save
- **THEN** it throws `OrderPersistenceError.storage(.saveFailed(message: "disk full"))`
- **AND** it rolls back the pending context changes

### Requirement: Currency metadata preserves cache and API error categories

CurrencyMetadataPersistence SHALL throw CurrencyMetadataPersistenceError.emptyCodeList when replace receives an empty code list and SHALL leave existing records unchanged. Other fetch and save failures SHALL use storage(PersistenceError). CurrencyMetadataRepository SHALL use CurrencyMetadataRepositoryError to distinguish api(APIError) from persistence(CurrencyMetadataPersistenceError).

#### Scenario: An empty code list does not clear an existing cache

- **GIVEN** the cache contains TWD and USD
- **WHEN** CurrencyMetadataPersistence.replace receives an empty code list
- **THEN** the actor throws CurrencyMetadataPersistenceError.emptyCodeList
- **AND** the cache still contains TWD and USD

#### Scenario: An API failure is not classified as persistence failure

- **WHEN** CurrencyMetadataRepository cannot fetch supported codes because ExchangeRateClient throws APIError.transport(message: "network unavailable")
- **THEN** the repository throws CurrencyMetadataRepositoryError.api(APIError.transport(message: "network unavailable"))

#### Scenario: A cache failure is not classified as an API failure

- **WHEN** CurrencyMetadataRepository cannot read or write its SwiftData cache
- **THEN** the repository throws CurrencyMetadataRepositoryError.persistence with the corresponding CurrencyMetadataPersistenceError

##### Example: Cache save failure

- **GIVEN** saving the currency cache reports `"disk full"`
- **WHEN** `CurrencyMetadataRepository.forceRefresh` writes the fetched codes
- **THEN** it throws `CurrencyMetadataRepositoryError.persistence(.storage(.saveFailed(message: "disk full")))`

### Requirement: Persistence boundaries use complete typed throws contracts

Every throwing method in a persistence actor, PersistenceContainer throwing helper, PersistenceStoreQuarantine operation, or PersistenceStoreQuarantineClient closure SHALL declare a concrete typed throws contract that includes every error the boundary can emit. Raw SwiftData and Foundation errors SHALL NOT escape those boundaries. Repository dependency closures that only forward one persistence domain SHALL use the corresponding concrete typed error; a repository that combines API and persistence operations SHALL use a concrete wrapper for the complete union.

#### Scenario: A persistence-only repository exposes the persistence error type

- **WHEN** a caller invokes an OrderRepository operation that only forwards a persistence actor operation
- **THEN** the operation signature exposes PersistenceError or the appropriate OrderPersistenceError
- **AND** the operation does not expose any Error

##### Example: Fetching orders through the repository

- **GIVEN** `OrderPersistence.fetchAll` throws `PersistenceError.fetchFailed(message: "unavailable")`
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
- **AND** the raw framework error does not cross the boundary

##### Example: Foundation save error

- **GIVEN** Foundation reports `"permission denied"` while writing a store file
- **WHEN** the quarantine operation handles the failure
- **THEN** it throws `PersistenceRecoveryError.fileMoveFailed` with the file name and message

### Requirement: Store quarantine uses a separate typed recovery error

PersistenceStoreQuarantine SHALL use PersistenceRecoveryError with directoryResolutionFailed(message:), directoryCreationFailed(message:), and fileMoveFailed(fileName:message:) cases. The operation SHALL return nil and SHALL NOT create a recovery directory when no known store file exists. A failure during directory or file operations SHALL preserve the source localized description.

#### Scenario: No store files require no recovery directory

- **GIVEN** the store directory contains none of the known store files
- **WHEN** PersistenceStoreQuarantine.quarantine runs
- **THEN** the operation returns nil
- **AND** the backup directory remains absent

#### Scenario: A file move failure identifies the file

- **WHEN** moving a known store file fails
- **THEN** the operation throws PersistenceRecoveryError.fileMoveFailed with that file name and the source localized description

##### Example: Store sidecar cannot move

- **GIVEN** `BuyLedger.store-wal` cannot be moved and reports `"permission denied"`
- **WHEN** quarantine processes the sidecar
- **THEN** it throws `PersistenceRecoveryError.fileMoveFailed(fileName: "BuyLedger.store-wal", message: "permission denied")`

#### Scenario: Application Support resolution failure is classified as recovery failure

- **WHEN** PersistenceStoreQuarantineClient cannot resolve the Application Support directory
- **THEN** the client throws PersistenceRecoveryError.directoryResolutionFailed with the source localized description

##### Example: Application Support lookup fails

- **GIVEN** FileManager reports `"location unavailable"`
- **WHEN** the live quarantine client resolves Application Support
- **THEN** it throws `PersistenceRecoveryError.directoryResolutionFailed(message: "location unavailable")`

### Requirement: Typed error conversion preserves existing data safety behavior

Typed error conversion SHALL preserve successful persistence behavior, existing semantic error behavior, cache protection, and rollback behavior. The conversion SHALL NOT change schema, migration, store location, ordering, upsert semantics, cascade updates, deletion semantics, or seed semantics.

#### Scenario: A failed transactional save leaves no pending mutation

- **WHEN** a transactional persistence write fails during save
- **THEN** modelContext.rollback() runs before the typed error is thrown
- **AND** a later fetch does not observe the failed pending mutation

##### Example: Payment method edit rolls back

- **GIVEN** an edit changes a payment method and its orders before save reports `"disk full"`
- **WHEN** `PaymentMethodPersistence.applyEdit` fails
- **THEN** the method rolls back before throwing the typed storage error
- **AND** a later fetch sees the original payment method and orders

#### Scenario: Successful persistence behavior remains unchanged

- **WHEN** a persistence operation succeeds
- **THEN** it returns the same values and applies the same data changes as before the error contract change
- **AND** no schema or migration behavior changes

##### Example: Successful order update

- **GIVEN** an existing order is updated with valid values
- **WHEN** `OrderPersistence.update` succeeds
- **THEN** a later fetch returns the updated order with the same ordering and schema behavior
