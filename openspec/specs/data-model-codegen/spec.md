# data-model-codegen Specification

## Purpose

TBD - created by archiving change 'add-data-model-codegen'. Update Purpose after archive.

## Requirements

### Requirement: Unified schema directory is the single source of truth for data model shapes

The repository SHALL declare every cross-platform data model shape under a single directory shared/data-model/schema/, with one YAML file per type. Each file SHALL contain a types list whose entries are each one of three kinds: entity (a record with typed fields), enum (a string-raw-value enumeration of cases), or wrapper (a single-value newtype over a base type). The schema version SHALL be declared once in codegen.yaml, not repeated per file. Every type, field, and case declaration SHALL carry a single Traditional Chinese doc string that generators emit as documentation comments. Field type expressions SHALL be a string DSL supporting the base types string, int, bool, decimal, date, data, and uuid; the array and map containers; and by-name references to other declared types. Nullability SHALL NOT be encoded in the type string; it SHALL be expressed by an explicit per-field nullable boolean. Field declarations SHALL also support an optional mutability flag and an optional default value (literal, empty array, enum case reference, or new-UUID sentinel).

#### Scenario: Loading the BuyLedger domain model from a directory

- **WHEN** the generator is pointed at shared/data-model/schema/
- **THEN** it SHALL glob every YAML file, concatenate their types, and resolve by-name references against the merged set, yielding the seven entities LedgerOrder, LedgerOrderItem, LedgerCustomer, Campaign, Money, PaymentMethodInfo, and FxRateSnapshot, the four enums OrderStatus, CampaignStatus, PaymentReceiptStatus, and CustomerTier, and the wrapper CurrencyCode

##### Example: type expression grammar

| Expression + flags | Meaning |
| ------------------ | ------- |
| type: string | non-null string |
| type: date, nullable: true | optional date |
| type: array<LedgerOrderItem> | ordered list of entity references |
| type: map<CurrencyCode, decimal> | dictionary keyed by a wrapper type |
| type: PaymentReceiptStatus | by-name reference to an enum |


<!-- @trace
source: add-data-model-codegen
updated: 2026-06-09
code:
  - shared/data-model/fixtures/expected/kotlin/SampleMetadata.kt
  - shared/data-model/schema/CustomerTier.yaml
  - apps/apple/BuyLedger/Core/Domain/Generated/CampaignStatus.generated.swift
  - apps/apple/BuyLedger/Core/Domain/Campaign.swift
  - apps/apple/BuyLedger.xcodeproj/project.pbxproj
  - apps/apple/BuyLedger/Core/Domain/Generated/Money.generated.swift
  - shared/data-model/fixtures/expected/typescript/SampleOrder.ts
  - shared/data-model/fixtures/schema/sample-orders.yaml
  - shared/data-model/generator/src/datamodel-gen.ts
  - apps/apple/BuyLedger/Core/Domain/CurrencyCode.swift
  - shared/data-model/fixtures/expected/typescript/SampleStatus.ts
  - shared/data-model/schema/CampaignStatus.yaml
  - shared/data-model/fixtures/expected/swift/SampleStatus.generated.swift
  - shared/data-model/fixtures/expected/typescript/SampleTag.ts
  - shared/data-model/schema/Money.yaml
  - README.md
  - apps/apple/BuyLedger/Core/Domain/Generated/OrderStatus.generated.swift
  - apps/apple/BuyLedger/Core/Domain/PaymentMethodInfo.swift
  - shared/data-model/fixtures/expected/kotlin/SampleTag.kt
  - shared/data-model/schema/LedgerOrderItem.yaml
  - apps/apple/README.md
  - shared/data-model/schema/FxRateSnapshot.yaml
  - apps/apple/BuyLedger/Core/Domain/Generated/LedgerOrder.generated.swift
  - apps/apple/BuyLedger/Core/Domain/PaymentReceiptStatus.swift
  - shared/data-model/fixtures/codegen.yaml
  - shared/data-model/fixtures/schema/sample-enums.yaml
  - apps/apple/BuyLedger/Core/Domain/Generated/FxRateSnapshot.generated.swift
  - apps/apple/BuyLedger/Core/Domain/Generated/CurrencyCode.generated.swift
  - apps/apple/BuyLedger/Core/Domain/LedgerOrder.swift
  - apps/apple/BuyLedger/Core/Domain/Generated/PaymentMethodInfo.generated.swift
  - apps/apple/BuyLedger/Core/Domain/OrderStatus.swift
  - shared/data-model/schema/CurrencyCode.yaml
  - shared/data-model/schema/LedgerOrder.yaml
  - shared/data-model/fixtures/expected/swift/SampleMetadata.generated.swift
  - apps/apple/BuyLedger/Core/Domain/Generated/PaymentReceiptStatus.generated.swift
  - apps/apple/BuyLedger/Core/Domain/OrderMerge.swift
  - shared/data-model/README.md
  - shared/data-model/schema/OrderStatus.yaml
  - apps/apple/BuyLedger/Core/Domain/CampaignStatus.swift
  - apps/apple/BuyLedger/Core/Domain/LedgerCustomer.swift
  - apps/apple/BuyLedger/Core/Domain/Generated/Campaign.generated.swift
  - shared/data-model/schema/LedgerCustomer.yaml
  - shared/data-model/codegen.yaml
  - apps/apple/BuyLedger/Core/Domain/Generated/LedgerOrderItem.generated.swift
  - apps/apple/BuyLedger/Core/Domain/CustomerTier.swift
  - shared/data-model/generator/tsconfig.json
  - shared/data-model/generator/bun.lock
  - apps/apple/BuyLedger/Core/Domain/FxRateSnapshot.swift
  - shared/data-model/schema/Campaign.yaml
  - shared/data-model/schema/PaymentMethodInfo.yaml
  - CLAUDE.md
  - apps/apple/BuyLedger/Core/Domain/LedgerOrderItem.swift
  - shared/data-model/fixtures/expected/swift/SampleOrder.generated.swift
  - apps/apple/BuyLedger/Core/Domain/Generated/LedgerCustomer.generated.swift
  - apps/apple/BuyLedger/Core/Domain/Money.swift
  - apps/apple/CLAUDE.md
  - apps/apple/BuyLedger/Core/Domain/Generated/CustomerTier.generated.swift
  - shared/data-model/fixtures/expected/kotlin/SampleOrder.kt
  - shared/data-model/fixtures/expected/swift/SampleTag.generated.swift
  - shared/data-model/generator/package.json
  - shared/data-model/fixtures/expected/typescript/SampleMetadata.ts
  - shared/data-model/schema/PaymentReceiptStatus.yaml
  - shared/data-model/fixtures/expected/kotlin/SampleStatus.kt
tests:
  - shared/data-model/generator/test/datamodel-gen.test.ts
-->

---
### Requirement: Schema vocabulary is platform-neutral

The schema SHALL describe types using platform-neutral trait vocabulary only and SHALL NOT contain trait names specific to a single target language. The recognized traits SHALL be value-equality, serializable, identity, case-iterable, and hashable, plus a serialization marker whose custom value is mutually exclusive with the serializable trait. Each emitter SHALL translate neutral traits into its own idiom, and SHALL handle a trait it has no construct for by an explicit ignore branch rather than failing. Pure per-platform policy SHALL NOT appear in the schema: concurrency-safety (Swift Sendable) SHALL NOT be a schema trait and SHALL instead be applied by the Swift emitter as a global policy that adds Sendable to every generated struct and enum.

#### Scenario: Neutral trait maps across platforms

- **WHEN** a type declares the value-equality trait
- **THEN** the Swift emitter SHALL produce an Equatable conformance, the Kotlin emitter SHALL rely on data class structural equality, and the TypeScript emitter SHALL rely on structural interface comparison

#### Scenario: Swift Sendable is applied globally, not from the schema

- **WHEN** any struct or enum is generated for the Swift target
- **THEN** it SHALL carry a Sendable conformance even though no schema file declares a sendable trait


