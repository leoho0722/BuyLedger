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

The orders recomputed SHALL be the stored orders that use the payment method when the write runs, read inside the same transaction as the lookup update, so that the recomputation never overwrites an order with values read earlier and does not depend on whether the orders have been loaded into memory. Once the write succeeds, every in-memory order among them SHALL be replaced with the order that write produced.

Because recomputation rewrites stored values of existing orders and cannot be undone, it SHALL be confirmed before it runs. The confirmation SHALL state how many stored orders use the payment method when the edit is requested. Declining SHALL leave both the orders and the lookup flags unchanged, so that the lookup and the orders never disagree. An edit that leaves the flags unchanged, or that no stored order uses, SHALL be written without confirmation.

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

#### Scenario: Recomputation reads the orders stored when the write runs

- **WHEN** the user confirms a flag change on a payment method
- **THEN** the orders recomputed are the stored orders using that payment method at the time of the write, including any that are not held in memory

##### Example: orders not yet loaded into memory

- **GIVEN** stored orders A and B use "信用卡", 信用卡 has no flags set, and the in-memory orders are empty because loading has not finished
- **WHEN** the user sets the cash-on-delivery flag on 信用卡, the confirmation states 2 orders, and the user confirms
- **THEN** stored orders A and B are both recomputed with cash-on-delivery applied, and 信用卡 has the cash-on-delivery flag


