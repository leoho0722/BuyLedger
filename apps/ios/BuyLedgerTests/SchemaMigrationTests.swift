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

/// 驗證 V15 至 V17 遷移與同版本資料庫開啟
struct SchemaMigrationTests {

    // MARK: - Tests

    /// V15 升至 V16 後保留對帳狀態與主檔
    ///
    /// - Throws: 暫存 store 建立、遷移或資料讀取失敗時拋出錯誤；遷移後筆數不是 2 時由 `#require` 拋出
    @Test
    func stages_V15資料庫升至V16_保留對帳狀態與主檔() throws(any Error) {
        // Given
        let storeURL = try Self.makeTemporaryStoreURL()
        defer {
            Self.removeStore(at: storeURL)
        }

        let photo = Data([0xFF, 0xD8, 0xFF, 0xE0, 0x10])
        let masterNames = ["待對帳", "對帳成功", "對帳失敗"]
        try Self.seedV15Store(
            at: storeURL,
            photo: photo,
            reconciliationStatuses: ["對帳成功", "待對帳"],
            masterNames: masterNames
        )

        // When
        // 目標版本是 V16，讀回時要用 V16 的凍結型別
        let migrated = try Self.fetchV16Orders(
            at: storeURL,
            migrationPlan: BuyLedgerMigrationPlan.self
        )
        let statuses = try Self.fetchReconciliationStatuses(
            at: storeURL,
            versionedSchema: BuyLedgerSchemaV16.self,
            migrationPlan: BuyLedgerMigrationPlan.self
        )

        // Then
        try #require(migrated.count == 2)
        let ordersByID = Dictionary(migrated.map { ($0.id, $0) }) { first, _ in first }
        #expect(ordersByID["BL-V15-000"]?.reconciliationStatus == "對帳成功")
        #expect(ordersByID["BL-V15-001"]?.reconciliationStatus == "待對帳")
        #expect(statuses.sorted() == masterNames.sorted())
    }

