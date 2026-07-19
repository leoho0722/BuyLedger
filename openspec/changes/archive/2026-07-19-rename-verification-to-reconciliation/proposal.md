## Summary

將「對帳狀態」在 iOS codebase 與跨平台 data model 的程式識別字由 verification 全面改名為 reconciliation，使程式碼與已定案的 UI 英文用詞 (對帳 = Reconciliation) 及既有 spec 命名 (order-reconciliation-status) 一致。

## Motivation

先前的本地化調整已把「對帳狀態」的英文 UI 用詞標準化為 Reconciliation，且對應 spec 早已命名為 order-reconciliation-status；但實作層 (enum case、repository、SwiftData 欄位、跨平台 schema 欄位，以及 feature／view／測試識別字) 仍沿用 verification，造成程式碼與 UI／spec 用詞長期不一致，閱讀與維護容易混淆。此 change 只做識別字對齊，不改任何使用者可見行為。

## Proposed Solution

- 跨平台 schema：把 shared/data-model/schema/LedgerOrder.yaml 的 verificationStatus 欄位改名為 reconciliationStatus，於 shared/data-model/generator 執行產生器重生成 (bun run generate)，再以 bun run check 守門；生成檔 apps/ios/BuyLedger/Core/Domain/Generated/LedgerOrder.generated.swift 由重生成產出、不手改。
- SwiftData 持久層 (需 migration，依 swiftdata-schema-migration 流程)：apps/ios/BuyLedger/Core/Persistence/OrderRecord.swift 的 verificationStatus stored property 改名為 reconciliationStatus，以 @Attribute(originalName: "verificationStatus") 保留既有 SQLite 欄位不丟資料；對帳狀態主檔 @Model 由 VerificationStatusRecord 改名為 ReconciliationStatusRecord 並比照保表。於 apps/ios/BuyLedger/Core/Persistence/BuyLedgerSchema.swift 新增 schema 版本並串接 lightweight migration stage。
- Repository：apps/ios/BuyLedger/Core/Dependencies/VerificationStatusRepository.swift 改名為 ReconciliationStatusRepository (型別、liveValue、方法)；apps/ios/BuyLedger/Core/Dependencies/OrderRepository.swift 內相關方法一併更名。
- Feature／View：LookupKind.verificationStatus 改為 reconciliationStatus，以及 OrderEditFeature／OrdersFeature／RootFeature／LookupManagementFeature／OrderEditView／LookupManagementView／MoreView 等的 draft／shows／available／selected／add／picker 系列識別字。
- 測試：所有引用 verification 識別字的測試檔一併更名，確保綠燈。
- 收斂 migration floor 到 V15：本次新增 V16 後，順帶把 floor 由 V13 升到 V15。V13/V14/V15 同在 v1.5.0 (commit c1ec0ed) 落地、target 一律為 V15，故無任何已安裝 store 曾停在 V13/V14，移除兩版及其凍結影子不孤立任何 store，schema 檔大幅精簡 (影子由 3 份減為 1 份)。

## Non-Goals

- 不改變任何使用者可見行為或文案 (UI 已顯示 Reconciliation，本 change 不動 UI copy)。
- 不改變已儲存的對帳狀態「值」(如使用者自建的「對帳成功」等主檔資料)；只改欄位／型別識別字，並以 originalName／migration 保資料。
- 不觸及與對帳無關的識別字。

## Alternatives Considered

- 維持 verification 不改：零風險，但程式碼與 spec／UI 用詞長期不一致，故不採。
- 只改非持久層識別字、保留 schema／SwiftData 的 verificationStatus：避開 migration，但在 domain／persistence 邊界產生 reconciliation 與 verification 對映的混淆，故不採。

## Impact

- Affected specs：order-reconciliation-status (命名對齊、行為不變)、schema-migration-plan (新增 V16 stage 並收斂 floor 到 V15)。
- Affected code：
  - Modified：
    - shared/data-model/schema/LedgerOrder.yaml
    - apps/ios/BuyLedger/Core/Domain/Generated/LedgerOrder.generated.swift
    - apps/ios/BuyLedger/Core/Persistence/OrderRecord.swift
    - apps/ios/BuyLedger/Core/Persistence/OrderPersistence.swift
    - apps/ios/BuyLedger/Core/Persistence/BuyLedgerSchema.swift
    - apps/ios/BuyLedger/Core/Dependencies/OrderRepository.swift
    - apps/ios/BuyLedger/Core/Domain/OrderMerge.swift
    - apps/ios/BuyLedger/Core/Domain/LedgerOrder+Samples.swift
    - apps/ios/BuyLedger/Features/Lookups/LookupKind.swift
    - apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift
    - apps/ios/BuyLedger/Features/Lookups/LookupManagementView.swift
    - apps/ios/BuyLedger/Features/Orders/OrderEditFeature.swift
    - apps/ios/BuyLedger/Features/Orders/OrderEditView.swift
    - apps/ios/BuyLedger/Features/Orders/OrdersFeature.swift
    - apps/ios/BuyLedger/Features/App/RootFeature.swift
    - apps/ios/BuyLedger/Features/More/MoreView.swift
    - apps/ios/BuyLedgerTests 下所有引用 verification 識別字的測試檔 (OrderEditFeatureTests、OrdersFeatureTests、OrderPersistenceTests、LookupManagementFeatureTests、SchemaMigrationTests、RootFeatureTests、OrderCalculationTests、OrderMergeTests 等)
  - New (檔案改名產生的新檔)：
    - apps/ios/BuyLedger/Core/Dependencies/ReconciliationStatusRepository.swift
    - apps/ios/BuyLedger/Core/Persistence/ReconciliationStatusRecord.swift
    - apps/ios/BuyLedger/Core/Persistence/ReconciliationStatusPersistence.swift
  - Removed (被改名的舊檔)：
    - apps/ios/BuyLedger/Core/Dependencies/VerificationStatusRepository.swift
    - apps/ios/BuyLedger/Core/Persistence/VerificationStatusRecord.swift
    - apps/ios/BuyLedger/Core/Persistence/VerificationStatusPersistence.swift
