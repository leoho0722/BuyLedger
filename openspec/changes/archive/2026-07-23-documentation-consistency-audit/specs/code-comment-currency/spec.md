## ADDED Requirements

### Requirement: Comments do not describe mechanisms or rationale that no longer hold

A code comment SHALL NOT state a rationale, constraint, or mechanism that the current implementation contradicts. When a change removes or replaces something a comment explains, that comment SHALL be rewritten or removed, including comments in files the change did not otherwise modify.

A comment describing an intent the implementation does not fulfill SHALL be resolved by first determining which side is wrong. Where the implementation is to be corrected, that work belongs to the change owning it and SHALL NOT be performed here. Where the implementation is deliberately staying as it is, the comment SHALL be rewritten to describe what the code actually does, and the decision it defers to SHALL be identifiable.

#### Scenario: Rationale for a removed mechanism is not left standing

- **WHEN** a comment explains why a particular approach was chosen, and that approach has since been replaced
- **THEN** the comment is rewritten to reflect the current approach, or removed together with the construct it explained

#### Scenario: Comment describing unfulfilled intent is corrected

- **WHEN** a comment describes a layout or behavior the implementation does not produce, and the implementation is deliberately unchanged
- **THEN** the comment is rewritten to describe the actual behavior, rather than left stating the unachieved intent

#### Scenario: Implementation corrections are not made here

- **WHEN** a comment and its implementation disagree and the implementation is the side requiring correction
- **THEN** the discrepancy is recorded for the owning change and neither the implementation nor the comment is altered here

### Requirement: Comment auditing is limited to currency, not style

Comment auditing under this capability SHALL assess only whether a comment's content still holds. Language, terminal punctuation, bracket form, spacing, and conciseness SHALL NOT be assessed here, because a dedicated style gate already reviews those against each change's modified files.

This audit covers what that gate structurally cannot see: comments in files no change modified, which have become false because of changes elsewhere.

#### Scenario: Style issues are left to the style gate

- **WHEN** a comment is encountered whose content still holds but whose formatting departs from project conventions
- **THEN** it is left unmodified by this audit

#### Scenario: Unmodified files are still covered

- **WHEN** a comment resides in a file that no recent change modified
- **THEN** it is still assessed for whether its content still holds

### Requirement: Generated file comments are reported rather than edited

Comments in generated files SHALL NOT be edited directly. Generated files are produced by a generator, are held read-only on disk to prevent hand editing, and any direct edit would be lost on the next generation and would break the generated-versus-schema synchronization check. Problems found in generated comments SHALL be recorded as generator work items.

#### Scenario: Generated comment problem is recorded

- **WHEN** the audit finds a comment problem inside a generated file
- **THEN** it is recorded as a generator work item and the generated file is left unmodified

#### Scenario: Generated files remain synchronized

- **WHEN** the audit completes
- **THEN** the generated-versus-schema synchronization check still passes, because no generated file was hand edited

### Requirement: Comment edits change no executable code

Changes made under this capability SHALL affect comment text only. No executable statement, declaration, or annotation SHALL be altered. This SHALL be verified by inspecting the diff rather than asserted.

#### Scenario: Diff contains only comment lines

- **WHEN** the source changes made by this audit are inspected
- **THEN** every changed line is a comment line

#### Scenario: Project still builds

- **WHEN** the audit's source changes are complete
- **THEN** the project builds for both supported platform targets

### Requirement: Widely applicable knowledge in comments is identified for promotion

Where a comment records knowledge whose applicability extends beyond the file it sits in — a pitfall confirmed by testing, or a constraint that now governs several call sites — the audit SHALL identify it and record whether it warrants promotion to a documented project rule. The audit SHALL NOT perform the promotion, because wording and placement within the documentation hierarchy are separate decisions.

#### Scenario: Cross-cutting pitfall is identified

- **WHEN** a comment records a pitfall that now applies to multiple call sites rather than only its own
- **THEN** it is recorded as a candidate for promotion to a project rule, and the comment itself is left in place
