## ADDED Requirements

### Requirement: Design system entry points are enforced by a source scan

The test suite SHALL include a source scan that reads the app's own Swift sources and fails when a construction bypasses an established design system entry point. The scan SHALL be implemented inside the existing test target rather than by an external analysis tool, so that it runs with the normal test suite and introduces no additional toolchain.

Before comparing, the scan SHALL strip line comments and double-quoted string literals from each source line, so that prose, documentation, and localized copy containing the same wording are not reported. Generated sources SHALL be excluded from the scan.

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

## MODIFIED Requirements

### Requirement: Ineffective and unreferenced code is removed

Modifiers that have no effect, components with no call sites, and declarations that are never read SHALL be removed rather than retained. An unreferenced component in the design system carries an implicit endorsement, and a component whose preview demonstrates a discouraged construction actively propagates it. A call site that exists only inside the component's own preview SHALL NOT count as a call site for this purpose.

A declaration that is never read SHALL be removed even when it is harmless, because a reader cannot distinguish it from a live dependency without searching the whole file.

#### Scenario: Zero-width tracking modifier is removed

- **WHEN** the typography modifier is inspected
- **THEN** it applies no zero-width tracking, because doing so overrides the optical tracking the system font applies per size

#### Scenario: Unreferenced components are removed

- **WHEN** the design system is inspected for components with no call sites outside their own preview
- **THEN** the list row component and the amount field component no longer exist

#### Scenario: Environment declarations that are never read are removed

- **WHEN** a view declares an environment value and never reads it anywhere in the file
- **THEN** the declaration is removed, leaving only declarations that a reader can trace to a use
