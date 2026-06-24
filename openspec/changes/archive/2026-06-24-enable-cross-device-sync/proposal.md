## Why

`firebase-auth-multiuser-sync` 已鋪好基礎：後端為唯一寫入方、Postgres 為 source of truth、寫入後鏡像到 per-user Firestore 投影；但該 change 刻意把「跨裝置同步實際啟用」「衝突解決」「同步失敗補償」三件事延後。實測現況：web 完全沒 import `firebase/firestore`、零 `onSnapshot` (純 REST + 30 秒 cache)；iOS sync flag 預設關閉、零 listener、零後端 API client (訂單只進本機 SwiftData)；後端鏡像失敗只 log、全鏈路無時鐘無法偵測或合併並行修改。本 change 把同步通道真正接通，並依使用者定奪的三項策略——iOS 離線優先、欄位級合併、retry 後顯示待同步狀態——讓同一帳號的任意兩台裝置 (iOS↔web、iOS↔Android、Android↔web) 收斂到同一份資料。

## What Changes

- **跨裝置即時同步 (A↔B)**：web 新增 `firebase/firestore` 即時 `onSnapshot` listener，把 `users/{uid}/<collection>` 投影餵進既有 TanStack Query cache；iOS 把 sync 由「已串接但關閉」真正啟用為 opt-in。任一裝置的變更經後端合併、鏡像後，另一裝置即時看到。
- **iOS 離線優先 (local-first)**：SwiftData 維持本機 source of truth、離線可完整新增/編輯/刪除；sync 開啟時由 `CloudSyncEngine` 把本機變更推送後端、把投影拉回合併進 SwiftData。sync 關閉時行為與現況完全一致 (純本機、零網路、零 schema migration)。
- **欄位級合併 (field-level merge)**：以每欄位 Hybrid Logical Clock (HLC) 為準，集中在後端合併——不同欄位的並行修改全部保留、同欄位以 HLC (p→c→writerId) 決勝；client 送 partial patch (僅變更欄位 + 其 clock)，後端為線性化點並 clamp 時鐘偏移。刪除採帶時鐘的 tombstone，較晚修改可非破壞性復活 (保留未觸及欄位)。**取代**先前草擬的樂觀並行 409 模型。
- **同步失敗處理**：client 寫入失敗 retry 3 次 (backoff)，仍失敗則該筆顯示可觀察的「待同步/失敗」狀態、留在持久化本機佇列、連線恢復或下次啟動自動重送；重送以 client UUID upsert + 確定性伺服器時鐘保證冪等 (不重複、不回退並行較晚的修改)。**不採用**持久化 payload outbox；後端鏡像失敗採有限次內聯重試後標記 `mirrorDirty`，由輕量 dirty-key 掃描從 Postgres 重新鏡像自我修復投影。
- **版本提升**：iOS 1.4.0 / Web 1.3.0 / Backend 1.2.0。
- **BREAKING (僅後端持久化層)**：Order/Campaign 新增 `fieldClocks`(JSON)、`deletedAt`、`deleteClock`、`mirrorDirty`、`mirrorPendingSinceClock`，lookups 新增 `recordClock`；沿用前一 change 的 dev 策略 (尚未上線)，以 schema push 重建、不寫資料 migration。所有同步信封 metadata (writerId、fieldClocks、tombstone、syncStatus) 屬傳輸/持久化層，**不進 shared/data-model 領域 schema** (延續 `ownerUid` 先例)；iOS 同步 metadata 放本機專屬 SwiftData sidecar (`SyncMeta`/`SyncQueueItem`)、不污染生成型別。

## Non-Goals

(設計取捨與否決方案記於 design.md 的 Goals／Non-Goals 與 Decisions。)

## Capabilities

### New Capabilities

- `cross-device-sync`: 同一帳號任意兩平台 (iOS、web、Android) 經 Postgres 為伺服器 SoT、per-user Firestore 投影為即時讀取路徑傳播 Order/Campaign 變更；iOS 為 opt-in 預設關閉且關閉時維持完全離線可用。
- `sync-conflict-resolution`: 以每欄位 HLC 做欄位級合併——不同欄位並行修改皆保留、同欄位以 HLC 決勝、後端為線性化點並 clamp 時鐘偏移；刪除為帶時鐘 tombstone、較晚修改非破壞性復活。
- `sync-failure-recovery`: client 寫入 retry 3 次後顯示待同步/失敗狀態、持久化本機佇列、恢復自動重送；重送以 UUID upsert + 確定性伺服器時鐘冪等；無持久化 payload outbox。

### Modified Capabilities

- `firestore-realtime-projection`: 投影文件新增每欄位 HLC、顯式 `_deleted`+`_deleteClock`、照片參照 (非 base64)；client 以 `onSnapshot` 即時消費並於每次 (重新) 訂閱做全量重讀對齊；後端維持 Firestore/Storage 唯一寫入方、Postgres 維持 SoT；鏡像失敗採有限次內聯重試後標記 `mirrorDirty`、由背景/惰性掃描自 Postgres 重新鏡像自我修復 (非 payload outbox)。

## Impact

