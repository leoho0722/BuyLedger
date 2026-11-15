## MODIFIED Requirements

### Requirement: Reserved future directories are documented, not stubbed

The README project structure section SHALL document the full monorepo layout contract: apps/ios as the existing Apple project, apps/android as a reserved future deployable unit, and shared/ as the reserved home of cross-platform content. Directories that remain reserved SHALL be marked as not yet created, and the repository SHALL NOT contain empty placeholder directories or placeholder-only files for platforms or shared content that have no code.

#### Scenario: Reading the layout contract

- **WHEN** a contributor reads the README project structure section
- **THEN** it SHALL show apps/ios with its actual contents and SHALL list apps/android and shared/ as reserved directories that do not yet exist on disk

#### Scenario: No placeholder directories on disk

- **WHEN** the repository tree is listed
- **THEN** apps/ SHALL contain only ios, no shared/ directory SHALL exist, and no empty placeholder directory SHALL exist for platforms or shared content that have no code