<!-- @trace
source: add-data-model-codegen
updated: 2026-06-09
code:
  - shared/data-model/fixtures/expected/kotlin/SampleMetadata.kt
  - shared/data-model/schema/CustomerTier.yaml
  - apps/apple/BuyLedger/Core/Domain/Generated/CampaignStatus.generated.swift
  - apps/apple/BuyLedger/Core/Domain/Campaign.swift
  - apps/apple/BuyLedger.xcodeproj/project.pbxproj
  - apps/apple/BuyLedger/Core/Domain/Generated/Money.generated.swift
  - shared/data-model/fixtures/expected/typescript/SampleOrder.ts
  - shared/data-model/fixtures/schema/sample-orders.yaml
  - shared/data-model/generator/src/datamodel-gen.ts
  - apps/apple/BuyLedger/Core/Domain/CurrencyCode.swift
  - shared/data-model/fixtures/expected/typescript/SampleStatus.ts
  - shared/data-model/schema/CampaignStatus.yaml
  - shared/data-model/fixtures/expected/swift/SampleStatus.generated.swift
  - shared/data-model/fixtures/expected/typescript/SampleTag.ts
  - shared/data-model/schema/Money.yaml
  - README.md
  - apps/apple/BuyLedger/Core/Domain/Generated/OrderStatus.generated.swift
  - apps/apple/BuyLedger/Core/Domain/PaymentMethodInfo.swift
  - shared/data-model/fixtures/expected/kotlin/SampleTag.kt
  - shared/data-model/schema/LedgerOrderItem.yaml
  - apps/apple/README.md
  - shared/data-model/schema/FxRateSnapshot.yaml
  - apps/apple/BuyLedger/Core/Domain/Generated/LedgerOrder.generated.swift
  - apps/apple/BuyLedger/Core/Domain/PaymentReceiptStatus.swift
  - shared/data-model/fixtures/codegen.yaml
  - shared/data-model/fixtures/schema/sample-enums.yaml
  - apps/apple/BuyLedger/Core/Domain/Generated/FxRateSnapshot.generated.swift
  - apps/apple/BuyLedger/Core/Domain/Generated/CurrencyCode.generated.swift
  - apps/apple/BuyLedger/Core/Domain/LedgerOrder.swift
  - apps/apple/BuyLedger/Core/Domain/Generated/PaymentMethodInfo.generated.swift
  - apps/apple/BuyLedger/Core/Domain/OrderStatus.swift
  - shared/data-model/schema/CurrencyCode.yaml
  - shared/data-model/schema/LedgerOrder.yaml
  - shared/data-model/fixtures/expected/swift/SampleMetadata.generated.swift
  - apps/apple/BuyLedger/Core/Domain/Generated/PaymentReceiptStatus.generated.swift
  - apps/apple/BuyLedger/Core/Domain/OrderMerge.swift
  - shared/data-model/README.md
  - shared/data-model/schema/OrderStatus.yaml
  - apps/apple/BuyLedger/Core/Domain/CampaignStatus.swift
  - apps/apple/BuyLedger/Core/Domain/LedgerCustomer.swift
  - apps/apple/BuyLedger/Core/Domain/Generated/Campaign.generated.swift
  - shared/data-model/schema/LedgerCustomer.yaml
  - shared/data-model/codegen.yaml
  - apps/apple/BuyLedger/Core/Domain/Generated/LedgerOrderItem.generated.swift
  - apps/apple/BuyLedger/Core/Domain/CustomerTier.swift
  - shared/data-model/generator/tsconfig.json
  - shared/data-model/generator/bun.lock
  - apps/apple/BuyLedger/Core/Domain/FxRateSnapshot.swift
  - shared/data-model/schema/Campaign.yaml
  - shared/data-model/schema/PaymentMethodInfo.yaml
  - CLAUDE.md
  - apps/apple/BuyLedger/Core/Domain/LedgerOrderItem.swift
  - shared/data-model/fixtures/expected/swift/SampleOrder.generated.swift
  - apps/apple/BuyLedger/Core/Domain/Generated/LedgerCustomer.generated.swift
  - apps/apple/BuyLedger/Core/Domain/Money.swift
  - apps/apple/CLAUDE.md
  - apps/apple/BuyLedger/Core/Domain/Generated/CustomerTier.generated.swift
  - shared/data-model/fixtures/expected/kotlin/SampleOrder.kt
  - shared/data-model/fixtures/expected/swift/SampleTag.generated.swift
  - shared/data-model/generator/package.json
  - shared/data-model/fixtures/expected/typescript/SampleMetadata.ts
  - shared/data-model/schema/PaymentReceiptStatus.yaml
  - shared/data-model/fixtures/expected/kotlin/SampleStatus.kt
tests:
  - shared/data-model/generator/test/datamodel-gen.test.ts
-->

---
### Requirement: Nullability and defaults follow explicit, fidelity-preserving rules

A field SHALL be nullable when and only when its nullable flag is true, emitting an optional type (Swift T?, Kotlin T?, TypeScript T | null). The initializer or field default for a field SHALL be determined as follows: when a default is declared, that value SHALL be used; when no default is declared and the field is nullable, the emitted default SHALL be the platform nil (Swift = nil, Kotlin = null, TypeScript optional property key); when no default is declared and the field is non-nullable, the field SHALL be a required initializer parameter with no default and SHALL NOT receive a language zero value.

#### Scenario: Non-nullable field without default stays required

- **WHEN** a non-nullable decimal field declares no default
- **THEN** its initializer parameter SHALL be required, and the generator SHALL NOT emit a zero-valued default such as 0

#### Scenario: Nullable field without default defaults to nil

- **WHEN** a nullable date field declares no default and the entity has an explicit initializer
- **THEN** that field's initializer parameter SHALL default to the platform nil (e.g. Swift = nil)

##### Example: default resolution

| nullable | default declared | Swift init parameter |
| -------- | ---------------- | -------------------- |
| false | (none) | required, no default |
| false | 0 | = 0 |
| true | (none) | = nil |
| true | (none, id field) | n/a |
| false | $newUUID | = UUID() |


<!-- @trace
source: add-data-model-codegen
updated: 2026-06-09
code:
  - shared/data-model/fixtures/expected/kotlin/SampleMetadata.kt
  - shared/data-model/schema/CustomerTier.yaml
  - apps/apple/BuyLedger/Core/Domain/Generated/CampaignStatus.generated.swift
  - apps/apple/BuyLedger/Core/Domain/Campaign.swift
  - apps/apple/BuyLedger.xcodeproj/project.pbxproj
  - apps/apple/BuyLedger/Core/Domain/Generated/Money.generated.swift
  - shared/data-model/fixtures/expected/typescript/SampleOrder.ts
  - shared/data-model/fixtures/schema/sample-orders.yaml
  - shared/data-model/generator/src/datamodel-gen.ts
  - apps/apple/BuyLedger/Core/Domain/CurrencyCode.swift
  - shared/data-model/fixtures/expected/typescript/SampleStatus.ts
  - shared/data-model/schema/CampaignStatus.yaml
  - shared/data-model/fixtures/expected/swift/SampleStatus.generated.swift
  - shared/data-model/fixtures/expected/typescript/SampleTag.ts
  - shared/data-model/schema/Money.yaml
  - README.md
  - apps/apple/BuyLedger/Core/Domain/Generated/OrderStatus.generated.swift
  - apps/apple/BuyLedger/Core/Domain/PaymentMethodInfo.swift
  - shared/data-model/fixtures/expected/kotlin/SampleTag.kt
  - shared/data-model/schema/LedgerOrderItem.yaml
  - apps/apple/README.md
  - shared/data-model/schema/FxRateSnapshot.yaml
  - apps/apple/BuyLedger/Core/Domain/Generated/LedgerOrder.generated.swift
  - apps/apple/BuyLedger/Core/Domain/PaymentReceiptStatus.swift
  - shared/data-model/fixtures/codegen.yaml
  - shared/data-model/fixtures/schema/sample-enums.yaml
  - apps/apple/BuyLedger/Core/Domain/Generated/FxRateSnapshot.generated.swift
  - apps/apple/BuyLedger/Core/Domain/Generated/CurrencyCode.generated.swift
  - apps/apple/BuyLedger/Core/Domain/LedgerOrder.swift
  - apps/apple/BuyLedger/Core/Domain/Generated/PaymentMethodInfo.generated.swift
  - apps/apple/BuyLedger/Core/Domain/OrderStatus.swift
  - shared/data-model/schema/CurrencyCode.yaml
  - shared/data-model/schema/LedgerOrder.yaml
  - shared/data-model/fixtures/expected/swift/SampleMetadata.generated.swift
  - apps/apple/BuyLedger/Core/Domain/Generated/PaymentReceiptStatus.generated.swift
  - apps/apple/BuyLedger/Core/Domain/OrderMerge.swift
  - shared/data-model/README.md
  - shared/data-model/schema/OrderStatus.yaml
  - apps/apple/BuyLedger/Core/Domain/CampaignStatus.swift
  - apps/apple/BuyLedger/Core/Domain/LedgerCustomer.swift
  - apps/apple/BuyLedger/Core/Domain/Generated/Campaign.generated.swift
  - shared/data-model/schema/LedgerCustomer.yaml
  - shared/data-model/codegen.yaml
  - apps/apple/BuyLedger/Core/Domain/Generated/LedgerOrderItem.generated.swift
  - apps/apple/BuyLedger/Core/Domain/CustomerTier.swift
  - shared/data-model/generator/tsconfig.json
  - shared/data-model/generator/bun.lock
  - apps/apple/BuyLedger/Core/Domain/FxRateSnapshot.swift
  - shared/data-model/schema/Campaign.yaml
  - shared/data-model/schema/PaymentMethodInfo.yaml
  - CLAUDE.md
  - apps/apple/BuyLedger/Core/Domain/LedgerOrderItem.swift
  - shared/data-model/fixtures/expected/swift/SampleOrder.generated.swift
  - apps/apple/BuyLedger/Core/Domain/Generated/LedgerCustomer.generated.swift
  - apps/apple/BuyLedger/Core/Domain/Money.swift
  - apps/apple/CLAUDE.md
  - apps/apple/BuyLedger/Core/Domain/Generated/CustomerTier.generated.swift
  - shared/data-model/fixtures/expected/kotlin/SampleOrder.kt
  - shared/data-model/fixtures/expected/swift/SampleTag.generated.swift
  - shared/data-model/generator/package.json
  - shared/data-model/fixtures/expected/typescript/SampleMetadata.ts
  - shared/data-model/schema/PaymentReceiptStatus.yaml
  - shared/data-model/fixtures/expected/kotlin/SampleStatus.kt
tests:
  - shared/data-model/generator/test/datamodel-gen.test.ts
-->

---
### Requirement: Schema validation rejects malformed declarations before generation

The generator SHALL validate the merged schema before emitting any file and SHALL terminate with a non-zero exit code and a message naming the offending type or field when validation fails. No output file SHALL be written or modified on a failed run. Validation SHALL reject duplicate type names, duplicate field or case names within a type, by-name references to types not present in the merged set, an identity trait on an entity lacking an id field, a type declaring both the serializable trait and the custom serialization marker, a default referencing a non-existent enum case, an unknown trait, and an unknown kind.

#### Scenario: Unknown type reference

- **WHEN** a field declares type array<UnknownType> and UnknownType is declared in no schema file
- **THEN** the generator SHALL exit non-zero, SHALL name the field and the unresolved reference, and SHALL NOT write any output file

##### Example: validation rule outcomes

| Schema defect | Outcome |
| ------------- | ------- |
| two types both named Campaign | error: duplicate type name |
| entity with identity trait but no id field | error: identity requires id |
| traits contains serializable and serialization: custom | error: conflicting serialization |
| default references OrderStatus.unknown | error: unknown enum case reference |
| trait frobnicatable | error: unknown trait |


