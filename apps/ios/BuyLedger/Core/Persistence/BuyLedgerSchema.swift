//
//  BuyLedgerSchema.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/23.
//

import Foundation
import SwiftData

/// BuyLedger SwiftData schema 的版本化定義
enum BuyLedgerSchemaV15: VersionedSchema {

    // MARK: - Properties

    /// 版本識別
    static var versionIdentifier: Schema.Version { Schema.Version(15, 0, 0) }

    /// 此版本使用的 SwiftData model；改動中的型別使用本版本凍結的影子
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

    /// V15 的 OrderRecord 影子；保留 verificationStatus 欄位名稱
    @Model
    final class OrderRecord {

        // MARK: - Properties

        /// 訂單識別碼
        var id: String

        /// 客戶資料
        var customer: LedgerCustomer

        /// 訂單狀態
        var status: OrderStatus

        /// 商品原始幣別
        var currency: String

        /// 訂單建立或更新日期
        var date: Date

        /// 商品項目
        var items: [LedgerOrderItem]

        /// 商品成本
        var itemCost: Decimal

        /// 國內運費成本
        var domesticShipping: Decimal

        /// 國際運費成本
        var internationalShipping: Decimal

        /// 商品來源國當地國內運費成本
        var foreignDomesticShipping: Decimal = 0

        /// 刷卡手續費比例
        var cardFeeRate: Decimal

        /// 平台手續費比例
        var platformFeeRate: Decimal

        /// 金流手續費比例
        var paymentFeeRate: Decimal = 0

        /// 實際收款金額
        var chargedAmount: Decimal

        /// 無卡付款折抵金額
        var cardlessDeductionAmount: Decimal = 0

        /// 無卡付款補款金額
        var cardlessSupplementAmount: Decimal = 0

        /// 訂單來源
        var orderSource: String = ""

        /// 商品類別清單
        var categories: [String] = []

        /// 付款方式
        var paymentMethod: String = ""

        /// 訂單備註
        var notes: String = ""

        /// V15 的對帳狀態欄位
        var verificationStatus: String = ""

        /// 歸屬的開團名稱清單
        var campaignNames: [String] = []

        /// 收款狀態的原始值
        var paymentReceiptStatus: String = PaymentReceiptStatus.pending.rawValue

        /// 是否以貨到付款方式成立
        var isCashOnDelivery: Bool = false

        /// 訂單照片
        var photos: [Data] = []

        /// 合併來源訂單編號
        var mergedSourceIDs: [String] = []

        // MARK: - Init

        /// 依領域訂單建立 V15 的影子記錄
        /// - Parameter order: 對應的領域訂單
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

    /// V15 的對帳狀態主檔影子；V16 改名為 ReconciliationStatusRecord
    @Model
    final class VerificationStatusRecord {

        // MARK: - Properties

        /// 主檔名稱
        var name: String

        // MARK: - Init

        /// 依名稱建立 V15 的影子記錄
        /// - Parameter name: 主檔名稱
        init(name: String) {
            self.name = name
        }
    }

    /// V15 的 SyncMeta 影子；只供遷移使用，runtime 不讀寫
    @Model
    final class SyncMeta {

        // MARK: - Properties

        /// 被同步的資料識別碼
        var entityID: String

        /// 資料集合名稱
        var collection: String

        /// 欄位時鐘的 JSON 文字
        var fieldClocksJSON: String

        /// 有異動的欄位名稱
        var dirtyFields: [String]

        /// 是否標記為刪除
        var deleteTombstone: Bool

        /// 刪除操作的時鐘
        var deleteClock: String

        /// 待處理狀態的原始值
        var pendingStateRaw: String

        /// 重試次數
        var retryCount: Int

        /// 最近發出的 HLC
        var lastIssuedHLC: String

        /// 待送出的遠端資料 JSON
        var pendingRemoteJSON: String

        /// 照片參照的 JSON 文字
        var photoRefsJSON: String

        // MARK: - Init