<!-- @trace
source: service-ownership-alignment
updated: 2026-10-17
code:
  - apps/ios/BuyLedger/Features/Orders/Components/OrderDetailNotesView.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignListFeature.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderEditPaymentSection.swift
  - apps/ios/BuyLedger/Core/Dependencies/PaymentMethodService+Dependency.swift
  - apps/ios/BuyLedger/Core/Dependencies/PaymentMethodService.swift
  - apps/ios/BuyLedgerTests/CampaignWritesFeatureTests+Save.swift
  - apps/ios/BuyLedgerTests/LookupServiceTests+ReconciliationStatuses.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+LookupCatalogFailures.swift
  - apps/ios/BuyLedgerTests/OrderServiceTests+Merge.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+LookupCatalogAdditionFixtures.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoThumbnail.swift
  - apps/ios/BuyLedgerTests/ServiceOwnershipScanTests+LookupCatalogCases.swift
  - apps/ios/BuyLedgerTests/CampaignFeatureTests+DeletionReminder.swift
  - apps/ios/BuyLedgerTests/OrdersFeatureTests+StatusFailures.swift
  - apps/ios/BuyLedger/Features/Campaigns/Data/CampaignReminderService+Dependency.swift
  - apps/ios/BuyLedgerTests/CampaignIntegrationTests+Delete.swift
  - apps/ios/BuyLedgerTests/CampaignReminderFeatureTests+Removal.swift
  - apps/ios/BuyLedger/Features/App/RootFeature.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardSummarySection.swift
  - apps/ios/BuyLedger/Features/Orders/OrderEditPickerOperations.swift
  - apps/ios/BuyLedgerTests/CampaignIntegrationTests+Rename.swift
  - apps/ios/BuyLedgerTests/LookupServiceTests+RenameSupport.swift
  - apps/ios/BuyLedgerTests/OrderWritesFeatureTests+Options.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLListMetrics.swift
  - apps/ios/BuyLedgerTests/DependencyConventionScanScenario.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsCampaignProfitCard.swift
  - apps/ios/BuyLedgerTests/FxFormattersTests.swift
  - apps/ios/BuyLedger/Features/Lookups/Components/LookupItemRow.swift
  - apps/ios/BuyLedgerTests/CampaignFeatureTests+FailureTimingFollowUp.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Shared/aiSummaryView_總結失敗_顯示重試鈕.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Shared/paymentMethodEditorSheet_編輯既有付款方式_顯示三種旗標.1.png
  - apps/ios/BuyLedgerTests/OrdersPresentationFeatureTests.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderDetailSummaryView.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersRegularDetailColumn.swift
  - apps/ios/BuyLedger/Core/Dependencies/OrderService+Reads.swift
  - apps/ios/BuyLedgerTests/OrderServiceTests+BatchWrites.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLMetrics.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFilterDateSection.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+LookupRename.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardOngoingCampaignsSection.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+LookupCatalogAdditionForms.swift
  - apps/ios/BuyLedgerTests/LookupCatalogFeatureTests+Additions.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests.swift
  - apps/ios/BuyLedger/Features/Customers/Components/CustomerListRow.swift
  - apps/ios/BuyLedgerTests/OrderServiceTests+MergeFailureMapping.swift
  - apps/ios/BuyLedger/Core/Dependencies/OrderService+Writes.swift
  - apps/ios/BuyLedgerTests/InsightsFeatureTests+ScreenState.swift
  - apps/ios/BuyLedger/Features/AISummary/AISummaryView.swift
  - apps/ios/BuyLedgerTests/OrderEditOptionsTests.swift
  - apps/ios/BuyLedger/Features/Orders/OrderPercentConversion.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrderMerge/orderMergeCandidateSheet_無可合併訂單_顯示空狀態.1.png
  - apps/ios/BuyLedger/Features/FX/FxFeature.swift
  - apps/ios/BuyLedgerTests/CampaignServiceTests.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+LookupCatalogRequests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLRadius.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderEditPercentField.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+SharedOrders.swift
  - apps/ios/BuyLedger/Core/Persistence/OrderPersistenceError.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrdersCompactListView.swift
  - apps/ios/BuyLedger/Features/Orders/Data/OrderService+Writes.swift
  - apps/ios/BuyLedgerTests/LookupServiceTests+PaymentMethods.swift
  - apps/ios/BuyLedgerTests/OrdersContainerPlanTests+Presentation.swift
  - apps/ios/BuyLedgerTests/OrderSourceServiceTests.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersWriteOutcome.swift
  - apps/ios/BuyLedgerTests/PaymentMethodCorrectionFeatureTests+Confirmation.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsView.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementView.swift
  - apps/ios/BuyLedgerTests/LookupServiceTests+PaymentMethodEdits.swift
  - apps/ios/BuyLedger/Features/Campaigns/Data/CampaignService.swift
  - apps/ios/BuyLedgerTests/OrderServiceTests+Renames.swift
  - apps/ios/BuyLedgerTests/DashboardFeatureTests.swift
  - apps/ios/BuyLedgerTests/CampaignReminderFeatureTests+Failures.swift
  - apps/ios/BuyLedgerTests/InsightsFeatureTests.swift
  - apps/ios/BuyLedger/Features/App/RootSidebarLayout.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardKPITile.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderEditItemsSection.swift
  - apps/ios/BuyLedger/Features/Quote/QuoteRateFeature.swift
  - apps/ios/BuyLedger/Features/Orders/Data/OrderError.swift
  - apps/ios/BuyLedger/Features/Quote/Components/QuoteInputsCard.swift
  - apps/ios/BuyLedgerTests/OrderServiceTests+RenameNoOps.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+Campaigns.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFilterCategorySection.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsHeatmapCard.swift
  - apps/ios/BuyLedger/Features/Lookups/PaymentMethodEditPlan.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrdersToolbarContent.swift
  - apps/ios/BuyLedgerTests/DashboardFeatureTests+DateContext.swift
  - apps/ios/BuyLedgerTests/LookupManagementFeatureTests+Failures.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Insights/insightsView_已載入無訂單_顯示空狀態.1.png
  - apps/ios/BuyLedgerTests/OrderEditFeatureTests+Categories.swift
  - apps/ios/BuyLedgerTests/AISummaryFeatureTests.swift
  - apps/ios/BuyLedgerTests/DependencyConventionScanTests.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderEditFeesSection.swift
  - apps/ios/BuyLedgerTests/DesignSystemSourceScanTests+ScaledMetricScanner.swift
  - apps/ios/BuyLedgerTests/CampaignServiceTests+Rename.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Shared/aiSummaryView_總結完成_顯示摘要內容.1.png
  - apps/ios/BuyLedger/Features/Dashboard/DashboardFormatters.swift
  - apps/ios/BuyLedger/Core/Dependencies/PaymentMethodService+Preview.swift
  - apps/ios/BuyLedgerTests/QuoteFormattersTests.swift
  - apps/ios/BuyLedgerTests/CampaignServiceTests+Delete.swift
  - apps/ios/BuyLedger/Features/Quote/Components/QuoteBreakdownCard.swift
  - apps/ios/BuyLedger/Features/AISummary/AISummaryFeature.swift
  - apps/ios/BuyLedger/Features/FX/Components/FxRatesList.swift
  - apps/ios/README.md
  - apps/ios/BuyLedgerTests/DesignSystemSourceScanTests+Patterns.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Insights/insightsView_帶開團資料_顯示每團毛利排行卡.1.png
  - apps/ios/BuyLedger/Features/Orders/OrdersFeature.swift
  - apps/ios/BuyLedger/Core/Dependencies/CategoryService.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+More/appLockView_解鎖失敗_顯示失敗訊息與重試鈕.1.png
  - apps/ios/BuyLedgerTests/CampaignFeatureTests+Editing.swift
  - apps/ios/BuyLedger/Features/Orders/Data/OrderService+Dependency.swift
  - apps/ios/BuyLedgerTests/DashboardStatsTests+Progress.swift
  - apps/ios/BuyLedgerTests/LookupServiceTests+PaymentMethodAtomicity.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsStats+Trend.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/Color+Semantic.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFilterPreviewFixtures.swift
  - apps/ios/BuyLedger/Core/Dependencies/OrderService+Dependency.swift
  - apps/ios/CLAUDE.md
  - apps/ios/BuyLedgerTests/QuoteFeatureTests+CurrencyCodes.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+PaymentMethodRename.swift
  - apps/ios/BuyLedger/Features/Campaigns/Components/CampaignDetailDistributionSection.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLDonutChart.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Dashboard/dashboardView_已載入無訂單_顯示首次使用畫面.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrderMerge/orderMergeCandidateSheet_有可合併訂單_顯示候選清單.1.png
  - apps/ios/BuyLedger/Features/Insights/InsightsDateContext.swift
  - apps/ios/BuyLedgerTests/LookupManagementFeatureTests+Forms.swift
  - apps/ios/BuyLedgerTests/ContrastComplianceTests.swift
  - apps/ios/BuyLedgerTests/ServiceOwnershipScanTests+Models.swift
  - apps/ios/BuyLedger/Features/Lookups/Data/LookupService.swift
  - apps/ios/BuyLedger/Shared/Extensions/Color+Extensions.swift
  - apps/ios/BuyLedgerTests/OrdersFeatureTests+FailureTiming.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Customers/customersView_一般客戶資料_顯示名次徽章與排行卡.1.png
  - apps/ios/BuyLedgerTests/OrdersFeatureTests+DeleteEditFailures.swift
  - apps/ios/BuyLedgerTests/PaymentMethodServiceTests+ApplyEdit.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Progress/BLProgressView.swift
  - apps/ios/BuyLedgerTests/ServiceTestValueStrictnessTests.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+FilterPending.swift
  - apps/ios/BuyLedgerTests/OrderWritesFeatureTests+Create.swift
  - apps/ios/BuyLedgerTests/LookupManagementFeatureTests.swift
  - apps/ios/BuyLedgerTests/LookupCatalogFeatureTests.swift
  - apps/ios/BuyLedgerTests/DashboardStatsTests.swift
  - apps/ios/BuyLedgerTests/LookupManagementFeatureTests+PaymentMethodCorrection.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Customers/customersView_無客戶資料_顯示空狀態.1.png
  - apps/ios/BuyLedgerTests/InsightsAttributionTests.swift
  - apps/ios/BuyLedger/Features/Campaigns/Components/CampaignDetailSettlementSection.swift
  - apps/ios/BuyLedgerTests/OrderServiceTests+WriteFailures.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderDetailContentView.swift
  - apps/ios/BuyLedger/Features/Orders/OrderEditOptions.swift
  - apps/ios/BuyLedger/Features/App/AppLockView.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsStats.swift
  - apps/ios/BuyLedger/Features/Campaigns/Data/CampaignService+Reminders.swift
  - apps/ios/BuyLedgerTests/CampaignListFeatureTests+DateContext.swift
  - apps/ios/BuyLedger/Features/Orders/OrderOptionWritePlan.swift
  - apps/ios/BuyLedgerTests/OrdersFeatureTests+OptionWriteFailures.swift
  - apps/ios/BuyLedgerTests/CampaignWritesFeatureTests+Rename.swift
  - apps/ios/BuyLedger/Features/FX/FxView.swift
  - apps/ios/BuyLedgerTests/ServiceOwnershipScanTests.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardView.swift
  - apps/ios/BuyLedger/Features/Customers/Components/CustomerTopCard.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsCategory.swift
  - apps/ios/BuyLedgerTests/LookupServiceTests+RenameFailures.swift
  - apps/ios/BuyLedgerTests/DependencyConventionScanTests+Rules.swift
  - apps/ios/BuyLedger/Features/Lookups/Components/LookupItemList.swift
  - apps/ios/BuyLedger/Features/Campaigns/Data/CampaignReminderService+Preview.swift
  - apps/ios/BuyLedger/Features/Campaigns/Data/CampaignReminderService.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+LookupCatalog.swift
  - apps/ios/BuyLedger/Core/Dependencies/OrderService.swift
  - apps/ios/BuyLedgerTests/ColorContrast.swift
  - apps/ios/BuyLedgerTests/CampaignReminderServiceTests.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+CurrencyCodes.swift
  - apps/ios/BuyLedger/Features/Quote/Components/QuoteStatusBanner.swift
  - apps/ios/BuyLedger/Features/Orders/OrderListFeature.swift
  - apps/ios/BuyLedgerTests/LookupServiceTests+RenameNoOps.swift
  - apps/ios/BuyLedgerTests/OrderServiceTests+Create.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupNameEditorSheet.swift
  - apps/ios/BuyLedger/Features/Lookups/Data/LookupService+PaymentMethods.swift
  - apps/ios/BuyLedgerTests/ReconciliationStatusServiceTests.swift
  - apps/ios/BuyLedger/Features/Campaigns/Data/CampaignService+Dependency.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersCompactView.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersContainerPlan+Writes.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsCostStructureCard.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+More/moreView_預設清單_顯示各入口.1.png
  - apps/ios/BuyLedgerTests/CustomersFeatureTests.swift
  - apps/ios/BuyLedgerTests/InsightsStatsTests+Breakdown.swift
  - apps/ios/BuyLedgerTests/CampaignReminderFeatureTests.swift
  - apps/ios/BuyLedgerTests/CategoryServiceTests.swift
  - apps/ios/BuyLedgerTests/MoreFeatureTests+Relays.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardFeature.swift
  - apps/ios/BuyLedger/App/Testing/DependencyValues+BLUITestLookupOverrides.swift
  - apps/ios/BuyLedgerTests/FxFeatureTests+CurrencyCodes.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+LookupCatalogAdditions.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsTrendBucket.swift
  - apps/ios/BuyLedger/Features/Orders/OrderEditPhotosSection.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignPresentationFeature+Destination.swift
  - apps/ios/BuyLedgerTests/InsightsHeatmapTests.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+OrdersReload.swift
  - apps/ios/BuyLedgerTests/LookupServiceTests.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersRootRequest.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+More/appLockView_生物辨識解鎖_顯示解鎖鈕.1.png
  - apps/ios/BuyLedger/Features/Orders/Components/OrderDetailSourceView.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderEditCampaignSection.swift
  - apps/ios/BuyLedger/Features/Orders/Data/OrderService+Reads.swift
  - apps/ios/BuyLedger/Features/Orders/OrderEditDraftOperations.swift
  - apps/ios/BuyLedger/Features/Lookups/Data/LookupService+Dependency.swift
  - apps/ios/BuyLedger/Core/Dependencies/OrderSourceService+Preview.swift
  - apps/ios/BuyLedger/Core/Dependencies/OrderSourceService.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift
  - apps/ios/BuyLedger/Features/App/PersistenceFailureView.swift
  - apps/ios/BuyLedger/Core/Dependencies/OrderService+Renames.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsView.swift
  - apps/ios/BuyLedgerTests/OrderFilterFeatureTests.swift
  - apps/ios/BuyLedgerTests/StorageFailureWrappingTests.swift
  - apps/ios/BuyLedgerTests/SnapshotTests+Dashboard.swift
  - apps/ios/BuyLedgerTests/OrdersPresentationFeatureTests+Delegate.swift
  - apps/ios/BuyLedgerTests/LookupServiceTests+PaymentMethodFixtures.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLSparkline.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersView.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardStats.swift
  - apps/ios/BuyLedger.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
  - apps/ios/BuyLedgerTests/DependencyConventionScanScenario+ViewCases.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoViewer.swift
  - apps/ios/BuyLedgerTests/OrderServiceTests+RenameSupport.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+PaymentMethodCorrection.swift
  - apps/ios/BuyLedgerTests/DashboardFormattersTests.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+NewOrderOptions.swift
  - apps/ios/BuyLedger/Features/Campaigns/Components/CampaignDetailInfoSection.swift
  - apps/ios/BuyLedgerTests/SnapshotTests+More.swift
  - apps/ios/BuyLedgerTests/DependencyConventionScanTests+TestValueRules.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupCatalogFeature.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderEditPickerDestination.swift
  - apps/ios/BuyLedger/Resources/Localizable.xcstrings
  - apps/ios/BuyLedgerTests/CampaignListFeatureTests+VisibleSections.swift
  - apps/ios/BuyLedgerTests/ServiceOwnershipScanTests+Fixtures.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderDetailItemsView.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsFormatters.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+LookupCatalogFixtures.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+DeepLinks.swift
  - apps/ios/BuyLedgerTests/DashboardFeatureTests+ScreenState.swift
  - apps/ios/BuyLedger/Features/Campaigns/Components/CampaignRow.swift
  - apps/ios/BuyLedgerTests/DesignSystemSourceScanTests.swift
  - apps/ios/BuyLedger/Features/FX/FxFormatters.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderEditCostSection.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersLoadFeature.swift
  - apps/ios/BuyLedgerTests/ServiceOwnershipScanTests+DatabaseCases.swift
  - apps/ios/BuyLedgerTests/ServiceOwnershipScanTests+ReferenceCases.swift
  - apps/ios/BuyLedgerTests/InsightsFeatureTests+DateContext.swift
  - apps/ios/BuyLedger/Features/Quote/QuoteFormatters.swift
  - apps/ios/BuyLedgerTests/LookupServiceTests+PaymentMethodSelection.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+More/settingsView_預設偏好_顯示版本與偏好列.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Insights/insightsView_載入中_顯示載入骨架.1.png
  - apps/ios/BuyLedgerTests/InsightsFormattersTests.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignReminderFeature.swift
  - apps/ios/BuyLedger/Core/Dependencies/CategoryService+Preview.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsTrendCard.swift
  - apps/ios/BuyLedger.xcodeproj/project.pbxproj
  - apps/ios/BuyLedger/Features/Customers/CustomerRank.swift
  - apps/ios/BuyLedgerTests/OrdersLoadFeatureTests+Requests.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignEditView.swift
  - apps/ios/BuyLedgerTests/OrdersFeatureTests+OptionWrites.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderEditBasicSection.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderDetailCostView.swift
  - apps/ios/BuyLedgerTests/CampaignFeatureTests+ReminderIntegration.swift
  - apps/ios/BuyLedgerTests/LookupServiceTests+Renames.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardKPITiles.swift
  - apps/ios/BuyLedgerTests/OrdersFeatureTests+ListRequests.swift
  - apps/ios/BuyLedgerTests/ActionGroupingScanTests+Scenarios.swift
  - apps/ios/BuyLedgerTests/ServiceOwnershipScanTests+Rules.swift
  - apps/ios/BuyLedgerTests/DashboardStatsTests+Fixtures.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersFilterOperations.swift
  - apps/ios/BuyLedgerTests/CampaignIntegrationTests+Receipt.swift
  - apps/ios/BuyLedgerTests/OrderWritesFeatureTests+Merge.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsCategoryCard.swift
  - apps/ios/BuyLedgerTests/SnapshotTests+Customers.swift
  - apps/ios/BuyLedgerTests/CampaignEditFeatureTests.swift
  - apps/ios/BuyLedgerTests/SnapshotTests+Insights.swift
  - apps/ios/BuyLedgerTests/SnapshotTests+Shared.swift
  - apps/ios/BuyLedgerTests/OrderEditCampaignOptionsTests.swift
  - apps/ios/BuyLedger/Features/Quote/QuoteView.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Cards/BLCard.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignWritesFeature.swift
  - apps/ios/BuyLedger/Core/Persistence/PaymentMethodPersistenceError.swift
  - apps/ios/BuyLedgerTests/BLTrendTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLPalette.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/ViewModifiers/BLHeroCardBackground.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardDateContext.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLTrend.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardRecentOrdersSection.swift
  - apps/ios/BuyLedger/Features/Lookups/Data/LookupService+Renames.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+CampaignLoading.swift
  - apps/ios/BuyLedger/Features/Orders/Data/OrderService+Preview.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLBarChart.swift
  - apps/ios/BuyLedger/Core/Dependencies/CategoryService+Dependency.swift
  - apps/ios/BuyLedgerTests/CampaignServiceTests+DeleteFailure.swift
  - apps/ios/BuyLedger/Features/Orders/Components/MergePhotoPickerSheet.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Chips/BLFilterChip.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Tags/BLTagPill.swift
  - apps/ios/BuyLedger/Features/Orders/OrderEditPickersFeature.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Forms/PaymentMethodEditorSheet.swift
  - apps/ios/BuyLedgerTests/DesignSystemSourceScanTests+Scanner.swift
  - apps/ios/BuyLedger/Features/More/MoreView.swift
  - apps/ios/BuyLedgerTests/DependencyConventionScanTests+Scanner.swift
  - apps/ios/BuyLedger/App/Testing/DependencyValues+BLUITestOverrides.swift
  - apps/ios/BuyLedgerTests/LookupServiceTests+Sources.swift
  - apps/ios/BuyLedger/Features/Campaigns/Components/CampaignSectionList.swift
  - apps/ios/BuyLedgerTests/DesignSystemSourceScanTests+ScaledMetric.swift
  - apps/ios/BuyLedger/Features/App/RootNavigationOperations.swift
  - apps/ios/BuyLedgerTests/OrdersContainerPlanTests+Writes.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+Cascade.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersRegularListColumn.swift
  - apps/ios/BuyLedgerTests/OrderEditFeatureTests+Reconciliation.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrderMerge/mergePhotoPickerSheet_七張照片選滿上限_顯示已選與未選照片.1.png
  - apps/ios/BuyLedgerTests/OrderServiceTests+RenameFailures.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Dashboard/dashboardView_載入中_顯示載入骨架.1.png
  - apps/ios/BuyLedgerTests/OrdersFeatureTests+LoadAndSummary.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignListView.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderDetailCardlessView.swift
  - apps/ios/BuyLedgerTests/BuyLedgerDatabaseTests.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignEditFeature.swift
  - apps/ios/BuyLedgerTests/OrdersFeatureTests+Create.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+Fixtures.swift
  - apps/ios/BuyLedgerTests/InsightsStatsTests.swift
  - apps/ios/BuyLedgerTests/DashboardFormattersTests+Summary.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderEditSelectionRow.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+Foreground.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignFormatters.swift
  - apps/ios/BuyLedgerTests/OrdersFeatureTests+SaveFailureTiming.swift
  - apps/ios/BuyLedgerTests/ServiceOwnershipScanTests+Scanner.swift
  - apps/ios/BuyLedgerTests/OrderServiceTests+Concurrency.swift
  - apps/ios/BuyLedger/Features/Lookups/Data/LookupService+Preview.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupAdditionRequest.swift
  - apps/ios/BuyLedger/Features/Orders/OrderWriteOperations.swift
  - apps/ios/BuyLedgerTests/PaymentMethodCorrectionFeatureTests.swift
  - apps/ios/BuyLedger/Core/Dependencies/OrderService+Preview.swift
  - apps/ios/BuyLedger/Core/Dependencies/OrderSourceService+Dependency.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrderMerge/mergePhotoPickerSheet_七張照片只選部分_顯示未選取照片.1.png
  - apps/ios/BuyLedgerTests/CampaignEditFeatureTests+NavigationTitle.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLHitTarget.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsHeatmap.swift
  - apps/ios/BuyLedgerTests/LookupManagementFeatureTests+AlertTiming.swift
  - apps/ios/BuyLedgerTests/OrderPercentConversionTests.swift
  - apps/ios/BuyLedgerTests/ColorContrastTests.swift
  - apps/ios/BuyLedger/Core/Dependencies/ReconciliationStatusService+Dependency.swift
  - apps/ios/BuyLedgerTests/CampaignServiceTests+Reminders.swift
  - apps/ios/BuyLedgerTests/DependencyConventionScanTests+ViewRules.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupItemOperations.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsFeature.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsCostSegment.swift
  - apps/ios/BuyLedgerTests/OrderEditFeatureTests+Campaigns.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Shared/paymentMethodEditorSheet_新增付款方式_顯示空白表單.1.png
  - apps/ios/BuyLedger/Core/Dependencies/ReconciliationStatusService.swift
  - apps/ios/BuyLedger/Core/Dependencies/ReconciliationStatusService+Preview.swift
  - apps/ios/BuyLedgerTests/OrdersLoadStateTests.swift
  - apps/ios/BuyLedger/Features/Lookups/PaymentMethodCorrectionFeature.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderMergeCandidateSheet.swift
  - apps/ios/BuyLedger/Features/Customers/CustomersFeature.swift
  - apps/ios/BuyLedger/Features/Orders/OrderWritesFeature.swift
  - apps/ios/BuyLedger/Features/Customers/CustomerRankBadgeStyle.swift
  - apps/ios/BuyLedgerTests/PaymentMethodServiceTests.swift
  - apps/ios/BuyLedgerTests/OrdersFeatureTests+MergeWrites.swift
  - apps/ios/BuyLedgerTests/CampaignListFeatureTests+RowSummaries.swift
  - apps/ios/BuyLedgerTests/CampaignReminderFeatureTests+Rebuild.swift
  - apps/ios/BuyLedgerTests/SnapshotTests+CampaignDetail.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFilterPaymentMethodSection.swift
  - apps/ios/BuyLedgerTests/CampaignFeatureTests+NameConflict.swift
  - apps/ios/BuyLedgerTests/CustomerFormattersTests.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderSelectableRow.swift
  - apps/ios/BuyLedgerTests/CampaignFeatureTests+ReminderRename.swift
  - apps/ios/BuyLedgerTests/DashboardStatsTests+Comparison.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+LoadRequests.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+OrderFilters.swift
  - apps/ios/BuyLedger/Features/FX/Components/FxStatusBanner.swift
  - apps/ios/BuyLedger/Features/Customers/CustomersView.swift
  - apps/ios/BuyLedger/Features/More/MoreFeature.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Progress/BLProgressViewStyle.swift
  - apps/ios/BuyLedgerTests/OrderServiceResidueTests.swift
  - apps/ios/BuyLedger/Features/Customers/CustomerFormatters.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersPresentationFeature.swift
  - apps/ios/BuyLedgerTests/OrdersFeatureTests.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+LookupSync.swift
  - apps/ios/BuyLedgerTests/CampaignFormattersTests.swift
  - apps/ios/BuyLedger/Features/Orders/OrderEditFeature.swift
  - apps/ios/BuyLedgerTests/OrdersLoadFeatureTests.swift
  - apps/ios/BuyLedger/Features/Insights/CampaignProfitRank.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsDateRange.swift
  - apps/ios/BuyLedger/Features/Orders/Components/MergePhotoTile.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Buttons/BLButtonStyle.swift
  - apps/ios/BuyLedgerTests/InsightsStatsTests+Fixtures.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderRowView.swift
  - apps/ios/BuyLedgerTests/SnapshotTests+OrderMerge.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLSpacing.swift
  - apps/ios/BuyLedgerTests/SnapshotTests+OrdersBaseline.swift
  - apps/ios/BuyLedgerTests/LookupManagementFeatureTests+PaymentMethodStoredOrders.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardHeroCard.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+More/settingsView_開啟AI摘要與生物辨識_顯示對應列.1.png
  - apps/ios/BuyLedgerTests/CampaignIntegrationTests+Navigation.swift
  - apps/ios/BuyLedgerTests/OrderEditPickersFeatureTests.swift
  - apps/ios/BuyLedger/Features/Orders/Data/OrderService.swift
