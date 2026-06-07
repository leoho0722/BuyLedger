## ADDED Requirements

### Requirement: Deployable units are rooted under apps/

The repository SHALL place every deployable unit (platform app or backend service) in its own directory directly under apps/. The Apple multiplatform Xcode project SHALL reside at apps/apple, containing the Xcode project bundle, the app source root, the unit test target directory, and the UI test target directory. The Xcode project's internal structure, scheme name, and bundle identifiers SHALL remain unchanged by the relocation.

#### Scenario: Locating the Apple project after restructure

- **WHEN** a developer or build tool resolves the Xcode project path
- **THEN** the project SHALL exist at apps/apple/BuyLedger.xcodeproj and no Xcode project SHALL exist under a repository-root BuyLedger/ directory

##### Example: directory relocation mapping

| Before | After |
| ------ | ----- |
| BuyLedger/BuyLedger.xcodeproj | apps/apple/BuyLedger.xcodeproj |
| BuyLedger/BuyLedger | apps/apple/BuyLedger |
| BuyLedger/BuyLedgerTests | apps/apple/BuyLedgerTests |
| BuyLedger/BuyLedgerUITests | apps/apple/BuyLedgerUITests |

#### Scenario: All three Apple platforms still build after relocation

- **WHEN** the iOS simulator, iPadOS simulator, and macOS builds are run serially against apps/apple/BuyLedger.xcodeproj with the BuyLedger scheme
- **THEN** all three builds SHALL succeed without any source, resource, or build-setting change inside the Xcode project

### Requirement: Cross-platform content stays at the repository root

The repository SHALL keep platform-neutral content at the root: openspec/ for specs and change proposals, assets/ for repository-level marketing or documentation images, and the root documentation set (README.md, CLAUDE.md, AGENTS.md). These directories SHALL NOT move under apps/.

#### Scenario: Resolving cross-platform content

- **WHEN** a contributor looks for specs, change proposals, or repository documentation
- **THEN** openspec/ and assets/ SHALL exist at the repository root and SHALL NOT exist under apps/

### Requirement: Reserved future directories are documented, not stubbed

The README project structure section SHALL document the full monorepo layout contract: apps/apple as the existing Apple project, apps/android, apps/web, and apps/backend as reserved future deployable units, and shared/data-model as the reserved location for the cross-platform Data Model. Reserved directories SHALL be marked as not yet created, and the repository SHALL NOT contain empty placeholder directories or placeholder-only files for platforms that have no code.

#### Scenario: Reading the layout contract

- **WHEN** a contributor reads the README project structure section
- **THEN** it SHALL show apps/apple with its actual contents and SHALL list the reserved future directories as planned entries that do not yet exist on disk

#### Scenario: No placeholder directories on disk

- **WHEN** the repository tree is listed after the restructure
- **THEN** apps/ SHALL contain only apple, and no shared/ directory SHALL exist on disk

### Requirement: Committed path references track the actual layout

Every committed file that anchors a path at the repository root (README.md, CLAUDE.md, .gitignore, and openspec spec files) SHALL reference the Apple project through the apps/apple prefix. No committed file SHALL retain a stale root-anchored reference to the pre-restructure layout.

#### Scenario: Stale path scan returns empty

- **WHEN** committed files are searched for the substring BuyLedger/BuyLedger (the old project-root prefix, which no valid post-restructure path contains)
- **THEN** the search SHALL return zero matches across README.md, CLAUDE.md, .gitignore, and openspec/

##### Example: reference rewrite mapping

| File | Before | After |
| ---- | ------ | ----- |
| .gitignore | BuyLedger/BuyLedger/Resources/Config.xcconfig | apps/apple/BuyLedger/Resources/Config.xcconfig |
| .gitignore | BuyLedger/BuyLedger/Resources/GoogleService-Info.plist | apps/apple/BuyLedger/Resources/GoogleService-Info.plist |
| CLAUDE.md | BuyLedger/BuyLedger/Shared/DesignSystem/ | apps/apple/BuyLedger/Shared/DesignSystem/ |
| CLAUDE.md | BuyLedger/BuyLedgerTests/ | apps/apple/BuyLedgerTests/ |
| README.md | --project-path BuyLedger/BuyLedger.xcodeproj | --project-path apps/apple/BuyLedger.xcodeproj |
| openspec specs | BuyLedger/BuyLedger/Features/... | apps/apple/BuyLedger/Features/... |
