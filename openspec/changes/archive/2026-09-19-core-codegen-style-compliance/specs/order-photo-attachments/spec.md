## MODIFIED Requirements

### Requirement: Imported photos are normalized before storage

Each successfully loaded photo SHALL be downscaled so that its longest edge is at most 1600 pixels and re-encoded as JPEG before entering the draft. A picker item that cannot be turned into a stored photo SHALL be skipped without aborting the import of the remaining items. Three outcomes SHALL count as skipped: the transferable load throws, the transferable load yields no data, and normalization yields no data.

The import operation SHALL return both the normalized photo data and the number of skipped items, and SHALL NOT throw. The order edit form SHALL show the user that count when it is greater than zero, as supporting text inside the photo section rather than as a modal alert, and SHALL reset it when the next import begins. A skipped item SHALL NOT disappear without any indication.

#### Scenario: Oversized photo is downscaled

- **WHEN** the user picks a 4032x3024 photo
- **THEN** the stored photo data is a JPEG whose longest edge is at most 1600 pixels

#### Scenario: Failed items are skipped and reported

- **WHEN** the user picks 3 photos and one of them fails to load
- **THEN** the import returns the 2 normalized photos and a skipped count of 1
- **AND** the 2 photos are appended to the draft
- **AND** the photo section shows supporting text stating that 1 photo could not be imported

#### Scenario: Normalization failure counts as skipped

- **WHEN** a picked item loads successfully but cannot be downscaled or re-encoded
- **THEN** that item is counted as skipped
- **AND** the remaining items still enter the draft

#### Scenario: A fully successful import reports nothing

- **WHEN** every picked item loads and normalizes successfully
- **THEN** the photos are appended, the skipped count is zero, and no import failure text is shown

#### Scenario: A later import clears the previous report

- **GIVEN** the photo section shows that a previous import skipped items
- **WHEN** the user starts another import
- **THEN** the previous skipped count is cleared before the new result is reported

##### Example: import outcome by picked items

| Picked items | Normalized successfully | Draft gains | Skipped count | Supporting text |
| ------------ | ----------------------- | ----------- | ------------- | --------------- |
| 3 | 3 | 3 photos | 0 | none |
| 3 | 2 | 2 photos | 1 | 1 photo could not be imported |
| 2 | 0 | no photos | 2 | 2 photos could not be imported |
