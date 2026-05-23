# lookup-management Specification

## Purpose

TBD - created by archiving change 'lookup-management-macos-card-style'. Update Purpose after archive.

## Requirements

### Requirement: Platform-adaptive lookup management presentation

The lookup management screen (used for order source, category, and payment method) SHALL render a Design System card layout on macOS and SHALL render a system List on iOS and iPadOS. The choice of layout MUST NOT change the available operations or the underlying data.

#### Scenario: macOS renders the card layout

- **WHEN** the order source, category, or payment method management screen is shown on macOS
- **THEN** the screen presents a scrolling view with the Design System background and the items inside a single card with separators between rows, visually consistent with the customer list screen

#### Scenario: iOS and iPadOS keep the system List

- **WHEN** the order source, category, or payment method management screen is shown on iOS or iPadOS
- **THEN** the screen presents the system List with a section header, trailing swipe actions for delete and rename, and the existing footer, unchanged from before this change


<!-- @trace
source: lookup-management-macos-card-style
updated: 2026-05-24
code:
  - .agents/skills/spectra-discuss/SKILL.md
  - .agents/skills/spectra-drift/SKILL.md
  - .agents/skills/spectra-ingest/SKILL.md
  - .agents/skills/spectra-apply/SKILL.md
  - .agents/skills/spectra-propose/SKILL.md
  - BuyLedger/BuyLedger/Features/Lookups/LookupManagementView.swift
-->

---
### Requirement: Lookup item management operations are preserved across platforms

The screen SHALL allow the user to add, rename, and delete lookup items on every platform. The add, rename, and delete operations and their validation SHALL behave identically regardless of the platform layout, and SHALL write through the same management feature as before this change.

#### Scenario: Add a lookup item

- **WHEN** the user activates the toolbar add control and confirms a non-empty, trimmed name
- **THEN** the item is added through the management feature and appears in the list

#### Scenario: Rename a lookup item

- **WHEN** the user triggers rename on an item and confirms a non-empty name different from the original
- **THEN** the item is renamed through the management feature and orders referencing the old name are updated

#### Scenario: Delete a lookup item

- **WHEN** the user triggers delete on an item
- **THEN** the item is removed through the management feature

#### Scenario: macOS rename and delete use the context menu

- **WHEN** the user opens the context menu on an item row on macOS
- **THEN** the menu offers rename and delete, matching the behavior available before this change

#### Scenario: iOS swipe-to-delete is retained

- **WHEN** the user swipes an item row on iOS or iPadOS
- **THEN** the swipe actions for delete and rename are available, unchanged from before this change


<!-- @trace
source: lookup-management-macos-card-style
updated: 2026-05-24
code:
  - .agents/skills/spectra-discuss/SKILL.md
  - .agents/skills/spectra-drift/SKILL.md
  - .agents/skills/spectra-ingest/SKILL.md
  - .agents/skills/spectra-apply/SKILL.md
  - .agents/skills/spectra-propose/SKILL.md
  - BuyLedger/BuyLedger/Features/Lookups/LookupManagementView.swift
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
  - BuyLedger/BuyLedger/Features/Lookups/LookupManagementView.swift
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
  - BuyLedger/BuyLedger/Features/Lookups/LookupManagementView.swift
-->