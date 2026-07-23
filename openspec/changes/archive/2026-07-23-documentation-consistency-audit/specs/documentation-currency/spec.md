## ADDED Requirements

### Requirement: Documentation contains no statements contradicting the current implementation

Project documentation SHALL NOT describe mechanisms, files, or constraints that no longer exist or that the implementation now contradicts, because documentation that disagrees with the code is worse than absent documentation — it actively misleads. When a change removes or replaces a mechanism, every documentation statement describing that mechanism SHALL be rewritten or removed, including statements in sections whose primary topic is something else.

#### Scenario: Removed mechanism is not described as a rule

- **WHEN** the documentation is inspected after a mechanism has been removed from the codebase
- **THEN** no rule describes how that mechanism is implemented, and no rule states constraints on modifying it

#### Scenario: Examples do not cite removed components

- **WHEN** a documentation rule illustrates itself with an example naming a component
- **THEN** that component exists in the codebase, and examples naming removed components have been replaced with existing ones

#### Scenario: Superseded guidance is corrected, not appended

- **WHEN** a rule's guidance has been superseded by a later change
- **THEN** the original guidance is corrected in place rather than left standing alongside a contradicting addition

### Requirement: Symbols named in documentation exist in the codebase

Every type name, file name, and API name appearing in project documentation SHALL correspond to a declaration in the codebase. This provides an objective, checkable floor for documentation accuracy that does not depend on reading each sentence for meaning. Names that are illustrative rather than referential SHALL be identified as such during verification rather than treated as errors.

#### Scenario: Named symbols resolve

- **WHEN** the type and file names appearing in the documentation are checked against the codebase
- **THEN** each resolves to an existing declaration, or is recorded as illustrative with a stated reason

#### Scenario: Unmentioned symbols are not defects

- **WHEN** the codebase contains types not mentioned in the documentation
- **THEN** their absence from the documentation is not treated as a defect, because documentation is not required to enumerate every type

### Requirement: Declared documentation updates are verified against the documents

A change's claim to have synchronized documentation SHALL be verified against the documents themselves rather than accepted on the basis of a completed task. Verification SHALL identify, for each declared update, the location in the documentation where it landed.

#### Scenario: Each declared update is located

- **WHEN** a change's documentation task declares that a rule was recorded
- **THEN** that rule is found in the documentation, and its location is noted

#### Scenario: Undelivered updates are surfaced

- **WHEN** a declared update cannot be found in the documentation
- **THEN** it is recorded as outstanding and applied, rather than assumed to have been covered elsewhere

### Requirement: Accumulated additions preserve document structure

When multiple changes each add rules to the same document, the accumulated result SHALL be reorganized so that the document retains a readable hierarchy rather than degrading into a flat list. Reorganization SHALL be limited to merging semantically overlapping entries, demoting details and caveats to a subordinate level, and grouping related topics. Removing a rule's substance SHALL NOT be treated as reorganization.

#### Scenario: Related rules are grouped

- **WHEN** several changes have each added a rule on the same topic
- **THEN** those rules appear together rather than scattered across the document

#### Scenario: Merging preserves constraint strength

- **WHEN** two overlapping rules are merged into one
- **THEN** the merged rule carries the constraints of both, and any rule whose constraints cannot be fully preserved remains listed separately

#### Scenario: Project structure listings cover existing directories

- **WHEN** a document presents a project structure listing
- **THEN** every existing source directory appears in it
