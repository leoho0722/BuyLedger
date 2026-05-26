## ADDED Requirements

### Requirement: Row first line shows customer and order date

The order list row SHALL display, on its first line, the customer name followed by the localized short order date (month/day), separated by a middle dot, with the order status pill positioned immediately to the right of the date. The first line SHALL NOT display the order number suffix.

#### Scenario: First line composition

- **WHEN** the order list renders a row for an order
- **THEN** the first line displays the customer name, a middle dot, and the order's short date
- **AND** the order status pill appears to the right of the date
- **AND** the row SHALL NOT display the order number or any order number suffix

### Requirement: Row second line shows item details

The order list row SHALL display the order's item summary on its second line, listing each item name.

#### Scenario: Item summary rendering

- **WHEN** the order list renders a row for an order with one or more items
- **THEN** the second line displays the item names

### Requirement: Row third line shows product category as a tag

The order list row SHALL display the product category on its third line as a neutral-tone capsule containing the category text, preceded by a tag icon placed outside the capsule and vertically centered against the capsule. The capsule text SHALL remain on a single line. When the category is empty or contains only whitespace, the row SHALL NOT render the third line.

#### Scenario: Category present

- **WHEN** the order's category is a non-empty string after trimming whitespace
- **THEN** the third line displays a tag icon followed by a neutral-tone capsule containing the category text

#### Scenario: Category absent

- **WHEN** the order's category is empty or only whitespace after trimming
- **THEN** the row SHALL NOT render the third line, and SHALL NOT render an empty capsule or a standalone tag icon

##### Example: category rendering by value

| order.category | Third line rendered |
| -------------- | ------------------- |
| "服飾"          | tag icon + capsule "服飾" |
| ""             | not rendered |
| "   "          | not rendered |

### Requirement: Row uses symmetric vertical spacing

The order list row SHALL use uniform vertical spacing between its content lines and between the row content and the row separator, so the category tag has equal spacing above and below it and the separator is equidistant from the content of adjacent rows.

#### Scenario: Symmetric spacing around the category tag

- **WHEN** the order list renders a row whose category tag is the last content line
- **THEN** the spacing above the category tag equals the spacing below it down to the row separator

##### Example: spacing values

- **GIVEN** the row content lines are customer/date, item details, and the category tag
- **WHEN** the row renders on iOS
- **THEN** the spacing between each content line is 8 points
- **AND** the spacing from the category tag to the separator is 8 points
