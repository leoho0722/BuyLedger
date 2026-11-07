## ADDED Requirements

### Requirement: Text fields place the caret at the end when focus arrives

A free-text entry field (single-line, multi-line, or search) SHALL place the caret after the last character of its existing text at the moment it gains focus, regardless of where the user tapped. The field SHALL NOT select or clear its existing text when focus arrives. The caret SHALL be placed only on the transition from unfocused to focused; while the field stays focused, later taps SHALL be left to the system. An empty field SHALL behave as the system default. Managing the caret SHALL NOT interrupt keyboard text composition.

#### Scenario: Typing appends to an existing name

- **GIVEN** an order edit form whose customer name field shows 林書宇
- **WHEN** the user taps the left part of the customer name field and types 小姐
- **THEN** the field shows 林書宇小姐

#### Scenario: A later tap leaves caret placement to the system

- **GIVEN** a focused customer name field showing 林書宇 whose caret was placed at the end when focus arrived
- **WHEN** the user taps the left part of the same field and types 小
- **THEN** the field text contains 林書宇 and the typed 小 is not placed after the last character

#### Scenario: Multi-line notes continue at the end

- **GIVEN** an order notes field containing two lines of text
- **WHEN** the user taps the first line and types additional text
- **THEN** the additional text appears after the last character of the second line

#### Scenario: Search query continues at the end

- **GIVEN** a category search field containing 保養
- **WHEN** the user taps the left part of the search field and types 品
- **THEN** the search field shows 保養品

#### Scenario: List search query continues at the end

- **GIVEN** an order list search field containing 林 whose keyboard has been dismissed
- **WHEN** the user taps the left part of the search field and types 書
- **THEN** the search field shows 林書

#### Scenario: Phonetic composition is not interrupted

- **GIVEN** a focused customer name field showing 林書宇 with a Zhuyin keyboard
- **WHEN** the user composes a syllable with the keyboard keys and picks the candidate 小
- **THEN** the field shows 林書宇小

### Requirement: Numeric fields clear their text when focus arrives

A numeric entry field (amount, percentage, exchange amount, quote input, unit price, or monthly goal) SHALL show empty text at the moment that individual field gains focus, whatever its value and including when focus moves directly from another field on the same screen, so that typed digits replace the existing value instead of being inserted beside it. Clearing SHALL NOT write to the bound value. The field SHALL clear only on its transition from unfocused to focused; while the field stays focused, later taps SHALL NOT clear the typed text again. When editing ends and no parsable text was typed, the field SHALL show the bound value in the field's format again. Clearing SHALL NOT change the field's number format, fraction digits, keyboard type, alignment, or validation.

#### Scenario: Typing replaces a displayed zero

- **GIVEN** a numeric field whose bound value is 0
- **WHEN** the user taps the left part of the field, types the text, and ends editing
- **THEN** the shown text and the bound value match the example table

##### Example: Zero fields

| Field | Shown before focus | Typed text | Shown while focused | Shown after editing ends | Bound value |
| ----- | ------------------ | ---------- | ------------------- | ------------------------ | ----------- |
| Charged amount (whole numbers) | 0 | 1000 | 1000 | 1000 | 1000 |
| Order card fee percentage (two fraction digits) | 0.00 | 5 | 5 | 5.00 | 5 percent |
| Quote card fee percentage (one fraction digit) | 0.0 | 5 | 5 | 5.0 | 5 percent |

#### Scenario: Typing replaces an existing value

- **GIVEN** a quote whose principal field shows 2500 and whose keyboard has been dismissed
- **WHEN** the user taps the left part of the principal field and types 1000
- **THEN** the principal field shows 1000 and the suggested price shows $30

#### Scenario: Moving focus between quote fields also clears

- **GIVEN** a quote whose focused principal field shows 2500 and whose local shipping field shows 30
- **WHEN** the user taps the local shipping field without dismissing the keyboard and types 5
- **THEN** the local shipping field shows 5 and the principal field still shows 2500

#### Scenario: Moving focus from another field also clears

- **GIVEN** an order item whose name field is focused and whose unit price field shows 120
- **WHEN** the user taps the unit price field and types 95
- **THEN** the unit price field shows 95

#### Scenario: A later tap does not clear typed text

- **GIVEN** a focused percentage field in which the user has typed 12
- **WHEN** the user taps the left part of the same field and types 3
- **THEN** the field text contains the digits 12 and the typed 3

#### Scenario: An untouched field returns to its display

- **GIVEN** a numeric field showing the text in the example table
- **WHEN** the user focuses the field and dismisses the keyboard without typing
- **THEN** the field shows no text while focused and shows the same text after the keyboard is dismissed

##### Example: Untouched fields

| Field | Shown before focus | Shown after the keyboard is dismissed |
| ----- | ------------------ | ------------------------------------- |
| Order card fee percentage (two fraction digits) | 0.00 | 0.00 |
| Quote principal (up to two fraction digits) | 2500 | 2500 |

### Requirement: Numeric entry keeps its parsing and write-back behavior

Changing how a numeric field manages focus SHALL NOT change which text it accepts, how it rounds or limits fraction digits, or when the parsed value is written back to the feature state. Text that the field's number format cannot parse SHALL leave the bound value unchanged, except that empty text SHALL restore the value bound when focus arrived if this focus has already written a value. Gaining or losing focus without typing SHALL NOT write to the bound value. When editing ends, the field SHALL show the bound value in the field's format, and a bound value changed from outside the field SHALL replace the field's text.

#### Scenario: Fraction digits follow the field's format

- **GIVEN** a numeric field with its existing number format
- **WHEN** the field holds the given text and editing ends
- **THEN** the bound value and the shown text match the example table

##### Example: Parsing outcomes stay the same

| Field | Starting value | Text when editing ends | Bound value after editing ends | Field shows after editing ends | Notes |
| ----- | -------------- | ---------------------- | ------------------------------ | ------------------------------ | ----- |
| Charged amount (whole numbers) | 0 | 1000 | 1000 | 1000 | the shown 0 was cleared on focus |
| Quote principal (up to two fraction digits) | 0 | 22.8 | 22.8 | 22.8 | decimal entry allowed |
| Monthly goal (whole numbers) | 80000 | abc | 80000 | 80000 | unparsable text keeps the previous value |
| Monthly goal (whole numbers) | 80000 | empty text | 80000 | 80000 | left without typing |
| Charged amount (whole numbers) | 0 | empty text | 0 | 0 | left without typing |
| Card fee percentage (two fraction digits) | 0 | 12.345 | 12.35 | 12.35 | midpoint rounds away from zero |

#### Scenario: Emptying typed text restores the value from focus

- **GIVEN** an order edit form with no unsaved change whose charged amount field shows 2500
- **WHEN** the user focuses the field, types 1, deletes it, dismisses the keyboard, and taps cancel
- **THEN** the field shows 2500 after the keyboard is dismissed and the form closes without a discard confirmation

#### Scenario: Typing updates dependent results before editing ends

- **GIVEN** a quote whose principal field shows the default value 0 and is focused with the keyboard showing
- **WHEN** the user types 1000 without dismissing the keyboard
- **THEN** the suggested price shows $30 while the keyboard is still showing

#### Scenario: Focusing without typing keeps the form unmodified

- **GIVEN** an order edit form with no unsaved change
- **WHEN** the user focuses the charged amount field, dismisses the keyboard without typing, and taps cancel
- **THEN** the form closes without a discard confirmation

#### Scenario: An outside value change replaces the field text

- **GIVEN** an exchange amount field showing 150000
- **WHEN** the user taps a preset amount button
- **THEN** the field shows the preset amount
