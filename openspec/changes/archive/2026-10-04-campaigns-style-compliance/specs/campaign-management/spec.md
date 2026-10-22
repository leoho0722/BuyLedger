## MODIFIED Requirements

### Requirement: Campaign list groups campaigns by open date with selectable granularity

The campaign list SHALL group campaigns into sections by their open date, and SHALL let the user switch the grouping granularity among day, month, and year. When grouping by month, each month section SHALL be sub-grouped by day; when grouping by year, each year section SHALL be sub-grouped by month and each campaign row SHALL additionally display its open date. Within any group, campaigns SHALL be ordered by open date from newest to oldest, and campaigns with exactly the same open date SHALL be ordered by name.

The sections SHALL be derived from the campaign list feature's state rather than computed by the list view. Relative day titles ("今天", "昨天") SHALL be computed against the current date and calendar recorded in the campaign list feature's state from the injected date and calendar dependencies; the list view SHALL NOT read the current date itself. The recorded date SHALL be refreshed each time the list screen's appearance task runs, each time the app returns to the foreground, and each time the system reports a significant time change, such as the day changing while the app stays in the foreground, so that the titles follow the new day without the user leaving the list. Between these events the titles SHALL NOT change. Returning to the list from a campaign's detail is not guaranteed to run the appearance task.

#### Scenario: Switch grouping to month

- **WHEN** the user selects month grouping
- **THEN** the list shows top-level sections titled by month (for example "2026年5月"), each sub-grouped by day

#### Scenario: Year grouping keeps the open date visible

- **WHEN** the user selects year grouping
- **THEN** the list shows year sections sub-grouped by month AND each campaign row still shows its open date

#### Scenario: Relative day titles follow the recorded date

- **WHEN** the campaign list feature has recorded the current date
- **THEN** day sections whose date equals the recorded date are titled "今天", the previous day is titled "昨天", and older days in the same year show the month, day, and abbreviated weekday

##### Example: titles against a recorded date

- **GIVEN** day grouping, a recorded date of 2026-05-12 10:00 in a calendar fixed to UTC, the zh-Hant locale, and campaigns opened on 2026-05-12, 2026-05-11, and 2026-05-08 (a Friday)
- **WHEN** the list renders its sections
- **THEN** the section titles are "今天", "昨天", and the zh-Hant month-day-weekday form of 2026-05-08 (for example "5月8日週五") in that order

#### Scenario: Titles refresh when the app returns to the foreground

- **WHEN** the list has recorded a date, the app moves to the background, the day changes, and the app returns to the foreground
- **THEN** the recorded date is replaced with the current date when the app becomes active, without the list's appearance task running again

##### Example: returning after midnight

- **GIVEN** day grouping in a calendar fixed to UTC, a recorded date of 2026-05-12 10:00, and campaigns opened on 2026-05-12 and 2026-05-11
- **WHEN** the app goes to the background and returns to the foreground at 2026-05-13 00:30
- **THEN** the section for 2026-05-12 is titled "昨天" and the section for 2026-05-11 shows its zh-Hant month-day-weekday form (2026-05-11 is a Monday)

#### Scenario: Titles refresh when the day changes while the app stays in the foreground

- **WHEN** the list screen stays on screen in the foreground and the system reports a significant time change, such as passing midnight
- **THEN** the recorded date is replaced with the current date without the list's appearance task running again and without the app leaving the foreground

##### Example: midnight passes with the list on screen

- **GIVEN** day grouping in a calendar fixed to UTC, a recorded date of 2026-05-12 23:50, and a campaign opened on 2026-05-12
- **WHEN** the system reports a significant time change at 2026-05-13 00:00 while the list is on screen
- **THEN** the section for 2026-05-12 is titled "昨天"
