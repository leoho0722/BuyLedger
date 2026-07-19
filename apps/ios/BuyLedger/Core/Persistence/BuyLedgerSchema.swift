//
//  BuyLedgerSchema.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/23.
//

import Foundation
import SwiftData

/// BuyLedger SwiftData schema 的版本化定義
///
/// 目前保留的版本：
/// - ``BuyLedgerSchemaV15``：收斂後的 migration floor。此版本的 ``OrderRecord`` 對帳狀態欄位名為 `verificationStatus`、對帳狀態主檔為 `VerificationStatusRecord` entity；V16 改動此二者，故 V15 把 ``OrderRecord`` 與 ``VerificationStatusRecord`` 凍結為內嵌影子保住當時指紋。``CampaignReminderRecord`` 自 V15 未再變、引用 top-level
/// - ``BuyLedgerSchemaV16``：當前最新版本 (target)，把 ``OrderRecord`` 的對帳狀態欄位由 `verificationStatus` 改名為 `reconciliationStatus` (以 `@Attribute(originalName:)` 保欄位)，並把對帳狀態主檔 entity 由 `VerificationStatusRecord` 改名為 ``ReconciliationStatusRecord``；`models` 全部引用 top-level
///
/// V1~V14 已移除：V1~V12 於 pre-release 階段移除；V13/V14 為 v1.5.0 開團提醒功能的中間遷移版本、與 V15 同一個 release commit 落地 (target 一律為 V15)，故無任何已安裝 store 曾停在 V13/V14，floor 收斂到 V15 不會孤立任何 store
///
/// Migration 為 forward-only：停在 V15 的 store 以 `.custom` 遷到 V16
///
/// **移除版本會把 floor 往上抬 (單向操作)**：停在低於 V15 的 store 將失去遷移路徑、開啟時被 `makeForApp()` 砍檔重建，故上架後不可再回頭移除
enum BuyLedgerSchemaV15: VersionedSchema {

    // MARK: - Static Properties

    /// 版本識別
    static var versionIdentifier: Schema.Version { Schema.Version(15, 0, 0) }

    /// 此版本的 model 型別；``OrderRecord`` / ``VerificationStatusRecord`` 指向本 enum 內凍結的影子，其餘 (含 ``CampaignReminderRecord``) 維持引用 top-level
    static var models: [any PersistentModel.Type] {
        [
            OrderRecord.self,
            CategoryRecord.self,
            PaymentMethodRecord.self,
            CurrencyMetadataRecord.self,
            OrderSourceRecord.self,
            VerificationStatusRecord.self,
            CampaignRecord.self,
            SyncMeta.self,
            SyncQueueItem.self,
            CampaignReminderRecord.self,
        ]
    }

    // MARK: - Nested Types

    /// V15 的 ``OrderRecord`` 影子：對帳狀態欄位仍名為 `verificationStatus` (V16 才改名)，保住當時 attribute 指紋
    @Model
    final class OrderRecord {

        // MARK: - Data Properties

        var id: String
        var customer: LedgerCustomer
        var status: OrderStatus
        var currency: String
        var date: Date
        var items: [LedgerOrderItem]
        var itemCost: Decimal
        var domesticShipping: Decimal
        var internationalShipping: Decimal
        var foreignDomesticShipping: Decimal = 0
        var cardFeeRate: Decimal
        var platformFeeRate: Decimal
        var paymentFeeRate: Decimal = 0
        var chargedAmount: Decimal
        var cardlessDeductionAmount: Decimal = 0
        var cardlessSupplementAmount: Decimal = 0
        var orderSource: String = ""
        var categories: [String] = []
        var paymentMethod: String = ""
        var notes: String = ""
        var verificationStatus: String = ""
        var campaignNames: [String] = []
        var paymentReceiptStatus: String = PaymentReceiptStatus.pending.rawValue
        var isCashOnDelivery: Bool = false
        var photos: [Data] = []
        var mergedSourceIDs: [String] = []

        // MARK: - Init

        init(order: LedgerOrder) {
            self.id = order.id
            self.customer = order.customer
            self.status = order.status
            self.currency = order.currency.rawValue
            self.date = order.date
            self.items = order.items
            self.itemCost = order.itemCost
            self.domesticShipping = order.domesticShipping
            self.internationalShipping = order.internationalShipping
            self.foreignDomesticShipping = order.foreignDomesticShipping
            self.cardFeeRate = order.cardFeeRate
            self.platformFeeRate = order.platformFeeRate
            self.paymentFeeRate = order.paymentFeeRate
            self.chargedAmount = order.chargedAmount
            self.cardlessDeductionAmount = order.cardlessDeductionAmount
            self.cardlessSupplementAmount = order.cardlessSupplementAmount
            self.orderSource = order.orderSource
            self.categories = order.categories
            self.paymentMethod = order.paymentMethod
            self.notes = order.notes
            self.verificationStatus = order.reconciliationStatus
            self.campaignNames = order.campaignNames
            self.paymentReceiptStatus = order.paymentReceiptStatus.rawValue
            self.isCashOnDelivery = order.isCashOnDelivery
            self.photos = order.photos
            self.mergedSourceIDs = order.mergedSourceIDs
        }
    }

