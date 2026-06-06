---
name: swiftdata-schema-migration
description: BuyLedger SwiftData schema 版本升級標準流程。執行 schema 變更前 invoke，取得新增版本的逐步操作指引。決策規則（lightweight vs custom、floor 限制）見 CLAUDE.md「SwiftData Schema 與 Migration」一節。
---

BuyLedger SwiftData schema 升級的逐步操作指引。決策規則（何時用 lightweight、何時用 custom、移除舊版的前提）仍在 CLAUDE.md，請先確認已閱讀。

## 前置確認

執行前先確認：

- **加欄位／加表** → `.lightweight` migration（新增帶 default 的欄位或全新 model）
- **改既有欄位型別** → `.custom` migration（dump-and-restore pattern，中介 snapshot 用 `nonisolated(unsafe) static`）

schema 定義全部在 `Core/Persistence/BuyLedgerSchema.swift`。

## 升版流程（設目前 target 為 VN-1，新版為 VN）

**步驟 1**：新增新版 schema enum

```swift
enum BuyLedgerSchemaVN: VersionedSchema {
    static var versionIdentifier = Schema.Version(N, 0, 0)
    static var models: [any PersistentModel.Type] {
        [OrderRecord.self, /* 其他受影響的 top-level @Model */]
    }
}
```

**步驟 2**：把上一版（VN-1）的受影響 `@Model` 凍結為 shadow 型別

在 `BuyLedgerSchemaVN-1` enum 內部新增 `@Model` shadow，保住 attribute fingerprint：

```swift
enum BuyLedgerSchemaVN-1: VersionedSchema {
    // ... 既有內容 ...

    @Model
    final class OrderRecord {
        // 完整複製 VN-1 當時的所有屬性，不增不減
    }
}
```

> 只有 floor 版本以外的所有保留舊版都需要凍結 shadow；floor 本身的 shadow 應已存在。執行前先讀 `Core/Persistence/BuyLedgerSchema.swift` 確認當前 floor 與 target 版本號。

**步驟 3**：在 `BuyLedgerMigrationPlan` 加入新版與遷移階段

```swift
struct BuyLedgerMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [
            // ... 既有版本 ...
            BuyLedgerSchemaVN.self,   // ← 新增
        ]
    }

    static var stages: [MigrationStage] {
        [
            // ... 既有 stages ...
            migrateVN-1toVN,          // ← 新增
        ]
    }

    static let migrateVN-1toVN = MigrationStage.lightweight(
        fromVersion: BuyLedgerSchemaVN-1.self,
        toVersion: BuyLedgerSchemaVN.self
    )
    // 若是 .custom，改用 .custom(fromVersion:toVersion:willMigrate:didMigrate:)
}
```

**步驟 4**：更新 `PersistenceContainer.make` 的 schema 指向

```swift
static func make(...) -> ModelContainer {
    let schema = Schema(versionedSchema: BuyLedgerSchemaVN.self)  // ← 改到最新版
    // ...
}
```

## 完成後核對

- `BuyLedgerSchemaVN.models` 是否正確列出所有 top-level `@Model`
- 舊版 shadow 的屬性清單是否與升版前的 top-level 定義一致
- `PersistenceContainer.make` 的 schema 是否已指向新版
- Preview / 單元測試 / snapshot 用的 in-memory container 是否需要同步更新
