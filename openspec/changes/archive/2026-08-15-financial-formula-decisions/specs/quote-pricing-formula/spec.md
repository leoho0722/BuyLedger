## ADDED Requirements

### Requirement: The target margin input means gross margin, and the suggested price follows from it

The quote screen's target input SHALL express a gross margin, and the suggested price SHALL be derived so that the resulting margin equals the entered value. The suggested price SHALL therefore be the total cost divided by one minus the target margin, not the cost multiplied by one plus the target.

The margin shown on the same card SHALL agree with the entered target, so that the screen does not present two contradictory figures for the same quantity. Rounding of the suggested price MAY cause a small discrepancy; no other source of discrepancy is permitted.

#### Scenario: Entered target matches the reported margin

- **WHEN** the user enters a target margin and a cost
- **THEN** the estimated margin shown on the card equals the entered target apart from rounding of the suggested price

##### Example: suggested price by target margin

| Total cost | Target margin | Suggested price before rounding | Estimated margin shown |
| ---------- | ------------- | ------------------------------- | ---------------------- |
| 1000 | 0% | 1000 | 0% |
| 1000 | 30% | 1429 | 30% |
| 1000 | 50% | 2000 | 50% |

### Requirement: A target margin at or above one hundred percent yields no price

The target margin SHALL NOT be capped at an arbitrary upper bound. When the entered target reaches or exceeds one hundred percent, the screen SHALL NOT compute or present a suggested price, an estimated profit, or an estimated margin, and SHALL instead state that the target margin must be below one hundred percent.

Presenting any number in this case would be fabricated, because the formula has no finite result at one hundred percent and a negative result above it.

#### Scenario: One hundred percent produces an explanation, not a number

- **WHEN** the user enters a target margin of one hundred percent or more
- **THEN** no suggested price, estimated profit, or estimated margin is shown, and the screen states that the target margin must be below one hundred percent

#### Scenario: Just below the bound still computes

- **WHEN** the user enters a target margin just below one hundred percent
- **THEN** a suggested price is computed and shown, however large

#### Scenario: Lowering the target restores the figures

- **WHEN** the user reduces the target margin from at or above one hundred percent to below it
- **THEN** the suggested price, estimated profit, and estimated margin are shown again

### Requirement: Quote amounts use the same decimal precision as order finances

All monetary values on the quote screen SHALL be computed with the same decimal type used by the order financial path, so that a quote and the order created from it cannot disagree by accumulated binary floating-point error. Binary floating-point SHALL be used only where a charting component requires it for rendering.

#### Scenario: Quote and order agree

- **WHEN** the same cost inputs are entered on the quote screen and on an order
- **THEN** the computed amounts agree exactly rather than differing in trailing digits

#### Scenario: Floating point is confined to rendering

- **WHEN** the quote screen's calculation path is inspected
- **THEN** monetary values are held in the decimal type, with conversion to floating point occurring only at a charting boundary
