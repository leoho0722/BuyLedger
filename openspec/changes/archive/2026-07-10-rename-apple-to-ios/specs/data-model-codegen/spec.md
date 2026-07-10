## MODIFIED Requirements

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
