## ADDED Requirements

### Requirement: Localized text references use resources and a single resolution entry

Production code SHALL carry String Catalog keys as `LocalizedStringResource` values, not as `String`, including in feature state, shared values, enumeration payloads, enumeration properties, function return values, and component parameters; a `LocalizedStringKey` SHALL be built only from a string literal, never from a `String` value. A localized text with arguments SHALL be built from an explicit structured key and a default value whose interpolations supply the arguments in the order of the catalog's positional specifiers. Conversion of a `LocalizedStringResource` to `String` SHALL go through `AppLanguage`'s single resolution entry, which applies the selected App language; no other production code SHALL call `String(localized:)` or look up localized strings in a bundle. A shared component that displays both catalog keys and user data SHALL accept them through separate inputs, and user data SHALL be displayed verbatim even when it equals a catalog key.

#### Scenario: Resolution follows the App language rather than the system language

- **GIVEN** the system language is Traditional Chinese and the selected App language is English
- **WHEN** `AppLanguage.english` resolves the resource for `common.action.cancel`
- **THEN** the result is `Cancel`

#### Scenario: Arguments keep plural and positional behavior

- **WHEN** the selected-count resource for `orders.batch.message.selectedCount` is resolved with counts 1 and 3
- **THEN** the results match the catalog's plural variations for each language

##### Example: Selected count text

| App language | Count | Displayed text |
| --- | --- | --- |
| Traditional Chinese | 3 | `已選 3 筆` |
| English | 1 | `1 Selected` |
| English | 3 | `3 Selected` |

#### Scenario: Legacy string-key APIs are absent

- **WHEN** the production source is scanned
- **THEN** `AppLanguage.format`, `localizedString(forKey:`, `extractKeyAndArgs`, and `String.LocalizationValue` do not appear
- **THEN** `String(localized:` appears only in `AppLanguage.swift`
- **THEN** every `LocalizedStringKey(` is followed by a string literal

#### Scenario: User data equal to a key stays verbatim in a shared component

- **GIVEN** an order whose item category is named `orders.list.label.merged`
- **WHEN** the order row shows the category tag in English
- **THEN** the tag shows `orders.list.label.merged`, not the translated status `Merged`

#### Scenario: Open screens update when the App language changes

- **GIVEN** the campaign list shows a load failure message in Traditional Chinese
- **WHEN** the user switches the App language to English without relaunching
- **THEN** the message and the root navigation title are shown in English

## MODIFIED Requirements

### Requirement: String Catalog extraction state matches source references

The Localizable String Catalog SHALL keep each entry's extraction state consistent with how hand-written source code references its key, so that Xcode reports no stale entries and building the App in Xcode does not rewrite the catalog. Whether a key is extracted SHALL be judged from the compiler's extracted strings of hand-written source files only, excluding the Swift symbols Xcode generates for manually managed entries. Code inside `#Preview` SHALL NOT count as a reference, because Xcode marks a key referenced only there as stale; preview code SHALL use keys that App code references, or verbatim text. A component parameter that receives a catalog key SHALL be typed `LocalizedStringResource` (or another type whose string literals the compiler extracts), so literal call sites are extracted. An entry SHALL be marked as manually managed only when its key is not extracted from hand-written source code in at least one of the Debug and Release configurations, such as a literal compiled only under `DEBUG`, and each remaining manually managed entry SHALL have its reason recorded. A key with no reference in hand-written source code SHALL be removed from the catalog. Source code SHALL NOT pass verbatim text, such as preview sample copy, empty field titles, or user-entered names, through APIs whose string literals or interpolations the compiler extracts as catalog keys.

#### Scenario: Catalog has no stale entries

- **WHEN** the Localizable String Catalog is validated
- **THEN** no entry has the extraction state `stale`

#### Scenario: Building in Xcode leaves the catalog unchanged

- **GIVEN** the SHA-256 of `Localizable.xcstrings` is recorded before the build
- **WHEN** the `BuyLedger` scheme is built in the Xcode IDE
- **THEN** the SHA-256 of `Localizable.xcstrings` is unchanged after the build
- **THEN** Xcode reports zero warnings for `Localizable.xcstrings`

#### Scenario: Extracted keys and catalog entries match in both configurations

- **GIVEN** the compiler's extracted strings of the Debug and Release builds, excluding generated symbol sources
- **WHEN** they are compared with the catalog
- **THEN** every extracted key exists in the catalog
- **THEN** every catalog key without an extraction state is extracted in both configurations
- **THEN** no manually managed entry is extracted in both configurations

#### Scenario: Component parameter literal is extracted

- **GIVEN** `DashboardKPITile` receives the literal `dashboard.overview.label.revenue` through a `LocalizedStringResource` parameter
- **WHEN** the catalog entry for `dashboard.overview.label.revenue` is inspected after building
- **THEN** the entry has no extraction state
- **THEN** its `zh-Hant` and `en` values remain `營業額` and `Revenue`

#### Scenario: Resource returned from a function is extracted

- **GIVEN** the order write failure mapping returns `orders.general.message.orderSavedTry` as a `LocalizedStringResource` literal
- **WHEN** its String Catalog entry is inspected after building
- **THEN** the entry has no extraction state
- **THEN** its `zh-Hant` and `en` values remain `訂單儲存失敗，請稍後再試。` and `The order could not be saved. Try again later.`

#### Scenario: Debug-only key stays manual

- **GIVEN** `orders.general.label.model` is referenced only inside `#if DEBUG`
- **WHEN** the Release build's extracted strings are inspected
- **THEN** the key is absent from the Release build and its catalog entry stays manually managed
- **THEN** its `zh-Hant` and `en` values remain `模型` and `Model`

#### Scenario: Unreferenced key is removed

- **GIVEN** no hand-written source file references `common.general.label.workspace`
- **WHEN** the Localizable String Catalog is validated
- **THEN** the catalog contains no entry for `common.general.label.workspace`

#### Scenario: Campaign name equal to a key is shown verbatim

- **GIVEN** an order is assigned to a campaign named `orders.detail.label.unassigned`
- **WHEN** the order editor shows the campaign row in English
- **THEN** the row shows `orders.detail.label.unassigned` verbatim instead of its translation
