# app-settings Specification

## Purpose

Defines how the app's persisted preferences (interface language, default order currency, monthly net profit goal, AI summary toggle and model) are read, defaulted, made available at launch, and written. App lock behavior is specified separately in app-lock and is not covered here.

## Requirements

### Requirement: A setting that was never written reads as its documented default

When a preference has never been written, reading it SHALL yield the default documented for that preference, not the storage layer's zero value. A value the user has written SHALL be read back as written, including a value that equals the storage layer's zero value.

#### Scenario: A fresh install reads the documented monthly goal

- **WHEN** the monthly net profit goal has never been written and the settings are read
- **THEN** the goal is the documented default, so the dashboard shows its goal progress

##### Example: monthly goal reads

| Stored monthly goal | Read value | Notes |
| ------------------- | ---------- | ----- |
| never written | 80,000 | documented default |
| 0 | 0 | user chose no goal |
| 120,000 | 120,000 | user value |

#### Scenario: A deliberately cleared goal stays cleared

- **WHEN** the user has set the monthly net profit goal to zero and the settings are read
- **THEN** the goal is zero, and the dashboard shows no goal progress


<!-- @trace
source: small-features-style-compliance
updated: 2026-09-24
code:
  - apps/ios/BuyLedgerTests/BLFormattersTests.swift
  - apps/ios/BuyLedger/Features/Quote/Components/QuoteInputsCard.swift
  - apps/ios/BuyLedger/Features/FX/Components/FxStatusBanner.swift
  - apps/ios/BuyLedger/Features/Orders/OrderDateSection.swift
  - apps/ios/BuyLedger/Features/Quote/QuoteView.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/fxViewBaseline.1.png
  - apps/ios/BuyLedger/Features/FX/Components/FxRatesList.swift
  - apps/ios/BuyLedger/Features/AISummary/OllamaDTO.swift
  - apps/ios/BuyLedgerTests/ActionGroupingScanTests+Scanner.swift
  - apps/ios/BuyLedgerTests/ActionGroupingScanTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLFormatters.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsSnapshot.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsStore.swift
  - apps/ios/BuyLedgerTests/SnapshotTests.swift
  - apps/ios/BuyLedger/Core/Networking/OllamaChatRequest.swift
  - apps/ios/BuyLedgerTests/SettingsFeatureTests.swift
  - apps/ios/BuyLedger/Features/Customers/CustomersView.swift
  - apps/ios/BuyLedger/App/BuyLedgerApp.swift
  - apps/ios/BuyLedger/Features/Quote/QuoteRateFeature.swift
  - apps/ios/BuyLedgerTests/FxFeatureTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/fxViewRateFailureBaseline.1.png
  - apps/ios/BuyLedger/Shared/Extensions/Bundle+Extensions.swift
  - apps/ios/BuyLedger/Features/Customers/CustomerRankBadgeStyle.swift
  - apps/ios/BuyLedgerTests/ActionGroupingScanTests+Scenarios.swift
  - apps/ios/BuyLedgerTests/AISummaryFeatureTests.swift
  - apps/ios/BuyLedger/Core/Networking/OllamaClient.swift
  - apps/ios/BuyLedger/Features/Customers/Components/CustomerTopCard.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsFeature.swift
  - apps/ios/BuyLedgerTests/LedgerOrder+Fixture.swift
  - apps/ios/BuyLedger/Features/Customers/CustomerRow.swift
  - apps/ios/CLAUDE.md
  - apps/ios/BuyLedger/Features/Settings/AISummaryModelCatalog.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsView.swift
  - apps/ios/BuyLedger/Features/FX/FxView.swift
  - apps/ios/BuyLedger/Features/Customers/CustomersFeature.swift
  - apps/ios/BuyLedgerTests/SettingsStoreTests.swift
  - apps/ios/BuyLedger/Features/FX/FxFormatters.swift
  - apps/ios/BuyLedger/Features/Quote/Components/QuoteBreakdownCard.swift
  - apps/ios/BuyLedger/Features/AISummary/AISummaryView.swift
  - apps/ios/BuyLedger/Features/AISummary/AISummaryFeature.swift
  - apps/ios/BuyLedgerTests/FxRateSnapshotTests.swift
  - apps/ios/BuyLedger/Features/App/RootFeature.swift
  - apps/ios/BuyLedger/Features/More/MoreView.swift
  - apps/ios/BuyLedgerTests/CustomersFeatureTests.swift
  - apps/ios/BuyLedgerTests/OllamaClientTests.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests.swift
  - apps/ios/BuyLedgerTests/AppLanguageTests.swift
  - apps/ios/BuyLedger/Features/Quote/Components/QuoteStatusBanner.swift
  - apps/ios/README.md
  - apps/ios/BuyLedgerTests/CustomerRowTests.swift
  - apps/ios/BuyLedger/Core/Networking/OllamaChatResponse.swift
  - apps/ios/BuyLedger/Features/Quote/QuoteFeature.swift
  - apps/ios/BuyLedger/Core/Domain/FxRateSnapshot.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersFeature+StateQuery.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFormatters.swift
  - apps/ios/BuyLedger/Features/FX/FxFeature.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsStorage.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestDependencyOverrides.swift
  - apps/ios/BuyLedger/Features/Customers/Components/CustomerListRow.swift
  - apps/ios/BuyLedger.xcodeproj/project.pbxproj
  - apps/ios/BuyLedger/Features/Orders/OrdersFeature.swift
  - apps/ios/BuyLedgerTests/QuoteFeatureTests.swift
  - apps/ios/BuyLedger/Features/AISummary/OllamaClient.swift
  - apps/ios/BuyLedgerTests/OrdersFeatureTests.swift
