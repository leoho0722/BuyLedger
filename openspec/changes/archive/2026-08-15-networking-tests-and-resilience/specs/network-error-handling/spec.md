## ADDED Requirements

### Requirement: Error messages never carry credentials

An error surfaced from the networking layer SHALL NOT include a request URL, a header value, or any other text that can contain an API key. When URL composition is rejected because a configured credential contains a control character, the reported message SHALL describe the failure without reproducing the address.

#### Scenario: Control-character URL composition rejection omits the address

- **WHEN** a configured API key contains a control character and URL composition is rejected before calling `URL(string:)`
- **THEN** the reported error states that the request could not be constructed and contains no part of the address

The later `URL(string:)`-nil guard remains a defense-in-depth branch. Under the current Foundation behavior, a NUL is percent-encoded rather than making `URL(string:)` return `nil`, so the control-character guard is a separate precondition. The `URL(string:) == nil` branch is therefore defensive-only and practically unreachable under the current Foundation behavior for this input path. Tests cover the precondition and do not claim coverage of the `URL(string:)`-nil branch.

#### Scenario: No error path reproduces a key

- **WHEN** the networking layer's error construction sites are inspected
- **THEN** none of them interpolates a URL, a header value, or a configuration value into the message

### Requirement: Every error category has a defined boundary and is covered by tests

The networking layer SHALL classify failures into transport failure, non-success status code, decoding failure, service-reported business error, quota exhaustion, and invalid credential. Each category SHALL have at least one test that drives the layer into it and asserts the resulting classification, so that a change to the mapping cannot pass silently.

#### Scenario: A non-success status code is classified as such

- **WHEN** the service returns a status code outside the success range
- **THEN** the failure is classified as a status-code failure carrying that code

#### Scenario: A malformed payload is classified as a decoding failure

- **WHEN** the service returns a success status with a payload that does not match the expected shape
- **THEN** the failure is classified as a decoding failure

#### Scenario: Service-reported errors map to their own categories

- **WHEN** the service returns a success status with a payload reporting an error condition
- **THEN** an invalid or inactive credential maps to the invalid-credential category, an exhausted quota maps to the quota category, and any other reported code maps to the generic service-error category carrying that code

#### Scenario: An unrecognized result is classified as a generic service error

- **WHEN** the service returns a success status with a result value other than `success` or `error`, such as `partial`
- **THEN** the failure is classified as a generic service error carrying `unexpected-result-partial`

##### Example: error classification

| Condition | Classification |
| --------- | -------------- |
| transport failure before a response | transport |
| status code outside success range | status code |
| success status, payload shape mismatch | decoding |
| success status, reported code invalid-key | invalid credential |
| success status, reported code inactive-account | invalid credential |
| success status, reported code quota-reached | quota |
| success status, any other reported code | service error carrying the code |

### Requirement: Request construction preserves its contract

The networking layer SHALL assemble each outbound `URLRequest` with the caller-specified HTTP method, headers, body, and timeout. Tests SHALL inspect the request received by the injected data client and assert those fields.

#### Scenario: Request assembly preserves caller inputs

- **WHEN** `HTTPClient.send` is called with a POST method, authorization and content-type headers, a body, and a 12.5-second timeout
- **THEN** the injected data client receives a request with the same URL, method, headers, body, and timeout

### Requirement: The absence of retry is stated rather than implied

The networking layer SHALL NOT describe a retry policy it does not implement. Documentation SHALL state plainly that no automatic retry exists and that a failed request is surfaced to the caller, so that a reader cannot mistake an intention for a behaviour.

#### Scenario: Documentation matches behaviour

- **WHEN** the error classification's documentation is read
- **THEN** it states that no automatic retry is performed, rather than describing which categories would be retried

#### Scenario: A failure reaches the caller unretried

- **WHEN** a transport failure occurs
- **THEN** the failure is surfaced to the caller without a second attempt