    /// V16 資料庫以 V16 schema 開啟後保留陣列欄位、對帳狀態與照片
    ///
    /// - Throws: 暫存 store 建立、資料寫入或讀取失敗時拋出錯誤；讀回筆數不是 1 時由 `#require` 拋出
    @Test
    func schemas_V16資料庫以V16開啟_讀回陣列欄位對帳狀態與照片() throws(any Error) {
        // Given
        let storeURL = try Self.makeTemporaryStoreURL()
        defer {
            Self.removeStore(at: storeURL)
        }

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
                        id: "BL-V16-001",
                        photos: [photo],
                        reconciliationStatus: "對帳成功"
                    )
                )
            )
            try context.save()
        }

        // When
        let reopened = try Self.fetchV16Orders(
            at: storeURL,
            migrationPlan: BuyLedgerMigrationPlan.self
        )

        // Then
        try #require(reopened.count == 1)
        let order = try #require(reopened.first)
        #expect(order.id == "BL-V16-001")
        #expect(order.categories == ["美妝", "服飾"])
        #expect(order.campaignNames == ["春團", "夏團"])
        #expect(order.mergedSourceIDs == ["BL-SRC-001", "BL-SRC-002"])
        #expect(order.reconciliationStatus == "對帳成功")
        #expect(order.photos == [photo])
    }

    /// 真實 bootstrap 重開 V17 資料庫後維持正常狀態並保留陣列欄位與照片
    ///
    /// - Throws: 暫存 store 建立、資料寫入或讀取失敗時拋出錯誤；開啟狀態不是 `.healthy` 或讀回筆數不是 1 時由 `#require` 拋出
    @Test
    func makeBootstrapForTesting_V17資料庫重新開啟_維持正常狀態並保留陣列欄位與照片() throws(any Error) {
        // Given
        let storeURL = try Self.makeTemporaryStoreURL()
        defer {
            Self.removeStore(at: storeURL)
        }

        let photo = Data([0xFF, 0xD8, 0xFF, 0xE0, 0x10])
        do {
            let bootstrap = TestContainerCreationLock.withLock {
                PersistenceContainer.makeBootstrapForTesting(storeURL: storeURL)
            }
            try #require(bootstrap.status == .healthy)
            let context = ModelContext(bootstrap.container)
            context.insert(
                OrderRecord(
                    order: Self.makeOrder(
                        id: "BL-V17-001",
                        photos: [photo],
                        reconciliationStatus: "對帳成功"
                    )
                )
            )
            try context.save()
        }

        // When
        let reopened = TestContainerCreationLock.withLock {
            PersistenceContainer.makeBootstrapForTesting(storeURL: storeURL)
        }
        let reopenedContext = ModelContext(reopened.container)
        let orders = try reopenedContext.fetch(FetchDescriptor<OrderRecord>())

        // Then
        try #require(reopened.status == .healthy)
        try #require(orders.count == 1)
        let order = try #require(orders.first)
        #expect(order.id == "BL-V17-001")
        #expect(order.categories == ["美妝", "服飾"])
        #expect(order.campaignNames == ["春團", "夏團"])
        #expect(order.mergedSourceIDs == ["BL-SRC-001", "BL-SRC-002"])
        #expect(order.reconciliationStatus == "對帳成功")
        #expect(order.photos == [photo])
    }

    /// V17 schema 不包含同步資料模型
    @Test
    func models_V17資料模型_不包含同步實體() {
        // Given
        let syncMetaModelName = "SyncMeta"
        let syncQueueItemModelName = "SyncQueueItem"

        // When
        let v15Names = BuyLedgerSchemaV15.models.map { String(describing: $0) }
        let v16Names = BuyLedgerSchemaV16.models.map { String(describing: $0) }
        let v17Names = BuyLedgerSchemaV17.models.map { String(describing: $0) }

        // Then
        #expect(v15Names.contains { $0.contains(syncMetaModelName) })
        #expect(v15Names.contains { $0.contains(syncQueueItemModelName) })
        #expect(v16Names.contains { $0.contains(syncMetaModelName) })
        #expect(v16Names.contains { $0.contains(syncQueueItemModelName) })
        #expect(!v17Names.contains { $0.contains(syncMetaModelName) })
        #expect(!v17Names.contains { $0.contains(syncQueueItemModelName) })
    }

    /// V16 升至 V17 後保留訂單照片與對帳主檔
    ///
    /// - Throws: 暫存 store 建立、遷移或資料讀取失敗時拋出錯誤；遷移後筆數不是 2 時由 `#require` 拋出
    @Test
    func stages_V16資料庫升至V17_保留訂單照片與對帳主檔() throws(any Error) {
        // Given
        let storeURL = try Self.makeTemporaryStoreURL()
        defer {
            Self.removeStore(at: storeURL)
        }

        let photoA = Data([0xFF, 0xD8, 0xFF, 0xE0, 0xA1])
        let photoB = Data([0xFF, 0xD8, 0xFF, 0xE0, 0xB2])
        let masterNames = ["待對帳", "對帳成功", "對帳失敗"]
        try Self.seedV16Store(
            at: storeURL,
            orderPhotos: [
                "BL-V16-000": [photoA],
                "BL-V16-001": [photoA, photoB],
            ],
            masterNames: masterNames
        )

        // When
        let migrated = try Self.fetchOrders(
            at: storeURL,
            migrationPlan: BuyLedgerMigrationPlan.self
        )
        let statuses = try Self.fetchReconciliationStatuses(
            at: storeURL,
            versionedSchema: BuyLedgerSchemaV17.self,
            migrationPlan: BuyLedgerMigrationPlan.self
        )

        // Then
        try #require(migrated.count == 2)
        let ordersByID = Dictionary(migrated.map { ($0.id, $0) }) { first, _ in first }
        #expect(ordersByID["BL-V16-000"]?.categories == ["美妝", "服飾"])
        #expect(ordersByID["BL-V16-000"]?.campaignNames == ["春團", "夏團"])
        #expect(ordersByID["BL-V16-000"]?.mergedSourceIDs == ["BL-SRC-001", "BL-SRC-002"])
        #expect(ordersByID["BL-V16-000"]?.reconciliationStatus == "對帳成功")
        #expect(ordersByID["BL-V16-001"]?.reconciliationStatus == "對帳成功")
        #expect(ordersByID["BL-V16-000"]?.photos == [photoA])
        #expect(ordersByID["BL-V16-001"]?.photos == [photoA, photoB])
        #expect(statuses.sorted() == masterNames.sorted())
    }

    /// V15 經 V16 升至 V17 後保留對帳狀態、照片與主檔
    ///
    /// - Throws: 暫存 store 建立、遷移或資料讀取失敗時拋出錯誤；遷移後筆數不是 2 時由 `#require` 拋出
    @Test
    func stages_V15資料庫升至V17_保留對帳狀態照片與主檔() throws(any Error) {
        // Given
        let storeURL = try Self.makeTemporaryStoreURL()
        defer {
            Self.removeStore(at: storeURL)
        }

        let photo = Data([0xFF, 0xD8, 0xFF, 0xE0, 0x10])
        let masterNames = ["待對帳", "對帳成功", "對帳失敗"]
        try Self.seedV15Store(
            at: storeURL,
            photo: photo,
            reconciliationStatuses: ["對帳成功", "待對帳"],
            masterNames: masterNames
        )

        // When
        let migrated = try Self.fetchOrders(
            at: storeURL,
            migrationPlan: BuyLedgerMigrationPlan.self
        )
        let statuses = try Self.fetchReconciliationStatuses(
            at: storeURL,
            versionedSchema: BuyLedgerSchemaV17.self,
            migrationPlan: BuyLedgerMigrationPlan.self
        )

        // Then
        try #require(migrated.count == 2)
        let ordersByID = Dictionary(migrated.map { ($0.id, $0) }) { first, _ in first }
        #expect(ordersByID["BL-V15-000"]?.reconciliationStatus == "對帳成功")
        #expect(ordersByID["BL-V15-001"]?.reconciliationStatus == "待對帳")
        #expect(ordersByID["BL-V15-000"]?.photos == [photo])
        #expect(ordersByID["BL-V15-001"]?.photos == [photo])
        #expect(ordersByID["BL-V15-000"]?.categories == ["美妝", "服飾"])
        #expect(ordersByID["BL-V15-000"]?.campaignNames == ["春團", "夏團"])
        #expect(statuses.sorted() == masterNames.sorted())
    }

    /// 同版本 schema 新增單欄索引後直接開啟並保留資料
    ///
    /// - Throws: 暫存 store 建立、資料寫入、索引 schema 開啟或資料讀取失敗時拋出錯誤；讀回筆數不是 1 時由 `#require` 拋出
    @Test
    func init_同版本schema加單欄索引_直接開啟並保留資料() throws(any Error) {
        // Given
        let storeURL = try Self.makeTemporaryStoreURL()
        defer {
            Self.removeStore(at: storeURL)
        }

        do {
            let originalContainer = try Self.makeContainer(
                versionedSchema: IndexAdditionNoIndexSchema.self,
                migrationPlan: nil,
                url: storeURL
            )
            let originalContext = ModelContext(originalContainer)
            originalContext.insert(
                IndexAdditionNoIndexSchema.ProbeRecord(identifier: "probe-001", label: "無索引時期寫入")
            )
            try originalContext.save()
        }

        // When
        // 新增索引不需要遷移計畫，直接用新 schema 開啟
        let indexedContainer = try Self.makeContainer(
            versionedSchema: IndexAdditionIndexedSchema.self,
            migrationPlan: nil,
            url: storeURL
        )
        let indexedContext = ModelContext(indexedContainer)
        let probes = try indexedContext.fetch(
            FetchDescriptor<IndexAdditionIndexedSchema.ProbeRecord>()
        )

        // Then
        try #require(probes.count == 1)
        let probe = try #require(probes.first)
        #expect(probe.identifier == "probe-001")
        #expect(probe.label == "無索引時期寫入")
    }
}

