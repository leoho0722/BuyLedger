## MODIFIED Requirements

### Requirement: Supported App languages

The App SHALL organize all shipped user-facing iOS and iPadOS interface text in String Catalogs (`Localizable.xcstrings` and `InfoPlist.xcstrings`) using lowercase structured English keys conforming to the format `<domain>.<component>.<elementType>.<descriptor>`. Identifiers containing multiple words SHALL use `lowerCamelCase`. The App SHALL maintain complete translations for Traditional Chinese (`zh-Hant`) and English (`en`), and SHALL use Traditional Chinese as the fallback when no valid language preference is stored.

#### Scenario: First launch uses Traditional Chinese

- **GIVEN** `settings.language` is absent or contains an unknown value
- **WHEN** the App launches
- **THEN** all shipped interface text is presented in Traditional Chinese

#### Scenario: Both supported localizations are complete

- **WHEN** the Localizable String Catalog is validated
- **THEN** every shipped key has a non-empty Traditional Chinese value and a non-empty English translation
- **THEN** translations are not empty placeholders or raw key literals

##### Example: Dashboard title has both values

- **GIVEN** the shipped static key is `common.action.cancel`
- **WHEN** its `zh-Hant` and `en` String Catalog entries are inspected
- **THEN** the values are `取消` and `Cancel`, respectively

#### Scenario: English mode has no shipped static Chinese residue

- **GIVEN** the user selected English
- **WHEN** the user navigates through reachable screens and layouts
- **THEN** every shipped navigation title, section header, control, status, filter, empty state, and relative date header is presented in English
- **THEN** user-entered content, external data, brand names, and identifiers remain unchanged

### Requirement: Locale-aware presentation follows App language

The App SHALL apply the selected language locale at the SwiftUI root and SHALL use that locale for locale-aware user-facing formatting. The App MUST NOT bypass the selected locale by reading the system preferred language or hardcoding `zh_TW` in presentation paths. Relative date headers for today and yesterday SHALL format through the active language without hardcoded Chinese strings.

#### Scenario: Locale changes with language

- **GIVEN** a screen shows localized static text, relative date headers, and a locale-aware currency or formatted value
- **WHEN** the user switches from Traditional Chinese to English
- **THEN** static text, relative date headers (Today and Yesterday), and formatted values update using the English locale

## ADDED Requirements

### Requirement: Prohibition of string concatenation in localized interfaces

User-facing sentences and compound messages SHALL be defined as atomic format strings in the String Catalog. Production code MUST NOT assemble user-facing sentences by concatenating separate localized `Text` views or strings.

#### Scenario: Compound filter summaries and notifications use atomic format strings

- **GIVEN** an interface displays a multi-part status or summary
- **WHEN** the summary is rendered
- **THEN** the string is resolved from a single catalog key containing necessary format arguments rather than string concatenation

### Requirement: Positional parameter specifiers for multi-variable strings

When a localized string template contains two or more variables, the format string in String Catalogs SHALL use explicit positional specifiers (`%1$lld`, `%2$@`).

#### Scenario: Argument order reordering across languages

- **GIVEN** a format template contains multiple arguments
- **WHEN** different target language translations require alternate grammatical ordering
- **THEN** positional markers ensure arguments map correctly without argument type mismatch

### Requirement: Plural variations handled by String Catalog substitutions

When a localized message varies based on a numeric quantity, the variations SHALL be defined using String Catalog plural substitutions. Production code MUST NOT use conditional branches (such as `if count == 1`) to switch English singular and plural text in application logic.

#### Scenario: Plural substitution adapts to count

- **GIVEN** a key configured with plural substitution in the String Catalog
- **WHEN** a quantity of 1 versus a quantity greater than 1 is provided
- **THEN** the resolved English text uses the appropriate grammatical singular or plural form

### Requirement: Verbatim preservation for user data and external content

User-generated data (customer names, product names, custom category tags, notes) and external system identifiers (currency codes, raw error codes, URLs) SHALL be presented verbatim without passing through the String Catalog translation pipeline.

#### Scenario: User entries remain untranslated

- **GIVEN** an order contains custom customer name `王小明` and category `日韓代購`
- **WHEN** displayed in English mode
- **THEN** the customer name displays verbatim as `王小明`
- **THEN** the category displays verbatim as `日韓代購`
- **THEN** accompanying system labels are presented in English

## REMOVED Requirements

### Requirement: Device acceptance

**Reason**: Building and running on a physical iPhone 15 Plus was an archived change acceptance criteria, not an ongoing capability requirement for app-localization.
**Migration**: Automated unit tests (`LocalizationCatalogTests`) and UI test suites maintain ongoing regression coverage.
