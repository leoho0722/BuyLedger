## MODIFIED Requirements

### Requirement: Deployable units are rooted under apps/

The repository SHALL place every deployable unit (platform app) in its own directory directly under apps/. The Apple app Xcode project SHALL reside at apps/apple, containing the Xcode project bundle, the app source root, the unit test target directory, and the UI test target directory. The Xcode project's internal structure, scheme name, and bundle identifiers SHALL remain unchanged by the relocation.

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

#### Scenario: iOS and iPadOS both build after relocation

- **WHEN** the iOS simulator and iPadOS simulator builds are run serially against apps/apple/BuyLedger.xcodeproj with the BuyLedger scheme
- **THEN** both builds SHALL succeed without any source, resource, or build-setting change inside the Xcode project, and no macOS build SHALL be attempted (the app supports iphoneos/iphonesimulator only)