// MARK: - Nested Types

extension SchemaMigrationTests {

    /// 代表尚未建立單欄索引的測試 schema
    ///
    /// - Note: `@Model` 巨集展開在檔案層級，巢狀型別不能是 `private`
    enum IndexAdditionNoIndexSchema: VersionedSchema {

        /// 保存探針欄位以驗證新增索引時既有資料仍可讀取
        ///
        /// - Note: 須與 `IndexAdditionIndexedSchema.ProbeRecord` 使用相同類別名稱，讓 SwiftData 將兩者視為同一張表
        @Model
        final class ProbeRecord {

            /// 寫入的探針識別值，重開後用來確認讀回的是同一筆
            var identifier: String

            /// 用於確認原始資料保留的文字
            var label: String

            /// 建立探針記錄
            ///
            /// - Parameters:
            ///   - identifier: 記錄識別值
            ///   - label: 驗證資料保留的文字
            init(identifier: String, label: String) {
                self.identifier = identifier
                self.label = label
            }
        }

        /// 與加索引版相同，模擬不拉新版本
        static var versionIdentifier: Schema.Version {
            Schema.Version(1, 0, 0)
        }

        /// 此 schema 唯一包含的持久化模型
        static var models: [any PersistentModel.Type] {
            [ProbeRecord.self]
        }
    }

