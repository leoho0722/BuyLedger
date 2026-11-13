## MODIFIED Requirements

### Requirement: Identifier naming scheme

Fixed identifiers and the fixed prefixes of composed identifiers SHALL consist of two to four lower camel case ASCII segments separated by dots, in the form `feature.element` or `feature.screen.element`, optionally followed by one qualifier segment; the screen segment is omitted when the feature segment already names a single screen. The fixed parts of identifiers SHALL use only ASCII characters and SHALL NOT be localised; business keys appended to user-data rows keep their original form as specified for dynamic collections. The feature segment SHALL equal the lower camel case form of the name of the nested type that sits directly under the shared identifier namespace and contains the declaration, directly or through deeper nested types. The lower camel case form lowercases the first letter of the type name; when the name starts with several capital letters followed by a lowercase letter, all of those capitals except the last are lowercased, so `AISummary` becomes `aiSummary` and `Fx` becomes `fx`; when the name consists only of capital letters, all of them are lowercased, so `AI` becomes `ai`. The element segment SHALL name the semantic role rather than the visual appearance. Identifiers SHALL NOT encode transient state that a test can read from the element itself, such as enabled or selected.

#### Scenario: Static control identifier

- **WHEN** the orders list exposes its add-order control
- **THEN** its identifier is composed of the orders feature segment, the list screen segment, and an element segment naming the add action

#### Scenario: Disabled state is read from the element

- **WHEN** a UI test asserts that the save control is unavailable
- **THEN** it reads the element's enabled state rather than looking up a different identifier

#### Scenario: Feature segment follows the declaring nested type

- **GIVEN** an identifier is declared inside the nested type `AISummary` of the shared identifier namespace
- **WHEN** its value is checked against the naming scheme
- **THEN** its first segment is `aiSummary`

#### Scenario: Segment shape is checked for fixed values and fixed prefixes

- **WHEN** a fixed identifier or the fixed prefix of a composed identifier is checked against the naming scheme
- **THEN** it passes only if it has two to four dot-separated segments, each starting with a lowercase letter followed by letters or digits, and its first segment matches the declaring nested type

##### Example: shapes of fixed values and fixed prefixes

Each value below is a string literal written in the shared namespace; identifiers composed at run time by `row` keep their colon and business key and are not checked against this table.

| Fixed value or fixed prefix | Declared in | Result | Notes |
| --------------------------- | ----------- | ------ | ----- |
| fixed `fx.root` | `Fx` | passes | feature and element |
| fixed `orders.list.addButton` | `Orders` | passes | feature, screen, element |
| fixed `orders.list.paymentMethodMenu.all` | `Orders` | passes | qualifier segment |
| `option` prefix `orders.list.paymentMethodMenu.option` | `Orders` | passes | the appended key is not counted |
| fixed `orders` | `Orders` | fails | one segment |
| fixed `orders.list.a.b.c` | `Orders` | fails | five segments |
| fixed `orders.list.row:ORD-1` | `Orders` | fails | a colon is only produced by `row` at run time |
| fixed `Orders.listRoot` | `Orders` | fails | segment starts with a capital letter and differs from the declaring type |
| fixed `order.list.root` | `Orders` | fails | first segment differs from the declaring type |
| fixed `BackButton` | `Common` | fails | a platform-assigned identifier does not belong in the shared namespace |

### Requirement: Single source of identifier constants

Identifiers that the app assigns SHALL be declared exactly once in a shared constant namespace that both the app target and the UI test target compile. Identifiers that the platform assigns and the app cannot rename SHALL NOT be declared in that shared namespace; they SHALL be declared exactly once in the UI test support layer. Application code and test code SHALL reference the constants and SHALL NOT write identifier string literals inline.

#### Scenario: Both targets reference the same declaration

- **WHEN** an identifier constant's value is changed
- **THEN** the application code that sets it and the test code that queries it both observe the new value without any other edit

#### Scenario: Inline literals are rejected

- **WHEN** a screen needs a new identifier
- **THEN** the identifier is added to the shared namespace first and both sides reference it by name

#### Scenario: Platform-assigned identifiers stay on the test side

- **WHEN** a UI test needs the identifier that the platform gives the navigation back button, a sidebar toggle, or a popover dismiss region
- **THEN** it references the single declaration in the UI test support layer, and the shared namespace contains no declaration of that value

##### Example: platform-assigned identifier written inline

- **GIVEN** the UI test support file declares `static let backButton = "BackButton"`, and another UI test file writes `app.buttons["BackButton"]`
- **WHEN** the guard runs
- **THEN** it reports that file and line, naming `SystemAccessibilityID.backButton`; a comment or a longer message string that merely mentions `BackButton` is not reported

## ADDED Requirements

### Requirement: Identifier definitions are verified by a source scan

A guard SHALL scan the source files of the shared identifier namespace and SHALL derive the identifiers it checks from that scan rather than from a hand-maintained list, so that an identifier added later is checked without editing the guard. The query prefix of a composed identifier is its fixed prefix followed by the separator that its composing helper (`option`, `row`, or `indexed`) inserts before the variable segment; UI tests obtain the same value when they call the identifier function with an empty key. The guard SHALL fail and name the offending declaration when any of the following holds:

