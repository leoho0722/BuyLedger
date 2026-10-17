## ADDED Requirements

### Requirement: Overview and insights figures follow a recorded current date

The overview's month figures (revenue, cost, profit, margin, order count, goal progress, the twelve-month profit trend and their month-over-month deltas), the overview's date subtitle (formatted with the recorded calendar and its time zone), and the insights trend bars, period comparison and order heatmap SHALL be computed against a current date and calendar recorded in the overview feature's state and the insights feature's state respectively. Each feature's reducer SHALL record the date and calendar from the injected date and calendar dependencies. The overview and insights views SHALL NOT read the current date, the calendar, or the time zone themselves, and no production source SHALL read the device's current calendar.

The recorded date SHALL be refreshed each time the screen's appearance task runs, each time the user retries after a load failure, each time the app returns to the foreground, and each time the system reports a significant time change, such as passing midnight while the app stays in the foreground. Each of these events SHALL replace the recorded date even when one has already been recorded. Between these events the recorded date SHALL NOT change. Whenever the orders, the campaigns, the monthly goal, or the selected insights range change, the figures SHALL be recomputed immediately against the recorded date, without waiting for one of these events. A retry SHALL record the new date before it requests the orders again.

A load failure SHALL be shown as the failure view with its retry button whether or not a date has been recorded. Otherwise, while no date has been recorded, each screen SHALL show its loading placeholder. It SHALL NOT show the onboarding, the empty state, or figures computed from any other date.

The heatmap's weekday labels SHALL be taken from the recorded calendar localized to the app language, ordered from Monday to Sunday.

#### Scenario: Overview month figures follow the recorded date

- **WHEN** the overview feature has recorded a date
- **THEN** its month figures count only the orders inside the recorded date's month, and the previous-month comparison uses the month before it

##### Example: one order in each month

- **GIVEN** a recorded date of 2026-05-12 10:00 in a calendar fixed to UTC, and two revenue-attributed orders: one on 2026-05-03 with revenue 1000, one on 2026-04-20 with revenue 800
- **WHEN** the overview computes its figures
- **THEN** this month's revenue is 1000, this month's order count is 1, and the revenue delta is the Decimal 0.25

#### Scenario: Figures follow data changes without changing the recorded date

- **WHEN** the orders, the campaigns, the monthly goal, or the insights range change while a date is recorded
- **THEN** the figures are recomputed against the same recorded date

##### Example: a new order in the current month

- **GIVEN** a recorded date of 2026-05-12 10:00 in a calendar fixed to UTC and one revenue-attributed order on 2026-05-03 with revenue 1000
- **WHEN** an order on 2026-05-10 with revenue 500 is added to the overview's orders
- **THEN** this month's revenue is 1500 and the recorded date is still 2026-05-12 10:00

#### Scenario: Figures move to the new month when the app returns to the foreground

- **WHEN** the overview has recorded a date, the app moves to the background, the month changes, and the app returns to the foreground
- **THEN** the previously recorded date is replaced with the current date when the app becomes active, without the overview's appearance task running again

##### Example: returning after the month ends

- **GIVEN** a recorded date of 2026-05-31 23:50 in a calendar fixed to UTC, and one revenue-attributed order on 2026-05-31 with revenue 1000
- **WHEN** the app goes to the background and returns to the foreground at 2026-06-01 00:30
- **THEN** this month's revenue is 0 and this month's order count is 0, and the 2026-05-31 order counts toward the previous month

#### Scenario: Insights follow a significant time change while on screen

- **WHEN** the insights screen stays on screen in the foreground and the system reports a significant time change
- **THEN** the recorded date is replaced with the current date without the insights appearance task running again

##### Example: midnight passes on the thirty-day range

- **GIVEN** the thirty-day range, a recorded date of 2026-05-12 23:50 in a calendar fixed to UTC
- **WHEN** the system reports a significant time change at 2026-05-13 00:00
- **THEN** the last trend bar is labelled "05/13" instead of "05/12"

#### Scenario: A retry records the date before reloading

- **WHEN** the overview or the insights screen shows a load failure and the user taps retry
- **THEN** the feature records the current date and then asks the root feature to load the orders again

##### Example: retrying the next morning

- **GIVEN** the overview recorded 2026-05-12 10:00 in a calendar fixed to UTC and then showed a load failure
- **WHEN** the user taps retry at 2026-05-13 09:00
- **THEN** the recorded date becomes 2026-05-13 09:00 before the refresh request is sent, and the month figures use May 2026

#### Scenario: No figures are shown before a date is recorded

- **WHEN** the orders have finished loading but the overview or the insights feature has not recorded a date
- **THEN** the screen shows its loading placeholder instead of the onboarding, the empty state, or any figure, while a load failure is still shown as the failure view

##### Example: loaded orders without a recorded date

| Load state | Orders | Recorded date | Overview shows | Insights shows |
| ---------- | ------ | ------------- | -------------- | -------------- |
| failed | 0 | none | failure view with retry | failure view with retry |
| loading | 0 | 2026-05-12 10:00 | loading placeholder | loading placeholder |
| loaded | 3 | none | loading placeholder | loading placeholder |
| loaded | 0 | none | loading placeholder | loading placeholder |
| loaded | 0 | 2026-05-12 10:00 | onboarding | empty state |
| loaded | 3 | 2026-05-12 10:00 | overview figures | analytics |

#### Scenario: Heatmap weekday labels follow the app language

- **WHEN** the insights heatmap renders its weekday labels
- **THEN** the labels come from the recorded calendar localized to the app language, starting on Monday

##### Example: labels per app language

| App language | Weekday labels from Monday to Sunday |
| ------------ | ------------------------------------ |
| Traditional Chinese | 一, 二, 三, 四, 五, 六, 日 |
| English | M, T, W, T, F, S, S |

#### Scenario: Views do not read the current date

- **WHEN** the production sources are scanned
- **THEN** no view type declares an injected dependency, and no source reads the device's current calendar