    /// 代表加入單欄索引後的同版本測試 schema
    ///
    /// - Note: `@Model` 巨集展開在檔案層級，巢狀型別不能是 `private`
    enum IndexAdditionIndexedSchema: VersionedSchema {

        /// 以單欄索引驗證同版本 schema 可直接開啟
        ///
        /// - Note: 須與 `IndexAdditionNoIndexSchema.ProbeRecord` 使用相同類別名稱，讓 SwiftData 將兩者視為同一張表
        @Model
        final class ProbeRecord {

            /// 此欄位 `identifier` 的單欄索引
            #Index<ProbeRecord>([\.identifier])

            /// 建立單欄索引的欄位，重開後用來確認讀回的是同一筆
            var identifier: String

            /// 用於確認原始資料保留的文字
            var label: String

            /// 建立探針記錄
            ///
            /// - Parameters:
            ///   - identifier: 記錄識別值
            ///   - label: 驗證資料保留的文字
            init(identifier: String, label: String) {
                self.identifier = identifier
                self.label = label
            }
        }

        /// 與無索引版相同，模擬不拉新版本
        static var versionIdentifier: Schema.Version {
            Schema.Version(1, 0, 0)
        }

        /// 此 schema 唯一包含的持久化模型
        static var models: [any PersistentModel.Type] {
            [ProbeRecord.self]
        }
    }
}

// MARK: - Private Method

private extension SchemaMigrationTests {

    /// 建立每個測試獨立的磁碟 store URL
    ///
    /// - Returns: 暫存 store 路徑
    /// - Throws: 暫存目錄建立失敗時拋出檔案系統錯誤
    static func makeTemporaryStoreURL() throws(any Error) -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appending(path: "BuyLedgerMigrationTests", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appending(path: "\(UUID().uuidString).store", directoryHint: .notDirectory)
    }

