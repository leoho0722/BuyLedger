## ADDED Requirements

### Requirement: Deep link from analytics applies the category filter

When the user taps a category row in the analytics page's category ranking, the app SHALL navigate to the orders tab and apply the tapped category as the active category filter on the orders list. The selection SHALL drive the category chip's selected highlight (chip selection compares against the active category filter value). The orders list SHALL be filtered by exact match on each order's `category` field — it SHALL NOT rely on text search to approximate the filter.

#### Scenario: Tapping a category row navigates and applies the filter

- **WHEN** the user is on the analytics page and taps the category row whose name is "beauty"
- **THEN** the active tab changes to "orders"
- **AND** the orders list's active category filter equals "beauty"
- **AND** the "beauty" chip in the category filter row is rendered in its selected state
- **AND** the orders list contains exactly those orders whose `category` field equals "beauty"

##### Example: deep link with mixed-category data

- **GIVEN** orders: O1(category="beauty", customer="Alice"), O2(category="snacks", customer="Beauty Bob"), O3(category="beauty", customer="Carol")
- **WHEN** the user taps the "beauty" row in the analytics category ranking
- **THEN** the orders list contains exactly { O1, O3 } and excludes O2, even though O2's customer name contains the substring "Beauty"

#### Scenario: Tapping a category row resets unrelated orders-list filters

- **WHEN** the user has the orders list state with status filter "delivered" and date-period filter "this month", then taps a category row on the analytics page
- **THEN** the status filter resets to "all"
- **AND** the date-period filter resets to "all"
- **AND** the search text is cleared
- **AND** the active category filter equals the tapped category

---

### Requirement: Cross-feature navigations reset the category filter

Cross-feature navigations into the orders list SHALL reset the orders list's active category filter to "all categories" unless the navigation explicitly applies a category. This applies to navigations originating from smart group selection (status-based deep links) and from customer-name selection. This prevents a stale category filter from intersecting with the new navigation's filters and producing an empty list.

#### Scenario: Smart group deep link clears a stale category filter

- **WHEN** the user has the orders list category filter set to "beauty", then taps the "shipping" smart group from another page
- **THEN** the active tab changes to "orders"
- **AND** the status filter equals "shipping"
- **AND** the active category filter resets to "all categories"
- **AND** the orders list contains every order with status "shipping" regardless of category

#### Scenario: Customer deep link clears a stale category filter

- **WHEN** the user has the orders list category filter set to "snacks", then taps the customer name "Alice" from the customers page
- **THEN** the active tab changes to "orders"
- **AND** the orders list's search text equals "Alice"
- **AND** the active category filter resets to "all categories"
