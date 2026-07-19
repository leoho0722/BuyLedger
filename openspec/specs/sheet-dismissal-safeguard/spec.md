# sheet-dismissal-safeguard Specification

## Purpose

TBD - created by archiving change 'sheet-hig-compliance'. Update Purpose after archive.

## Requirements

### Requirement: Guard edit sheets against silent data loss on dismissal

Each editing sheet that holds user-entered draft data — the order editor, the campaign editor, and the payment method editor — SHALL track whether its draft differs from the values it was opened with (a dirty state). While the sheet is dirty, it SHALL prevent interactive swipe-to-dismiss so that unsaved changes cannot be lost silently. The dirty state SHALL be derived from all editable draft fields of that sheet, not a partial subset.

#### Scenario: Dirty edit sheet resists swipe-to-dismiss

- **WHEN** the user has modified at least one draft field in the order, campaign, or payment method editor and then swipes down to dismiss the sheet
- **THEN** the sheet does not dismiss and the draft is preserved

#### Scenario: Clean edit sheet dismisses freely

- **WHEN** the user opens an editor and swipes down to dismiss without modifying any draft field
- **THEN** the sheet dismisses immediately without any confirmation


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
### Requirement: Confirm discarding unsaved changes when cancelling

When an editing sheet is dirty and the user taps its cancel control, the sheet SHALL present a confirmation dialog offering a destructive "discard changes" choice and a non-destructive "keep editing" choice, rather than dismissing directly. Choosing discard SHALL dismiss the sheet without saving; choosing keep editing SHALL leave the sheet open with the draft intact. When the sheet is not dirty, the cancel control SHALL dismiss directly without a confirmation dialog.

#### Scenario: Cancel with unsaved changes asks for confirmation

- **WHEN** the user has modified a draft field and taps the cancel control
- **THEN** a confirmation dialog appears with "discard changes" (destructive) and "keep editing" options

#### Scenario: Discard confirmed dismisses without saving

- **WHEN** the confirmation dialog is showing and the user chooses "discard changes"
- **THEN** the sheet dismisses and no draft changes are persisted

#### Scenario: Keep editing returns to the form

- **WHEN** the confirmation dialog is showing and the user chooses "keep editing"
- **THEN** the confirmation dialog closes and the sheet stays open with the draft unchanged

#### Scenario: Cancel without changes dismisses directly

- **WHEN** the user taps the cancel control without having modified any draft field
- **THEN** the sheet dismisses immediately without a confirmation dialog

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