-->

---
### Requirement: Stored preference keys survive code renames

The key under which each preference is stored SHALL remain unchanged when the code identifiers that hold the preference are renamed. A value written by an earlier version SHALL be read by a later version without migration.

#### Scenario: Values written under the existing keys are read after a rename

- **WHEN** every preference is written under the keys used before the identifier renames and the settings are read by the renamed code
- **THEN** every preference reads back the written value

##### Example: the stored keys that stay fixed

| Preference | Stored key |
| ---------- | ---------- |
| interface language | `settings.language` |
| default order currency | `settings.defaultCurrency` |
| monthly net profit goal | `settings.monthlyProfitGoalTwd` |
| AI summary toggle | `settings.useAiSummary` |
| AI summary model | `settings.aiSummaryModel` |
| app lock toggle | `settings.isBiometricUnlockEnabled` |


<!-- @trace
source: small-features-style-compliance
updated: 2026-09-24
code:
  - apps/ios/BuyLedgerTests/BLFormattersTests.swift
  - apps/ios/BuyLedger/Features/Quote/Components/QuoteInputsCard.swift
  - apps/ios/BuyLedger/Features/FX/Components/FxStatusBanner.swift
  - apps/ios/BuyLedger/Features/Orders/OrderDateSection.swift
  - apps/ios/BuyLedger/Features/Quote/QuoteView.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/fxViewBaseline.1.png
  - apps/ios/BuyLedger/Features/FX/Components/FxRatesList.swift
  - apps/ios/BuyLedger/Features/AISummary/OllamaDTO.swift
  - apps/ios/BuyLedgerTests/ActionGroupingScanTests+Scanner.swift
  - apps/ios/BuyLedgerTests/ActionGroupingScanTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLFormatters.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsSnapshot.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsStore.swift
  - apps/ios/BuyLedgerTests/SnapshotTests.swift
  - apps/ios/BuyLedger/Core/Networking/OllamaChatRequest.swift
  - apps/ios/BuyLedgerTests/SettingsFeatureTests.swift
  - apps/ios/BuyLedger/Features/Customers/CustomersView.swift
  - apps/ios/BuyLedger/App/BuyLedgerApp.swift
  - apps/ios/BuyLedger/Features/Quote/QuoteRateFeature.swift
  - apps/ios/BuyLedgerTests/FxFeatureTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/fxViewRateFailureBaseline.1.png
  - apps/ios/BuyLedger/Shared/Extensions/Bundle+Extensions.swift
  - apps/ios/BuyLedger/Features/Customers/CustomerRankBadgeStyle.swift
  - apps/ios/BuyLedgerTests/ActionGroupingScanTests+Scenarios.swift
  - apps/ios/BuyLedgerTests/AISummaryFeatureTests.swift
  - apps/ios/BuyLedger/Core/Networking/OllamaClient.swift
  - apps/ios/BuyLedger/Features/Customers/Components/CustomerTopCard.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsFeature.swift
  - apps/ios/BuyLedgerTests/LedgerOrder+Fixture.swift
  - apps/ios/BuyLedger/Features/Customers/CustomerRow.swift
  - apps/ios/CLAUDE.md
  - apps/ios/BuyLedger/Features/Settings/AISummaryModelCatalog.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsView.swift
  - apps/ios/BuyLedger/Features/FX/FxView.swift
  - apps/ios/BuyLedger/Features/Customers/CustomersFeature.swift
  - apps/ios/BuyLedgerTests/SettingsStoreTests.swift
  - apps/ios/BuyLedger/Features/FX/FxFormatters.swift
  - apps/ios/BuyLedger/Features/Quote/Components/QuoteBreakdownCard.swift
  - apps/ios/BuyLedger/Features/AISummary/AISummaryView.swift
  - apps/ios/BuyLedger/Features/AISummary/AISummaryFeature.swift
  - apps/ios/BuyLedgerTests/FxRateSnapshotTests.swift
  - apps/ios/BuyLedger/Features/App/RootFeature.swift
  - apps/ios/BuyLedger/Features/More/MoreView.swift
  - apps/ios/BuyLedgerTests/CustomersFeatureTests.swift
  - apps/ios/BuyLedgerTests/OllamaClientTests.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests.swift
  - apps/ios/BuyLedgerTests/AppLanguageTests.swift
  - apps/ios/BuyLedger/Features/Quote/Components/QuoteStatusBanner.swift
  - apps/ios/README.md
  - apps/ios/BuyLedgerTests/CustomerRowTests.swift
  - apps/ios/BuyLedger/Core/Networking/OllamaChatResponse.swift
  - apps/ios/BuyLedger/Features/Quote/QuoteFeature.swift
  - apps/ios/BuyLedger/Core/Domain/FxRateSnapshot.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersFeature+StateQuery.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFormatters.swift
  - apps/ios/BuyLedger/Features/FX/FxFeature.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsStorage.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestDependencyOverrides.swift
  - apps/ios/BuyLedger/Features/Customers/Components/CustomerListRow.swift
  - apps/ios/BuyLedger.xcodeproj/project.pbxproj
  - apps/ios/BuyLedger/Features/Orders/OrdersFeature.swift
  - apps/ios/BuyLedgerTests/QuoteFeatureTests.swift
  - apps/ios/BuyLedger/Features/AISummary/OllamaClient.swift
  - apps/ios/BuyLedgerTests/OrdersFeatureTests.swift
