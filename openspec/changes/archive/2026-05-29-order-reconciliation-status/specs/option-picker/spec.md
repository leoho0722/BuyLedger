## MODIFIED Requirements

### Requirement: Add-option flows are preserved across platforms

When adding is allowed, the picker SHALL provide an add control on every platform. The add control SHALL select its presentation by handler precedence:

1. When a payment-method add handler is provided, the add control SHALL present the payment method editor, collecting a name plus the cardless and bank-transfer flags.
2. Otherwise, when a name-sheet add handler is provided, the add control SHALL present a medium-height name editor sheet collecting a single name.
3. Otherwise, the add control SHALL present the add alert collecting a name.

Confirming an add SHALL invoke the corresponding add callback with the collected values and dismiss the picker. When no add handler is provided, the existing alert behavior SHALL be unchanged for all callers.

#### Scenario: Add via the general alert

- **WHEN** adding is allowed, neither a payment-method add handler nor a name-sheet add handler is provided, and the user confirms a non-empty trimmed name in the add alert
- **THEN** the add callback is invoked with that name and the picker dismisses

#### Scenario: Add a payment method via the editor sheet

- **WHEN** adding is allowed and a payment-method add handler is provided and the user confirms the editor sheet
- **THEN** the payment-method add callback is invoked with the name, cardless flag, and bank-transfer flag, and the picker dismisses

#### Scenario: Add via the name editor sheet

- **WHEN** adding is allowed, no payment-method add handler is provided, a name-sheet add handler is provided, and the user confirms a non-empty trimmed name in the medium-height name editor sheet
- **THEN** the name-sheet add callback is invoked with that name and the picker dismisses
