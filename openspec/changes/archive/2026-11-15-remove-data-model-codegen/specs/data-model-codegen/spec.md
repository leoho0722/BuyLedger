## REMOVED Requirements

### Requirement: Unified schema directory is the single source of truth for data model shapes

**Reason**: The repository no longer contains a schema directory or a generator; the iOS domain types are declared directly in Swift source.
**Migration**: Change a data shape by editing the type's declaration in its file under apps/ios/BuyLedger/Core/Domain; when the type is embedded in a persisted record, invoke the SwiftData schema migration workflow first and update the persisted value shape test in the same change.

### Requirement: Schema vocabulary is platform-neutral

**Reason**: There is no schema left whose documentation or trait vocabulary needs to stay platform-neutral.
**Migration**: Write documentation comments on the Swift declarations following the platform coding style; no neutral vocabulary rule applies.

### Requirement: Nullability and defaults follow explicit, fidelity-preserving rules

**Reason**: Nullability and default values are no longer derived from schema fields; they are written directly in the Swift declarations.
**Migration**: Declare optionality and default parameter values in the Swift type and its initializer.

### Requirement: Schema validation rejects malformed declarations before generation

**Reason**: Without a schema there is nothing to validate before generation; the Swift compiler checks type references directly.
**Migration**: Rely on the iOS and iPadOS builds to reject unknown type references.

### Requirement: Generator emits deterministic Swift, Kotlin, and TypeScript code

**Reason**: The generator and its Swift, Kotlin, and TypeScript emitters are deleted; only the Swift output had a consumer.
**Migration**: None required; a future platform declares its own model types when it is started.

### Requirement: Check mode detects drift between schema and committed output

**Reason**: With no schema and no generated output there is no drift to detect, and the continuous integration job that ran the check is removed.
**Migration**: None required; the Swift source is the only copy of each data shape.

### Requirement: Generated Swift owns the data shape and handwritten extensions own behavior

**Reason**: The split between generated declarations and handwritten cross-file extensions is removed; each domain type is declared together with its domain-layer extensions in a single file, apart from the sample data files.
**Migration**: Find a domain type's stored properties, initializer, and domain-layer extensions together in its own file under apps/ios/BuyLedger/Core/Domain, apart from the sample data files named with a +Samples suffix; extensions that belong to a feature layer or to the test target stay where the layering and test conventions place them.

### Requirement: Kotlin and TypeScript emitters are locked by golden-file tests

**Reason**: The emitters and their golden fixtures are deleted together with the generator.
**Migration**: None required.

### Requirement: Generated output files are locked read-only on disk

**Reason**: No generated output files remain, so there is nothing to lock.
**Migration**: Edit domain type files directly; they are ordinary writable sources.

### Requirement: Enum constants follow each target platform's naming convention

**Reason**: Enum case names are no longer converted per target platform; only the Swift declarations exist.
**Migration**: Name Swift enum cases following the platform coding style.
