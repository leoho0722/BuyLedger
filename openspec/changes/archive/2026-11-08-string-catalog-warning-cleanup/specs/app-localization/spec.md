## ADDED Requirements

### Requirement: String Catalog extraction state matches source references

The Localizable String Catalog SHALL keep each entry's extraction state consistent with how hand-written source code references its key, so that Xcode reports no stale entries and building the App in Xcode does not rewrite the catalog. Whether a key is extracted SHALL be judged from the compiler's extracted strings of hand-written source files only, excluding the Swift symbols Xcode generates for manually managed entries. Code inside `#Preview` SHALL NOT count as a reference, because Xcode marks a key referenced only there as stale; preview code SHALL use keys that App code references, or verbatim text. A component parameter that receives a catalog key SHALL be typed `LocalizedStringResource` (or another type whose string literals the compiler extracts), so literal call sites are extracted. A key referenced only through paths the compiler does not extract SHALL be marked as manually managed; these paths include a `String` key resolved through `AppLanguage` helpers, a key held in feature state or returned from a function, and a literal compiled only under `DEBUG`. A key with no reference in hand-written source code SHALL be removed from the catalog. Source code SHALL NOT pass verbatim text, such as preview sample copy, empty field titles, or user-entered names, through APIs whose string literals or interpolations the compiler extracts as catalog keys.

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

#### Scenario: Component parameter literal is extracted

- **GIVEN** `DashboardKPITile` receives the literal `dashboard.overview.label.revenue` through a `LocalizedStringResource` parameter
- **WHEN** the catalog entry for `dashboard.overview.label.revenue` is inspected after building
- **THEN** the entry has no extraction state
- **THEN** its `zh-Hant` and `en` values remain `營業額` and `Revenue`

#### Scenario: Dynamically referenced key is managed manually

- **GIVEN** the key `orders.general.message.orderSavedTry` is returned as a `String` by the order write failure mapping
- **WHEN** its String Catalog entry is inspected
- **THEN** the entry is marked as manually managed
- **THEN** its `zh-Hant` and `en` values remain `訂單儲存失敗，請稍後再試。` and `The order could not be saved. Try again later.`

#### Scenario: Unreferenced key is removed

- **GIVEN** no hand-written source file references `common.general.label.workspace`
- **WHEN** the Localizable String Catalog is validated
- **THEN** the catalog contains no entry for `common.general.label.workspace`

#### Scenario: Campaign name equal to a key is shown verbatim

- **GIVEN** an order is assigned to a campaign named `orders.detail.label.unassigned`
- **WHEN** the order editor shows the campaign row in English
- **THEN** the row shows `orders.detail.label.unassigned` verbatim instead of its translation

### Requirement: Percentages in localized text are formatted in code

Localized values in the Localizable String Catalog SHALL NOT embed a numeric percentage. A user-facing text that contains a percentage SHALL use a format string whose placeholder receives a value formatted by a `FormatStyle` with the locale of the selected App language, showing at most one fraction digit and omitting a zero fraction. Placeholders follow the existing positional specifier requirement.

#### Scenario: Catalog values contain no literal percentage

- **WHEN** every `zh-Hant` and `en` value in the Localizable String Catalog is inspected, including variations and substitutions
- **THEN** no value contains a digit followed by a percent sign that does not start a format specifier

##### Example: Literal percentage detection

| Value | Detected as literal percentage |
| --- | --- |
| `目標毛利需低於 100% 才能計算建議售價。` | yes |
| `Enter 1.5 for 1.5%.` | yes |
| `8 %` | yes |
| `1 %1$@ = %2$@ TWD` | no |
| `%1$lld 筆 · %2$@` | no |

#### Scenario: Target margin warning formats the limit in code

- **GIVEN** the quote calculator target margin is 100 or higher
- **WHEN** the margin warning is shown
- **THEN** the percentage limit is produced by a `FormatStyle` using the selected App language locale

##### Example: Target margin warning text per language

| App language | Displayed text |
| --- | --- |
| Traditional Chinese | `目標毛利需低於 100% 才能計算建議售價。` |
| English | `The target margin must be below 100% to calculate a suggested price.` |

#### Scenario: Fee input hint formats every number in code

- **GIVEN** the order editor shows the fee section
- **WHEN** the fee input hint is shown
- **THEN** the example input, the example percentage, and the lower and upper limits are produced by `FormatStyle` values using the selected App language locale

##### Example: Fee input hint text per language

| App language | Displayed text |
| --- | --- |
| Traditional Chinese | `輸入百分比例如 1.5 表示 1.5%；超出 0% ~ 100% 範圍會自動限制。` |
| English | `Enter 1.5 for 1.5%. Values outside 0% ~ 100% are automatically limited.` |
