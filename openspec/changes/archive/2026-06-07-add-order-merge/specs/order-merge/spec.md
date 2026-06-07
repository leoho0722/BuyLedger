## ADDED Requirements

### Requirement: Order merge entry points

The system SHALL provide a "merge order" action on the orders list row context menu and in the order detail page's "more" actions menu, on iOS, iPadOS, and macOS. On the order detail page, the merge, edit, and delete actions SHALL be grouped into a single "more" menu (ellipsis label) — ordered as merge, edit, then delete, with delete presented as a destructive action separated from the others by a divider — while the status update control SHALL remain a separate control outside that menu. Both entry points SHALL open the same merge candidate sheet, with the originating order as the primary order. The merge action SHALL NOT be offered for orders whose status is merged or cancelled.

#### Scenario: Entry from the orders list context menu

- **WHEN** the user opens the context menu of an order row whose status is neither merged nor cancelled and selects the merge action
- **THEN** the merge candidate sheet opens with that order as the primary order

#### Scenario: Entry from the order detail page

- **WHEN** the user opens the "more" menu on the detail page of an order whose status is neither merged nor cancelled and selects the merge action
- **THEN** the merge candidate sheet opens with that order as the primary order

#### Scenario: Detail page actions are consolidated into a more menu

- **WHEN** the user views the detail page of any order
- **THEN** the action area shows exactly two controls: the status update menu and a "more" menu that contains the merge action (when the order is eligible), the edit action, and the destructive delete action separated by a divider

#### Scenario: Entry hidden for merged and cancelled orders

- **WHEN** an order's status is merged or cancelled
- **THEN** neither the context menu nor the detail page "more" menu offers the merge action, while the "more" menu still offers edit and delete

---
### Requirement: Merge candidate selection

The merge candidate sheet SHALL list the orders eligible to merge with the primary order. An order is eligible only when all of the following hold: it is not the primary order itself, its status is neither merged nor cancelled, its currency equals the primary order's currency, and its customer name equals the primary order's customer name. Cross-customer merging SHALL NOT be offered. The candidate list SHALL group rows into date sections by order date (start of day), sections ordered newest first and rows inside each section ordered newest first, with section titles produced the same way as the orders list date sections (relative today/yesterday or a formatted day). Each candidate row SHALL reuse the orders list row layout — avatar, customer name, item summary (one line per item), and category tag — with the trailing column showing the order's charged amount and a charged-amount label instead of the status pill, revenue, and profit; the row SHALL NOT display an inline date (the section title carries the date) and SHALL NOT display the raw order identifier. The sheet SHALL provide a search field that filters the candidate rows in real time, and SHALL show an empty state when no eligible order exists or no row matches the search. Tapping a candidate row SHALL select it as the secondary order and advance the merge flow.

#### Scenario: Candidate row shows the item summary

- **WHEN** the merge candidate sheet lists a candidate order whose items are "藍牙耳機" with quantity 2 and "保護殼" with quantity 1
- **THEN** the row shows the orders-list row layout with the customer name, the item summary lines "藍牙耳機 x2" and "保護殼 x1", and a trailing charged amount, without an inline date and without the order identifier

#### Scenario: Candidates are grouped by date sections

- **WHEN** the eligible candidates span two different order dates
- **THEN** the list shows two date sections ordered newest first, each titled the same way as the orders list date sections, with that day's candidates inside ordered newest first

#### Scenario: Candidate eligibility filtering

- **WHEN** the merge candidate sheet opens for a primary order
- **THEN** the sheet lists exactly the orders that share the primary order's currency and customer name, excluding the primary order itself and any order whose status is merged or cancelled

##### Example: eligibility matrix

| Candidate | Currency | Customer | Status    | Listed |
| --------- | -------- | -------- | --------- | ------ |
| O2        | JPY      | Alice    | purchased | yes    |
| O3        | JPY      | Alice    | merged    | no     |
| O4        | JPY      | Alice    | cancelled | no     |
| O5        | KRW      | Alice    | purchased | no     |
| O6        | JPY      | Bob      | purchased | no     |