-->

---
### Requirement: Lookup data has a single source shared by every consumer

The four lookup kinds — order source, category, payment method, and reconciliation status — SHALL be held in one store shared by every consumer, rather than copied into each feature that reads them. A consumer SHALL derive its view of a lookup kind from that store rather than maintaining its own collection.

Only the lookup side SHALL write the shared lookup store: the management screens and a lookup catalog feature that has no view of its own. The catalog feature SHALL store an option that the order editor adds, and SHALL read the four kinds from storage before the orders are loaded: every request to load the orders, at launch or from a retry, SHALL first ask the catalog feature, which reads the four kinds unless it has already read all of them successfully, and the orders SHALL be loaded once it has finished. A kind whose read fails SHALL keep its previous values, and the orders SHALL still be loaded afterwards. Order features SHALL hold the shared lookup store read-only and SHALL NOT read or write lookup storage themselves.

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

#### Scenario: The lookup catalog is read before the orders load

- **WHEN** the orders are requested to load, at launch or from a retry
- **THEN** the lookup catalog feature finishes reading the four lookup kinds from storage, or confirms it already has all of them, before the orders are loaded, and the order loading reads only the orders

##### Example: categories available in the first editor opened

- **GIVEN** the stored categories are ["服飾", "美妝"]
- **WHEN** the app launches and the user opens a new order editor as soon as the orders have loaded, without visiting the categories management screen
- **THEN** the editor's category list contains 服飾 and 美妝

