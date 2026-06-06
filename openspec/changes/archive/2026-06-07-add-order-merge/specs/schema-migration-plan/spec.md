## ADDED Requirements

### Requirement: Type-changing migrations preserve values through a custom stage

When a schema version changes the type of an existing attribute, the bridging stage SHALL be a custom (dump-and-restore) stage that maps every persisted value into the new shape without data loss. The V10 → V11 stage SHALL convert each order's single category string into a category list (a non-empty string becomes a one-element list; an empty string becomes an empty list), convert each order's campaign name into a campaign list (a non-empty name becomes a one-element list; the empty unassigned string becomes an empty list), and initialize the new merged-source list to empty for every migrated order. The V10 schema SHALL be frozen as an embedded shadow definition so its attribute fingerprint stays intact.

#### Scenario: Single-select values migrate into lists

- **WHEN** a V10 store is opened with the plan targeting V11
- **THEN** every order's category and campaign values are mapped into lists per the conversion rules and no record is lost

##### Example: V10 to V11 value mapping

| V10 category | V10 campaignName | V11 categories | V11 campaignNames | V11 mergedSourceIDs |
| ------------ | ---------------- | -------------- | ----------------- | ------------------- |
| "beauty"     | "May-JP"         | ["beauty"]     | ["May-JP"]        | []                  |
| "beauty"     | ""               | ["beauty"]     | []                | []                  |
| ""           | ""               | []             | []                | []                  |

#### Scenario: On-disk regression covers the custom stage

- **WHEN** the on-disk migration regression suite runs
- **THEN** it includes a store persisted at V10 that is reopened with the plan, asserting the list conversions above and the survival of every other field
