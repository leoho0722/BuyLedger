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

/// 驗證收斂後的 ``BuyLedgerMigrationPlan`` (floor V15) 在 on-disk store 上的遷移行為
///
/// 與其他 persistence 測試刻意不同：這裡使用「實體檔案」store 而非 in-memory
///
/// SwiftData 的 migration 只在開啟既有 store、且其 schema 指紋與 target 有 delta 時才會執行；
/// in-memory 永遠是全新的 target store，無法行經遷移路徑，因此無法守住砍檔 fallback 與指紋穩定性
@MainActor
struct SchemaMigrationTests {

    // MARK: - Tests

    /// 對帳狀態改名前 (V15，floor) 的 store 遷到 V16 後，每筆訂單的對帳狀態值與對帳狀態主檔清單皆完整保留
    ///
    /// 對應 spec 需求 Data preservation across retained migrations 的 Scenario
    /// 「Reconciliation-status rename migration preserves values」：
    /// - ``OrderRecord`` 的 `verificationStatus` 欄位值經 `@Attribute(originalName:)` 映射到 `reconciliationStatus`
    /// - 對帳狀態主檔 entity 由 `VerificationStatusRecord` 以 `.custom` stage dump/restore 到 ``ReconciliationStatusRecord``，名稱清單不丟
    @Test func reconciliationRenameMigrationPreservesValues() throws {
        let storeURL = Self.makeTemporaryStoreURL()
        defer { Self.removeStore(at: storeURL) }

        // 1. 以 V15 schema 落下改名前 store：兩筆帶對帳狀態值的訂單 + 一份對帳狀態主檔 (含未被任何訂單使用的項目)
        let photo = Data([0xFF, 0xD8, 0xFF, 0xE0, 0x10])
        let masterNames = ["待對帳", "對帳成功", "對帳失敗"]
        try Self.seedV15Store(
            at: storeURL,
            photo: photo,
            orderStatuses: ["對帳成功", "待對帳"],
            masterNames: masterNames
        )

        // 2. 用收斂後的 plan (target V16) 開啟，觸發 V15 → V16 對帳狀態改名遷移
        let migrated = try Self.fetchOrders(
            at: storeURL,
            versionedSchema: BuyLedgerSchemaV16.self,
            migrationPlan: BuyLedgerMigrationPlan.self
        )

        // 3. 每筆訂單的對帳狀態值保留 (verificationStatus → reconciliationStatus)
        #expect(migrated.count == 2)
        let byID = Dictionary(uniqueKeysWithValues: migrated.map { ($0.id, $0) })
        #expect(byID["BL-V15-000"]?.reconciliationStatus == "對帳成功")
        #expect(byID["BL-V15-001"]?.reconciliationStatus == "待對帳")

        // 4. 對帳狀態主檔清單完整保留 (含未被訂單使用的「對帳失敗」)，且已改由 ReconciliationStatusRecord 承載
        let statuses = try Self.fetchReconciliationStatuses(
            at: storeURL,
            versionedSchema: BuyLedgerSchemaV16.self,
            migrationPlan: BuyLedgerMigrationPlan.self
        )
        #expect(Set(statuses) == Set(masterNames))
    }

    /// V16 store 以 V16 schema 重新開啟時不應觸發遷移，資料與筆數原封不動
    ///
    /// 此測試同時作為「V16 schema 指紋未被意外更動」的守門
    ///
    /// 若改動 top-level `@Model` 或 V15／V16 定義導致指紋改變，開啟既有 V16 store 會嘗試非預期的遷移或拋錯，本測試即失敗
    @Test func v16StoreReopensWithoutMigration() throws {
        let storeURL = Self.makeTemporaryStoreURL()
        defer { Self.removeStore(at: storeURL) }

        // 1. 以 target V16 直接建立 store 並寫入一筆多類別/多開團、帶合併來源與對帳狀態的訂單
        let photo = Data([0xFF, 0xD8, 0xFF, 0xE0, 0x10])
        do {
            let container = try Self.makeContainer(
                versionedSchema: BuyLedgerSchemaV16.self,
                migrationPlan: nil,
                url: storeURL
            )
            let context = ModelContext(container)
            context.insert(OrderRecord(order: Self.makeOrder(id: "BL-V16-001", photo: photo, reconciliationStatus: "對帳成功")))
            try context.save()
        }

        // 2. 用收斂後的 plan 重新開啟同一 store
        let reopened = try Self.fetchOrders(
            at: storeURL,
            versionedSchema: BuyLedgerSchemaV16.self,
            migrationPlan: BuyLedgerMigrationPlan.self
        )

        // 3. 已在 target 的 store 不觸發遷移，資料原封不動 (含陣列欄位、對帳狀態與照片 data)
        #expect(reopened.count == 1)
        #expect(reopened.first?.id == "BL-V16-001")
        #expect(reopened.first?.categories == ["美妝", "服飾"])
        #expect(reopened.first?.campaignNames == ["春團", "夏團"])
        #expect(reopened.first?.mergedSourceIDs == ["BL-SRC-001", "BL-SRC-002"])
        #expect(reopened.first?.reconciliationStatus == "對帳成功")
        #expect(reopened.first?.photos == [photo])
    }
}

