## MODIFIED Requirements

### Requirement: Settings are available from the first frame

The persisted preferences SHALL be read once at launch and held by the root state from launch, so that the first rendered frame already reflects them, including the overview's monthly goal. They SHALL be supplied to the settings state when the settings screen is pushed rather than loaded by an action afterwards. The settings feature SHALL be the only writer of the persisted preferences, and after each write it SHALL report the written preferences so that the root state's copy and every value derived from it stay current; refreshing another screen SHALL NOT re-read them from storage.

#### Scenario: The first frame uses the persisted language

- **WHEN** the app launches with English stored as the interface language
- **THEN** the first frame is rendered in English, without first rendering the default language

##### Example: state at construction

- **GIVEN** stored settings of English, USD, and a monthly goal of 120,000
- **WHEN** the root state is constructed at launch, before any action is processed
- **THEN** the root state's preferences already hold English, USD, and 120,000, and a settings state built from them when the settings screen is pushed holds the same values

#### Scenario: The overview goal uses the stored goal from the first frame

- **WHEN** the app launches with a stored monthly net profit goal that differs from the documented default
- **THEN** the overview's goal progress uses the stored goal from the first frame, without waiting for the settings screen to be opened

##### Example: stored goal of 50,000

- **GIVEN** the stored monthly net profit goal is 50,000
- **WHEN** the root state is constructed at launch, before any action is processed
- **THEN** the overview state's monthly goal is 50,000, not the default 80,000

#### Scenario: A settings write updates the root's preferences

- **WHEN** the user changes a preference on the settings screen
- **THEN** the value is written to storage once, and the root state's preferences and the values derived from them hold the new value once the change has been handled

##### Example: changing the monthly goal

- **GIVEN** the root state's preferences hold a monthly goal of 80,000 and the settings screen is pushed
- **WHEN** the user enters 120,000 in the monthly goal field
- **THEN** storage holds 120,000, the root state's preferences hold 120,000, and the overview state's monthly goal is 120,000

#### Scenario: A dashboard refresh does not re-read settings

- **WHEN** the user pulls to refresh the dashboard
- **THEN** orders are reloaded and the in-memory settings are left as they are

##### Example: storage reads during a refresh

- **GIVEN** the settings storage records every read
- **WHEN** the dashboard refresh is handled
- **THEN** the only action forwarded is the orders load, and the storage read count stays at 0
