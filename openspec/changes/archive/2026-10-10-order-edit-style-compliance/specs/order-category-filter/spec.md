## MODIFIED Requirements

### Requirement: Cross-feature navigations reset the category filter

Cross-feature navigations into the orders list SHALL reset the orders list's active category filter to "all categories" unless the navigation explicitly applies a category. This applies to navigations originating from customer-name selection. This prevents a stale category filter from intersecting with the new navigation's filters and producing an empty list.

#### Scenario: Customer deep link clears a stale category filter

- **WHEN** the user has the orders list category filter set to "snacks", then taps the customer name "Alice" from the customers page
- **THEN** the active tab changes to "orders"
- **AND** the orders list's search text equals "Alice"
- **AND** the active category filter resets to "all categories"
