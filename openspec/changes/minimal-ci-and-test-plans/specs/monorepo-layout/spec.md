## MODIFIED Requirements

### Requirement: Cross-platform content stays at the repository root

The repository SHALL keep platform-neutral content at the root: openspec/ for specs and change proposals, assets/ for repository-level marketing or documentation images, .github/ for repository-level automation, and the root documentation set (README.md, CLAUDE.md, AGENTS.md). These directories SHALL NOT move under apps/.

#### Scenario: Resolving cross-platform content

- **WHEN** a contributor looks for specs, change proposals, or repository documentation
- **THEN** openspec/ and assets/ SHALL exist at the repository root and SHALL NOT exist under apps/

#### Scenario: Resolving repository automation

- **WHEN** a contributor looks for the continuous integration definition
- **THEN** .github/ SHALL exist at the repository root and SHALL NOT exist under apps/, because it governs every platform directory rather than any single one
