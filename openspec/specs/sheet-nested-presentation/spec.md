# sheet-nested-presentation Specification

## Purpose

本規格涵蓋 sheet 疊層情境下的具體呈現方式，包括 sheet 內揀選器改以推入導覽呈現、新增子編輯器避免第三層 sheet、頂層單一 sheet 揀選器的保留、媒體檢視器以全螢幕模態呈現、多步驟 sheet 後續步驟使用返回鍵。不涵蓋 `navigation-path-integrity` 所訂的同一時間僅一層模態、單一目的地單一路徑等一般性導覽規則。

## Requirements

### Requirement: Present in-sheet pickers via push navigation

When a picker or sub-editor is opened from within an already-presented sheet, it SHALL be presented by pushing onto the host sheet's navigation stack (gaining a system Back control) rather than by stacking a second sheet on top. This applies to the order editor's selection pickers (order source, category, payment method, reconciliation status, currency, campaign). Only one such picker SHALL be pushed at a time, and its Back control SHALL return to the parent form with no change to the selectable options or the selection outcome. The campaign editor's reminder time is instead edited inline in the form (see its scenario) — no separate presentation at all, which trivially avoids stacking a second sheet.

#### Scenario: Selecting from the order editor pushes instead of stacking a sheet

- **WHEN** the user taps a selection picker row inside the order editor sheet
- **THEN** the picker is pushed onto the same navigation stack with a Back control, and no second sheet is stacked over the editor

#### Scenario: Back returns to the editor form

- **WHEN** a pushed picker is showing and the user taps Back
- **THEN** the picker is popped and the editor form is shown, with any completed selection already applied

#### Scenario: Reminder time is edited inline in the campaign editor

