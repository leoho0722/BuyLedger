## Context

`BuyLedgerSchema.swift` 目前定義 `BuyLedgerSchemaV1`~`BuyLedgerSchemaV8` 八個 versioned schema。`BuyLedgerMigrationPlan.schemas` 列出 V1…V8，`stages` 為「`.custom` V1→V2 ＋ `.lightweight` V2→V3 … V7→V8」。`PersistenceContainer.make` 以 `Schema(versionedSchema: BuyLedgerSchemaV8.self)` 搭配 `migrationPlan: BuyLedgerMigrationPlan.self` 建立 container；當 init 失敗時 `makeForApp()` 會呼叫 `resetStoreFiles()` 整批刪除 store 檔後退回 in-memory。

已驗證的 SwiftData 遷移語意 (WWDC23 session 10195 ＋ Apple SwiftData 官方文件)：遷移是 forward-only，stage 只在 on-disk store 的 fingerprint 與 target 有 delta 時、沿「store 當前版本 → target」的連續路徑執行；已在 V8 的 store delta 為 0，不會觸發任何 stage。若 store 停在低於 plan 最舊版本 (floor) 的版本，找不到遷移路徑，`ModelContainer` init 會 throw。

專案約束：Swift 6 strict concurrency 預設 `nonisolated`；目前 pre-release (尚未上架、無簽章／散佈版本、無 git tag)；CloudKit 於 code (`make(cloudKit: .disabled)`) 與 entitlements 皆為關閉。

## Goals / Non-Goals

**Goals:**

- 移除 V1~V6 versioned schema 與其 shadow 型別，將 `BuyLedgerMigrationPlan` 收斂為 `schemas = [V7, V8]`、`stages = [.lightweight V7→V8]`。
- 對「已在 V7／V8 的 store」維持零行為改變 (不觸發任何遷移、fingerprint 不變)。
- 新增 on-disk migration 回歸測試，鎖定「V7 store 遷到 V8 後資料全數存活」並守門 V8／V7 fingerprint 穩定。
- 同步更新 CLAUDE.md 的「SwiftData Schema 與 Migration」段，使規則與實際 floor (V7) 一致。

**Non-Goals:**

- 不更動任何 top-level `@Model` 欄位，也不更動 `BuyLedgerSchemaV7` 的 `OrderRecord` shadow 與 `BuyLedgerSchemaV8.models` 接線 (fingerprint 必須保持 byte-identical)。
- 不更動 `PersistenceContainer` 的邏輯，特別是不調整 `resetStoreFiles()` 砍檔 fallback 的行為。
- 不啟用 CloudKit，也不處理多裝置 sync 情境下的遷移與砍檔傳播。
- 不保留對 V1~V6 store 的遷移能力 (明確放棄；pre-release 前提)。
- 不將 V7／V8 重新編號為 V1／V2。

## Decisions

### 將 migration plan 的 floor 收斂為 V7 並移除 V1~V6

SwiftData 遷移只需要「最舊仍存在的 store 版本 → target」之間連續的 stage 鏈。pre-release 不存在低於 V8 的 field store，唯一可能停在舊版的是開發機／模擬器的本機 store (專案已視為可丟棄)。保留 V7 作為 floor，讓 `.lightweight` V7→V8 stage 的 `fromVersion` 仍有對應 schema，且維持一條真實、可被測試覆蓋的遷移路徑。

替代方案：(1) 全部保留 V1~V8——否決，純維護負擔的死碼，正是本 change 要解決的問題。(2) 收斂成單一 `[V8]`、無 stage——否決，雖然對全新安裝可行，但會連 V7 dev store 的遷移路徑也一併丟掉，且失去一條可驗證的 lightweight 遷移；保留 V7 是「能展示遷移」的最小連續尾巴，成本極低。

### 移除 .custom V1→V2 dump-and-restore 與其暫存型別

`.custom` V1→V2 stage、`PendingOrder` struct 與 `pendingOrders` 中介 snapshot 的存在，唯一目的是把 V1 的 enum currency 轉成 String。移除 V1 後三者皆成死碼，一併刪除。需明確記錄的代價：這是唯一能讀懂「舊 enum 編碼的 currency 欄位」的路徑，移除後任何 V1 store 將永久不可復原 (不是 throw，而是再也沒有 reader)；pre-release 無此類 store，可接受。

替代方案：保留 `.custom` 但只刪 V2~V6——否決，與「收斂 floor」目標矛盾且自相不一致。

### 以外科手術式移除維持 V8／V7 fingerprint 不變

「已在 V8 的 store 不受影響」的前提，是 V8 的 fingerprint 保持 byte-identical。`BuyLedgerSchemaV8.models` 指向 top-level `@Model`；`BuyLedgerSchemaV7` 凍結自己的 `OrderRecord` shadow，但 `PaymentMethodRecord` / `CategoryRecord` / `CurrencyMetadataRecord` / `OrderSourceRecord` / `VerificationStatusRecord` 仍引用 top-level。因此編輯必須只刪除 V1~V6 enum 與引用它們的 stage，絕不順手「清理」任何 top-level `@Model` 欄位或 V7 shadow——一旦 fingerprint 改變，連 V8 store 都會 mismatch，觸發遷移／throw，落入 `resetStoreFiles()` 砍檔。

