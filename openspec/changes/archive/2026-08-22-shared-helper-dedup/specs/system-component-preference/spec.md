## MODIFIED Requirements

### Requirement: System-provided capabilities are not reimplemented

An interface component SHALL NOT reimplement a capability that a system component already provides, unless the system component demonstrably cannot meet a stated requirement. Where a hand-built component exists for a capability the system provides, it SHALL be replaced by the system component and its source removed, so that it cannot be adopted again by a later implementer.

Reimplementation includes assembling a capability inline from primitive shapes, not only defining a named component for it. A determinate progress indicator drawn as a track and a fill inside a measuring container is a reimplementation, even though no reusable type was declared, and SHALL be replaced by the system progress view with the project's existing style extension.

#### Scenario: Hand-built search field is replaced by the system presentation

- **WHEN** a screen presents a search entry point
- **THEN** it uses the system search presentation, and the hand-built search field type no longer exists in the codebase

#### Scenario: Hand-built segmented control is removed

- **WHEN** the codebase is searched for the hand-built segmented control type
- **THEN** no definition and no call site remain, and screens offering mutually exclusive view switching use the system segmented picker

#### Scenario: Hand-built progress bar is replaced by the system progress view

- **WHEN** a screen displays determinate progress
- **THEN** it uses the system progress view, and the progress value is exposed to assistive technology

#### Scenario: Inline progress drawing is also a reimplementation

- **WHEN** the codebase is searched for a track-and-fill pair of shapes sized by a measuring container
- **THEN** no such construction remains, because each has been replaced by the system progress view with the project's style extension

#### Scenario: Decorative shapes remain permitted

- **WHEN** a shape is used purely as a background or clipping form for a label
- **THEN** it is not a reimplementation and is permitted, because it carries no capability the system provides
