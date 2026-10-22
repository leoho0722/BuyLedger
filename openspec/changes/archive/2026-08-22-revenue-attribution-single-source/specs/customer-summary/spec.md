## MODIFIED Requirements

### Requirement: Customers screen aggregates orders into per-customer summaries

The customers screen SHALL derive its rows entirely from the existing orders, grouping orders by customer name. For each customer the screen SHALL report the customer's order count, total spent, and most-recent order date, and SHALL carry that customer's initials and tier. Total spent and order count SHALL use the same revenue-attribution rule as overview totals: only realized orders count, and an order listed as a source by an existing merge result does not count alongside that result. Membership, initials, tier, and most-recent order date SHALL still derive from all orders, so a customer with only cancelled orders remains visible with zero spent and zero counted orders. The list SHALL be sorted by total spent in descending order. The screen SHALL NOT hold any persisted customer state of its own; when the underlying orders change, the summaries SHALL recompute from the current orders.

#### Scenario: Aggregate orders by customer

- **WHEN** the customers screen is shown with existing orders
- **THEN** each row represents one customer with that customer's order count, total spent, and most-recent order date, and the rows are ordered by total spent descending

##### Example: three customers ranked by spend

- **GIVEN** orders: Amy(revenue=300, date=2026-03-01), Amy(revenue=200, date=2026-03-05), Bob(revenue=400, date=2026-03-02), Cara(revenue=100, date=2026-03-03)
- **WHEN** the customers screen aggregates them
- **THEN** the rows are: Amy(orderCount=2, totalSpent=500, lastOrderDate=2026-03-05), Bob(orderCount=1, totalSpent=400, lastOrderDate=2026-03-02), Cara(orderCount=1, totalSpent=100, lastOrderDate=2026-03-03), in that order

#### Scenario: Empty state when there are no orders

- **WHEN** there are no orders
- **THEN** the customers screen shows its empty state and no customer rows

#### Scenario: Cancelled orders do not count toward spending

- **WHEN** a customer has one realized order and one cancelled order
- **THEN** the customer's total spent and order count reflect only the realized order

#### Scenario: A customer with only cancelled orders stays visible

- **WHEN** every order belonging to a customer is cancelled
- **THEN** the customer still appears in the list with zero total spent and zero counted orders

#### Scenario: Merged orders are not double counted

- **WHEN** a customer's orders include two merge sources and their merge result
- **THEN** the customer's total spent counts the merge result once and does not additionally count the sources
