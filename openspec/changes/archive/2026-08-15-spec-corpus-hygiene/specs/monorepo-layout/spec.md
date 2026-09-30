## MODIFIED Requirements

### Requirement: Committed path references track the actual layout

Every committed file that anchors a path at the repository root (README.md, CLAUDE.md, AGENTS.md, .gitignore, and the normative bodies of active openspec spec files) SHALL reference the Apple project through the apps/ios prefix. No such file SHALL retain a stale root-anchored reference to a superseded layout — neither the pre-restructure BuyLedger/BuyLedger prefix nor the former apps/apple prefix. This contract covers hand-authored references only; it excludes archived changes under openspec/changes/archive/ (immutable history) and the auto-generated @trace metadata blocks in spec files (tool-managed, refreshed at archive time).

Because the @trace blocks are exempt from this contract, they accumulate references to files that no longer exist. A reader SHALL therefore treat a @trace block as a historical record of which change last touched a requirement, and SHALL NOT treat the paths it lists as a description of the current codebase. Tooling and agent instructions that read specs SHALL state this explicitly, so that a reader does not infer current structure from tool-generated history.

#### Scenario: Stale path scan returns empty

- **WHEN** the hand-authored root-anchored references (README.md, CLAUDE.md, AGENTS.md, .gitignore, and the normative bodies of active openspec spec files, excluding archived changes and auto-generated @trace metadata blocks) are searched for a superseded prefix (BuyLedger/BuyLedger or apps/apple)
- **THEN** the search SHALL return zero matches, except where the superseded prefix appears as the subject of this contract itself

#### Scenario: Trace blocks are not read as current structure

- **WHEN** a reader or an agent consults a spec file to determine which files implement a requirement
- **THEN** the guidance available to them states that @trace paths are historical and unverified, so the current codebase is determined by searching it rather than by reading the trace block

## ADDED Requirements

### Requirement: Purpose sections are written for policy specs and deliberately left blank for feature specs

A spec whose scope is not evident from its directory name SHALL carry a Purpose section stating what it covers and naming at least one adjacent capability it does not cover. This applies to cross-cutting policy specs, whose boundaries overlap and which are otherwise indistinguishable from one another.

A spec whose directory name already delimits its scope MAY leave its Purpose section at the tool-generated placeholder. That omission SHALL be recorded as a deliberate decision rather than treated as an outstanding defect, because it costs reading time rather than correctness.

Purpose sections SHALL be written in Traditional Chinese, following the project's documentation language. Requirement and scenario bodies SHALL remain in English, because they use normative vocabulary that the tooling and the existing corpus express in English.

#### Scenario: A policy spec states its boundary

- **WHEN** a cross-cutting policy spec is read
- **THEN** its Purpose section states what the spec covers and names at least one adjacent capability that it does not cover

#### Scenario: Purpose does not introduce obligations

- **WHEN** a Purpose section is written
- **THEN** it describes scope without using normative vocabulary, so that it cannot be mistaken for a requirement

#### Scenario: Feature spec blanks are a recorded decision

- **WHEN** a feature spec is found with a placeholder Purpose
- **THEN** that is a recorded deliberate omission rather than an unaddressed finding
