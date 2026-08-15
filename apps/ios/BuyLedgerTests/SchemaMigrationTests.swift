//
//  SchemaMigrationTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/5/30.
//

import Foundation
import SwiftData
import Testing
@testable import BuyLedger

/// 驗證 V15 到 V17 的遷移
@MainActor
struct SchemaMigrationTests {
    
    // MARK: - Tests
    
    /// 驗證 V15 到 V16 的遷移保留對帳資料
    /// - Throws: 測試 store 建立或遷移失敗時拋出錯誤
    @Test func reconciliationRenameMigrationPreservesValues() throws(any Error) {
        let storeURL = try Self.makeTemporaryStoreURL()
        defer { Self.removeStore(at: storeURL) }
        
        // 1. 建立含對帳資料的 V15 store。
        let photo = Data([0xFF, 0xD8, 0xFF, 0xE0, 0x10])
        let masterNames = ["待對帳", "對帳成功", "對帳失敗"]
        try Self.seedV15Store(
            at: storeURL,
            photo: photo,
            orderStatuses: ["對帳成功", "待對帳"],
            masterNames: masterNames
        )
        
        // 目標是 V16，讀回時使用 V16 shadow 型別
        let migrated = try Self.fetchV16Orders(
            at: storeURL,
            versionedSchema: BuyLedgerSchemaV16.self,
            migrationPlan: BuyLedgerMigrationPlan.self
        )
        
        // 3. 每筆訂單的對帳狀態值保留 (verificationStatus → reconciliationStatus)
        #expect(migrated.count == 2)
        let byID = Dictionary(uniqueKeysWithValues: migrated.map { ($0.id, $0) })
        #expect(byID["BL-V15-000"]?.reconciliationStatus == "對帳成功")
        #expect(byID["BL-V15-001"]?.reconciliationStatus == "待對帳")
        
        // 4. 對帳狀態主檔完整保留。
        let statuses = try Self.fetchReconciliationStatuses(
            at: storeURL,
            versionedSchema: BuyLedgerSchemaV16.self,
            migrationPlan: BuyLedgerMigrationPlan.self
        )
        #expect(Set(statuses) == Set(masterNames))
    }
    
    /// V16 store 以 V16 schema 重新開啟時不應觸發遷移，資料與筆數原封不動
    /// - Throws: 測試 store 建立或讀取失敗時拋出錯誤
    @Test func v16StoreReopensWithoutMigration() throws(any Error) {
        let storeURL = try Self.makeTemporaryStoreURL()
        defer { Self.removeStore(at: storeURL) }
        
        // 1. 以 V16 shadow 建立含完整欄位的 store。
        let photo = Data([0xFF, 0xD8, 0xFF, 0xE0, 0x10])
        do {
            let container = try Self.makeContainer(
                versionedSchema: BuyLedgerSchemaV16.self,
                migrationPlan: nil,
                url: storeURL
            )
            let context = ModelContext(container)
            context.insert(
                BuyLedgerSchemaV16.OrderRecord(
                    order: Self.makeOrder(
                        id: "BL-V16-001", photos: [photo], reconciliationStatus: "對帳成功")
                )
            )
            try context.save()
        }
        
        // 2. 以 V16 plan 重新開啟同一 store。
        let reopened = try Self.fetchV16Orders(
            at: storeURL,
            versionedSchema: BuyLedgerSchemaV16.self,
            migrationPlan: BuyLedgerMigrationPlan.self
        )
        
        // 3. 已在 target 的 store 不觸發遷移，資料維持不變。
        #expect(reopened.count == 1)
        #expect(reopened.first?.id == "BL-V16-001")
        #expect(reopened.first?.categories == ["美妝", "服飾"])
        #expect(reopened.first?.campaignNames == ["春團", "夏團"])
        #expect(reopened.first?.mergedSourceIDs == ["BL-SRC-001", "BL-SRC-002"])
        #expect(reopened.first?.reconciliationStatus == "對帳成功")
        #expect(reopened.first?.photos == [photo])
    }
    
