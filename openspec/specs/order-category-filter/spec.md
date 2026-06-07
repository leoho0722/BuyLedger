# order-category-filter Specification

## Purpose

TBD - created by archiving change 'ai-product-summary'. Update Purpose after archive.

## Requirements

### Requirement: Category filter on the orders list

The orders list SHALL provide a product-category filter that coexists with the existing status, date-period, and search filters on iOS, iPadOS, and macOS. The filter SHALL offer an "all categories" option plus one option per available category. The available categories SHALL be sourced from the existing merged category options (category master plus categories used by orders). Selecting "all categories" SHALL clear the category constraint.

#### Scenario: Select a specific category

- **WHEN** the user selects a specific category in the filter
- **THEN** the orders list shows only orders whose category list contains the selected category, while still honoring the active status, date-period, and search filters

#### Scenario: Select all categories

- **WHEN** the user selects the "all categories" option
- **THEN** the category constraint is cleared and the orders list is no longer narrowed by category


<!-- @trace
source: add-order-merge
updated: 2026-06-07
code:
  - BuyLedger/BuyLedger/Features/Orders/OrdersView.swift
  - BuyLedger/BuyLedger/Features/Orders/OrdersCompactView.swift
  - BuyLedger/BuyLedger/Features/Orders/OrdersMacView.swift
  - BuyLedger/BuyLedgerTests/OrderMergeFeatureTests.swift
  - BuyLedger/BuyLedger/Features/Orders/OrdersFeature.swift
  - BuyLedger/BuyLedger/Features/Orders/Components/OrderRowView.swift
  - BuyLedger/BuyLedger/Features/Orders/Components/OrderMergeCandidateSheet.swift
  - BuyLedger/BuyLedger/Features/Orders/OrderMergeFeature.swift
-->

---
### Requirement: Category filter combines with existing filters

The filtered orders result SHALL be the conjunction of the status, search, date-period, and category predicates. A category constraint SHALL match an order only when the order's category list contains the selected category.

#### Scenario: Category combined with status filter

- **WHEN** both a status filter and a category filter are active
- **THEN** only orders matching both the status and the category appear in the list

##### Example: conjunction of filters with multi-category orders

- **GIVEN** orders: O1(categories=["beauty"], status=purchased), O2(categories=["beauty", "snacks"], status=quoting), O3(categories=["snacks"], status=purchased), O4(categories=["beauty", "snacks"], status=purchased)
- **WHEN** the status filter is "purchased" and the category filter is "beauty"
- **THEN** the list shows exactly { O1, O4 }

#### Scenario: Selection recomputes the active selection

- **WHEN** the user changes the category filter
- **THEN** the system recomputes the currently selected order to the first order of the newly filtered list


<!-- @trace
source: add-order-merge
updated: 2026-06-07
code:
  - BuyLedger/BuyLedger/Features/Orders/OrdersView.swift
  - BuyLedger/BuyLedger/Features/Orders/OrdersCompactView.swift
  - BuyLedger/BuyLedger/Features/Orders/OrdersMacView.swift
  - BuyLedger/BuyLedgerTests/OrderMergeFeatureTests.swift
  - BuyLedger/BuyLedger/Features/Orders/OrdersFeature.swift
  - BuyLedger/BuyLedger/Features/Orders/Components/OrderRowView.swift
  - BuyLedger/BuyLedger/Features/Orders/Components/OrderMergeCandidateSheet.swift
  - BuyLedger/BuyLedger/Features/Orders/OrderMergeFeature.swift
-->

---
### Requirement: Deep link from analytics applies the category filter

When the user taps a category row in the analytics page's category ranking, the app SHALL navigate to the orders tab and apply the tapped category as the active category filter on the orders list. The active category filter value SHALL drive both the orders list filtering and the visual state of the category filter trigger button and picker sheet (trigger label and picker selected-row indicator compare against the active category filter value). The orders list SHALL be filtered by containment against each order's category list — it SHALL NOT rely on text search to approximate the filter.

#### Scenario: Tapping a category row navigates and applies the filter

