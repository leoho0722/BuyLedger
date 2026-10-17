## MODIFIED Requirements

### Requirement: Campaign write failures are visible to the user

A failed campaign write SHALL be presented to the user as a dismissible dialog stating the reason. A failure message SHALL NOT be written to state that no presentation reads, because that leaves the code appearing to handle errors while the user observes nothing. Load failures SHALL keep their existing persistent presentation and SHALL NOT share a carrier with one-shot operation failures.

While the add/edit form is open, or is closing by any path (saving, canceling, confirming discard, or swiping down), a failure dialog SHALL NOT replace or interrupt the form; it SHALL be held and presented once the form has finished closing, because a dialog set during the sheet's dismissal is discarded by the system while the state still claims it is shown. When several failures arrive in that window, the most recent one SHALL be presented.

#### Scenario: Silent failure is not possible

- **WHEN** any campaign write fails
- **THEN** a dialog stating the reason is presented to the user

#### Scenario: Dismissal leaves no residue

- **WHEN** the user dismisses a campaign write failure dialog
- **THEN** no error text remains in the campaign presentation

#### Scenario: No unread failure carrier remains

- **WHEN** the campaign feature state is inspected
- **THEN** it holds no failure message field that no presentation reads

#### Scenario: A save failure after the form closes is still shown

- **WHEN** the user saves the add/edit form, the form starts closing, and the campaign write fails before the form has finished closing
- **THEN** the failure dialog is presented after the form has closed

##### Example: failing save of a new campaign

- **GIVEN** campaign writes are made to fail and the add form contains the name "失敗開團"
- **WHEN** the user taps save
- **THEN** the form closes, then a dialog titled "操作失敗" with the message "開團儲存失敗，請稍後再試。" is shown, and the campaign list does not contain "失敗開團"

#### Scenario: A failure arriving while the form is open waits for it to close

- **WHEN** a campaign write failure arrives while the add/edit form is still open, and the user later cancels the form
- **THEN** the form stays open until the user cancels, and the failure dialog is presented only after the form has finished closing

##### Example: automatic status update fails while the add form is open

- **GIVEN** the add form is open and the automatic close-date status update of an existing campaign fails
- **WHEN** the user later taps cancel on the unchanged form
- **THEN** the form remains open until that tap, and only after it finishes closing a dialog with the message "開團狀態自動更新失敗，請稍後再試。" is shown
