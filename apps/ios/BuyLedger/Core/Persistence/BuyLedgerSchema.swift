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
    
    // MARK: - Static Properties
    
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
    
    /// V15 的對帳狀態主檔影子；V16 改名為 ReconciliationStatusRecord
    @Model
    final class VerificationStatusRecord {
        
        // MARK: - Data Properties
        
        var name: String
        
        // MARK: - Init
        
        init(name: String) {
            self.name = name
        }
    }
    
    /// V15 的 SyncMeta 影子；只供遷移使用，runtime 不讀寫
    @Model
    final class SyncMeta {
        
        // MARK: - Data Properties
        
        var entityID: String
        var collection: String
        var fieldClocksJSON: String
        var dirtyFields: [String]
        var deleteTombstone: Bool
        var deleteClock: String
        var pendingStateRaw: String
        var retryCount: Int
        var lastIssuedHLC: String
        var pendingRemoteJSON: String
        var photoRefsJSON: String
        
        // MARK: - Init
        
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
        
        // MARK: - Data Properties
        
        var opID: String
        var entityID: String
        var collection: String
        var opRaw: String
        var changedFieldsJSON: String
        var fieldClocksJSON: String
        var attempts: Int
        var enqueuedAt: Date
        
        // MARK: - Init
        
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
    
    // MARK: - Static Properties
    
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
        
        @Attribute(originalName: "verificationStatus")
        var reconciliationStatus: String = ""
        
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
        
        // MARK: - Data Properties
        
        var entityID: String
        var collection: String
        var fieldClocksJSON: String
        var dirtyFields: [String]
        var deleteTombstone: Bool
        var deleteClock: String
        var pendingStateRaw: String
        var retryCount: Int
        var lastIssuedHLC: String
        var pendingRemoteJSON: String
        var photoRefsJSON: String
        
        // MARK: - Init
        
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
        
        // MARK: - Data Properties
        
        var opID: String
        var entityID: String
        var collection: String
        var opRaw: String
        var changedFieldsJSON: String
        var fieldClocksJSON: String
        var attempts: Int
        var enqueuedAt: Date
        
        // MARK: - Init
        
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
    
    // MARK: - Static Properties
    
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
    
    // MARK: - Static Properties
    
    /// `willMigrate` 讀出、`didMigrate` 寫回的對帳狀態主檔名稱清單
    nonisolated(unsafe) static var carriedNames: [String] = []
}

/// BuyLedger SwiftData migration plan
enum BuyLedgerMigrationPlan: SchemaMigrationPlan {
    
    // MARK: - Static Properties
    
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
