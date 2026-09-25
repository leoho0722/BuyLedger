## ADDED Requirements

### Requirement: Credentials travel in headers, not in the URL

A request SHALL carry its credential in a request header. A credential SHALL NOT appear in a URL path or query string, because URLs are recorded by the system's network logging, retained by intermediaries, and are more likely to be copied out when reporting a problem. This holds regardless of who can obtain the product, because the leak path is the URL itself rather than the binary.

#### Scenario: The rate service request carries a header credential

- **WHEN** a request is made to the exchange rate service
- **THEN** the credential is sent as a request header and the request URL contains no credential

#### Scenario: No request path embeds a credential

- **WHEN** the request construction sites are inspected
- **THEN** none interpolates a credential into a URL path or query string

### Requirement: Credentials never reach logs, messages, or diagnostics

A credential SHALL NOT be written to a log, an error message, a crash diagnostic, or any other output that outlives the request. This applies to the credential itself and to any value containing it, such as a fully composed request URL.

#### Scenario: No output site can carry a credential

- **WHEN** the logging, error construction, and diagnostic sites are inspected
- **THEN** none interpolates a credential or a value containing one

### Requirement: An embedded credential is recorded as an accepted risk with its precondition

Where a credential ships inside the product rather than being supplied at runtime, that SHALL be recorded as an evaluated and accepted risk rather than left undocumented. The record SHALL state the precondition under which the acceptance holds, and SHALL state what must change if that precondition stops holding.

The precondition for this project is that the product is not distributed beyond its developer and the credentials belong to that developer. An undocumented embedded credential SHALL NOT be treated as accepted merely because nobody has objected to it.

#### Scenario: The acceptance and its precondition are discoverable

- **WHEN** a reader examines how credentials are provided
- **THEN** the documentation states that embedding is an accepted risk, states the precondition, and states what must change if the product is distributed

#### Scenario: A rotation procedure exists

- **WHEN** a credential is suspected of having leaked
- **THEN** the documented procedure states how to revoke and reissue it and that a rebuild and reinstall is required for the new value to take effect

#### Scenario: Distribution invalidates the acceptance

- **WHEN** the product is distributed beyond its developer
- **THEN** the recorded precondition no longer holds, and the documented consequence is that credentials must move out of the product
