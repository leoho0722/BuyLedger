## MODIFIED Requirements

### Requirement: Summary input scope is the filtered list's product details

The summary input SHALL be derived from the product details (item name, quantity, unit price with currency, and category) of the orders in the currently filtered list. When a category filter is active, the input SHALL be limited to the orders that contain at least one selected category, because the filtered list itself is already scoped to the selected category set, and the prompt SHALL state every selected category as the filtered scope. The system SHALL NOT include fabricated data not present in the orders.

#### Scenario: No category filter active

- **WHEN** no category filter is active
- **THEN** the summary input covers the product details of all orders in the current filtered list
- **AND** the prompt states that it covers every category of the current list

#### Scenario: Category filter active

- **WHEN** a category filter with one or more selected categories is active
- **THEN** the summary input covers only the product details of the orders in the filtered list, matching the filtered list
- **AND** the prompt names every selected category as the filtered scope

##### Example: scope text for selected categories

| Selected categories | Scope stated in the prompt |
| --- | --- |
| none | covers every category of the current list |
| {"美妝"} | filtered categories: 美妝 |
| {"書籍", "美妝"} | filtered categories: 美妝、書籍 (names ordered with a locale-aware standard comparison) |