- **GIVEN** the primary order O1 has currency JPY, customer "Alice", status shipping, and candidates O2–O6 as in the table
- **WHEN** the merge candidate sheet opens for O1
- **THEN** only O2 is listed

#### Scenario: Empty state when no eligible order exists

- **WHEN** no other order shares the primary order's currency and customer name with an eligible status
- **THEN** the sheet shows an empty state instead of an empty list

---
### Requirement: Photo over-limit selection step

When the combined photo count of the primary and secondary orders exceeds the order photo limit (5), the merge flow SHALL present a photo selection step before the prefilled merge form, showing every photo from both orders. The user SHALL select at most 5 photos to keep; confirming advances to the prefilled merge form carrying only the kept photos. When the combined count is 5 or fewer, the merge flow SHALL skip this step and carry all photos in primary-then-secondary order.

#### Scenario: Combined photos exceed the limit

- **WHEN** the primary order has 4 photos and the secondary order has 3 photos
- **THEN** the photo selection step is shown with all 7 photos, and the user can confirm only while 5 or fewer photos are selected

#### Scenario: Combined photos within the limit

- **WHEN** the primary order has 2 photos and the secondary order has 3 photos
- **THEN** the merge flow skips the photo selection step and the prefilled form carries all 5 photos in primary-then-secondary order

---
### Requirement: Merged draft prefill rules

After candidate selection (and the photo step when required), the system SHALL open the new-order edit form prefilled from the primary order (P) and the secondary order (S) as follows:

- Categories: the ordered union of P's then S's categories, without duplicates.
- Campaigns: the ordered union of P's then S's campaign lists, without duplicates.
- Order date: the current date and time at the moment of merging, obtained from the injected clock dependency.
- Customer name, order source, status, currency, payment receipt status: P's values.
- Payment method: when P and S share the same payment method, that value; otherwise, when exactly one of the two payment methods is a cardless method, the cardless one; otherwise P's value. The verification status and the cash-on-delivery flag SHALL follow the order that supplied the payment method.
- Charged amount, cardless deduction amount, cardless supplement amount, item cost, foreign domestic shipping, international shipping, domestic shipping: the per-field sum of P and S.
- Card, platform, and payment fee rates: per-field weighted average using the two charged amounts as weights — `(rateP × chargedP + rateS × chargedS) ÷ (chargedP + chargedS)` — clamped to [0, 1]; when both charged amounts are 0, P's rate. The result MUST NOT be NaN.
- Items: P's items followed by S's items, contents unchanged.
- Notes: when both are non-empty after trimming, P's notes, a separator line consisting of dashes (`----------`) on its own line, then S's notes; when only one side is non-empty, that side alone without a separator; when both are empty, empty.
- Photos: the photos carried over from the photo step (kept selection when the step ran, otherwise the primary-then-secondary concatenation).

The form SHALL behave as a normal new-order draft afterwards: every prefilled value — including the received amounts, costs, fee rates, and item details — remains editable before saving. The merge computation supplies initial values only.

#### Scenario: Amount fields are summed

- **WHEN** the user merges P (charged 1000, item cost 600, domestic shipping 60) with S (charged 2000, item cost 900, domestic shipping 80)
- **THEN** the prefilled form shows charged 3000, item cost 1500, and domestic shipping 140

#### Scenario: Fee rates use the charged-amount weighted average

- **WHEN** the user merges two orders with differing fee rates
- **THEN** each fee rate is prefilled as the charged-amount weighted average of the two source rates

##### Example: weighted average and degenerate weights

