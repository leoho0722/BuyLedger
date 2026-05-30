## 1. 以 on-disk 回歸測試鎖定遷移行為 (TDD 先行)

- [x] 1.1 新增 `BuyLedger/BuyLedgerTests/SchemaMigrationTests.swift`：以 floor 版本 `BuyLedgerSchemaV7` 在 temp on-disk store URL (非 in-memory) 寫入多筆訂單與相關主檔並 save，再以收斂後 plan 開啟同一 URL，斷言所有訂單與 currency／orderSource／notes／verificationStatus 全數存活——交付 spec「Data preservation across retained migrations」與「On-disk migration regression coverage」的可執行守門，對應 design「新增 on-disk migration 回歸測試作為砍檔守門」。驗證：在現行完整 plan 下執行此測試即通過 (characterization guard)。
- [x] 1.2 於同檔補測 spec「Contiguous migration chain from floor to target」的兩個 scenario：floor (V7) store 開啟後遷到 V8、已在 target (V8) 的 store 開啟不觸發遷移且資料不變；此案例同時守門 spec「Schema-version removal preserves the target fingerprint」。驗證：測試斷言已在 V8 的 store 開啟前後 row 數與欄位一致。

## 2. 收斂 BuyLedgerMigrationPlan 並移除 V1~V6

- [x] 2.1 將 `BuyLedgerMigrationPlan.schemas` 收斂為 `[BuyLedgerSchemaV7.self, BuyLedgerSchemaV8.self]`、`stages` 收斂為單一 `.lightweight(fromVersion: BuyLedgerSchemaV7.self, toVersion: BuyLedgerSchemaV8.self)`——交付 design「將 migration plan 的 floor 收斂為 V7 並移除 V1~V6」。驗證：第 1 組 on-disk 測試仍綠，且 `schemas`／`stages` 中 `grep BuyLedgerSchemaV[1-6]` 無殘留。
- [x] 2.2 從 `BuyLedgerSchema.swift` 刪除 `BuyLedgerSchemaV1`~`BuyLedgerSchemaV6` enum 與其內嵌 shadow 型別 (`V1CurrencyCode`、各版 `OrderRecord`／`PaymentMethodRecord` shadow)，並移除僅服務 `.custom` V1→V2 的 `PendingOrder` struct 與 `pendingOrders` snapshot——交付 design「移除 .custom V1→V2 dump-and-restore 與其暫存型別」。驗證：模組編譯通過，全 repo `grep BuyLedgerSchemaV[1-6]` 僅剩已歸檔 spec 文件中的歷史引用。
- [x] 2.3 確認本次為外科手術式移除：`BuyLedgerSchemaV7` 的 `OrderRecord` shadow、`BuyLedgerSchemaV8.models` 接線與所有 top-level `@Model` 欄位維持 byte-identical 不變——交付 design「以外科手術式移除維持 V8／V7 fingerprint 不變」並守住 spec「Schema-version removal preserves the target fingerprint」。驗證：第 1 組「已在 V8 store 不觸發遷移」測試通過 (代表 fingerprint 未變)，且 `git diff` 僅含 V1~V6 與其對應 stage 的刪除、無 top-level 型別更動。

## 3. 同步 CLAUDE.md 規則並記錄一次性與 CloudKit 限制

- [x] 3.1 更新 CLAUDE.md「SwiftData Schema 與 Migration」段：保留「新增版本需凍結上一版 shadow」通則，但把版本範圍與範例對齊新 floor (V7) 與 target (V8)，並明記 V1~V6 已於 pre-release 移除、spec「Removing pre-floor schema versions is a one-way operation」(上架後不可再回頭移除版本) ——交付 design「同步更新 CLAUDE.md 的 Schema 與 Migration 規則段」。驗證：該段 content review，無 V1~V6 凍結範例殘留，且明列 floor＝V7 與一次性前提。
- [x] 3.2 在 CLAUDE.md 與 spec 明記 spec「CloudKit sync invalidates per-device removal safety」：啟用 sync 前必須重新評估版本移除與砍檔的跨裝置傳播。驗證：CLAUDE.md 與 `openspec/changes/prune-legacy-schema-versions/specs/schema-migration-plan/spec.md` 皆含此限制描述 (content review)。

## 4. 整合驗證

- [x] 4.1 跑全測試套件 (含新 `SchemaMigrationTests`) 與 macOS、iOS Simulator build，確認既有 `OrderPersistenceTests`／`CampaignPersistenceTests` 全綠、新測試檔被 file system synchronized group 拾取。驗證：`xcodebuildmcp` test 與序列化 (`cmd1 && cmd2`) 的 macOS／iOS build 皆通過。