-->

---
### Requirement: Settings are available from the first frame

The persisted preferences SHALL be read once at launch and supplied when the settings state is constructed, so that the first rendered frame already reflects them. The settings held in memory SHALL be the only writer of the persisted preferences; refreshing another screen SHALL NOT re-read them from storage.

#### Scenario: The first frame uses the persisted language

- **WHEN** the app launches with English stored as the interface language
- **THEN** the first frame is rendered in English, without first rendering the default language

##### Example: state at construction

- **GIVEN** stored settings of English, USD, and a monthly goal of 120,000
- **WHEN** the root state is constructed at launch, before any action is processed
- **THEN** the settings state already holds English, USD, and 120,000

#### Scenario: A dashboard refresh does not re-read settings

- **WHEN** the user pulls to refresh the dashboard
- **THEN** orders are reloaded and the in-memory settings are left as they are

##### Example: storage reads during a refresh

- **GIVEN** the settings storage records every read
- **WHEN** the dashboard refresh is handled
- **THEN** the only action forwarded is the orders load, and the storage read count stays at 0


<!-- @trace
source: small-features-style-compliance
updated: 2026-09-24
code:
  - apps/ios/BuyLedgerTests/BLFormattersTests.swift
  - apps/ios/BuyLedger/Features/Quote/Components/QuoteInputsCard.swift
  - apps/ios/BuyLedger/Features/FX/Components/FxStatusBanner.swift
  - apps/ios/BuyLedger/Features/Orders/OrderDateSection.swift
  - apps/ios/BuyLedger/Features/Quote/QuoteView.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/fxViewBaseline.1.png
  - apps/ios/BuyLedger/Features/FX/Components/FxRatesList.swift
  - apps/ios/BuyLedger/Features/AISummary/OllamaDTO.swift
  - apps/ios/BuyLedgerTests/ActionGroupingScanTests+Scanner.swift
  - apps/ios/BuyLedgerTests/ActionGroupingScanTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLFormatters.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsSnapshot.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsStore.swift
  - apps/ios/BuyLedgerTests/SnapshotTests.swift
  - apps/ios/BuyLedger/Core/Networking/OllamaChatRequest.swift
  - apps/ios/BuyLedgerTests/SettingsFeatureTests.swift
  - apps/ios/BuyLedger/Features/Customers/CustomersView.swift
  - apps/ios/BuyLedger/App/BuyLedgerApp.swift
  - apps/ios/BuyLedger/Features/Quote/QuoteRateFeature.swift
  - apps/ios/BuyLedgerTests/FxFeatureTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/fxViewRateFailureBaseline.1.png
  - apps/ios/BuyLedger/Shared/Extensions/Bundle+Extensions.swift
  - apps/ios/BuyLedger/Features/Customers/CustomerRankBadgeStyle.swift
  - apps/ios/BuyLedgerTests/ActionGroupingScanTests+Scenarios.swift
  - apps/ios/BuyLedgerTests/AISummaryFeatureTests.swift
  - apps/ios/BuyLedger/Core/Networking/OllamaClient.swift
  - apps/ios/BuyLedger/Features/Customers/Components/CustomerTopCard.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsFeature.swift
  - apps/ios/BuyLedgerTests/LedgerOrder+Fixture.swift
  - apps/ios/BuyLedger/Features/Customers/CustomerRow.swift
  - apps/ios/CLAUDE.md
  - apps/ios/BuyLedger/Features/Settings/AISummaryModelCatalog.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsView.swift
  - apps/ios/BuyLedger/Features/FX/FxView.swift
  - apps/ios/BuyLedger/Features/Customers/CustomersFeature.swift
  - apps/ios/BuyLedgerTests/SettingsStoreTests.swift
  - apps/ios/BuyLedger/Features/FX/FxFormatters.swift
  - apps/ios/BuyLedger/Features/Quote/Components/QuoteBreakdownCard.swift
  - apps/ios/BuyLedger/Features/AISummary/AISummaryView.swift
  - apps/ios/BuyLedger/Features/AISummary/AISummaryFeature.swift
  - apps/ios/BuyLedgerTests/FxRateSnapshotTests.swift
  - apps/ios/BuyLedger/Features/App/RootFeature.swift
  - apps/ios/BuyLedger/Features/More/MoreView.swift
  - apps/ios/BuyLedgerTests/CustomersFeatureTests.swift
  - apps/ios/BuyLedgerTests/OllamaClientTests.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests.swift
  - apps/ios/BuyLedgerTests/AppLanguageTests.swift
  - apps/ios/BuyLedger/Features/Quote/Components/QuoteStatusBanner.swift
  - apps/ios/README.md
  - apps/ios/BuyLedgerTests/CustomerRowTests.swift
  - apps/ios/BuyLedger/Core/Networking/OllamaChatResponse.swift
  - apps/ios/BuyLedger/Features/Quote/QuoteFeature.swift
  - apps/ios/BuyLedger/Core/Domain/FxRateSnapshot.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersFeature+StateQuery.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFormatters.swift
  - apps/ios/BuyLedger/Features/FX/FxFeature.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsStorage.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestDependencyOverrides.swift
  - apps/ios/BuyLedger/Features/Customers/Components/CustomerListRow.swift
  - apps/ios/BuyLedger.xcodeproj/project.pbxproj
  - apps/ios/BuyLedger/Features/Orders/OrdersFeature.swift
  - apps/ios/BuyLedgerTests/QuoteFeatureTests.swift
  - apps/ios/BuyLedger/Features/AISummary/OllamaClient.swift
  - apps/ios/BuyLedgerTests/OrdersFeatureTests.swift
