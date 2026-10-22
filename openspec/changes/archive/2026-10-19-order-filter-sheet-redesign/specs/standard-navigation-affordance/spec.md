## MODIFIED Requirements

### Requirement: Search scope is disclosed accurately

A search field's prompt SHALL describe the scope actually searched. It SHALL NOT name a narrower scope than the one the query filters, and it SHALL NOT name a scope the query does not filter.

#### Scenario: Filter sheet prompt names only the category scope

- **WHEN** the orders filter sheet on iPhone or the category picker sheet on iPadOS presents its search field, and the query filters only the category options
- **THEN** the prompt reads `搜尋類別` and does not mention payment methods
