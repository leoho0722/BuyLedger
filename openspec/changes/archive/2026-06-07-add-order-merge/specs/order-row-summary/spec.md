## MODIFIED Requirements

### Requirement: Row third line shows product category as a tag

The order list row SHALL display the order's categories on its third line as a neutral-tone capsule containing the category names joined by "、", preceded by a tag icon placed outside the capsule and vertically centered against the capsule. The capsule text SHALL remain on a single line. When the category list is empty, or every element trims to whitespace, the row SHALL NOT render the third line.

#### Scenario: Category present

- **WHEN** the order's category list contains at least one non-whitespace name
- **THEN** the third line displays a tag icon followed by a neutral-tone capsule containing the category names joined by "、"

#### Scenario: Category absent

- **WHEN** the order's category list is empty or every element is whitespace after trimming
- **THEN** the row SHALL NOT render the third line, and SHALL NOT render an empty capsule or a standalone tag icon

##### Example: category rendering by value

| order.categories     | Third line rendered          |
| -------------------- | ---------------------------- |
| ["服飾"]              | tag icon + capsule "服飾"     |
| ["服飾", "美妝"]      | tag icon + capsule "服飾、美妝" |
| []                   | not rendered                 |
| ["   "]              | not rendered                 |