    /// V17 store 重新開啟時資料維持不變
    /// - Throws: 測試 store 建立或讀取失敗時拋出錯誤
    @Test func v17StoreReopensWithoutMigration() throws(any Error) {
        let storeURL = try Self.makeTemporaryStoreURL()
        defer { Self.removeStore(at: storeURL) }
        
        let photo = Data([0xFF, 0xD8, 0xFF, 0xE0, 0x10])
        
        // 1. 以真實建構路徑落下 V17 store
        do {
            let bootstrap = PersistenceContainer.makeBootstrapForTesting(storeURL: storeURL)
            guard case .healthy = bootstrap.outcome else {
                Issue.record("Expected a healthy disk-backed bootstrap when seeding a V17 store.")
                return
            }
            let context = ModelContext(bootstrap.container)
            context.insert(
                OrderRecord(
                    order: Self.makeOrder(
                        id: "BL-V17-001", photos: [photo], reconciliationStatus: "對帳成功"))
            )
            try context.save()
        }
        
        // 2. 重新開啟同一 store，確認沒有落入 in-memory fallback。
        let reopened = PersistenceContainer.makeBootstrapForTesting(storeURL: storeURL)
        guard case .healthy = reopened.outcome else {
            Issue.record(
                "V17 store reopened in degraded mode."
            )
            return
        }
        let context = ModelContext(reopened.container)
        let orders = try context.fetch(FetchDescriptor<OrderRecord>())
        
        #expect(orders.count == 1)
        #expect(orders.first?.id == "BL-V17-001")
        #expect(orders.first?.categories == ["美妝", "服飾"])
        #expect(orders.first?.campaignNames == ["春團", "夏團"])
        #expect(orders.first?.mergedSourceIDs == ["BL-SRC-001", "BL-SRC-002"])
        #expect(orders.first?.reconciliationStatus == "對帳成功")
        #expect(orders.first?.photos == [photo])
    }
    
    /// 驗證 V17 移除 SyncMeta 與 SyncQueueItem
    @Test func syncEntitiesAreAbsentFromV17Models() {
        let v15Names = BuyLedgerSchemaV15.models.map { String(describing: $0) }
        let v16Names = BuyLedgerSchemaV16.models.map { String(describing: $0) }
        let v17Names = BuyLedgerSchemaV17.models.map { String(describing: $0) }
        
        #expect(v15Names.contains { $0.contains("SyncMeta") })
        #expect(v15Names.contains { $0.contains("SyncQueueItem") })
        #expect(v16Names.contains { $0.contains("SyncMeta") })
        #expect(v16Names.contains { $0.contains("SyncQueueItem") })
        #expect(!v17Names.contains { $0.contains("SyncMeta") })
        #expect(!v17Names.contains { $0.contains("SyncQueueItem") })
    }
    
    /// V16 store 遷移至 V17 後保留訂單與照片
    /// - Throws: 測試 store 建立或遷移失敗時拋出錯誤
    @Test func v16StoreMigratesToV17PreservingOrdersAndPhotos() throws(any Error) {
        let storeURL = try Self.makeTemporaryStoreURL()
        defer { Self.removeStore(at: storeURL) }
        
        let photoA = Data([0xFF, 0xD8, 0xFF, 0xE0, 0xA1])
        let photoB = Data([0xFF, 0xD8, 0xFF, 0xE0, 0xB2])
        let masterNames = ["待對帳", "對帳成功", "對帳失敗"]
        
        // 1. 以 V16 shadow 建立含照片與對帳狀態的 store。
        try Self.seedV16Store(
            at: storeURL,
            orderPhotos: [
                "BL-V16-000": [photoA],
                "BL-V16-001": [photoA, photoB],
            ],
            masterNames: masterNames
        )
        
        // 2. 以 V17 plan 開啟，觸發 V16→V17 遷移。
        let migrated = try Self.fetchOrders(
            at: storeURL,
            versionedSchema: BuyLedgerSchemaV17.self,
            migrationPlan: BuyLedgerMigrationPlan.self
        )
        
        // 3. 筆數與每個欄位值完全相同
        #expect(migrated.count == 2)
        let byID = Dictionary(uniqueKeysWithValues: migrated.map { ($0.id, $0) })
        #expect(byID["BL-V16-000"]?.categories == ["美妝", "服飾"])
        #expect(byID["BL-V16-000"]?.campaignNames == ["春團", "夏團"])
        #expect(byID["BL-V16-000"]?.mergedSourceIDs == ["BL-SRC-001", "BL-SRC-002"])
        #expect(byID["BL-V16-000"]?.reconciliationStatus == "對帳成功")
        #expect(byID["BL-V16-001"]?.reconciliationStatus == "對帳成功")
        
        // 4. 照片位元組逐張、逐筆完全相同 (雙保險：byte 相等 + 張數相等)
        #expect(byID["BL-V16-000"]?.photos == [photoA])
        #expect(byID["BL-V16-001"]?.photos == [photoA, photoB])
        
        // 5. 對帳狀態主檔清單完整保留
        let statuses = try Self.fetchReconciliationStatuses(
            at: storeURL,
            versionedSchema: BuyLedgerSchemaV17.self,
            migrationPlan: BuyLedgerMigrationPlan.self
        )
        #expect(Set(statuses) == Set(masterNames))
    }
    