- Affected specs：新增 `cross-device-sync`、`sync-conflict-resolution`、`sync-failure-recovery`；修改 `firestore-realtime-projection`。`firebase-authentication`、`multi-user-data-ownership` 不變。同步 metadata 不進 shared/data-model schema，data-model-codegen 不受影響。
- Affected code:
  - New:
    - apps/backend/src/sync/hlc.ts
    - apps/backend/src/sync/hlc.service.ts
    - apps/backend/src/sync/apply-field-writes.ts
    - apps/backend/src/sync/mirror-sweep.service.ts
    - apps/backend/src/sync/sync.module.ts
    - apps/web/src/lib/sync/hlc.ts
    - apps/web/src/lib/sync/useFirestoreSync.tsx
    - apps/web/src/lib/sync/orderPatch.ts
    - apps/web/src/lib/sync/writeQueue.ts
    - apps/web/src/lib/sync/SyncStatusBadge.tsx
    - apps/apple/BuyLedger/Core/Sync/BackendAPIClient.swift
    - apps/apple/BuyLedger/Core/Sync/Hlc.swift
    - apps/apple/BuyLedger/Core/Sync/HlcClient.swift
    - apps/apple/BuyLedger/Core/Sync/JSONValue.swift
    - apps/apple/BuyLedger/Core/Sync/SyncMeta.swift
    - apps/apple/BuyLedger/Core/Sync/SyncMetaPersistence.swift
    - apps/apple/BuyLedger/Core/Sync/SyncQueueItem.swift
    - apps/apple/BuyLedger/Core/Sync/SyncQueuePersistence.swift
    - apps/apple/BuyLedger/Core/Sync/CloudSyncFieldMerge.swift
    - apps/apple/BuyLedger/Core/Sync/NetworkPathMonitor.swift
    - apps/apple/BuyLedger/Core/Sync/PhotoRefResolver.swift
    - apps/apple/BuyLedger/Features/App/CloudSyncEngine.swift
    - apps/apple/BuyLedger/Core/Networking/AppConfiguration.swift (apply：取代 APIKeyProvider，收斂 API key + 後端 base URL)
    - apps/apple/BuyLedger/Core/Networking/HTTPMethod.swift (apply)
    - apps/apple/BuyLedger/Core/Networking/URLRequestBuilder.swift (apply)
    - apps/apple/BuyLedger/Shared/Extensions/NotificationName+Extensions.swift (apply：同步觸發通知名)
    - shared/sync-conformance/hlc-vectors.json
    - shared/sync-conformance/field-merge-vectors.json
    - shared/sync-conformance/field-categories.json
  - Modified:
    - apps/backend/prisma/schema.prisma
    - apps/backend/prisma/seed.ts
    - apps/backend/src/firebase/firestore-mirror.service.ts
    - apps/backend/src/orders/orders.service.ts
    - apps/backend/src/orders/orders.controller.ts
    - apps/backend/src/orders/order.mapper.ts
    - apps/backend/src/orders/orders.types.ts
    - apps/backend/src/orders/orders.module.ts (apply：註冊 MirrorSweepService 以注入 OrdersService)
    - apps/backend/src/campaigns/campaigns.service.ts
    - apps/backend/src/lookups/lookups.service.ts
    - apps/backend/src/settings/settings.service.ts
    - apps/backend/src/app.module.ts
    - apps/web/src/lib/firebase.ts
    - apps/web/src/lib/queries.ts
    - apps/web/src/lib/api.ts
    - apps/web/src/lib/providers.tsx
    - apps/apple/BuyLedger/Features/App/CloudSync.swift
    - apps/apple/BuyLedger/App/CloudSyncFeatureFlag.swift
    - apps/apple/BuyLedger/Features/App/AppRootView.swift
    - apps/apple/BuyLedger/Features/Orders/OrdersFeature.swift
    - apps/apple/BuyLedger/Features/App/RootFeature.swift
    - apps/apple/BuyLedger/Core/Persistence/BuyLedgerSchema.swift
    - apps/apple/BuyLedger/Core/Networking/HTTPClient.swift (apply：新增 send/stream，改用 URLSession(configuration:.default))
    - apps/apple/BuyLedger/Features/AISummary/OllamaClient.swift (apply：改走 HTTPClient.stream；自 Core/Networking 移入)
    - apps/apple/BuyLedger/Core/Dependencies/OrderRepository.swift (apply：所有訂單異動統一發同步通知 + 刪除觸發)
    - apps/apple/BuyLedger/Resources/Info.plist (apply：BACKEND_API_BASE_URL + Google REVERSED_CLIENT_ID URL scheme)
    - apps/apple/BuyLedger/Resources/Config.example.xcconfig
    - apps/backend/README.md
    - apps/backend/CLAUDE.md
    - apps/web/README.md
    - apps/web/CLAUDE.md
    - apps/apple/CLAUDE.md
    - apps/apple/README.md
    - README.md
  - Removed:
    - apps/apple/BuyLedger/Core/Networking/APIKeyProvider.swift (apply：由 AppConfiguration 取代)
  - 測試：對應的 `*.spec.ts` / `*Tests.swift` 隨上述產品碼一併新增或修改 (TDD)，不逐一列舉。
