## ADDED Requirements

### Requirement: AI summary provider is a configured value with a single extension point

The AI summary SHALL be produced by an AI provider selected from a closed list of supported providers, together with a model name for that provider. Each supported provider SHALL define the name of its API key configuration, its default model, and its Debug candidate models, and the summary request SHALL be sent through a provider-neutral chat client built for the selected provider. Supporting an additional provider SHALL require adding it to the provider list and to the client construction for providers, and SHALL NOT require changing the summary sheet's reducer or view. In this version the only supported provider SHALL be Anthropic, with default model `claude-haiku-5-5`, Debug candidates `claude-haiku-5-5`, `claude-sonnet-5-5` and `claude-opus-5-5`, and API key configuration `ANTHROPIC_API_KEY`.

The request for the selected provider SHALL carry the summary prompt as a single user message, SHALL carry the selected model, and SHALL carry its API key only in a request header, never in the request URL.

#### Scenario: The default configuration summarizes with Claude Haiku 5.5

- **WHEN** the user has never chosen a provider or model and opens the AI summary sheet with an Anthropic key configured
- **THEN** the summary request is sent to Anthropic with model `claude-haiku-5-5`, the prompt as the only user message, and the key in a request header

#### Scenario: The summary sheet passes the configured provider and model

- **WHEN** the orders container presents the AI summary sheet while the settings hold provider `anthropic` and model `claude-sonnet-5-5`
- **THEN** the sheet requests the summary from provider `anthropic` with model `claude-sonnet-5-5` and reads the API key configured for `anthropic`

## MODIFIED Requirements

### Requirement: Streaming Markdown summary sheet

When AI summary is enabled, the system SHALL stream the summary from the configured AI provider's chat streaming API through the LKAIKit chat client and render the summary as Markdown that updates incrementally as content streams in. The summary content SHALL be produced in Traditional Chinese. Rendered Markdown SHALL display block structure including headings and lists, not only inline styles. While streaming, the sheet SHALL indicate progress; on completion it SHALL show the full rendered summary.

The stream SHALL be bounded by an overall duration limit of 30 seconds in production, in addition to any idle timeout the request layer provides. A response that keeps producing content slowly SHALL NOT be able to hold the sheet indefinitely. On reaching the limit the system SHALL stop the stream and present what was received together with a statement that the summary was cut short, rather than discarding the partial content or continuing to wait.

When the stream completes, or reaches the overall duration limit, without having received any content other than whitespace, the sheet SHALL stop the progress indication and present the failure state with a retry action instead of an empty summary or a statement that the summary was cut short.

#### Scenario: Streaming renders incrementally

- **WHEN** the summary sheet is presented and the service streams Markdown content
- **THEN** the sheet appends each streamed chunk to the displayed summary and re-renders the Markdown as it grows

#### Scenario: Stream completion

- **WHEN** the service signals the stream is done
- **THEN** the sheet shows the complete rendered Markdown summary and stops the progress indication

#### Scenario: Cancel by dismissing the sheet

- **WHEN** the user dismisses the summary sheet while streaming is in progress
- **THEN** the system cancels the in-flight stream and underlying network request without surfacing an error

#### Scenario: Overall 30-second duration limit ends a slow stream

- **WHEN** a stream keeps producing content past the 30-second overall duration limit
- **THEN** the system stops the stream, keeps the content received so far, stops the progress indication, and states that the summary was cut short

#### Scenario: A stream that ends without content shows a failure

- **WHEN** the stream completes, or reaches the 30-second overall duration limit, without having received any content other than whitespace
- **THEN** the sheet stops the progress indication and shows the failure state with a retry action instead of an empty summary

### Requirement: AI summary setting and model configuration

The settings page SHALL provide a toggle that persists whether AI summary is enabled. The system SHALL persist the AI summary provider together with a model name for that provider, defaulting to the default provider and that provider's default model. In Debug builds the settings page SHALL provide a control to change the model at runtime from the selected provider's candidate list with a custom-value option; in Release builds no model-switching control SHALL be presented and the persisted model SHALL be used. No build SHALL present a control to change the provider in this version.