<!-- @trace
source: add-data-model-codegen
updated: 2026-06-09
code:
  - shared/data-model/fixtures/expected/kotlin/SampleMetadata.kt
  - shared/data-model/schema/CustomerTier.yaml
  - apps/apple/BuyLedger/Core/Domain/Generated/CampaignStatus.generated.swift
  - apps/apple/BuyLedger/Core/Domain/Campaign.swift
  - apps/apple/BuyLedger.xcodeproj/project.pbxproj
  - apps/apple/BuyLedger/Core/Domain/Generated/Money.generated.swift
  - shared/data-model/fixtures/expected/typescript/SampleOrder.ts
  - shared/data-model/fixtures/schema/sample-orders.yaml
  - shared/data-model/generator/src/datamodel-gen.ts
  - apps/apple/BuyLedger/Core/Domain/CurrencyCode.swift
  - shared/data-model/fixtures/expected/typescript/SampleStatus.ts
  - shared/data-model/schema/CampaignStatus.yaml
  - shared/data-model/fixtures/expected/swift/SampleStatus.generated.swift
  - shared/data-model/fixtures/expected/typescript/SampleTag.ts
  - shared/data-model/schema/Money.yaml
  - README.md
  - apps/apple/BuyLedger/Core/Domain/Generated/OrderStatus.generated.swift
  - apps/apple/BuyLedger/Core/Domain/PaymentMethodInfo.swift
  - shared/data-model/fixtures/expected/kotlin/SampleTag.kt
  - shared/data-model/schema/LedgerOrderItem.yaml
  - apps/apple/README.md
  - shared/data-model/schema/FxRateSnapshot.yaml
  - apps/apple/BuyLedger/Core/Domain/Generated/LedgerOrder.generated.swift
  - apps/apple/BuyLedger/Core/Domain/PaymentReceiptStatus.swift
  - shared/data-model/fixtures/codegen.yaml
  - shared/data-model/fixtures/schema/sample-enums.yaml
  - apps/apple/BuyLedger/Core/Domain/Generated/FxRateSnapshot.generated.swift
  - apps/apple/BuyLedger/Core/Domain/Generated/CurrencyCode.generated.swift
  - apps/apple/BuyLedger/Core/Domain/LedgerOrder.swift
  - apps/apple/BuyLedger/Core/Domain/Generated/PaymentMethodInfo.generated.swift
  - apps/apple/BuyLedger/Core/Domain/OrderStatus.swift
  - shared/data-model/schema/CurrencyCode.yaml
  - shared/data-model/schema/LedgerOrder.yaml
  - shared/data-model/fixtures/expected/swift/SampleMetadata.generated.swift
  - apps/apple/BuyLedger/Core/Domain/Generated/PaymentReceiptStatus.generated.swift
  - apps/apple/BuyLedger/Core/Domain/OrderMerge.swift
  - shared/data-model/README.md
  - shared/data-model/schema/OrderStatus.yaml
  - apps/apple/BuyLedger/Core/Domain/CampaignStatus.swift
  - apps/apple/BuyLedger/Core/Domain/LedgerCustomer.swift
  - apps/apple/BuyLedger/Core/Domain/Generated/Campaign.generated.swift
  - shared/data-model/schema/LedgerCustomer.yaml
  - shared/data-model/codegen.yaml
  - apps/apple/BuyLedger/Core/Domain/Generated/LedgerOrderItem.generated.swift
  - apps/apple/BuyLedger/Core/Domain/CustomerTier.swift
  - shared/data-model/generator/tsconfig.json
  - shared/data-model/generator/bun.lock
  - apps/apple/BuyLedger/Core/Domain/FxRateSnapshot.swift
  - shared/data-model/schema/Campaign.yaml
  - shared/data-model/schema/PaymentMethodInfo.yaml
  - CLAUDE.md
  - apps/apple/BuyLedger/Core/Domain/LedgerOrderItem.swift
  - shared/data-model/fixtures/expected/swift/SampleOrder.generated.swift
  - apps/apple/BuyLedger/Core/Domain/Generated/LedgerCustomer.generated.swift
  - apps/apple/BuyLedger/Core/Domain/Money.swift
  - apps/apple/CLAUDE.md
  - apps/apple/BuyLedger/Core/Domain/Generated/CustomerTier.generated.swift
  - shared/data-model/fixtures/expected/kotlin/SampleOrder.kt
  - shared/data-model/fixtures/expected/swift/SampleTag.generated.swift
  - shared/data-model/generator/package.json
  - shared/data-model/fixtures/expected/typescript/SampleMetadata.ts
  - shared/data-model/schema/PaymentReceiptStatus.yaml
  - shared/data-model/fixtures/expected/kotlin/SampleStatus.kt
tests:
  - shared/data-model/generator/test/datamodel-gen.test.ts
-->

---
### Requirement: Generator emits deterministic Swift, Kotlin, and TypeScript code

The datamodel-gen CLI, implemented in TypeScript and run under Bun, SHALL provide a generate command that reads the schema directory and codegen.yaml (declaring version and one or more targets of language, output directory, and language options) and writes one output file per declared type for every configured target. Output SHALL be deterministic: repeated runs over the same inputs SHALL produce byte-identical files on any machine, types SHALL be emitted in a stable order derived from filename ordering then in-file declaration order, and no timestamp or environment-derived content SHALL appear in generated files. The emitters SHALL map schema types to Swift, Kotlin, and TypeScript according to a fixed mapping table.

#### Scenario: Regenerating produces identical bytes

- **WHEN** the generate command is run twice consecutively against the same schema directory and codegen.yaml
- **THEN** every generated file SHALL be byte-identical between the two runs

##### Example: cross-language type mapping

| Schema type | Swift | Kotlin | TypeScript |
| ----------- | ----- | ------ | ---------- |
| decimal | Decimal | java.math.BigDecimal | string alias DecimalString |
| date | Date | java.time.Instant | string alias ISODateString |
| data | Data | ByteArray | string alias Base64String |
| array<T> | [T] | List<T> | T[] |
| map<K, V> | [K: V] | Map<K, V> | Record<K, V> |
| nullable T | T? | T? | T \| null |
| entity | struct | data class | interface |
| enum | enum with String raw value | enum class with rawValue property | string literal union |
| wrapper | struct over rawValue | @JvmInline value class | type alias |

#### Scenario: Invalid configuration aborts the run

- **WHEN** codegen.yaml names a language the generator does not support
- **THEN** the generate command SHALL exit non-zero with an error naming the unsupported language and SHALL NOT write any output file


<!-- @trace
source: add-data-model-codegen
updated: 2026-06-09
code:
  - shared/data-model/fixtures/expected/kotlin/SampleMetadata.kt
  - shared/data-model/schema/CustomerTier.yaml
  - apps/apple/BuyLedger/Core/Domain/Generated/CampaignStatus.generated.swift
  - apps/apple/BuyLedger/Core/Domain/Campaign.swift
  - apps/apple/BuyLedger.xcodeproj/project.pbxproj
  - apps/apple/BuyLedger/Core/Domain/Generated/Money.generated.swift
  - shared/data-model/fixtures/expected/typescript/SampleOrder.ts
  - shared/data-model/fixtures/schema/sample-orders.yaml
  - shared/data-model/generator/src/datamodel-gen.ts
  - apps/apple/BuyLedger/Core/Domain/CurrencyCode.swift
  - shared/data-model/fixtures/expected/typescript/SampleStatus.ts
  - shared/data-model/schema/CampaignStatus.yaml
  - shared/data-model/fixtures/expected/swift/SampleStatus.generated.swift
  - shared/data-model/fixtures/expected/typescript/SampleTag.ts
  - shared/data-model/schema/Money.yaml
  - README.md
  - apps/apple/BuyLedger/Core/Domain/Generated/OrderStatus.generated.swift
  - apps/apple/BuyLedger/Core/Domain/PaymentMethodInfo.swift
  - shared/data-model/fixtures/expected/kotlin/SampleTag.kt
  - shared/data-model/schema/LedgerOrderItem.yaml
  - apps/apple/README.md
  - shared/data-model/schema/FxRateSnapshot.yaml
  - apps/apple/BuyLedger/Core/Domain/Generated/LedgerOrder.generated.swift
  - apps/apple/BuyLedger/Core/Domain/PaymentReceiptStatus.swift
  - shared/data-model/fixtures/codegen.yaml
  - shared/data-model/fixtures/schema/sample-enums.yaml
  - apps/apple/BuyLedger/Core/Domain/Generated/FxRateSnapshot.generated.swift
  - apps/apple/BuyLedger/Core/Domain/Generated/CurrencyCode.generated.swift
  - apps/apple/BuyLedger/Core/Domain/LedgerOrder.swift
  - apps/apple/BuyLedger/Core/Domain/Generated/PaymentMethodInfo.generated.swift
  - apps/apple/BuyLedger/Core/Domain/OrderStatus.swift
  - shared/data-model/schema/CurrencyCode.yaml
  - shared/data-model/schema/LedgerOrder.yaml
  - shared/data-model/fixtures/expected/swift/SampleMetadata.generated.swift
  - apps/apple/BuyLedger/Core/Domain/Generated/PaymentReceiptStatus.generated.swift
  - apps/apple/BuyLedger/Core/Domain/OrderMerge.swift
  - shared/data-model/README.md
  - shared/data-model/schema/OrderStatus.yaml
  - apps/apple/BuyLedger/Core/Domain/CampaignStatus.swift
  - apps/apple/BuyLedger/Core/Domain/LedgerCustomer.swift
  - apps/apple/BuyLedger/Core/Domain/Generated/Campaign.generated.swift
  - shared/data-model/schema/LedgerCustomer.yaml
  - shared/data-model/codegen.yaml
  - apps/apple/BuyLedger/Core/Domain/Generated/LedgerOrderItem.generated.swift
  - apps/apple/BuyLedger/Core/Domain/CustomerTier.swift
  - shared/data-model/generator/tsconfig.json
  - shared/data-model/generator/bun.lock
  - apps/apple/BuyLedger/Core/Domain/FxRateSnapshot.swift
  - shared/data-model/schema/Campaign.yaml
  - shared/data-model/schema/PaymentMethodInfo.yaml
  - CLAUDE.md
  - apps/apple/BuyLedger/Core/Domain/LedgerOrderItem.swift
  - shared/data-model/fixtures/expected/swift/SampleOrder.generated.swift
  - apps/apple/BuyLedger/Core/Domain/Generated/LedgerCustomer.generated.swift
  - apps/apple/BuyLedger/Core/Domain/Money.swift
  - apps/apple/CLAUDE.md
  - apps/apple/BuyLedger/Core/Domain/Generated/CustomerTier.generated.swift
  - shared/data-model/fixtures/expected/kotlin/SampleOrder.kt
  - shared/data-model/fixtures/expected/swift/SampleTag.generated.swift
  - shared/data-model/generator/package.json
  - shared/data-model/fixtures/expected/typescript/SampleMetadata.ts
  - shared/data-model/schema/PaymentReceiptStatus.yaml
  - shared/data-model/fixtures/expected/kotlin/SampleStatus.kt
