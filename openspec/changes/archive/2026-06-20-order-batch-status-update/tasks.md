## 1. Backend 批次更改狀態端點

- [x] 1.1 依「Backend 批次端點形狀」新增 `POST /orders/status/batch` 與 `BatchStatusChangeInput { ids: string[]; status }`，行為：以 `prisma.order.updateMany` 依 `ownerUid` 圈一次更新已選訂單的 status、拒絕缺漏／非法／`merged` 的 status (回 400)、回傳受影響 `OrderDTO[]`；完成 spec「Backend batch status endpoint is owner-scoped and re-mirrors Firestore」中 owner 圈與拒絕 `merged` 兩個 scenario。驗證：對 `apps/backend` 寫 service/e2e 測試或手動 curl 確認跨使用者 id 不受影響且 `merged` 目標回 400 (locator: `apps/backend/src/orders/orders.controller.ts`、`orders.service.ts`、`orders.types.ts`)。
- [x] 1.2 在 `OrdersService.batchSetStatus` 內，Postgres `updateMany` 成功後逐筆 `mirror.mirrorOrder` remirror 受影響訂單，維持「後端為唯一 Firestore 寫入方」並完成 spec 同需求的 re-mirror scenario。驗證：手動於 Firestore 觀察受影響文件 status 更新，或沿用既有 mirror 測試樣式斷言 remirror 被呼叫。

## 2. Web 訂單列表多選與批次

- [x] 2.1 依「多選狀態模型與進出多選模式」在訂單列表頁加入多選模式 (`selecting`/`selectedIds` local state) 與多選工具列 (進出多選、全選/清除、已選筆數)，且多選時列點擊改為切換勾選而非導航，完成 spec「Orders list provides a multi-select mode」三個 scenario。驗證：chrome-devtools 操作確認勾選計數、全選/清除、退出後回復導航 (locator: `apps/web/src/app/orders/page.tsx`、`apps/web/src/components/OrderRow.tsx`)。
- [x] 2.2 [P] 依「Web 批次 mutation 與失效」新增 `api.orders.batchSetStatus(ids, status)` 與 `useOrderMutations().batchSetStatus`，成功後同時 invalidate `['orders']` 與 `['campaigns']`，完成 spec「Web batch status update invalidates orders and campaigns」。驗證：chrome-devtools network 面板確認呼叫批次端點、列表與開團衍生視圖刷新 (locator: `apps/web/src/lib/api.ts`、`apps/web/src/lib/queries.ts`)。
- [x] 2.3 依「目標狀態清單排除 merged」以既有 `OptionPicker` 提供批次目標狀態 (options 排除 `merged`)，套用到已選訂單、成功後退出多選並清空選取，完成 spec「Batch apply a single target status to selected orders」與「Batch target status list excludes merged」。驗證：chrome-devtools 確認 picker 不含 `merged`、選多筆套用後狀態膠囊更新且退出多選。

## 3. Apple 訂單列表多選與批次

- [x] 3.1 依「多選狀態模型與進出多選模式」在 `OrdersFeature.State` 加 `isSelecting`/`selectedOrderIDs` 與 `selectionModeToggled`/`orderSelectionToggled`/`selectAllTapped`/`clearSelectionTapped` actions，並在 `OrdersView`/`OrdersCompactView`/`OrdersMacView` 加多選 UI (勾選態、工具列、已選筆數)，完成 spec「Orders list provides a multi-select mode」。驗證：TestStore 斷言 selection actions 的 state 變化 + build-and-run 實機操作。
- [x] 3.2 [P] 依「Apple 批次原子落盤 (循 mergeOrders 模式)」在 `OrderRepository` 加 `saveOrders(_:)`、`OrderPersistence` 加對應批次 upsert，於 `@ModelActor` 內逐筆 upsert 後單次 `save()`，完成 spec「Batch status persistence is atomic on Apple」。驗證：TestStore 以 mock repository 斷言一次 `saveOrders` 帶入所有變更訂單 (而非多次 `saveOrder`)。
- [x] 3.3 實作 `batchStatusChangeRequested`/`batchStatusChanged(OrderStatus)`：對 `selectedOrderIDs` 套用目標狀態、以 `withStatus` 重建、略過已是目標狀態者、單次 `saveOrders` 落盤後退出多選，批次目標清單套用「目標狀態清單排除 merged」，完成 spec「Batch apply a single target status to selected orders」與「Batch target status list excludes merged」。驗證：TestStore 驗證只重建有變更的訂單、呼叫 `saveOrders`、退出多選 + 實機操作。

## 4. 雙平台驗收

- [x] 4.1 Apple：先 `cd apps/apple && agvtool next-version -all`，再 build-and-run 到實體 iPhone，實測進入多選→勾選多筆→批次改狀態→列表狀態膠囊即時更新且退出多選，截圖佐證。
- [x] 4.2 Web：用 chrome-devtools 開訂單頁，實測進入多選→勾選多筆→更改狀態 (確認無 `merged` 選項)→列表更新並觀察 orders/campaigns 連動失效，截圖佐證。