- **WHEN** the user is on the analytics page and taps the category row whose name is "beauty"
- **THEN** the active tab changes to "orders"
- **AND** the orders list's active category filter equals "beauty"
- **AND** the category filter trigger button label reads `類別：beauty` and the trigger background uses the active-selection style
- **AND** opening the picker sheet shows the `beauty` row as the currently selected row
- **AND** the orders list contains exactly those orders whose category list contains "beauty"

##### Example: deep link with mixed-category data

- **GIVEN** orders: O1(categories=["beauty"], customer="Alice"), O2(categories=["snacks"], customer="Beauty Bob"), O3(categories=["beauty", "snacks"], customer="Carol")
- **WHEN** the user taps the "beauty" row in the analytics category ranking
- **THEN** the orders list contains exactly { O1, O3 } and excludes O2, even though O2's customer name contains the substring "Beauty"

#### Scenario: Tapping a category row resets unrelated orders-list filters

- **WHEN** the user has the orders list state with status filter "delivered" and date-period filter "this month", then taps a category row on the analytics page
- **THEN** the status filter resets to "all"
- **AND** the date-period filter resets to "all"
- **AND** the search text is cleared
- **AND** the active category filter equals the tapped category


<!-- @trace
source: add-order-merge
updated: 2026-06-07
code:
  - BuyLedger/BuyLedger/Features/Orders/OrdersView.swift
  - BuyLedger/BuyLedger/Features/Orders/OrdersCompactView.swift
  - BuyLedger/BuyLedger/Features/Orders/OrdersMacView.swift
  - BuyLedger/BuyLedgerTests/OrderMergeFeatureTests.swift
  - BuyLedger/BuyLedger/Features/Orders/OrdersFeature.swift
  - BuyLedger/BuyLedger/Features/Orders/Components/OrderRowView.swift
  - BuyLedger/BuyLedger/Features/Orders/Components/OrderMergeCandidateSheet.swift
  - BuyLedger/BuyLedger/Features/Orders/OrderMergeFeature.swift
-->

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

<!-- @trace
source: fix-category-deep-link-filter
updated: 2026-05-28
code:
  - BuyLedger/BuyLedger/Features/App/RootFeature.swift
  - BuyLedger/BuyLedgerTests/RootFeatureTests.swift
-->

---
### Requirement: Category filter is presented as a trigger button with a searchable picker sheet

On iPadOS and macOS the orders list category filter SHALL be rendered as a single capsule-shaped trigger button. The trigger button SHALL display the currently active category selection in its label so the user can identify the active selection without opening the picker. The category filter SHALL NOT be rendered as a horizontally scrolling row of capsule chips and SHALL NOT be rendered as an inline Menu.

On iOS in the Compact size class the orders list category filter SHALL instead be folded into the unified filter sheet defined by the `order-filter-sheet` capability. The dedicated category trigger described in this requirement SHALL NOT be rendered in that size class.

The trigger button SHALL occupy the full available horizontal width of the orders filter area on every platform where it is rendered, so its left and right edges align with the search field and other full-width controls above it.

The trigger button label SHALL be composed of, in order:
1. A leading tag icon consistent with the icon previously used by the category chips.
2. A text segment of the form `類別：<current>`, where `<current>` is `全部` when no category is selected, and the category name otherwise. The text segment SHALL support multi-line wrapping when the category name exceeds the available single-line width — the capsule SHALL grow vertically to fit the wrapped text rather than truncating it.
3. A trailing chevron-down indicator that communicates the control opens a picker sheet.

When the label wraps to multiple lines, the leading tag icon and the trailing chevron-down icon SHALL align to the first text baseline rather than the vertical center of the capsule.

The trigger button SHALL apply a filled capsule background. The fill SHALL be the active-selection style when a category is selected and the inactive-selection style otherwise, so the user can tell from the trigger alone whether a category filter is currently applied.

The trigger button SHALL only be rendered when the set of available categories is non-empty. When no categories are available, the category filter UI on iPadOS and macOS SHALL be hidden, matching the prior behavior.

Tapping the trigger button SHALL present a category picker sheet that:
1. Lists, in order, a "clear" row labeled `全部` (which clears the active category filter when tapped) followed by one row per entry in the available categories list (which sets the active category to that name when tapped).
2. Provides a search field that filters the category rows in real time. The "clear" row SHALL remain visible regardless of the search input.
3. Marks exactly one row as the currently selected row — the "clear" row when no category is selected, or the matching category row otherwise — with a visually distinguishable indicator such as a leading or trailing checkmark glyph.
4. Dismisses itself after the user taps any row.