tests:
  - shared/data-model/generator/test/datamodel-gen.test.ts
-->

---
### Requirement: Check mode detects drift between schema and committed output

The datamodel-gen CLI SHALL provide a check command that regenerates all configured targets in memory and compares the results against the files on disk. When every file matches, the command SHALL exit zero. When any file differs, is missing, or is present on disk but no longer generated, the command SHALL exit non-zero and list each drifted file path. The check command SHALL NOT modify any file on disk.

#### Scenario: Schema changed without regeneration

- **WHEN** a field is added to a type in the schema directory and the check command runs before generate is re-run
- **THEN** the check command SHALL exit non-zero and list the affected generated file paths for every configured target

#### Scenario: Outputs in sync

- **WHEN** the check command runs immediately after a successful generate with no further edits
- **THEN** it SHALL exit zero and SHALL NOT modify any file


<!-- @trace
source: add-data-model-codegen
updated: 2026-06-09
code:
  - shared/data-model/fixtures/expected/kotlin/SampleMetadata.kt
  - shared/data-model/schema/CustomerTier.yaml
  - apps/apple/BuyLedger/Core/Domain/Generated/CampaignStatus.generated.swift
  - apps/apple/BuyLedger/Core/Domain/Campaign.swift
  - apps/apple/BuyLedger.xcodeproj/project.pbxproj
  - apps/apple/BuyLedger/Core/Domain/Generated/Money.generated.swift
  - shared/data-model/fixtures/expected/typescript/SampleOrder.ts
  - shared/data-model/fixtures/schema/sample-orders.yaml
  - shared/data-model/generator/src/datamodel-gen.ts
  - apps/apple/BuyLedger/Core/Domain/CurrencyCode.swift
  - shared/data-model/fixtures/expected/typescript/SampleStatus.ts
  - shared/data-model/schema/CampaignStatus.yaml
  - shared/data-model/fixtures/expected/swift/SampleStatus.generated.swift
  - shared/data-model/fixtures/expected/typescript/SampleTag.ts
  - shared/data-model/schema/Money.yaml
  - README.md
  - apps/apple/BuyLedger/Core/Domain/Generated/OrderStatus.generated.swift
  - apps/apple/BuyLedger/Core/Domain/PaymentMethodInfo.swift
  - shared/data-model/fixtures/expected/kotlin/SampleTag.kt
  - shared/data-model/schema/LedgerOrderItem.yaml
  - apps/apple/README.md
  - shared/data-model/schema/FxRateSnapshot.yaml
  - apps/apple/BuyLedger/Core/Domain/Generated/LedgerOrder.generated.swift
  - apps/apple/BuyLedger/Core/Domain/PaymentReceiptStatus.swift
  - shared/data-model/fixtures/codegen.yaml
  - shared/data-model/fixtures/schema/sample-enums.yaml
  - apps/apple/BuyLedger/Core/Domain/Generated/FxRateSnapshot.generated.swift
  - apps/apple/BuyLedger/Core/Domain/Generated/CurrencyCode.generated.swift
  - apps/apple/BuyLedger/Core/Domain/LedgerOrder.swift
  - apps/apple/BuyLedger/Core/Domain/Generated/PaymentMethodInfo.generated.swift
  - apps/apple/BuyLedger/Core/Domain/OrderStatus.swift
  - shared/data-model/schema/CurrencyCode.yaml
  - shared/data-model/schema/LedgerOrder.yaml
  - shared/data-model/fixtures/expected/swift/SampleMetadata.generated.swift
  - apps/apple/BuyLedger/Core/Domain/Generated/PaymentReceiptStatus.generated.swift
  - apps/apple/BuyLedger/Core/Domain/OrderMerge.swift
  - shared/data-model/README.md
  - shared/data-model/schema/OrderStatus.yaml
  - apps/apple/BuyLedger/Core/Domain/CampaignStatus.swift
  - apps/apple/BuyLedger/Core/Domain/LedgerCustomer.swift
  - apps/apple/BuyLedger/Core/Domain/Generated/Campaign.generated.swift
  - shared/data-model/schema/LedgerCustomer.yaml
  - shared/data-model/codegen.yaml
  - apps/apple/BuyLedger/Core/Domain/Generated/LedgerOrderItem.generated.swift
  - apps/apple/BuyLedger/Core/Domain/CustomerTier.swift
  - shared/data-model/generator/tsconfig.json
  - shared/data-model/generator/bun.lock
  - apps/apple/BuyLedger/Core/Domain/FxRateSnapshot.swift
  - shared/data-model/schema/Campaign.yaml
  - shared/data-model/schema/PaymentMethodInfo.yaml
  - CLAUDE.md
  - apps/apple/BuyLedger/Core/Domain/LedgerOrderItem.swift
  - shared/data-model/fixtures/expected/swift/SampleOrder.generated.swift
  - apps/apple/BuyLedger/Core/Domain/Generated/LedgerCustomer.generated.swift
  - apps/apple/BuyLedger/Core/Domain/Money.swift
  - apps/apple/CLAUDE.md
  - apps/apple/BuyLedger/Core/Domain/Generated/CustomerTier.generated.swift
  - shared/data-model/fixtures/expected/kotlin/SampleOrder.kt
  - shared/data-model/fixtures/expected/swift/SampleTag.generated.swift
  - shared/data-model/generator/package.json
  - shared/data-model/fixtures/expected/typescript/SampleMetadata.ts
  - shared/data-model/schema/PaymentReceiptStatus.yaml
  - shared/data-model/fixtures/expected/kotlin/SampleStatus.kt
tests:
  - shared/data-model/generator/test/datamodel-gen.test.ts
-->

---
### Requirement: Generated Swift owns the data shape and handwritten extensions own behavior

The Swift target SHALL emit one file per schema type into apps/ios/BuyLedger/Core/Domain/Generated/ named <TypeName>.generated.swift, containing the primary type declaration: stored properties or enum cases, the conformances corresponding to the declared neutral traits plus the globally applied Sendable, a rawValue-based id accessor for identity enums and wrappers, and an explicit initializer with parameter defaults when any field declares a default or is nullable. Behavior code SHALL remain handwritten in per-type extension files: computed properties, display titles, static collections, view helpers, and custom Codable implementations; a type whose handwritten file would retain no behavior SHALL have that file removed and be fully replaced by its generated file. Types marked serialization custom SHALL NOT receive a Codable conformance in their generated declaration so the handwritten Codable extension keeps its encoding shape. Generated files SHALL begin with a fixed do-not-edit header and SHALL follow the project Swift file conventions for MARK sections, blank lines between enum cases, and Traditional Chinese documentation comments. The public API of the twelve domain types SHALL be unchanged by the split, except that every generated value type gains an explicit Sendable conformance.

#### Scenario: Apple platforms build and tests pass after the split

- **WHEN** the iOS and iPadOS builds and the BuyLedgerTests suite run after the generated/handwritten split
- **THEN** both builds SHALL succeed and all existing tests SHALL pass without modifying any call site of the twelve domain types

#### Scenario: Custom serialization shape is preserved

- **WHEN** a LedgerOrderItem value is encoded to JSON after the split
- **THEN** the output SHALL contain name, quantity, and unitPrice and SHALL NOT contain id, identical to the behavior before the split

#### Scenario: Editing a generated file is detectable

- **WHEN** a developer hand-edits any file under apps/ios/BuyLedger/Core/Domain/Generated/ and runs the check command
- **THEN** the check command SHALL exit non-zero and list that file as drifted


