## ADDED Requirements

### Requirement: Attach photos to an order via the native photo picker

The order edit form SHALL provide an order-photos section that opens the system PhotosPicker in multiple-selection mode filtered to images. An order SHALL hold at most 5 photos. The picker SHALL limit selection to the remaining capacity (5 minus the photos already attached), and the reducer SHALL enforce the cap by truncating any imported batch that would exceed 5, regardless of what the picker returns.

#### Scenario: Adding photos within capacity

- **WHEN** the user picks 3 photos while the draft has 0 photos
- **THEN** the draft contains 3 photos, appended in selection order

#### Scenario: Cap is enforced at 5 photos

- **WHEN** an import would push the photo count past 5
- **THEN** photos are appended in order only up to the cap and the excess is discarded

##### Example: boundary cases for the photo cap

| Existing photos | Imported batch | Resulting photos | Notes |
| --------------- | -------------- | ---------------- | ----- |
| 0 | 5 | 5 | full batch accepted |
| 3 | 4 | 5 (3 existing + first 2 imported) | excess discarded |
| 5 | 1 | 5 (unchanged) | already full |

#### Scenario: Add control unavailable when full

- **WHEN** the draft already has 5 photos
- **THEN** the add-photos control is not available until a photo is deleted

### Requirement: Imported photos are normalized before storage

Each successfully loaded photo SHALL be downscaled so that its longest edge is at most 1600 pixels and re-encoded as JPEG before entering the draft. A picker item whose data fails to load or decode SHALL be skipped without aborting the import of the remaining items and without surfacing an error alert.

#### Scenario: Oversized photo is downscaled

- **WHEN** the user picks a 4032x3024 photo
- **THEN** the stored photo data is a JPEG whose longest edge is at most 1600 pixels

#### Scenario: Failed item is skipped silently

- **WHEN** the user picks 3 photos and one of them fails to load
- **THEN** the 2 successfully loaded photos are appended and no error alert is shown

### Requirement: Delete an attached photo

Each attached photo SHALL be rendered as a thumbnail with a delete control that removes exactly that photo from the draft. The removal SHALL take effect in persistence when the order is saved.

#### Scenario: Deleting the middle photo preserves the order of the rest

- **GIVEN** the draft photos are [A, B, C]
- **WHEN** the user taps delete on B
- **THEN** the draft photos are [A, C] in that order

### Requirement: Photos persist with the order

Order photos SHALL be stored in SwiftData as binary data on the order record and SHALL share the order's lifecycle: saving the order persists the current draft photos, deleting the order removes its photos, and rebuilding an order during master-data cascade renames SHALL carry the photos unchanged. Reopening the edit form for a persisted order SHALL show its stored photos.

#### Scenario: Photos survive app relaunch

- **WHEN** the user saves an order with 2 photos, terminates the app, relaunches, and reopens the edit form for that order
- **THEN** the form shows the same 2 photos

#### Scenario: Master-data rename keeps photos

- **WHEN** an order source, category, payment method, verification status, or campaign referenced by an order with photos is renamed
- **THEN** the rebuilt order still has the identical photo data

### Requirement: Existing stores migrate with empty photo lists

The schema SHALL advance to a new version that adds the photos attribute with an empty-array default, bridged from the previous version by a lightweight migration stage. Opening a store persisted at any retained earlier version SHALL preserve every order and its field values, with each migrated order having zero photos.

#### Scenario: Pre-photos store opens at the new target

- **GIVEN** an on-disk store at the previous schema version containing 3 orders
- **WHEN** the store is opened with the migration plan targeting the new version
- **THEN** all 3 orders are present with their field values intact and each has an empty photo list

### Requirement: View attached photos full screen

Tapping a photo thumbnail outside its delete control SHALL present a photo viewer as a sheet on all platforms, showing that photo scaled to fit with rounded corners against the system background, which SHALL adapt to light and dark appearance. The sheet's navigation bar SHALL show the position indicator (x/n) as its centered title and a close button as its trailing toolbar item. The photo area SHALL lie strictly below the navigation bar and SHALL NOT extend behind it, with a uniform margin separating the photo area from the bar and the sheet edges. The viewer SHALL support horizontal swiping to navigate between all photos attached to the draft, in their stored order, stopping at the first and the last photo. The viewer SHALL show a position indicator and a close control; closing SHALL return to the edit form without altering the draft. Tapping a thumbnail's delete control SHALL NOT open the viewer.

#### Scenario: Tapping a thumbnail opens the viewer at that photo

- **GIVEN** the draft photos are [A, B, C]
- **WHEN** the user taps the thumbnail of B
- **THEN** the viewer opens full screen showing B with indicator 2/3

#### Scenario: Swiping navigates between photos in stored order

- **GIVEN** the viewer is showing B of [A, B, C]
- **WHEN** the user swipes left
- **THEN** the viewer shows C

##### Example: swipe boundaries

| Current photo | Swipe direction | Result | Notes |
| ------------- | --------------- | ------ | ----- |
| B of [A, B, C] | left | C | next photo |
| B of [A, B, C] | right | A | previous photo |
| A of [A, B, C] | right | A | stops at first |
| C of [A, B, C] | left | C | stops at last |

#### Scenario: Closing the viewer preserves the draft

- **WHEN** the user taps the close control in the viewer
- **THEN** the edit form reappears with the draft photos unchanged

#### Scenario: Delete control does not open the viewer

- **WHEN** the user taps the delete control on a thumbnail
- **THEN** that photo is removed from the draft and no viewer is presented