// MARK: - Private Method

private extension SchemaMigrationTests {

    // MARK: Store URL

    /// 建立每個測試獨立、不污染 production store 的 on-disk store URL
    static func makeTemporaryStoreURL() -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("BuyLedgerMigrationTests", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("\(UUID().uuidString).store")
    }

    /// 清除 store 主檔與其 sidecar (`-wal` / `-shm`)
    static func removeStore(at url: URL) {
        let fileManager = FileManager.default
        for suffix in ["", "-wal", "-shm"] {
            let candidate = URL(fileURLWithPath: url.path + suffix)
            try? fileManager.removeItem(at: candidate)
        }
    }

    // MARK: Container

    /// 以指定版本 schema、migration plan 與實體 URL 建立 ``ModelContainer``；明確關閉 CloudKit 以維持純本機行為
    static func makeContainer(
        versionedSchema: any VersionedSchema.Type,
        migrationPlan: (any SchemaMigrationPlan.Type)?,
        url: URL
    ) throws -> ModelContainer {
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

    /// 以指定 schema／plan 開啟 store 並讀回全部 ``OrderRecord``
    static func fetchOrders(
        at url: URL,
        versionedSchema: any VersionedSchema.Type,
        migrationPlan: (any SchemaMigrationPlan.Type)?
    ) throws -> [OrderRecord] {
        let container = try makeContainer(
            versionedSchema: versionedSchema,
            migrationPlan: migrationPlan,
            url: url
        )
        let context = ModelContext(container)

        return try context.fetch(FetchDescriptor<OrderRecord>())
    }

    /// 以指定 schema／plan 開啟 store 並讀回全部對帳狀態主檔名稱 (``ReconciliationStatusRecord``)
    static func fetchReconciliationStatuses(
        at url: URL,
        versionedSchema: any VersionedSchema.Type,
        migrationPlan: (any SchemaMigrationPlan.Type)?
    ) throws -> [String] {
        let container = try makeContainer(
            versionedSchema: versionedSchema,
            migrationPlan: migrationPlan,
            url: url
        )
        let context = ModelContext(container)

        return try context.fetch(FetchDescriptor<ReconciliationStatusRecord>()).map { $0.name }
    }

    // MARK: Seeding

    /// 以 V15 schema (floor，對帳狀態改名前的最後一版) 落下 store：帶對帳狀態值的訂單與對帳狀態主檔清單，供 V15 → V16 改名遷移測試
    /// - Parameters:
    ///   - url: store 位置
    ///   - photo: 訂單要附上的照片 data
    ///   - orderStatuses: 每筆訂單的對帳狀態值 (存入 V15 shadow 的 `verificationStatus` 欄位)
    ///   - masterNames: 對帳狀態主檔清單 (存入 V15 shadow 的 `VerificationStatusRecord`)
    static func seedV15Store(
        at url: URL,
        photo: Data,
        orderStatuses: [String],
        masterNames: [String]
    ) throws {
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
                        photo: photo,
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

    // MARK: Order Factory

    /// 建立測試訂單 (預設多類別／多開團／帶合併來源)
    static func makeOrder(
        id: String,
        photo: Data,
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
            photos: [photo],
            mergedSourceIDs: mergedSourceIDs
        )
    }
}