-->

---
### Requirement: Settings writes preserve the order of edits

Each edit to a persisted preference SHALL be written before the next edit is processed, so that the last value the user entered is the value that remains stored.

#### Scenario: Rapid edits keep the last value

- **WHEN** the user types a new monthly goal one digit at a time
- **THEN** the stored goal after the last keystroke equals the value shown in the field

##### Example: three keystrokes

- **GIVEN** the stored monthly goal is 0
- **WHEN** the field receives 1, 12, and 120 in that order
- **THEN** three writes happen in that order and the stored goal is 120

<!-- @trace
source: small-features-style-compliance
updated: 2026-09-24
code:
  - apps/ios/BuyLedgerTests/BLFormattersTests.swift
  - apps/ios/BuyLedger/Features/Quote/Components/QuoteInputsCard.swift
  - apps/ios/BuyLedger/Features/FX/Components/FxStatusBanner.swift
  - apps/ios/BuyLedger/Features/Orders/OrderDateSection.swift
  - apps/ios/BuyLedger/Features/Quote/QuoteView.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/fxViewBaseline.1.png
  - apps/ios/BuyLedger/Features/FX/Components/FxRatesList.swift
  - apps/ios/BuyLedger/Features/AISummary/OllamaDTO.swift
  - apps/ios/BuyLedgerTests/ActionGroupingScanTests+Scanner.swift
  - apps/ios/BuyLedgerTests/ActionGroupingScanTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLFormatters.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsSnapshot.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsStore.swift
  - apps/ios/BuyLedgerTests/SnapshotTests.swift
  - apps/ios/BuyLedger/Core/Networking/OllamaChatRequest.swift
  - apps/ios/BuyLedgerTests/SettingsFeatureTests.swift
  - apps/ios/BuyLedger/Features/Customers/CustomersView.swift
  - apps/ios/BuyLedger/App/BuyLedgerApp.swift
  - apps/ios/BuyLedger/Features/Quote/QuoteRateFeature.swift
  - apps/ios/BuyLedgerTests/FxFeatureTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/fxViewRateFailureBaseline.1.png
  - apps/ios/BuyLedger/Shared/Extensions/Bundle+Extensions.swift
  - apps/ios/BuyLedger/Features/Customers/CustomerRankBadgeStyle.swift
  - apps/ios/BuyLedgerTests/ActionGroupingScanTests+Scenarios.swift
  - apps/ios/BuyLedgerTests/AISummaryFeatureTests.swift
  - apps/ios/BuyLedger/Core/Networking/OllamaClient.swift
  - apps/ios/BuyLedger/Features/Customers/Components/CustomerTopCard.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsFeature.swift
  - apps/ios/BuyLedgerTests/LedgerOrder+Fixture.swift
  - apps/ios/BuyLedger/Features/Customers/CustomerRow.swift
  - apps/ios/CLAUDE.md
  - apps/ios/BuyLedger/Features/Settings/AISummaryModelCatalog.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsView.swift
  - apps/ios/BuyLedger/Features/FX/FxView.swift
  - apps/ios/BuyLedger/Features/Customers/CustomersFeature.swift
  - apps/ios/BuyLedgerTests/SettingsStoreTests.swift
  - apps/ios/BuyLedger/Features/FX/FxFormatters.swift
  - apps/ios/BuyLedger/Features/Quote/Components/QuoteBreakdownCard.swift
  - apps/ios/BuyLedger/Features/AISummary/AISummaryView.swift
  - apps/ios/BuyLedger/Features/AISummary/AISummaryFeature.swift
  - apps/ios/BuyLedgerTests/FxRateSnapshotTests.swift
  - apps/ios/BuyLedger/Features/App/RootFeature.swift
  - apps/ios/BuyLedger/Features/More/MoreView.swift
  - apps/ios/BuyLedgerTests/CustomersFeatureTests.swift
  - apps/ios/BuyLedgerTests/OllamaClientTests.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests.swift
  - apps/ios/BuyLedgerTests/AppLanguageTests.swift
  - apps/ios/BuyLedger/Features/Quote/Components/QuoteStatusBanner.swift
  - apps/ios/README.md
  - apps/ios/BuyLedgerTests/CustomerRowTests.swift
  - apps/ios/BuyLedger/Core/Networking/OllamaChatResponse.swift
  - apps/ios/BuyLedger/Features/Quote/QuoteFeature.swift
  - apps/ios/BuyLedger/Core/Domain/FxRateSnapshot.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersFeature+StateQuery.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFormatters.swift
  - apps/ios/BuyLedger/Features/FX/FxFeature.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsStorage.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestDependencyOverrides.swift
  - apps/ios/BuyLedger/Features/Customers/Components/CustomerListRow.swift
  - apps/ios/BuyLedger.xcodeproj/project.pbxproj
  - apps/ios/BuyLedger/Features/Orders/OrdersFeature.swift
  - apps/ios/BuyLedgerTests/QuoteFeatureTests.swift
  - apps/ios/BuyLedger/Features/AISummary/OllamaClient.swift
  - apps/ios/BuyLedgerTests/OrdersFeatureTests.swift
-->