        /// 依同步狀態建立 V15 的影子記錄
        /// - Parameters:
        ///   - entityID: 被同步的資料識別碼
        ///   - collection: 資料集合名稱
        ///   - fieldClocksJSON: 欄位時鐘的 JSON 文字
        ///   - dirtyFields: 有異動的欄位名稱
        ///   - deleteTombstone: 是否標記為刪除
        ///   - deleteClock: 刪除操作的時鐘
        ///   - pendingStateRaw: 待處理狀態的原始值
        ///   - retryCount: 重試次數
        ///   - lastIssuedHLC: 最近發出的 HLC
        ///   - pendingRemoteJSON: 待送出的遠端資料 JSON
        ///   - photoRefsJSON: 照片參照的 JSON 文字
        init(
            entityID: String,
            collection: String,
            fieldClocksJSON: String = "{}",
            dirtyFields: [String] = [],
            deleteTombstone: Bool = false,
            deleteClock: String = "",
            pendingStateRaw: String = "synced",
            retryCount: Int = 0,
            lastIssuedHLC: String = "",
            pendingRemoteJSON: String = "{}",
            photoRefsJSON: String = "[]"
        ) {
            self.entityID = entityID
            self.collection = collection
            self.fieldClocksJSON = fieldClocksJSON
            self.dirtyFields = dirtyFields
            self.deleteTombstone = deleteTombstone
            self.deleteClock = deleteClock
            self.pendingStateRaw = pendingStateRaw
            self.retryCount = retryCount
            self.lastIssuedHLC = lastIssuedHLC
            self.pendingRemoteJSON = pendingRemoteJSON
            self.photoRefsJSON = photoRefsJSON
        }
    }

    /// V15 的 SyncQueueItem 影子；只供遷移使用，勿加入 runtime 讀寫
    @Model
    final class SyncQueueItem {

        // MARK: - Properties

        /// 操作識別碼
        var opID: String

        /// 被同步的資料識別碼
        var entityID: String

        /// 資料集合名稱
        var collection: String

        /// 操作類型的原始值
        var opRaw: String

        /// 異動欄位的 JSON 文字
        var changedFieldsJSON: String

        /// 欄位時鐘的 JSON 文字
        var fieldClocksJSON: String

        /// 已嘗試次數
        var attempts: Int

        /// 加入佇列的時間
        var enqueuedAt: Date

        // MARK: - Init

        /// 依同步操作建立 V15 的影子記錄
        /// - Parameters:
        ///   - opID: 操作識別碼
        ///   - entityID: 被同步的資料識別碼
        ///   - collection: 資料集合名稱
        ///   - opRaw: 操作類型的原始值
        ///   - changedFieldsJSON: 異動欄位的 JSON 文字
        ///   - fieldClocksJSON: 欄位時鐘的 JSON 文字
        ///   - attempts: 已嘗試次數
        ///   - enqueuedAt: 加入佇列的時間
        init(
            opID: String,
            entityID: String,
            collection: String,
            opRaw: String,
            changedFieldsJSON: String,
            fieldClocksJSON: String,
            attempts: Int = 0,
            enqueuedAt: Date
        ) {
            self.opID = opID
            self.entityID = entityID
            self.collection = collection
            self.opRaw = opRaw
            self.changedFieldsJSON = changedFieldsJSON
            self.fieldClocksJSON = fieldClocksJSON
            self.attempts = attempts
            self.enqueuedAt = enqueuedAt
        }
    }
}

/// V16 schema：把對帳狀態的程式識別字由 verification 對齊為 reconciliation
enum BuyLedgerSchemaV16: VersionedSchema {

    // MARK: - Properties

    /// 版本識別
    static var versionIdentifier: Schema.Version { Schema.Version(16, 0, 0) }

    /// 此版本使用的 SwiftData model；改動中的型別使用本版本凍結的影子
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

    // MARK: - Nested Types

    /// V16 的 OrderRecord 影子；保留 V17 前的資料形狀
    @Model
    final class OrderRecord {

        // MARK: - Properties

        /// 訂單識別碼
        var id: String

        /// 客戶資料
        var customer: LedgerCustomer

        /// 訂單狀態
        var status: OrderStatus

        /// 商品原始幣別
        var currency: String

