## Context

訂單狀態 (`OrderStatus`，10 個值：`quoting`、`confirmed`、`purchased`、`shipping`、`partiallyArrived`、`arrived`、`delivered`、`pickedUp`、`cancelled`、`merged`) 是掛在整筆訂單 (`LedgerOrder`) 上的欄位；商品項目 (`LedgerOrderItem`) 沒有自己的狀態。三平台目前都只能逐筆更新訂單狀態：

- **Apple** (`OrdersFeature`)：詳情頁「更新狀態」Menu → `statusChanged(id, status)` action → reducer 以 memberwise init 重建該筆 `LedgerOrder` → `OrderRepository.saveOrder` (單筆) → `OrderPersistence.upsert` (SwiftData `@ModelActor`)。無 HTTP API，純本機持久化。既有的多筆原子寫入範本是 `OrderRepository.mergeOrders` → `OrderPersistence.mergeOrders` (actor 內 fetch→改多筆→單次 `save()`)。
- **Web/Backend**：詳情頁「更新狀態」→ `api.orders.setStatus(id, status)` → `POST /orders/:id/status` → `OrdersService.setStatus` (驗狀態合法、`ensureExists(uid,id)` 圈 owner、`prisma.order.update`、`mirror.mirrorOrder` 同步 Firestore)。前端用 TanStack Query，mutation 成功後 invalidate `['orders']` 與 `['campaigns']`。後端**沒有**批次端點。

三平台訂單列表都沒有任何多選 / 批次機制。`merged` 狀態僅能由合併流程寫入，既有狀態選單一律以 `OrderStatus.allCases.filter { $0 != .merged || order.status == .merged }` 排除手動指定。

## Goals / Non-Goals

**Goals:**

- 三平台訂單列表都能進入多選模式、勾選多筆訂單、一次把它們批次更新為同一個目標 `OrderStatus`。
- Apple 端以單次原子落盤完成批次寫入 (不逐筆 save)。
- Backend 提供批次端點，依 `ownerUid` 圈訂單、`updateMany` 後 remirror 受影響訂單至 Firestore；Web 串接並沿用 `orders` + `campaigns` 失效。
- 批次目標狀態清單一律排除 `merged`；已是目標狀態的訂單視為無變更略過。

**Non-Goals:**

- 不引入 per-item (`LedgerOrderItem`) 狀態 (屬 schema 形狀變更)。
- 不批次更改狀態以外的欄位；不提供批次刪除／批次合併。
- 不放寬 `merged` 寫入限制；不改變單筆更新既有流程。

## Decisions

### 多選狀態模型與進出多選模式

- **Apple**：`OrdersFeature.State` 新增 `isSelecting: Bool`（多選模式旗標）與 `selectedOrderIDs: Set<LedgerOrder.ID>`（已選集合）。新增 actions：`selectionModeToggled`（進出多選模式，退出時清空 `selectedOrderIDs`、關閉批次 sheet）、`orderSelectionToggled(LedgerOrder.ID)`（單列勾選切換）、`selectAllTapped` / `clearSelectionTapped`（全選目前篩選後清單／清除）。
- **Web**：訂單列表頁以 component local state (`useState`) 持有 `selecting: boolean` 與 `selectedIds: Set<string>`，不引入全域 store。進入多選時列點擊改為切換勾選而非導航。
- 理由：選取狀態是 UI 暫態，Apple 既以 TCA 管理列表狀態故收進 `OrdersFeature.State`；Web 既無對應全域 store，用 local state 最輕量。replace 為全域狀態會增加不必要的耦合。

### Apple 批次原子落盤 (循 mergeOrders 模式)

- `OrderRepository` 新增 `saveOrders(_ orders: [LedgerOrder])`，`OrderPersistence` 新增對應的批次 upsert：在 `@ModelActor` 內逐筆 upsert 後**單次** `modelContext.save()`，達成原子落盤。
- `OrdersFeature` 新增 `batchStatusChangeRequested`（開批次狀態選單）與 `batchStatusChanged(OrderStatus)`：reducer 對 `selectedOrderIDs` 中每筆，若狀態已等於目標則略過，否則以既有 `LedgerOrder.withStatus(_:)` 重建；收集所有實際變更的訂單，更新 in-memory `state.orders`，以單一 effect 呼叫 `orderRepository.saveOrders(changed)`；完成後退出多選模式並清空選取。
- 理由：逐筆 `saveOrder` 會觸發多次落盤且非原子；`mergeOrders` 已證實可在 actor 內一次 save 多筆，沿用同模式一致且安全。

### Backend 批次端點形狀

- 新增 `POST /orders/status/batch`，body `BatchStatusChangeInput { ids: string[]; status: OrderStatus }`。
- `OrdersService.batchSetStatus(uid, input)`：驗證 `status` 合法且非 `merged`；以 `prisma.order.updateMany({ where: { id: { in: ids }, ownerUid: uid }, data: { status } })` 一次更新（`ownerUid` 圈確保不跨使用者）；查回受影響訂單並逐筆 `mirror.mirrorOrder` remirror（沿用既有 cascade／remirror 模式）；回傳更新後的 `OrderDTO[]` 或受影響筆數。
- DTO 用 TS interface 規避全域 `ValidationPipe whitelist` 對陣列／大 body 的剝除，於 service 內手動正規化。
- 理由：單一 `updateMany` 比迴圈 `update` 高效且天然原子；remirror 必須逐筆以維持「後端為唯一 Firestore 寫入方」。`merged` 在端點層拒絕，與用戶端排除一致，雙重防線。

