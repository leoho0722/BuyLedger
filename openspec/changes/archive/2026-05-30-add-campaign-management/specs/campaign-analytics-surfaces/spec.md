## ADDED Requirements

### Requirement: Dashboard shows an ongoing campaigns card

The dashboard SHALL show a card listing the ongoing campaigns, each with its derived progress and total amount. When there are no ongoing campaigns, the dashboard SHALL hide the card entirely rather than show an empty card.

#### Scenario: Card lists ongoing campaigns

- **WHEN** there is at least one ongoing campaign
- **THEN** the dashboard shows the ongoing campaigns card with each ongoing campaign's progress and amount

#### Scenario: Card hidden when none ongoing

- **WHEN** there are no ongoing campaigns
- **THEN** the dashboard does not render the ongoing campaigns card

### Requirement: Insights shows a per-campaign profit ranking

The insights view SHALL show a bar chart that ranks campaigns by profit, where each campaign's profit is computed by aggregating its member orders. Campaigns without member orders SHALL be excluded from the ranking.

#### Scenario: Profit ranking is shown

- **WHEN** at least one campaign has member orders
- **THEN** insights shows a bar chart of campaigns ranked by profit

##### Example: profit ranking order

- **GIVEN** campaigns with profits Camp-A=3000, Camp-B=1200, Camp-C=4500
- **WHEN** the ranking is computed
- **THEN** the bars appear in order Camp-C, Camp-A, Camp-B

### Requirement: Selecting a campaign navigates to its detail

The system SHALL provide a navigation action that switches to the campaign tab and opens the selected campaign's detail. Tapping a campaign in the dashboard ongoing campaigns card or in the insights profit ranking SHALL trigger this navigation.

#### Scenario: Navigate from the dashboard card

- **WHEN** the user taps a campaign in the dashboard ongoing campaigns card
- **THEN** the app switches to the campaign tab and opens that campaign's detail

#### Scenario: Navigate from the insights ranking

- **WHEN** the user taps a campaign bar in the insights profit ranking
- **THEN** the app switches to the campaign tab and opens that campaign's detail