    /// 驗證 V15 store 可經兩段遷移
    /// - Throws: 測試 store 建立或遷移失敗時拋出錯誤
    @Test func v15StoreMigratesThroughV16ToV17() throws(any Error) {
        let storeURL = try Self.makeTemporaryStoreURL()
        defer { Self.removeStore(at: storeURL) }
        
        let photo = Data([0xFF, 0xD8, 0xFF, 0xE0, 0x10])
        let masterNames = ["待對帳", "對帳成功", "對帳失敗"]
        try Self.seedV15Store(
            at: storeURL,
            photo: photo,
            orderStatuses: ["對帳成功", "待對帳"],
            masterNames: masterNames
        )
        
        let migrated = try Self.fetchOrders(
            at: storeURL,
            versionedSchema: BuyLedgerSchemaV17.self,
            migrationPlan: BuyLedgerMigrationPlan.self
        )
        
        #expect(migrated.count == 2)
        let byID = Dictionary(uniqueKeysWithValues: migrated.map { ($0.id, $0) })
        #expect(byID["BL-V15-000"]?.reconciliationStatus == "對帳成功")
        #expect(byID["BL-V15-001"]?.reconciliationStatus == "待對帳")
        #expect(byID["BL-V15-000"]?.photos == [photo])
        #expect(byID["BL-V15-001"]?.photos == [photo])
        #expect(byID["BL-V15-000"]?.categories == ["美妝", "服飾"])
        #expect(byID["BL-V15-000"]?.campaignNames == ["春團", "夏團"])
        
        let statuses = try Self.fetchReconciliationStatuses(
            at: storeURL,
            versionedSchema: BuyLedgerSchemaV17.self,
            migrationPlan: BuyLedgerMigrationPlan.self
        )
        #expect(Set(statuses) == Set(masterNames))
    }
    
    /// 驗證新增索引不需凍結 shadow
    /// - Throws: 測試 store 建立或遷移失敗時拋出錯誤
    @Test func addingIndexDoesNotRequireFrozenShadow() throws(any Error) {
        let storeURL = try Self.makeTemporaryStoreURL()
        defer { Self.removeStore(at: storeURL) }
        
        // 1. 以無索引 schema 建立舊 store。
        do {
            let schema = Schema(versionedSchema: IndexAdditionNoIndexSchema.self)
            let configuration = ModelConfiguration(
                schema: schema, url: storeURL, cloudKitDatabase: .none)
            let container = try ModelContainer(for: schema, configurations: configuration)
            let context = ModelContext(container)
            context.insert(
                IndexAdditionNoIndexSchema.ProbeRecord(identifier: "probe-001", label: "無索引時期寫入"))
            try context.save()
        }
        
        // 加索引不需 migration plan，直接用新 schema 開啟同一檔案
        let indexedSchema = Schema(versionedSchema: IndexAdditionIndexedSchema.self)
        let indexedConfiguration = ModelConfiguration(
            schema: indexedSchema, url: storeURL, cloudKitDatabase: .none)
        let indexedContainer = try ModelContainer(
            for: indexedSchema, configurations: indexedConfiguration)
        let context = ModelContext(indexedContainer)
        let probes = try context.fetch(FetchDescriptor<IndexAdditionIndexedSchema.ProbeRecord>())
        
        // 3. 遷移成功、資料完整保留
        #expect(probes.count == 1)
        #expect(probes.first?.identifier == "probe-001")
        #expect(probes.first?.label == "無索引時期寫入")
    }
}

/// 建立沒有索引的測試 store
private enum IndexAdditionNoIndexSchema: VersionedSchema {
    
    // MARK: - Static Properties
    
    static var versionIdentifier: Schema.Version { Schema.Version(1, 0, 0) }
    
    static var models: [any PersistentModel.Type] {
        [ProbeRecord.self]
    }
    
    // MARK: - Nested Types
    /// 測試用的 migration 資料模型
    @Model
    final class ProbeRecord {
        
