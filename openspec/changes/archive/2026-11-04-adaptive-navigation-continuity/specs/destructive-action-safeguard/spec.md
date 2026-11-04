## ADDED Requirements

### Requirement: Swipe deletion keeps the row until the deletion succeeds

A swipe action that starts a deletion requiring confirmation SHALL NOT remove the row from the presented list by itself. The row SHALL stay visible while the confirmation is shown, after the user cancels it, and after a confirmed deletion whose persistence fails; the row SHALL disappear only when the deletion succeeds, and removing it SHALL NOT terminate the app. The number of rows shown SHALL always equal the item count stated in the list header. The swipe delete control SHALL keep its red appearance, its label, and its identifier.

#### Scenario: Failed swipe deletion keeps the row on iPadOS 27

- **GIVEN** a category list with 生活雜貨, 服飾, 美妝, 精品 and lookup writes that fail
- **WHEN** the user swipes 生活雜貨, taps delete, confirms, and dismisses the failure notice on an iPad running iPadOS 27
- **THEN** 生活雜貨 is visible in the list and the header states 4 items with 4 rows shown

#### Scenario: Cancelling a swipe deletion keeps the row

- **GIVEN** a category list with 生活雜貨
- **WHEN** the user swipes 生活雜貨, taps delete, and dismisses the confirmation without confirming
- **THEN** 生活雜貨 remains visible and no persistence operation occurs

#### Scenario: Successful swipe deletion removes the row without terminating the app

- **GIVEN** a category list with 生活雜貨, 服飾, 美妝, 精品 and lookup writes that succeed
- **WHEN** the user swipes 生活雜貨, taps delete, and confirms on an iPad running iPadOS 27 or an iPhone running iOS 26
- **THEN** the app keeps running, 生活雜貨 is no longer shown, and the header states 3 items with 3 rows shown

### Requirement: A failed deletion reports the failure and keeps deletion available

When a confirmed lookup or campaign deletion fails to persist, the screen SHALL present the failure notice after the confirmation dismisses; for lookups this applies whether the deletion started from the swipe action or the context menu. After the user dismisses the failure notice, starting another deletion SHALL present the deletion confirmation again. A failure notice SHALL NOT be lost because it is requested while the confirmation is still dismissing, and the screen SHALL NOT be left in a state where deletion requests show nothing.

#### Scenario: Failure notice appears after a confirmed swipe deletion fails

- **GIVEN** a category list with 生活雜貨 and lookup writes that fail
- **WHEN** the user swipes 生活雜貨, taps delete, and confirms
- **THEN** the failure notice 操作失敗 is presented
- **AND** 生活雜貨 remains visible with the header stating 4 items

#### Scenario: Failure notice appears after a confirmed context menu deletion fails

- **GIVEN** a category list with 生活雜貨 and lookup writes that fail
- **WHEN** the user long-presses 生活雜貨, chooses delete from the context menu, and confirms
- **THEN** the failure notice 操作失敗 is presented
- **AND** 生活雜貨 remains visible with the header stating 4 items

#### Scenario: Deletion stays available after a failure notice

- **GIVEN** a confirmed deletion of 生活雜貨 failed and the user dismissed the failure notice
- **WHEN** the user starts deleting 服飾 from the swipe action
- **THEN** the deletion confirmation for 服飾 is presented

#### Scenario: Failure notice appears after a confirmed campaign deletion fails

- **GIVEN** the campaign detail of 三月日本團 is shown and campaign writes fail
- **WHEN** the user chooses 刪除開團 from the detail more menu and confirms
- **THEN** the failure notice 操作失敗 is presented
- **AND** after the user dismisses it, choosing 刪除開團 again presents the deletion confirmation