    /// 移除 store 主檔與相關附屬檔案
    ///
    /// - Parameter url: 要移除的 store URL
    static func removeStore(at url: URL) {
        let fileManager = FileManager.default
        for suffix in ["", "-wal", "-shm"] {
            let candidate = URL(filePath: url.path + suffix)
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

    /// 建立含訂單、照片與對帳主檔的 V15 測試 store
    ///
    /// - Parameters:
    ///   - url: 要建立的 store URL
    ///   - photo: 每筆訂單要寫入的照片資料
    ///   - reconciliationStatuses: 每筆訂單的對帳狀態，筆數也是訂單筆數
    ///   - masterNames: V15 對帳狀態主檔的全部名稱
    /// - Throws: SwiftData 容器建立或初始資料寫入失敗時拋出錯誤
    static func seedV15Store(
        at url: URL,
        photo: Data,
        reconciliationStatuses: [String],
        masterNames: [String]
    ) throws(any Error) {
        let container = try makeContainer(
            versionedSchema: BuyLedgerSchemaV15.self,
            migrationPlan: nil,
            url: url
        )
        let context = ModelContext(container)

        for (index, status) in reconciliationStatuses.enumerated() {
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

    /// 以指定 schema 開啟暫存 store
    ///
    /// - Parameters:
    ///   - versionedSchema: 要開啟的版本化 schema
    ///   - migrationPlan: 開啟 store 時使用的遷移計畫，無遷移時傳入 `nil`
    ///   - url: store 的檔案 URL
    /// - Returns: 已開啟的 SwiftData 容器
    /// - Throws: SwiftData 容器建立失敗時拋出錯誤
    static func makeContainer(
        versionedSchema: any VersionedSchema.Type,
        migrationPlan: (any SchemaMigrationPlan.Type)?,
        url: URL
    ) throws(any Error) -> ModelContainer {
        let schema = Schema(versionedSchema: versionedSchema)
        let configuration = ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)

        return try TestContainerCreationLock.withLock {
            try ModelContainer(
                for: schema,
                migrationPlan: migrationPlan,
                configurations: configuration
            )
        }
    }

    /// 建立遷移測試固定欄位的訂單
    ///
    /// - Parameters:
    ///   - id: 訂單識別值
    ///   - photos: 訂單照片
    ///   - reconciliationStatus: 訂單的對帳狀態
    /// - Returns: 遷移測試使用的領域訂單
    static func makeOrder(id: String, photos: [Data], reconciliationStatus: String) -> LedgerOrder {
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
            categories: ["美妝", "服飾"],
            paymentMethod: "貨到付款",
            notes: "",
            reconciliationStatus: reconciliationStatus,
            campaignNames: ["春團", "夏團"],
            paymentReceiptStatus: .pending,
            isCashOnDelivery: true,
            photos: photos,
            mergedSourceIDs: ["BL-SRC-001", "BL-SRC-002"]
        )
    }

    /// 開啟 V16 schema 並讀取訂單
    ///
    /// - Parameters:
    ///   - url: store 的檔案 URL
    ///   - migrationPlan: 開啟 store 時使用的遷移計畫
    /// - Returns: V16 schema 的訂單記錄
    /// - Throws: SwiftData 容器建立或訂單讀取失敗時拋出錯誤
    static func fetchV16Orders(
        at url: URL,
        migrationPlan: any SchemaMigrationPlan.Type
    ) throws(any Error) -> [BuyLedgerSchemaV16.OrderRecord] {
        let container = try makeContainer(
            versionedSchema: BuyLedgerSchemaV16.self,
            migrationPlan: migrationPlan,
            url: url
        )
        let context = ModelContext(container)

        return try context.fetch(FetchDescriptor<BuyLedgerSchemaV16.OrderRecord>())
    }

    /// 開啟指定 schema 並讀取對帳狀態主檔
    ///
    /// - Parameters:
    ///   - url: store 的檔案 URL
    ///   - versionedSchema: 要開啟的版本化 schema
    ///   - migrationPlan: 開啟 store 時使用的遷移計畫
    /// - Returns: 對帳狀態名稱
    /// - Throws: SwiftData 容器建立或主檔讀取失敗時拋出錯誤
    static func fetchReconciliationStatuses(
        at url: URL,
        versionedSchema: any VersionedSchema.Type,
        migrationPlan: any SchemaMigrationPlan.Type
    ) throws(any Error) -> [String] {
        let container = try makeContainer(
            versionedSchema: versionedSchema,
            migrationPlan: migrationPlan,
            url: url
        )
        let context = ModelContext(container)

        return try context.fetch(FetchDescriptor<ReconciliationStatusRecord>()).map {
            $0.name
        }
    }

    /// 建立含照片與對帳主檔的 V16 測試 store
    ///
    /// - Parameters:
    ///   - url: 要建立的 store URL
    ///   - orderPhotos: 訂單識別值對應的照片清單
    ///   - masterNames: 對帳狀態主檔的全部名稱
    /// - Throws: SwiftData 容器建立或初始資料寫入失敗時拋出錯誤
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

        let sortedOrderPhotos = orderPhotos.sorted { lhs, rhs in
            lhs.key < rhs.key
        }
        for (id, photos) in sortedOrderPhotos {
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

    /// 開啟 V17 schema 並讀取訂單
    ///
    /// - Parameters:
    ///   - url: store 的檔案 URL
    ///   - migrationPlan: 開啟 store 時使用的遷移計畫
    /// - Returns: V17 訂單記錄
    /// - Throws: SwiftData 容器建立或訂單讀取失敗時拋出錯誤
    static func fetchOrders(
        at url: URL,
        migrationPlan: any SchemaMigrationPlan.Type
    ) throws(any Error) -> [OrderRecord] {
        let container = try makeContainer(
            versionedSchema: BuyLedgerSchemaV17.self,
            migrationPlan: migrationPlan,
            url: url
        )
        let context = ModelContext(container)

        return try context.fetch(FetchDescriptor<OrderRecord>())
    }
}