        /// 訂單建立或更新日期
        var date: Date

        /// 商品項目
        var items: [LedgerOrderItem]

        /// 商品成本
        var itemCost: Decimal

        /// 國內運費成本
        var domesticShipping: Decimal

        /// 國際運費成本
        var internationalShipping: Decimal

        /// 商品來源國當地國內運費成本
        var foreignDomesticShipping: Decimal = 0

        /// 刷卡手續費比例
        var cardFeeRate: Decimal

        /// 平台手續費比例
        var platformFeeRate: Decimal

        /// 金流手續費比例
        var paymentFeeRate: Decimal = 0

        /// 實際收款金額
        var chargedAmount: Decimal

        /// 無卡付款折抵金額
        var cardlessDeductionAmount: Decimal = 0

        /// 無卡付款補款金額
        var cardlessSupplementAmount: Decimal = 0

        /// 訂單來源
        var orderSource: String = ""

        /// 商品類別清單
        var categories: [String] = []

        /// 付款方式
        var paymentMethod: String = ""

        /// 訂單備註
        var notes: String = ""

        /// V16 的對帳狀態欄位
        @Attribute(originalName: "verificationStatus")
        var reconciliationStatus: String = ""

        /// 歸屬的開團名稱清單
        var campaignNames: [String] = []

        /// 收款狀態的原始值
        var paymentReceiptStatus: String = PaymentReceiptStatus.pending.rawValue

        /// 是否以貨到付款方式成立
        var isCashOnDelivery: Bool = false

        /// 訂單照片
        var photos: [Data] = []

        /// 合併來源訂單編號
        var mergedSourceIDs: [String] = []

        // MARK: - Init

        /// 依領域訂單建立 V16 的影子記錄
        /// - Parameter order: 對應的領域訂單
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
            self.reconciliationStatus = order.reconciliationStatus
            self.campaignNames = order.campaignNames
            self.paymentReceiptStatus = order.paymentReceiptStatus.rawValue
            self.isCashOnDelivery = order.isCashOnDelivery
            self.photos = order.photos
            self.mergedSourceIDs = order.mergedSourceIDs
        }
    }

    /// V16 的 SyncMeta 影子；只供遷移使用，runtime 不讀寫
    @Model
    final class SyncMeta {

        // MARK: - Properties

        /// 被同步的資料識別碼
        var entityID: String

        /// 資料集合名稱
        var collection: String

        /// 欄位時鐘的 JSON 文字
        var fieldClocksJSON: String

        /// 有異動的欄位名稱
        var dirtyFields: [String]

        /// 是否標記為刪除
        var deleteTombstone: Bool

        /// 刪除操作的時鐘
        var deleteClock: String

        /// 待處理狀態的原始值
        var pendingStateRaw: String

        /// 重試次數
        var retryCount: Int

        /// 最近發出的 HLC
        var lastIssuedHLC: String

        /// 待送出的遠端資料 JSON
        var pendingRemoteJSON: String

        /// 照片參照的 JSON 文字
        var photoRefsJSON: String

        // MARK: - Init

        /// 依同步狀態建立 V16 的影子記錄
        /// - Parameters:
        ///   - entityID: 被同步的資料識別碼
        ///   - collection: 資料集合名稱
        ///   - fieldClocksJSON: 欄位時鐘的 JSON 文字
        ///   - dirtyFields: 有異動的欄位名稱
        ///   - deleteTombstone: 是否標記為刪除
        ///   - deleteClock: 刪除操作的時鐘
        ///   - pendingStateRaw: 待處理狀態的原始值
        ///   - retryCount: 重試次數
        ///   - lastIssuedHLC: 最近發出的 HLC
        ///   - pendingRemoteJSON: 待送出的遠端資料 JSON
        ///   - photoRefsJSON: 照片參照的 JSON 文字
        init(
            entityID: String,
            collection: String,
            fieldClocksJSON: String = "{}",
            dirtyFields: [String] = [],
            deleteTombstone: Bool = false,
            deleteClock: String = "",
            pendingStateRaw: String = "synced",
            retryCount: Int = 0,
            lastIssuedHLC: String = "",
            pendingRemoteJSON: String = "{}",
            photoRefsJSON: String = "[]"
        ) {
            self.entityID = entityID
            self.collection = collection
            self.fieldClocksJSON = fieldClocksJSON
            self.dirtyFields = dirtyFields
            self.deleteTombstone = deleteTombstone
            self.deleteClock = deleteClock
            self.pendingStateRaw = pendingStateRaw
            self.retryCount = retryCount
            self.lastIssuedHLC = lastIssuedHLC
            self.pendingRemoteJSON = pendingRemoteJSON
            self.photoRefsJSON = photoRefsJSON
        }
    }

