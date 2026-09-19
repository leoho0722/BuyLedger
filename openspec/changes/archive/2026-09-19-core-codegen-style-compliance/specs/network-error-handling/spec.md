## ADDED Requirements

### Requirement: Networking errors carry the source failure without exposing it to the user

The networking error type SHALL NOT conform to Equatable. Categories that wrap a framework failure, namely transport failure and decoding failure, SHALL carry that failure under an underlying label whose type is constrained to Error and Sendable, instead of a reconstructed message string. A framework error SHALL be bridged to NSError when it is wrapped, so that its domain, code, and user info survive the boundary. Every failure this layer wraps originates in a framework, so this layer has no unbridged case. Categories that carry only classification data, namely status code, service-reported code, quota exhaustion, and invalid credential, SHALL keep their existing payloads. The underlying error SHALL be available for logging and diagnostics only; any text shown to the user SHALL be produced by the feature layer and SHALL remain subject to the existing rule that error text never carries a request URL, a header value, or a configuration value.

#### Scenario: A transport failure keeps the framework error

- **WHEN** a request fails before a response arrives
- **THEN** the thrown transport failure carries the bridged error the URL loading system reported

##### Example: Request times out

- **GIVEN** the URL loading system reports a timeout in the `NSURLErrorDomain` domain
- **WHEN** the networking layer maps the failure
- **THEN** the thrown transport failure carries an underlying error whose domain is `NSURLErrorDomain` and whose code is the reported timeout code

#### Scenario: A decoding failure keeps the decoding error

- **WHEN** a success status returns a payload that does not match the expected shape
- **THEN** the thrown decoding failure carries the bridged decoding error raised while decoding

##### Example: Missing required field

- **GIVEN** decoding a rates payload fails because a required key is absent
- **WHEN** the networking layer maps the failure
- **THEN** the thrown decoding failure carries an underlying error whose localized description is the one the decoder produced

#### Scenario: User-facing text is unaffected by the wrapped error

- **WHEN** a feature presents a networking failure to the user
- **THEN** the presented text comes from the feature's own message mapping
- **AND** the text contains no part of the request address, no header value, and no configuration value

#### Scenario: Callers distinguish categories by pattern matching

- **WHEN** a caller or a test needs to tell one failure category from another
- **THEN** it matches the case rather than comparing two whole error values
