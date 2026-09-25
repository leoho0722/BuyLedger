## MODIFIED Requirements

### Requirement: Kotlin and TypeScript emitters are locked by golden-file tests

Because no Android or Web platform directory exists yet, the Kotlin and TypeScript emitters SHALL be exercised by golden-file tests in the generator test suite running under Bun: a fixture schema SHALL be emitted and compared byte-for-byte against committed expected output files for every supported language. The fixture SHALL include a type that declares no serialization trait so the global Sendable policy is exercised. A mismatch SHALL fail the test suite. The production codegen.yaml SHALL configure only the Swift target until other platforms start.

The fixture schema SHALL cover every emit path that the production schema actually exercises. A path that the production schema uses but the fixture omits is unprotected, because a golden-file test can only fail on material it contains. The fixture SHALL therefore include at least: a multi-word enum case, an entity declaring custom serialization, string and boolean field defaults, and a wrapper over an integer base.

#### Scenario: Emitter change breaks a golden file

- **WHEN** an emitter is modified so its output for the fixture schema differs from the committed golden file
- **THEN** the generator test suite SHALL fail and report the differing file

#### Scenario: Production path missing from the fixture is a coverage defect

- **WHEN** the production schema exercises an emit path that no fixture type exercises
- **THEN** the fixture SHALL be extended to cover it, because the golden-file suite cannot otherwise detect a regression on that path

### Requirement: Schema vocabulary is platform-neutral

The schema SHALL describe types using platform-neutral trait vocabulary only and SHALL NOT contain trait names specific to a single target language. The recognized traits SHALL be value-equality, serializable, identity, case-iterable, and hashable, plus a serialization marker whose custom value is mutually exclusive with the serializable trait. Each emitter SHALL translate neutral traits into its own idiom, and SHALL handle a trait it has no construct for by an explicit ignore branch rather than failing. Pure per-platform policy SHALL NOT appear in the schema: concurrency-safety (Swift Sendable) SHALL NOT be a schema trait and SHALL instead be applied by the Swift emitter as a global policy that adds Sendable to every generated struct and enum.

Neutrality SHALL extend to documentation text, and SHALL be enforced by the test suite rather than by convention alone. Schema documentation SHALL NOT name any target platform's language, framework, or type constructs, and SHALL NOT use an em dash.

#### Scenario: Neutral trait maps across platforms

- **WHEN** a type declares the value-equality trait
- **THEN** the Swift emitter SHALL produce an Equatable conformance, the Kotlin emitter SHALL rely on data class structural equality, and the TypeScript emitter SHALL rely on structural interface comparison

#### Scenario: Swift Sendable is applied globally, not from the schema

- **WHEN** any struct or enum is generated for the Swift target
- **THEN** it SHALL carry a Sendable conformance even though no schema file declares a sendable trait

#### Scenario: Platform vocabulary in documentation fails the suite

- **WHEN** a schema documentation string names a target platform's language, framework, or type construct
- **THEN** the generator test suite SHALL fail and report the offending schema file

#### Scenario: Em dash in documentation fails the suite

- **WHEN** a schema documentation string contains an em dash
- **THEN** the generator test suite SHALL fail and report the offending schema file

## ADDED Requirements

### Requirement: Enum constants follow each target platform's naming convention

An emitter SHALL translate a schema's camel-case enum case name into the naming convention of its target platform rather than applying a naive case change. For the Kotlin target this means a screaming snake case constant, so that a multi-word case becomes underscore-separated rather than a single run of letters. The conversion SHALL be implemented once and used by every site that emits a case name, including enum case declarations and enum-valued field defaults, so that the two cannot diverge.

#### Scenario: Multi-word case becomes underscore separated

- **WHEN** the Kotlin emitter emits an enum whose schema case name is multi-word camel case
- **THEN** the emitted constant separates the words with an underscore and preserves the original case name as the raw value

##### Example: case name conversion

| Schema case name | Kotlin constant | Raw value |
| ---------------- | --------------- | --------- |
| arrived | ARRIVED | arrived |
| partiallyArrived | PARTIALLY_ARRIVED | partiallyArrived |
| pickedUp | PICKED_UP | pickedUp |

#### Scenario: Declaration and default use the same conversion

- **WHEN** a field declares a default whose value is an enum case
- **THEN** the emitted default references the same constant name that the enum declaration emits for that case

#### Scenario: Swift output is unaffected

- **WHEN** the Swift emitter emits the same enum
- **THEN** its case names are unchanged by this convention, because the schema's camel case already matches that platform's convention
