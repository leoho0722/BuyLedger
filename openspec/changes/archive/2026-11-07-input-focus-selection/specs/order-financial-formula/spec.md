## MODIFIED Requirements

### Requirement: A cardless deduction never exceeds the charged amount

The stored cardless deduction amount SHALL NOT exceed the order's charged amount. This holds as a data invariant, so that revenue, defined as the charged amount plus any cardless supplement minus the cardless deduction, can never be negative.

When the deduction in the order form is greater than the charged amount and the selected payment method is cardless, the form SHALL keep the deduction exactly as entered, show a validation message at the bottom of the received amount section, below the explanation of cardless payment, asking the user to adjust the deduction, and SHALL NOT allow the order to be saved until the deduction no longer exceeds the charged amount. The form SHALL NOT change the deduction on its own when the deduction, the charged amount, or the payment method changes, and SHALL NOT correct an existing order's deduction when the form opens. A payment method that is not cardless saves no deduction, so the form SHALL NOT show the message or block saving for it.

#### Scenario: Excessive deduction is kept and blocks saving

- **GIVEN** a cardless order form whose charged amount is 1000
- **WHEN** the user enters a cardless deduction of 5000 and ends editing
- **THEN** the deduction field shows 5000, the message at the bottom of the section states that the deduction cannot exceed the charged amount and must be adjusted, and save is unavailable

#### Scenario: Adjusting the deduction allows saving

- **GIVEN** a cardless order form whose charged amount is 1000 and whose deduction of 5000 shows the validation message
- **WHEN** the user changes the deduction to 800
- **THEN** the message disappears and save is available

#### Scenario: Lowering the charged amount flags the deduction

- **GIVEN** a cardless order form whose charged amount is 2500 and whose deduction is 1000
- **WHEN** the user changes the charged amount to 500, ends editing, and then changes it to 3000
- **THEN** the deduction shows 1000 with the message and save unavailable after the first change, and shows 1000 without the message after the second

#### Scenario: Editing the charged amount keeps the deduction

- **GIVEN** a cardless order with no unsaved change whose charged amount is 2500 and whose deduction is 1000
- **WHEN** the user focuses the charged amount field, types 2600, ends editing, and saves
- **THEN** the deduction field shows 1000 and the saved deduction is 1000

#### Scenario: Emptying a typed charged amount keeps the deduction

- **GIVEN** a cardless order with no unsaved change whose charged amount is 2500 and whose deduction is 1000
- **WHEN** the user focuses the charged amount field, types 1, deletes it, dismisses the keyboard, and taps cancel
- **THEN** the deduction shows 1000 and the form closes without a discard confirmation

#### Scenario: Existing over-cap data is flagged when opened

- **GIVEN** a cardless order stored before this rule whose charged amount is 1000 and whose deduction is 1500
- **WHEN** the user opens the order form
- **THEN** the deduction field shows 1500 with the message, save is unavailable, and tapping cancel closes the form without a discard confirmation

#### Scenario: A non-cardless payment method is not flagged

- **GIVEN** an order form whose charged amount is 1000 and whose deduction is 1500 with a cardless payment method
- **WHEN** the user selects a payment method that is not cardless
- **THEN** the message is not shown and save is available

#### Scenario: Revenue cannot be negative

- **WHEN** an order is saved with any combination of charged amount, supplement, and deduction
- **THEN** the computed revenue is zero or greater

##### Example: deduction validation

| Charged | Supplement | Entered deduction | Can save | Stored deduction | Revenue |
| ------- | ---------- | ----------------- | -------- | ---------------- | ------- |
| 1000 | 0 | 300 | yes | 300 | 700 |
| 1000 | 0 | 1000 | yes | 1000 | 0 |
| 1000 | 0 | 1500 | no | (not saved) | (not saved) |
| 1000 | 200 | 1000 | yes | 1000 | 200 |
| 1000 | 200 | 1500 | no | (not saved) | (not saved) |
