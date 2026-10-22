## ADDED Requirements

### Requirement: Editor form snapshots exclude system date pickers and compare one reference image

Snapshot tests of the order editor and the campaign editor SHALL capture each form section separately. A section that contains a system date picker SHALL NOT be pixel compared, because the date picker's appearance follows the real clock and cannot be controlled by the injected time; the values that section shows SHALL be guarded by unit tests, and the presence of its date rows and the app-formatted timestamp SHALL be guarded by UI tests. Every snapshot assertion SHALL compare against exactly one approved reference image, and alternate reference images SHALL NOT be used to accept a mismatch.

#### Scenario: Batch snapshot run passes at any time of day

- **GIVEN** the full snapshot test class runs as one batch on the reference simulator
- **WHEN** the editor form section snapshots are compared with their approved reference images
- **THEN** none of the compared images contains a system date picker and every comparison passes without re-running a test alone

##### Example: editor sections and how each is guarded

| Editor | Section | Guard |
| --- | --- | --- |
| Order editor | Basic information (customer, source, category, order date) | Unit tests for the category text and the timestamp format; UI test for the order date row and the footer timestamp |
| Order editor | Status and currency, payment amount, campaign and receipt, cost, fees, items, notes, photos, original order | One pixel snapshot each |
| Campaign editor | Campaign information (name, open date, close date, status, reminder) | UI test for the open, close and reminder date rows |
| Campaign editor | Notes | One pixel snapshot |

#### Scenario: Merged order categories are joined without a pixel snapshot

- **WHEN** the category text for an order editor draft is computed
- **THEN** multiple categories are joined with "、" in their stored order, a single category is shown as is, and no categories produce an empty text

##### Example: category text

| Draft categories | Category text |
| --- | --- |
| ["美妝", "服飾"] | 美妝、服飾 |
| ["美妝"] | 美妝 |
| [] | (empty) |

#### Scenario: Order date row is guarded by a UI test

- **GIVEN** the app launches in UI test mode with the minimal orders seed
- **WHEN** the user opens the editor for the seeded order `UITEST-MIN-001`
- **THEN** the order date row exists and the footer shows the order date as formatted by the app

#### Scenario: Campaign date rows are guarded by a UI test

- **GIVEN** the campaign editor is opened to add a new campaign
- **WHEN** the form appears and the user then turns the order reminder on
- **THEN** the open date and close date rows exist before the toggle, the reminder date row is absent before the toggle, and the reminder date row appears after the toggle

#### Scenario: Long order identifiers are shown in their short form

- **WHEN** the original order section of the order editor shows an order whose identifier is `BL-DRAFT-00000000-0000-0000-0000-000000000000`
- **THEN** the section shows the short identifier `BL-DRAFT-000000` and its pixel snapshot matches the approved reference image
