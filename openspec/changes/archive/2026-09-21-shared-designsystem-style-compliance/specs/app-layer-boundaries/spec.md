## ADDED Requirements

### Requirement: The design system does not reference domain types or the application architecture framework

The design system layer SHALL NOT reference any type declared in the app's domain layer, and SHALL NOT import the application architecture framework that features are built with.

A reusable component that needs a domain-shaped value SHALL receive that value as primitives or as a type the design system itself declares, and the calling feature SHALL perform the conversion. A component whose entire content is a mapping from one domain type to a visual value SHALL be moved to the feature that owns that domain type, rather than kept in the design system behind an indirection.

A design system component that needs a time-based effect SHALL obtain it from the platform's structured concurrency primitives rather than from the architecture framework's injected clock, so that the design system carries no dependency on the feature layer's dependency container.

This constraint is narrower than the layer rule that forbids Core and Shared from referencing feature types: it applies to the design system sub-layer only, and the rest of the shared layer remains free to depend on the domain layer.

An automated scan SHALL enforce both halves of this constraint, and the scan SHALL be shown to fail when a violation is introduced.

The scan's inventory of domain type names SHALL include types whose declaration exists only in generated sources. A scan that inherits an exclusion of generated files silently omits those names and passes regardless of what the design system references, which is indistinguishable from a passing scan by its result alone.

#### Scenario: A design system component does not name a domain type

- **WHEN** the design system source files are scanned for the top-level declaration names of the domain layer
- **THEN** no design system file references any of them outside comments and string literals

#### Scenario: A component receiving domain-shaped data takes primitives

- **GIVEN** a reusable sheet that reports a newly created payment method to its caller
- **WHEN** the sheet reports the result
- **THEN** it passes the name and each classification flag as separate primitive values, and the calling feature assembles the domain type

#### Scenario: A domain-to-visual mapping lives with its domain type

- **GIVEN** a helper whose only content maps an order status to a colour
- **WHEN** the design system is reviewed for domain references
- **THEN** the helper is declared alongside the order status presentation extensions in the orders feature, and no equivalent declaration remains in the design system

#### Scenario: The design system does not import the architecture framework

- **WHEN** the design system source files are scanned for the architecture framework import
- **THEN** no design system file imports it

#### Scenario: The scan detects an introduced violation

- **GIVEN** the boundary scan passes on the current source
- **WHEN** a design system file is temporarily changed to reference a domain type declared only in a generated source, and separately to import the architecture framework
- **THEN** the corresponding scan reports a failure in each case, confirming the guard is effective rather than vacuously green

#### Scenario: Generated declarations are part of the scanned inventory

- **WHEN** the scan builds its list of domain type names
- **THEN** the list contains the names declared only in generated sources, so that referencing one of them from the design system is detected rather than ignored
