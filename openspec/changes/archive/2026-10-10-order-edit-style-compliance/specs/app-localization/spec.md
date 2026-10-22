## ADDED Requirements

### Requirement: Date section titles and timestamps follow the injected calendar's time zone

Date section titles that group orders or campaigns by day, month or year, and the full timestamp shown in the order editor, SHALL be formatted with the time zone of the injected calendar that grouped them, so a date is never grouped under one day and titled with another. The formatting SHALL live in one shared place used by both the orders and the campaigns features. The full timestamp SHALL always print a Gregorian year, month and day; only the time zone comes from the injected calendar, so a device set to another calendar system does not change the printed year.

#### Scenario: An order near midnight is titled with the day it is grouped under

- **GIVEN** the injected calendar uses Asia/Taipei, the device time zone is America/Los_Angeles, and an order was created at 2026-04-26 00:30 Taipei time
- **WHEN** the orders list groups the order by day
- **THEN** the order appears under the section titled for 2026-04-26

#### Scenario: Campaign month titles use the injected time zone

- **GIVEN** the injected calendar uses Asia/Taipei and a campaign started at 2026-05-01 00:30 Taipei time
- **WHEN** the campaigns list groups campaigns by month
- **THEN** the campaign appears under the section titled for May 2026

#### Scenario: The order editor shows the timestamp in the injected time zone

- **GIVEN** the injected calendar uses Asia/Taipei and an order dated 2026-04-26 14:30 Taipei time
- **WHEN** the user opens the order editor
- **THEN** the timestamp shown for the order is 2026/04/26 14:30:00

#### Scenario: The editor timestamp keeps the Gregorian year under another calendar system

- **GIVEN** the injected calendar is the Republic of China calendar in Asia/Taipei and an order dated 2026-04-26 14:30 Taipei time
- **WHEN** the user opens the order editor
- **THEN** the timestamp shown for the order is 2026/04/26 14:30:00
