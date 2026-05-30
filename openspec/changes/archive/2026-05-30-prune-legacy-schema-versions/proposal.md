## Why

BuyLedger 的 SwiftData schema 已演進到 V8，但 `BuyLedgerSchema.swift` 仍保留 `BuyLedgerSchemaV1`~`BuyLedgerSchemaV6` 六個 versioned schema、其凍結的 shadow `@Model` 型別，以及 V1→V2 (`.custom`) 至 V6→V7 (`.lightweight`) 的 migration stages。保留這些版本的唯一目的，是讓任何停在舊版的 on-disk store 能逐步遷移到最新版；但本專案目前仍是 pre-release (尚未上架、無簽章／散佈版本、無 git tag)，欄位與行為都還在快速變動，實機與 TestFlight 上不存在任何停在 V1~V6 的已安裝 store。

因此這整段歷史在現階段是純死碼：它對實際使用者沒有作用 (已在 V8 的 store 遷移 delta 為 0，永遠不會執行這些 stage)，卻持續增加 `BuyLedgerSchema.swift` 的閱讀與維護負擔——每次新增 schema 版本都得連帶照顧六個舊版的 attribute 指紋與 shadow 型別。趁 pre-release、收斂成本最低且零使用者風險時清掉。

## What Changes

- 從 `BuyLedgerSchema.swift` 移除 `BuyLedgerSchemaV1`~`BuyLedgerSchemaV6` 六個 versioned schema enum，連同其內嵌的 shadow `@Model` 型別 (`V1CurrencyCode`、各版凍結的 `OrderRecord` 與 `PaymentMethodRecord` shadow)。
- `BuyLedgerMigrationPlan.schemas` 由 `[V1 … V8]` 收斂為 `[V7, V8]`。
- `BuyLedgerMigrationPlan.stages` 由「`.custom` V1→V2 ＋ `.lightweight` V2→V3 … V7→V8」收斂為單一 `.lightweight` V7→V8；一併移除僅服務 V1→V2 dump-and-restore 的 `PendingOrder` 暫存 struct 與 `pendingOrders` 中介 snapshot。
- 保留並維持不變的型別：`BuyLedgerSchemaV7` (其 `OrderRecord` shadow 是收斂後 floor 的 fromVersion，必須原樣保留)、`BuyLedgerSchemaV8` (target，引用 top-level `@Model`)，以及所有 top-level `@Model` 與 `PersistenceContainer`。
- 新增 on-disk migration 回歸測試：以保留版本 V7 的 schema 在實體檔案寫入訂單 → 用收斂後的 plan 開啟同一 store → 斷言既有 row 全數存活且欄位正確；此測試同時作為「V8／V7 指紋未被意外更動」的守門 (現有 persistence 測試全走 in-memory 全新 V8 store，無法涵蓋遷移路徑)。
- **BREAKING (僅影響舊版 store)**：收斂後 migration plan 的 floor 為 V7。任何停在 V6 或更早版本的 on-disk store 將失去遷移路徑，開啟時 `ModelContainer` init 會 throw，進而觸發 `PersistenceContainer.makeForApp()` 的 `resetStoreFiles()` 砍檔 fallback (靜默清空後退回 in-memory)。對「已在 V7／V8 的 store」零影響。pre-release 階段不存在前者，故實務上安全；此性質構成一道單向門 (見 design 的風險與限制)。

## Capabilities

### New Capabilities

- `schema-migration-plan`: 定義 BuyLedger SwiftData schema 版本鏈與 migration 的安全不變量——版本鏈必須從「最舊仍支援的 store 版本」連續延伸到 target、container 對最新 versioned schema 建立、移除舊版的前提條件，以及遷移過程中既有資料必須存活的保證。

### Modified Capabilities

(none)

## Impact

- Affected specs: 新增 `schema-migration-plan`
- Affected code:
  - Modified:
    - BuyLedger/BuyLedger/Core/Persistence/BuyLedgerSchema.swift
    - CLAUDE.md (同步「SwiftData Schema 與 Migration」段，反映 floor 已升至 V7、V1~V6 已移除)
  - New: BuyLedger/BuyLedgerTests/SchemaMigrationTests.swift
  - Removed: (無檔案刪除；移除的是 BuyLedger/BuyLedger/Core/Persistence/BuyLedgerSchema.swift 內的 V1~V6 定義與對應 stages)
- 其他：測試 target 採 file system synchronized groups，新增測試檔會自動被拾取，無需手動編輯 pbxproj。`PersistenceContainer.swift` 不需變更 (持續引用 `BuyLedgerSchemaV8` 與 `BuyLedgerMigrationPlan`)。