        var identifier: String
        var label: String
        
        init(identifier: String, label: String) {
            self.identifier = identifier
            self.label = label
        }
    }
}

/// 測試用的加索引 V17 schema
private enum IndexAdditionIndexedSchema: VersionedSchema {
    
    // MARK: - Static Properties
    
    static var versionIdentifier: Schema.Version { Schema.Version(1, 0, 0) }
    
    static var models: [any PersistentModel.Type] {
        [ProbeRecord.self]
    }
    
    // MARK: - Nested Types
    /// 測試用的 migration 資料模型
    @Model
    final class ProbeRecord {
        
        #Index<ProbeRecord>([\.identifier])
        
        var identifier: String
        var label: String
        
        init(identifier: String, label: String) {
            self.identifier = identifier
            self.label = label
        }
    }
}

// MARK: - Private Method

private extension SchemaMigrationTests {
    
    // MARK: Store URL
    
    /// 建立每個測試獨立、不污染 production store 的 on-disk store URL
    /// - Returns: 測試 store 路徑
    /// - Throws: 暫存路徑建立失敗時拋出錯誤
    static func makeTemporaryStoreURL() throws(any Error) -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("BuyLedgerMigrationTests", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("\(UUID().uuidString).store")
    }
    
    /// 清除 store 主檔與其 sidecar (`-wal` / `-shm`)
    static func removeStore(at url: URL) {
        let fileManager = FileManager.default
        for suffix in ["", "-wal", "-shm"] {
            let candidate = URL(fileURLWithPath: url.path + suffix)
            do {
                try fileManager.removeItem(at: candidate)
            } catch {
                guard fileManager.fileExists(atPath: candidate.path) else {
                    continue
                }
                Issue.record("無法清除測試 store：\(error.localizedDescription)")
            }
        }
    }
    
    // MARK: Container
    
    /// 建立指定 schema 的 ModelContainer
    /// - Parameters:
    ///   - versionedSchema: 版本化 schema
    ///   - migrationPlan: 遷移計畫
    ///   - url: store 路徑
    /// - Returns: ModelContainer
    /// - Throws: ModelContainer 建立失敗時拋出錯誤
    static func makeContainer(
        versionedSchema: any VersionedSchema.Type,
        migrationPlan: (any SchemaMigrationPlan.Type)?,
        url: URL
    ) throws(any Error) -> ModelContainer {
        let schema = Schema(versionedSchema: versionedSchema)
        let configuration = ModelConfiguration(
            schema: schema,
            url: url,
            cloudKitDatabase: .none
        )
        
        return try ModelContainer(
            for: schema,
            migrationPlan: migrationPlan,
            configurations: configuration
        )
    }
    
    /// 開啟指定 store 並讀取 V16 訂單
    /// - Parameters:
    ///   - url: store 路徑
    ///   - versionedSchema: 版本化 schema
    ///   - migrationPlan: 遷移計畫
    /// - Returns: 訂單記錄
    /// - Throws: store 開啟或資料讀取失敗時拋出錯誤
    static func fetchOrders(
        at url: URL,
        versionedSchema: any VersionedSchema.Type,
        migrationPlan: (any SchemaMigrationPlan.Type)?
    ) throws(any Error) -> [OrderRecord] {
        let container = try makeContainer(
            versionedSchema: versionedSchema,
            migrationPlan: migrationPlan,
            url: url
        )
        let context = ModelContext(container)
        
        return try context.fetch(FetchDescriptor<OrderRecord>())
    }
    
    /// 開啟指定 store 並讀取 V16 訂單
    /// - Parameters:
    ///   - url: store 路徑
    ///   - versionedSchema: 版本化 schema
    ///   - migrationPlan: 遷移計畫
    /// - Returns: V16 訂單記錄
    /// - Throws: store 開啟或資料讀取失敗時拋出錯誤
    static func fetchV16Orders(
        at url: URL,
        versionedSchema: any VersionedSchema.Type,
        migrationPlan: (any SchemaMigrationPlan.Type)?
    ) throws(any Error) -> [BuyLedgerSchemaV16.OrderRecord] {
        let container = try makeContainer(
            versionedSchema: versionedSchema,
            migrationPlan: migrationPlan,
            url: url
        )
        let context = ModelContext(container)
        
        return try context.fetch(FetchDescriptor<BuyLedgerSchemaV16.OrderRecord>())
    }
    
