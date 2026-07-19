## Context

「對帳狀態」的 UI 英文用詞已標準化為 Reconciliation，對應 spec 亦名為 order-reconciliation-status；但實作層仍以 verification 命名，涵蓋跨平台 schema 欄位、SwiftData stored property 與 @Model 型別、repository、feature／view 與測試共約 35 個檔案。其中兩處屬持久層，改名即為 SwiftData schema 變更，必須以 migration 保資料。此 change 只對齊識別字，不改任何使用者可見行為與已儲存的資料值。

## Goals / Non-Goals

Goals：

- 將 verificationStatus／VerificationStatus 全面改名為 reconciliationStatus／ReconciliationStatus，含跨平台 schema、SwiftData、repository、feature／view、測試。
- 以 migration 保住既有訂單的對帳狀態欄位值與對帳狀態主檔清單，升級後不丟資料。
- 生成檔經 schema 重生成產出，維持與 shared/data-model 同步 (check 綠燈)。

Non-Goals：

- 不改任何 UI 文案或行為 (UI 已顯示 Reconciliation)。
- 不改已儲存的對帳狀態「值」(使用者自建的主檔字串)。
- 不啟用 CloudKit 或改變同步策略。
- 不觸及與對帳無關的識別字。

## Decisions

### Decision 1：改名目標一律為 reconciliation

理由：與 D1 已定的 UI 用詞 (對帳 = Reconciliation) 及 spec 名 order-reconciliation-status 對齊，消除 code 與 UI／spec 的長期不一致。

### Decision 2：OrderRecord 欄位改名走 lightweight + originalName

apps/ios/BuyLedger/Core/Persistence/OrderRecord.swift 的 stored property 由 verificationStatus 改為 reconciliationStatus，標註 @Attribute(originalName: "verificationStatus")，使底層 SQLite 欄位名不變、資料零搬遷，走 lightweight migration。

### Decision 3：VerificationStatusRecord @Model 類別改名需明確遷移對策

對帳狀態主檔以獨立 @Model (VerificationStatusRecord) 儲存名稱清單；SwiftData 以型別名作為 entity 名，直接改類別名等同新 entity、舊資料不會自動帶入。對策二選一，於 apply 時依實測決定並以測試驗證：

- 方案 A (優先)：若該 SwiftData 版本支援 entity 級 originalName／renaming identifier，沿用 lightweight，保住主檔資料。
- 方案 B (備援)：以 custom migration stage 將舊 entity 的名稱清單 dump 後 restore 進新 entity (內容僅為字串清單、搬遷單純)。

務必寫 SchemaMigrationTests 驗證：升級後對帳狀態主檔清單與各訂單的對帳狀態值皆完整保留。

實作前置 (硬性)：本決策的遷移方案不確定性最高，實作前必須先用 Context7 查證目標 SwiftData 版本對 @Model entity 改名／originalName 的實際支援，據以確認方案 A 是否可行，查證通過後才開始實作；且實作後必須先執行 Unit Test (含 SchemaMigrationTests 資料保留案) 與模擬器測試並全數通過，才視為此決策落地。

### Decision 4：新增一個 schema 版本並串接 migration

於 apps/ios/BuyLedger/Core/Persistence/BuyLedgerSchema.swift 依既有版本鏈新增下一版 (floor 到 target 連續)，加入本次改名的 migration stage，並更新 PersistenceContainer 的 target 版本。實作前 invoke /swiftdata-schema-migration 取得逐步指引。

### Decision 5：跨平台 schema 先改再生成

先改 shared/data-model/schema/LedgerOrder.yaml 的欄位名，於 shared/data-model/generator 執行產生器重生成，再 check 守門；apps/ios/BuyLedger/Core/Domain/Generated/LedgerOrder.generated.swift 由重生成產出、不得手改。順序：先改 schema／重生成 (讓 domain 型別的欄位更名)，再改持久層與上層識別字，避免中途編譯錯誤堆積。

### Decision 6：新增 V16 後，順帶把 migration floor 由 V13 收斂到 V15

新增 V16 使版本鏈成為 V13→V14→V15→V16，其中 V13/V14 的凍結影子 (OrderRecord / VerificationStatusRecord / CampaignReminderRecord) 純屬歷史包袱。查證 git 史：V13、V14、V15 皆在同一個 v1.5.0 commit (c1ec0ed) 落地，且該 release 起 target 一律為 V15；因此任何 v1.5.0+ 裝置的 store 只會停在 V15 (啟動時一次遷到 target)，永不「停在」V13/V14，而 1.5.0 之前的 store 早於當時 floor-V13 砍檔清除。據此 floor 可安全升到 V15 (「最高的安全 floor」——不能再高到 V16，因為 V15 store 仍在、需要 V15→V16 路徑)。

實作：移除 BuyLedgerSchemaV13 / V14 兩個 version enum 及其影子，BuyLedgerMigrationPlan 收斂為 schemas=[V15,V16]、stages=[V15→V16 custom]；V15 (新 floor) 保留 OrderRecord + VerificationStatusRecord 影子 (V15 store 內仍是這兩者的舊形狀)。VerificationStatusRecord 影子由 3 份減為 1 份。此收斂為單向操作，遵循 CLAUDE.md「移除舊版本」規則：僅在確定沒有 store 停在被移除版本時才可為之，本案已以 git 史佐證此前提成立。

## Risks / Trade-offs

- 遷移失誤會讓 ModelContainer 建立失敗，觸發 makeForApp() 的 fallback 砍檔邏輯而遺失使用者資料；必須以 SchemaMigrationTests 驗證資料保留，切勿依賴 fallback。
- @Model 類別改名 (Decision 3) 是本 change 最大不確定點；方案 A 不可行時退方案 B，並以測試把關。
- 改名面廣 (~35 檔)；以「先 schema 重生成 → 持久層 → repository → feature／view → 測試」的順序推進，過程中分段編譯，降低一次性大量錯誤。

## Migration

- 版本鏈：於 BuyLedgerSchema.swift 現行 target 之上新增 V16 並加入改名 migration stage，並依 Decision 6 把 floor 收斂到 V15 (移除 V13/V14)，最終為 floor V15 → target V16 單一 custom stage。
- 資料保留：OrderRecord 欄位以 originalName 保欄位；VerificationStatusRecord 主檔依 Decision 3 保表。
- 驗證：SchemaMigrationTests 補一案，模擬升級前含對帳狀態值與主檔清單的 store，升級後逐項比對保留。

## Open Questions

- Decision 3 的方案 A 是否可行，需於 apply 時以目標 SwiftData 版本實測後定案。
