## ADDED Requirements

### Requirement: Filter chips meet the minimum hit region through a shared component

The repeated filter chip implementations SHALL be consolidated into a single shared component, and that component SHALL provide a hit region of at least 44 by 44 points while preserving the current visible size. The hit region SHALL be declared using the chip's own capsule shape so that adjacent chips do not overlap one another's tappable area.

#### Scenario: Each chip is independently tappable

- **WHEN** two filter chips are rendered side by side with the existing spacing
- **THEN** each chip's hit region measures at least 44 points in both dimensions and a tap near the boundary activates the intended chip

##### Example: measured chips before consolidation

| Location | Measured height before | Required |
| -------- | ---------------------- | -------- |
| Compact order list filter chip | about 34 points | at least 44 points |
| Compact order list unified filter trigger | about 34 points | at least 44 points |
| Regular order list status chips | about 32 points | at least 44 points |
| Regular order list date chips | about 32 points | at least 44 points |
| Regular order list category trigger | about 32 points | at least 44 points |
| Regular order list payment method trigger | about 32 points | at least 44 points |

#### Scenario: Chip appearance is unchanged

- **WHEN** the consolidated chip renders in any of its six original locations
- **THEN** its visible size, padding, and selected-state appearance match the appearance before consolidation

### Requirement: Data-mutating controls meet the minimum hit region

A control that mutates data without a confirmation step SHALL provide a hit region of at least 44 by 44 points. The campaign receipt status toggle mutates order data with no confirmation and no undo, and therefore SHALL meet the minimum.

#### Scenario: Receipt status toggle is reliably tappable

- **WHEN** the campaign detail screen renders the receipt status toggle for an order row
- **THEN** the toggle's hit region measures at least 44 points in both dimensions

### Requirement: Gesture-only functions gain a visible alternative

Every function reachable by a gesture SHALL also be reachable through a visible button or menu item, so that users of voice control, switch control, or an external keyboard can invoke it. A visible alternative SHALL be placed within an existing menu or control group rather than added as a standalone control where a suitable group already exists.

#### Scenario: Campaign deletion is reachable without a long press

- **WHEN** the user opens the actions menu on the campaign detail screen
- **THEN** a delete item is present, and invoking it deletes the campaign with the same confirmation as the long-press path

#### Scenario: Line item deletion is reachable without a swipe

- **WHEN** the order edit form displays its line items
- **THEN** a visible deletion affordance is available, matching the visibility of the existing add affordance

#### Scenario: Existing gesture paths still work

- **WHEN** the user long-presses a campaign row or swipes a line item after this change
- **THEN** the existing gesture path still performs the deletion, because the visible alternative is added rather than substituted

### Requirement: Photo viewer follows the standard gesture vocabulary

The full screen photo viewer SHALL support pinch to zoom and double tap to magnify, matching the system photo viewing vocabulary. Paging SHALL remain active only while the zoom scale is at its baseline; once magnified, horizontal dragging SHALL pan the image instead of changing pages.

#### Scenario: Pinch magnifies the photo

- **WHEN** the user pinches outward on a displayed photo
- **THEN** the photo magnifies, allowing detail such as labels and amounts to be read

#### Scenario: Double tap toggles between baseline and magnified

- **WHEN** the user double taps a photo at baseline scale
- **THEN** the photo magnifies, and a further double tap returns it directly to baseline rather than magnifying further

#### Scenario: Paging yields to panning while magnified

- **WHEN** the photo is magnified and the user drags horizontally
- **THEN** the image pans within the viewport and the viewer does not change pages

#### Scenario: Paging resumes at baseline scale

- **WHEN** the photo has been returned to baseline scale and the user drags horizontally
- **THEN** the viewer changes pages as it did before this change
