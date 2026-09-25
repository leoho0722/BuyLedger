## ADDED Requirements

### Requirement: Trend comparison expresses improvement consistently

The Dashboard KPI deltas and the Insights trend card SHALL derive their percentage magnitude and direction from the same current-versus-previous-period comparison. When the previous period is non-zero, the percentage denominator SHALL be the absolute value of the previous period. This absolute denominator is observable in Dashboard KPI deltas because the signed Decimal delta is presented directly. In the Insights trend card, the displayed magnitude uses `abs(ratio)`, so changing only the denominator's sign does not change its rendered percentage. A higher current profit SHALL be presented as improvement and a lower current profit as deterioration, including when both values are losses. When the previous period is zero or has no orders, Dashboard KPI deltas and the Insights trend card SHALL continue to show no comparison.

#### Scenario: Loss turns into profit

- **WHEN** the previous period profit is -100 and the current period profit is 50
- **THEN** the trend card presents improvement as `↑ 150.0%`

#### Scenario: Loss narrows

- **WHEN** the previous period profit is -100 and the current period profit is -50
- **THEN** the trend card presents improvement as `↑ 50.0%`

#### Scenario: Loss grows

- **WHEN** the previous period profit is -100 and the current period profit is -200
- **THEN** the trend card presents deterioration as `↓ 100.0%`

#### Scenario: Dashboard profit delta keeps direction when previous profit is negative

- **WHEN** the previous period profit is -100 and the current period profit is -50
- **THEN** the dashboard profit delta is the signed Decimal `0.5`, indicating improvement because current profit is greater than or equal to previous profit

#### Scenario: No prior comparison

- **WHEN** the previous period has zero profit or no orders
- **THEN** Dashboard KPI deltas and the trend card present no comparison
