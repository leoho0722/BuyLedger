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

/// 驗證收斂後的 ``BuyLedgerMigrationPlan`` (floor V13) 在 on-disk store 上的遷移行為
///
/// 與其他 persistence 測試刻意不同：這裡使用「實體檔案」store 而非 in-memory。SwiftData 的 migration 只在開啟既有 store、且其 schema 指紋與 target 有 delta 時才會執行；in-memory 永遠是全新的 target store，無法行經遷移路徑，因此無法守住砍檔 fallback 與指紋穩定性
@MainActor
struct SchemaMigrationTests {

    // MARK: - Tests

    /// V13 (floor) store 開啟後，應以 lightweight (V13 → V14 → V15) 逐段遷到 target：``OrderRecord`` 資料原封不動；``CampaignReminderRecord`` 保留 `campaignID` / `eventIdentifier`，新欄位 `reminderTimestamp` 帶預設值 (中間版本的 `minuteOfDay` 已於 lightweight 汰換)
    @Test func v13StoreMigratesToV15() throws {
        let storeURL = Self.makeTemporaryStoreURL()
        defer { Self.removeStore(at: storeURL) }

        // 1. 以 V13 schema 落下「V13 指紋」store：一筆訂單 + 一筆 V13 形狀的提醒連結
        let photo = Data([0xFF, 0xD8, 0xFF, 0xE0, 0x10])
        try Self.seedV13Store(at: storeURL, photo: photo)

        // 2. 用收斂後的 plan (target V15) 開啟同一 store，觸發 V13 → V14 → V15 lightweight
        let migrated = try Self.fetchOrders(
            at: storeURL,
            versionedSchema: BuyLedgerSchemaV15.self,
            migrationPlan: BuyLedgerMigrationPlan.self
        )

        // 3. OrderRecord 完整保留
        #expect(migrated.count == 1)
        let order = try #require(migrated.first)
        #expect(order.id == "BL-V13-001")
        #expect(order.categories == ["美妝"])
        #expect(order.campaignNames == ["春團"])
        #expect(order.mergedSourceIDs == ["BL-SRC-001"])
        #expect(order.photos == [photo])

        // 4. CampaignReminderRecord 遷到 V15：campaignID / eventIdentifier 保留、reminderTimestamp 為預設 epoch
        let reminders = try Self.fetchReminders(
            at: storeURL,
            versionedSchema: BuyLedgerSchemaV15.self,
            migrationPlan: BuyLedgerMigrationPlan.self
        )
        #expect(reminders.count == 1)
        #expect(reminders.first?.campaignID == "CMP-1")
        #expect(reminders.first?.eventIdentifier == "EVT-1")
        #expect(reminders.first?.reminderTimestamp == Date(timeIntervalSince1970: 0))
    }

    /// V15 store 以 V15 schema 重新開啟時不應觸發遷移，資料與筆數原封不動
    ///
    /// 此測試同時作為「V15 schema 指紋未被意外更動」的守門：若改動 top-level `@Model` 或 V13～V15 定義導致指紋改變，開啟既有 V15 store 會嘗試非預期的遷移或拋錯，本測試即失敗
    @Test func v15StoreReopensWithoutMigration() throws {
        let storeURL = Self.makeTemporaryStoreURL()
        defer { Self.removeStore(at: storeURL) }

        // 1. 以 target V15 直接建立 store 並寫入一筆多類別/多開團、帶合併來源的訂單
        let photo = Data([0xFF, 0xD8, 0xFF, 0xE0, 0x10])
        do {
            let container = try Self.makeContainer(
                versionedSchema: BuyLedgerSchemaV15.self,
                migrationPlan: nil,
                url: storeURL
            )
            let context = ModelContext(container)
            context.insert(OrderRecord(order: Self.makeOrder(id: "BL-V15-001", photo: photo)))
            try context.save()
        }

        // 2. 用收斂後的 plan 重新開啟同一 store
        let reopened = try Self.fetchOrders(
            at: storeURL,
            versionedSchema: BuyLedgerSchemaV15.self,
            migrationPlan: BuyLedgerMigrationPlan.self
        )

        // 3. 已在 target 的 store 不觸發遷移，資料原封不動 (含陣列欄位與照片 data)
        #expect(reopened.count == 1)
        #expect(reopened.first?.id == "BL-V15-001")
        #expect(reopened.first?.categories == ["美妝", "服飾"])
        #expect(reopened.first?.campaignNames == ["春團", "夏團"])
        #expect(reopened.first?.mergedSourceIDs == ["BL-SRC-001", "BL-SRC-002"])
        #expect(reopened.first?.photos == [photo])
    }
}

// MARK: - Helpers

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

    /// 以指定 schema／plan 開啟 store 並讀回全部 ``CampaignReminderRecord``
    static func fetchReminders(
        at url: URL,
        versionedSchema: any VersionedSchema.Type,
        migrationPlan: (any SchemaMigrationPlan.Type)?
    ) throws -> [CampaignReminderRecord] {
        let container = try makeContainer(
            versionedSchema: versionedSchema,
            migrationPlan: migrationPlan,
            url: url
        )
        let context = ModelContext(container)

        return try context.fetch(FetchDescriptor<CampaignReminderRecord>())
    }

    // MARK: Seeding

    /// 以 V13 schema 在實體 store 寫入一筆訂單與一筆 V13 形狀的提醒連結，落下「V13 指紋」store 供 V13 → V15 遷移測試
    /// - Parameters:
    ///   - url: store 位置
    ///   - photo: 訂單要附上的照片 data，用於驗證遷移不掉資料
    static func seedV13Store(at url: URL, photo: Data) throws {
        let container = try makeContainer(
            versionedSchema: BuyLedgerSchemaV13.self,
            migrationPlan: nil,
            url: url
        )
        let context = ModelContext(container)

        context.insert(
            OrderRecord(
                order: makeOrder(
                    id: "BL-V13-001",
                    photo: photo,
                    categories: ["美妝"],
                    campaignNames: ["春團"],
                    mergedSourceIDs: ["BL-SRC-001"]
                )
            )
        )
        context.insert(BuyLedgerSchemaV13.CampaignReminderRecord(campaignID: "CMP-1", eventIdentifier: "EVT-1"))
        try context.save()
    }

    // MARK: Order Factory

    /// 建立測試訂單 (預設多類別／多開團／帶合併來源)
    static func makeOrder(
        id: String,
        photo: Data,
        categories: [String] = ["美妝", "服飾"],
        campaignNames: [String] = ["春團", "夏團"],
        mergedSourceIDs: [String] = ["BL-SRC-001", "BL-SRC-002"]
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
            verificationStatus: "",
            campaignNames: campaignNames,
            paymentReceiptStatus: .pending,
            isCashOnDelivery: true,
            photos: [photo],
            mergedSourceIDs: mergedSourceIDs
        )
    }
}