<!-- @trace
source: rename-apple-to-ios
updated: 2026-07-10
code:
  - apps/apple/BuyLedgerTests/__Snapshots__/SnapshotTests/orderDetailCostBreakdownBaseline.1.png
  - apps/ios/BuyLedger/Features/App/RootSidebarLayout.swift
  - apps/apple/BuyLedger/Shared/DesignSystem/Foundations/BLMetrics.swift
  - apps/apple/BuyLedger/Features/Orders/Components/OrderMergeCandidateSheet.swift
  - apps/apple/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoThumbnail.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewLongContentBaseline.2.png
  - apps/apple/BuyLedger/Shared/DesignSystem/Components/Charts/BLDonutSegment.swift
  - apps/ios/BuyLedger.xcodeproj/project.xcworkspace/contents.xcworkspacedata
  - apps/ios/BuyLedger/Features/Lookups/LookupKind.swift
  - apps/ios/BuyLedger/Features/AISummary/OllamaClient.swift
  - apps/ios/BuyLedgerTests/SchemaMigrationTests.swift
  - apps/apple/BuyLedgerTests/__Snapshots__/SnapshotTests/dashboardViewBaseline.2.png
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/TextFields/BLSearchField.swift
  - apps/apple/BuyLedger/Shared/DesignSystem/Components/Buttons/BLButtonStyle.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/ViewModifiers/BLCardShadow.swift
  - apps/apple/BuyLedger/Features/Settings/SettingsSnapshot.swift
  - apps/apple/BuyLedgerTests/__Snapshots__/SnapshotTests/insightsViewBaseline.1.png
  - apps/ios/BuyLedgerTests/OrdersFeatureTests.swift
  - apps/apple/BuyLedger/Features/Orders/OrdersFeature.swift
  - apps/ios/BuyLedgerTests/LookupManagementFeatureTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderDetailCostBreakdownBaseline.1.png
  - apps/ios/BuyLedger/Core/Domain/Generated/CampaignStatus.generated.swift
  - apps/apple/BuyLedgerTests/__Snapshots__/SnapshotTests/orderDetailCostBreakdownBaseline.2.png
  - apps/apple/BuyLedger/Core/Dependencies/CurrencyMetadataRepository.swift
  - apps/ios/BuyLedger/Features/Orders/OrderMergeFeature.swift
  - apps/apple/BuyLedger/Features/Quote/QuoteFeature.swift
  - apps/apple/BuyLedger/Resources/Assets.xcassets/AccentColor.colorset/Contents.json
  - apps/apple/BuyLedger/Resources/Assets.xcassets/Contents.json
  - apps/apple/BuyLedger/Shared/DesignSystem/Foundations/BLTone.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsStorage.swift
  - apps/apple/BuyLedger/Shared/DesignSystem/Components/TextFields/BLSearchField.swift
  - apps/apple/BuyLedger/Shared/DesignSystem/Foundations/ViewModifiers/BLCardShadow.swift
  - apps/apple/BuyLedger/Features/Orders/Components/OrderFormatters.swift
  - apps/apple/BuyLedger/Core/Persistence/CurrencyMetadataPersistence.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/SegmentedControls/BLSegmentedControl.swift
  - apps/ios/BuyLedgerTests/CampaignFeatureTests.swift
  - apps/ios/BuyLedgerTests/OrderPersistenceTests.swift
  - apps/apple/BuyLedger/Features/Customers/CustomersView.swift
  - apps/apple/BuyLedger/Features/Orders/Components/LookupItemEditorSheet.swift
  - apps/ios/BuyLedger/Core/Dependencies/CategoryRepository.swift
  - apps/apple/BuyLedgerTests/OrderPersistenceTests.swift
  - apps/apple/BuyLedgerTests/QuoteFeatureTests.swift
  - apps/apple/BuyLedger/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-Any-1024.png
  - apps/apple/BuyLedger/Shared/DesignSystem/Components/Progress/BLProgressBar.swift
  - apps/ios/BuyLedger/Core/Dependencies/OrderSourceRepository.swift
  - apps/ios/BuyLedger/Core/Dependencies/CampaignRepository.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/OrderStatus.generated.swift
  - apps/ios/BuyLedger/Core/Persistence/CategoryRecord.swift
  - apps/apple/BuyLedgerTests/AppConfigurationTests.swift
  - apps/ios/BuyLedger/Features/Orders/OrderEditView.swift
  - apps/apple/BuyLedger/Features/Orders/Components/OrderStatus+Presentation.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Badges/BLBadge.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLSparkline.swift
  - apps/apple/BuyLedger/Features/Orders/Components/OptionPickerSheet.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLBarChart.swift
  - apps/apple/BuyLedgerTests/CampaignSummaryTests.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/FxRateSnapshot.generated.swift
  - apps/ios/BuyLedger/Features/App/RootTab.swift
  - apps/ios/BuyLedger/Resources/Info.plist
  - apps/apple/BuyLedger/Features/Lookups/LookupManagementFeature.swift
  - apps/apple/BuyLedger/Core/Dependencies/OrderSourceRepository.swift
  - apps/apple/BuyLedger/Core/Domain/Generated/Money.generated.swift
  - apps/apple/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewBaseline.1.png
  - apps/apple/BuyLedger/Core/Networking/APIError.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Tags/BLTagPill.swift
  - apps/apple/BuyLedger/Features/App/RootFeature.swift
  - apps/apple/BuyLedger/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-Dark-1024.png
  - apps/apple/BuyLedger/Shared/Localization/Locale+Preferred.swift
  - apps/apple/BuyLedger/Core/Domain/Campaign+Samples.swift
  - apps/ios/BuyLedger/Features/Orders/OrderStatusFilter.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Status/BLStatusPill.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/ViewModifiers/BLTypographyModifier.swift
  - apps/apple/BuyLedger/Core/Persistence/OrderSourcePersistence.swift
  - apps/apple/BuyLedger/Features/Orders/Components/OrderFilterSheet.swift
  - apps/apple/BuyLedgerTests/RootFeatureTests.swift
  - apps/apple/BuyLedger/Resources/Assets.xcassets/AppIcon.appiconset/Contents.json
  - apps/apple/BuyLedger/Core/Persistence/BuyLedgerSchema.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsFeature.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignSummary.swift
  - apps/ios/BuyLedger/Features/Orders/Components/MergePhotoPickerSheet.swift
  - apps/ios/BuyLedger/Core/Persistence/VerificationStatusRecord.swift
  - apps/ios/BuyLedger/Core/Dependencies/OrderRepository.swift
  - apps/ios/BuyLedger/Features/Orders/OrderEditFeature.swift
  - apps/apple/BuyLedger/Core/Dependencies/OrderRepository.swift
  - apps/apple/BuyLedger/Shared/DesignSystem/Components/Status/BLStatusPill.swift
  - apps/apple/BuyLedgerTests/__Snapshots__/SnapshotTests/insightsViewBaseline.2.png
  - apps/apple/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoViewer.swift
  - apps/apple/BuyLedger/Features/Orders/OrderDatePeriod.swift
  - apps/apple/BuyLedger/Core/Persistence/PaymentMethodPersistence.swift
  - apps/ios/BuyLedger/Features/Settings/AISummaryModelCatalog.swift
  - apps/apple/BuyLedger/Core/Persistence/CategoryRecord.swift
  - apps/apple/BuyLedger/Core/Persistence/PaymentMethodRecord.swift
  - apps/apple/BuyLedger/Features/App/RootView.swift
  - apps/apple/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewBaseline.1.png
  - apps/ios/BuyLedger/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-Tinted-1024.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/blBarChartThirtyDaysBaseline.2.png
  - apps/ios/BuyLedgerTests/AppConfigurationTests.swift
  - apps/ios/BuyLedgerTests/OrderMergeFeatureTests.swift
  - apps/ios/BuyLedgerTests/SnapshotTests.swift
  - apps/ios/BuyLedger/Features/App/RootView.swift
  - apps/apple/BuyLedger/Features/Orders/OrdersView.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignListView.swift
  - apps/ios/BuyLedger/Features/Quote/QuoteFeature.swift
  - apps/ios/BuyLedger/Features/AISummary/AISummaryFeature.swift
  - apps/apple/BuyLedger/Core/Domain/CustomerTier.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-Dark-1024.png
  - apps/ios/BuyLedgerTests/InsightsAttributionTests.swift
  - apps/apple/BuyLedgerTests/FxFeatureTests.swift
  - apps/ios/BuyLedger/Core/Domain/OrderSummary.swift
  - apps/apple/BuyLedger/Shared/DesignSystem/Components/SegmentedControls/BLSegmentedControl.swift
  - apps/apple/BuyLedgerTests/SchemaMigrationTests.swift
  - apps/ios/BuyLedgerTests/OrderCalculationTests.swift
  - apps/ios/README.md
  - apps/apple/BuyLedgerTests/CampaignPersistenceTests.swift
  - apps/apple/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewLongContentBaseline.2.png
  - apps/apple/BuyLedger/Resources/Config.example.xcconfig
  - apps/ios/BuyLedger/Resources/Assets.xcassets/AppIcon.appiconset/Contents.json
  - apps/ios/BuyLedger/Core/Persistence/BuyLedgerSchema.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLBarChartValue.swift
  - apps/ios/BuyLedger/Core/Dependencies/PhotoClient.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/LedgerOrderItem.generated.swift
  - apps/apple/BuyLedgerTests/LookupManagementFeatureTests.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OptionPickerSheet.swift
  - apps/apple/BuyLedger/Features/Campaigns/CampaignListView.swift
  - apps/apple/BuyLedger/Features/Settings/SettingsFeature.swift
  - apps/ios/BuyLedger/Core/Persistence/PaymentMethodPersistence.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewBaseline.2.png
  - apps/ios/BuyLedger/Core/Domain/LedgerOrderItem.swift
  - apps/ios/BuyLedgerTests/OllamaClientTests.swift
  - apps/apple/BuyLedger/Shared/DesignSystem/Components/Avatar/BLAvatar.swift
  - apps/ios/BuyLedger/Shared/Keyboard/KeyboardDismissOnTap.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewBaseline.2.png
  - apps/apple/BuyLedger/Features/Orders/OrderEditFeature.swift
  - apps/apple/BuyLedgerTests/__Snapshots__/SnapshotTests/dashboardViewBaseline.1.png
  - apps/apple/BuyLedger/Core/Domain/FxRateSnapshot.swift
  - apps/apple/BuyLedger/Features/App/RootSidebarLayout.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsView.swift
  - apps/apple/BuyLedger/Core/Sync/SyncMeta.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersFeature.swift
  - apps/apple/BuyLedger/Core/Domain/Generated/PaymentReceiptStatus.generated.swift
  - apps/ios/BuyLedgerTests/OrdersFeaturePerformanceTests.swift
  - apps/apple/BuyLedger/Features/Orders/OrderEditView.swift
  - apps/ios/BuyLedger/Core/Domain/Campaign+Samples.swift
  - apps/ios/BuyLedger/Core/Persistence/CampaignRecord.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/blBarChartThirtyDaysBaseline.1.png
  - apps/apple/CLAUDE.md
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/dashboardViewBaseline.1.png
  - apps/apple/BuyLedger/Core/Networking/AppConfiguration.swift
  - apps/apple/BuyLedger/Features/Orders/OrderStatusFilter.swift
  - apps/apple/BuyLedger/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-Tinted-1024.png
  - apps/apple/BuyLedger/Shared/DesignSystem/Foundations/BLPalette.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLDonutChart.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/Contents.json
  - apps/apple/BuyLedgerTests/OrderCalculationTests.swift
  - apps/ios/BuyLedger/Core/Domain/Campaign.swift
  - apps/apple/BuyLedger/Features/Settings/AppearancePreference.swift
  - apps/ios/BuyLedger/Core/Persistence/CampaignPersistence.swift
  - apps/ios/CLAUDE.md
  - apps/apple/BuyLedger/Core/Domain/Generated/LedgerOrderItem.generated.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Avatar/BLAvatar.swift
  - apps/ios/BuyLedger/Core/Domain/OrderMerge.swift
  - apps/apple/BuyLedger/Features/FX/FxRates.swift
  - apps/apple/BuyLedger/Core/Domain/Generated/FxRateSnapshot.generated.swift
  - apps/apple/BuyLedger/Features/Quote/QuoteView.swift
  - apps/apple/BuyLedger/Core/Persistence/OrderPersistence.swift
  - apps/apple/BuyLedger/Features/Settings/SettingsStorage.swift
  - apps/apple/BuyLedger/Shared/DesignSystem/Components/Tags/BLTagPill.swift
  - apps/ios/BuyLedger/Core/Domain/PaymentReceiptStatus.swift
  - apps/ios/BuyLedgerTests/OrderMergeTests.swift
  - apps/apple/BuyLedger/Core/Networking/HTTPMethod.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignEditView.swift
  - apps/ios/BuyLedger/Core/Persistence/CurrencyMetadataRecord.swift
  - apps/ios/BuyLedger/Core/Persistence/OrderSourcePersistence.swift
  - apps/ios/BuyLedger/Core/Networking/URLRequestBuilder.swift
  - apps/apple/BuyLedger/Features/More/MoreView.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-Any-1024.png
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/TextFields/BLAmountField.swift
  - apps/apple/README.md
  - apps/ios/BuyLedger/Features/Orders/Components/PaymentMethodEditorSheet.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/Money.generated.swift
  - apps/ios/BuyLedgerTests/CampaignPersistenceTests.swift
  - apps/apple/BuyLedger/Core/Persistence/OrderSourceRecord.swift
  - apps/ios/BuyLedger/Features/FX/FxView.swift
  - apps/apple/BuyLedger/Features/Orders/OrderMergeFeature.swift
  - apps/ios/BuyLedger/Core/Networking/HTTPMethod.swift
  - apps/apple/BuyLedger/Features/Campaigns/CampaignSummary.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLMetrics.swift
  - shared/data-model/codegen.yaml
  - apps/apple/BuyLedger/Features/Orders/Components/OrderDetailView.swift
  - apps/apple/BuyLedger/Features/Campaigns/CampaignDetailView.swift
  - apps/apple/BuyLedgerTests/OrderStatusTests.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFilterSheet.swift
  - apps/ios/BuyLedger/Core/Persistence/CategoryPersistence.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardView.swift
  - apps/ios/BuyLedgerTests/SettingsFeatureTests.swift
  - apps/apple/BuyLedger/Core/Persistence/PersistenceContainer.swift
  - apps/apple/BuyLedger/App/AppLaunchConfigurator.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementView.swift
  - CLAUDE.md
  - apps/apple/BuyLedger.xcodeproj/project.pbxproj
  - apps/apple/BuyLedgerTests/CampaignFeatureTests.swift
  - apps/ios/BuyLedger/Core/Domain/LedgerOrder+Samples.swift
  - apps/apple/BuyLedger/Core/Domain/Generated/CustomerTier.generated.swift
  - apps/apple/BuyLedger/Core/Domain/LedgerOrder.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderStatus+Presentation.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLDonutSegment.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewBaseline.1.png
  - apps/apple/BuyLedger/Features/Campaigns/CampaignEditView.swift
  - apps/ios/BuyLedger/Core/Persistence/OrderRecord.swift
  - apps/apple/BuyLedger/Core/Persistence/CampaignPersistence.swift
  - apps/apple/BuyLedger/Features/Lookups/LookupManagementView.swift
  - apps/apple/BuyLedgerTests/OllamaClientTests.swift
  - apps/ios/BuyLedger/Core/Dependencies/CurrencyMetadataRepository.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Buttons/BLButtonStyle.swift
  - apps/apple/BuyLedger/Shared/DesignSystem/Components/Charts/BLSparkline.swift
  - apps/apple/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewBaseline.2.png
  - apps/apple/BuyLedgerTests/OrderMergeFeatureTests.swift
  - apps/ios/BuyLedger.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
  - apps/ios/BuyLedger/App/AppLaunchConfigurator.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift
  - apps/apple/BuyLedger/Features/Settings/AISummaryModelCatalog.swift
  - apps/ios/BuyLedger/Features/Quote/QuoteView.swift
  - apps/ios/BuyLedger/Features/FX/ExchangeRateClient.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/dashboardViewBaseline.2.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderDetailCostBreakdownBaseline.2.png
  - apps/apple/BuyLedger/Features/Insights/InsightsView.swift
  - apps/apple/BuyLedger/Core/Domain/LedgerOrder+Samples.swift
  - apps/apple/BuyLedger/Core/Domain/CampaignStatus.swift
  - apps/apple/BuyLedger/Core/Domain/LedgerOrderItem.swift
  - apps/apple/BuyLedger/Features/FX/FxFeature.swift
  - apps/apple/BuyLedger/Features/Orders/Components/PaymentMethodEditorSheet.swift
  - apps/ios/BuyLedger/App/AppDelegate.swift
  - apps/ios/BuyLedger.xcodeproj/xcshareddata/xcschemes/BuyLedger.xcscheme
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLPalette.swift
  - apps/apple/BuyLedger/Core/Dependencies/CampaignRepository.swift
  - apps/apple/BuyLedger/Core/Domain/Generated/CurrencyCode.generated.swift
  - apps/ios/BuyLedger/Features/FX/FxRates.swift
  - apps/ios/BuyLedgerTests/CampaignIntegrationTests.swift
  - apps/apple/BuyLedger/Features/Dashboard/DashboardView.swift
  - apps/ios/BuyLedgerTests/OrderStatusTests.swift
  - apps/ios/BuyLedgerUITests/BuyLedgerUITestsLaunchTests.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderRowView.swift
  - apps/ios/BuyLedgerTests/PhotoDataProcessorTests.swift
  - apps/apple/BuyLedger/Core/Domain/Generated/LedgerOrder.generated.swift
  - apps/ios/BuyLedger/Features/Customers/CustomersView.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLTone.swift
  - apps/apple/BuyLedgerTests/OrderEditFeatureTests.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/PaymentMethodInfo.generated.swift
  - apps/apple/BuyLedgerTests/AISummaryFeatureTests.swift
  - apps/apple/BuyLedger/App/BuyLedgerApp.swift
  - apps/ios/BuyLedger/Core/Dependencies/PaymentMethodRepository.swift
  - apps/ios/BuyLedger/Core/Sync/SyncMeta.swift
  - apps/ios/BuyLedger/Features/App/RootFeature.swift
  - apps/ios/BuyLedger/Features/FX/FxFeature.swift
  - apps/ios/BuyLedger/Shared/Media/PhotoDataProcessor.swift
  - apps/apple/BuyLedger.xcodeproj/xcshareddata/xcschemes/BuyLedger.xcscheme
  - apps/apple/BuyLedger/Shared/DesignSystem/Components/Badges/BLBadge.swift
  - apps/apple/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewMergeContextBaseline.2.png
  - apps/apple/BuyLedgerUITests/BuyLedgerUITests.swift
  - apps/apple/BuyLedgerUITests/BuyLedgerUITestsLaunchTests.swift
  - apps/apple/BuyLedger/Core/Domain/Generated/PaymentMethodInfo.generated.swift
  - apps/apple/BuyLedgerTests/OrdersFeatureTests.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignEditFeature.swift
  - apps/ios/BuyLedgerTests/FxFeatureTests.swift
  - apps/ios/BuyLedger/Core/Persistence/PersistenceContainer.swift
  - apps/ios/BuyLedger/Core/Persistence/PaymentMethodRecord.swift
  - apps/apple/BuyLedgerTests/__Snapshots__/SnapshotTests/blBarChartThirtyDaysBaseline.2.png
  - apps/ios/BuyLedgerTests/PaymentMethodPersistenceTests.swift
  - apps/apple/BuyLedger/Features/AISummary/AISummaryFeature.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewMergeContextBaseline.2.png
  - apps/apple/BuyLedger/Core/Domain/Generated/LedgerCustomer.generated.swift
  - apps/apple/BuyLedgerTests/PhotoDataProcessorTests.swift
  - apps/ios/BuyLedger/Core/Domain/CustomerTier.swift
  - apps/ios/BuyLedger/Core/Persistence/VerificationStatusPersistence.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderMergeCandidateSheet.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewMergeContextBaseline.1.png
  - apps/apple/BuyLedger/Resources/Info.plist
  - apps/apple/BuyLedgerTests/InsightsAttributionTests.swift
  - apps/apple/BuyLedger/App/AppDelegate.swift
  - apps/apple/BuyLedger/Features/AISummary/OllamaClient.swift
  - apps/apple/BuyLedger/Features/App/RootTab.swift
  - apps/apple/BuyLedgerTests/SnapshotTests.swift
  - apps/ios/BuyLedger/Core/Dependencies/VerificationStatusRepository.swift
  - apps/ios/BuyLedger/Features/Settings/AppearancePreference.swift
  - apps/apple/BuyLedger/Features/FX/FxView.swift
  - apps/apple/BuyLedger/Shared/DesignSystem/Foundations/Image+PhotoData.swift
  - apps/apple/BuyLedger/Shared/Media/PhotoDataProcessor.swift
  - apps/ios/BuyLedger/Core/Domain/LedgerOrder.swift
  - apps/apple/BuyLedger/Features/Orders/Components/MergePhotoPickerSheet.swift
  - apps/apple/BuyLedger/Shared/DesignSystem/Foundations/BLTypography.swift
  - apps/apple/BuyLedger/Core/Domain/OrderSummary.swift
  - apps/apple/BuyLedgerTests/CampaignIntegrationTests.swift
  - apps/ios/BuyLedger/Core/Domain/OrderStatus.swift
  - apps/apple/BuyLedger/Core/Persistence/VerificationStatusRecord.swift
  - apps/apple/BuyLedger/Core/Dependencies/CategoryRepository.swift
  - apps/apple/BuyLedger/Features/Settings/SettingsView.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/PaymentReceiptStatus.generated.swift
  - apps/ios/BuyLedger/Core/Networking/APIError.swift
  - apps/apple/BuyLedgerTests/PaymentMethodPersistenceTests.swift
  - apps/apple/BuyLedger/Core/Sync/SyncQueueItem.swift
  - apps/apple/BuyLedger/Shared/DesignSystem/Components/TextFields/BLAmountField.swift
  - apps/apple/BuyLedger.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
  - apps/ios/BuyLedger/Features/Settings/SettingsView.swift
  - apps/apple/BuyLedger/Shared/DesignSystem/Foundations/ViewModifiers/BLTypographyModifier.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersCompactView.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Progress/BLProgressBar.swift
  - apps/apple/BuyLedger.xcodeproj/project.xcworkspace/contents.xcworkspacedata
  - apps/ios/BuyLedger/Core/Domain/CurrencyCode.swift
  - apps/ios/BuyLedgerTests/OrderEditFeatureTests.swift
  - apps/ios/BuyLedgerTests/QuoteFeatureTests.swift
  - apps/ios/BuyLedgerTests/TestDependencies.swift
  - apps/ios/BuyLedger/App/BuyLedgerApp.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/CurrencyCode.generated.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFormatters.swift
  - apps/apple/BuyLedger/Core/Persistence/CurrencyMetadataRecord.swift
  - apps/apple/BuyLedgerTests/TestDependencies.swift
  - apps/apple/BuyLedger/Shared/Keyboard/KeyboardDismissOnTap.swift
  - apps/apple/BuyLedger/Core/Domain/Generated/CampaignStatus.generated.swift
  - apps/apple/BuyLedger/Shared/DesignSystem/Components/Cards/BLCard.swift
  - apps/apple/BuyLedger/Core/Dependencies/VerificationStatusRepository.swift
  - apps/ios/BuyLedger/Core/Networking/HTTPClient.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersView.swift
  - apps/ios/BuyLedger/Features/More/MoreView.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignFormatters.swift
  - apps/apple/BuyLedger/Core/Networking/URLRequestBuilder.swift
  - apps/apple/BuyLedger/Core/Dependencies/PaymentMethodRepository.swift
  - apps/apple/BuyLedger/Features/FX/ExchangeRateClient.swift
  - apps/apple/BuyLedgerTests/OrdersFeaturePerformanceTests.swift
  - apps/ios/BuyLedger/Core/Domain/FxRateSnapshot.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/LedgerCustomer.generated.swift
  - apps/apple/BuyLedger/Core/Domain/OrderMerge.swift
  - apps/ios/BuyLedger/Features/Orders/Components/LookupItemEditorSheet.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsSnapshot.swift
  - AGENTS.md
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewBaseline.1.png
  - apps/apple/BuyLedger/Core/Persistence/CampaignRecord.swift
  - apps/apple/BuyLedger/Features/Orders/OrdersCompactView.swift
  - apps/apple/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewLongContentBaseline.1.png
  - apps/apple/BuyLedger/Core/Domain/Generated/OrderStatus.generated.swift
  - apps/apple/BuyLedger/Shared/DesignSystem/Components/Charts/BLBarChart.swift
  - apps/apple/BuyLedger/Shared/DesignSystem/Components/Charts/BLBarChartValue.swift
  - apps/apple/BuyLedgerTests/OrderMergeTests.swift
  - apps/ios/BuyLedger/Features/AISummary/AISummaryView.swift
  - apps/apple/BuyLedger/Core/Dependencies/PhotoClient.swift
  - apps/apple/BuyLedger/Features/App/RootTabLayout.swift
  - apps/apple/BuyLedger/Features/AISummary/AISummaryView.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignFeature.swift
  - apps/apple/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewBaseline.2.png
  - apps/ios/BuyLedger/Features/Orders/Components/OrderDetailView.swift
  - apps/apple/BuyLedgerTests/__Snapshots__/SnapshotTests/blBarChartThirtyDaysBaseline.1.png
  - apps/apple/BuyLedger/Core/Domain/OrderStatus.swift
  - apps/apple/BuyLedger/Features/Orders/Components/OrderRowView.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/Campaign.generated.swift
  - apps/ios/BuyLedger/Core/Networking/AppConfiguration.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoViewer.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLTypography.swift
  - apps/apple/BuyLedger/Shared/DesignSystem/Components/Charts/BLDonutChart.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/Image+PhotoData.swift
  - apps/ios/BuyLedgerTests/AISummaryFeatureTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Lists/BLListRow.swift
  - apps/apple/BuyLedger/Shared/DesignSystem/Components/Lists/BLListRow.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests.swift
  - apps/apple/BuyLedger/Core/Domain/PaymentReceiptStatus.swift
  - apps/ios/BuyLedger/Core/Domain/CampaignStatus.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/LedgerOrder.generated.swift
  - apps/apple/BuyLedger/Core/Domain/Campaign.swift
  - apps/apple/BuyLedger/Core/Persistence/OrderRecord.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/insightsViewBaseline.1.png
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Cards/BLCard.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewLongContentBaseline.1.png
  - apps/ios/BuyLedgerTests/CampaignSummaryTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoThumbnail.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderStatusFilterBar.swift
  - apps/apple/BuyLedger/Features/Lookups/LookupKind.swift
  - apps/apple/BuyLedger/Core/Domain/CurrencyCode.swift
  - apps/apple/BuyLedger/Core/Domain/Generated/Campaign.generated.swift
  - apps/apple/BuyLedger/Features/Campaigns/CampaignFormatters.swift
  - apps/apple/BuyLedger/Core/Persistence/CategoryPersistence.swift
  - apps/apple/BuyLedger/Features/Campaigns/CampaignEditFeature.swift
  - apps/ios/BuyLedger/Core/Persistence/CurrencyMetadataPersistence.swift
  - apps/apple/BuyLedger/Features/Campaigns/CampaignFeature.swift
  - apps/ios/BuyLedger/Features/App/RootTabLayout.swift
  - apps/apple/BuyLedger/Features/Orders/Components/OrderStatusFilterBar.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/CustomerTier.generated.swift
  - apps/ios/BuyLedger/Resources/Assets.xcassets/AccentColor.colorset/Contents.json
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/insightsViewBaseline.2.png
  - apps/ios/BuyLedger/Core/Persistence/OrderPersistence.swift
  - apps/apple/BuyLedger/Core/Persistence/VerificationStatusPersistence.swift
  - apps/apple/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewMergeContextBaseline.1.png
  - apps/apple/BuyLedger/Core/Networking/HTTPClient.swift
  - apps/apple/BuyLedgerTests/SettingsFeatureTests.swift
  - apps/ios/BuyLedger/Resources/Config.example.xcconfig
  - apps/ios/BuyLedger.xcodeproj/project.pbxproj
  - apps/ios/BuyLedger/Features/Orders/OrderDatePeriod.swift
  - apps/ios/BuyLedger/Core/Persistence/OrderSourceRecord.swift
  - apps/ios/BuyLedger/Core/Sync/SyncQueueItem.swift
  - README.md
  - apps/ios/BuyLedger/Features/Campaigns/CampaignDetailView.swift
  - apps/ios/BuyLedger/Shared/Localization/Locale+Preferred.swift
  - apps/ios/BuyLedgerUITests/BuyLedgerUITests.swift
