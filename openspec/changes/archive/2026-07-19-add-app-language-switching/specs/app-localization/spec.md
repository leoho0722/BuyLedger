## ADDED Requirements

### Requirement: Supported App languages

The App SHALL localize all shipped static user-facing iOS and iPadOS interface text through a String Catalog for Traditional Chinese and English. The App SHALL use Traditional Chinese when no valid language preference has been stored.

#### Scenario: First launch uses Traditional Chinese

- **GIVEN** settings.language is absent or contains an unknown value
- **WHEN** the App launches
- **THEN** all shipped static interface text is presented in Traditional Chinese

#### Scenario: Both supported localizations are complete

- **WHEN** the Localizable String Catalog is validated
- **THEN** every shipped static user-facing key has a non-empty Traditional Chinese value and a non-empty English translation

##### Example: Dashboard title has both values

- **GIVEN** the shipped static key is `儀表板`
- **WHEN** its `zh-Hant` and `en` String Catalog entries are inspected
- **THEN** the values are `儀表板` and `Dashboard`, respectively

#### Scenario: English mode has no shipped static Chinese residue

- **GIVEN** the user selected English
- **WHEN** the user navigates through every reachable iPhone screen and the iPad sidebar layout
- **THEN** every shipped static navigation title, section, control, status, filter, empty state, error state, and locale-aware date or formatted value is presented in English
- **THEN** user-entered content, external data, brand names, and identifiers remain unchanged

##### Example: Dashboard and Orders use English consistently

- **GIVEN** English is selected and the current date is July 18, 2026
- **WHEN** the user visits Dashboard and Orders
- **THEN** `總覽`, `訂單`, and `全部` are displayed as `Overview`, `Orders`, and `All`
- **THEN** the date is formatted with the English locale rather than displayed as `7月18日星期六`

#### Scenario: Reported order-flow controls use English consistently

- **GIVEN** English is selected and the user opens More, its currency and AI-model selectors, and an order with editable data
- **WHEN** the user opens source-currency, default-currency, AI-model, order-source, category, and payment-method pickers, then opens order creation, editing, and detail screens
- **THEN** `更多`, `選擇來源幣別`, `選擇預設幣別`, `選擇 AI 模型`, `收款進度`, `到貨進度`, `待收款`, `已收款`, `到貨`, `收款`, `選擇來源`, `選擇類別`, `選擇訂單來源`, `選擇商品類別`, and `選擇付款方式` are presented in English
- **THEN** the add-source and add-category placeholders and helper text are presented in English
- **THEN** user-entered source, category, payment-method, product, and customer values remain unchanged

### Requirement: Root navigation titles follow the selected App language

The App SHALL present the Dashboard, Orders, Campaigns, Insights, and More root navigation titles using the selected App language. The title presentation path SHALL resolve the String Catalog through the selected App language's localization bundle so it remains correct after an in-app language change.

#### Scenario: Root titles update in both directions

- **GIVEN** the user is on each root tab in turn
- **WHEN** the user selects English
- **THEN** the navigation titles are `Overview`, `Orders`, `Campaigns`, `Insights`, and `More`
- **WHEN** the user selects Traditional Chinese
- **THEN** the navigation titles are `總覽`, `訂單`, `開團`, `分析`, and `更多`

### Requirement: Language selection in Settings

The Settings screen SHALL provide an App language Picker with Traditional Chinese and English options. Its interaction and visual structure SHALL match the existing appearance mode Picker.

#### Scenario: User selects English

- **GIVEN** the App is displaying Traditional Chinese
- **WHEN** the user opens More, navigates to Settings, and selects English
- **THEN** the current interface updates to English without restarting or resetting the navigation stack

#### Scenario: User selects Traditional Chinese

- **GIVEN** the App is displaying English
- **WHEN** the user selects Traditional Chinese in the App language Picker
- **THEN** the current interface updates to Traditional Chinese without restarting or resetting the navigation stack

### Requirement: Language preference persistence

The App SHALL persist the selected App language in SettingsStorage and SHALL restore it during App startup before the user visits Settings.

#### Scenario: Relaunch restores English

- **GIVEN** the user selected English and terminated the App
- **WHEN** the App is launched again
- **THEN** the root interface restores English without requiring navigation to Settings

#### Scenario: Invalid persisted preference falls back safely

- **GIVEN** SettingsStorage contains an unsupported language raw value
- **WHEN** settings are loaded
- **THEN** the language state becomes Traditional Chinese and all other stored settings retain their stored values

### Requirement: Locale-aware presentation follows App language

The App SHALL apply the selected language locale at the SwiftUI root and SHALL use that locale for locale-aware user-facing formatting. The App MUST NOT bypass the selected locale by reading the system preferred language in a presentation path.

#### Scenario: Locale changes with language

- **GIVEN** a screen shows localized static text and a locale-aware currency name or formatted value
- **WHEN** the user switches from Traditional Chinese to English
- **THEN** both the static text and locale-aware presentation update using the English locale

### Requirement: Device acceptance

The iOS App SHALL build, install, and launch on the user's connected iPhone 15 Plus through XcodeBuildMCP CLI.

#### Scenario: Build and run on iPhone 15 Plus

- **WHEN** the implementation is accepted
- **THEN** XcodeBuildMCP CLI reports a successful device build-and-run for the connected iPhone 15 Plus and the App is visible running on that device
