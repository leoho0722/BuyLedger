## MODIFIED Requirements

### Requirement: Targeted multi-clause conditions use named rule boundaries

The implementation SHALL express the six targeted multi-clause rules through named, side-effect-free snapshots, predicates, collections, or computed properties. The application and test call sites MUST NOT repeat the original long boolean chains for payment-flag changes, merge eligibility, editor dirty state, delivery status membership, active filter state, or localization forbidden patterns.

#### Scenario: Payment flags are compared as one value

- **GIVEN** an existing payment method has three stored flags, with a missing dictionary entry treated as false
- **WHEN** the edit flow compares the stored flags with the three requested flags
- **THEN** it obtains flagsChanged from an Equatable flag value and returns true if and only if at least one flag differs

#### Scenario: Merge eligibility is evaluated by a named predicate

- **GIVEN** a primary order and an input list containing the primary order, merged orders, cancelled orders, different-currency orders, different-customer orders, and valid candidates
- **WHEN** the merge candidate query runs
- **THEN** it keeps only valid candidates and preserves the input order

#### Scenario: Editor dirty state is evaluated from snapshots

- **GIVEN** an initial payment-method editor snapshot and a draft snapshot
- **WHEN** the name or any one of the three flags differs
- **THEN** isDirty is true; when all snapshot fields are equal, isDirty is false

#### Scenario: Delivery status membership is centralized

- **GIVEN** orders with statuses arrived, delivered, pickedUp, partiallyArrived, cancelled, and merged
- **WHEN** CampaignSummary calculates arrivedCount
- **THEN** only arrived, delivered, and pickedUp contribute to arrivedCount

#### Scenario: Active filter state is named

- **GIVEN** a filter selection with datePeriod all, an empty category set, and no payment method
- **WHEN** the selection reports whether it is active
- **THEN** isActive is false
- **WHEN** datePeriod is not all, the category set is non-empty, or a payment method is set
- **THEN** isActive is true

#### Scenario: Localization forbidden patterns are data-driven

- **GIVEN** source text containing any one of the three existing forbidden navigationTitle patterns
- **WHEN** LocalizationCatalogTests checks the source
- **THEN** the check reports a violation
- **WHEN** source text contains none of the patterns
- **THEN** the check reports no violation

##### Example: Targeted rule truth table

| Rule | Input | Expected result |
| ----- | ----- | --------------- |
| Payment flags | stored=(false,false,false), requested=(false,true,false) | flagsChanged=true |
| Merge eligibility | candidate.status=cancelled | candidate excluded |
| Editor dirty state | draft name differs from initial name | isDirty=true |
| Delivery membership | status=partiallyArrived | does not increment arrivedCount |
| Active filter | datePeriod=all, categories=[], paymentMethod=nil | isActive=false |
| Localization pattern | source contains .navigationTitle(" | violation=true |
