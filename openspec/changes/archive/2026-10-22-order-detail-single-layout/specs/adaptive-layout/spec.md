## ADDED Requirements

### Requirement: The order detail content uses one arrangement in both layouts

The order detail content SHALL use a single arrangement in the compact layout's pushed order detail and in the regular layout's order detail column. In that arrangement the content SHALL present, from top to bottom: the order header with the display ID, status, date and currency; the source section; a financial summary card that shows the profit and gross margin above the total payment, total cost and fees; the cardless adjustments card when the order has cardless adjustments; the cost breakdown as a donut chart followed by one legend row per cost component when the total cost is greater than zero; the item details under an item details heading; and the notes under a notes heading when the order has notes. The regular layout's order detail column SHALL NOT present an arrangement of its own, such as a row of separate summary tiles, cost breakdown bars, or the cost breakdown and item details placed side by side. At an accessibility text size, the financial summary card SHALL stack the profit and gross margin vertically and SHALL stack the total payment, total cost and fees vertically in both layouts.

#### Scenario: The regular detail column shows the pushed detail arrangement

- **GIVEN** an iPad running the app in full screen, which uses the regular layout
- **AND** an order whose total cost is greater than zero
- **WHEN** the user selects that order in the orders list column
- **THEN** the order detail column shows one financial summary card with the profit and gross margin above the total payment, total cost and fees
- **AND** below it the cost breakdown is a donut chart followed by a legend row for each cost component
- **AND** the item details appear under the item details heading below the cost breakdown
- **AND** the column shows no row of separate summary tiles and no cost breakdown bars

#### Scenario: The same order reports the same summary values in both layouts

- **GIVEN** the same seeded order data on an iPhone, which uses the compact layout, and on an iPad in full screen, which uses the regular layout
- **WHEN** the user opens the same order's detail on each device
- **THEN** both details expose the total payment, total cost and profit with the same values

##### Example: full order seed

- **GIVEN** the full orders seed and the order `BL-2604-018`
- **WHEN** the user opens its detail in the compact layout and in the regular layout
- **THEN** both details report total payment `$11,800`, total cost `$9,069` and profit `+$2,731`

#### Scenario: The regular detail column stacks the summary at an accessibility text size

- **GIVEN** an iPad running the app in full screen at the largest accessibility text size
- **WHEN** the user selects an order in the orders list column
- **THEN** the financial summary card in the order detail column shows the profit above the gross margin instead of beside it
- **AND** shows the total payment, total cost and fees one below another, as the pushed detail does at the same text size