tests:
  - shared/data-model/generator/test/datamodel-gen.test.ts
-->

---
### Requirement: Kotlin and TypeScript emitters are locked by golden-file tests

Because no Android or Web platform directory exists yet, the Kotlin and TypeScript emitters SHALL be exercised by golden-file tests in the generator test suite running under Bun: a fixture schema SHALL be emitted and compared byte-for-byte against committed expected output files for every supported language. The fixture SHALL include a type that declares no serialization trait so the global Sendable policy is exercised. A mismatch SHALL fail the test suite. The production codegen.yaml SHALL configure only the Swift target until other platforms start.

#### Scenario: Emitter change breaks a golden file

- **WHEN** an emitter is modified so its output for the fixture schema differs from the committed golden file
- **THEN** the generator test suite SHALL fail and report the differing file


<!-- @trace
source: add-data-model-codegen
updated: 2026-06-09
code:
  - shared/data-model/fixtures/expected/kotlin/SampleMetadata.kt
  - shared/data-model/schema/CustomerTier.yaml
  - apps/apple/BuyLedger/Core/Domain/Generated/CampaignStatus.generated.swift
  - apps/apple/BuyLedger/Core/Domain/Campaign.swift
  - apps/apple/BuyLedger.xcodeproj/project.pbxproj
  - apps/apple/BuyLedger/Core/Domain/Generated/Money.generated.swift
  - shared/data-model/fixtures/expected/typescript/SampleOrder.ts
  - shared/data-model/fixtures/schema/sample-orders.yaml
  - shared/data-model/generator/src/datamodel-gen.ts
  - apps/apple/BuyLedger/Core/Domain/CurrencyCode.swift
  - shared/data-model/fixtures/expected/typescript/SampleStatus.ts
  - shared/data-model/schema/CampaignStatus.yaml
  - shared/data-model/fixtures/expected/swift/SampleStatus.generated.swift
  - shared/data-model/fixtures/expected/typescript/SampleTag.ts
  - shared/data-model/schema/Money.yaml
  - README.md
  - apps/apple/BuyLedger/Core/Domain/Generated/OrderStatus.generated.swift
  - apps/apple/BuyLedger/Core/Domain/PaymentMethodInfo.swift
  - shared/data-model/fixtures/expected/kotlin/SampleTag.kt
  - shared/data-model/schema/LedgerOrderItem.yaml
  - apps/apple/README.md
  - shared/data-model/schema/FxRateSnapshot.yaml
  - apps/apple/BuyLedger/Core/Domain/Generated/LedgerOrder.generated.swift
  - apps/apple/BuyLedger/Core/Domain/PaymentReceiptStatus.swift
  - shared/data-model/fixtures/codegen.yaml
  - shared/data-model/fixtures/schema/sample-enums.yaml
  - apps/apple/BuyLedger/Core/Domain/Generated/FxRateSnapshot.generated.swift
  - apps/apple/BuyLedger/Core/Domain/Generated/CurrencyCode.generated.swift
  - apps/apple/BuyLedger/Core/Domain/LedgerOrder.swift
  - apps/apple/BuyLedger/Core/Domain/Generated/PaymentMethodInfo.generated.swift
  - apps/apple/BuyLedger/Core/Domain/OrderStatus.swift
  - shared/data-model/schema/CurrencyCode.yaml
  - shared/data-model/schema/LedgerOrder.yaml
  - shared/data-model/fixtures/expected/swift/SampleMetadata.generated.swift
  - apps/apple/BuyLedger/Core/Domain/Generated/PaymentReceiptStatus.generated.swift
  - apps/apple/BuyLedger/Core/Domain/OrderMerge.swift
  - shared/data-model/README.md
  - shared/data-model/schema/OrderStatus.yaml
  - apps/apple/BuyLedger/Core/Domain/CampaignStatus.swift
  - apps/apple/BuyLedger/Core/Domain/LedgerCustomer.swift
  - apps/apple/BuyLedger/Core/Domain/Generated/Campaign.generated.swift
  - shared/data-model/schema/LedgerCustomer.yaml
  - shared/data-model/codegen.yaml
  - apps/apple/BuyLedger/Core/Domain/Generated/LedgerOrderItem.generated.swift
  - apps/apple/BuyLedger/Core/Domain/CustomerTier.swift
  - shared/data-model/generator/tsconfig.json
  - shared/data-model/generator/bun.lock
  - apps/apple/BuyLedger/Core/Domain/FxRateSnapshot.swift
  - shared/data-model/schema/Campaign.yaml
  - shared/data-model/schema/PaymentMethodInfo.yaml
  - CLAUDE.md
  - apps/apple/BuyLedger/Core/Domain/LedgerOrderItem.swift
  - shared/data-model/fixtures/expected/swift/SampleOrder.generated.swift
  - apps/apple/BuyLedger/Core/Domain/Generated/LedgerCustomer.generated.swift
  - apps/apple/BuyLedger/Core/Domain/Money.swift
  - apps/apple/CLAUDE.md
  - apps/apple/BuyLedger/Core/Domain/Generated/CustomerTier.generated.swift
  - shared/data-model/fixtures/expected/kotlin/SampleOrder.kt
  - shared/data-model/fixtures/expected/swift/SampleTag.generated.swift
  - shared/data-model/generator/package.json
  - shared/data-model/fixtures/expected/typescript/SampleMetadata.ts
  - shared/data-model/schema/PaymentReceiptStatus.yaml
  - shared/data-model/fixtures/expected/kotlin/SampleStatus.kt