### Web 批次 mutation 與失效

- `api.orders` 新增 `batchSetStatus(ids, status)` 呼叫新端點；`useOrderMutations` 新增 `batchSetStatus` mutation，成功後沿用既有 `invalidate(['orders'])` + `invalidate(['campaigns'])`。
- 列表頁多選工具列：顯示已選筆數、批次「更改狀態」按鈕（開既有 `OptionPicker` 選目標狀態，options 排除 `merged`）、清除／全選與退出多選。
- 理由：開團統計衍生自訂單，狀態異動必須同時失效 campaigns（既有鐵則）；重用 `OptionPicker` 避免新增選單元件。

### 目標狀態清單排除 merged

- 三平台批次目標狀態一律 `OrderStatus.allCases.filter { $0 != .merged }`（Web 對應排除）。批次不需要「保留當前 merged」的特例（那只對單筆停在 merged 的訂單有意義），故比單筆規則更單純。

## Implementation Contract

**行為 (Behavior)：** 使用者在訂單列表點「選取」進入多選模式 → 勾選多筆訂單（可全選／清除）→ 點「更改狀態」選一個目標狀態 → 所有已選訂單的 status 變為該狀態，列表狀態膠囊即時反映，並退出多選模式。已是目標狀態者不變。`merged` 不出現在可選目標中。

**介面 / 資料形狀：**

- Apple：
  - `OrderRepository.saveOrders(_ orders: [LedgerOrder])`（新，type-based 注入既有）。
  - `OrderPersistence` 對應批次 upsert，單次 `save()` 落盤。
  - `OrdersFeature.State`：`isSelecting: Bool`、`selectedOrderIDs: Set<LedgerOrder.ID>`。
  - `OrdersFeature.Action`：`selectionModeToggled`、`orderSelectionToggled(LedgerOrder.ID)`、`selectAllTapped`、`clearSelectionTapped`、`batchStatusChangeRequested`、`batchStatusChanged(OrderStatus)`。
- Backend：`POST /orders/status/batch`，request `{ ids: string[]; status: OrderStatus }`，response 更新後 `OrderDTO[]`（或 `{ updated: number }`）。非法／`merged` status 回 400；ids 中不屬該 uid 的訂單一律不受影響（不報錯，僅更新交集）。
- Web：`api.orders.batchSetStatus(ids: string[], status: OrderStatus): Promise<OrderDTO[]>`；`useOrderMutations().batchSetStatus`。

**失效模式 (Failure modes)：**

- Apple：批次中若全部已是目標狀態 → 無變更、無落盤、仍退出多選模式。落盤失敗沿用既有 `try?` 容錯（不中斷 UI）。
- Backend：`status` 非法或為 `merged` → 400；空 `ids` → 回 0 筆更新（不報錯）；`updateMany` 只作用於 `ownerUid` 交集，杜絕跨使用者寫入。
- Web：mutation 失敗顯示錯誤、不清空選取（讓使用者可重試）；成功才退出多選並 invalidate。

**驗收標準 (Acceptance criteria)：**

- Apple：`OrdersFeature` 以 TestStore 驗證 `batchStatusChanged` 只重建有變更的訂單、更新 state、呼叫 `saveOrders`、退出多選；build-and-run 到實體 iPhone 實測多選→批次改狀態→膠囊更新。
- Backend：批次端點以 `ownerUid` 圈、`updateMany` + remirror；可由 e2e／service 測試或手動驗證跨使用者不受影響、Firestore 鏡像更新。
- Web：以 chrome-devtools 實測進入多選→勾選多筆→改狀態→列表更新且 campaigns 連動失效。

**範圍邊界 (Scope boundaries)：**

- In scope：訂單層級 `OrderStatus` 的多選批次更新（三平台 + 後端端點 + Firestore remirror + 查詢失效）。
- Out of scope：per-item 狀態、批次改其他欄位、批次刪除／合併、放寬 `merged` 限制、既有單筆流程改動。

## Risks / Trade-offs

- [選取集合與篩選／重載不同步：批次當下某些已選 id 可能已不在清單或已變狀態] → reducer/service 端對「目標狀態已相同」與「id 不存在」皆採略過語意，不報錯；Apple 在 `state.orders` 找不到的 id 直接忽略。
- [Backend remirror 逐筆，批次大時鏡像耗時] → 接受；`updateMany` 已使 Postgres 寫入原子，鏡像為事後同步，可日後再批次化。
- [Web 列點擊在多選模式改變語意（勾選 vs 導航）可能誤觸] → 以明顯的多選工具列與勾選框視覺區隔，退出多選即回復導航。
- [merged 訂單若被選取並套用非 merged 狀態會破壞合併語意] → 產品上罕見；本期目標清單排除 merged 已避免「改成 merged」；是否禁止選取 merged 來源列為 Open Question，預設不特別禁止以與單筆行為一致。

## Migration Plan

- 無資料 schema 變更（`OrderStatus`／`LedgerOrder` 形狀不動，免動 `shared/data-model/schema`）。
- Backend 端點為新增，向後相容；部署後 Web 才會呼叫。
- Rollback：移除新端點與三平台多選 UI 即可，無持久化結構需回滾。

## Open Questions

- 是否禁止「已 merged 的訂單」被選入批次？預設不禁止（與單筆一致），如需禁止再於 reducer/service 加排除。
- Backend 批次回傳採完整 `OrderDTO[]` 或精簡 `{ updated: number }`？預設回 `OrderDTO[]` 以利前端就地更新，若 payload 過大再改精簡。
