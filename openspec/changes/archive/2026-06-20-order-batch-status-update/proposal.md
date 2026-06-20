## Why

目前三平台 (iOS / iPadOS / macOS 與 Web) 的訂單列表都只能一次更新一筆訂單的狀態，必須逐筆進入詳情頁操作。代購流程中常需要把同一批貨的多筆訂單一起推進到同一個狀態 (例如整批「已下單」、整批「集運中」、整批「已到貨」)，逐筆操作費時且容易漏改。提供「多選訂單後批次套用同一狀態」可大幅降低重複操作成本。

## What Changes

- 訂單列表新增「多選模式」：可進入／退出選取模式，於模式中勾選多筆訂單，並提供全選／清除與已選筆數提示。
- 多選模式下提供「批次更改狀態」動作：選定一個目標 `OrderStatus` 後，一次套用到所有已選訂單。
- 狀態選單沿用既有排除規則：`merged` 不可被使用者手動指定 (僅合併流程能寫入)；批次目標狀態清單一律排除 `merged`。
- Apple 端透過本機 SwiftData 一次性原子落盤 (循 `mergeOrders` 既有模式：actor 內 fetch→逐筆以 memberwise init 重建→單次 save)，避免逐筆寫入。
- Backend 新增批次更新狀態端點，依 `ownerUid` 圈訂單，以 `updateMany` 更新後重新鏡像 (remirror) 受影響訂單至 Firestore。
- Web 端訂單列表加入多選 UI 與批次操作工具列，串接新後端端點；批次 mutation 成功後沿用既有的 `orders` + `campaigns` 查詢失效 (invalidate)。
- 各平台批次操作完成後退出多選模式並清空選取；批次中若部分訂單已是目標狀態則視為無變更略過。

## Non-Goals (optional)

- 不在此變更引入「每個商品 (`LedgerOrderItem`) 各自的狀態」——資料模型中狀態僅存在於訂單層級，per-item 狀態屬 schema 形狀變更，不在本範圍。
- 不批次更改狀態以外的欄位 (如收款狀態、類別、開團)；本變更僅限 `OrderStatus`。
- 不提供跨狀態的「批次合併」或「批次刪除」；合併仍走既有 `order-merge` 流程。
- 不放寬 `merged` 的寫入限制。

## Capabilities

### New Capabilities

- `order-batch-status-update`: 在訂單列表多選多筆訂單後，一次將它們的訂單狀態批次更新為同一個目標狀態，涵蓋三平台 (Apple 本機落盤) 與 Web/Backend (HTTP 批次端點 + Firestore remirror) 的行為契約。

### Modified Capabilities

(none)

## Impact

- Affected specs:
  - New: `order-batch-status-update`
- Affected code:
  - New:
    - `openspec/specs/order-batch-status-update/spec.md`
  - Modified:
    - Apple：`apps/apple/BuyLedger/Features/Orders/OrdersFeature.swift`、`apps/apple/BuyLedger/Features/Orders/OrdersView.swift`、`apps/apple/BuyLedger/Features/Orders/OrdersCompactView.swift`、`apps/apple/BuyLedger/Features/Orders/OrdersMacView.swift`、`apps/apple/BuyLedger/Features/Orders/Components/OrderRowView.swift`、`apps/apple/BuyLedger/Core/Dependencies/OrderRepository.swift`、`apps/apple/BuyLedger/Core/Persistence/OrderPersistence.swift`
    - Web：`apps/web/src/app/orders/page.tsx`、`apps/web/src/components/OrderRow.tsx`、`apps/web/src/lib/api.ts`、`apps/web/src/lib/queries.ts`
    - Backend：`apps/backend/src/orders/orders.controller.ts`、`apps/backend/src/orders/orders.service.ts`、`apps/backend/src/orders/orders.types.ts`
- Affected systems：本機 SwiftData 持久化 (Apple)、PostgreSQL via Prisma 與 Firestore 鏡像 (Backend)、TanStack Query 快取失效 (Web)。
