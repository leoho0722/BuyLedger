# order-merge Specification

## Purpose

TBD - created by archiving change 'add-order-merge'. Update Purpose after archive.

## Requirements

### Requirement: Order merge entry points

The system SHALL provide a "merge order" action on the orders list row context menu and in the order detail page's "more" actions menu, on iOS and iPadOS. On the order detail page, the merge, edit, and delete actions SHALL be grouped into a single "more" menu (ellipsis label) — ordered as merge, edit, then delete, with delete presented as a destructive action separated from the others by a divider — while the status update control SHALL remain a separate control outside that menu. Both entry points SHALL open the same merge candidate sheet, with the originating order as the primary order. The merge action SHALL NOT be offered for orders whose status is merged or cancelled.

#### Scenario: Entry from the orders list context menu

- **WHEN** the user opens the context menu of an order row whose status is neither merged nor cancelled and selects the merge action
- **THEN** the merge candidate sheet opens with that order as the primary order

#### Scenario: Entry from the order detail page

- **WHEN** the user opens the "more" menu on the detail page of an order whose status is neither merged nor cancelled and selects the merge action
- **THEN** the merge candidate sheet opens with that order as the primary order

#### Scenario: Detail page actions are consolidated into a more menu

- **WHEN** the user views the detail page of any order
- **THEN** the action area shows exactly two controls: the status update menu and a "more" menu that contains the merge action (when the order is eligible), the edit action, and the destructive delete action separated by a divider

#### Scenario: Entry hidden for merged and cancelled orders

- **WHEN** an order's status is merged or cancelled
- **THEN** neither the context menu nor the detail page "more" menu offers the merge action, while the "more" menu still offers edit and delete

---
### Requirement: Merge candidate selection

The merge candidate sheet SHALL list the orders eligible to merge with the primary order. An order is eligible only when all of the following hold: it is not the primary order itself, its status is neither merged nor cancelled, its currency equals the primary order's currency, and its customer name equals the primary order's customer name. Cross-customer merging SHALL NOT be offered. The candidate list SHALL group rows into date sections by order date (start of day), sections ordered newest first and rows inside each section ordered newest first, with section titles produced the same way as the orders list date sections (relative today/yesterday or a formatted day). Each candidate row SHALL reuse the orders list row layout — avatar, customer name, item summary (one line per item), and category tag — with the trailing column showing the order's charged amount and a charged-amount label instead of the status pill, revenue, and profit; the row SHALL NOT display an inline date (the section title carries the date) and SHALL NOT display the raw order identifier. The sheet SHALL provide a search field that filters the candidate rows in real time, and SHALL show an empty state when no eligible order exists or no row matches the search. Tapping a candidate row SHALL select it as the secondary order and advance the merge flow.

#### Scenario: Candidate row shows the item summary

- **WHEN** the merge candidate sheet lists a candidate order whose items are "藍牙耳機" with quantity 2 and "保護殼" with quantity 1
- **THEN** the row shows the orders-list row layout with the customer name, the item summary lines "藍牙耳機 x2" and "保護殼 x1", and a trailing charged amount, without an inline date and without the order identifier

#### Scenario: Candidates are grouped by date sections

- **WHEN** the eligible candidates span two different order dates
- **THEN** the list shows two date sections ordered newest first, each titled the same way as the orders list date sections, with that day's candidates inside ordered newest first

#### Scenario: Candidate eligibility filtering

- **WHEN** the merge candidate sheet opens for a primary order
- **THEN** the sheet lists exactly the orders that share the primary order's currency and customer name, excluding the primary order itself and any order whose status is merged or cancelled

##### Example: eligibility matrix

| Candidate | Currency | Customer | Status    | Listed |
| --------- | -------- | -------- | --------- | ------ |
| O2        | JPY      | Alice    | purchased | yes    |
| O3        | JPY      | Alice    | merged    | no     |
| O4        | JPY      | Alice    | cancelled | no     |
| O5        | KRW      | Alice    | purchased | no     |
| O6        | JPY      | Bob      | purchased | no     |

- **GIVEN** the primary order O1 has currency JPY, customer "Alice", status shipping, and candidates O2–O6 as in the table
- **WHEN** the merge candidate sheet opens for O1
- **THEN** only O2 is listed

#### Scenario: Empty state when no eligible order exists

- **WHEN** no other order shares the primary order's currency and customer name with an eligible status
- **THEN** the sheet shows an empty state instead of an empty list


<!-- @trace
source: add-order-merge
updated: 2026-06-07
code:
  - apps/apple/BuyLedger/Features/Orders/OrdersView.swift
  - apps/apple/BuyLedger/Features/Orders/OrdersCompactView.swift
  - apps/apple/BuyLedger/Features/Orders/OrdersMacView.swift
  - apps/apple/BuyLedgerTests/OrderMergeFeatureTests.swift
  - apps/apple/BuyLedger/Features/Orders/OrdersFeature.swift
  - apps/apple/BuyLedger/Features/Orders/Components/OrderRowView.swift
  - apps/apple/BuyLedger/Features/Orders/Components/OrderMergeCandidateSheet.swift
  - apps/apple/BuyLedger/Features/Orders/OrderMergeFeature.swift
-->

---
### Requirement: Photo over-limit selection step

When the combined photo count of the primary and secondary orders exceeds the order photo limit (5), the merge flow SHALL present a photo selection step before the prefilled merge form, showing every photo from both orders. The user SHALL select at most 5 photos to keep; confirming advances to the prefilled merge form carrying only the kept photos. When the combined count is 5 or fewer, the merge flow SHALL skip this step and carry all photos in primary-then-secondary order.

#### Scenario: Combined photos exceed the limit

- **WHEN** the primary order has 4 photos and the secondary order has 3 photos
- **THEN** the photo selection step is shown with all 7 photos, and the user can confirm only while 5 or fewer photos are selected

#### Scenario: Combined photos within the limit

- **WHEN** the primary order has 2 photos and the secondary order has 3 photos
- **THEN** the merge flow skips the photo selection step and the prefilled form carries all 5 photos in primary-then-secondary order


<!-- @trace
source: add-order-merge
updated: 2026-06-07
code:
  - apps/apple/BuyLedger/Features/Orders/OrdersView.swift
  - apps/apple/BuyLedger/Features/Orders/OrdersCompactView.swift
  - apps/apple/BuyLedger/Features/Orders/OrdersMacView.swift
  - apps/apple/BuyLedgerTests/OrderMergeFeatureTests.swift
  - apps/apple/BuyLedger/Features/Orders/OrdersFeature.swift
  - apps/apple/BuyLedger/Features/Orders/Components/OrderRowView.swift
  - apps/apple/BuyLedger/Features/Orders/Components/OrderMergeCandidateSheet.swift
  - apps/apple/BuyLedger/Features/Orders/OrderMergeFeature.swift
-->

---
### Requirement: Merged draft prefill rules

After candidate selection (and the photo step when required), the system SHALL open the new-order edit form prefilled from the primary order (P) and the secondary order (S) as follows:

- Categories: the ordered union of P's then S's categories, without duplicates.
- Campaigns: the ordered union of P's then S's campaign lists, without duplicates.
- Order date: the current date and time at the moment of merging, obtained from the injected clock dependency.
- Customer name, order source, status, currency, payment receipt status: P's values.
- Payment method: when P and S share the same payment method, that value; otherwise, when exactly one of the two payment methods is a cardless method, the cardless one; otherwise P's value. The verification status and the cash-on-delivery flag SHALL follow the order that supplied the payment method.
- Charged amount, cardless deduction amount, cardless supplement amount, item cost, foreign domestic shipping, international shipping, domestic shipping: the per-field sum of P and S.
- Card, platform, and payment fee rates: per-field weighted average using the two charged amounts as weights — `(rateP × chargedP + rateS × chargedS) ÷ (chargedP + chargedS)` — clamped to [0, 1]; when both charged amounts are 0, P's rate. The result MUST NOT be NaN.
- Items: P's items followed by S's items, contents unchanged.
- Notes: when both are non-empty after trimming, P's notes, a separator line consisting of dashes (`----------`) on its own line, then S's notes; when only one side is non-empty, that side alone without a separator; when both are empty, empty.
- Photos: the photos carried over from the photo step (kept selection when the step ran, otherwise the primary-then-secondary concatenation).

The form SHALL behave as a normal new-order draft afterwards: every prefilled value — including the received amounts, costs, fee rates, and item details — remains editable before saving. The merge computation supplies initial values only.

#### Scenario: Amount fields are summed

- **WHEN** the user merges P (charged 1000, item cost 600, domestic shipping 60) with S (charged 2000, item cost 900, domestic shipping 80)
- **THEN** the prefilled form shows charged 3000, item cost 1500, and domestic shipping 140

#### Scenario: Fee rates use the charged-amount weighted average

