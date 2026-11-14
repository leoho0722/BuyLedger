## ADDED Requirements

### Requirement: View animations are disabled in UI test mode

In UI test mode the app SHALL disable UIKit view animations during harness activation, before the first scene is created, unless the launch declares the keep-view-animations argument. Neither the app nor the harness SHALL re-enable view animations afterwards in that process, and the harness SHALL NOT offer any other way to re-enable them. Launches without the UI test launch argument SHALL leave view animations untouched. The guarantee covers UIKit view animations only; whether SwiftUI transitions, the keyboard or system presentations also stop is not part of it. The purpose is to keep XCUITest's wait for the app to become idle from stalling after interface changes such as rotation, while UI tests that guard presentation timing races keep the production animation path.

UI tests that verify an alert or a confirmation dialog being presented after a sheet, a confirmation dialog or an alert closes SHALL launch with the keep-view-animations argument, because those races only occur while the closing animation runs.

#### Scenario: UI test launch disables view animations

- **WHEN** the app launches with the UI test launch argument and without the keep-view-animations argument
- **THEN** view animations are disabled once, before the first scene is created, and nothing in the app turns them back on while the process runs

##### Example: UI test launch arguments

| Launch arguments | View animation switch | Notes |
| ---------------- | --------------------- | ----- |
| `-BLUITest` with any seed profile | turned off once | every UI test that does not ask to keep animations |
| `-BLUITest -BLUITestKeepViewAnimations` | not touched | presentation race tests |

#### Scenario: Launch without the UI test argument leaves view animations untouched

- **WHEN** the app launches without the UI test launch argument
- **THEN** the harness does not touch the view animation switch, including when the keep-view-animations argument appears on its own

##### Example: launches outside UI test mode

| Launch arguments | View animation switch | Notes |
| ---------------- | --------------------- | ----- |
| no launch arguments | not touched | normal use of a Debug build |
| `-BLUITestKeepViewAnimations` only | not touched | the argument has no effect outside UI test mode |
| launch from `LaunchPerformanceTests` | not touched | launch timing keeps the production animation path |

#### Scenario: Presentation race tests keep animations

- **WHEN** a UI test verifies that a failure notice appears after a confirmation dialog closes, and that the confirmation can be opened again after the notice closes
- **THEN** the test launches with the keep-view-animations argument, and it fails when the failure notice shares one presentation state with the confirmation dialog

##### Example: deletion failure followed by a second deletion

- **GIVEN** the lookup management screen launched with `-BLUITest`, `-BLUITestLookupWriteFailure` and `-BLUITestKeepViewAnimations`
- **WHEN** the user confirms deleting an item, closes the failure notice, and requests the deletion again
- **THEN** the failure notice appears after the first confirmation closes and the deletion confirmation appears again
