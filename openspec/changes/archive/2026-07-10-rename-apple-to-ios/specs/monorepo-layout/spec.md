## MODIFIED Requirements

### Requirement: Deployable units are rooted under apps/

The repository SHALL place every deployable unit (platform app) in its own directory directly under apps/. The Apple app Xcode project SHALL reside at apps/ios, containing the Xcode project bundle, the app source root, the unit test target directory, and the UI test target directory. The Xcode project's internal structure, scheme name, and bundle identifiers SHALL remain unchanged by the relocation.

#### Scenario: Locating the Apple project after restructure

- **WHEN** a developer or build tool resolves the Xcode project path
- **THEN** the project SHALL exist at apps/ios/BuyLedger.xcodeproj and no Xcode project SHALL exist under a repository-root BuyLedger/ directory

##### Example: directory relocation mapping

| Before | After |
| ------ | ----- |
| BuyLedger/BuyLedger.xcodeproj | apps/ios/BuyLedger.xcodeproj |
| BuyLedger/BuyLedger | apps/ios/BuyLedger |
| BuyLedger/BuyLedgerTests | apps/ios/BuyLedgerTests |
| BuyLedger/BuyLedgerUITests | apps/ios/BuyLedgerUITests |

#### Scenario: iOS and iPadOS both build after relocation

- **WHEN** the iOS simulator and iPadOS simulator builds are run serially against apps/ios/BuyLedger.xcodeproj with the BuyLedger scheme
- **THEN** both builds SHALL succeed without any source, resource, or build-setting change inside the Xcode project, and no macOS build SHALL be attempted (the app supports iphoneos/iphonesimulator only)

### Requirement: Reserved future directories are documented, not stubbed

The README project structure section SHALL document the full monorepo layout contract: apps/ios as the existing Apple project, apps/android as the sole reserved future deployable unit, and shared/data-model as the home of the cross-platform Data Model (created and populated by the data-model-codegen capability). Directories that remain reserved SHALL be marked as not yet created, and the repository SHALL NOT contain empty placeholder directories or placeholder-only files for platforms that have no code.

#### Scenario: Reading the layout contract

- **WHEN** a contributor reads the README project structure section
- **THEN** it SHALL show apps/ios and shared/data-model with their actual contents and SHALL list apps/android as the sole reserved future directory that does not yet exist on disk

#### Scenario: No placeholder directories on disk

- **WHEN** the repository tree is listed
- **THEN** apps/ SHALL contain only ios, shared/ SHALL contain only data-model with real content (schema document, generator sources, tests, and documentation), and no empty placeholder directory SHALL exist for platforms that have no code

### Requirement: Committed path references track the actual layout

Every committed file that anchors a path at the repository root (README.md, CLAUDE.md, AGENTS.md, .gitignore, and the normative bodies of active openspec spec files) SHALL reference the Apple project through the apps/ios prefix. No such file SHALL retain a stale root-anchored reference to a superseded layout — neither the pre-restructure BuyLedger/BuyLedger prefix nor the former apps/apple prefix. This contract covers hand-authored references only; it excludes archived changes under openspec/changes/archive/ (immutable history) and the auto-generated @trace metadata blocks in spec files (tool-managed, refreshed at archive time).

#### Scenario: Stale path scan returns empty

- **WHEN** the hand-authored root-anchored references (README.md, CLAUDE.md, AGENTS.md, .gitignore, and the normative bodies of active openspec spec files, excluding archived changes and auto-generated @trace metadata blocks) are searched for a superseded prefix (BuyLedger/BuyLedger or apps/apple)
- **THEN** the search SHALL return zero matches

##### Example: reference rewrite mapping

| File | Before | After |
| ---- | ------ | ----- |
| .gitignore | apps/apple/BuyLedger/Resources/Config.xcconfig | apps/ios/BuyLedger/Resources/Config.xcconfig |
| .gitignore | apps/apple/BuyLedger/Resources/GoogleService-Info.plist | apps/ios/BuyLedger/Resources/GoogleService-Info.plist |
| CLAUDE.md | apps/apple/BuyLedger/Shared/DesignSystem/ | apps/ios/BuyLedger/Shared/DesignSystem/ |
| README.md | --project-path apps/apple/BuyLedger.xcodeproj | --project-path apps/ios/BuyLedger.xcodeproj |
| AGENTS.md | apps/apple/CLAUDE.md | apps/ios/CLAUDE.md |
| openspec specs | apps/apple/BuyLedger/Features/... | apps/ios/BuyLedger/Features/... |
