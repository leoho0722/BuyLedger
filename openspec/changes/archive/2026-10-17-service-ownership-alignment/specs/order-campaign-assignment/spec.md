## MODIFIED Requirements

### Requirement: Renaming a campaign cascades to its orders

The system SHALL replace every occurrence of the old campaign name inside each order's campaign list when a campaign is renamed, keeping persisted orders and the in-memory order copies consistent in a single update. The renamed campaign and the stored orders SHALL be written in a single save: either both reflect the new name or, when the save fails, both keep the old name and the user is told that the campaign could not be saved. A rename SHALL NOT leave the campaign saved under its new name while its orders still carry the old name.

#### Scenario: Cascade rename

- **WHEN** a campaign named "三月日本團" is renamed to "三月日本團 (補)"
- **THEN** every order whose campaign list previously contained "三月日本團" now contains "三月日本團 (補)" in its place, in both persistence and the in-memory order list, with other list elements unchanged

#### Scenario: A failed rename keeps the campaign and its orders on the old name

- **WHEN** a campaign is renamed and the save fails
- **THEN** the stored campaign and every stored order keep the old name, the in-memory orders are not rewritten, and a dialog states that the campaign save failed

##### Example: rename with a failing save

- **GIVEN** the campaign 三月日本團 has orders A and B, and saving is made to fail
- **WHEN** the user renames it to 三月日本團 (補) and saves
- **THEN** the stored campaign is still 三月日本團, orders A and B still contain 三月日本團, and the dialog message is 開團儲存失敗，請稍後再試。
