## 1. 跨平台 schema 改名與重生成

- [x] 1.1 將 shared/data-model/schema/LedgerOrder.yaml 的 verificationStatus 欄位改名為 reconciliationStatus (doc 維持平台中立)；完成時 schema 內已無 verificationStatus 欄位 (對應 design Decision 1：改名目標一律為 reconciliation)
- [x] 1.2 於 shared/data-model/generator 執行產生器重生成 (bun run generate)，使 apps/ios/BuyLedger/Core/Domain/Generated/LedgerOrder.generated.swift 的欄位變為 reconciliationStatus (生成檔不手改)；再執行 bun run check，exit 0 表生成檔與 schema 同步 (對應 design Decision 5：跨平台 schema 先改再生成)

## 2. SwiftData 持久層與 migration (實作前 invoke /swiftdata-schema-migration)

- [x] 2.1 apps/ios/BuyLedger/Core/Persistence/OrderRecord.swift 的 stored property verificationStatus 改名為 reconciliationStatus，加 @Attribute(originalName: "verificationStatus") 保留底層欄位，並更新其 init 與 domain 映射引用；完成時 OrderRecord 對外以 reconciliationStatus 表示、SQLite 欄位名不變 (對應 design Decision 2：OrderRecord 欄位改名走 lightweight + originalName)
- [x] 2.2 依 design Decision 3：VerificationStatusRecord @Model 類別改名需明確遷移對策，定案遷移方案 (優先 entity 級 originalName，不可行則 custom dump/restore)，將型別與檔案 apps/ios/BuyLedger/Core/Persistence/VerificationStatusRecord.swift 改名為 ReconciliationStatusRecord；完成時對帳狀態主檔以新型別儲存、既有名稱清單不丟。實作前先用 Context7 查證目標 SwiftData 版本對 @Model entity 改名／originalName 的支援、確認方案後才動手；完成後須執行 Unit Test 與模擬器測試並全數通過
- [x] 2.3 apps/ios/BuyLedger/Core/Persistence/VerificationStatusPersistence.swift 改名為 ReconciliationStatusPersistence.swift，型別與方法一併更名
- [x] 2.4 apps/ios/BuyLedger/Core/Persistence/OrderPersistence.swift 內對 verificationStatus 欄位的 #Predicate 與讀寫改為 reconciliationStatus
- [x] 2.5 apps/ios/BuyLedger/Core/Persistence/BuyLedgerSchema.swift 依既有版本鏈新增下一版並串接本次改名的 migration stage、更新 target 版本，維持 floor 到 target 連續 (對應 design Decision 4：新增一個 schema 版本並串接 migration)
- [x] 2.6 於 apps/ios/BuyLedgerTests/SchemaMigrationTests.swift 新增一案：升級前 store 含對帳狀態欄位值與主檔清單，升級後逐項比對皆保留 (不依賴 makeForApp fallback 砍檔)，以滿足 spec 需求 Data preservation across retained migrations

## 3. Repository

- [x] 3.1 apps/ios/BuyLedger/Core/Dependencies/VerificationStatusRepository.swift 改名為 ReconciliationStatusRepository.swift：型別、DependencyKey 的 liveValue/previewValue、方法 (add/remove/rename/load) 全部由 verification* 改為 reconciliation*
- [x] 3.2 apps/ios/BuyLedger/Core/Dependencies/OrderRepository.swift 內對帳狀態相關方法 (如 renameVerificationStatus) 與呼叫改為 reconciliation*

## 4. Feature 與 View 識別字

