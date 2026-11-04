## MODIFIED Requirements

### Requirement: Category filter combines with existing filters

The filtered orders result SHALL be the conjunction of the status, search, date-period, payment-method, and category predicates. A category constraint SHALL match an order when the order's category list contains at least one category of the selected set; an empty selected set SHALL match every order. After a committed category change, the current destination SHALL follow the matching-selection rule of `navigation-path-integrity`, without automatically selecting the first result.

#### Scenario: Category combined with status filter

- **WHEN** both a status filter and a category filter are active
- **THEN** only orders matching the status and containing at least one selected category appear in the list

##### Example: conjunction of filters with multi-category orders

- **GIVEN** orders: O1(categories=["beauty"], status=purchased), O2(categories=["beauty", "snacks"], status=quoting), O3(categories=["snacks"], status=purchased), O4(categories=["books"], status=purchased), O5(categories=[], status=purchased)

| Status filter | Selected categories | Listed orders |
| --- | --- | --- |
| purchased | {beauty} | { O1 } |
| purchased | {beauty, snacks} | { O1, O3 } |
| purchased | {books} | { O4 } |
| purchased | none | { O1, O3, O4, O5 } |
| all | {snacks} | { O2, O3 } |

#### Scenario: Category changes retain only a matching destination

- **GIVEN** the orders list has a current destination or no selection
- **WHEN** the committed category set changes
- **THEN** the system retains the existing destination and detail state if it remains in the filtered result, and clears it otherwise
- **AND** an unselected list stays unselected without choosing the first order
