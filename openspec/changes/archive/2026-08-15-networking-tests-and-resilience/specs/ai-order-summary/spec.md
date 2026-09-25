## MODIFIED Requirements

### Requirement: Streaming Markdown summary sheet

When AI summary is enabled, the system SHALL call the Ollama Cloud chat streaming endpoint and render the summary as Markdown that updates incrementally as content streams in. The summary content SHALL be produced in Traditional Chinese. Rendered Markdown SHALL display block structure including headings and lists, not only inline styles. While streaming, the sheet SHALL indicate progress; on completion it SHALL show the full rendered summary.

The stream SHALL be bounded by an overall duration limit of 30 seconds in production, in addition to any idle timeout the request layer provides. A response that keeps producing content slowly SHALL NOT be able to hold the sheet indefinitely. On reaching the limit the system SHALL stop the stream and present what was received together with a statement that the summary was cut short, rather than discarding the partial content or continuing to wait.

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
