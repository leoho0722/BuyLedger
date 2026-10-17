## MODIFIED Requirements

### Requirement: Deterministic data seeding by profile

The app SHALL accept a seed profile name as a launch argument and SHALL populate the in-memory store with the fixed data set that the profile declares. Every seeded date SHALL be derived from the injected reference time rather than from the system clock, so the same profile yields structurally identical data on any calendar day. An unknown or absent profile name SHALL be treated as the empty profile. Seeded master data names (order sources, categories, payment methods, reconciliation statuses) and the master data values that seeded orders reference SHALL be user data as a user would type it, and SHALL NOT be String Catalog keys.

#### Scenario: Empty profile yields empty states

- **WHEN** the app launches in UI test mode with the empty seed profile
- **THEN** the overview screen shows its onboarding empty state and the orders list shows its no-matching-orders empty state

#### Scenario: Populated profile yields content

- **WHEN** the app launches in UI test mode with a populated seed profile
- **THEN** the orders list shows exactly the number of orders the profile declares, and the overview screen shows content instead of the onboarding empty state

#### Scenario: Seeded dates follow the injected reference time

- **WHEN** the app launches in UI test mode with a populated seed profile and a given reference time
- **THEN** the order whose profile position is "today" is grouped under the relative today section, and the order whose profile position is "yesterday" is grouped under the relative yesterday section

#### Scenario: Unknown profile falls back to empty

- **WHEN** the app launches in UI test mode with a seed profile name that no profile declares
- **THEN** the store is left empty, a warning is logged, and the app continues launching without crashing

#### Scenario: Seeded master data names are user data

- **GIVEN** any declared seed profile
- **WHEN** the profile is seeded into an in-memory store
- **THEN** no seeded master data name and no order source, category, payment method or reconciliation status referenced by a seeded order has the dotted shape of a String Catalog key (three or four lowerCamelCase segments, the same format the String Catalog key test enforces)

##### Example: payment method names seeded with master data

| Seeded payment method name | Cardless | Bank transfer | Cash on delivery |
| --- | --- | --- | --- |
| 信用卡 | no | no | no |
| 銀行轉帳 | no | yes | no |
| 無卡 | yes | no | no |
| 貨到付款 | no | no | yes |
| LINE Pay | no | no | no |
| Apple Pay | no | no | no |

A value such as `orders.list.label.cashDelivery` in place of 貨到付款 violates this scenario.