    /// V16 的 SyncQueueItem 影子；只供遷移使用，勿加入 runtime 讀寫
    @Model
    final class SyncQueueItem {

        // MARK: - Properties

        /// 操作識別碼
        var opID: String

        /// 被同步的資料識別碼
        var entityID: String

        /// 資料集合名稱
        var collection: String

        /// 操作類型的原始值
        var opRaw: String

        /// 異動欄位的 JSON 文字
        var changedFieldsJSON: String

        /// 欄位時鐘的 JSON 文字
        var fieldClocksJSON: String

        /// 已嘗試次數
        var attempts: Int

        /// 加入佇列的時間
        var enqueuedAt: Date

        // MARK: - Init

        /// 依同步操作建立 V16 的影子記錄
        /// - Parameters:
        ///   - opID: 操作識別碼
        ///   - entityID: 被同步的資料識別碼
        ///   - collection: 資料集合名稱
        ///   - opRaw: 操作類型的原始值
        ///   - changedFieldsJSON: 異動欄位的 JSON 文字
        ///   - fieldClocksJSON: 欄位時鐘的 JSON 文字
        ///   - attempts: 已嘗試次數
        ///   - enqueuedAt: 加入佇列的時間
        init(
            opID: String,
            entityID: String,
            collection: String,
            opRaw: String,
            changedFieldsJSON: String,
            fieldClocksJSON: String,
            attempts: Int = 0,
            enqueuedAt: Date
        ) {
            self.opID = opID
            self.entityID = entityID
            self.collection = collection
            self.opRaw = opRaw
            self.changedFieldsJSON = changedFieldsJSON
            self.fieldClocksJSON = fieldClocksJSON
            self.attempts = attempts
            self.enqueuedAt = enqueuedAt
        }
    }
}

/// V17 schema：當前最新版本 (target)
enum BuyLedgerSchemaV17: VersionedSchema {

    // MARK: - Properties

    /// 版本識別
    static var versionIdentifier: Schema.Version { Schema.Version(17, 0, 0) }

    /// 此版本使用的 SwiftData model；改動中的型別使用本版本凍結的影子
    static var models: [any PersistentModel.Type] {
        [
            OrderRecord.self,
            CategoryRecord.self,
            PaymentMethodRecord.self,
            CurrencyMetadataRecord.self,
            OrderSourceRecord.self,
            ReconciliationStatusRecord.self,
            CampaignRecord.self,
            CampaignReminderRecord.self,
        ]
    }
}

/// 對帳狀態主檔改名 (V15 → V16) 的跨階段暫存
enum ReconciliationStatusRenameMigration {

    // MARK: - Properties

    /// `willMigrate` 讀出、`didMigrate` 寫回的對帳狀態主檔名稱清單
    nonisolated(unsafe) static var carriedNames: [String] = []
}

/// BuyLedger SwiftData migration plan
enum BuyLedgerMigrationPlan: SchemaMigrationPlan {

    // MARK: - Properties

    /// migration plan 涉及的所有 schema 版本
    static var schemas: [any VersionedSchema.Type] {
        [
            BuyLedgerSchemaV15.self,
            BuyLedgerSchemaV16.self,
            BuyLedgerSchemaV17.self,
        ]
    }

    /// V15→V16 自訂遷移；V16→V17 輕量遷移
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
            .lightweight(
                fromVersion: BuyLedgerSchemaV16.self,
                toVersion: BuyLedgerSchemaV17.self
            ),
        ]
    }
}
