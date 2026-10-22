## ADDED Requirements

### Requirement: An option added from the order editor is stored before it appears

When the user adds an order source, category, payment method or reconciliation status from inside the order editor, the new value SHALL be written to storage first. Only after the write succeeds SHALL it appear in the shared lookup data and in the editor's list, selected in the draft. When the write fails, the shared lookup data, the editor's list and the draft SHALL stay unchanged, and the failure SHALL be reported without replacing the open editor.

#### Scenario: A stored category appears and is selected

- **WHEN** the user adds the category 香氛 from the order editor and the write succeeds
- **THEN** 香氛 appears in the editor's category list and in lookup management, and the draft has 香氛 selected

#### Scenario: A failed add leaves everything unchanged

- **GIVEN** writing a new category fails
- **WHEN** the user adds the category 香氛 from the order editor
- **THEN** 香氛 does not appear in the editor's list or in lookup management, the draft keeps its previous categories, the editor stays open, and the failure is reported once the editor closes

#### Scenario: A write that finishes after its editor closed changes no other editor

- **GIVEN** the user adds the category 香氛 from order editor A, closes A before the write finishes, and opens order editor B
- **WHEN** the write succeeds
- **THEN** 香氛 is added to the shared lookup data, and editor B's draft and selected categories are unchanged

#### Scenario: A new payment method keeps its flags

- **WHEN** the user adds the payment method 街口支付 marked as cardless from the order editor and the write succeeds
- **THEN** the stored payment method, the shared lookup data and the editor's list all carry the cardless flag for 街口支付