- A declaration in the namespace is not one of the accepted forms: a constant whose value is exactly one complete string literal without interpolation; a function that returns `String` and whose body is exactly one call to a composing helper, with a string literal prefix and a variable segment that contains no string literal, where, when the call is unqualified, neither the function's parameters nor the declaring nested type (including deeper nested types and its extensions) declare a name equal to the called helper; one of the three composing helpers, each declared once, returning `String`, whose body is exactly its single-line composing template; or a nested enumeration that conforms to nothing other than `String` and `Sendable` and whose cases assign no raw value. A nested type named like the shared namespace is rejected. Any other declaration, and any string literal in any other position, is rejected.
- The app target or the UI test target, outside the namespace directory, declares an enumeration, structure, class, actor, protocol, or type alias named like the shared namespace, or names the shared namespace in an extension header (up to its opening brace) or on the right-hand side of a type alias declaration; a right-hand side continues onto a following line only inside brackets or across a `.`. Other forms of indirection are not detected by this guard and are left to review.
- A source file of the app target or the UI test target, other than the UI test support file that declares the platform-assigned identifiers, contains a string literal equal to one of those identifiers; the guard derives the identifiers from that support file.
- A fixed identifier or a fixed prefix violates the naming scheme.
- A fixed identifier or a fixed prefix contains a non-ASCII character.
- Two fixed identifiers have the same value, or two fixed prefixes have the same value regardless of which composing helper they are passed to.
- A fixed identifier begins with a query prefix, or one query prefix begins with another.
- The scan finds no source file, no fixed identifier, or no composed prefix; a scanned directory outside the namespace yields no source file; or the support file of platform-assigned identifiers is missing or declares none.

Each failure condition SHALL be demonstrated by a test that runs the guard on synthetic source and observes that the guard reports it.

#### Scenario: A duplicate value is rejected

- **WHEN** two fixed identifiers, or two fixed prefixes, have the same value
- **THEN** the guard fails and names both declarations

##### Example: duplicate values

| First declaration | Second declaration | Result |
| ----------------- | ------------------ | ------ |
| fixed `orders.list.root` | fixed `orders.list.root` | fails |
| `option` prefix `orders.list.chip` | `row` prefix `orders.list.chip` | fails |
| fixed `orders.list.chip` | `option` prefix `orders.list.chip` | passes, because prefix queries use the query prefix `orders.list.chip.` |

#### Scenario: Overlapping query prefixes are rejected

- **WHEN** a fixed identifier begins with a query prefix, or one query prefix begins with another
- **THEN** the guard fails, because a prefix query issued by UI tests would also match those elements

##### Example: values checked against query prefixes

| Query prefix | Other value | Result |
| ------------ | ----------- | ------ |
| `orders.list.row:` from `row` | fixed `orders.list.row:summary` | fails |
| `orders.list.statusChip.` from `option` | fixed `orders.list.statusChip.all` | fails |
| `orderEdit.photoThumbnail.index.` from `indexed` | fixed `orderEdit.photoThumbnail.index.0` | fails |
| `orders.filter.category.` from `option` | query prefix `orders.filter.category.group.` from `option` | fails |
| `orderEdit.photoThumbnail.index.` from `indexed` | query prefix `orderEdit.photoThumbnail.index.` from `option` with prefix `orderEdit.photoThumbnail.index` | fails |
| `orders.filter.category.` from `option` | query prefix `orders.filter.categoryGroup.` from `option` | passes |
| `orders.list.row:` from `row` | fixed `orders.list.root` | passes |

#### Scenario: Declarations outside the accepted forms are rejected

- **WHEN** the namespace contains a declaration that is not one of the accepted forms
- **THEN** the guard fails and names that declaration

##### Example: declarations checked for definition form

| Declaration | Result |
| ----------- | ------ |
| `static let loading = "dashboard.loading"` | passes |
| `static let loading: String = "dashboard.loading"` | passes |
| `static let loading =` followed by `"dashboard.loading"` on the next line | passes |
| `static let loading = "dashboard.loading" // shown while loading` | passes |
| `static func row(orderID: String) -> String { BLAccessibilityID.row("orders.list.row", key: orderID) }` | passes |
| the same function with the call split so that each argument is on its own line | passes |
| `static let loading = "dashboard.\("loading")"` | fails |
| `static let loading = prefix + ".loading"` | fails |
| `static var legacyRoot: String { listRoot }` | fails |
| `static func chip(_ key: String) -> String { statusChip(key) }` | fails |
| `static func detailRow(_ id: String) -> String { detailRoot + id }` | fails |
| `static func chip(_ key: String) -> String { option(chipPrefix, key: key) }` | fails |
| `case shipping = "shipping"` inside a nested enumeration | fails |
| `enum Kind: String, CaseIterable` holding only plain cases | fails |
| `static func row(orderID: String) async throws -> String? { BLAccessibilityID.row("orders.list.row", key: orderID) }` | fails |
| inside `Orders`, `static func chip(_ key: String) -> String { option("orders.list.chip", key: key) }` while `Orders` also declares a function named `option` | fails |
| a composing helper whose body adds a second literal next to its template | fails |

#### Scenario: A declaration outside the namespace directory is rejected

- **WHEN** a source file of the app target or the UI test target outside the namespace directory declares a type named `BLAccessibilityID`, or names it in an extension header or on the right-hand side of a type alias declaration
- **THEN** the guard fails and names that file, because identifiers added there would not be scanned

#### Scenario: A non-ASCII value is rejected

- **WHEN** a fixed identifier contains a non-ASCII character
- **THEN** the guard fails and names that declaration

##### Example: non-ASCII value

- **GIVEN** the nested type `Orders` declares `static let cafeRow = "orders.list.café"`
- **WHEN** the guard runs
- **THEN** it reports an ASCII violation for `Orders.cafeRow`

#### Scenario: An empty scan does not pass

- **WHEN** the scan finds no source file, or finds no fixed identifier, or finds no composed prefix
- **THEN** the guard fails instead of reporting that no violation was found

#### Scenario: Each rule is shown to fail

- **WHEN** the guard runs on synthetic source that breaks one failure condition
- **THEN** it reports that condition and names the declaration that breaks it
