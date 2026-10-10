## MODIFIED Requirements

### Requirement: The order editor selects from existing campaigns only

The system SHALL let the order editor choose among existing campaigns only, and SHALL NOT create a new campaign from within the order editor. The editor's selectable campaign list SHALL include only campaigns whose status is ongoing, EXCEPT that any campaign already assigned to the order being edited — a single order's existing campaign, or a campaign carried in from the source orders of a merge — SHALL remain selectable even when its status is closed, so an existing assignment is never dropped by the editor. The unassigned (未歸團) option SHALL always be available. Every entry point that opens the editor (a new order opened from the orders tab or the overview, editing an existing order, or a merge confirmation) SHALL supply the campaigns it already holds through one shared construction when it creates the editor; that construction SHALL evaluate automatic closing against the injected current time at creation, so every entry point presents the same filtered list. The editor SHALL NOT fetch campaigns from storage when it appears. In merge contexts — a merge confirmation draft, or editing an order whose merged-source list is non-empty — the editor SHALL offer a multi-select campaign picker: tapping a row toggles its selection without dismissing the sheet, and the sheet provides an explicit done action. For every other order, the editor SHALL keep the existing single-select campaign selector with an unassigned option, and the selection SHALL be stored as a one-element campaign list (unassigned as an empty list). An empty selection SHALL be valid and displayed as unassigned (未歸團) on the campaign trigger row; a non-empty multi-selection SHALL be displayed joined by "、".

#### Scenario: Only ongoing campaigns are offered

- **WHEN** the user opens the campaign selector on an order that carries no closed campaign
- **THEN** the selector lists the unassigned option plus only the campaigns whose status is ongoing, and omits every closed campaign

##### Example: closed campaigns filtered out, assigned closed campaign kept

| Existing campaigns (status)                          | Order's current campaigns | Selectable options besides 未歸團 |
| ---------------------------------------------------- | ------------------------- | --------------------------------- |
| May-JP (ongoing), April-KR (closed)                  | []                        | May-JP                            |
| May-JP (ongoing), April-KR (closed)                  | [April-KR]                | April-KR, May-JP                  |
| June-US (ongoing), May-JP (ongoing), April-KR (closed) | []                      | June-US, May-JP                   |

#### Scenario: An already-assigned closed campaign stays selectable

- **WHEN** the user edits an order assigned to "April-KR" whose status is now closed
- **THEN** the selector still lists "April-KR" alongside the ongoing campaigns, so the existing assignment is preserved and re-selectable

#### Scenario: A new order from the overview offers the same campaigns as one from the orders tab

- **GIVEN** the campaigns May-JP (ongoing) and April-KR (closed) are loaded
- **WHEN** the user opens a new order from the overview, and separately opens a new order from the orders tab
- **THEN** both editors offer 未歸團 and May-JP, without fetching campaigns when the editor appears

#### Scenario: A campaign past its closing date is treated as closed when the editor opens

- **GIVEN** the campaign May-JP is stored as ongoing with an automatic closing date of 2026-05-31 and the injected current time is 2026-06-01
- **WHEN** the user opens a new order
- **THEN** May-JP is not offered, because automatic closing is evaluated against the injected current time when the editor is created

#### Scenario: Merge confirmation form offers ongoing campaigns as toggles

- **WHEN** the user opens the campaign selector inside a merge confirmation form
- **THEN** the selector lists the ongoing campaigns, plus any campaign already carried in from the source orders, as toggleable rows, with no create-campaign action

#### Scenario: Regular orders keep single selection

- **WHEN** the user edits an order that was not produced by a merge and opens the campaign selector
- **THEN** the selector behaves as the existing single-select control with an unassigned option, and choosing the ongoing campaign "May-JP" stores the campaign list ["May-JP"]

#### Scenario: Empty selection means unassigned

- **WHEN** the user deselects every campaign in a merge confirmation form and confirms
- **THEN** the order's campaign list is empty and the trigger row displays 未歸團