A model equal to the provider's default model SHALL be stored as following the default rather than as a fixed name, so that a later change of the provider's default model applies to installations where the user never chose another model. A stored model name SHALL be used only together with the provider it was saved with. When no provider is stored, as for values written before providers were introduced, or the stored provider is not a supported provider, the system SHALL use the default provider and its default model and SHALL NOT send the stored model name to any provider.

Renaming the code identifiers that hold these settings SHALL NOT change the keys under which they are stored, so that a value persisted by an earlier version is still read after an update.

#### Scenario: Toggle persists across launches

- **WHEN** the user changes the AI summary toggle
- **THEN** the new value is persisted and restored on the next launch

#### Scenario: Model switching available only in Debug

- **WHEN** the build is a Debug build
- **THEN** the settings page presents a model-switching control listing the selected provider's candidate models and a custom option, whose selection persists and takes effect on the next summary

#### Scenario: Model fixed in Release

- **WHEN** the build is a Release build
- **THEN** the settings page presents no model-switching control and the persisted model is used

#### Scenario: A toggle saved before an identifier rename is still read

- **WHEN** the AI summary toggle was turned on by a version that used a different code identifier for it, and the app is updated
- **THEN** the toggle is still on after the update, because the stored key did not change

#### Scenario: A model saved before providers existed is not sent to the new provider

- **WHEN** the stored settings contain a model name but no provider, and the settings are read
- **THEN** the provider is the default provider and the model is that provider's default model

##### Example: provider and model reads

| Stored provider | Stored model | Read provider | Read model | Notes |
| --------------- | ------------ | ------------- | ---------- | ----- |
| never written | never written | `anthropic` | `claude-haiku-5-5` | fresh install |
| never written | `gemma4:31b-cloud` | `anthropic` | `claude-haiku-5-5` | written before providers existed |
| `anthropic` | `claude-sonnet-5-5` | `anthropic` | `claude-sonnet-5-5` | user choice in Debug |
| `anthropic` | empty | `anthropic` | `claude-haiku-5-5` | empty model falls back to the provider default |
| `retired-provider` | `some-model` | `anthropic` | `claude-haiku-5-5` | unsupported provider |

#### Scenario: Saving settings writes the provider with the model

- **WHEN** the settings are saved with a provider and a model
- **THEN** the provider is persisted, and the model is persisted as following the default when it equals the provider's default model, otherwise as the chosen name

##### Example: stored values after saving

| Saved provider | Saved model | Stored provider | Stored model |
| -------------- | ----------- | --------------- | ------------ |
| `anthropic` | `claude-haiku-5-5` | `anthropic` | empty (follows the provider default) |
| `anthropic` | `claude-sonnet-5-5` | `anthropic` | `claude-sonnet-5-5` |

### Requirement: Failure handling shows empty/error state without fake data

When the AI service cannot produce a summary — missing API key, authentication failure, transport error, or non-success HTTP status — the sheet SHALL present a failure state with a retry action and SHALL NOT display fabricated summary content.

Failures reported by the chat client SHALL map to the sheet's existing failure categories: an invalid key or a permission failure SHALL be shown as an authentication failure; an exhausted quota as quota exhaustion; rate limiting as a server error with status 429; an unavailable service as a server error with its status code; a network failure as a connection problem; an unreadable response as a response that could not be parsed; and a rejected request, a refusal, or an unrecognized failure as a service error with a short code. A cancelled stream SHALL end without surfacing an error.

#### Scenario: Missing API key

- **WHEN** the API key for the configured provider is not configured
- **THEN** the sheet shows a failure state indicating the summary is not set up, offers retry, and sends no request

#### Scenario: Service or transport error

- **WHEN** the service returns an authentication failure, a non-success status, or a transport error occurs
- **THEN** the sheet shows a failure state with a friendly message and a retry action, and no partial fabricated content is presented as success

##### Example: chat client failure mapping

| Chat client failure | Failure shown by the sheet |
| ------------------- | -------------------------- |
| invalid API key | AI service authentication failed |
| permission denied | AI service authentication failed |
| quota exceeded | API quota exhausted |
| rate limited | server error (429) |
| service unavailable with status 529 | server error (529) |
| network failure | connection problem |
| unreadable response | response could not be parsed |
| invalid request | service error (invalid_request) |
| refused | service error (refused) |
| cancelled | no failure; the stream ends |
