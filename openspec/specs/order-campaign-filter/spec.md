# order-campaign-filter Specification

## Purpose

TBD - created by archiving change 'add-campaign-management'. Update Purpose after archive.

## Requirements

### Requirement: Filter orders by campaign status

The system SHALL let the orders list filter by campaign status with three options: all, ongoing, and closed. Selecting all SHALL apply no campaign-status restriction. The ongoing and closed options SHALL match an order when at least one campaign in the order's campaign list has the selected status.

#### Scenario: Filter to ongoing campaigns

- **WHEN** the user selects the ongoing campaign-status filter
- **THEN** only orders assigned to at least one campaign whose status is ongoing are shown

##### Example: campaign-status filter with multi-campaign orders

| Selected filter | Order's campaigns and their statuses    | Order shown |
| --------------- | --------------------------------------- | ----------- |
| all             | ["May-JP" (ongoing)]                    | yes         |
| all             | [] (unassigned)                         | yes         |
| ongoing         | ["May-JP" (ongoing)]                    | yes         |
| ongoing         | ["April-KR" (closed)]                   | no          |
| ongoing         | ["April-KR" (closed), "May-JP" (ongoing)] | yes       |
| closed          | ["April-KR" (closed)]                   | yes         |
| closed          | ["May-JP" (ongoing)]                    | no          |


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
### Requirement: Filter orders by a specific campaign

The system SHALL let the orders list filter by a specific campaign name. A specific-campaign constraint SHALL match an order only when the order's campaign list contains the selected campaign. The campaign-status filter and the specific-campaign filter SHALL compose with the existing search, order-status, date-period, category, and payment-method filters so that all active filters apply together.

#### Scenario: Filter by a specific campaign

- **WHEN** the user selects a specific campaign in the orders filter
- **THEN** only orders whose campaign list contains that campaign are shown

##### Example: specific-campaign filter with multi-campaign orders

- **GIVEN** orders: O1(campaigns=["May-JP"]), O2(campaigns=["May-JP", "June-KR"]), O3(campaigns=["June-KR"]), O4(campaigns=[])
- **WHEN** the specific-campaign filter is "May-JP"
- **THEN** the list shows exactly { O1, O2 }

#### Scenario: Campaign filter composes with category filter

- **WHEN** the user selects a specific campaign and a specific category
- **THEN** only orders whose campaign list contains that campaign and whose category list contains that category are shown

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