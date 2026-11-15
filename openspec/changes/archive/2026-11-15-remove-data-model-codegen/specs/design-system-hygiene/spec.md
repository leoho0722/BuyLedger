## MODIFIED Requirements

### Requirement: Design system entry points are enforced by a source scan

The test suite SHALL include a source scan that reads the app's own Swift sources and fails when a construction bypasses an established design system entry point. The scan SHALL be implemented inside the existing test target rather than by an external analysis tool, so that it runs with the normal test suite and introduces no additional toolchain.

Before comparing, the scan SHALL strip line comments and double-quoted string literals from each source line, so that prose, documentation, and localized copy containing the same wording are not reported.

Each failure message SHALL name the offending file and line and SHALL state the correct alternative, so that a violation is resolved by following the message rather than by rediscovering the rule.

An exemption SHALL be expressible as a named marker on the offending line that carries a written reason. The scan SHALL fail when a marker carries no reason, and SHALL list every active exemption in its output so that exemptions cannot accumulate unnoticed.

#### Scenario: A bypass introduced later fails the scan

- **WHEN** a source file uses a construction that an established entry point already covers
- **THEN** the scan fails, naming the file and line and stating the entry point to use instead

#### Scenario: Matching text in comments and strings is not reported

- **WHEN** a forbidden spelling appears inside a line comment or a string literal
- **THEN** the scan does not report it

#### Scenario: An exemption without a reason fails

- **WHEN** an exemption marker is present but carries no written reason
- **THEN** the scan fails on that marker

#### Scenario: Active exemptions are always visible

- **WHEN** the scan runs
- **THEN** its output lists every active exemption together with its reason