替代方案：趁機清理看似未使用的 top-level 欄位——否決，這正是會把「已在 V8 的用戶」推下砍檔懸崖的編輯，必須隔離成獨立 change。

### 新增 on-disk migration 回歸測試作為砍檔守門

現有 persistence 測試全走 `make(inMemoryOnly: true)` 的全新 V8 store，永遠不會行經遷移路徑，因此目前沒有任何自動化守住 `makeForApp()` 砍檔 fallback。新增測試：在實體檔案以 V7 schema 寫入訂單與主檔 → 用收斂後的 plan 開啟同一 store → 斷言 row 全數存活、欄位正確。此測試同時守門 fingerprint：若 V8／V7 指紋被意外更動，開啟時會嘗試遷移或 throw，測試即失敗。

替代方案：僅以手動驗證——否決，無持久守門，回歸只會以「靜默清空使用者資料」的形式在 runtime 浮現。

### 同步更新 CLAUDE.md 的 Schema 與 Migration 規則段

移除後，CLAUDE.md「SwiftData Schema 與 Migration」段內以 V1~V5 為例的描述 (例如「所有舊版本 (V1–V4) 必須把當時的 @Model 凍結成 shadow」) 會與實際不符。更新該段：保留「新增版本時需凍結上一版 shadow」的通則，但把版本範圍與範例對齊到新的 floor (V7) 與 target (V8)，並補一句註明 V1~V6 已於 pre-release 階段移除、floor 升至 V7。

## Implementation Contract

**Behavior (可觀察行為)：**

- 已在 V8 的 on-disk store：開啟後不觸發任何遷移，行為與現況完全一致。
- 停在 V7 的 on-disk store：開啟時以 `.lightweight` 遷到 V8，既有 row 全數保留。
- 停在 ≤V6 的 on-disk store：無遷移路徑，`ModelContainer` init throw → `makeForApp()` 砍檔後退回 in-memory (沿用既有 fallback，行為不變，pre-release 不存在此類 store)。

**Interface / data shape：**

- `BuyLedgerMigrationPlan.schemas` 等於 `[BuyLedgerSchemaV7.self, BuyLedgerSchemaV8.self]`。
- `BuyLedgerMigrationPlan.stages` 等於 `[.lightweight(fromVersion: BuyLedgerSchemaV7.self, toVersion: BuyLedgerSchemaV8.self)]`。
- `BuyLedgerSchemaV1`~`BuyLedgerSchemaV6`、`PendingOrder`、`pendingOrders` 在模組內不再存在。
- `BuyLedgerSchemaV7`、`BuyLedgerSchemaV8` 定義與所有 top-level `@Model` 維持不變。

**Failure modes：**

- ≤V6 store → init throw → `resetStoreFiles()` 整批刪除 `BuyLedger.store` / `-wal` / `-shm` → in-memory。此為既有、刻意對開發期靜默的行為，本 change 不更動。

**Acceptance criteria：**

- 新測試 `SchemaMigrationTests`：以 V7 schema 在實體 store 寫入 N 筆訂單與相關主檔 → 用 `PersistenceContainer.make()` (on-disk、收斂後 plan) 重新開啟 → 斷言 N 筆訂單與其欄位 (含 currency、orderSource、notes、verificationStatus 等) 全數存活。
- 既有測試全數通過，特別是 `OrderPersistenceTests` 與 `CampaignPersistenceTests`。
- macOS 與 iOS Simulator build 皆成功 (file system synchronized group 拾取新測試檔)。
- 全 repo grep `BuyLedgerSchemaV[1-6]` 僅剩已歸檔 spec 文件中的歷史引用，原始碼與測試中無殘留。

**Scope boundaries：**

- In scope：`BuyLedgerSchema.swift` 移除 V1~V6 與 stage 收斂；新增 `SchemaMigrationTests.swift`；CLAUDE.md Schema 段同步。
- Out of scope：`PersistenceContainer` 邏輯與 fallback、top-level `@Model` 欄位調整、CloudKit 啟用與多裝置遷移、V7／V8 重新編號。

## Risks / Trade-offs

- [編輯時誤動 V7／V8 fingerprint → 連已在 V8 的 store 都 mismatch → 觸發砍檔] → 外科手術式編輯，只刪 V1~V6 enum 與其 stage；新增 on-disk migration 測試守門；移除後跑既有 persistence 測試與 macOS／iOS build 確認。
- [≤V6 store 永久不可遷移 (`.custom` V1→V2 是唯一 enum currency reader)] → pre-release 不存在此類 store；以 `makeForApp()` fallback 兜底；此性質構成單向門，於 spec 與 CLAUDE.md 記為「上架後不可再回頭移除版本」的前提。
- [CloudKit 啟用後「per-device 已在 V8 就安全」結論失效，砍檔可能透過 sync 傳播] → 目前 `.disabled` (code ＋ entitlements)；於 spec 記為已知限制；未來啟用 sync 前必須重新評估遷移策略與 fallback。
- [收斂後 CLAUDE.md 的舊版範例失準，誤導未來 schema 變更] → 納入本 change 的 doc 同步 task。

## Open Questions

- 是否要為「最低支援 store 版本」訂一個明文政策 (例如上架後每個 App Store 版本只可在確認所有 field store 已過某版後才移除該版)？本 change 先以 spec 記錄不變量，正式政策可於上架前另開 change 細化。