##### Example: one kind fails to read

| Before the read | Read results | After the read |
| --------------- | ------------ | -------------- |
| categories [], payment methods [] | categories ["服飾"] succeeds, payment methods fails | categories ["服飾"], payment methods [], the orders are loaded, and the next orders load request reads the four kinds again |
| categories ["服飾"], payment methods ["信用卡"] after all four kinds were read successfully | no read runs | unchanged, and the orders are loaded |

#### Scenario: Order features cannot write the lookup store

- **WHEN** the order features are inspected
- **THEN** they declare the shared lookup store read-only and do not obtain the lookup service

#### Scenario: Deleting removes the value from every consumer

- **WHEN** a lookup item is deleted and the write succeeds
- **THEN** the order editor no longer offers it as a selectable value


<!-- @trace
source: service-ownership-alignment
updated: 2026-10-17
code:
  - apps/ios/BuyLedger/Features/Orders/Components/OrderDetailNotesView.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignListFeature.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderEditPaymentSection.swift
  - apps/ios/BuyLedger/Core/Dependencies/PaymentMethodService+Dependency.swift
  - apps/ios/BuyLedger/Core/Dependencies/PaymentMethodService.swift
  - apps/ios/BuyLedgerTests/CampaignWritesFeatureTests+Save.swift
  - apps/ios/BuyLedgerTests/LookupServiceTests+ReconciliationStatuses.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+LookupCatalogFailures.swift
  - apps/ios/BuyLedgerTests/OrderServiceTests+Merge.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+LookupCatalogAdditionFixtures.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoThumbnail.swift
  - apps/ios/BuyLedgerTests/ServiceOwnershipScanTests+LookupCatalogCases.swift
  - apps/ios/BuyLedgerTests/CampaignFeatureTests+DeletionReminder.swift
  - apps/ios/BuyLedgerTests/OrdersFeatureTests+StatusFailures.swift
  - apps/ios/BuyLedger/Features/Campaigns/Data/CampaignReminderService+Dependency.swift
  - apps/ios/BuyLedgerTests/CampaignIntegrationTests+Delete.swift
  - apps/ios/BuyLedgerTests/CampaignReminderFeatureTests+Removal.swift
  - apps/ios/BuyLedger/Features/App/RootFeature.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardSummarySection.swift
  - apps/ios/BuyLedger/Features/Orders/OrderEditPickerOperations.swift
  - apps/ios/BuyLedgerTests/CampaignIntegrationTests+Rename.swift
  - apps/ios/BuyLedgerTests/LookupServiceTests+RenameSupport.swift
  - apps/ios/BuyLedgerTests/OrderWritesFeatureTests+Options.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLListMetrics.swift
  - apps/ios/BuyLedgerTests/DependencyConventionScanScenario.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsCampaignProfitCard.swift
  - apps/ios/BuyLedgerTests/FxFormattersTests.swift
  - apps/ios/BuyLedger/Features/Lookups/Components/LookupItemRow.swift
  - apps/ios/BuyLedgerTests/CampaignFeatureTests+FailureTimingFollowUp.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Shared/aiSummaryView_總結失敗_顯示重試鈕.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Shared/paymentMethodEditorSheet_編輯既有付款方式_顯示三種旗標.1.png
  - apps/ios/BuyLedgerTests/OrdersPresentationFeatureTests.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderDetailSummaryView.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersRegularDetailColumn.swift
  - apps/ios/BuyLedger/Core/Dependencies/OrderService+Reads.swift
  - apps/ios/BuyLedgerTests/OrderServiceTests+BatchWrites.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLMetrics.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFilterDateSection.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+LookupRename.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardOngoingCampaignsSection.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+LookupCatalogAdditionForms.swift
  - apps/ios/BuyLedgerTests/LookupCatalogFeatureTests+Additions.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests.swift
  - apps/ios/BuyLedger/Features/Customers/Components/CustomerListRow.swift
  - apps/ios/BuyLedgerTests/OrderServiceTests+MergeFailureMapping.swift
  - apps/ios/BuyLedger/Core/Dependencies/OrderService+Writes.swift
  - apps/ios/BuyLedgerTests/InsightsFeatureTests+ScreenState.swift
  - apps/ios/BuyLedger/Features/AISummary/AISummaryView.swift
  - apps/ios/BuyLedgerTests/OrderEditOptionsTests.swift
  - apps/ios/BuyLedger/Features/Orders/OrderPercentConversion.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrderMerge/orderMergeCandidateSheet_無可合併訂單_顯示空狀態.1.png
  - apps/ios/BuyLedger/Features/FX/FxFeature.swift
  - apps/ios/BuyLedgerTests/CampaignServiceTests.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+LookupCatalogRequests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLRadius.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderEditPercentField.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+SharedOrders.swift
  - apps/ios/BuyLedger/Core/Persistence/OrderPersistenceError.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrdersCompactListView.swift
  - apps/ios/BuyLedger/Features/Orders/Data/OrderService+Writes.swift
  - apps/ios/BuyLedgerTests/LookupServiceTests+PaymentMethods.swift
  - apps/ios/BuyLedgerTests/OrdersContainerPlanTests+Presentation.swift
  - apps/ios/BuyLedgerTests/OrderSourceServiceTests.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersWriteOutcome.swift
  - apps/ios/BuyLedgerTests/PaymentMethodCorrectionFeatureTests+Confirmation.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsView.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementView.swift
  - apps/ios/BuyLedgerTests/LookupServiceTests+PaymentMethodEdits.swift
  - apps/ios/BuyLedger/Features/Campaigns/Data/CampaignService.swift
  - apps/ios/BuyLedgerTests/OrderServiceTests+Renames.swift
  - apps/ios/BuyLedgerTests/DashboardFeatureTests.swift
  - apps/ios/BuyLedgerTests/CampaignReminderFeatureTests+Failures.swift
  - apps/ios/BuyLedgerTests/InsightsFeatureTests.swift
  - apps/ios/BuyLedger/Features/App/RootSidebarLayout.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardKPITile.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderEditItemsSection.swift
  - apps/ios/BuyLedger/Features/Quote/QuoteRateFeature.swift
  - apps/ios/BuyLedger/Features/Orders/Data/OrderError.swift
  - apps/ios/BuyLedger/Features/Quote/Components/QuoteInputsCard.swift
  - apps/ios/BuyLedgerTests/OrderServiceTests+RenameNoOps.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+Campaigns.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFilterCategorySection.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsHeatmapCard.swift
  - apps/ios/BuyLedger/Features/Lookups/PaymentMethodEditPlan.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrdersToolbarContent.swift
  - apps/ios/BuyLedgerTests/DashboardFeatureTests+DateContext.swift
  - apps/ios/BuyLedgerTests/LookupManagementFeatureTests+Failures.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Insights/insightsView_已載入無訂單_顯示空狀態.1.png
  - apps/ios/BuyLedgerTests/OrderEditFeatureTests+Categories.swift
  - apps/ios/BuyLedgerTests/AISummaryFeatureTests.swift
  - apps/ios/BuyLedgerTests/DependencyConventionScanTests.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderEditFeesSection.swift
  - apps/ios/BuyLedgerTests/DesignSystemSourceScanTests+ScaledMetricScanner.swift
  - apps/ios/BuyLedgerTests/CampaignServiceTests+Rename.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Shared/aiSummaryView_總結完成_顯示摘要內容.1.png
  - apps/ios/BuyLedger/Features/Dashboard/DashboardFormatters.swift
  - apps/ios/BuyLedger/Core/Dependencies/PaymentMethodService+Preview.swift
  - apps/ios/BuyLedgerTests/QuoteFormattersTests.swift
  - apps/ios/BuyLedgerTests/CampaignServiceTests+Delete.swift
  - apps/ios/BuyLedger/Features/Quote/Components/QuoteBreakdownCard.swift
  - apps/ios/BuyLedger/Features/AISummary/AISummaryFeature.swift
  - apps/ios/BuyLedger/Features/FX/Components/FxRatesList.swift
  - apps/ios/README.md
  - apps/ios/BuyLedgerTests/DesignSystemSourceScanTests+Patterns.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Insights/insightsView_帶開團資料_顯示每團毛利排行卡.1.png
  - apps/ios/BuyLedger/Features/Orders/OrdersFeature.swift
  - apps/ios/BuyLedger/Core/Dependencies/CategoryService.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+More/appLockView_解鎖失敗_顯示失敗訊息與重試鈕.1.png
  - apps/ios/BuyLedgerTests/CampaignFeatureTests+Editing.swift
  - apps/ios/BuyLedger/Features/Orders/Data/OrderService+Dependency.swift
  - apps/ios/BuyLedgerTests/DashboardStatsTests+Progress.swift
  - apps/ios/BuyLedgerTests/LookupServiceTests+PaymentMethodAtomicity.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsStats+Trend.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/Color+Semantic.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFilterPreviewFixtures.swift
  - apps/ios/BuyLedger/Core/Dependencies/OrderService+Dependency.swift
  - apps/ios/CLAUDE.md
  - apps/ios/BuyLedgerTests/QuoteFeatureTests+CurrencyCodes.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+PaymentMethodRename.swift
  - apps/ios/BuyLedger/Features/Campaigns/Components/CampaignDetailDistributionSection.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLDonutChart.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Dashboard/dashboardView_已載入無訂單_顯示首次使用畫面.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrderMerge/orderMergeCandidateSheet_有可合併訂單_顯示候選清單.1.png
  - apps/ios/BuyLedger/Features/Insights/InsightsDateContext.swift
  - apps/ios/BuyLedgerTests/LookupManagementFeatureTests+Forms.swift
  - apps/ios/BuyLedgerTests/ContrastComplianceTests.swift
  - apps/ios/BuyLedgerTests/ServiceOwnershipScanTests+Models.swift
  - apps/ios/BuyLedger/Features/Lookups/Data/LookupService.swift
  - apps/ios/BuyLedger/Shared/Extensions/Color+Extensions.swift
  - apps/ios/BuyLedgerTests/OrdersFeatureTests+FailureTiming.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Customers/customersView_一般客戶資料_顯示名次徽章與排行卡.1.png
  - apps/ios/BuyLedgerTests/OrdersFeatureTests+DeleteEditFailures.swift
  - apps/ios/BuyLedgerTests/PaymentMethodServiceTests+ApplyEdit.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Progress/BLProgressView.swift
  - apps/ios/BuyLedgerTests/ServiceTestValueStrictnessTests.swift
  - apps/ios/BuyLedgerTests/OrderListFeatureTests+FilterPending.swift
  - apps/ios/BuyLedgerTests/OrderWritesFeatureTests+Create.swift
  - apps/ios/BuyLedgerTests/LookupManagementFeatureTests.swift
  - apps/ios/BuyLedgerTests/LookupCatalogFeatureTests.swift
  - apps/ios/BuyLedgerTests/DashboardStatsTests.swift
  - apps/ios/BuyLedgerTests/LookupManagementFeatureTests+PaymentMethodCorrection.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Customers/customersView_無客戶資料_顯示空狀態.1.png
  - apps/ios/BuyLedgerTests/InsightsAttributionTests.swift
  - apps/ios/BuyLedger/Features/Campaigns/Components/CampaignDetailSettlementSection.swift
  - apps/ios/BuyLedgerTests/OrderServiceTests+WriteFailures.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderDetailContentView.swift
  - apps/ios/BuyLedger/Features/Orders/OrderEditOptions.swift
  - apps/ios/BuyLedger/Features/App/AppLockView.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsStats.swift
  - apps/ios/BuyLedger/Features/Campaigns/Data/CampaignService+Reminders.swift
  - apps/ios/BuyLedgerTests/CampaignListFeatureTests+DateContext.swift
  - apps/ios/BuyLedger/Features/Orders/OrderOptionWritePlan.swift
  - apps/ios/BuyLedgerTests/OrdersFeatureTests+OptionWriteFailures.swift
  - apps/ios/BuyLedgerTests/CampaignWritesFeatureTests+Rename.swift
  - apps/ios/BuyLedger/Features/FX/FxView.swift
  - apps/ios/BuyLedgerTests/ServiceOwnershipScanTests.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardView.swift
  - apps/ios/BuyLedger/Features/Customers/Components/CustomerTopCard.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsCategory.swift
  - apps/ios/BuyLedgerTests/LookupServiceTests+RenameFailures.swift
  - apps/ios/BuyLedgerTests/DependencyConventionScanTests+Rules.swift
  - apps/ios/BuyLedger/Features/Lookups/Components/LookupItemList.swift
  - apps/ios/BuyLedger/Features/Campaigns/Data/CampaignReminderService+Preview.swift
  - apps/ios/BuyLedger/Features/Campaigns/Data/CampaignReminderService.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+LookupCatalog.swift
  - apps/ios/BuyLedger/Core/Dependencies/OrderService.swift
  - apps/ios/BuyLedgerTests/ColorContrast.swift
  - apps/ios/BuyLedgerTests/CampaignReminderServiceTests.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+CurrencyCodes.swift
  - apps/ios/BuyLedger/Features/Quote/Components/QuoteStatusBanner.swift
  - apps/ios/BuyLedger/Features/Orders/OrderListFeature.swift
  - apps/ios/BuyLedgerTests/LookupServiceTests+RenameNoOps.swift
  - apps/ios/BuyLedgerTests/OrderServiceTests+Create.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupNameEditorSheet.swift
  - apps/ios/BuyLedger/Features/Lookups/Data/LookupService+PaymentMethods.swift
  - apps/ios/BuyLedgerTests/ReconciliationStatusServiceTests.swift
  - apps/ios/BuyLedger/Features/Campaigns/Data/CampaignService+Dependency.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersCompactView.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersContainerPlan+Writes.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsCostStructureCard.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+More/moreView_預設清單_顯示各入口.1.png
  - apps/ios/BuyLedgerTests/CustomersFeatureTests.swift
  - apps/ios/BuyLedgerTests/InsightsStatsTests+Breakdown.swift
  - apps/ios/BuyLedgerTests/CampaignReminderFeatureTests.swift
  - apps/ios/BuyLedgerTests/CategoryServiceTests.swift
  - apps/ios/BuyLedgerTests/MoreFeatureTests+Relays.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardFeature.swift
  - apps/ios/BuyLedger/App/Testing/DependencyValues+BLUITestLookupOverrides.swift
  - apps/ios/BuyLedgerTests/FxFeatureTests+CurrencyCodes.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+LookupCatalogAdditions.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsTrendBucket.swift
  - apps/ios/BuyLedger/Features/Orders/OrderEditPhotosSection.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignPresentationFeature+Destination.swift
  - apps/ios/BuyLedgerTests/InsightsHeatmapTests.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+OrdersReload.swift
  - apps/ios/BuyLedgerTests/LookupServiceTests.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersRootRequest.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+More/appLockView_生物辨識解鎖_顯示解鎖鈕.1.png
  - apps/ios/BuyLedger/Features/Orders/Components/OrderDetailSourceView.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderEditCampaignSection.swift
  - apps/ios/BuyLedger/Features/Orders/Data/OrderService+Reads.swift
  - apps/ios/BuyLedger/Features/Orders/OrderEditDraftOperations.swift
  - apps/ios/BuyLedger/Features/Lookups/Data/LookupService+Dependency.swift
  - apps/ios/BuyLedger/Core/Dependencies/OrderSourceService+Preview.swift
  - apps/ios/BuyLedger/Core/Dependencies/OrderSourceService.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift
  - apps/ios/BuyLedger/Features/App/PersistenceFailureView.swift
  - apps/ios/BuyLedger/Core/Dependencies/OrderService+Renames.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsView.swift
  - apps/ios/BuyLedgerTests/OrderFilterFeatureTests.swift
  - apps/ios/BuyLedgerTests/StorageFailureWrappingTests.swift
  - apps/ios/BuyLedgerTests/SnapshotTests+Dashboard.swift
  - apps/ios/BuyLedgerTests/OrdersPresentationFeatureTests+Delegate.swift
  - apps/ios/BuyLedgerTests/LookupServiceTests+PaymentMethodFixtures.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLSparkline.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersView.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardStats.swift
  - apps/ios/BuyLedger.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
  - apps/ios/BuyLedgerTests/DependencyConventionScanScenario+ViewCases.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoViewer.swift
  - apps/ios/BuyLedgerTests/OrderServiceTests+RenameSupport.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+PaymentMethodCorrection.swift
  - apps/ios/BuyLedgerTests/DashboardFormattersTests.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+NewOrderOptions.swift
  - apps/ios/BuyLedger/Features/Campaigns/Components/CampaignDetailInfoSection.swift
  - apps/ios/BuyLedgerTests/SnapshotTests+More.swift
  - apps/ios/BuyLedgerTests/DependencyConventionScanTests+TestValueRules.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupCatalogFeature.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderEditPickerDestination.swift
  - apps/ios/BuyLedger/Resources/Localizable.xcstrings
  - apps/ios/BuyLedgerTests/CampaignListFeatureTests+VisibleSections.swift
  - apps/ios/BuyLedgerTests/ServiceOwnershipScanTests+Fixtures.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderDetailItemsView.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsFormatters.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+LookupCatalogFixtures.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+DeepLinks.swift
  - apps/ios/BuyLedgerTests/DashboardFeatureTests+ScreenState.swift
  - apps/ios/BuyLedger/Features/Campaigns/Components/CampaignRow.swift
  - apps/ios/BuyLedgerTests/DesignSystemSourceScanTests.swift
  - apps/ios/BuyLedger/Features/FX/FxFormatters.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderEditCostSection.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersLoadFeature.swift
  - apps/ios/BuyLedgerTests/ServiceOwnershipScanTests+DatabaseCases.swift
  - apps/ios/BuyLedgerTests/ServiceOwnershipScanTests+ReferenceCases.swift
  - apps/ios/BuyLedgerTests/InsightsFeatureTests+DateContext.swift
  - apps/ios/BuyLedger/Features/Quote/QuoteFormatters.swift
  - apps/ios/BuyLedgerTests/LookupServiceTests+PaymentMethodSelection.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+More/settingsView_預設偏好_顯示版本與偏好列.1.png
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Insights/insightsView_載入中_顯示載入骨架.1.png
  - apps/ios/BuyLedgerTests/InsightsFormattersTests.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignReminderFeature.swift
  - apps/ios/BuyLedger/Core/Dependencies/CategoryService+Preview.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsTrendCard.swift
  - apps/ios/BuyLedger.xcodeproj/project.pbxproj
  - apps/ios/BuyLedger/Features/Customers/CustomerRank.swift
  - apps/ios/BuyLedgerTests/OrdersLoadFeatureTests+Requests.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignEditView.swift
  - apps/ios/BuyLedgerTests/OrdersFeatureTests+OptionWrites.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderEditBasicSection.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderDetailCostView.swift
  - apps/ios/BuyLedgerTests/CampaignFeatureTests+ReminderIntegration.swift
  - apps/ios/BuyLedgerTests/LookupServiceTests+Renames.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardKPITiles.swift
  - apps/ios/BuyLedgerTests/OrdersFeatureTests+ListRequests.swift
  - apps/ios/BuyLedgerTests/ActionGroupingScanTests+Scenarios.swift
  - apps/ios/BuyLedgerTests/ServiceOwnershipScanTests+Rules.swift
  - apps/ios/BuyLedgerTests/DashboardStatsTests+Fixtures.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersFilterOperations.swift
  - apps/ios/BuyLedgerTests/CampaignIntegrationTests+Receipt.swift
  - apps/ios/BuyLedgerTests/OrderWritesFeatureTests+Merge.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsCategoryCard.swift
  - apps/ios/BuyLedgerTests/SnapshotTests+Customers.swift
  - apps/ios/BuyLedgerTests/CampaignEditFeatureTests.swift
  - apps/ios/BuyLedgerTests/SnapshotTests+Insights.swift
  - apps/ios/BuyLedgerTests/SnapshotTests+Shared.swift
  - apps/ios/BuyLedgerTests/OrderEditCampaignOptionsTests.swift
  - apps/ios/BuyLedger/Features/Quote/QuoteView.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Cards/BLCard.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignWritesFeature.swift
  - apps/ios/BuyLedger/Core/Persistence/PaymentMethodPersistenceError.swift
  - apps/ios/BuyLedgerTests/BLTrendTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLPalette.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/ViewModifiers/BLHeroCardBackground.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardDateContext.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLTrend.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardRecentOrdersSection.swift
  - apps/ios/BuyLedger/Features/Lookups/Data/LookupService+Renames.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+CampaignLoading.swift
  - apps/ios/BuyLedger/Features/Orders/Data/OrderService+Preview.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLBarChart.swift
  - apps/ios/BuyLedger/Core/Dependencies/CategoryService+Dependency.swift
  - apps/ios/BuyLedgerTests/CampaignServiceTests+DeleteFailure.swift
  - apps/ios/BuyLedger/Features/Orders/Components/MergePhotoPickerSheet.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Chips/BLFilterChip.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Tags/BLTagPill.swift
  - apps/ios/BuyLedger/Features/Orders/OrderEditPickersFeature.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Forms/PaymentMethodEditorSheet.swift
  - apps/ios/BuyLedgerTests/DesignSystemSourceScanTests+Scanner.swift
  - apps/ios/BuyLedger/Features/More/MoreView.swift
  - apps/ios/BuyLedgerTests/DependencyConventionScanTests+Scanner.swift
  - apps/ios/BuyLedger/App/Testing/DependencyValues+BLUITestOverrides.swift
  - apps/ios/BuyLedgerTests/LookupServiceTests+Sources.swift
  - apps/ios/BuyLedger/Features/Campaigns/Components/CampaignSectionList.swift
  - apps/ios/BuyLedgerTests/DesignSystemSourceScanTests+ScaledMetric.swift
  - apps/ios/BuyLedger/Features/App/RootNavigationOperations.swift
  - apps/ios/BuyLedgerTests/OrdersContainerPlanTests+Writes.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+Cascade.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersRegularListColumn.swift
  - apps/ios/BuyLedgerTests/OrderEditFeatureTests+Reconciliation.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrderMerge/mergePhotoPickerSheet_七張照片選滿上限_顯示已選與未選照片.1.png
  - apps/ios/BuyLedgerTests/OrderServiceTests+RenameFailures.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Dashboard/dashboardView_載入中_顯示載入骨架.1.png
  - apps/ios/BuyLedgerTests/OrdersFeatureTests+LoadAndSummary.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignListView.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderDetailCardlessView.swift
  - apps/ios/BuyLedgerTests/BuyLedgerDatabaseTests.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignEditFeature.swift
  - apps/ios/BuyLedgerTests/OrdersFeatureTests+Create.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+Fixtures.swift
  - apps/ios/BuyLedgerTests/InsightsStatsTests.swift
  - apps/ios/BuyLedgerTests/DashboardFormattersTests+Summary.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderEditSelectionRow.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+Foreground.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignFormatters.swift
  - apps/ios/BuyLedgerTests/OrdersFeatureTests+SaveFailureTiming.swift
  - apps/ios/BuyLedgerTests/ServiceOwnershipScanTests+Scanner.swift
  - apps/ios/BuyLedgerTests/OrderServiceTests+Concurrency.swift
  - apps/ios/BuyLedger/Features/Lookups/Data/LookupService+Preview.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupAdditionRequest.swift
  - apps/ios/BuyLedger/Features/Orders/OrderWriteOperations.swift
  - apps/ios/BuyLedgerTests/PaymentMethodCorrectionFeatureTests.swift
  - apps/ios/BuyLedger/Core/Dependencies/OrderService+Preview.swift
  - apps/ios/BuyLedger/Core/Dependencies/OrderSourceService+Dependency.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrderMerge/mergePhotoPickerSheet_七張照片只選部分_顯示未選取照片.1.png
  - apps/ios/BuyLedgerTests/CampaignEditFeatureTests+NavigationTitle.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLHitTarget.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsHeatmap.swift
  - apps/ios/BuyLedgerTests/LookupManagementFeatureTests+AlertTiming.swift
  - apps/ios/BuyLedgerTests/OrderPercentConversionTests.swift
  - apps/ios/BuyLedgerTests/ColorContrastTests.swift
  - apps/ios/BuyLedger/Core/Dependencies/ReconciliationStatusService+Dependency.swift
  - apps/ios/BuyLedgerTests/CampaignServiceTests+Reminders.swift
  - apps/ios/BuyLedgerTests/DependencyConventionScanTests+ViewRules.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupItemOperations.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsFeature.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsCostSegment.swift
  - apps/ios/BuyLedgerTests/OrderEditFeatureTests+Campaigns.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Shared/paymentMethodEditorSheet_新增付款方式_顯示空白表單.1.png
  - apps/ios/BuyLedger/Core/Dependencies/ReconciliationStatusService.swift
  - apps/ios/BuyLedger/Core/Dependencies/ReconciliationStatusService+Preview.swift
  - apps/ios/BuyLedgerTests/OrdersLoadStateTests.swift
  - apps/ios/BuyLedger/Features/Lookups/PaymentMethodCorrectionFeature.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderMergeCandidateSheet.swift
  - apps/ios/BuyLedger/Features/Customers/CustomersFeature.swift
  - apps/ios/BuyLedger/Features/Orders/OrderWritesFeature.swift
  - apps/ios/BuyLedger/Features/Customers/CustomerRankBadgeStyle.swift
  - apps/ios/BuyLedgerTests/PaymentMethodServiceTests.swift
  - apps/ios/BuyLedgerTests/OrdersFeatureTests+MergeWrites.swift
  - apps/ios/BuyLedgerTests/CampaignListFeatureTests+RowSummaries.swift
  - apps/ios/BuyLedgerTests/CampaignReminderFeatureTests+Rebuild.swift
  - apps/ios/BuyLedgerTests/SnapshotTests+CampaignDetail.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFilterPaymentMethodSection.swift
  - apps/ios/BuyLedgerTests/CampaignFeatureTests+NameConflict.swift
  - apps/ios/BuyLedgerTests/CustomerFormattersTests.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderSelectableRow.swift
  - apps/ios/BuyLedgerTests/CampaignFeatureTests+ReminderRename.swift
  - apps/ios/BuyLedgerTests/DashboardStatsTests+Comparison.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+LoadRequests.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+OrderFilters.swift
  - apps/ios/BuyLedger/Features/FX/Components/FxStatusBanner.swift
  - apps/ios/BuyLedger/Features/Customers/CustomersView.swift
  - apps/ios/BuyLedger/Features/More/MoreFeature.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Progress/BLProgressViewStyle.swift
  - apps/ios/BuyLedgerTests/OrderServiceResidueTests.swift
  - apps/ios/BuyLedger/Features/Customers/CustomerFormatters.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersPresentationFeature.swift
  - apps/ios/BuyLedgerTests/OrdersFeatureTests.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests+LookupSync.swift
  - apps/ios/BuyLedgerTests/CampaignFormattersTests.swift
  - apps/ios/BuyLedger/Features/Orders/OrderEditFeature.swift
  - apps/ios/BuyLedgerTests/OrdersLoadFeatureTests.swift
  - apps/ios/BuyLedger/Features/Insights/CampaignProfitRank.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsDateRange.swift
  - apps/ios/BuyLedger/Features/Orders/Components/MergePhotoTile.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Buttons/BLButtonStyle.swift
  - apps/ios/BuyLedgerTests/InsightsStatsTests+Fixtures.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderRowView.swift
  - apps/ios/BuyLedgerTests/SnapshotTests+OrderMerge.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLSpacing.swift
  - apps/ios/BuyLedgerTests/SnapshotTests+OrdersBaseline.swift
  - apps/ios/BuyLedgerTests/LookupManagementFeatureTests+PaymentMethodStoredOrders.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardHeroCard.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+More/settingsView_開啟AI摘要與生物辨識_顯示對應列.1.png
  - apps/ios/BuyLedgerTests/CampaignIntegrationTests+Navigation.swift
  - apps/ios/BuyLedgerTests/OrderEditPickersFeatureTests.swift
  - apps/ios/BuyLedger/Features/Orders/Data/OrderService.swift
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