    /// 開啟指定 store 並讀取對帳狀態名稱
    /// - Parameters:
    ///   - url: store 路徑
    ///   - versionedSchema: 版本化 schema
    ///   - migrationPlan: 遷移計畫
    /// - Returns: 對帳狀態名稱
    /// - Throws: store 開啟或資料讀取失敗時拋出錯誤
    static func fetchReconciliationStatuses(
        at url: URL,
        versionedSchema: any VersionedSchema.Type,
        migrationPlan: (any SchemaMigrationPlan.Type)?
    ) throws(any Error) -> [String] {
        let container = try makeContainer(
            versionedSchema: versionedSchema,
            migrationPlan: migrationPlan,
            url: url
        )
        let context = ModelContext(container)
        
        return try context.fetch(FetchDescriptor<ReconciliationStatusRecord>()).map { $0.name }
    }
    
    // MARK: Seeding
    
    /// 建立 V15 store 供遷移測試
    /// - Parameters:
    ///   - url: store 路徑
    ///   - photo: 照片資料
    ///   - orderStatuses: 訂單狀態清單
    ///   - masterNames: 主檔名稱清單
    /// - Throws: store 建立或資料寫入失敗時拋出錯誤
    static func seedV15Store(
        at url: URL,
        photo: Data,
        orderStatuses: [String],
        masterNames: [String]
    ) throws(any Error) {
        let container = try makeContainer(
            versionedSchema: BuyLedgerSchemaV15.self,
            migrationPlan: nil,
            url: url
        )
        let context = ModelContext(container)
        
        for (index, status) in orderStatuses.enumerated() {
            context.insert(
                BuyLedgerSchemaV15.OrderRecord(
                    order: makeOrder(
                        id: String(format: "BL-V15-%03d", index),
                        photos: [photo],
                        reconciliationStatus: status
                    )
                )
            )
        }
        for name in masterNames {
            context.insert(BuyLedgerSchemaV15.VerificationStatusRecord(name: name))
        }
        try context.save()
    }
    
    /// 建立 V16 store 供遷移測試
    /// - Parameters:
    ///   - url: store 路徑
    ///   - orderPhotos: 訂單照片
    ///   - masterNames: 主檔名稱清單
    /// - Throws: store 建立或資料寫入失敗時拋出錯誤
    static func seedV16Store(
        at url: URL,
        orderPhotos: [String: [Data]],
        masterNames: [String]
    ) throws(any Error) {
        let container = try makeContainer(
            versionedSchema: BuyLedgerSchemaV16.self,
            migrationPlan: nil,
            url: url
        )
        let context = ModelContext(container)
        
        for (id, photos) in orderPhotos.sorted(by: { $0.key < $1.key }) {
            context.insert(
                BuyLedgerSchemaV16.OrderRecord(
                    order: makeOrder(id: id, photos: photos, reconciliationStatus: "對帳成功")
                )
            )
        }
        for name in masterNames {
            context.insert(ReconciliationStatusRecord(name: name))
        }
        try context.save()
    }
    
    // MARK: Order Factory
    
    /// 建立測試訂單 (預設多類別／多開團／帶合併來源)
    /// - Returns: 建立的訂單
    static func makeOrder(
        id: String,
        photos: [Data],
        categories: [String] = ["美妝", "服飾"],
        campaignNames: [String] = ["春團", "夏團"],
        mergedSourceIDs: [String] = ["BL-SRC-001", "BL-SRC-002"],
        reconciliationStatus: String = ""
    ) -> LedgerOrder {
        LedgerOrder(
            id: id,
            customer: LedgerCustomer(name: "測試客戶", initials: "VX", tier: .regular),
            status: .confirmed,
            currency: .twd,
            date: Date(timeIntervalSince1970: 1_700_000_000),
            items: [],
            itemCost: 0,
            domesticShipping: 100,
            internationalShipping: 200,
            foreignDomesticShipping: 0,
            cardFeeRate: 0,
            platformFeeRate: 0,
            paymentFeeRate: 0,
            chargedAmount: 0,
            cardlessDeductionAmount: 0,
            cardlessSupplementAmount: 0,
            orderSource: "蝦皮",
            categories: categories,
            paymentMethod: "貨到付款",
            notes: "",
            reconciliationStatus: reconciliationStatus,
            campaignNames: campaignNames,
            paymentReceiptStatus: .pending,
            isCashOnDelivery: true,
            photos: photos,
            mergedSourceIDs: mergedSourceIDs
        )
    }
}
