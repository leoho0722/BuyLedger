## ADDED Requirements

### Requirement: Value shapes stored in persisted records are locked by a test

Value types that a SwiftData record stores as embedded values, and enums or codes whose raw strings a record stores, SHALL have their stored shape locked by a unit test that compares against literal values. When retained schema versions reference such a type directly instead of freezing a copy, a change to its keys or stored properties changes how every retained version reads existing rows at once, and opening a store that the same build created does not detect it.

The locked shape SHALL cover the encoded keys and the stored property list of each embedded struct, the raw value of every case of each persisted enum, and the code strings of the built-in currency constants. Adding an enum case SHALL only require updating the literal values. Removing or renaming a key, a stored property, or a raw value SHALL be made deliberately, together with the schema migration it requires. A value type that becomes embedded in a persisted record SHALL be added to the test in the same change.

#### Scenario: An embedded item keeps its encoded keys

- **WHEN** an order item is encoded, and an encoded item without an identifier is decoded
- **THEN** the encoded output contains exactly the name, quantity, and unit price keys and no identifier key, and the decoded item has the same name, quantity, and unit price

##### Example: order item encoding

- **GIVEN** an order item with a fixed identifier, named "Tote", with quantity 2 and unit price 1200
- **WHEN** it is encoded with sorted keys
- **THEN** the output is {"name":"Tote","quantity":2,"unitPrice":1200}

#### Scenario: An embedded customer keeps its keys and stored properties

- **WHEN** an order customer is encoded and its stored properties are listed in declaration order
- **THEN** the encoded keys are initials, name, and tier, and the stored properties are name, initials, and tier with the types text, text, and customer tier

#### Scenario: Persisted raw values stay fixed

- **WHEN** the raw values of every case of the order status, customer tier, campaign status, and payment receipt status are listed, together with the codes of the built-in currency constants
- **THEN** each set equals its literal expectation, and a case added to an enum that cannot enumerate its cases is caught because the test maps every case exhaustively

#### Scenario: An accidental shape change fails the test

- **GIVEN** the shape test passes on the current source
- **WHEN** the order item's custom encoding is temporarily replaced by the synthesized encoding
- **THEN** the shape test fails