tests:
  - shared/data-model/generator/test/datamodel-gen.test.ts
-->

---
### Requirement: Generated output files are locked read-only on disk

The generate command SHALL write every generated output file with read-only permissions (owner mode 0o444) so the files cannot be hand-edited by accident. A subsequent generate run SHALL still succeed against already-read-only files by unlocking, rewriting, and re-locking each file, so regeneration stays idempotent. The CLI SHALL provide an unlock command that restores write permission to the generated files of every configured target without modifying their content — for the rare case a developer must inspect or experiment locally — and the next generate SHALL re-lock them. The check command SHALL read the files without requiring write permission. This read-only lock is a local working-copy guard (version control need not track the write bit) that complements, not replaces, the do-not-edit header and the check gate.

#### Scenario: Generated files are read-only after generate

- **WHEN** the generate command writes the configured targets
- **THEN** each generated file SHALL have read-only permissions and SHALL NOT be writable without an explicit unlock

#### Scenario: Regenerating over read-only files succeeds

- **WHEN** the generate command runs again while the previously generated files are read-only
- **THEN** it SHALL overwrite them without error and leave them read-only again

#### Scenario: Unlock restores write permission

- **WHEN** the unlock command runs for a configured target
- **THEN** that target's generated files SHALL become writable, their content SHALL be unchanged, and a following generate SHALL re-lock them

