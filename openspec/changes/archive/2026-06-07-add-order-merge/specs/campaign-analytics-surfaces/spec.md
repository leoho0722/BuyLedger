## ADDED Requirements

### Requirement: Campaign analytics attribute pre-merge amounts from leaf orders

Every campaign analytics surface — the dashboard ongoing campaigns card, the insights per-campaign profit ranking, and the campaign detail summary (including the distribution list) — SHALL compute a campaign's member set from "leaf" orders: orders whose merged-source list is empty and whose campaign list contains the campaign name. Orders produced by a merge SHALL NOT be campaign members; their revenue enters through their pre-merge source orders, each with its own original campaigns, amounts, receipt status, and order date. Membership SHALL impose no additional status restriction beyond the pre-existing aggregation rules, so merged-away source orders keep contributing exactly as they did before the merge. The delivery-progress denominator SHALL exclude merged orders in the same way it already excludes cancelled orders, because a merged-away order no longer awaits delivery on its own. Because multi-selection is offered only in merge contexts, leaf orders carry at most one campaign and the attribution is exact; as a defensive rule, a leaf order that nevertheless carries multiple campaigns SHALL contribute its full amounts to each of them.

#### Scenario: Merged order's revenue enters campaign aggregates through its sources

- **WHEN** leaf orders A (campaigns ["May-JP"], profit 1000) and B (campaigns ["June-KR"], profit 2000) have been merged into order M
- **THEN** the profit ranking and campaign summaries show May-JP +1000 and June-KR +2000, and M contributes to neither campaign

##### Example: campaign attribution matrix

| Order | Leaf | Status    | Campaigns               | Profit | May-JP | June-KR |
| ----- | ---- | --------- | ----------------------- | ------ | ------ | ------- |
| A     | yes  | merged    | ["May-JP"]              | 1000   | +1000  | —       |
| B     | yes  | merged    | ["June-KR"]             | 2000   | —      | +2000   |
| M     | no   | shipping  | ["May-JP", "June-KR"]   | 3000   | —      | —       |
| C     | yes  | delivered | ["May-JP"]              | 500    | +500   | —       |

#### Scenario: Campaign membership uses list containment

- **WHEN** a campaign summary is computed for "May-JP"
- **THEN** its member orders are exactly the leaf orders whose campaign list contains "May-JP"

#### Scenario: Delivery progress ignores merged-away members

- **WHEN** a campaign has members with statuses delivered, merged, and shipping
- **THEN** the delivery-progress denominator counts only the delivered and shipping members, and the merged member is excluded like a cancelled one