    /// V15 的對帳狀態主檔影子 (entity 名 `VerificationStatusRecord`)；V16 改名為 ``ReconciliationStatusRecord``
    @Model
    final class VerificationStatusRecord {

        // MARK: - Data Properties

        var name: String

        // MARK: - Init

        init(name: String) {
            self.name = name
        }
    }
}

/// V16 schema：當前最新版本 (target)，把對帳狀態的程式識別字由 verification 對齊為 reconciliation
///
/// - ``OrderRecord`` 的對帳狀態欄位由 `verificationStatus` 改名為 `reconciliationStatus`，以 `@Attribute(originalName: "verificationStatus")` 保住底層欄位名、既有值零搬遷
/// - 對帳狀態主檔 entity 由 `VerificationStatusRecord` 改名為 ``ReconciliationStatusRecord``；SwiftData 無 entity 級 originalName，故 V15 → V16 以 `.custom` stage dump/restore 保住主檔名稱清單
///
/// 其餘 model 形狀不變、``models`` 全部引用 top-level
enum BuyLedgerSchemaV16: VersionedSchema {

    // MARK: - Static Properties

    /// 版本識別
    static var versionIdentifier: Schema.Version { Schema.Version(16, 0, 0) }

    /// 此版本的 model 型別全部引用 top-level (含改名後的 ``OrderRecord`` 與 ``ReconciliationStatusRecord``)
    static var models: [any PersistentModel.Type] {
        [
            OrderRecord.self,
            CategoryRecord.self,
            PaymentMethodRecord.self,
            CurrencyMetadataRecord.self,
            OrderSourceRecord.self,
            ReconciliationStatusRecord.self,
            CampaignRecord.self,
            SyncMeta.self,
            SyncQueueItem.self,
            CampaignReminderRecord.self,
        ]
    }
}

/// 對帳狀態主檔改名 (V15 → V16) 的跨階段暫存
///
/// SwiftData 的 `.custom` migration 中，`willMigrate` 只見舊 schema、`didMigrate` 只見新 schema，兩者無法同時取用；故在 `willMigrate` 讀出舊 entity 名稱清單暫存於此，`didMigrate` 再寫進新 entity
///
/// migration 於 `ModelContainer` init 期間單執行緒執行 (one-shot、無 race)，故以 `nonisolated(unsafe) static` 承載
enum ReconciliationStatusRenameMigration {

    // MARK: - Static Properties

    /// `willMigrate` 讀出、`didMigrate` 寫回的對帳狀態主檔名稱清單
    nonisolated(unsafe) static var carriedNames: [String] = []
}

/// BuyLedger SwiftData migration plan
///
/// floor 為 V15：唯一保留的遷移為 V15 → V16 對帳狀態改名
///
/// V15 → V16 為 `.custom`：``OrderRecord`` 欄位改名由 `@Attribute(originalName:)` 走自動 (lightweight) 映射；對帳狀態主檔 entity 改名以 `willMigrate` dump／`didMigrate` restore 保住名稱清單
///
/// 停在 V15 的 store 遷到 V16，已在 V16 的 store 開啟時 delta 為 0、不觸發任何 stage
///
/// 新增版本時，於 ``schemas`` 與 ``stages`` append 新版與遷移階段，並把上一版凍結為影子型別保住其 attribute 指紋 (該型別有變更時)
enum BuyLedgerMigrationPlan: SchemaMigrationPlan {

    // MARK: - Static Properties

    /// migration plan 涉及的所有 schema 版本
    static var schemas: [any VersionedSchema.Type] {
        [
            BuyLedgerSchemaV15.self,
            BuyLedgerSchemaV16.self,
        ]
    }

    /// V15 → V16 (custom，對帳狀態改名：``OrderRecord`` 欄位以 originalName 自動映射，對帳狀態主檔 entity 以 dump/restore 保住名稱清單)
    static var stages: [MigrationStage] {
        [
            .custom(
                fromVersion: BuyLedgerSchemaV15.self,
                toVersion: BuyLedgerSchemaV16.self,
                willMigrate: { context in
                    let records = try context.fetch(
                        FetchDescriptor<BuyLedgerSchemaV15.VerificationStatusRecord>()
                    )
                    ReconciliationStatusRenameMigration.carriedNames = records.map { $0.name }
                },
                didMigrate: { context in
                    for name in ReconciliationStatusRenameMigration.carriedNames {
                        context.insert(ReconciliationStatusRecord(name: name))
                    }
                    try context.save()
                    ReconciliationStatusRenameMigration.carriedNames = []
                }
            ),
        ]
    }
}