#### Scenario: Trigger label reflects the active selection on iPadOS and macOS

- **GIVEN** the orders list is displayed on iPadOS or macOS and has at least one available category
- **WHEN** the active category filter is "all categories" (no specific category selected)
- **THEN** the trigger button label reads `類別：全部`
- **AND** the trigger background uses the inactive-selection style

##### Example: trigger labels under different selections

| Active selection           | Trigger label  | Trigger background style |
| -------------------------- | -------------- | ------------------------ |
| none ("all categories")    | `類別：全部`   | inactive                 |
| "beauty"                   | `類別：beauty` | active                   |
| "snacks"                   | `類別：snacks` | active                   |

#### Scenario: Dedicated category trigger is not rendered on iOS Compact

- **GIVEN** the orders list is displayed on iOS in the Compact horizontal size class
- **WHEN** the orders list filter area is rendered
- **THEN** the dedicated category trigger described in this requirement is not rendered
- **AND** the category filter is exposed instead through the unified filter sheet defined by the `order-filter-sheet` capability

#### Scenario: Picker sheet lists clear row and all categories with a selection indicator

- **GIVEN** the orders list is displayed on iPadOS or macOS with available categories `["beauty", "snacks", "books"]` and the active category filter is "snacks"
- **WHEN** the user taps the trigger button and the picker sheet opens
- **THEN** the picker shows rows in order: `全部`, `beauty`, `snacks`, `books`
- **AND** the `snacks` row is marked as the currently selected row
- **AND** no other row is marked as currently selected

#### Scenario: Selecting a category from the picker sheet updates the filter

- **GIVEN** the orders list is displayed on iPadOS or macOS with the category filter currently `全部` (no category selected)
- **WHEN** the user opens the picker sheet and taps the `beauty` row
- **THEN** the active category filter equals "beauty"
- **AND** the picker sheet dismisses
- **AND** the trigger button label reads `類別：beauty` and the trigger background uses the active-selection style
- **AND** the orders list is filtered to orders whose category list contains "beauty" (combined with any other active filters)
- **AND** reopening the picker sheet shows `beauty` as the currently selected row

#### Scenario: Selecting the clear row from the picker sheet clears the filter

- **GIVEN** the orders list is displayed on iPadOS or macOS
- **WHEN** the user opens the picker sheet while a specific category is active and taps the `全部` row
- **THEN** the active category filter is cleared
- **AND** the picker sheet dismisses
- **AND** the trigger button label reads `類別：全部` and the trigger background uses the inactive-selection style
- **AND** the orders list is no longer narrowed by category

#### Scenario: Search filters the category rows but preserves the clear row

- **GIVEN** the orders list is displayed on iPadOS or macOS with available categories `["beauty", "snacks", "books"]` and the picker sheet is open
- **WHEN** the user types `boo` into the search field
- **THEN** the picker shows the `全部` row at the top and the `books` row as the only matching category row
- **AND** the `beauty` and `snacks` rows are not shown

#### Scenario: Category filter is hidden when no categories are available on iPadOS and macOS

- **GIVEN** the orders list is displayed on iPadOS or macOS and the merged available categories list is empty
- **WHEN** the orders list is displayed
- **THEN** the trigger button is not rendered
- **AND** the active category filter remains cleared

<!-- @trace
source: add-order-merge
updated: 2026-06-07
code:
  - BuyLedger/BuyLedger/Features/Orders/OrdersView.swift
  - BuyLedger/BuyLedger/Features/Orders/OrdersCompactView.swift
  - BuyLedger/BuyLedger/Features/Orders/OrdersMacView.swift
  - BuyLedger/BuyLedgerTests/OrderMergeFeatureTests.swift
  - BuyLedger/BuyLedger/Features/Orders/OrdersFeature.swift
  - BuyLedger/BuyLedger/Features/Orders/Components/OrderRowView.swift
  - BuyLedger/BuyLedger/Features/Orders/Components/OrderMergeCandidateSheet.swift
  - BuyLedger/BuyLedger/Features/Orders/OrderMergeFeature.swift
-->