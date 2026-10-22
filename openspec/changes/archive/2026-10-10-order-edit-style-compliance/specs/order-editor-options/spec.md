## Purpose

Defines the order editor's inputs and save precondition: where its selectable option lists come from (so every entry point opens it with the same order sources, categories, payment methods, reconciliation statuses and currency codes, and the editor never reads option data from storage on its own), how fee rate percentages are converted, and when a save is accepted.

## ADDED Requirements

### Requirement: The order editor receives its option lists when it is created

Every entry point that opens the order editor — a new order from the orders tab, a new order from the overview, editing an existing order, and a merge confirmation — SHALL supply the order sources, categories, payment methods, reconciliation statuses and currency codes when it creates the editor, built by one shared construction from the data the app already holds. The lookup lists SHALL be the same lists the orders tab offers for that kind, including values already used by existing orders. When the currency list the app loads from its cache at launch is non-empty, the currency codes SHALL come from that list; behavior while that list is empty is unchanged by this requirement. The editor SHALL NOT fetch any option list from storage when it appears; loading the photos of an existing order is not an option list and remains part of the editor.

#### Scenario: The overview and the orders tab open the editor with the same options

- **GIVEN** the categories 美妝 and 服飾 and the order sources IG and LINE are loaded
- **WHEN** the user opens a new order from the overview, and separately opens a new order from the orders tab
- **THEN** both editors offer the categories 美妝 and 服飾 and the order sources IG and LINE

#### Scenario: Showing the editor reads no option data from storage

- **GIVEN** a test renders the order editor for a new order, or for an existing order whose photos are already loaded, with no data service overridden
- **WHEN** the editor appears
- **THEN** no option-list service is called, so the full snapshot test class completes without an unimplemented-dependency issue from the order editor

#### Scenario: Currency codes come from the list loaded at launch

- **GIVEN** the cached currency list contains TWD, JPY and EUR
- **WHEN** the user opens a new order after launch
- **THEN** the currency picker offers TWD, JPY and EUR

### Requirement: Fee rate percentages keep the value the user entered

The order editor SHALL convert a fee rate entered as a percentage to its stored fraction with decimal arithmetic, so that for an entry from 0 to 100 with at most two decimal places the stored rate is exactly the entered percentage divided by one hundred and redisplaying it shows the entered value. An entry with more than two decimal places SHALL be stored rounded half away from zero to two decimal places of the percentage, and the field SHALL display the same rounded value. Showing a rate without the user changing it SHALL NOT alter the draft. Entries outside 0 to 100 keep the existing behavior of being clamped to that range when the order is saved.

#### Scenario: A two-decimal percentage is stored exactly

- **WHEN** the user enters 4.56 in the card fee rate field
- **THEN** the draft's card fee rate is exactly 0.0456 and the field shows 4.56

#### Scenario: Viewing a rate field without editing it leaves the draft unchanged

- **WHEN** the user moves focus into the platform fee rate field and out again without typing
- **THEN** the draft is unchanged and the editor is not dirty

##### Example: percentage entry

| Entered percentage | Stored rate |
| --- | --- |
| 4.56 | 0.0456 |
| 1.5 | 0.015 |
| 2.8 | 0.028 |
| 4.567 | 0.0457 |
| 4.565 | 0.0457 |

### Requirement: The order editor refuses to save until the required fields are filled

The order editor SHALL save only when the customer name and the order source are non-empty after trimming whitespace and at least one category is non-empty after trimming. When a save is requested while any of these is missing, nothing SHALL be written and the editor SHALL stay open, regardless of whether the request came from the enabled save button or from any other path.

#### Scenario: A save request with a missing required field writes nothing

- **GIVEN** a new order whose customer name is "林書宇" and whose order source is empty
- **WHEN** a save is requested
- **THEN** no order is written and the editor stays open

#### Scenario: A complete draft is saved once

- **GIVEN** a new order with customer name "林書宇", order source "IG" and category "美妝"
- **WHEN** a save is requested
- **THEN** the order is written exactly once and the editor closes
