## MODIFIED Requirements

### Requirement: Guard edit sheets against silent data loss on dismissal

Each sheet that holds user input which is not yet committed — the order editor, the campaign editor, the payment method editor, and the orders filter sheet — SHALL track whether that input differs from the values it was opened with (a dirty state). While the sheet is dirty, it SHALL prevent interactive swipe-to-dismiss so that uncommitted input cannot be lost silently. The dirty state SHALL be derived from all uncommitted fields of that sheet, not a partial subset.

For sheets bound to a feature store, the dirty state SHALL be derived from state held by that feature rather than from view-local state, so that it is observable and assertable outside the view layer.

Coverage of all uncommitted fields SHALL be guaranteed structurally rather than by maintaining a parallel list of fields. Where a sheet's uncommitted input is grouped into a single value, the dirty state SHALL be that value compared against the value captured when the sheet opened, so that adding a field cannot omit it from the comparison. A separate fingerprint enumerating the fields SHALL NOT be maintained, because it duplicates the field list and can silently fall out of step with it.

Values that are presentation state rather than user input — focus, navigation route within the sheet, and in-flight picker selections — SHALL NOT contribute to the dirty state.

#### Scenario: Dirty edit sheet resists swipe-to-dismiss

- **WHEN** the user has modified at least one draft field in the order, campaign, or payment method editor and then swipes down to dismiss the sheet
- **THEN** the sheet does not dismiss and the draft is preserved

#### Scenario: Clean edit sheet dismisses freely

- **WHEN** the user opens an editor and swipes down to dismiss without modifying any draft field
- **THEN** the sheet dismisses immediately without any confirmation

#### Scenario: Filter sheet with pending selections resists swipe-to-dismiss

- **WHEN** the user has changed at least one pending selection in the orders filter sheet and then swipes down to dismiss it
- **THEN** the sheet does not dismiss and the pending selections are preserved

#### Scenario: Dirty state is derived from feature state

- **WHEN** the dirty state of a store-bound sheet is inspected
- **THEN** it is computed from values held by that sheet's feature, so a test driving the feature can assert it without rendering the view

#### Scenario: A newly added draft field is covered without any further step

- **WHEN** a new field is added to a sheet's uncommitted input
- **THEN** modifying it makes the sheet dirty, because the dirty state compares the whole grouped value rather than an enumerated list of fields

#### Scenario: Presentation state does not make the sheet dirty

- **WHEN** the user only moves focus between fields, navigates within the sheet, or opens a picker without choosing a value
- **THEN** the sheet is not dirty and dismisses without a confirmation
