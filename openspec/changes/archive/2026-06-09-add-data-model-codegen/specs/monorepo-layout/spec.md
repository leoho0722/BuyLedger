## MODIFIED Requirements

### Requirement: Reserved future directories are documented, not stubbed

The README project structure section SHALL document the full monorepo layout contract: apps/apple as the existing Apple project, apps/android, apps/web, and apps/backend as reserved future deployable units, and shared/data-model as the home of the cross-platform Data Model (created and populated by the data-model-codegen capability). Directories that remain reserved SHALL be marked as not yet created, and the repository SHALL NOT contain empty placeholder directories or placeholder-only files for platforms that have no code.

#### Scenario: Reading the layout contract

- **WHEN** a contributor reads the README project structure section
- **THEN** it SHALL show apps/apple and shared/data-model with their actual contents and SHALL list the remaining reserved future directories (apps/android, apps/web, apps/backend) as planned entries that do not yet exist on disk

#### Scenario: No placeholder directories on disk

- **WHEN** the repository tree is listed
- **THEN** apps/ SHALL contain only apple, shared/ SHALL contain only data-model with real content (schema document, generator sources, tests, and documentation), and no empty placeholder directory SHALL exist for platforms that have no code
