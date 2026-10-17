## MODIFIED Requirements

### Requirement: Generated Swift owns the data shape and handwritten extensions own behavior

The Swift target SHALL emit one file per schema type into apps/ios/BuyLedger/Core/Domain/Generated/ named <TypeName>.generated.swift, containing the primary type declaration: stored properties or enum cases, the conformances corresponding to the declared neutral traits plus the globally applied Sendable, a rawValue-based id accessor for identity enums and wrappers, and an explicit initializer with parameter defaults when any field declares a default or is nullable. Behavior code SHALL remain handwritten in per-type extension files: computed properties, display titles, static collections, view helpers, and custom Codable implementations; a type whose handwritten file would retain no behavior SHALL have that file removed and be fully replaced by its generated file. Types marked serialization custom SHALL NOT receive a Codable conformance in their generated declaration so the handwritten Codable extension keeps its encoding shape. Generated files SHALL begin with a fixed do-not-edit header and SHALL follow the project Swift file conventions for MARK sections, blank lines between enum cases, and Traditional Chinese documentation comments. The public API of the twelve domain types SHALL be unchanged by the split, except that every generated value type gains an explicit Sendable conformance.

The emitted documentation and conformance layout SHALL additionally follow three conventions:

- A documentation summary SHALL NOT restate the declaration name it documents. This applies to the generator's own fixed doc strings for a wrapper's raw value and for the rawValue-based id accessor, not only to doc text taken from the schema.
- Supplementary prose beyond the summary SHALL be emitted as a `- Note:` item rather than as a free-standing paragraph.
- A conformance the generator satisfies with a hand-written member, namely the rawValue-based id accessor for identity enums and wrappers, SHALL be declared on an extension carrying the corresponding MARK section rather than on the primary type declaration line. Conformances satisfied entirely by the compiler SHALL stay on the primary type declaration line.

#### Scenario: Apple platforms build and tests pass after the split

- **WHEN** the iOS and iPadOS builds and the BuyLedgerTests suite run after the generated/handwritten split
- **THEN** both builds SHALL succeed and all existing tests SHALL pass without modifying any call site of the twelve domain types

#### Scenario: Custom serialization shape is preserved

- **WHEN** a LedgerOrderItem value is encoded to JSON after the split
- **THEN** the output SHALL contain name, quantity, and unitPrice and SHALL NOT contain id, identical to the behavior before the split

#### Scenario: Editing a generated file is detectable

- **WHEN** a developer hand-edits any file under apps/ios/BuyLedger/Core/Domain/Generated/ and runs the check command
- **THEN** the check command SHALL exit non-zero and list that file as drifted

#### Scenario: An identity enum declares its identity conformance on an extension

- **WHEN** the generator emits an enum declared with the identity trait
- **THEN** the primary declaration line SHALL NOT list that identity conformance
- **AND** an extension carrying the identity MARK section SHALL declare the conformance together with the rawValue-based id accessor

##### Example: SampleStatus identity layout

- **GIVEN** the sample schema declares `SampleStatus` as an enum with the identity and case-iterable traits
- **WHEN** the generator emits `SampleStatus.generated.swift`
- **THEN** the primary declaration is `enum SampleStatus: String, CaseIterable, Codable, Sendable` and the identity member appears only under a trailing `// MARK: - Identifiable` extension that declares `extension SampleStatus: Identifiable` and holds `var id: String { rawValue }`

#### Scenario: Documentation does not restate the declaration name

- **WHEN** the generator emits the documentation comment for a type, an initializer, a wrapper raw value, or an id accessor
- **THEN** the summary SHALL describe what the declaration is for and SHALL NOT repeat the declaration name as the whole summary

##### Example: fixed doc strings before and after

The three doc strings the generator writes itself are fixed text, so the golden fixtures compare them byte for byte.

| Declaration | Emitted today | Required text |
| ----------- | ------------- | ------------- |
| generated initializer | `/// 建立 SampleOrder` | `/// 以必填欄位建立值，宣告了預設值的欄位可以省略` |
| wrapper raw value | `/// 包裝的原始值` | `/// 實際保存的基礎值` |
| id accessor | `/// 穩定識別值 (以 rawValue 表示)` | `/// 以實際保存的值作為穩定識別` |

A doc string that comes from the schema SHALL be emitted as written, apart from the existing removal of a trailing full stop.

#### Scenario: Supplementary prose is emitted as a note

- **WHEN** a schema doc string carries explanation beyond its first sentence
- **THEN** the emitted documentation SHALL place that explanation in a `- Note:` item

##### Example: SampleOrder type documentation

- **GIVEN** the sample schema doc for `SampleOrder` carries a summary plus a sentence explaining which mapping paths the sample covers
- **WHEN** the generator emits the type documentation
- **THEN** the first line is the summary and the explanation appears as a `- Note:` item, with no free-standing paragraph between them

#### Scenario: Golden files lock the emitted layout

- **WHEN** the generator test suite runs against the sample schema
- **THEN** the Swift golden fixtures SHALL match the emitted output byte for byte, including the documentation and conformance layout above

##### Example: Swift golden fixtures under test

- **GIVEN** the fixtures `shared/data-model/fixtures/expected/swift/SampleOrder.generated.swift` and `shared/data-model/fixtures/expected/swift/SampleStatus.generated.swift`
- **WHEN** `bun test` runs in `shared/data-model/generator`
- **THEN** both fixtures compare equal to the freshly emitted output and any layout drift fails the suite
