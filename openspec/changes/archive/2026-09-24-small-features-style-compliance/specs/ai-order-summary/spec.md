## MODIFIED Requirements

### Requirement: AI summary setting and model configuration

The settings page SHALL provide a toggle that persists whether AI summary is enabled. The system SHALL persist an AI summary model name with a default model value used for summaries. In Debug builds the settings page SHALL provide a control to change the model at runtime from a candidate list with a custom-value option; in Release builds no model-switching control SHALL be presented and the default model SHALL be used.

Renaming the code identifiers that hold these two settings SHALL NOT change the keys under which they are stored, so that a value persisted by an earlier version is still read after an update.

#### Scenario: Toggle persists across launches

- **WHEN** the user changes the AI summary toggle
- **THEN** the new value is persisted and restored on the next launch

#### Scenario: Model switching available only in Debug

- **WHEN** the build is a Debug build
- **THEN** the settings page presents a model-switching control whose selection persists and takes effect on the next summary

#### Scenario: Model fixed in Release

- **WHEN** the build is a Release build
- **THEN** the settings page presents no model-switching control and the persisted default model is used

#### Scenario: A toggle saved before an identifier rename is still read

- **WHEN** the AI summary toggle was turned on by a version that used a different code identifier for it, and the app is updated
- **THEN** the toggle is still on after the update, because the stored key did not change
