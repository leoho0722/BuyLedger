## MODIFIED Requirements

### Requirement: Platform-adaptive option picker presentation

The single-select option picker (used for order source, category, payment method, currency, and tool-page selections) SHALL render a system List on iOS and iPadOS. The presentation MUST NOT change the available actions or the selectable options.

#### Scenario: iOS and iPadOS keep the system List

- **WHEN** the option picker is presented on iOS or iPadOS
- **THEN** the picker presents the system List with the add section, option rows, and empty state, unchanged from before this change
