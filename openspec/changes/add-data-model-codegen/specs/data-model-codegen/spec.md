## ADDED Requirements

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

### Requirement: Schema vocabulary is platform-neutral

The schema SHALL describe types using platform-neutral trait vocabulary only and SHALL NOT contain trait names specific to a single target language. The recognized traits SHALL be value-equality, serializable, identity, case-iterable, and hashable, plus a serialization marker whose custom value is mutually exclusive with the serializable trait. Each emitter SHALL translate neutral traits into its own idiom, and SHALL handle a trait it has no construct for by an explicit ignore branch rather than failing. Pure per-platform policy SHALL NOT appear in the schema: concurrency-safety (Swift Sendable) SHALL NOT be a schema trait and SHALL instead be applied by the Swift emitter as a global policy that adds Sendable to every generated struct and enum.

#### Scenario: Neutral trait maps across platforms

- **WHEN** a type declares the value-equality trait
- **THEN** the Swift emitter SHALL produce an Equatable conformance, the Kotlin emitter SHALL rely on data class structural equality, and the TypeScript emitter SHALL rely on structural interface comparison

#### Scenario: Swift Sendable is applied globally, not from the schema

- **WHEN** any struct or enum is generated for the Swift target
- **THEN** it SHALL carry a Sendable conformance even though no schema file declares a sendable trait

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

### Requirement: Check mode detects drift between schema and committed output

The datamodel-gen CLI SHALL provide a check command that regenerates all configured targets in memory and compares the results against the files on disk. When every file matches, the command SHALL exit zero. When any file differs, is missing, or is present on disk but no longer generated, the command SHALL exit non-zero and list each drifted file path. The check command SHALL NOT modify any file on disk.

#### Scenario: Schema changed without regeneration

- **WHEN** a field is added to a type in the schema directory and the check command runs before generate is re-run
- **THEN** the check command SHALL exit non-zero and list the affected generated file paths for every configured target

#### Scenario: Outputs in sync

- **WHEN** the check command runs immediately after a successful generate with no further edits
- **THEN** it SHALL exit zero and SHALL NOT modify any file

### Requirement: Generated Swift owns the data shape and handwritten extensions own behavior

The Swift target SHALL emit one file per schema type into apps/apple/BuyLedger/Core/Domain/Generated/ named <TypeName>.generated.swift, containing the primary type declaration: stored properties or enum cases, the conformances corresponding to the declared neutral traits plus the globally applied Sendable, a rawValue-based id accessor for identity enums and wrappers, and an explicit initializer with parameter defaults when any field declares a default or is nullable. Behavior code SHALL remain handwritten in per-type extension files: computed properties, display titles, static collections, view helpers, and custom Codable implementations; a type whose handwritten file would retain no behavior SHALL have that file removed and be fully replaced by its generated file. Types marked serialization custom SHALL NOT receive a Codable conformance in their generated declaration so the handwritten Codable extension keeps its encoding shape. Generated files SHALL begin with a fixed do-not-edit header and SHALL follow the project Swift file conventions for MARK sections, blank lines between enum cases, and Traditional Chinese documentation comments. The public API of the twelve domain types SHALL be unchanged by the split, except that every generated value type gains an explicit Sendable conformance.

#### Scenario: Apple platforms build and tests pass after the split

- **WHEN** the iOS, iPadOS, and macOS builds and the BuyLedgerTests suite run after the generated/handwritten split
- **THEN** all three builds SHALL succeed and all existing tests SHALL pass without modifying any call site of the twelve domain types

#### Scenario: Custom serialization shape is preserved

- **WHEN** a LedgerOrderItem value is encoded to JSON after the split
- **THEN** the output SHALL contain name, quantity, and unitPrice and SHALL NOT contain id, identical to the behavior before the split

#### Scenario: Editing a generated file is detectable

- **WHEN** a developer hand-edits any file under apps/apple/BuyLedger/Core/Domain/Generated/ and runs the check command
- **THEN** the check command SHALL exit non-zero and list that file as drifted

### Requirement: Kotlin and TypeScript emitters are locked by golden-file tests

Because no Android or Web platform directory exists yet, the Kotlin and TypeScript emitters SHALL be exercised by golden-file tests in the generator test suite running under Bun: a fixture schema SHALL be emitted and compared byte-for-byte against committed expected output files for every supported language. The fixture SHALL include a type that declares no serialization trait so the global Sendable policy is exercised. A mismatch SHALL fail the test suite. The production codegen.yaml SHALL configure only the Swift target until other platforms start.

#### Scenario: Emitter change breaks a golden file

- **WHEN** an emitter is modified so its output for the fixture schema differs from the committed golden file
- **THEN** the generator test suite SHALL fail and report the differing file

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
