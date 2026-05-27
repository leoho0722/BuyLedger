## ADDED Requirements

### Requirement: Category filter on the orders list

The orders list SHALL provide a product-category filter that coexists with the existing status, date-period, and search filters on iOS, iPadOS, and macOS. The filter SHALL offer an "all categories" option plus one option per available category. The available categories SHALL be sourced from the existing merged category options (category master plus categories used by orders). Selecting "all categories" SHALL clear the category constraint.

#### Scenario: Select a specific category

- **WHEN** the user selects a specific category in the filter
- **THEN** the orders list shows only orders whose category equals the selected category, while still honoring the active status, date-period, and search filters

#### Scenario: Select all categories

- **WHEN** the user selects the "all categories" option
- **THEN** the category constraint is cleared and the orders list is no longer narrowed by category

### Requirement: Category filter combines with existing filters

The filtered orders result SHALL be the conjunction of the status, search, date-period, and category predicates. A category constraint SHALL match an order only when the order's category equals the selected category.

#### Scenario: Category combined with status filter

- **WHEN** both a status filter and a category filter are active
- **THEN** only orders matching both the status and the category appear in the list

##### Example: conjunction of filters

- **GIVEN** orders: O1(category="beauty", status=purchased), O2(category="beauty", status=quoting), O3(category="snacks", status=purchased)
- **WHEN** the status filter is "purchased" and the category filter is "beauty"
- **THEN** the list shows only O1

#### Scenario: Selection recomputes the active selection

- **WHEN** the user changes the category filter
- **THEN** the system recomputes the currently selected order to the first order of the newly filtered list
