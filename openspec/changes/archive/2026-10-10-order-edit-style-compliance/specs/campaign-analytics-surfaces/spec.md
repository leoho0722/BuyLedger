## ADDED Requirements

### Requirement: Order and campaign data are loaded when the app launches

The app SHALL request the orders and the campaigns as soon as the main interface appears after launch, without waiting for the user to visit the orders or campaigns tab, so that the overview's ongoing campaigns card and the insights per-campaign profit ranking show their content on a cold launch. A retry from the overview, the insights or the customers screen SHALL request the orders again. Automatic closing of campaigns past their closing date SHALL be evaluated and stored once per campaign load, by the campaigns side only.

#### Scenario: The overview shows ongoing campaigns on a cold launch

- **GIVEN** the stored data contains the ongoing campaign 四月韓國團 with orders
- **WHEN** the app is launched and the user stays on the overview without opening the campaigns tab
- **THEN** the overview shows the ongoing campaigns card listing 四月韓國團

#### Scenario: Insights shows the per-campaign ranking on a cold launch

- **GIVEN** the stored data contains campaigns with attributed orders
- **WHEN** the app is launched and the user opens the insights tab first
- **THEN** the per-campaign profit ranking lists those campaigns without the user visiting the campaigns tab

#### Scenario: Retrying after a failed first load shows the data

- **GIVEN** the first read of the orders fails and the overview shows the load failure with a retry button
- **WHEN** the user taps retry and the second read succeeds
- **THEN** the overview shows the order data

#### Scenario: Opening the orders tab after a failed first load requests the orders again

- **GIVEN** the first read of the orders at launch fails
- **WHEN** the user opens the orders tab and the next read succeeds
- **THEN** the orders list shows the orders without any other screen having retried

#### Scenario: A campaign past its closing date is closed once

- **GIVEN** the ongoing campaign 三月日本團 has a closing date before the injected current time
- **WHEN** the campaigns are loaded at launch
- **THEN** 三月日本團 is stored as closed exactly once, and the orders side performs no campaign write