<!-- @trace
source: add-data-model-codegen
updated: 2026-06-09
code:
  - shared/data-model/fixtures/expected/kotlin/SampleMetadata.kt
  - shared/data-model/schema/CustomerTier.yaml
  - apps/apple/BuyLedger/Core/Domain/Generated/CampaignStatus.generated.swift
  - apps/apple/BuyLedger/Core/Domain/Campaign.swift
  - apps/apple/BuyLedger.xcodeproj/project.pbxproj
  - apps/apple/BuyLedger/Core/Domain/Generated/Money.generated.swift
  - shared/data-model/fixtures/expected/typescript/SampleOrder.ts
  - shared/data-model/fixtures/schema/sample-orders.yaml
  - shared/data-model/generator/src/datamodel-gen.ts
  - apps/apple/BuyLedger/Core/Domain/CurrencyCode.swift
  - shared/data-model/fixtures/expected/typescript/SampleStatus.ts
  - shared/data-model/schema/CampaignStatus.yaml
  - shared/data-model/fixtures/expected/swift/SampleStatus.generated.swift
  - shared/data-model/fixtures/expected/typescript/SampleTag.ts
  - shared/data-model/schema/Money.yaml
  - README.md
  - apps/apple/BuyLedger/Core/Domain/Generated/OrderStatus.generated.swift
  - apps/apple/BuyLedger/Core/Domain/PaymentMethodInfo.swift
  - shared/data-model/fixtures/expected/kotlin/SampleTag.kt
  - shared/data-model/schema/LedgerOrderItem.yaml
  - apps/apple/README.md
  - shared/data-model/schema/FxRateSnapshot.yaml
  - apps/apple/BuyLedger/Core/Domain/Generated/LedgerOrder.generated.swift
  - apps/apple/BuyLedger/Core/Domain/PaymentReceiptStatus.swift
  - shared/data-model/fixtures/codegen.yaml
  - shared/data-model/fixtures/schema/sample-enums.yaml
  - apps/apple/BuyLedger/Core/Domain/Generated/FxRateSnapshot.generated.swift
  - apps/apple/BuyLedger/Core/Domain/Generated/CurrencyCode.generated.swift
  - apps/apple/BuyLedger/Core/Domain/LedgerOrder.swift
  - apps/apple/BuyLedger/Core/Domain/Generated/PaymentMethodInfo.generated.swift
  - apps/apple/BuyLedger/Core/Domain/OrderStatus.swift
  - shared/data-model/schema/CurrencyCode.yaml
  - shared/data-model/schema/LedgerOrder.yaml
  - shared/data-model/fixtures/expected/swift/SampleMetadata.generated.swift
  - apps/apple/BuyLedger/Core/Domain/Generated/PaymentReceiptStatus.generated.swift
  - apps/apple/BuyLedger/Core/Domain/OrderMerge.swift
  - shared/data-model/README.md
  - shared/data-model/schema/OrderStatus.yaml
  - apps/apple/BuyLedger/Core/Domain/CampaignStatus.swift
  - apps/apple/BuyLedger/Core/Domain/LedgerCustomer.swift
  - apps/apple/BuyLedger/Core/Domain/Generated/Campaign.generated.swift
  - shared/data-model/schema/LedgerCustomer.yaml
  - shared/data-model/codegen.yaml
  - apps/apple/BuyLedger/Core/Domain/Generated/LedgerOrderItem.generated.swift
  - apps/apple/BuyLedger/Core/Domain/CustomerTier.swift
  - shared/data-model/generator/tsconfig.json
  - shared/data-model/generator/bun.lock
  - apps/apple/BuyLedger/Core/Domain/FxRateSnapshot.swift
  - shared/data-model/schema/Campaign.yaml
  - shared/data-model/schema/PaymentMethodInfo.yaml
  - CLAUDE.md
  - apps/apple/BuyLedger/Core/Domain/LedgerOrderItem.swift
  - shared/data-model/fixtures/expected/swift/SampleOrder.generated.swift
  - apps/apple/BuyLedger/Core/Domain/Generated/LedgerCustomer.generated.swift
  - apps/apple/BuyLedger/Core/Domain/Money.swift
  - apps/apple/CLAUDE.md
  - apps/apple/BuyLedger/Core/Domain/Generated/CustomerTier.generated.swift
  - shared/data-model/fixtures/expected/kotlin/SampleOrder.kt
  - shared/data-model/fixtures/expected/swift/SampleTag.generated.swift
  - shared/data-model/generator/package.json
  - shared/data-model/fixtures/expected/typescript/SampleMetadata.ts
  - shared/data-model/schema/PaymentReceiptStatus.yaml
  - shared/data-model/fixtures/expected/kotlin/SampleStatus.kt
tests:
  - shared/data-model/generator/test/datamodel-gen.test.ts
-->