| chargedP | rateP | chargedS | rateS | Prefilled rate          |
| -------- | ----- | -------- | ----- | ----------------------- |
| 1000     | 1.5%  | 2000     | 2%    | (15 + 40) ÷ 3000 ≈ 1.83% |
| 1000     | 1.5%  | 0        | 3%    | 1.5%                    |
| 0        | 1.5%  | 0        | 3%    | 1.5% (P's rate)         |

#### Scenario: Categories and campaigns take the ordered union

- **WHEN** the user merges P (categories ["beauty"], campaigns ["May-JP"]) with S (categories ["snacks", "beauty"], campaigns ["June-KR"])
- **THEN** the prefilled categories are ["beauty", "snacks"] and the prefilled campaigns are ["May-JP", "June-KR"]

#### Scenario: Notes join with a dash separator line

- **WHEN** both source orders have non-empty notes
- **THEN** the prefilled notes are P's notes, a line of dashes, then S's notes

##### Example: notes composition

| notesP  | notesS  | Prefilled notes              |
| ------- | ------- | ---------------------------- |
| "急件"   | "含贈品" | "急件\n----------\n含贈品"     |
| "急件"   | ""      | "急件"                        |
| ""      | ""      | ""                           |

#### Scenario: Cardless payment method wins on conflict

- **WHEN** P's payment method is not cardless and S's payment method is cardless
- **THEN** the prefilled payment method is S's, and the verification status and cash-on-delivery flag are prefilled from S

---
### Requirement: Merge-related orders stay fully editable

When editing an order produced by a merge (non-empty merged-source list) or an order whose status is merged, the order editor SHALL keep every field editable — including the received-amount, cost, fee-rate, and item-details sections — exactly like a regular order. Categories and campaigns keep the multi-select picker in these merge contexts. Editing amounts after a merge is allowed to make the per-category and per-campaign breakdowns (attributed from the pre-merge source orders) diverge from the merged order's totals; this divergence is the accepted trade-off of keeping the fields editable.

#### Scenario: Editing a merge-produced order keeps amounts editable

- **WHEN** the user edits an order that was produced by a merge
- **THEN** the received-amount, cost, fee-rate, and item-details fields accept changes like any regular order

#### Scenario: Editing a merged-away source order keeps amounts editable

- **WHEN** the user edits an order whose status is merged
- **THEN** the received-amount, cost, fee-rate, and item-details fields accept changes like any regular order

---
### Requirement: Saving a merged draft commits atomically

When the user saves the prefilled merge form, the system SHALL, in a single persistence operation: insert the new merged order with both source order IDs recorded in its merged-source list, and set the status of both source orders to merged. The in-memory orders list SHALL reflect the new order and both source-status changes together. When persistence fails, neither the new order nor any source-status change SHALL be applied, and the failure SHALL surface through the existing persistence error path. An order not produced by a merge SHALL have an empty merged-source list.

#### Scenario: Save commits the merge

- **WHEN** the user saves the merge form
- **THEN** the orders list contains the new merged order carrying both source order IDs, and both source orders with status merged, and the same state is persisted

#### Scenario: Persistence failure leaves no partial merge

- **WHEN** the persistence operation fails during save
- **THEN** no new order is persisted, both source orders keep their previous status, and the error surfaces through the existing error path

---
### Requirement: Cancelling the merge leaves no changes

Dismissing the candidate sheet, the photo selection step, or cancelling the prefilled merge form SHALL leave every order unchanged in persistence and in memory.

#### Scenario: Cancel from the merge form

- **WHEN** the user cancels the prefilled merge form
- **THEN** no new order exists and both source orders keep their previous status

---
### Requirement: Analytics attribution after a merge uses pre-merge revenue

The merged status SHALL NOT be part of the realized-status allowlist, so overall (non-categorized) revenue aggregates in Insights and Dashboard count a merge's revenue exactly once, through the new merged order at its merge date. Per-category and per-campaign breakdowns SHALL instead attribute revenue from "leaf" orders — orders whose merged-source list is empty; orders produced by a merge SHALL NOT contribute to per-category or per-campaign breakdowns. The category breakdown keeps its pre-existing status rule (the realized allowlist) extended with the merged status; campaign aggregates keep their pre-existing membership rules per the campaign-analytics-surfaces capability. A leaf order contributes with its own original categories, campaigns, amounts, and order date. Chained merges (merging an order that is itself a merge result) SHALL NOT cause double counting, because merge-produced orders never contribute to breakdowns and leaf orders are never removed by merging. The orders list status filter SHALL include the merged status so the user can still locate merged-away orders.

#### Scenario: Overall totals count the merge once

- **WHEN** two realized orders are merged and the new order is saved
- **THEN** overall revenue aggregates include only the new merged order's amounts, not the source orders'

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