- [x] [P] 4.1 apps/ios/BuyLedger/Features/Lookups/LookupKind.swift 的 case verificationStatus 改為 reconciliationStatus (title 等顯示字串維持中文原文、不動 UI copy)
- [x] [P] 4.2 apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift 與 LookupManagementView.swift 的 verification* 識別字改為 reconciliation*
- [x] [P] 4.3 apps/ios/BuyLedger/Features/Orders/OrderEditFeature.swift 與 OrderEditView.swift 的 draft/shows*Row/shows*Sheet/available/selected/add*Tapped/*PickerTapped/*PickerRow 等 verification* 識別字改為 reconciliation*
- [x] [P] 4.4 apps/ios/BuyLedger/Features/Orders/OrdersFeature.swift 與 apps/ios/BuyLedger/Features/App/RootFeature.swift 的 verification* 識別字 (含 cascade rename 攔截處) 改為 reconciliation*
- [x] [P] 4.5 apps/ios/BuyLedger/Features/More/MoreView.swift 的 verification* 識別字改為 reconciliation*
- [x] [P] 4.6 apps/ios/BuyLedger/Core/Domain/OrderMerge.swift 與 apps/ios/BuyLedger/Core/Domain/LedgerOrder+Samples.swift 的 verification* 引用改為 reconciliation*

## 5. 測試更名

- [x] 5.1 更新 apps/ios/BuyLedgerTests 下所有引用 verification 識別字的測試檔 (OrderEditFeatureTests、OrdersFeatureTests、OrderPersistenceTests、LookupManagementFeatureTests、RootFeatureTests、OrderCalculationTests、OrderMergeTests、OrderMergeFeatureTests、OrdersFeaturePerformanceTests、CampaignIntegrationTests、CampaignSummaryTests、CustomersFeatureTests、DashboardStatsTests、InsightsAttributionTests、InsightsStatsTests、SnapshotTests) 的識別字為 reconciliation*，斷言與固定資料一併更新

## 6. 文件同步

- [x] 6.1 若 apps/ios/CLAUDE.md 或其他文件提及 verificationStatus 識別字，一併更新為 reconciliationStatus (概念詞「對帳狀態」與 UI 文案不變)

## 7. 驗證

- [x] 7.1 於 shared/data-model/generator 執行 bun run check，exit 0
- [x] 7.2 iOS 與 iPadOS simulator build 各通過一次 (以 && 序列化，避免 build.db 鎖)
- [x] 7.3 全測試綠燈，特別確認 SchemaMigrationTests 與 OrderPersistenceTests 的資料保留案通過
- [x] 7.4 實機驗證：以改名前的既有 store 升級，確認每筆訂單的對帳狀態值與對帳狀態主檔清單皆完整保留、無 fallback 砍檔
- [x] 7.5 全 codebase grep 確認已無 verification 或 Verification 殘留 (生成檔亦然)

## 8. 收斂 migration floor 到 V15

- [x] 8.1 查證 V13/V14 從未有已安裝 store 停在其上 (V13/V14/V15 同在 v1.5.0 commit c1ec0ed 落地、target 一律 V15；1.5.0 之前的 store 已於當時 floor-V13 砍檔)，確認 floor 可安全升到 V15 (對應 design Decision 6)
- [x] 8.2 BuyLedgerSchema.swift 移除 BuyLedgerSchemaV13 / BuyLedgerSchemaV14 兩個 version enum 及其所有凍結影子 (OrderRecord / VerificationStatusRecord / CampaignReminderRecord)；BuyLedgerMigrationPlan.schemas 收斂為 [V15, V16]、stages 收斂為單一 V15→V16 custom stage；V15 (新 floor) 保留 OrderRecord + VerificationStatusRecord 影子
- [x] 8.3 SchemaMigrationTests.swift 移除只能測 V13 的 v13StoreMigratesToV16 與 seedV13Store / fetchReminders helper；保留並通過 reconciliationRenameMigrationPreservesValues (V15→V16 floor→target) 與 v16StoreReopensWithoutMigration
- [x] 8.4 文件同步：apps/ios/README.md 的 floor 由 V13 改為 V15、apps/ios/CLAUDE.md 的 floor 範例與 CampaignReminderRecord 版本史更新
- [x] 8.5 iOS + iPadOS build 綠、全測試綠 (V15→V16 資料保留案通過)