- **WHEN** the user enables the reminder toggle in the campaign editor sheet
- **THEN** the reminder date and time appear as an inline DatePicker row within the form (identical to the open/close date rows, opening the system's native calendar/time popover on tap), with no separate sheet, push, or dialog presented


<!-- @trace
source: sheet-hig-compliance
updated: 2026-07-19
code:
  - apps/ios/BuyLedger.xcodeproj/project.pbxproj
  - apps/ios/BuyLedger/Features/Orders/OrderEditFeature.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignEditView.swift
  - apps/ios/BuyLedger/Features/Orders/Components/PaymentMethodEditorSheet.swift
  - apps/ios/BuyLedger/Features/Orders/OrderMergeFeature.swift
  - apps/ios/BuyLedger/Resources/InfoPlist.xcstrings
  - apps/ios/BuyLedgerTests/CampaignEditFeatureTests.swift
  - apps/ios/BuyLedgerTests/OrderMergeFeatureTests.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignEditFeature.swift
  - apps/ios/BuyLedgerTests/CampaignFeatureTests.swift
  - apps/ios/BuyLedgerTests/OrderEditFeatureTests.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderMergeCandidateSheet.swift
  - apps/ios/BuyLedger/Resources/Localizable.xcstrings
  - apps/ios/CLAUDE.md
  - apps/ios/BuyLedger/Features/Orders/Components/OptionPickerSheet.swift
  - apps/ios/BuyLedger/Features/Orders/OrderEditView.swift
-->

---
### Requirement: Add-new sub-editors avoid a third stacked sheet

When the user adds a new item from within a picker that is itself presented inside an editing sheet — specifically adding a payment method from the order editor's payment method picker — the add-new editor SHALL be pushed onto the current navigation stack rather than presented as an additional sheet, so the presentation never exceeds one sheet plus in-sheet navigation.

#### Scenario: Adding a payment method pushes rather than stacking a third sheet

- **WHEN** the user taps "add payment method" from within the order editor's payment method picker
- **THEN** the add-payment-method editor is pushed onto the current navigation stack, and at no point are three sheets stacked


<!-- @trace
source: sheet-hig-compliance
updated: 2026-07-19
code:
  - apps/ios/BuyLedger.xcodeproj/project.pbxproj
  - apps/ios/BuyLedger/Features/Orders/OrderEditFeature.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignEditView.swift
  - apps/ios/BuyLedger/Features/Orders/Components/PaymentMethodEditorSheet.swift
  - apps/ios/BuyLedger/Features/Orders/OrderMergeFeature.swift
  - apps/ios/BuyLedger/Resources/InfoPlist.xcstrings
  - apps/ios/BuyLedgerTests/CampaignEditFeatureTests.swift
  - apps/ios/BuyLedgerTests/OrderMergeFeatureTests.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignEditFeature.swift
  - apps/ios/BuyLedgerTests/CampaignFeatureTests.swift
  - apps/ios/BuyLedgerTests/OrderEditFeatureTests.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderMergeCandidateSheet.swift
  - apps/ios/BuyLedger/Resources/Localizable.xcstrings
  - apps/ios/CLAUDE.md
  - apps/ios/BuyLedger/Features/Orders/Components/OptionPickerSheet.swift
  - apps/ios/BuyLedger/Features/Orders/OrderEditView.swift
-->

---
### Requirement: Preserve top-level single-sheet picker presentation

The shared option picker component SHALL retain its self-contained sheet presentation (its own navigation stack and cancel control) when invoked directly from a main-interface surface — the settings, quote, exchange-rate, and orders filtering pickers. Making the picker embeddable for push navigation SHALL NOT change the appearance or interaction of these top-level single-sheet call sites.

#### Scenario: Main-interface pickers are unchanged

- **WHEN** the user opens a currency, model, category, or payment method picker directly from the settings, quote, exchange-rate, or orders screen
- **THEN** the picker is presented as a single self-contained sheet with its own cancel control, exactly as before this change


<!-- @trace
source: sheet-hig-compliance
updated: 2026-07-19
code:
  - apps/ios/BuyLedger.xcodeproj/project.pbxproj
  - apps/ios/BuyLedger/Features/Orders/OrderEditFeature.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignEditView.swift
  - apps/ios/BuyLedger/Features/Orders/Components/PaymentMethodEditorSheet.swift
  - apps/ios/BuyLedger/Features/Orders/OrderMergeFeature.swift
  - apps/ios/BuyLedger/Resources/InfoPlist.xcstrings
  - apps/ios/BuyLedgerTests/CampaignEditFeatureTests.swift
  - apps/ios/BuyLedgerTests/OrderMergeFeatureTests.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignEditFeature.swift
  - apps/ios/BuyLedgerTests/CampaignFeatureTests.swift
  - apps/ios/BuyLedgerTests/OrderEditFeatureTests.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderMergeCandidateSheet.swift
  - apps/ios/BuyLedger/Resources/Localizable.xcstrings
  - apps/ios/CLAUDE.md
  - apps/ios/BuyLedger/Features/Orders/Components/OptionPickerSheet.swift
  - apps/ios/BuyLedger/Features/Orders/OrderEditView.swift
-->

---
### Requirement: Present media viewers as full-screen modals

Read-only media viewers opened from within an editing sheet SHALL be presented as a full-screen modal rather than as a second sheet stacked on the editor. Specifically, the order editor's photo viewer SHALL be presented with a full-screen cover.

#### Scenario: Photo viewer opens as a full-screen cover

- **WHEN** the user taps a photo thumbnail inside the order editor sheet
- **THEN** the photo viewer is presented as a full-screen modal (full-screen cover), not as a second sheet stacked on the editor, and its close control returns to the editor


<!-- @trace
source: sheet-hig-compliance
updated: 2026-07-19
code:
  - apps/ios/BuyLedger.xcodeproj/project.pbxproj
  - apps/ios/BuyLedger/Features/Orders/OrderEditFeature.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignEditView.swift
  - apps/ios/BuyLedger/Features/Orders/Components/PaymentMethodEditorSheet.swift
  - apps/ios/BuyLedger/Features/Orders/OrderMergeFeature.swift
  - apps/ios/BuyLedger/Resources/InfoPlist.xcstrings
  - apps/ios/BuyLedgerTests/CampaignEditFeatureTests.swift
  - apps/ios/BuyLedgerTests/OrderMergeFeatureTests.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignEditFeature.swift
  - apps/ios/BuyLedgerTests/CampaignFeatureTests.swift
  - apps/ios/BuyLedgerTests/OrderEditFeatureTests.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderMergeCandidateSheet.swift
  - apps/ios/BuyLedger/Resources/Localizable.xcstrings
  - apps/ios/CLAUDE.md
  - apps/ios/BuyLedger/Features/Orders/Components/OptionPickerSheet.swift
  - apps/ios/BuyLedger/Features/Orders/OrderEditView.swift
-->

---
### Requirement: Multi-step sheets use Back on subsequent steps

When a sheet presents a multi-step flow, steps after the first SHALL be pushed onto the sheet's navigation stack so they carry the system Back control (in place of Cancel) with native push/pop animation, rather than swapping content in place. Cancel, Done, and Back SHALL NOT all appear together on one step.

#### Scenario: Merge photo-selection step is pushed with a system Back control

- **WHEN** the merge flow advances to the "choose which photos to keep" step
- **THEN** the step is pushed onto the sheet's navigation stack with the system Back control (not Cancel) that, when tapped, animates back to candidate selection and clears the in-progress photo selection, while the trailing control remains "continue"

<!-- @trace
source: sheet-hig-compliance
updated: 2026-07-19
code:
  - apps/ios/BuyLedger.xcodeproj/project.pbxproj
  - apps/ios/BuyLedger/Features/Orders/OrderEditFeature.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignEditView.swift
  - apps/ios/BuyLedger/Features/Orders/Components/PaymentMethodEditorSheet.swift
  - apps/ios/BuyLedger/Features/Orders/OrderMergeFeature.swift
  - apps/ios/BuyLedger/Resources/InfoPlist.xcstrings
  - apps/ios/BuyLedgerTests/CampaignEditFeatureTests.swift
  - apps/ios/BuyLedgerTests/OrderMergeFeatureTests.swift
  - apps/ios/BuyLedger/Features/Campaigns/CampaignEditFeature.swift
  - apps/ios/BuyLedgerTests/CampaignFeatureTests.swift
  - apps/ios/BuyLedgerTests/OrderEditFeatureTests.swift
  - apps/ios/BuyLedger/Features/Orders/Components/OrderMergeCandidateSheet.swift
  - apps/ios/BuyLedger/Resources/Localizable.xcstrings
  - apps/ios/CLAUDE.md
  - apps/ios/BuyLedger/Features/Orders/Components/OptionPickerSheet.swift
  - apps/ios/BuyLedger/Features/Orders/OrderEditView.swift
-->