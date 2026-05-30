## ADDED Requirements

### Requirement: An order can be assigned to a single campaign

The system SHALL allow an order to be assigned to at most one campaign, stored as the campaign name. An order whose campaign name is empty SHALL be treated as unassigned and SHALL NOT belong to any campaign.

#### Scenario: Assign an order to a campaign

- **WHEN** the user edits an order and selects an existing campaign
- **THEN** the order records that campaign name

#### Scenario: Unassigned order

- **WHEN** an order has an empty campaign name
- **THEN** the order is excluded from every campaign's distribution and settlement

### Requirement: The order editor selects from existing campaigns only

The system SHALL let the order editor choose among existing campaigns and an unassigned option, and SHALL NOT create a new campaign from within the order editor.

#### Scenario: Editor offers existing campaigns

- **WHEN** the user opens the campaign selector in the order editor
- **THEN** the selector offers the existing campaigns and an unassigned option, with no create-campaign action

### Requirement: Renaming a campaign cascades to its orders

The system SHALL update the campaign name on every assigned order when a campaign is renamed, keeping persisted orders and the in-memory order copies consistent in a single update.

#### Scenario: Cascade rename

- **WHEN** a campaign named "三月日本團" is renamed to "三月日本團 (補)"
- **THEN** every order previously assigned to "三月日本團" references "三月日本團 (補)" in both persistence and the in-memory order list
