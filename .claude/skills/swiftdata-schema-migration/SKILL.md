---
name: swiftdata-schema-migration
description: BuyLedger SwiftData schema 版本升級標準流程。執行 schema 變更前 invoke，取得新增版本的逐步操作指引。決策規則 (lightweight vs custom、floor 限制) 見 CLAUDE.md「SwiftData Schema 與 Migration」一節。
---

BuyLedger SwiftData schema 升級的逐步操作指引。決策規則 (何時用 lightweight、何時用 custom、移除舊版的前提) 仍在 CLAUDE.md，請先確認已閱讀。

## 前置確認

執行前先確認：

- **加欄位／加表** → `.lightweight` migration (新增帶 default 的欄位或全新 model)。現存 V15 → V16 的 `OrderRecord` 欄位改名以 `@Attribute(originalName:)` 保持 lightweight 映射。
- **改既有欄位型別** → `.custom` migration 的 dump-and-restore：`willMigrate` 把舊 row 序列化進記憶體後刪除，`didMigrate` 用新版影子型別重建；中介 snapshot 用 `nonisolated(unsafe) static` (one-shot、單執行緒，無 race)。現存 V15 → V16 因對帳狀態 entity 改名採用此作法。
- **丟棄整個 entity (新版 `models` 清單完全不再列出該型別)** → 同樣 `.lightweight`：Core Data 原生支援丟棄零列 entity；若該型別在丟棄前並非零列，須另補落地 store 遷移測試證明資料保存或可接受的處置。凍結時機與改欄位型別不同：**每個仍引用該型別的保留版本都要各自凍結一份 shadow**，不是只凍前一版；新版的 `models` 清單直接省略該型別。shadow 的 doc comment 統一寫「僅為保住該版本指紋而凍結，runtime 恆為空、勿新增讀寫」，不得保留描述已移除機制的舊敘述。現存 V16 → V17 移除兩張恆空同步表 (`SyncMeta`／`SyncQueueItem`) 採用此作法：V15 與 V16 各自凍結一份 shadow，V17 的 `models` 不含這兩型。

schema 定義全部在 `Core/Persistence/BuyLedgerSchema.swift`。動手前先讀此檔確認當前 floor 與 target 版本號，並以檔內既有宣告為準。

## 升版流程 (設新版為 VN、上一版為 VM)

VN / VM 為佔位符：N 是新版號、M 是上一版號 (M = N - 1)，撰寫時請代入實際數字。

**步驟 1**：新增新版 schema enum

```swift
enum BuyLedgerSchemaVN: VersionedSchema {

    // MARK: - Static Properties

    /// 版本識別。
    static var versionIdentifier: Schema.Version { Schema.Version(N, 0, 0) }

    /// 此版本包含的 model 型別；只有最新版本引用 top-level 定義。
    static var models: [any PersistentModel.Type] {
        [OrderRecord.self, /* 其餘所有 top-level @Model */]
    }
}
```

**步驟 2**：把上一版 (VM) 的受影響 `@Model` 凍結為 shadow 型別

在 `BuyLedgerSchemaVM` enum 內部新增 `@Model` shadow，保住 attribute fingerprint：

```swift
enum BuyLedgerSchemaVM: VersionedSchema {
    // ... 既有內容 ...

    @Model
    final class OrderRecord {
        // 完整複製 VM 當時的所有屬性，不增不減
    }
}
```

> - 只有 floor 版本以外的所有保留舊版都需要凍結 shadow；floor 本身的 shadow 應已存在。
> - 若該版本同時改動多個 `@Model` 型別，每個受影響型別都要各自凍結一份 shadow，不只 `OrderRecord`。

**步驟 3**：在 `BuyLedgerMigrationPlan` 加入新版與遷移階段

`BuyLedgerMigrationPlan` 是無 case 的 `enum`，stage 直接以 inline literal 寫在 `stages` 陣列內，不另立 named constant：

```swift
enum BuyLedgerMigrationPlan: SchemaMigrationPlan {

    // MARK: - Static Properties

    static var schemas: [any VersionedSchema.Type] {
        [
            // ... 既有版本 ...
            BuyLedgerSchemaVN.self,   // ← 新增
        ]
    }

    static var stages: [MigrationStage] {
        [
            // ... 既有 stages ...
            // ↓ 新增；若是 .custom，改用 .custom(fromVersion:toVersion:willMigrate:didMigrate:)
            .lightweight(
                fromVersion: BuyLedgerSchemaVM.self,
                toVersion: BuyLedgerSchemaVN.self
            ),
        ]
    }
}
```

**步驟 4**：更新 `PersistenceContainer.make` 的 schema 指向

```swift
nonisolated static func make(...) throws -> ModelContainer {
    let schema = Schema(versionedSchema: BuyLedgerSchemaVN.self)  // ← 改到最新版
    // ...
}
```

## 完成後核對

- `BuyLedgerSchemaVN.models` 是否正確列出所有 top-level `@Model`
- 舊版 shadow 的屬性清單是否與升版前的 top-level 定義一致
- 若該版本改動多個型別，每個受影響型別是否都各自凍結了 shadow
- 若本次升版丟棄了某個 entity，是否每個仍引用該型別的保留版本都已各自凍結 shadow (不只前一版)，且新版 `models` 已不再列出該型別
- `PersistenceContainer.make` 的 schema 是否已指向新版
- Preview / 單元測試 / snapshot 用的 in-memory container 是否需要同步更新
