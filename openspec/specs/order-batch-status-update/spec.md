# order-batch-status-update Specification

## Purpose

TBD - created by archiving change 'order-batch-status-update'. Update Purpose after archive.

## Requirements

### Requirement: Orders list provides a multi-select mode

The orders list SHALL provide a multi-select mode on iOS, iPadOS, macOS, and Web. The system SHALL provide a control to enter and exit multi-select mode. While in multi-select mode, tapping or clicking an order row SHALL toggle that order's selection instead of navigating to its detail. The system SHALL provide a way to select all orders in the current filtered list and to clear the current selection, and SHALL display the count of currently selected orders. Exiting multi-select mode SHALL clear the current selection.

#### Scenario: Enter multi-select and toggle selection

- **WHEN** the user enters multi-select mode and taps two order rows
- **THEN** both rows show as selected, the selected count shows 2, and neither tap navigates to order detail

#### Scenario: Select all then clear

- **WHEN** the user taps "select all" with a filtered list of 5 orders, then taps "clear selection"
- **THEN** the selected count goes to 5 and then to 0

#### Scenario: Exiting clears selection

- **WHEN** the user has selected orders and exits multi-select mode
- **THEN** the selection is empty and rows return to navigating to detail on tap


<!-- @trace
source: order-batch-status-update
updated: 2026-06-20
code:
  - apps/apple/BuyLedgerTests/OrderPersistenceTests.swift
  - apps/apple/BuyLedger.xcodeproj/project.pbxproj
  - apps/backend/src/orders/orders.types.ts
  - apps/apple/CLAUDE.md
  - apps/backend/README.md
  - apps/apple/BuyLedger/Core/Persistence/OrderPersistence.swift
  - apps/apple/BuyLedger/Features/Orders/OrdersFeature.swift
  - apps/apple/BuyLedger/Features/Orders/OrdersView.swift
  - apps/apple/BuyLedgerTests/OrdersFeatureTests.swift
  - apps/web/src/components/OrderRow.tsx
  - apps/backend/src/orders/orders.service.ts
  - apps/web/src/lib/api.ts
  - apps/web/src/lib/queries.ts
  - apps/web/src/app/orders/page.tsx
  - apps/apple/BuyLedger/Features/Orders/OrdersMacView.swift
  - apps/apple/BuyLedger/Core/Dependencies/OrderRepository.swift
  - apps/apple/BuyLedger/Features/Orders/OrdersCompactView.swift
  - apps/backend/src/orders/orders.controller.ts
tests:
  - apps/backend/src/orders/orders.service.spec.ts
-->

---
### Requirement: Batch apply a single target status to selected orders

The system SHALL allow the user, while orders are selected, to choose one target `OrderStatus` and apply it to every selected order in a single batch action. After the batch action completes, the system SHALL exit multi-select mode and clear the selection, and the order list SHALL reflect each affected order's new status.

#### Scenario: Apply target status to multiple orders

- **WHEN** the user selects three orders and applies the target status "purchased"
- **THEN** all three orders' status becomes "purchased", the list reflects the change, and the app exits multi-select mode with an empty selection

#### Scenario: Orders already at the target status are skipped

- **WHEN** the user selects orders where some already have the target status and applies that target status
- **THEN** orders already at the target status are left unchanged and only the remaining orders are updated

##### Example: mixed-status batch to "arrived"

- **GIVEN** selected orders: O1(status=shipping), O2(status=arrived), O3(status=shipping)
- **WHEN** the user applies target status "arrived"
- **THEN** O1 and O3 become "arrived" and O2 is unchanged (no rewrite)


