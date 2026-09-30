## ADDED Requirements

### Requirement: A cardless deduction never exceeds the charged amount

The stored cardless deduction amount SHALL NOT exceed the order's charged amount. This holds as a data invariant, so that revenue, defined as the charged amount plus any cardless supplement minus the cardless deduction, can never be negative.

When the user enters a deduction larger than the charged amount, the form SHALL correct it to the charged amount visibly and explain why. It SHALL NOT silently alter the entered value, because a number the user typed changing without explanation is indistinguishable from a bug.

#### Scenario: Excessive deduction is capped and explained

- **WHEN** the user enters a cardless deduction greater than the charged amount
- **THEN** the value shown becomes the charged amount and the form states that the deduction cannot exceed the charged amount

#### Scenario: Revenue cannot be negative

- **WHEN** an order is saved with any combination of charged amount, supplement, and deduction
- **THEN** the computed revenue is zero or greater

#### Scenario: Existing over-cap data is corrected on next save

- **WHEN** an order stored before this rule carries a deduction greater than its charged amount and the user opens and saves it
- **THEN** the saved deduction is the charged amount

##### Example: deduction capping

| Charged | Supplement | Entered deduction | Stored deduction | Revenue |
| ------- | ---------- | ----------------- | ---------------- | ------- |
| 1000 | 0 | 300 | 300 | 700 |
| 1000 | 0 | 1000 | 1000 | 0 |
| 1000 | 0 | 1500 | 1000 | 0 |
| 1000 | 200 | 1500 | 1000 | 200 |

### Requirement: Margin is not reported when there is no revenue to measure against

When an order's revenue is zero, the margin SHALL be presented as an empty value rather than as a percentage. A margin of zero percent asserts a measured ratio that does not exist, which the project's presentation policy treats as fabricated data.

The presentation guard SHALL report a margin only when `revenue > 0`. Revenue equal to zero or below SHALL be presented as an empty value. This explicit positive-revenue guard also covers legacy over-cap records whose revenue may be negative and prevents two negative values from being reported as a misleading positive percentage.

#### Scenario: Zero revenue shows no margin figure

- **WHEN** an order's revenue is zero
- **THEN** the margin is presented as an empty value rather than as zero percent

#### Scenario: Positive revenue reports the margin normally

- **WHEN** an order's revenue is greater than zero
- **THEN** the margin is presented as the ratio of profit to revenue
