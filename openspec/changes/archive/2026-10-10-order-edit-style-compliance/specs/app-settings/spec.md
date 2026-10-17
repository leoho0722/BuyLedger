## ADDED Requirements

### Requirement: New orders start in the default currency

A new order SHALL start with the default currency chosen in settings (the row 新訂單預設), whether it is opened from the orders tab or from the overview. Editing an existing order SHALL keep that order's currency, and a merge confirmation SHALL keep the currency of the primary order. The default currency SHALL be part of the values the new order editor opens with, so opening a new order does not by itself make the editor dirty. A change to the default currency SHALL apply to new orders opened afterwards and SHALL NOT change any existing order.

#### Scenario: A new order from the orders tab uses the default currency

- **GIVEN** the default currency is JPY
- **WHEN** the user opens a new order from the orders tab
- **THEN** the draft currency is JPY and the editor is not dirty

#### Scenario: A new order from the overview uses the default currency

- **GIVEN** the default currency is JPY
- **WHEN** the user opens a new order from the overview
- **THEN** the draft currency is JPY

#### Scenario: Editing and merging keep the existing currency

- **GIVEN** the default currency is JPY
- **WHEN** the user edits an existing KRW order, or confirms a merge whose primary order is in KRW
- **THEN** the draft currency stays KRW

#### Scenario: Changing the default affects only later new orders

- **GIVEN** the default currency is TWD and an existing order is in TWD
- **WHEN** the user changes the default currency to JPY and then opens a new order
- **THEN** the new draft is in JPY and the existing order is still in TWD
