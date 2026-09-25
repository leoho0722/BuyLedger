## MODIFIED Requirements

### Requirement: Analytics attribution after a merge uses pre-merge revenue

Overall (non-categorized) revenue aggregates in Insights and Dashboard SHALL count a merge exactly once through its existing merge result at its merge date. Only orders in the existing realized-status allowlist SHALL be eligible for overall attribution, and the merged status SHALL NOT be part of that allowlist. Before each aggregation, the system SHALL build a set from the merged-source identifiers of all existing merge results and exclude any realized order whose identifier is in that set. If the merge result is deleted, its former sources SHALL no longer be excluded by the existing-merge-result guard; they SHALL be counted only if they otherwise satisfy the realized-status allowlist. If a merge result is cancelled, it remains an existing result and its sources SHALL remain excluded; neither the cancelled result nor its sources contributes revenue. Per-category and per-campaign breakdowns SHALL instead attribute revenue from "leaf" orders — orders whose merged-source list is empty; orders produced by a merge SHALL NOT contribute to per-category or per-campaign breakdowns. The category breakdown keeps its pre-existing status rule (the realized allowlist) extended with the merged status; campaign aggregates keep their pre-existing membership rules per the campaign-analytics-surfaces capability. A leaf order contributes with its own original categories, campaigns, amounts, and order date. Chained merges (merging an order that is itself a merge result) SHALL NOT cause double counting, because merge-produced orders never contribute to breakdowns and leaf orders are never removed by merging. The orders list status filter SHALL include the merged status so the user can still locate merged-away orders.

#### Scenario: Overall totals count the merge once

- **WHEN** two realized orders are merged and the new order is saved
- **THEN** overall revenue aggregates include only the new merged order's amounts, not the source orders'

#### Scenario: Reverted source does not inflate overall totals

- **WHEN** a merge source is changed back to a realized status while its merge result still exists
- **THEN** overall revenue aggregates continue to include the merge result only

#### Scenario: Reverting remains permitted

- **WHEN** the user changes a merge source back to a realized status
- **THEN** the status change succeeds, because it is the recovery path for an incorrect merge

#### Scenario: Deleted merge result restores its sources

- **WHEN** a merge result is deleted
- **THEN** its former source orders are no longer excluded from overall revenue aggregates

#### Scenario: Cancelled merge result keeps its sources excluded

- **WHEN** a merge result is changed to cancelled while it still exists
- **THEN** neither the cancelled result nor its sources contributes to overall revenue aggregates

#### Scenario: Category and campaign breakdowns use the pre-merge orders

- **WHEN** order A (category "beauty", campaign "May-JP", profit 1000) and order B (category "snacks", campaign "June-KR", profit 2000) are merged
- **THEN** the category breakdown shows beauty +1000 and snacks +2000, and the campaign breakdown shows May-JP +1000 and June-KR +2000, each at the source order's original date
- **AND** the merged order contributes to neither breakdown

##### Example: chained merge stays single-counted

- **GIVEN** leaf orders A (beauty, 1000) and B (snacks, 2000) merged into M1, then M1 merged with leaf order C (beauty, 500) into M2
- **WHEN** the category breakdown is computed
- **THEN** beauty = 1500 (A + C) and snacks = 2000 (B); M1 and M2 contribute nothing to the breakdown

#### Scenario: Merged orders remain findable

- **WHEN** the user filters the orders list by the merged status
- **THEN** the merged source orders are listed

##### Example: total attribution

| Source A status | Source B status | Result C status | Result C exists | Counted in overview total |
| --------------- | --------------- | --------------- | --------------- | ------------------------- |
| merged | merged | delivered | yes | C only |
| arrived (reverted) | merged | delivered | yes | C only |
| arrived (reverted) | arrived (reverted) | delivered | yes | C only |
| arrived | arrived | deleted | no | A and B |
| arrived | arrived | cancelled | yes | none |
