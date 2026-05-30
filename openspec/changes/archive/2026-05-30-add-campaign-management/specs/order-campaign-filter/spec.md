## ADDED Requirements

### Requirement: Filter orders by campaign status

The system SHALL let the orders list filter by campaign status with three options: all, ongoing, and closed. Selecting all SHALL apply no campaign-status restriction. The ongoing and closed options SHALL match an order through the status of the campaign it is assigned to.

#### Scenario: Filter to ongoing campaigns

- **WHEN** the user selects the ongoing campaign-status filter
- **THEN** only orders assigned to a campaign whose status is ongoing are shown

##### Example: campaign-status filter

| Selected filter | Order's campaign status | Order shown |
| --------------- | ----------------------- | ----------- |
| all             | ongoing                 | yes         |
| all             | unassigned              | yes         |
| ongoing         | ongoing                 | yes         |
| ongoing         | closed                  | no          |
| closed          | closed                  | yes         |
| closed          | ongoing                 | no          |

### Requirement: Filter orders by a specific campaign

The system SHALL let the orders list filter by a specific campaign name. The campaign-status filter and the specific-campaign filter SHALL compose with the existing search, order-status, date-period, category, and payment-method filters so that all active filters apply together.

#### Scenario: Filter by a specific campaign

- **WHEN** the user selects a specific campaign in the orders filter
- **THEN** only orders assigned to that campaign are shown

#### Scenario: Campaign filter composes with category filter

- **WHEN** the user selects a specific campaign and a specific category
- **THEN** only orders assigned to that campaign and belonging to that category are shown
