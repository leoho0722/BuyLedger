# ai-order-summary Specification

## Purpose

TBD - created by archiving change 'ai-product-summary'. Update Purpose after archive.

## Requirements

### Requirement: AI summary entry point gated by setting

The orders list SHALL present an "AI summary" toolbar action on iOS, iPadOS, and macOS, placed alongside the existing new-order action. The action SHALL be disabled when the currently filtered orders list is empty. When activated, the system SHALL read the `useAiSummary` setting and branch: if enabled, it SHALL present the streaming summary sheet; if disabled, it SHALL present a prompt alert.

#### Scenario: Activate with AI summary enabled

- **WHEN** the user activates the AI summary action and `useAiSummary` is enabled
- **THEN** the system presents the streaming summary sheet and begins summarizing the filtered list's product details

#### Scenario: Activate with AI summary disabled

- **WHEN** the user activates the AI summary action and `useAiSummary` is disabled
- **THEN** the system presents a prompt alert instead of the sheet, and does not call the AI service

#### Scenario: Empty filtered list

- **WHEN** the currently filtered orders list contains no orders
- **THEN** the AI summary action is disabled

---
### Requirement: Streaming Markdown summary sheet

When AI summary is enabled, the system SHALL call the Ollama Cloud chat streaming endpoint and render the summary as Markdown that updates incrementally as content streams in. The summary content SHALL be produced in Traditional Chinese. Rendered Markdown SHALL display block structure including headings and lists, not only inline styles. While streaming, the sheet SHALL indicate progress; on completion it SHALL show the full rendered summary.

#### Scenario: Streaming renders incrementally

- **WHEN** the summary sheet is presented and the service streams Markdown content
- **THEN** the sheet appends each streamed chunk to the displayed summary and re-renders the Markdown as it grows

#### Scenario: Stream completion

- **WHEN** the service signals the stream is done
- **THEN** the sheet shows the complete rendered Markdown summary and stops the progress indication

#### Scenario: Cancel by dismissing the sheet

- **WHEN** the user dismisses the summary sheet while streaming is in progress
- **THEN** the system cancels the in-flight stream and underlying network request without surfacing an error

---
### Requirement: Summary input scope is the filtered list's product details

The summary input SHALL be derived from the product details (item name, quantity, unit price with currency, and category) of the orders in the currently filtered list. When a category filter is active, the input SHALL be limited to that category's items because the filtered list itself is already scoped to that category. The system SHALL NOT include fabricated data not present in the orders.

#### Scenario: No category filter active

- **WHEN** no category filter is active
- **THEN** the summary input covers the product details of all orders in the current filtered list

#### Scenario: Category filter active

- **WHEN** a category filter is active
- **THEN** the summary input covers only the product details of that category, matching the filtered list

---
### Requirement: Disabled-state prompt alert with deep link to settings

When AI summary is disabled, the prompt alert SHALL present two actions: a left "close" action that dismisses the alert, and a right "go to settings" action. Activating the right action SHALL navigate the user to the settings page where the toggle lives. On iOS and iPadOS this SHALL switch to the more tab and push the settings page; on macOS it SHALL open the standard preferences window.

#### Scenario: Close the prompt

- **WHEN** the user activates the left "close" action
- **THEN** the alert is dismissed and no navigation occurs

#### Scenario: Navigate to settings (iOS / iPadOS)

- **WHEN** the user activates the right "go to settings" action on iOS or iPadOS
- **THEN** the app switches to the more tab and pushes the settings page

#### Scenario: Navigate to settings (macOS)

- **WHEN** the user activates the right "go to settings" action on macOS
- **THEN** the app opens the standard preferences window

---
### Requirement: AI summary setting and model configuration

The settings page SHALL provide a toggle that persists `useAiSummary`. The system SHALL persist an `aiSummaryModel` with a default model value used for summaries. In Debug builds the settings page SHALL provide a control to change the model at runtime from a candidate list with a custom-value option; in Release builds no model-switching control SHALL be presented and the default model SHALL be used.

#### Scenario: Toggle persists across launches

- **WHEN** the user changes the AI summary toggle
- **THEN** the new value is persisted and restored on the next launch

#### Scenario: Model switching available only in Debug

- **WHEN** the build is a Debug build
- **THEN** the settings page presents a model-switching control whose selection persists and takes effect on the next summary

#### Scenario: Model fixed in Release

- **WHEN** the build is a Release build
- **THEN** the settings page presents no model-switching control and the persisted default model is used

---
### Requirement: Failure handling shows empty/error state without fake data

When the AI service cannot produce a summary — missing API key, authentication failure, transport error, or non-success HTTP status — the sheet SHALL present a failure state with a retry action and SHALL NOT display fabricated summary content.

#### Scenario: Missing API key

- **WHEN** the Ollama API key is not configured
- **THEN** the sheet shows a failure state indicating the key is not set and offers retry

#### Scenario: Service or transport error

- **WHEN** the service returns an authentication failure, a non-success status, or a transport error occurs
- **THEN** the sheet shows a failure state with a friendly message and a retry action, and no partial fabricated content is presented as success