- **WHEN** the user merges two orders with differing fee rates
- **THEN** each fee rate is prefilled as the charged-amount weighted average of the two source rates

##### Example: weighted average and degenerate weights

| chargedP | rateP | chargedS | rateS | Prefilled rate          |
| -------- | ----- | -------- | ----- | ----------------------- |
| 1000     | 1.5%  | 2000     | 2%    | (15 + 40) ÷ 3000 ≈ 1.83% |
| 1000     | 1.5%  | 0        | 3%    | 1.5%                    |
| 0        | 1.5%  | 0        | 3%    | 1.5% (P's rate)         |

#### Scenario: Categories and campaigns take the ordered union

- **WHEN** the user merges P (categories ["beauty"], campaigns ["May-JP"]) with S (categories ["snacks", "beauty"], campaigns ["June-KR"])
- **THEN** the prefilled categories are ["beauty", "snacks"] and the prefilled campaigns are ["May-JP", "June-KR"]

#### Scenario: Notes join with a dash separator line

- **WHEN** both source orders have non-empty notes
- **THEN** the prefilled notes are P's notes, a line of dashes, then S's notes

##### Example: notes composition

| notesP  | notesS  | Prefilled notes              |
| ------- | ------- | ---------------------------- |
| "急件"   | "含贈品" | "急件\n----------\n含贈品"     |
| "急件"   | ""      | "急件"                        |
| ""      | ""      | ""                           |

#### Scenario: Cardless payment method wins on conflict

- **WHEN** P's payment method is not cardless and S's payment method is cardless
- **THEN** the prefilled payment method is S's, and the verification status and cash-on-delivery flag are prefilled from S


<!-- @trace
source: add-order-merge
updated: 2026-06-07
code:
  - apps/apple/BuyLedger/Features/Orders/OrdersView.swift
  - apps/apple/BuyLedger/Features/Orders/OrdersCompactView.swift
  - apps/apple/BuyLedger/Features/Orders/OrdersMacView.swift
  - apps/apple/BuyLedgerTests/OrderMergeFeatureTests.swift
  - apps/apple/BuyLedger/Features/Orders/OrdersFeature.swift
  - apps/apple/BuyLedger/Features/Orders/Components/OrderRowView.swift
  - apps/apple/BuyLedger/Features/Orders/Components/OrderMergeCandidateSheet.swift
  - apps/apple/BuyLedger/Features/Orders/OrderMergeFeature.swift
-->

---
### Requirement: Merge-related orders stay fully editable

When editing an order produced by a merge (non-empty merged-source list) or an order whose status is merged, the order editor SHALL keep every field editable — including the received-amount, cost, fee-rate, and item-details sections — exactly like a regular order. Categories and campaigns keep the multi-select picker in these merge contexts. Editing amounts after a merge is allowed to make the per-category and per-campaign breakdowns (attributed from the pre-merge source orders) diverge from the merged order's totals; this divergence is the accepted trade-off of keeping the fields editable.

#### Scenario: Editing a merge-produced order keeps amounts editable

- **WHEN** the user edits an order that was produced by a merge
- **THEN** the received-amount, cost, fee-rate, and item-details fields accept changes like any regular order

#### Scenario: Editing a merged-away source order keeps amounts editable

- **WHEN** the user edits an order whose status is merged
- **THEN** the received-amount, cost, fee-rate, and item-details fields accept changes like any regular order


<!-- @trace
source: add-order-merge
updated: 2026-06-07
code:
  - apps/apple/BuyLedger/Features/Orders/OrdersView.swift
  - apps/apple/BuyLedger/Features/Orders/OrdersCompactView.swift
  - apps/apple/BuyLedger/Features/Orders/OrdersMacView.swift
  - apps/apple/BuyLedgerTests/OrderMergeFeatureTests.swift
  - apps/apple/BuyLedger/Features/Orders/OrdersFeature.swift
  - apps/apple/BuyLedger/Features/Orders/Components/OrderRowView.swift
  - apps/apple/BuyLedger/Features/Orders/Components/OrderMergeCandidateSheet.swift
  - apps/apple/BuyLedger/Features/Orders/OrderMergeFeature.swift
-->

---
### Requirement: Saving a merged draft commits atomically

When the user saves the prefilled merge form, the system SHALL, in a single persistence operation: insert the new merged order with both source order IDs recorded in its merged-source list, and set the status of both source orders to merged. The in-memory orders list SHALL reflect the new order and both source-status changes together. When persistence fails, neither the new order nor any source-status change SHALL be applied, and the failure SHALL surface through the existing persistence error path. An order not produced by a merge SHALL have an empty merged-source list.

The merged order SHALL be written with create intent. When its identifier collides with an existing order, the whole operation SHALL fail and SHALL NOT overwrite the existing order, so that a merge can never consume an unrelated order.

#### Scenario: Save commits the merge

- **WHEN** the user saves the merge form
- **THEN** the orders list contains the new merged order carrying both source order IDs, and both source orders with status merged, and the same state is persisted

#### Scenario: Persistence failure leaves no partial merge

- **WHEN** persistence fails while saving the merge
- **THEN** no new order exists, both source orders keep their previous status, and the failure surfaces through the existing persistence error path

#### Scenario: Identifier collision aborts the merge

- **WHEN** the merged order's identifier already belongs to an existing order
- **THEN** the operation fails, the existing order is unchanged in every field, and neither source order's status is modified


<!-- @trace
source: order-identity-and-write-integrity
updated: 2026-08-15
code:
  - apps/ios/BuyLedgerUITests/Tests/Tools/FxTests.swift
  - apps/ios/CLAUDE.md
  - apps/ios/BuyLedger/Features/FX/FxView.swift
  - apps/ios/BuyLedger/Resources/PrivacyInfo.xcprivacy
  - apps/ios/BuyLedgerUITests/Tests/Customers/CustomersTests.swift
  - apps/ios/BuyLedger/App/BuyLedgerApp.swift
  - apps/ios/BuyLedger/Features/FX/FxRates.swift
  - apps/ios/BuyLedger/Core/Networking/HTTPClient.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderStatus+Presentation.swift
  - apps/ios/BuyLedgerTests/OrderCalculationTests.swift
  - apps/ios/BuyLedger/Core/Persistence/CategoryRecord.swift
  - apps/ios/BuyLedgerUITests/Tests/Campaigns/CampaignCrudTests.swift
  - apps/ios/BuyLedger/Features/App/RootTabLayout.swift
  - apps/ios/BuyLedger/Core/Dependencies/CampaignRepository.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignEditView.swift
  - apps/ios/BuyLedgerTests/OrderDraftTests.swift
  - apps/ios/BuyLedger/Core/Dependencies/CampaignReminderRepository.swift
  - apps/ios/BuyLedger/Features/App/AppLockFeature.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsStats.swift
  - apps/ios/BuyLedger/Core/Domain/FxRates.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLSparkline.swift
  - shared/data-model/schema/CurrencyCode.yaml
  - apps/ios/BuyLedgerUITests/Screens/OrderEditScreen.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/States/DelayedProgressView.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignListView.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLDonutChart.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsView.swift
  - apps/ios/BuyLedgerTests/OrdersFilterOperationsTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrdersListTests.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/PaymentReceiptStatus.generated.swift
  - apps/ios/BuyLedgerUITests/Screens/AppLockScreen.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestSeedData.swift
  - apps/ios/BuyLedger/Core/Dependencies/PaymentMethodRepository.swift
  - apps/ios/BuyLedger/Core/Testing/BLUITestSeedData.swift
  - apps/ios/BuyLedgerUITests/Screens/OptionPickerScreen.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Badges/BLBadge.swift
  - apps/ios/BuyLedgerTests/LayerBoundaryTests.swift
  - apps/ios/BuyLedgerUITests/Support/Assertions.swift
  - apps/ios/BuyLedgerTests/BLPhotoViewerTests.swift
  - apps/ios/BuyLedger/Features/App/SidebarBadgeCounts.swift
  - apps/ios/BuyLedgerUITests/Tests/Smoke/HarnessSelfCheckTests.swift
  - apps/ios/BuyLedger/App/AppDelegate.swift
  - apps/ios/BuyLedger.xcodeproj/project.pbxproj
  - apps/ios/BuyLedger/Features/App/AppLockView.swift
  - apps/ios/BuyLedger.xctestplan
  - apps/ios/BuyLedger/Features/Orders/Components/OptionPickerSheet.swift
  - apps/ios/BuyLedgerUITests/Tests/Performance/LaunchPerformanceTests.swift
  - shared/data-model/schema/LedgerOrder.yaml
  - apps/ios/BuyLedgerUITests/Screens/CampaignEditScreen.swift
  - shared/data-model/fixtures/expected/typescript/SamplePreference.ts
  - apps/ios/BuyLedgerUITests/Tests/Smoke/AppLockTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/quoteViewBaseline.1.png
  - apps/ios/BuyLedger/Core/Networking/URLRequestBuilder.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/States/BLDelayedProgressView.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/CurrencyCode.generated.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/LedgerOrderItem.generated.swift
  - apps/ios/BuyLedger/Features/Orders/Components/PaymentMethodEditorSheet.swift
  - apps/ios/BuyLedger/Features/More/MoreView.swift
  - apps/ios/BuyLedgerUITests/Screens/QuoteScreen.swift
  - apps/ios/BuyLedger/Core/Dependencies/CurrencyMetadataRepository.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersView.swift
  - apps/ios/BuyLedger/Core/Domain/LedgerOrder.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderSelectableRow.swift
  - apps/ios/BuyLedgerUITests/Support/LaunchOptions.swift
  - apps/ios/BuyLedger/Shared/Extensions/Decimal+Extensions.swift
  - apps/ios/BuyLedger/Features/Settings/AppLanguage.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLBarChartValue.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/States/BLLoadFailureView.swift
  - apps/ios/BuyLedger/Resources/GoogleService-Info.example.plist
  - apps/ios/BuyLedgerTests/ContrastComplianceTests.swift
  - apps/ios/BuyLedger/Features/Customers/CustomersFeature.swift
  - apps/ios/BuyLedgerTests/LookupCatalogTests.swift
  - apps/ios/BuyLedgerTests/CalendarReminderTests.swift
  - apps/ios/BuyLedger/Core/Dependencies/CategoryRepository.swift
  - apps/ios/BuyLedger/Core/Persistence/OrderSourcePersistence.swift
  - apps/ios/BuyLedgerTests/OrderMergeFeatureTests.swift
  - apps/ios/BuyLedger/Core/Networking/ExchangeRateDTO.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsFeature.swift
  - shared/data-model/fixtures/expected/typescript/SampleProfile.ts
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoThumbnail.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/persistenceFailureViewBaseline.1.png
  - apps/ios/BuyLedger/Core/Persistence/PersistenceStoreQuarantineClient.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Chips/BLFilterChip.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLFormatters.swift
  - apps/ios/BuyLedgerUITests/Support/Diagnostics.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFilterSheet.swift
  - apps/ios/BuyLedger/Core/Dependencies/NameLookupOperations.swift
  - shared/data-model/schema/PaymentMethodInfo.yaml
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderMergeTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLBarChart.swift
  - apps/ios/BuyLedger/Features/Customers/CustomerRankBadgeStyle.swift
  - apps/ios/BuyLedgerUITests/Screens/InsightsScreen.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLStatusHue.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignFormatters.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/ViewModifiers/BLCardShadow.swift
  - apps/ios/BuyLedger/Core/Dependencies/OrderSourceRepository.swift
  - apps/ios/BuyLedger/Core/Persistence/CampaignReminderPersistence.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Status/BLStatusPill.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersMergeFlowOperations.swift
  - apps/ios/BuyLedgerUITests/PhotoViewerPagingTests.swift
  - apps/ios/BuyLedgerUITests/Support/Waiting.swift
  - apps/ios/BuyLedgerTests/CustomersFeatureTests.swift
  - apps/ios/BuyLedger/Features/App/RootView.swift
  - apps/ios/BuyLedgerUITests/Support/BLUITestCase.swift
  - apps/ios/BuyLedger/Features/Orders/OrderEditView.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupNameEditorSheet.swift
  - apps/ios/BuyLedger/Core/Persistence/CategoryPersistence.swift
  - shared/data-model/schema/PaymentReceiptStatus.yaml
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Buttons/BLButtonStyle.swift
  - apps/ios/BuyLedgerAccessibilityIDs/BLAccessibilityID.swift
  - apps/ios/BuyLedger/Resources/Info.plist
  - apps/ios/BuyLedger/Shared/Media/PhotoDataProcessor.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderDetailTests.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/PaymentMethodInfo.generated.swift
  - apps/ios/BuyLedger/Features/App/RootTab.swift
  - apps/ios/BuyLedgerTests/OrderEditFocusTests.swift
  - apps/ios/BuyLedger/Features/Orders/OrderDraft.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersCompactView.swift
  - apps/ios/BuyLedger/Features/FX/FxFeature.swift
  - apps/ios/BuyLedgerUITests/Support/AppNavigator.swift
  - shared/data-model/fixtures/expected/typescript/SampleStatus.ts
  - apps/ios/BuyLedger/Features/Orders/Components/OrderDetailView.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignEditFeature.swift
  - apps/ios/BuyLedger/Features/App/RootFeature.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Avatar/BLAvatar.swift
  - apps/ios/BuyLedger/Core/Dependencies/OrderRepository.swift
  - apps/ios/BuyLedger.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
  - apps/ios/BuyLedgerTests/BiometricAuthClientTests.swift
  - apps/ios/BuyLedger/Features/Quote/QuoteFeature.swift
  - apps/ios/BuyLedgerUITests/Screens/OrderDetailScreen.swift
  - apps/ios/BuyLedger/Features/Orders/OrderMergeFeature.swift
  - apps/ios/BuyLedgerTests/PaymentMethodPersistenceTests.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementDestination.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Cards/BLCard.swift
  - apps/ios/BuyLedger/Core/Persistence/PersistenceError.swift
  - apps/ios/BuyLedgerUITests/Tests/Campaigns/CampaignDetailTests.swift
  - apps/ios/BuyLedger/Core/Dependencies/OpenSettingsClient.swift
  - apps/ios/BuyLedgerUITests/Support/SheetInteraction.swift
  - apps/ios/BuyLedgerUITests/Screens/SettingsScreen.swift
  - apps/ios/BuyLedger/Features/App/PersistenceFailureFeature.swift
  - apps/ios/BuyLedgerUITests/Screens/OrdersScreen.swift
  - apps/ios/BuyLedgerTests/ColorContrast.swift
  - apps/ios/BuyLedgerTests/CampaignSummaryTests.swift
  - apps/ios/BuyLedger/Core/Persistence/PaymentMethodRecord.swift
  - shared/data-model/schema/Campaign.yaml
  - apps/ios/BuyLedger/Core/Domain/Generated/CampaignStatus.generated.swift
  - apps/ios/BuyLedger/Features/Orders/OrderStatusFilter.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/ViewModifiers/BLTypographyModifier.swift
  - apps/ios/BuyLedger/Resources/InfoPlist.xcstrings
  - apps/ios/BuyLedger/Core/Diagnostics/CrashDiagnosticsClient.swift
  - apps/ios/BuyLedger/App/AppLaunchConfigurator.swift
  - apps/ios/BuyLedgerTests/FxFeatureTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLHeatmapDepth.swift
  - shared/data-model/fixtures/expected/kotlin/SampleStatus.kt
  - apps/ios/BuyLedger/Core/Domain/Generated/Money.generated.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardView.swift
  - apps/ios/BuyLedger/Core/Domain/CurrencyCode.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLDonutSegment.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsStorage.swift
  - apps/ios/BuyLedgerTests/PersistenceFailureFeatureTests.swift
  - apps/ios/BuyLedgerTests/SettingsFeatureTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLMetrics.swift
  - shared/data-model/schema/LedgerOrderItem.yaml
  - apps/ios/BuyLedger/Core/Dependencies/BiometricAuthClient.swift
  - apps/ios/BuyLedger/Features/AISummary/AISummaryFeature.swift
  - apps/ios/BuyLedger/Features/AISummary/OllamaDTO.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/dashboardViewBaseline.1.png
  - apps/ios/BuyLedgerUITests/KeyboardDismissTests.swift
  - apps/ios/BuyLedgerUITests/Screens/DashboardScreen.swift
  - CLAUDE.md
  - shared/data-model/fixtures/expected/typescript/SampleQuote.ts
  - apps/ios/BuyLedgerTests/PersistenceErrorContractTests.swift
  - apps/ios/BuyLedger/Core/Persistence/CurrencyMetadataRecord.swift
  - apps/ios/BuyLedgerTests/NameLookupPersistenceTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewBaseline.1.png
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderCreateTests.swift
  - apps/ios/BuyLedgerTests/TestSuiteIntegrityTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Campaigns/CampaignListTests.swift
  - shared/data-model/fixtures/expected/kotlin/SampleSequence.kt
  - apps/ios/BuyLedgerTests/PrivacyManifestTests.swift
  - apps/ios/BuyLedger/Core/Domain/LedgerOrderItem.swift
  - apps/ios/BuyLedger/Features/AISummary/OllamaClient.swift
  - apps/ios/BuyLedger/Core/Networking/AppConfiguration.swift
  - shared/data-model/fixtures/expected/swift/SampleQuote.generated.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLPalette.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Pickers/OptionPickerSheet.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestHarness.swift
  - apps/ios/BuyLedger/Core/Persistence/OrderSourceRecord.swift
  - apps/ios/BuyLedgerUITests/Screens/PhotoViewerScreen.swift
  - apps/ios/BuyLedgerTests/DashboardFeatureTests.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementView.swift
  - shared/data-model/fixtures/schema/sample-orders.yaml
  - apps/ios/BuyLedger/App/Testing/BLUITestConfiguration.swift
  - apps/ios/BuyLedgerTests/HTTPClientTests.swift
  - shared/data-model/fixtures/expected/kotlin/SampleReceipt.kt
  - apps/ios/BuyLedgerTests/SnapshotTests.swift
  - apps/ios/BuyLedger/Core/Dependencies/TelemetryClient.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersFilterOperations.swift
  - apps/ios/BuyLedgerTests/LocalizationCatalogTests.swift
  - shared/data-model/fixtures/schema/sample-enums.yaml
  - apps/ios/BuyLedgerUITests.xctestplan
  - apps/ios/BuyLedger/Features/Orders/OrdersFeature.swift
  - shared/data-model/schema/Money.yaml
  - apps/ios/BuyLedgerUITests/Support/Scrolling.swift
  - apps/ios/BuyLedger/Core/Persistence/PaymentMethodPersistence.swift
  - apps/ios/BuyLedger/Core/Testing/BLUITestConfiguration.swift
  - apps/ios/BuyLedgerTests/ColorContrastTests.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsView.swift
  - shared/data-model/fixtures/expected/swift/SampleProfile.generated.swift
  - apps/ios/BuyLedgerTests/DashboardStatsTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/AISummaryTests.swift
  - shared/data-model/schema/LedgerCustomer.yaml
  - apps/ios/BuyLedger.xcodeproj/xcshareddata/xcschemes/BuyLedger.xcscheme
  - apps/ios/BuyLedger/Core/Domain/Generated/OrderStatus.generated.swift
  - apps/ios/BuyLedger/Features/Orders/OrderDatePeriod.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardStats.swift
  - apps/ios/BuyLedgerTests/AppLockFeatureTests.swift
  - apps/ios/BuyLedger/Core/Persistence/CurrencyMetadataPersistence.swift
  - shared/data-model/schema/CampaignStatus.yaml
  - apps/ios/BuyLedgerTests/NumericInputGroupingScanTests.swift
  - apps/ios/BuyLedgerTests/CampaignReminderFailureTests.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/LedgerOrder.generated.swift
  - apps/ios/BuyLedgerTests/PersistenceRecoveryTests.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderMergeCandidateSheet.swift
  - shared/data-model/fixtures/expected/kotlin/SamplePreference.kt
  - apps/ios/BuyLedger/Features/Orders/Components/OrderRowView.swift
  - apps/ios/BuyLedger/Core/Persistence/CampaignPersistence.swift
  - apps/ios/README.md
  - apps/ios/BuyLedgerTests/CampaignPersistenceTests.swift
  - apps/ios/BuyLedgerTests/OllamaClientTests.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/Campaign.generated.swift
  - apps/ios/BuyLedger/Core/Sync/SyncQueueItem.swift
  - shared/data-model/schema/OrderStatus.yaml
  - apps/ios/BuyLedger/Features/Orders/OrderEditFeature.swift
  - shared/data-model/fixtures/expected/kotlin/SampleQuote.kt
  - apps/ios/BuyLedgerUITests/Tests/Insights/InsightsTests.swift
  - apps/ios/BuyLedger/Features/App/PersistenceFailureView.swift
  - apps/ios/BuyLedgerTests/OrdersLoadStateTests.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift
  - apps/ios/BuyLedger/Core/Domain/LedgerOrder+Samples.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFormatters.swift
  - apps/ios/BuyLedgerTests/BLUITestConfigurationTests.swift
  - apps/ios/BuyLedgerUITests-Performance.xctestplan
  - apps/ios/BuyLedgerTests/CampaignFeatureTests.swift
  - apps/ios/BuyLedger/Core/Testing/BLUITestSeedProfile.swift
  - apps/ios/BuyLedgerUITests/Support/MenuInteraction.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignSummary.swift
  - apps/ios/BuyLedger/Features/Customers/CustomersView.swift
  - apps/ios/BuyLedgerTests/OrderStatusTests.swift
  - shared/data-model/fixtures/expected/swift/SampleSequence.generated.swift
  - apps/ios/BuyLedger/Features/AISummary/AISummaryView.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupCatalog.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewMultiSelectBaseline.1.png
  - apps/ios/BuyLedger/Core/Domain/Campaign.swift
  - apps/ios/BuyLedgerTests/CampaignEditFeatureTests.swift
  - apps/ios/BuyLedgerUITests/Screens/FxScreen.swift
  - apps/ios/BuyLedgerTests/TestDependencies.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersRegularViewMultiSelectBaseline.1.png
  - apps/ios/BuyLedgerUITests/Support/AlertInteraction.swift
  - shared/data-model/fixtures/schema/sample-trait-matrix.yaml
  - apps/ios/BuyLedger/Core/Persistence/CampaignRecord.swift
  - apps/ios/BuyLedger/Features/Settings/AISummaryModelCatalog.swift
  - apps/ios/BuyLedger/Features/FX/ExchangeRateDTO.swift
  - apps/ios/BuyLedger/Core/Persistence/OrderRecord.swift
  - apps/ios/BuyLedger/Core/Dependencies/CalendarReminderClient.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestDependencyOverrides.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderEditDirtyTests.swift
  - apps/ios/BuyLedgerTests/AISummaryFeatureTests.swift
  - apps/ios/BuyLedgerTests/InsightsStatsTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewLongContentBaseline.1.png
  - apps/ios/BuyLedger/Core/Persistence/OrderPersistence.swift
  - apps/ios/BuyLedgerUITests/Screens/CampaignsScreen.swift
  - apps/ios/BuyLedger/Features/Orders/LedgerOrder+OrderMutation.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewBaseline.1.png
  - apps/ios/BuyLedgerTests/PhotoDataProcessorTests.swift
  - apps/ios/BuyLedger/Features/App/RootSidebarLayout.swift
  - shared/data-model/schema/CustomerTier.yaml
  - apps/ios/BuyLedgerTests/LookupManagementFeatureTests.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests.swift
  - apps/ios/BuyLedger/Core/Dependencies/ReconciliationStatusRepository.swift
  - apps/ios/BuyLedger/Core/Persistence/ReconciliationStatusPersistence.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewLongIdentifierBaseline.1.png
  - apps/ios/BuyLedger/Core/Persistence/ReconciliationStatusRecord.swift
  - apps/ios/BuyLedgerUITests/Screens/RootNavigationScreen.swift
  - apps/ios/BuyLedger/Core/Networking/ExchangeRateClient.swift
  - apps/ios/BuyLedger/Core/Networking/APIError.swift
  - shared/data-model/README.md
  - apps/ios/BuyLedgerTests/OrderPersistenceTests.swift
  - apps/ios/BuyLedgerTests/BLAccessibilityIDTests.swift
  - apps/ios/BuyLedger/Core/Persistence/PersistenceStoreQuarantine.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/ViewModifiers/BLHeroCardBackground.swift
  - apps/ios/BuyLedgerTests/InsightsFeatureTests.swift
  - apps/ios/BuyLedger/Core/Persistence/CampaignReminderRecord.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsDateRange.swift
  - apps/ios/BuyLedgerTests/QuoteFeatureTests.swift
  - shared/data-model/fixtures/expected/kotlin/SampleProfile.kt
  - apps/ios/BuyLedger/Core/Domain/OrderMerge.swift
  - shared/data-model/fixtures/expected/swift/SampleStatus.generated.swift
  - shared/data-model/fixtures/expected/swift/SampleGrade.generated.swift
  - shared/data-model/fixtures/expected/swift/SampleReceipt.generated.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsFeature.swift
  - apps/ios/BuyLedgerTests/InsightsAttributionTests.swift
  - apps/ios/BuyLedger/Core/Persistence/NameLookupRecord.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/CustomerTier.generated.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Progress/BLProgressBar.swift
  - README.md
  - apps/ios/BuyLedger/Core/Testing/BLUITestDependencyOverrides.swift
  - apps/ios/BuyLedger/Features/Orders/OrderDetailPath.swift
  - apps/ios/BuyLedgerTests/CampaignIntegrationTests.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsSnapshot.swift
  - apps/ios/BuyLedgerTests/OrderEditFeatureTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/quoteViewRateUnavailable.1.png
  - shared/data-model/schema/FxRateSnapshot.yaml
  - apps/ios/BuyLedgerTests/SchemaMigrationTests.swift
  - apps/ios/BuyLedgerTests/AppScenePhaseCoordinatorTests.swift
  - apps/ios/BuyLedger/Resources/Localizable.xcstrings
  - apps/ios/BuyLedgerTests/AppConfigurationTests.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardFeature.swift
  - apps/ios/BuyLedgerTests/DesignSystemSourceScanTests.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestSeedProfile.swift
  - AGENTS.md
  - apps/ios/BuyLedger/Shared/Localization/AppLanguage.swift
  - apps/ios/BuyLedger/Core/Sync/SyncMeta.swift
  - shared/data-model/fixtures/expected/typescript/SampleGrade.ts
  - apps/ios/BuyLedgerTests/AccessibilityConventionScanTests.swift
  - apps/ios/BuyLedgerTests/OrdersFeaturePerformanceTests.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersFeature+StateQuery.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignFeature.swift
  - apps/ios/BuyLedger/Core/Persistence/PersistenceContainer.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignDetailView.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/LedgerCustomer.generated.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Forms/PaymentMethodEditorSheet.swift
  - apps/ios/BuyLedgerUITests/Screens/CampaignDetailScreen.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersBatchOperations.swift
  - apps/ios/BuyLedgerTests/ExchangeRateClientTests.swift
  - .github/workflows/ci.yml
  - apps/ios/BuyLedgerUITests/Screens/MergeFlowScreen.swift
  - apps/ios/BuyLedger/Shared/Extensions/Image+Extensions.swift
  - apps/ios/BuyLedger/Features/Orders/Components/MergePhotoPickerSheet.swift
  - apps/ios/BuyLedgerUITests/Screens/CustomersScreen.swift
  - apps/ios/BuyLedger/Core/Domain/FxRateSnapshot.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoViewer.swift
  - apps/ios/BuyLedgerUITests/Support/TextInput.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupKind.swift
  - apps/ios/BuyLedger/Features/Quote/QuoteView.swift
  - apps/ios/BuyLedgerTests/OrdersFeatureTests.swift
  - shared/data-model/fixtures/expected/swift/SamplePreference.generated.swift
  - apps/ios/BuyLedgerTests/CurrencyMetadataCacheTests.swift
  - apps/ios/BuyLedger/Core/Domain/Campaign+Samples.swift
  - apps/ios/BuyLedgerUITests/Tests/Tools/QuoteTests.swift
  - apps/ios/BuyLedger/Core/Networking/HTTPMethod.swift
  - apps/ios/BuyLedger/Core/Persistence/BuyLedgerSchema.swift
  - apps/ios/BuyLedger/Features/App/AppScenePhaseCoordinator.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLTypography.swift
  - apps/ios/BuyLedgerTests/APIErrorMappingTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Tags/BLTagPill.swift
  - apps/ios/BuyLedgerUITests/Screens/AISummaryScreen.swift
  - apps/ios/BuyLedgerUITests/Screens/Screen.swift
  - shared/data-model/fixtures/expected/kotlin/SampleGrade.kt
  - apps/ios/BuyLedger/Core/Dependencies/PhotoClient.swift
  - apps/ios/BuyLedger/Shared/Extensions/Bundle+Extensions.swift
  - apps/ios/BuyLedgerUITests/Tests/Smoke/LaunchSmokeTests.swift
  - apps/ios/BuyLedgerTests/OrderMergeTests.swift
  - apps/ios/BuyLedger/Core/Persistence/NameLookupPersistence.swift
  - apps/ios/BuyLedgerTests/ProjectionWriteBoundaryTests.swift
  - apps/ios/BuyLedgerUITests/Support/ValueParsing.swift
  - apps/ios/BuyLedger/Shared/Extensions/Color+Extensions.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLTone.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrdersToolbarContent.swift
  - apps/ios/BuyLedgerTests/BLFormattersTests.swift
  - shared/data-model/fixtures/expected/typescript/SampleSequence.ts
  - shared/data-model/fixtures/expected/typescript/SampleReceipt.ts
  - apps/ios/BuyLedgerTests/OrdersBatchOperationsTests.swift
  - apps/ios/BuyLedger/Core/Domain/OrderSummary.swift
  - apps/ios/BuyLedger/Core/Domain/OrderStatus.swift
  - apps/ios/BuyLedger/Features/FX/ExchangeRateClient.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/FxRateSnapshot.generated.swift
  - apps/ios/BuyLedgerTests/OrdersSearchCancellationTests.swift
  - shared/data-model/generator/src/datamodel-gen.ts
  - apps/ios/BuyLedger/Core/Testing/BLUITestHarness.swift
tests:
  - shared/data-model/generator/test/datamodel-gen.test.ts
-->

---
### Requirement: Cancelling the merge leaves no changes

Dismissing the candidate sheet, the photo selection step, or cancelling the prefilled merge form SHALL leave every order unchanged in persistence and in memory.

#### Scenario: Cancel from the merge form

- **WHEN** the user cancels the prefilled merge form
- **THEN** no new order exists and both source orders keep their previous status


<!-- @trace
source: add-order-merge
updated: 2026-06-07
code:
  - apps/apple/BuyLedger/Features/Orders/OrdersView.swift
  - apps/apple/BuyLedger/Features/Orders/OrdersCompactView.swift
  - apps/apple/BuyLedger/Features/Orders/OrdersMacView.swift
  - apps/apple/BuyLedgerTests/OrderMergeFeatureTests.swift
  - apps/apple/BuyLedger/Features/Orders/OrdersFeature.swift
  - apps/apple/BuyLedger/Features/Orders/Components/OrderRowView.swift
  - apps/apple/BuyLedger/Features/Orders/Components/OrderMergeCandidateSheet.swift
  - apps/apple/BuyLedger/Features/Orders/OrderMergeFeature.swift
-->

---
### Requirement: Analytics attribution after a merge uses pre-merge revenue

Overall (non-categorized) revenue aggregates in Insights and Dashboard SHALL count a merge exactly once through its existing merge result at its merge date. Only orders in the existing realized-status allowlist SHALL be eligible for overall attribution, and the merged status SHALL NOT be part of that allowlist. Before each aggregation, the system SHALL build a set from the merged-source identifiers of all existing merge results and exclude any realized order whose identifier is in that set. If the merge result is deleted, its former sources SHALL no longer be excluded by the existing-merge-result guard; they SHALL be counted only if they otherwise satisfy the realized-status allowlist. If a merge result is cancelled, it remains an existing result and its sources SHALL remain excluded; neither the cancelled result nor its sources contributes revenue. Per-category and per-campaign breakdowns SHALL instead attribute revenue from "leaf" orders — orders whose merged-source list is empty; orders produced by a merge SHALL NOT contribute to per-category or per-campaign breakdowns. The category breakdown keeps its pre-existing status rule (the realized allowlist) extended with the merged status; campaign aggregates keep their pre-existing membership rules per the campaign-analytics-surfaces capability. A leaf order contributes with its own original categories, campaigns, amounts, and order date. Chained merges (merging an order that is itself a merge result) SHALL NOT cause double counting, because merge-produced orders never contribute to breakdowns and leaf orders are never removed by merging. The orders list status filter SHALL include the merged status so the user can still locate merged-away orders.

#### Scenario: Overall totals count the merge once

- **WHEN** two realized orders are merged and the new order is saved
- **THEN** overall revenue aggregates include only the new merged order's amounts, not the source orders'

#### Scenario: Reverted source does not inflate overall totals

- **WHEN** a merge source is changed back to a realized status while its merge result still exists
- **THEN** overall revenue aggregates continue to include the merge result only

#### Scenario: Reverting remains permitted

- **WHEN** the user changes a merge source back to a realized status
- **THEN** the status change succeeds, because it is the recovery path for an incorrect merge

#### Scenario: Deleted merge result restores its sources

- **WHEN** a merge result is deleted
- **THEN** its former source orders are no longer excluded from overall revenue aggregates

#### Scenario: Cancelled merge result keeps its sources excluded

- **WHEN** a merge result is changed to cancelled while it still exists
- **THEN** neither the cancelled result nor its sources contributes to overall revenue aggregates

#### Scenario: Category and campaign breakdowns use the pre-merge orders

- **WHEN** order A (category "beauty", campaign "May-JP", profit 1000) and order B (category "snacks", campaign "June-KR", profit 2000) are merged
- **THEN** the category breakdown shows beauty +1000 and snacks +2000, and the campaign breakdown shows May-JP +1000 and June-KR +2000, each at the source order's original date
- **AND** the merged order contributes to neither breakdown

##### Example: chained merge stays single-counted

- **GIVEN** leaf orders A (beauty, 1000) and B (snacks, 2000) merged into M1, then M1 merged with leaf order C (beauty, 500) into M2
- **WHEN** the category breakdown is computed
- **THEN** beauty = 1500 (A + C) and snacks = 2000 (B); M1 and M2 contribute nothing to the breakdown

#### Scenario: Merged orders remain findable

- **WHEN** the user filters the orders list by the merged status
- **THEN** the merged source orders are listed

##### Example: total attribution

| Source A status | Source B status | Result C status | Result C exists | Counted in overview total |
| --------------- | --------------- | --------------- | --------------- | ------------------------- |
| merged | merged | delivered | yes | C only |
| arrived (reverted) | merged | delivered | yes | C only |
| arrived (reverted) | arrived (reverted) | delivered | yes | C only |
| arrived | arrived | deleted | no | A and B |
| arrived | arrived | cancelled | yes | none |

<!-- @trace
source: revenue-attribution-single-source
updated: 2026-08-22
code:
  - apps/ios/BuyLedger/Core/Domain/Generated/OrderStatus.generated.swift
  - apps/ios/BuyLedger/Features/App/AppLockFeature.swift
  - apps/ios/BuyLedger/Features/AISummary/AISummaryFeature.swift
  - apps/ios/BuyLedgerTests/AccessibilityConventionScanTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Tags/BLTagPill.swift
  - apps/ios/BuyLedger/Features/Orders/OrderStatusFilter.swift
  - apps/ios/BuyLedger/Core/Dependencies/ReconciliationStatusRepository.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersView.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignDetailView.swift
  - apps/ios/BuyLedgerTests/OrdersBatchOperationsTests.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardView.swift
  - apps/ios/BuyLedgerUITests/Tests/Insights/InsightsTests.swift
  - apps/ios/BuyLedgerUITests/KeyboardDismissTests.swift
  - apps/ios/BuyLedger/Core/Sync/SyncMeta.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/quoteViewRateUnavailable.1.png
  - apps/ios/BuyLedger/Core/Networking/URLRequestBuilder.swift
  - apps/ios/BuyLedgerTests/AppConfigurationTests.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/FxRateSnapshot.generated.swift
  - apps/ios/BuyLedgerTests/PrivacyManifestTests.swift
  - apps/ios/BuyLedgerUITests/Screens/QuoteScreen.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsFeature.swift
  - shared/data-model/fixtures/expected/kotlin/SampleReceipt.kt
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementDestination.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderMergeCandidateSheet.swift
  - apps/ios/BuyLedgerTests/CurrencyMetadataCacheTests.swift
  - apps/ios/BuyLedger/Core/Persistence/OrderPersistence.swift
  - apps/ios/BuyLedger/Features/Quote/QuoteFeature.swift
  - apps/ios/BuyLedger/Shared/Media/PhotoDataProcessor.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/ViewModifiers/BLTypographyModifier.swift
  - apps/ios/BuyLedgerTests/BLFormattersTests.swift
  - apps/ios/BuyLedger/Features/AISummary/OllamaClient.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsSnapshot.swift
  - apps/ios/BuyLedgerUITests/Screens/AISummaryScreen.swift
  - apps/ios/BuyLedger/Features/App/RootTab.swift
  - apps/ios/BuyLedgerTests/AppScenePhaseCoordinatorTests.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersFilterOperations.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/LedgerCustomer.generated.swift
  - shared/data-model/fixtures/expected/typescript/SampleStatus.ts
  - apps/ios/BuyLedgerTests/OrderDraftTests.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/CurrencyCode.generated.swift
  - apps/ios/BuyLedger/Core/Domain/LedgerOrder+Samples.swift
  - apps/ios/BuyLedger/Core/Dependencies/TelemetryClient.swift
  - apps/ios/BuyLedgerTests/RootFeatureTests.swift
  - apps/ios/BuyLedgerTests/PhotoDataProcessorTests.swift
  - apps/ios/BuyLedger/Core/Persistence/OrderSourceRecord.swift
  - apps/ios/BuyLedger/Core/Persistence/PersistenceStoreQuarantine.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestSeedData.swift
  - shared/data-model/fixtures/schema/sample-orders.yaml
  - apps/ios/BuyLedgerTests/OrdersFilterOperationsTests.swift
  - apps/ios/BuyLedgerTests/OrdersLoadStateTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Avatar/BLAvatar.swift
  - apps/ios/BuyLedger/Core/Dependencies/CampaignRepository.swift
  - apps/ios/BuyLedger/Features/AISummary/AISummaryView.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignFeature.swift
  - CLAUDE.md
  - apps/ios/BuyLedgerUITests/Screens/OrdersScreen.swift
  - apps/ios/BuyLedger/App/AppDelegate.swift
  - apps/ios/BuyLedger/Core/Testing/BLUITestConfiguration.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLBarChart.swift
  - apps/ios/BuyLedgerUITests/Screens/OrderEditScreen.swift
  - apps/ios/BuyLedger/Core/Dependencies/OrderSourceRepository.swift
  - apps/ios/BuyLedgerTests/LayerBoundaryTests.swift
  - apps/ios/BuyLedgerTests/TestDependencies.swift
  - apps/ios/BuyLedger/Core/Persistence/CategoryRecord.swift
  - shared/data-model/fixtures/expected/kotlin/SampleStatus.kt
  - apps/ios/BuyLedger/Features/Insights/InsightsFeature.swift
  - apps/ios/BuyLedger/Core/Dependencies/NameLookupOperations.swift
  - apps/ios/BuyLedgerTests/OrderMergeFeatureTests.swift
  - apps/ios/BuyLedgerUITests/Support/AppNavigator.swift
  - apps/ios/BuyLedgerUITests/Tests/Tools/QuoteTests.swift
  - apps/ios/BuyLedger.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
  - apps/ios/BuyLedgerTests/PersistenceFailureFeatureTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/States/BLLoadFailureView.swift
  - shared/data-model/fixtures/expected/typescript/SampleProfile.ts
  - apps/ios/BuyLedger/Core/Persistence/CurrencyMetadataRecord.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsStorage.swift
  - apps/ios/BuyLedgerUITests/Tests/Smoke/HarnessSelfCheckTests.swift
  - apps/ios/BuyLedgerTests/CampaignReminderFailureTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/quoteViewBaseline.1.png
  - apps/ios/BuyLedger/Features/AISummary/OllamaDTO.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Buttons/BLButtonStyle.swift
  - apps/ios/BuyLedgerUITests/Tests/Campaigns/CampaignListTests.swift
  - apps/ios/BuyLedger/Core/Networking/ExchangeRateClient.swift
  - apps/ios/BuyLedgerUITests/Tests/Smoke/LaunchSmokeTests.swift
  - shared/data-model/schema/PaymentReceiptStatus.yaml
  - apps/ios/BuyLedger/Core/Dependencies/CampaignReminderRepository.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsDateRange.swift
  - apps/ios/BuyLedger/Core/Persistence/BuyLedgerSchema.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewLongContentBaseline.1.png
  - apps/ios/BuyLedger/Core/Dependencies/OpenSettingsClient.swift
  - apps/ios/BuyLedger/Features/Orders/Components/MergePhotoPickerSheet.swift
  - apps/ios/BuyLedger/Core/Persistence/CampaignRecord.swift
  - apps/ios/BuyLedger/Features/Orders/Components/PaymentMethodEditorSheet.swift
  - apps/ios/BuyLedger/Features/App/RootFeature.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Cards/BLCard.swift
  - apps/ios/BuyLedger/Features/App/AppLockView.swift
  - shared/data-model/fixtures/expected/typescript/SampleGrade.ts
  - apps/ios/BuyLedgerUITests-Performance.xctestplan
  - shared/data-model/schema/Campaign.yaml
  - shared/data-model/schema/OrderStatus.yaml
  - apps/ios/BuyLedger.xcodeproj/xcshareddata/xcschemes/BuyLedger.xcscheme
  - shared/data-model/schema/LedgerOrder.yaml
  - apps/ios/BuyLedger/Features/Orders/OrdersFeature.swift
  - shared/data-model/schema/Money.yaml
  - apps/ios/README.md
  - apps/ios/BuyLedger/Resources/GoogleService-Info.example.plist
  - apps/ios/BuyLedger/Core/Persistence/PaymentMethodRecord.swift
  - apps/ios/BuyLedger/Core/Sync/SyncQueueItem.swift
  - apps/ios/BuyLedger/Features/Orders/OrderDatePeriod.swift
  - shared/data-model/generator/src/datamodel-gen.ts
  - apps/ios/BuyLedger/Core/Testing/BLUITestHarness.swift
  - apps/ios/BuyLedgerTests/ColorContrast.swift
  - shared/data-model/schema/PaymentMethodInfo.yaml
  - apps/ios/BuyLedgerTests/AISummaryFeatureTests.swift
  - apps/ios/BuyLedgerUITests/Support/Waiting.swift
  - shared/data-model/README.md
  - apps/ios/BuyLedger/Features/Settings/AppLanguage.swift
  - apps/ios/BuyLedger/Features/Settings/SettingsView.swift
  - apps/ios/BuyLedger/Resources/Info.plist
  - apps/ios/BuyLedger/Features/FX/ExchangeRateDTO.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLHeatmapDepth.swift
  - apps/ios/BuyLedgerTests/TestSuiteIntegrityTests.swift
  - shared/data-model/fixtures/expected/swift/SampleStatus.generated.swift
  - apps/ios/BuyLedger/Features/App/RootSidebarLayout.swift
  - apps/ios/BuyLedger.xcodeproj/project.pbxproj
  - apps/ios/BuyLedger/Core/Persistence/CampaignReminderPersistence.swift
  - apps/ios/BuyLedgerTests/OrderCalculationTests.swift
  - apps/ios/BuyLedger/Features/Customers/CustomerRankBadgeStyle.swift
  - apps/ios/BuyLedgerUITests/Tests/Performance/LaunchPerformanceTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLFormatters.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignListView.swift
  - apps/ios/BuyLedgerTests/BiometricAuthClientTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrdersListTests.swift
  - apps/ios/BuyLedgerTests/OrdersSearchCancellationTests.swift
  - apps/ios/BuyLedgerUITests/Screens/CampaignDetailScreen.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersMergeFlowOperations.swift
  - shared/data-model/fixtures/expected/typescript/SamplePreference.ts
  - apps/ios/BuyLedgerUITests.xctestplan
  - apps/ios/BuyLedgerTests/CampaignPersistenceTests.swift
  - apps/ios/BuyLedger/Core/Persistence/NameLookupRecord.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsStats.swift
  - shared/data-model/schema/FxRateSnapshot.yaml
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderCreateTests.swift
  - apps/ios/BuyLedger/Core/Networking/APIError.swift
  - apps/ios/BuyLedgerUITests/Support/ValueParsing.swift
  - apps/ios/BuyLedgerTests/CampaignFeatureTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Badges/BLBadge.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Progress/BLProgressBar.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewBaseline.1.png
  - apps/ios/BuyLedger/App/Testing/BLUITestHarness.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestSeedProfile.swift
  - apps/ios/BuyLedger/Core/Persistence/NameLookupPersistence.swift
  - apps/ios/BuyLedger/Core/Persistence/ReconciliationStatusPersistence.swift
  - shared/data-model/fixtures/expected/typescript/SampleQuote.ts
  - shared/data-model/fixtures/expected/typescript/SampleSequence.ts
  - apps/ios/BuyLedgerTests/OllamaClientTests.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderDetailView.swift
  - shared/data-model/fixtures/expected/kotlin/SampleSequence.kt
  - apps/ios/BuyLedger/Features/Orders/Components/OrderRowView.swift
  - apps/ios/BuyLedger/Features/Customers/CustomersView.swift
  - apps/ios/BuyLedger/Core/Domain/FxRates.swift
  - apps/ios/BuyLedgerTests/InsightsAttributionTests.swift
  - apps/ios/BuyLedgerTests/OrderStatusTests.swift
  - apps/ios/BuyLedgerUITests/Screens/AppLockScreen.swift
  - apps/ios/BuyLedger/Core/Networking/AppConfiguration.swift
  - apps/ios/BuyLedger/Features/FX/FxView.swift
  - apps/ios/CLAUDE.md
  - apps/ios/BuyLedgerUITests/PhotoViewerPagingTests.swift
  - apps/ios/BuyLedger/Core/Dependencies/BiometricAuthClient.swift
  - apps/ios/BuyLedger/Core/Persistence/PersistenceError.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestConfiguration.swift
  - apps/ios/BuyLedger/Core/Dependencies/OrderRepository.swift
  - apps/ios/BuyLedger/Core/Persistence/PaymentMethodPersistence.swift
  - apps/ios/BuyLedgerTests/APIErrorMappingTests.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupCatalog.swift
  - apps/ios/BuyLedgerTests/SettingsFeatureTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLBarChartValue.swift
  - apps/ios/BuyLedger/Features/App/RootView.swift
  - apps/ios/BuyLedger/Core/Persistence/CurrencyMetadataPersistence.swift
  - apps/ios/BuyLedger/Features/App/PersistenceFailureFeature.swift
  - apps/ios/BuyLedger/Features/Orders/OrderMergeFeature.swift
  - apps/ios/BuyLedger/Core/Domain/Campaign+Samples.swift
  - apps/ios/BuyLedger/Resources/PrivacyInfo.xcprivacy
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoThumbnail.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Chips/BLFilterChip.swift
  - apps/ios/BuyLedgerUITests/Support/TextInput.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewLongIdentifierBaseline.1.png
  - shared/data-model/fixtures/expected/kotlin/SampleQuote.kt
  - shared/data-model/fixtures/schema/sample-enums.yaml
  - apps/ios/BuyLedgerUITests/Screens/CustomersScreen.swift
  - apps/ios/BuyLedgerTests/OrdersFeatureTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/ViewModifiers/BLCardShadow.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/PaymentMethodInfo.generated.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/CustomerTier.generated.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupNameEditorSheet.swift
  - .github/workflows/ci.yml
  - apps/ios/BuyLedger/Features/Orders/Components/OrdersToolbarContent.swift
  - apps/ios/BuyLedger/Shared/Extensions/Bundle+Extensions.swift
  - apps/ios/BuyLedgerUITests/Support/AlertInteraction.swift
  - apps/ios/BuyLedger/Features/App/PersistenceFailureView.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersCompactView.swift
  - apps/ios/BuyLedgerUITests/Support/BLUITestCase.swift
  - apps/ios/BuyLedgerUITests/Support/Diagnostics.swift
  - apps/ios/BuyLedger/Core/Persistence/OrderRecord.swift
  - apps/ios/BuyLedger/Features/FX/FxRates.swift
  - apps/ios/BuyLedger/Resources/Localizable.xcstrings
  - apps/ios/BuyLedgerTests/ProjectionWriteBoundaryTests.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersFeature+StateQuery.swift
  - apps/ios/BuyLedgerUITests/Screens/PhotoViewerScreen.swift
  - apps/ios/BuyLedger.xctestplan
  - apps/ios/BuyLedger/Features/Orders/Components/OrderSelectableRow.swift
  - shared/data-model/fixtures/expected/swift/SampleGrade.generated.swift
  - apps/ios/BuyLedger/Core/Persistence/OrderSourcePersistence.swift
  - apps/ios/BuyLedger/Features/FX/ExchangeRateClient.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/States/DelayedProgressView.swift
  - apps/ios/BuyLedger/Core/Dependencies/PhotoClient.swift
  - apps/ios/BuyLedgerAccessibilityIDs/BLAccessibilityID.swift
  - apps/ios/BuyLedger/Core/Dependencies/CalendarReminderClient.swift
  - apps/ios/BuyLedgerUITests/Support/SheetInteraction.swift
  - apps/ios/BuyLedgerTests/OrderEditFocusTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/persistenceFailureViewBaseline.1.png
  - apps/ios/BuyLedgerUITests/Support/MenuInteraction.swift
  - apps/ios/BuyLedgerTests/BLAccessibilityIDTests.swift
  - apps/ios/BuyLedger/Shared/Extensions/Color+Extensions.swift
  - apps/ios/BuyLedgerTests/PersistenceErrorContractTests.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignFormatters.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupKind.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoViewer.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardStats.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLDonutChart.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OptionPickerSheet.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFormatters.swift
  - apps/ios/BuyLedgerTests/InsightsStatsTests.swift
  - apps/ios/BuyLedger/Features/Orders/OrderDraft.swift
  - apps/ios/BuyLedgerTests/DesignSystemSourceScanTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewMergeContextBaseline.1.png
  - apps/ios/BuyLedger/Core/Diagnostics/CrashDiagnosticsClient.swift
  - apps/ios/BuyLedger/Core/Networking/ExchangeRateDTO.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/CampaignStatus.generated.swift
  - apps/ios/BuyLedger/Features/More/MoreView.swift
  - apps/ios/BuyLedgerTests/DashboardFeatureTests.swift
  - apps/ios/BuyLedgerTests/ContrastComplianceTests.swift
  - apps/ios/BuyLedgerTests/NameLookupPersistenceTests.swift
  - apps/ios/BuyLedger/Features/Orders/OrdersBatchOperations.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLDonutSegment.swift
  - apps/ios/BuyLedgerTests/CampaignIntegrationTests.swift
  - shared/data-model/schema/CurrencyCode.yaml
  - apps/ios/BuyLedger/Core/Domain/LedgerOrder.swift
  - apps/ios/BuyLedger/Features/Orders/OrderEditView.swift
  - apps/ios/BuyLedger/Core/Domain/OrderSummary.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift
  - apps/ios/BuyLedger/Resources/InfoPlist.xcstrings
  - apps/ios/BuyLedger/Core/Dependencies/PaymentMethodRepository.swift
  - apps/ios/BuyLedgerUITests/Screens/CampaignsScreen.swift
  - apps/ios/BuyLedgerUITests/Screens/OptionPickerScreen.swift
  - apps/ios/BuyLedger/Features/Orders/LedgerOrder+OrderMutation.swift
  - apps/ios/BuyLedger/Features/Quote/QuoteView.swift
  - apps/ios/BuyLedger/App/AppLaunchConfigurator.swift
  - apps/ios/BuyLedger/Core/Persistence/PersistenceContainer.swift
  - apps/ios/BuyLedgerUITests/Screens/OrderDetailScreen.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/dashboardViewBaseline.1.png
  - apps/ios/BuyLedgerTests/LookupCatalogTests.swift
  - apps/ios/BuyLedger/Features/Settings/AISummaryModelCatalog.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersRegularViewMultiSelectBaseline.1.png
  - apps/ios/BuyLedger/Core/Networking/HTTPMethod.swift
  - apps/ios/BuyLedgerTests/AppLockFeatureTests.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/Campaign.generated.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewBaseline.1.png
  - apps/ios/BuyLedger/Features/Customers/CustomersFeature.swift
  - apps/ios/BuyLedgerTests/BLUITestConfigurationTests.swift
  - apps/ios/BuyLedgerUITests/Screens/MergeFlowScreen.swift
  - shared/data-model/fixtures/expected/swift/SamplePreference.generated.swift
  - apps/ios/BuyLedgerUITests/Tests/Tools/FxTests.swift
  - apps/ios/BuyLedgerTests/LocalizationCatalogTests.swift
  - apps/ios/BuyLedger/Shared/Localization/AppLanguage.swift
  - shared/data-model/schema/CustomerTier.yaml
  - apps/ios/BuyLedger/Core/Domain/Campaign.swift
  - apps/ios/BuyLedgerTests/LookupManagementFeatureTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Campaigns/CampaignCrudTests.swift
  - shared/data-model/fixtures/expected/swift/SampleReceipt.generated.swift
  - apps/ios/BuyLedgerTests/ExchangeRateClientTests.swift
  - README.md
  - shared/data-model/fixtures/expected/kotlin/SampleGrade.kt
  - apps/ios/BuyLedgerTests/OrderEditFeatureTests.swift
  - apps/ios/BuyLedgerTests/InsightsFeatureTests.swift
  - apps/ios/BuyLedger/Core/Domain/CurrencyCode.swift
  - apps/ios/BuyLedger/Core/Persistence/PersistenceStoreQuarantineClient.swift
  - apps/ios/BuyLedgerTests/CalendarReminderTests.swift
  - apps/ios/BuyLedger/Core/Persistence/CampaignReminderRecord.swift
  - apps/ios/BuyLedgerTests/PaymentMethodPersistenceTests.swift
  - shared/data-model/schema/LedgerOrderItem.yaml
  - apps/ios/BuyLedger/Core/Testing/BLUITestDependencyOverrides.swift
  - apps/ios/BuyLedger/Features/FX/FxFeature.swift
  - shared/data-model/fixtures/expected/kotlin/SampleProfile.kt
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Pickers/OptionPickerSheet.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/PaymentReceiptStatus.generated.swift
  - apps/ios/BuyLedger/Core/Domain/FxRateSnapshot.swift
  - apps/ios/BuyLedgerUITests/Support/Scrolling.swift
  - shared/data-model/fixtures/expected/swift/SampleQuote.generated.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignEditFeature.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/Money.generated.swift
  - AGENTS.md
  - apps/ios/BuyLedgerTests/NumericInputGroupingScanTests.swift
  - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ordersCompactViewMultiSelectBaseline.1.png
  - apps/ios/BuyLedger/Shared/Extensions/Image+Extensions.swift
  - apps/ios/BuyLedger/Core/Dependencies/CategoryRepository.swift
  - apps/ios/BuyLedger/Features/Orders/OrderDetailPath.swift
  - apps/ios/BuyLedger/Features/App/RootTabLayout.swift
  - apps/ios/BuyLedger/Core/Persistence/CategoryPersistence.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/LedgerOrderItem.generated.swift
  - apps/ios/BuyLedgerTests/OrderPersistenceTests.swift
  - apps/ios/BuyLedger/App/Testing/BLUITestDependencyOverrides.swift
  - apps/ios/BuyLedger/Core/Persistence/CampaignPersistence.swift
  - apps/ios/BuyLedger/Features/Insights/InsightsView.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignEditView.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderMergeTests.swift
  - shared/data-model/fixtures/expected/swift/SampleProfile.generated.swift
  - shared/data-model/fixtures/expected/kotlin/SamplePreference.kt
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLTone.swift
  - apps/ios/BuyLedger/Core/Domain/OrderMerge.swift
  - apps/ios/BuyLedgerTests/OrdersFeaturePerformanceTests.swift
  - apps/ios/BuyLedger/Core/Persistence/ReconciliationStatusRecord.swift
  - apps/ios/BuyLedgerUITests/Screens/CampaignEditScreen.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/AISummaryTests.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderFilterSheet.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLPalette.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLStatusHue.swift
  - apps/ios/BuyLedgerUITests/Screens/DashboardScreen.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Status/BLStatusPill.swift
  - apps/ios/BuyLedger/Core/Dependencies/CurrencyMetadataRepository.swift
  - apps/ios/BuyLedgerUITests/Screens/SettingsScreen.swift
  - apps/ios/BuyLedgerTests/DashboardStatsTests.swift
  - apps/ios/BuyLedger/App/BuyLedgerApp.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLSparkline.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLTypography.swift
  - apps/ios/BuyLedger/Features/App/SidebarBadgeCounts.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/ViewModifiers/BLHeroCardBackground.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/Forms/PaymentMethodEditorSheet.swift
  - apps/ios/BuyLedgerTests/OrderMergeTests.swift
  - apps/ios/BuyLedgerUITests/Screens/InsightsScreen.swift
  - apps/ios/BuyLedger/Core/Testing/BLUITestSeedData.swift
  - apps/ios/BuyLedgerUITests/Tests/Customers/CustomersTests.swift
  - apps/ios/BuyLedgerUITests/Screens/RootNavigationScreen.swift
  - apps/ios/BuyLedgerTests/CustomersFeatureTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLMetrics.swift
  - apps/ios/BuyLedger/Core/Domain/Generated/LedgerOrder.generated.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignSummary.swift
  - apps/ios/BuyLedgerTests/BLPhotoViewerTests.swift
  - apps/ios/BuyLedgerTests/SnapshotTests.swift
  - apps/ios/BuyLedgerUITests/Screens/FxScreen.swift
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderDetailTests.swift
  - shared/data-model/schema/CampaignStatus.yaml
  - apps/ios/BuyLedger/Core/Networking/HTTPClient.swift
  - apps/ios/BuyLedgerTests/SchemaMigrationTests.swift
  - apps/ios/BuyLedger/Core/Testing/BLUITestSeedProfile.swift
  - apps/ios/BuyLedgerUITests/Support/Assertions.swift
  - apps/ios/BuyLedgerTests/FxFeatureTests.swift
  - apps/ios/BuyLedger/Core/Domain/OrderStatus.swift
  - apps/ios/BuyLedgerUITests/Screens/Screen.swift
  - apps/ios/BuyLedger/Features/Lookups/LookupManagementView.swift
  - shared/data-model/schema/LedgerCustomer.yaml
  - apps/ios/BuyLedger/Shared/Extensions/Decimal+Extensions.swift
  - apps/ios/BuyLedgerTests/HTTPClientTests.swift
  - apps/ios/BuyLedgerTests/CampaignEditFeatureTests.swift
  - apps/ios/BuyLedgerTests/ColorContrastTests.swift
  - apps/ios/BuyLedger/Features/Dashboard/DashboardFeature.swift
  - shared/data-model/fixtures/schema/sample-trait-matrix.yaml
  - apps/ios/BuyLedgerUITests/Tests/Orders/OrderEditDirtyTests.swift
  - apps/ios/BuyLedgerUITests/Support/LaunchOptions.swift
  - apps/ios/BuyLedgerTests/CampaignSummaryTests.swift
  - shared/data-model/fixtures/expected/swift/SampleSequence.generated.swift
  - apps/ios/BuyLedger/Features/Orders/OrderEditFeature.swift
  - apps/ios/BuyLedgerTests/QuoteFeatureTests.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderStatus+Presentation.swift
  - apps/ios/BuyLedger/Features/App/AppScenePhaseCoordinator.swift
  - apps/ios/BuyLedger/Core/Domain/LedgerOrderItem.swift
  - apps/ios/BuyLedgerUITests/Tests/Campaigns/CampaignDetailTests.swift
  - shared/data-model/fixtures/expected/typescript/SampleReceipt.ts
  - apps/ios/BuyLedgerTests/PersistenceRecoveryTests.swift
  - apps/ios/BuyLedgerUITests/Tests/Smoke/AppLockTests.swift
  - apps/ios/BuyLedger/Shared/DesignSystem/Components/States/BLDelayedProgressView.swift
tests:
  - shared/data-model/generator/test/datamodel-gen.test.ts
-->