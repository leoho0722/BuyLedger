# lookup-management Specification

## Purpose

TBD - created by archiving change 'lookup-management-macos-card-style'. Update Purpose after archive.

## Requirements

### Requirement: Platform-adaptive lookup management presentation

The lookup management screen (used for order source, category, and payment method) SHALL render a system List on iOS and iPadOS. The presentation MUST NOT change the available operations or the underlying data.

#### Scenario: iOS and iPadOS keep the system List

- **WHEN** the order source, category, or payment method management screen is shown on iOS or iPadOS
- **THEN** the screen presents the system List with a section header, trailing swipe actions for delete and rename, and the existing footer, unchanged from before this change

---
### Requirement: Lookup item management operations are preserved across platforms

The screen SHALL allow the user to add, rename, and delete lookup items on iOS and iPadOS. The add, rename, and delete operations and their validation SHALL behave identically on both, and SHALL write through the same management feature as before this change.

Each operation SHALL update the shared lookup store, and therefore every list derived from it (the management list and the order editor's selectable values), as part of the same state update, rather than through separate synchronization performed by the root feature. Rewriting the orders held in memory after a rename is not part of that update; it follows the requirement "Lookup data has a single source shared by every consumer". Every operation SHALL be written to the store first, and the shared lookup state SHALL change only after that write succeeds; a failed write SHALL leave the shared lookup state exactly as it was before the operation, so that no consumer can select a value the store does not hold.

A failed add, rename, or delete SHALL be reported as a one-time notice that the user dismisses and that disappears once dismissed. A failed payment method correction, whether sampling the affected orders or the atomic write fails, SHALL be reported the same way, and SHALL leave both the payment method and the orders unchanged. It SHALL NOT be written to the load-failure message shown above the list, which is reserved for the screen's initial load failing.

When a lookup management screen cannot be resolved for a requested kind, the screen SHALL present the existing load-failure view rather than rendering blank, so that a resolution failure is visible rather than silent.

#### Scenario: Add a lookup item

- **WHEN** the user activates the toolbar add control and confirms a non-empty, trimmed name, and the write succeeds
- **THEN** the item is added through the management feature and appears in the list

#### Scenario: Rename a lookup item

- **WHEN** the user triggers rename on an item and confirms a non-empty name different from the original, and the write succeeds
- **THEN** the item is renamed through the management feature and orders referencing the old name are updated

#### Scenario: Delete a lookup item

- **WHEN** the user triggers delete on an item, confirms, and the write succeeds
- **THEN** the item is removed through the management feature

#### Scenario: A failed operation leaves the list unchanged and shows a one-time notice

- **WHEN** the store rejects the write of an add, rename, delete, or payment method correction, or reading the orders affected by a payment method correction fails
- **THEN** the list and every consumer's selectable values are unchanged, a dismissible notice states which operation failed, and no message is added above the list

##### Example: failure notices per operation

| Operation | List after failure | Notice message |
| --------- | ------------------ | -------------- |
| add "手工藝品" to categories ["服飾"] | ["服飾"] | 新增失敗，請稍後再試。 |
| rename "服飾" to "衣著" in ["服飾"] | ["服飾"], orders still reference "服飾" | 重新命名失敗，請稍後再試。 |
| delete "服飾" from ["服飾"] | ["服飾"] | 刪除失敗，請稍後再試。 |
| correct "信用卡" to cash on delivery, the atomic write fails | 信用卡 keeps its previous flags, orders unchanged | 付款方式編輯失敗，請稍後再試。 |
| correct "信用卡", reading the affected orders fails | 信用卡 keeps its previous flags, orders unchanged | 付款方式編輯失敗，請稍後再試。 |

#### Scenario: A rename writes the stored lookup and the stored orders in one transaction

- **WHEN** the user renames a lookup item
- **THEN** the stored lookup and every stored order that references the old name are updated in a single save, so either both reflect the new name or, if the save fails, both keep their previous state; on failure the list and every consumer still show the previous values, a one-time notice states that the rename failed, and no rename delegate action is emitted

##### Example: renames with a failing save

| Stored categories before | Stored orders before | Rename | Stored categories after | Stored orders after |
| ------------------------ | -------------------- | ------ | ----------------------- | ------------------- |
| ["服飾"] | A: 服飾 | 服飾 → 衣著 | ["服飾"] | A: 服飾 |
| ["服飾", "衣著"] | A: 服飾, B: 衣著 | 服飾 → 衣著 | ["服飾", "衣著"] | A: 服飾, B: 衣著 |

##### Example: a rename onto an existing name that succeeds

- **GIVEN** the stored categories are ["服飾", "衣著"] and order A references "服飾"
- **WHEN** the user renames "服飾" to "衣著" and the save succeeds
- **THEN** the stored categories are ["衣著"] and order A references "衣著"

#### Scenario: A notice that is ready while the form is closing appears after the form closes

- **WHEN** an add, rename, or payment method edit is submitted from its form, and the write failure notice or the retroactive confirmation is ready before the form has finished closing
- **THEN** the notice or confirmation is held until the form has closed and is then shown once; one that becomes ready after the form has closed is shown immediately

##### Example: an add that the store rejects immediately

- **GIVEN** the categories are ["服飾"] and the store rejects every write without delay
- **WHEN** the user submits "失敗類別" from the add form
- **THEN** the form closes first, the notice 新增失敗，請稍後再試。 then appears, and the list stays ["服飾"]

#### Scenario: Dismissing a failure notice clears it

- **WHEN** the user dismisses a write-failure notice
- **THEN** the notice is gone, and it does not reappear on later successful operations

#### Scenario: The initial load failure stays above the list

- **WHEN** the screen's initial load of a lookup kind fails
- **THEN** the load-failure message is shown above the list until a later load succeeds

#### Scenario: iOS swipe-to-delete is retained

- **WHEN** the user swipes an item row on iOS or iPadOS
- **THEN** the swipe actions for delete and rename are available, unchanged from before this change

#### Scenario: An unresolvable management screen is visibly failed, not blank

- **WHEN** the management screen for a requested lookup kind cannot be resolved
- **THEN** the load-failure view is shown instead of an empty screen


<!-- @trace
source: lookups-style-compliance
updated: 2026-09-25
code:
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Lookups/lookupManagementEmptyBaseline.1.png
  - apps/ios/BuyLedger/Features/Lookups/LookupItemRename.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementView.swift
  - apps/ios/BuyLedgerTests/ActionGroupingScanTests.swift
  - apps/ios/BuyLedgerTests/LookupManagementFeatureTests+AlertTiming.swift
  - apps/ios/BuyLedgerTests/OrderPersistenceTests.swift
  - apps/ios/BuyLedger/Features/Lookups/Components/LookupItemList.swift
  - apps/ios/BuyLedger/Core/Dependencies/OrderRepository.swift
  - apps/ios/BuyLedgerTests/SnapshotTests+Lookups.swift
  - apps/ios/BuyLedger/Features/Lookups/PaymentMethodEditFormFeature.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupItemOperations.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestConfiguration.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupNameEditorSheet.swift
  - apps/ios/BuyLedger.xcodeproj/project.pbxproj
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Lookups/moreViewMissingLookupManagementShowsUnavailableBaseline.1.png
  - apps/ios/BuyLedgerTests/LookupManagementFeatureTests+Failures.swift
  - apps/ios/BuyLedger/Core/Persistence/NameLookupPersistence.swift
  - apps/ios/BuyLedgerTests/LookupManagementFeatureTests+Forms.swift
  - apps/ios/BuyLedger/Core/Persistence/PaymentMethodPersistence.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Lookups/lookupNameEditorSheetRenameBaseline.1.png
  - apps/ios/BuyLedgerTests/BLUITestConfigurationTests.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift
  - apps/ios/BuyLedger/Core/Persistence/LookupRecordRenamer.swift
  - apps/ios/BuyLedgerTests/OrderPersistenceTests+LookupRenameFailures.swift
  - apps/ios/BuyLedger/Features/App/RootFeature.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupKind.swift
  - apps/ios/BuyLedgerTests/LookupManagementFeatureTests+PaymentMethodCorrection.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Lookups/lookupManagementLoadFailureBaseline.1.png
  - apps/ios/BuyLedgerTests/LookupCatalog+TestIsolation.swift
  - apps/ios/BuyLedgerUITests/Screens/LookupManagementScreen.swift
  - apps/ios/BuyLedger/Features/App/RootSidebarLayout.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupAddFormFeature.swift
  - apps/ios/BuyLedgerTests/LookupManagementFeatureTests+Support.swift
  - apps/ios/BuyLedger/Features/Lookups/SharedKey+LookupCatalog.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestDependencyOverrides.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Lookups/lookupManagementCategoryBaseline.1.png
  - apps/ios/CLAUDE.md
  - apps/ios/BuyLedger/Features/Lookups/PaymentMethodCorrectionFeature.swift
  - apps/ios/BuyLedgerTests/OrderPersistence+LookupTesting.swift
  - apps/ios/BuyLedgerAccessibilityIDs/BLAccessibilityID.swift
  - apps/ios/BuyLedgerTests/PaymentMethodCorrectionFeatureTests.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupRenameFormFeature.swift
  - apps/ios/BuyLedgerTests/LocalizationCatalogTests.swift
  - apps/ios/BuyLedgerTests/LookupManagementFeatureTests.swift
  - apps/ios/BuyLedgerUITests/Tests/More/LookupManagementTests.swift
  - apps/ios/BuyLedgerTests/LookupCatalogTests.swift
  - apps/ios/README.md
  - apps/ios/BuyLedger/Core/Persistence/OrderPersistence.swift
  - apps/ios/BuyLedger/Features/Lookups/PaymentMethodEditPlan.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature+Destination.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupItemAddition.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupCatalog.swift
  - apps/ios/BuyLedgerUITests/Support/LaunchOptions.swift
  - apps/ios/BuyLedger/Features/Lookups/Components/LookupItemRow.swift
  - apps/ios/BuyLedgerTests/OrderPersistenceTests+LookupRename.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Lookups/lookupManagementPaymentMethodBaseline.1.png
  - apps/ios/BuyLedgerTests/ActionGroupingScanTests+Scenarios.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementDestination.swift
-->

---
### Requirement: Payment method cardless indicator

For the payment method kind, the screen SHALL display a "cardless" badge on each item flagged as cardless and SHALL display an explanatory note describing the cardless behavior. The badge and note SHALL be present on all platforms.

#### Scenario: Cardless payment method shows badge and note

- **WHEN** the payment method management screen is shown and at least one method is flagged cardless
- **THEN** each cardless method row displays the "無卡" badge and the screen displays the explanatory note about the cardless discount and top-up fields


<!-- @trace
source: lookup-management-macos-card-style
updated: 2026-05-24
code:
  - .agents/skills/spectra-discuss/SKILL.md
  - .agents/skills/spectra-drift/SKILL.md
  - .agents/skills/spectra-ingest/SKILL.md
  - .agents/skills/spectra-apply/SKILL.md
  - .agents/skills/spectra-propose/SKILL.md
  - apps/apple/BuyLedger/Features/Lookups/LookupManagementView.swift
-->

---
### Requirement: Lookup item count and empty state

The screen SHALL display the count of created items, and SHALL display an empty state with the kind-specific title and description when no items exist.

#### Scenario: Count is displayed

- **WHEN** the management screen is shown with one or more items
- **THEN** the screen displays the number of created items

#### Scenario: Empty state when no items exist

- **WHEN** the management screen is shown with no items
- **THEN** the screen displays the kind-specific empty title and description

<!-- @trace
source: lookup-management-macos-card-style
updated: 2026-05-24
code:
  - .agents/skills/spectra-discuss/SKILL.md
  - .agents/skills/spectra-drift/SKILL.md
  - .agents/skills/spectra-ingest/SKILL.md
  - .agents/skills/spectra-apply/SKILL.md
  - .agents/skills/spectra-propose/SKILL.md
  - apps/apple/BuyLedger/Features/Lookups/LookupManagementView.swift
-->

---
### Requirement: Reconciliation status is a managed lookup kind

The lookup management screen SHALL support reconciliation status as a managed kind, with the same add, rename, and delete operations and the same presentation (system List on iOS and iPadOS) as the existing order source, category, and payment method kinds. Adding a reconciliation status SHALL use a medium-height name editor sheet (matching the add-payment-method interaction), not a plain alert. Renaming a reconciliation status SHALL update orders that reference the old value.

#### Scenario: Add a reconciliation status via the medium sheet

- **WHEN** the user activates the add control on the reconciliation status management screen and confirms a non-empty, trimmed name in the medium-height sheet
- **THEN** the status is added through the management feature and appears in the list

#### Scenario: Rename a reconciliation status cascades to orders

- **WHEN** the user renames a reconciliation status to a non-empty name different from the original
- **THEN** the status is renamed through the management feature and orders referencing the old status value are updated to the new value

#### Scenario: Delete a reconciliation status

- **WHEN** the user triggers delete on a reconciliation status
- **THEN** the status is removed through the management feature

#### Scenario: Empty state when no reconciliation statuses exist

- **WHEN** the reconciliation status management screen is shown with no items
- **THEN** the screen displays the reconciliation-status empty title and description

---
### Requirement: Payment method bank-transfer indicator

For the payment method kind, the screen SHALL display a "bank transfer" (銀行匯款) badge on each item flagged as bank transfer, in addition to the existing cardless badge. A payment method flagged as both cardless and bank transfer SHALL display both badges. The badges SHALL be present on all platforms.

#### Scenario: Bank-transfer payment method shows the badge

- **WHEN** the payment method management screen is shown and at least one method is flagged bank transfer
- **THEN** each bank-transfer method row displays the "銀行匯款" badge

#### Scenario: A method flagged both cardless and bank transfer shows both badges

- **WHEN** a payment method is flagged both cardless and bank transfer
- **THEN** its row displays both the "無卡" and "銀行匯款" badges


<!-- @trace
source: order-reconciliation-status
updated: 2026-05-29
code:
  - apps/apple/BuyLedger/Features/Lookups/LookupManagementFeature.swift
  - apps/apple/BuyLedger/Core/Persistence/PaymentMethodPersistence.swift
  - apps/apple/BuyLedger/Features/Orders/Components/OptionPickerSheet.swift
  - apps/apple/BuyLedger/Core/Dependencies/OrderRepository.swift
  - apps/apple/BuyLedger/Features/More/MoreView.swift
  - apps/apple/BuyLedger/Features/Orders/Components/PaymentMethodEditorSheet.swift
  - apps/apple/BuyLedger/Features/Orders/OrdersFeature.swift
  - apps/apple/BuyLedger/Core/Dependencies/PaymentMethodRepository.swift
  - apps/apple/BuyLedger/Core/Persistence/PaymentMethodRecord.swift
  - apps/apple/BuyLedger/Features/Lookups/LookupKind.swift
  - apps/apple/BuyLedger/Core/Persistence/OrderRecord.swift
  - apps/apple/BuyLedger/Core/Domain/LedgerOrder+Samples.swift
  - apps/apple/BuyLedgerTests/PaymentMethodPersistenceTests.swift
  - apps/apple/BuyLedger/Core/Domain/PaymentMethodInfo.swift
  - apps/apple/BuyLedger/Core/Persistence/BuyLedgerSchema.swift
  - apps/apple/BuyLedger/Features/Lookups/LookupManagementView.swift
  - apps/apple/BuyLedger/Core/Persistence/PersistenceContainer.swift
  - apps/apple/BuyLedger/Core/Domain/LedgerOrder.swift
  - apps/apple/BuyLedger/Features/Orders/Components/LookupItemEditorSheet.swift
  - apps/apple/BuyLedgerTests/OrderEditFeatureTests.swift
  - apps/apple/BuyLedger/Features/Orders/OrderEditView.swift
  - apps/apple/BuyLedgerTests/RootFeatureTests.swift
  - apps/apple/BuyLedgerTests/SnapshotTests.swift
  - apps/apple/BuyLedger/Features/Orders/OrderEditFeature.swift
  - apps/apple/BuyLedgerTests/OrderPersistenceTests.swift
  - apps/apple/BuyLedger/Core/Persistence/OrderPersistence.swift
  - apps/apple/BuyLedgerTests/OrderCalculationTests.swift
  - apps/apple/BuyLedger/Core/Dependencies/VerificationStatusRepository.swift
  - apps/apple/BuyLedgerTests/OrdersFeaturePerformanceTests.swift
  - apps/apple/BuyLedger/Features/App/RootFeature.swift
  - apps/apple/BuyLedgerTests/LookupManagementFeatureTests.swift
  - apps/apple/BuyLedger/Core/Persistence/VerificationStatusRecord.swift
  - apps/apple/BuyLedgerTests/OrdersFeatureTests.swift
  - apps/apple/BuyLedger/Core/Persistence/VerificationStatusPersistence.swift
-->

---
### Requirement: Payment method editing via the editor sheet

For the payment method kind, the per-item edit action SHALL be labeled "編輯" and SHALL present the payment method editor pre-filled with the item's current name, cardless flag, and bank-transfer flag. Confirming SHALL apply the edited name and flags authoritatively: changing the name SHALL rename the item and cascade to orders referencing the old name, and the cardless and bank-transfer flags SHALL be set to exactly the user's selection — including clearing a previously-set flag. The edit action SHALL be available from every per-item entry point that previously offered rename (iOS swipe, iOS context menu). Other lookup kinds (order source, category, reconciliation status) SHALL retain the rename-only action labeled "重新命名".

Applying flags authoritatively SHALL extend to orders already using the payment method. The flags govern how an order's finances are computed, so leaving existing orders on the previous flags would keep computing them from a state the user has just corrected. Existing orders SHALL therefore be recomputed using the same normalization the order editor applies, and SHALL be written together with the lookup update so that a failure applies neither.

Because recomputation rewrites stored values of existing orders and cannot be undone, it SHALL be confirmed before it runs. The confirmation SHALL state how many orders will be affected. Declining SHALL leave both the orders and the lookup flags unchanged, so that the lookup and the orders never disagree.

#### Scenario: Edit a payment method's name and flags

- **WHEN** the user activates "編輯" on a payment method, changes its name, and confirms
- **THEN** the payment method is renamed, orders referencing the old name are updated, and its cardless and bank-transfer flags reflect the user's selection

#### Scenario: Correcting a missed cash-on-delivery flag fixes existing profit

- **WHEN** the user sets the cash-on-delivery flag on a payment method that orders already use, and confirms the recomputation
- **THEN** those orders are recomputed so that the three shipping amounts are included in their cost, and their reported profit changes accordingly

#### Scenario: Confirmation states the blast radius

- **WHEN** a flag change would affect existing orders
- **THEN** the confirmation states the number of orders that will be recomputed

#### Scenario: Declining leaves everything unchanged

- **WHEN** the user declines the recomputation confirmation
- **THEN** neither the orders nor the payment method's flags are changed

#### Scenario: Recomputation and lookup update are atomic

- **WHEN** persistence fails while recomputing affected orders
- **THEN** neither the orders nor the payment method's flags are changed

#### Scenario: Clearing the cardless flag clears dependent amounts

- **WHEN** the user clears the cardless flag on a payment method that orders already use, and confirms
- **THEN** those orders' cardless deduction and supplement amounts become zero, matching what the order editor would produce


<!-- @trace
source: payment-flag-retroactive-correction
updated: 2026-08-22
code:
  - apps/ios/BuyLedger/Core/Dependencies/ReconciliationStatusRepository.swift
  - apps/ios/BuyLedgerUITests/Screens/PhotoViewerScreen.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementView.swift
  - apps/ios/BuyLedgerTests/OrderMergeTests.swift
  - apps/ios/BuyLedger/App/AppLaunchConfigurator.swift
  - apps/ios/BuyLedgerUITests/Screens/SettingsScreen.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/LedgerOrderItem.generated.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/ViewModifiers/BLTypographyModifier.swift
  - apps/ios/BuyLedgerTests/BLPhotoViewerTests.swift
  - apps/ios/BuyLedgerTests/NumericInputGroupingScanTests.swift
  - apps/ios/BuyLedger/Core/Persistence/OrderRecord.swift
  - apps/ios/BuyLedgerUITests/Screens/OrderDetailScreen.swift
  - apps/ios/BuyLedgerTests/AccessibilityConventionScanTests.swift
  - shared/data-model/fixtures/expected/swift/SampleStatus.generated.swift
  - shared/data-model/fixtures/expected/typescript/SampleSequence.ts
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewMultiSelectBaseline.1.png
  - apps/ios/BuyLedger/Core/Domain/Generated/FxRateSnapshot.generated.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupCatalog.swift
  - apps/ios/BuyLedger/Resources/Localizable.xcstrings
  - apps/ios/BuyLedger/Core/Domain/Generated/CurrencyCode.generated.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestDependencyOverrides.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLFormatters.swift
  - apps/ios/BuyLedger/Core/Domain/FxRateSnapshot.swift
  - apps/ios/BuyLedger/Features/Settings/AppLanguage.swift
  - apps/ios/BuyLedger/Features/App/SidebarBadgeCounts.swift
  - apps/ios/BuyLedgerUITests/Screens/OptionPickerScreen.swift
  - apps/ios/BuyLedgerTests/InsightsFeatureTests.swift
  - apps/ios/BuyLedger/Core/Persistence/ReconciliationStatusPersistence.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardView.swift
  - apps/ios/BuyLedgerUITests/Support/MenuInteraction.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderDetailView.swift
  - apps/ios/BuyLedgerUITests/Tests/Campaigns/CampaignCrudTests.swift
  - shared/data-model/fixtures/expected/kotlin/SampleProfile.kt
  - shared/data-model/fixtures/expected/typescript/SampleGrade.ts
  - apps/ios/BuyLedgerUITests/Support/AlertInteraction.swift
  - apps/ios/BuyLedger/Core/Domain/FxRates.swift
  - apps/ios/BuyLedger/Core/Domain/Campaign+Samples.swift
  - apps/ios/BuyLedger.xcodeproj/project.pbxproj
  - apps/ios/BuyLedgerUITests/Screens/FxScreen.swift
  - apps/ios/BuyLedger/Core/Dependencies/CategoryRepository.swift
  - apps/ios/BuyLedgerTests/OrderCalculationTests.swift
  - shared/data-model/fixtures/expected/swift/SampleQuote.generated.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewBaseline.1.png
  - apps/ios/BuyLedger/Core/Persistence/CampaignRecord.swift
  - apps/ios/BuyLedger/Features/AISummary/AISummaryFeature.swift
  - apps/ios/BuyLedgerTests/DesignSystemSourceScanTests.swift
  - shared/data-model/fixtures/expected/typescript/SamplePreference.ts
  - apps/ios/BuyLedger/Core/Domain/Generated/CampaignStatus.generated.swift
  - shared/data-model/schema/OrderStatus.yaml
  - apps/ios/BuyLedgerTests/TestSuiteIntegrityTests.swift
  - apps/ios/BuyLedger/Core/Persistence/CategoryPersistence.swift
  - apps/ios/BuyLedger/Shared/Media/PhotoDataProcessor.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersBatchOperations.swift
  - apps/ios/BuyLedger/Core/Persistence/OrderSourcePersistence.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestConfiguration.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLHeatmapDepth.swift
  - apps/ios/BuyLedger/Features/Customers/CustomersFeature.swift
  - apps/ios/BuyLedger/Core/Persistence/PersistenceStoreQuarantineClient.swift
  - apps/ios/BuyLedger/Features/App/RootTabLayout.swift
  - apps/ios/BuyLedger/Features/Orders/OrderEditView.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersFilterOperations.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests.swift
  - apps/ios/BuyLedgerTests/FxFeatureTests.swift
  - shared/data-model/fixtures/expected/kotlin/SampleQuote.kt
  - apps/ios/BuyLedgerTests/AppScenePhaseCoordinatorTests.swift
  - apps/ios/BuyLedger/Features/App/RootFeature.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Buttons/BLButtonStyle.swift
  - apps/ios/BuyLedgerTests/CalendarReminderTests.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignListView.swift
  - apps/ios/BuyLedgerUITests/Screens/AppLockScreen.swift
  - apps/ios/BuyLedger/Features/FX/FxView.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLSparkline.swift
  - shared/data-model/fixtures/expected/swift/SampleReceipt.generated.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestHarness.swift
  - apps/ios/BuyLedgerTests/CampaignReminderFailureTests.swift
  - shared/data-model/README.md
  - apps/ios/BuyLedger/Core/Dependencies/OrderRepository.swift
  - apps/ios/BuyLedger/Core/Persistence/BuyLedgerSchema.swift
  - apps/ios/BuyLedgerTests/AISummaryFeatureTests.swift
  - apps/ios/BuyLedgerTests/OrderStatusTests.swift
  - apps/ios/BuyLedgerTests/APIErrorMappingTests.swift
  - apps/ios/BuyLedgerTests/PersistenceRecoveryTests.swift
  - apps/ios/BuyLedgerTests/BLUITestConfigurationTests.swift
  - apps/ios/BuyLedger/Core/Domain/OrderSummary.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLTypography.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLMetrics.swift
  - apps/ios/BuyLedger/Core/Networking/ExchangeRateClient.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsStorage.swift
  - apps/ios/BuyLedger/Features/Orders/OrderEditFeature.swift
  - apps/ios/BuyLedgerTests/OrderEditFeatureTests.swift
  - shared/data-model/schema/CampaignStatus.yaml
  - apps/ios/BuyLedger/Core/Domain/Generated/PaymentReceiptStatus.generated.swift
  - apps/ios/BuyLedgerTests/InsightsStatsTests.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignEditFeature.swift
  - apps/ios/BuyLedgerTests/CampaignEditFeatureTests.swift
  - apps/ios/BuyLedger/Core/Persistence/PersistenceContainer.swift
  - apps/ios/BuyLedgerTests/BiometricAuthClientTests.swift
  - apps/ios/BuyLedger/Core/Dependencies/CampaignRepository.swift
  - apps/ios/BuyLedger/Features/App/RootView.swift
  - apps/ios/BuyLedger/Resources/PrivacyInfo.xcprivacy
  - apps/ios/BuyLedger/Core/Persistence/NameLookupRecord.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrdersListTests.swift
  - apps/ios/BuyLedgerTests/OrdersBatchOperationsTests.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsDateRange.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/States/DelayedProgressView.swift
  - apps/ios/BuyLedger/Core/Testing/BLUITestSeedData.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/States/BLDelayedProgressView.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLPalette.swift
  - apps/ios/BuyLedgerTests/LookupManagementFeatureTests.swift
  - apps/ios/CLAUDE.md
  - apps/ios/BuyLedgerUITests/KeyboardDismissTests.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsFeature.swift
  - apps/ios/BuyLedger/Core/Persistence/CampaignReminderPersistence.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsView.swift
  - apps/ios/BuyLedgerUITests/Screens/OrderEditScreen.swift
  - apps/ios/BuyLedger/Core/Persistence/CurrencyMetadataRecord.swift
  - apps/ios/BuyLedger/Core/Domain/OrderMerge.swift
  - apps/ios/BuyLedgerUITests/Support/BLUITestCase.swift
  - apps/ios/BuyLedger/Core/Persistence/CampaignReminderRecord.swift
  - apps/ios/BuyLedgerUITests/Screens/CampaignsScreen.swift
  - apps/ios/BuyLedgerUITests/Screens/CustomersScreen.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Badges/BLBadge.swift
  - apps/ios/BuyLedger/Core/Dependencies/CurrencyMetadataRepository.swift
  - shared/data-model/fixtures/expected/typescript/SampleReceipt.ts
  - apps/ios/BuyLedger/Features/Campaigns/CampaignFeature.swift
  - apps/ios/BuyLedger/Core/Persistence/PersistenceStoreQuarantine.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsFeature.swift
  - apps/ios/BuyLedger/Core/Persistence/ReconciliationStatusRecord.swift
  - apps/ios/BuyLedger/Core/Networking/APIError.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestSeedProfile.swift
  - apps/ios/BuyLedger/Core/Sync/SyncMeta.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignEditView.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OptionPickerSheet.swift
  - apps/ios/BuyLedger/Features/Orders/OrderMergeFeature.swift
  - apps/ios/BuyLedgerTests/SettingsFeatureTests.swift
  - apps/ios/BuyLedgerTests/CampaignSummaryTests.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderSelectableRow.swift
  - apps/ios/BuyLedger/Core/Domain/CurrencyCode.swift
  - apps/ios/BuyLedger/Core/Domain/LedgerOrder.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Chips/BLFilterChip.swift
  - apps/ios/BuyLedger/Features/Orders/Components/MergePhotoPickerSheet.swift
  - apps/ios/BuyLedger/Core/Testing/BLUITestDependencyOverrides.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/ViewModifiers/BLHeroCardBackground.swift
  - AGENTS.md
  - apps/ios/BuyLedgerTests/LookupCatalogTests.swift
  - apps/ios/BuyLedger/Features/App/RootTab.swift
  - apps/ios/BuyLedgerUITests/Support/ValueParsing.swift
  - apps/ios/BuyLedgerTests/QuoteFeatureTests.swift
  - apps/ios/BuyLedgerTests/PersistenceErrorContractTests.swift
  - apps/ios/BuyLedger/Features/Customers/CustomersView.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupKind.swift
  - apps/ios/BuyLedger/Features/Orders/OrderDatePeriod.swift
  - apps/ios/BuyLedgerTests/SnapshotTests.swift
  - apps/ios/BuyLedgerUITests/Support/SheetInteraction.swift
  - apps/ios/BuyLedger.xctestplan
  - apps/ios/BuyLedger/Core/Dependencies/PhotoClient.swift
  - apps/ios/BuyLedger/Core/Domain/Campaign.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrdersToolbarContent.swift
  - apps/ios/BuyLedgerTests/PersistenceFailureFeatureTests.swift
  - shared/data-model/fixtures/expected/swift/SampleProfile.generated.swift
  - apps/ios/BuyLedgerUITests/Tests/Performance/LaunchPerformanceTests.swift
  - apps/ios/BuyLedger/App/AppDelegate.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderDetailTests.swift
  - apps/ios/BuyLedger/Features/Quote/QuoteFeature.swift
  - shared/data-model/fixtures/expected/swift/SampleSequence.generated.swift
  - apps/ios/BuyLedgerTests/CampaignFeatureTests.swift
  - apps/ios/BuyLedgerTests/BLAccessibilityIDTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/ViewModifiers/BLCardShadow.swift
  - apps/ios/BuyLedger/Core/Persistence/PersistenceError.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/dashboardViewBaseline.1.png
  - apps/ios/BuyLedger/Core/Domain/Generated/LedgerOrder.generated.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift
  - apps/ios/BuyLedger/Features/Quote/QuoteView.swift
  - apps/ios/BuyLedgerTests/DashboardStatsTests.swift
  - apps/ios/BuyLedger/Features/Customers/CustomerRankBadgeStyle.swift
  - apps/ios/BuyLedgerUITests/Screens/CampaignDetailScreen.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/PaymentMethodInfo.generated.swift
  - apps/ios/BuyLedgerUITests/Screens/OrdersScreen.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersCompactView.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersFeature.swift
  - shared/data-model/fixtures/expected/kotlin/SamplePreference.kt
  - shared/data-model/schema/LedgerOrder.yaml
  - apps/ios/BuyLedger/Core/Persistence/PaymentMethodPersistence.swift
  - apps/ios/BuyLedgerTests/InsightsAttributionTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoThumbnail.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewBaseline.1.png
  - apps/ios/BuyLedgerUITests/Tests/Campaigns/CampaignListTests.swift
  - apps/ios/BuyLedger/Core/Domain/LedgerOrder+Samples.swift
  - apps/ios/BuyLedger/Resources/InfoPlist.xcstrings
  - apps/ios/BuyLedger/Features/AISummary/OllamaClient.swift
  - apps/ios/BuyLedgerUITests/Support/Scrolling.swift
  - apps/ios/BuyLedger/Features/Orders/Components/PaymentMethodEditorSheet.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignDetailView.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupNameEditorSheet.swift
  - apps/ios/BuyLedger/Features/App/RootSidebarLayout.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLBarChart.swift
  - apps/ios/BuyLedger/Core/Networking/URLRequestBuilder.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardFeature.swift
  - apps/ios/BuyLedgerTests/ContrastComplianceTests.swift
  - apps/ios/BuyLedgerTests/OrderMergeFeatureTests.swift
  - apps/ios/BuyLedger/Core/Persistence/CurrencyMetadataPersistence.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Status/BLStatusPill.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Pickers/OptionPickerSheet.swift
  - apps/ios/BuyLedger/Resources/Info.plist
  - apps/ios/BuyLedger.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
  - shared/data-model/schema/FxRateSnapshot.yaml
  - apps/ios/BuyLedger/Core/Dependencies/NameLookupOperations.swift
  - apps/ios/BuyLedger/Features/App/AppLockFeature.swift
  - apps/ios/BuyLedger/Features/Orders/LedgerOrder+OrderMutation.swift
  - shared/data-model/schema/CustomerTier.yaml
  - apps/ios/BuyLedger/Features/More/MoreView.swift
  - apps/ios/BuyLedgerUITests/Screens/AISummaryScreen.swift
  - shared/data-model/fixtures/schema/sample-trait-matrix.yaml
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewMergeContextBaseline.1.png
  - apps/ios/BuyLedger/Core/Dependencies/OrderSourceRepository.swift
  - apps/ios/BuyLedgerUITests/Support/TextInput.swift
  - shared/data-model/schema/PaymentMethodInfo.yaml
  - .github/workflows/ci.yml
  - apps/ios/BuyLedgerUITests/Screens/QuoteScreen.swift
  - apps/ios/BuyLedger/Features/FX/ExchangeRateClient.swift
  - apps/ios/BuyLedger/Features/App/AppScenePhaseCoordinator.swift
  - apps/ios/BuyLedger/App/BuyLedgerApp.swift
  - README.md
  - apps/ios/BuyLedger/Core/Dependencies/PaymentMethodRepository.swift
  - apps/ios/BuyLedger/Features/FX/FxRates.swift
  - apps/ios/BuyLedger/Core/Persistence/NameLookupPersistence.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsSnapshot.swift
  - apps/ios/BuyLedger/Core/Dependencies/OpenSettingsClient.swift
  - apps/ios/BuyLedgerTests/AppConfigurationTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersRegularViewMultiSelectBaseline.1.png
  - shared/data-model/schema/LedgerCustomer.yaml
  - apps/ios/BuyLedger/Shared/Extensions/Image+Extensions.swift
  - apps/ios/BuyLedgerTests/OrdersLoadStateTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Cards/BLCard.swift
  - apps/ios/BuyLedgerUITests/Screens/Screen.swift
  - shared/data-model/schema/Campaign.yaml
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Tags/BLTagPill.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewLongContentBaseline.1.png
  - apps/ios/BuyLedgerUITests/Tests/Customers/CustomersTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderMergeTests.swift
  - shared/data-model/fixtures/expected/kotlin/SampleGrade.kt
  - shared/data-model/schema/Money.yaml
  - apps/ios/BuyLedger/Core/Testing/BLUITestSeedProfile.swift
  - apps/ios/BuyLedger/Core/Persistence/PaymentMethodRecord.swift
  - apps/ios/BuyLedger/Features/App/AppLockView.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsView.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFormatters.swift
  - apps/ios/BuyLedgerAccessibilityIDs/BLAccessibilityID.swift
  - apps/ios/BuyLedger/Features/AISummary/OllamaDTO.swift
  - apps/ios/BuyLedger/Features/Orders/OrderDetailPath.swift
  - apps/ios/BuyLedgerTests/ProjectionWriteBoundaryTests.swift
  - apps/ios/BuyLedgerUITests-Performance.xctestplan
  - shared/data-model/fixtures/expected/typescript/SampleStatus.ts
  - apps/ios/BuyLedgerTests/OrderEditFocusTests.swift
  - apps/ios/BuyLedger/Core/Persistence/OrderSourceRecord.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestSeedData.swift
  - apps/ios/BuyLedger/Core/Persistence/CategoryRecord.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsStats.swift
  - apps/ios/BuyLedgerTests/OrderDraftTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/quoteViewBaseline.1.png
  - apps/ios/BuyLedgerTests/CampaignIntegrationTests.swift
  - apps/ios/BuyLedgerTests/NameLookupPersistenceTests.swift
  - apps/ios/BuyLedger/Features/Orders/OrderDraft.swift
  - apps/ios/BuyLedger/Core/Dependencies/CalendarReminderClient.swift
  - apps/ios/BuyLedgerTests/ColorContrastTests.swift
  - apps/ios/BuyLedgerTests/SchemaMigrationTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoViewer.swift
  - apps/ios/BuyLedger/Features/Orders/OrderStatusFilter.swift
  - apps/ios/BuyLedger/Shared/Extensions/Bundle+Extensions.swift
  - apps/ios/BuyLedgerTests/OrderPersistenceTests.swift
  - apps/ios/BuyLedgerTests/PrivacyManifestTests.swift
  - apps/ios/BuyLedger/Features/FX/FxFeature.swift
  - apps/ios/BuyLedgerUITests/Screens/InsightsScreen.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/CustomerTier.generated.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewLongIdentifierBaseline.1.png
  - apps/ios/BuyLedger/Features/Orders/Components/OrderStatus+Presentation.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderEditDirtyTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLDonutSegment.swift
  - apps/ios/BuyLedgerTests/DashboardFeatureTests.swift
  - apps/ios/BuyLedger/Features/App/PersistenceFailureView.swift
  - shared/data-model/fixtures/schema/sample-enums.yaml
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLDonutChart.swift
  - shared/data-model/fixtures/expected/typescript/SampleProfile.ts
  - apps/ios/BuyLedger/Core/Networking/ExchangeRateDTO.swift
  - apps/ios/BuyLedger/Shared/Extensions/Color+Extensions.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Forms/PaymentMethodEditorSheet.swift
  - shared/data-model/fixtures/schema/sample-orders.yaml
  - apps/ios/BuyLedger/Features/Orders/OrdersFeature+StateQuery.swift
  - apps/ios/BuyLedger/Core/Networking/AppConfiguration.swift
  - shared/data-model/generator/src/datamodel-gen.ts
  - apps/ios/BuyLedgerUITests/Support/LaunchOptions.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Progress/BLProgressBar.swift
  - apps/ios/BuyLedgerUITests/Support/Assertions.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLBarChartValue.swift
  - apps/ios/BuyLedger/Core/Dependencies/CampaignReminderRepository.swift
  - shared/data-model/fixtures/expected/swift/SamplePreference.generated.swift
  - apps/ios/BuyLedger/Core/Testing/BLUITestConfiguration.swift
  - apps/ios/BuyLedgerTests/OllamaClientTests.swift
  - apps/ios/BuyLedgerTests/OrdersSearchCancellationTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/persistenceFailureViewBaseline.1.png
  - apps/ios/BuyLedger/Core/Dependencies/TelemetryClient.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/LedgerCustomer.generated.swift
  - apps/ios/BuyLedgerUITests/Tests/Tools/FxTests.swift
  - apps/ios/BuyLedgerTests/BLFormattersTests.swift
  - apps/ios/BuyLedger/Core/Domain/LedgerOrderItem.swift
  - apps/ios/BuyLedgerUITests/PhotoViewerPagingTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Insights/InsightsTests.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementDestination.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderCreateTests.swift
  - apps/ios/BuyLedgerTests/AppLockFeatureTests.swift
  - apps/ios/README.md
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLStatusHue.swift
  - apps/ios/BuyLedgerTests/ExchangeRateClientTests.swift
  - apps/ios/BuyLedger/Features/FX/ExchangeRateDTO.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/AISummaryTests.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardStats.swift
  - apps/ios/BuyLedgerUITests/Tests/Smoke/HarnessSelfCheckTests.swift
  - shared/data-model/schema/PaymentReceiptStatus.yaml
  - apps/ios/BuyLedgerTests/PaymentMethodPersistenceTests.swift
  - apps/ios/BuyLedger/Core/Domain/OrderStatus.swift
  - apps/ios/BuyLedgerUITests/Screens/DashboardScreen.swift
  - apps/ios/BuyLedgerTests/CustomersFeatureTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/quoteViewRateUnavailable.1.png
  - apps/ios/BuyLedgerUITests/Support/AppNavigator.swift
  - apps/ios/BuyLedger/Core/Testing/BLUITestHarness.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Avatar/BLAvatar.swift
  - apps/ios/BuyLedger/Core/Persistence/OrderPersistence.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/Campaign.generated.swift
  - apps/ios/BuyLedgerUITests/Tests/Tools/QuoteTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Campaigns/CampaignDetailTests.swift
  - apps/ios/BuyLedgerTests/OrdersFilterOperationsTests.swift
  - apps/ios/BuyLedger/Shared/Extensions/Decimal+Extensions.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/States/BLLoadFailureView.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderMergeCandidateSheet.swift
  - shared/data-model/fixtures/expected/kotlin/SampleSequence.kt
  - apps/ios/BuyLedger/Resources/GoogleService-Info.example.plist
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFilterSheet.swift
  - apps/ios/BuyLedgerTests/CampaignPersistenceTests.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignSummary.swift
  - apps/ios/BuyLedgerUITests/Screens/CampaignEditScreen.swift
  - apps/ios/BuyLedger/Shared/Localization/AppLanguage.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersView.swift
  - apps/ios/BuyLedger.xcodeproj/xcshareddata/xcschemes/BuyLedger.xcscheme
  - apps/ios/BuyLedgerTests/CurrencyMetadataCacheTests.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/Money.generated.swift
  - CLAUDE.md
  - shared/data-model/fixtures/expected/typescript/SampleQuote.ts
  - apps/ios/BuyLedger/Core/Domain/Generated/OrderStatus.generated.swift
  - shared/data-model/schema/CurrencyCode.yaml
  - apps/ios/BuyLedgerTests/PhotoDataProcessorTests.swift
  - shared/data-model/schema/LedgerOrderItem.yaml
  - apps/ios/BuyLedgerUITests/Tests/Smoke/AppLockTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Smoke/LaunchSmokeTests.swift
  - apps/ios/BuyLedger/Features/Settings/AISummaryModelCatalog.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLTone.swift
  - shared/data-model/fixtures/expected/kotlin/SampleStatus.kt
  - apps/ios/BuyLedger/Features/Orders/OrdersMergeFlowOperations.swift
  - apps/ios/BuyLedger/Core/Networking/HTTPMethod.swift
  - apps/ios/BuyLedgerTests/OrdersFeaturePerformanceTests.swift
  - apps/ios/BuyLedgerUITests/Support/Diagnostics.swift
  - apps/ios/BuyLedgerTests/LayerBoundaryTests.swift
  - apps/ios/BuyLedgerUITests/Support/Waiting.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignFormatters.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderRowView.swift
  - shared/data-model/fixtures/expected/swift/SampleGrade.generated.swift
  - apps/ios/BuyLedger/Core/Networking/HTTPClient.swift
  - apps/ios/BuyLedger/Core/Persistence/CampaignPersistence.swift
  - apps/ios/BuyLedgerTests/LocalizationCatalogTests.swift
  - apps/ios/BuyLedgerTests/ColorContrast.swift
  - apps/ios/BuyLedger/Core/Sync/SyncQueueItem.swift
  - apps/ios/BuyLedgerUITests.xctestplan
  - apps/ios/BuyLedgerUITests/Screens/RootNavigationScreen.swift
  - apps/ios/BuyLedger/Features/App/PersistenceFailureFeature.swift
  - apps/ios/BuyLedgerTests/OrdersFeatureTests.swift
  - apps/ios/BuyLedgerTests/TestDependencies.swift
  - apps/ios/BuyLedgerUITests/Screens/MergeFlowScreen.swift
  - apps/ios/BuyLedger/Core/Dependencies/BiometricAuthClient.swift
  - apps/ios/BuyLedger/Features/AISummary/AISummaryView.swift
  - apps/ios/BuyLedger/Core/Diagnostics/CrashDiagnosticsClient.swift
  - apps/ios/BuyLedgerTests/HTTPClientTests.swift
  - shared/data-model/fixtures/expected/kotlin/SampleReceipt.kt
tests:
  - shared/data-model/generator/test/datamodel-gen.test.ts
-->

---
### Requirement: Lookup data has a single source shared by every consumer

The four lookup kinds — order source, category, payment method, and reconciliation status — SHALL be held in one store shared by every consumer, rather than copied into each feature that reads them. A consumer SHALL derive its view of a lookup kind from that store rather than maintaining its own collection.

Adding, renaming, or deleting a lookup item SHALL update the shared lookup store, and therefore every list derived from it (the management list and the order editor's selectable values), within the same state update once its write succeeds, without requiring a separate action or a root-level interception to propagate it to those lists. The in-memory orders are not derived from the shared lookup store; when a rename must rewrite them, that rewrite is the root feature's response to the management feature's delegate action, as described below.

Consistency SHALL NOT depend on hand-written synchronization between copies. Where a lookup change must also rewrite orders held in memory, the management feature SHALL report the completed change to the root feature through a delegate action carrying the old and new names, and the root feature SHALL rewrite the in-memory orders in response to that delegate action, so that a derived list that unions lookup values with values used by orders never contains the old name once the rename has completed.

#### Scenario: Renaming reaches every consumer once the write succeeds

- **WHEN** a lookup item of any kind is renamed and the write succeeds
- **THEN** the management list and the order editor's selectable values for that kind are updated in the same state update, and the orders referencing the old value are rewritten by the root feature when it receives the management feature's rename delegate action

##### Example: renaming a category

- **GIVEN** the categories are ["美妝", "服飾"] and an in-memory order has categories ["美妝"]
- **WHEN** the user renames "美妝" to "彩妝保養" and the write succeeds
- **THEN** the categories become ["服飾", "彩妝保養"], the management feature emits a delegate action carrying "美妝" and "彩妝保養", and after the root feature handles it the order has categories ["彩妝保養"]

#### Scenario: A rename never leaves the old name reachable

- **WHEN** a lookup item is renamed and a selectable list unions lookup values with values already used by orders
- **THEN** that list does not contain the old name once the root feature has handled the rename delegate action

#### Scenario: A failed rename rewrites no orders

- **WHEN** a rename is rejected by the store
- **THEN** no rename delegate action is emitted and the in-memory orders still reference the old name

#### Scenario: Adding inside the order editor is visible in management

- **WHEN** the user adds a lookup item from within the order editor
- **THEN** the item appears on that kind's management screen without relaunching the app

#### Scenario: Deleting removes the value from every consumer

- **WHEN** a lookup item is deleted and the write succeeds
- **THEN** the order editor no longer offers it as a selectable value


<!-- @trace
source: lookups-style-compliance
updated: 2026-09-25
code:
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Lookups/lookupManagementEmptyBaseline.1.png
  - apps/ios/BuyLedger/Features/Lookups/LookupItemRename.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementView.swift
  - apps/ios/BuyLedgerTests/ActionGroupingScanTests.swift
  - apps/ios/BuyLedgerTests/LookupManagementFeatureTests+AlertTiming.swift
  - apps/ios/BuyLedgerTests/OrderPersistenceTests.swift
  - apps/ios/BuyLedger/Features/Lookups/Components/LookupItemList.swift
  - apps/ios/BuyLedger/Core/Dependencies/OrderRepository.swift
  - apps/ios/BuyLedgerTests/SnapshotTests+Lookups.swift
  - apps/ios/BuyLedger/Features/Lookups/PaymentMethodEditFormFeature.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupItemOperations.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestConfiguration.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupNameEditorSheet.swift
  - apps/ios/BuyLedger.xcodeproj/project.pbxproj
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Lookups/moreViewMissingLookupManagementShowsUnavailableBaseline.1.png
  - apps/ios/BuyLedgerTests/LookupManagementFeatureTests+Failures.swift
  - apps/ios/BuyLedger/Core/Persistence/NameLookupPersistence.swift
  - apps/ios/BuyLedgerTests/LookupManagementFeatureTests+Forms.swift
  - apps/ios/BuyLedger/Core/Persistence/PaymentMethodPersistence.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Lookups/lookupNameEditorSheetRenameBaseline.1.png
  - apps/ios/BuyLedgerTests/BLUITestConfigurationTests.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift
  - apps/ios/BuyLedger/Core/Persistence/LookupRecordRenamer.swift
  - apps/ios/BuyLedgerTests/OrderPersistenceTests+LookupRenameFailures.swift
  - apps/ios/BuyLedger/Features/App/RootFeature.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupKind.swift
  - apps/ios/BuyLedgerTests/LookupManagementFeatureTests+PaymentMethodCorrection.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Lookups/lookupManagementLoadFailureBaseline.1.png
  - apps/ios/BuyLedgerTests/LookupCatalog+TestIsolation.swift
  - apps/ios/BuyLedgerUITests/Screens/LookupManagementScreen.swift
  - apps/ios/BuyLedger/Features/App/RootSidebarLayout.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupAddFormFeature.swift
  - apps/ios/BuyLedgerTests/LookupManagementFeatureTests+Support.swift
  - apps/ios/BuyLedger/Features/Lookups/SharedKey+LookupCatalog.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestDependencyOverrides.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Lookups/lookupManagementCategoryBaseline.1.png
  - apps/ios/CLAUDE.md
  - apps/ios/BuyLedger/Features/Lookups/PaymentMethodCorrectionFeature.swift
  - apps/ios/BuyLedgerTests/OrderPersistence+LookupTesting.swift
  - apps/ios/BuyLedgerAccessibilityIDs/BLAccessibilityID.swift
  - apps/ios/BuyLedgerTests/PaymentMethodCorrectionFeatureTests.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupRenameFormFeature.swift
  - apps/ios/BuyLedgerTests/LocalizationCatalogTests.swift
  - apps/ios/BuyLedgerTests/LookupManagementFeatureTests.swift
  - apps/ios/BuyLedgerUITests/Tests/More/LookupManagementTests.swift
  - apps/ios/BuyLedgerTests/LookupCatalogTests.swift
  - apps/ios/README.md
  - apps/ios/BuyLedger/Core/Persistence/OrderPersistence.swift
  - apps/ios/BuyLedger/Features/Lookups/PaymentMethodEditPlan.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature+Destination.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupItemAddition.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupCatalog.swift
  - apps/ios/BuyLedgerUITests/Support/LaunchOptions.swift
  - apps/ios/BuyLedger/Features/Lookups/Components/LookupItemRow.swift
  - apps/ios/BuyLedgerTests/OrderPersistenceTests+LookupRename.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Lookups/lookupManagementPaymentMethodBaseline.1.png
  - apps/ios/BuyLedgerTests/ActionGroupingScanTests+Scenarios.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementDestination.swift
-->

---
### Requirement: Adding a lookup kind is a compile-time obligation

The differences between lookup kinds — how an order references a value of that kind, and how an order is rewritten when that value is renamed — SHALL be expressed on the lookup-kind type itself as exhaustive mappings, so that introducing a new kind fails to compile until those differences are supplied.

Consumers SHALL NOT branch on lookup kind to perform these operations; they SHALL delegate to the kind. Introducing a new kind SHALL NOT require adding a parallel property, action case, or scope in the root feature.

Which storage each lookup kind reads and writes SHALL be dispatched in one place inside the lookups feature, as an exhaustive mapping over the kinds, so that the management feature itself does not repeat a branch over the kinds for each operation.

#### Scenario: A new kind does not compile until its differences are supplied

- **WHEN** a new lookup kind is added to the lookup-kind type
- **THEN** compilation fails until that kind supplies how orders reference it, how orders are rewritten on rename, and which storage it reads and writes

#### Scenario: Compilation errors are confined to the lookups feature

- **WHEN** a new lookup kind is added and the project is built
- **THEN** the errors appear only in files of the lookups feature (the lookup-kind type, the shared lookup store, the single storage dispatch, and the management view's per-kind rename title), not in the root feature or the orders feature

#### Scenario: Cascade contains no per-kind branching at the call site

- **WHEN** the cascade that rewrites orders after a rename is inspected
- **THEN** it delegates to the lookup kind and contains no branch over the set of kinds


<!-- @trace
source: lookups-style-compliance
updated: 2026-09-25
code:
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Lookups/lookupManagementEmptyBaseline.1.png
  - apps/ios/BuyLedger/Features/Lookups/LookupItemRename.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementView.swift
  - apps/ios/BuyLedgerTests/ActionGroupingScanTests.swift
  - apps/ios/BuyLedgerTests/LookupManagementFeatureTests+AlertTiming.swift
  - apps/ios/BuyLedgerTests/OrderPersistenceTests.swift
  - apps/ios/BuyLedger/Features/Lookups/Components/LookupItemList.swift
  - apps/ios/BuyLedger/Core/Dependencies/OrderRepository.swift
  - apps/ios/BuyLedgerTests/SnapshotTests+Lookups.swift
  - apps/ios/BuyLedger/Features/Lookups/PaymentMethodEditFormFeature.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupItemOperations.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestConfiguration.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupNameEditorSheet.swift
  - apps/ios/BuyLedger.xcodeproj/project.pbxproj
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Lookups/moreViewMissingLookupManagementShowsUnavailableBaseline.1.png
  - apps/ios/BuyLedgerTests/LookupManagementFeatureTests+Failures.swift
  - apps/ios/BuyLedger/Core/Persistence/NameLookupPersistence.swift
  - apps/ios/BuyLedgerTests/LookupManagementFeatureTests+Forms.swift
  - apps/ios/BuyLedger/Core/Persistence/PaymentMethodPersistence.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Lookups/lookupNameEditorSheetRenameBaseline.1.png
  - apps/ios/BuyLedgerTests/BLUITestConfigurationTests.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift
  - apps/ios/BuyLedger/Core/Persistence/LookupRecordRenamer.swift
  - apps/ios/BuyLedgerTests/OrderPersistenceTests+LookupRenameFailures.swift
  - apps/ios/BuyLedger/Features/App/RootFeature.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupKind.swift
  - apps/ios/BuyLedgerTests/LookupManagementFeatureTests+PaymentMethodCorrection.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Lookups/lookupManagementLoadFailureBaseline.1.png
  - apps/ios/BuyLedgerTests/LookupCatalog+TestIsolation.swift
  - apps/ios/BuyLedgerUITests/Screens/LookupManagementScreen.swift
  - apps/ios/BuyLedger/Features/App/RootSidebarLayout.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupAddFormFeature.swift
  - apps/ios/BuyLedgerTests/LookupManagementFeatureTests+Support.swift
  - apps/ios/BuyLedger/Features/Lookups/SharedKey+LookupCatalog.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestDependencyOverrides.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Lookups/lookupManagementCategoryBaseline.1.png
  - apps/ios/CLAUDE.md
  - apps/ios/BuyLedger/Features/Lookups/PaymentMethodCorrectionFeature.swift
  - apps/ios/BuyLedgerTests/OrderPersistence+LookupTesting.swift
  - apps/ios/BuyLedgerAccessibilityIDs/BLAccessibilityID.swift
  - apps/ios/BuyLedgerTests/PaymentMethodCorrectionFeatureTests.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupRenameFormFeature.swift
  - apps/ios/BuyLedgerTests/LocalizationCatalogTests.swift
  - apps/ios/BuyLedgerTests/LookupManagementFeatureTests.swift
  - apps/ios/BuyLedgerUITests/Tests/More/LookupManagementTests.swift
  - apps/ios/BuyLedgerTests/LookupCatalogTests.swift
  - apps/ios/README.md
  - apps/ios/BuyLedger/Core/Persistence/OrderPersistence.swift
  - apps/ios/BuyLedger/Features/Lookups/PaymentMethodEditPlan.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature+Destination.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupItemAddition.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupCatalog.swift
  - apps/ios/BuyLedgerUITests/Support/LaunchOptions.swift
  - apps/ios/BuyLedger/Features/Lookups/Components/LookupItemRow.swift
  - apps/ios/BuyLedgerTests/OrderPersistenceTests+LookupRename.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Lookups/lookupManagementPaymentMethodBaseline.1.png
  - apps/ios/BuyLedgerTests/ActionGroupingScanTests+Scenarios.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementDestination.swift
-->

---
### Requirement: Payment method classification lookup tolerates duplicate names

The payment method classification shown on the management screen and used to pre-fill the payment method editor SHALL be read through a single lookup by name on the shared lookup store. The lookup SHALL NOT assume that payment method names are unique, because the store has no uniqueness constraint; when several entries share a name, it SHALL use the first entry in the stored order. A name with no entry SHALL read as having no classification flags set.

#### Scenario: Duplicate payment method names do not terminate the screen

- **WHEN** the stored payment methods contain two entries with the same name
- **THEN** the management screen lists the payment methods and shows the classification badges of the first entry for that name, without terminating

##### Example: classification lookup by name

| Stored entries (in order) | Looked-up name | Flags read |
| ------------------------- | -------------- | ---------- |
| 匯款 (bank transfer), 匯款 (cardless) | 匯款 | bank transfer only |
| 信用卡 (none) | 信用卡 | none |
| 信用卡 (none) | 貨到付款 | none |

<!-- @trace
source: lookups-style-compliance
updated: 2026-09-25
code:
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Lookups/lookupManagementEmptyBaseline.1.png
  - apps/ios/BuyLedger/Features/Lookups/LookupItemRename.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementView.swift
  - apps/ios/BuyLedgerTests/ActionGroupingScanTests.swift
  - apps/ios/BuyLedgerTests/LookupManagementFeatureTests+AlertTiming.swift
  - apps/ios/BuyLedgerTests/OrderPersistenceTests.swift
  - apps/ios/BuyLedger/Features/Lookups/Components/LookupItemList.swift
  - apps/ios/BuyLedger/Core/Dependencies/OrderRepository.swift
  - apps/ios/BuyLedgerTests/SnapshotTests+Lookups.swift
  - apps/ios/BuyLedger/Features/Lookups/PaymentMethodEditFormFeature.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupItemOperations.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestConfiguration.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupNameEditorSheet.swift
  - apps/ios/BuyLedger.xcodeproj/project.pbxproj
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Lookups/moreViewMissingLookupManagementShowsUnavailableBaseline.1.png
  - apps/ios/BuyLedgerTests/LookupManagementFeatureTests+Failures.swift
  - apps/ios/BuyLedger/Core/Persistence/NameLookupPersistence.swift
  - apps/ios/BuyLedgerTests/LookupManagementFeatureTests+Forms.swift
  - apps/ios/BuyLedger/Core/Persistence/PaymentMethodPersistence.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Lookups/lookupNameEditorSheetRenameBaseline.1.png
  - apps/ios/BuyLedgerTests/BLUITestConfigurationTests.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift
  - apps/ios/BuyLedger/Core/Persistence/LookupRecordRenamer.swift
  - apps/ios/BuyLedgerTests/OrderPersistenceTests+LookupRenameFailures.swift
  - apps/ios/BuyLedger/Features/App/RootFeature.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupKind.swift
  - apps/ios/BuyLedgerTests/LookupManagementFeatureTests+PaymentMethodCorrection.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Lookups/lookupManagementLoadFailureBaseline.1.png
  - apps/ios/BuyLedgerTests/LookupCatalog+TestIsolation.swift
  - apps/ios/BuyLedgerUITests/Screens/LookupManagementScreen.swift
  - apps/ios/BuyLedger/Features/App/RootSidebarLayout.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupAddFormFeature.swift
  - apps/ios/BuyLedgerTests/LookupManagementFeatureTests+Support.swift
  - apps/ios/BuyLedger/Features/Lookups/SharedKey+LookupCatalog.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestDependencyOverrides.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Lookups/lookupManagementCategoryBaseline.1.png
  - apps/ios/CLAUDE.md
  - apps/ios/BuyLedger/Features/Lookups/PaymentMethodCorrectionFeature.swift
  - apps/ios/BuyLedgerTests/OrderPersistence+LookupTesting.swift
  - apps/ios/BuyLedgerAccessibilityIDs/BLAccessibilityID.swift
  - apps/ios/BuyLedgerTests/PaymentMethodCorrectionFeatureTests.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupRenameFormFeature.swift
  - apps/ios/BuyLedgerTests/LocalizationCatalogTests.swift
  - apps/ios/BuyLedgerTests/LookupManagementFeatureTests.swift
  - apps/ios/BuyLedgerUITests/Tests/More/LookupManagementTests.swift
  - apps/ios/BuyLedgerTests/LookupCatalogTests.swift
  - apps/ios/README.md
  - apps/ios/BuyLedger/Core/Persistence/OrderPersistence.swift
  - apps/ios/BuyLedger/Features/Lookups/PaymentMethodEditPlan.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature+Destination.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupItemAddition.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupCatalog.swift
  - apps/ios/BuyLedgerUITests/Support/LaunchOptions.swift
  - apps/ios/BuyLedger/Features/Lookups/Components/LookupItemRow.swift
  - apps/ios/BuyLedgerTests/OrderPersistenceTests+LookupRename.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Lookups/lookupManagementPaymentMethodBaseline.1.png
  - apps/ios/BuyLedgerTests/ActionGroupingScanTests+Scenarios.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementDestination.swift
-->