<!-- @trace
source: order-batch-status-update
updated: 2026-06-20
code:
  - apps/apple/BuyLedgerTests/OrderPersistenceTests.swift
  - apps/apple/BuyLedger.xcodeproj/project.pbxproj
  - apps/backend/src/orders/orders.types.ts
  - apps/apple/CLAUDE.md
  - apps/backend/README.md
  - apps/apple/BuyLedger/Core/Persistence/OrderPersistence.swift
  - apps/apple/BuyLedger/Features/Orders/OrdersFeature.swift
  - apps/apple/BuyLedger/Features/Orders/OrdersView.swift
  - apps/apple/BuyLedgerTests/OrdersFeatureTests.swift
  - apps/web/src/components/OrderRow.tsx
  - apps/backend/src/orders/orders.service.ts
  - apps/web/src/lib/api.ts
  - apps/web/src/lib/queries.ts
  - apps/web/src/app/orders/page.tsx
  - apps/apple/BuyLedger/Features/Orders/OrdersMacView.swift
  - apps/apple/BuyLedger/Core/Dependencies/OrderRepository.swift
  - apps/apple/BuyLedger/Features/Orders/OrdersCompactView.swift
  - apps/backend/src/orders/orders.controller.ts
tests:
  - apps/backend/src/orders/orders.service.spec.ts
-->

---
### Requirement: Batch target status list excludes merged

The batch target status options SHALL exclude `merged`. The system SHALL NOT allow a user to set `merged` via the batch action, because `merged` is written only by the order merge flow.

#### Scenario: merged is not offered as a batch target

- **WHEN** the user opens the batch status picker
- **THEN** the option list contains every `OrderStatus` except `merged`


<!-- @trace
source: order-batch-status-update
updated: 2026-06-20
code:
  - apps/apple/BuyLedgerTests/OrderPersistenceTests.swift
  - apps/apple/BuyLedger.xcodeproj/project.pbxproj
  - apps/backend/src/orders/orders.types.ts
  - apps/apple/CLAUDE.md
  - apps/backend/README.md
  - apps/apple/BuyLedger/Core/Persistence/OrderPersistence.swift
  - apps/apple/BuyLedger/Features/Orders/OrdersFeature.swift
  - apps/apple/BuyLedger/Features/Orders/OrdersView.swift
  - apps/apple/BuyLedgerTests/OrdersFeatureTests.swift
  - apps/web/src/components/OrderRow.tsx
  - apps/backend/src/orders/orders.service.ts
  - apps/web/src/lib/api.ts
  - apps/web/src/lib/queries.ts
  - apps/web/src/app/orders/page.tsx
  - apps/apple/BuyLedger/Features/Orders/OrdersMacView.swift
  - apps/apple/BuyLedger/Core/Dependencies/OrderRepository.swift
  - apps/apple/BuyLedger/Features/Orders/OrdersCompactView.swift
  - apps/backend/src/orders/orders.controller.ts
tests:
  - apps/backend/src/orders/orders.service.spec.ts
-->

---
### Requirement: Batch status persistence is atomic on Apple

On Apple platforms (iOS, iPadOS, macOS) where orders persist to the local store, a batch status update SHALL persist all changed orders in a single save operation rather than one save per order.

#### Scenario: Single persistence for a multi-order batch

- **WHEN** a batch status update changes the status of four orders
- **THEN** all four changed orders are written to the local store in one save operation


<!-- @trace
source: order-batch-status-update
updated: 2026-06-20
code:
  - apps/apple/BuyLedgerTests/OrderPersistenceTests.swift
  - apps/apple/BuyLedger.xcodeproj/project.pbxproj
  - apps/backend/src/orders/orders.types.ts
  - apps/apple/CLAUDE.md
  - apps/backend/README.md
  - apps/apple/BuyLedger/Core/Persistence/OrderPersistence.swift
  - apps/apple/BuyLedger/Features/Orders/OrdersFeature.swift
  - apps/apple/BuyLedger/Features/Orders/OrdersView.swift
  - apps/apple/BuyLedgerTests/OrdersFeatureTests.swift
  - apps/web/src/components/OrderRow.tsx
  - apps/backend/src/orders/orders.service.ts
  - apps/web/src/lib/api.ts
  - apps/web/src/lib/queries.ts
  - apps/web/src/app/orders/page.tsx
  - apps/apple/BuyLedger/Features/Orders/OrdersMacView.swift
  - apps/apple/BuyLedger/Core/Dependencies/OrderRepository.swift
  - apps/apple/BuyLedger/Features/Orders/OrdersCompactView.swift
  - apps/backend/src/orders/orders.controller.ts
tests:
  - apps/backend/src/orders/orders.service.spec.ts
-->

---
