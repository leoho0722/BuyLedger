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

/// 驗證收斂後的 ``BuyLedgerMigrationPlan`` 在 on-disk store 上的遷移行為。
///
/// 與其他 persistence 測試刻意不同：這裡使用「實體檔案」store 而非 in-memory。SwiftData 的 migration 只在開啟既有 store、且其 schema 指紋與 target 有 delta 時才會執行；in-memory 永遠是全新的 target store，無法行經遷移路徑，因此無法守住砍檔 fallback 與指紋穩定性。
@MainActor
struct SchemaMigrationTests {

    // MARK: - Tests

    /// floor 版本 (V7) 的 store 開啟後，應以 lightweight migration 遷到 V8 並保留所有既有訂單與欄位；V8 新增欄位以 default 補齊。
    @Test func v7StoreMigratesToV8PreservingOrders() throws {
        let storeURL = Self.makeTemporaryStoreURL()
        defer { Self.removeStore(at: storeURL) }

        // 1. 以 floor 版本 V7 schema 在實體檔案寫入訂單。
        try Self.seedV7Store(at: storeURL)

        // 2. 用收斂後的 plan (target V8 + BuyLedgerMigrationPlan) 開啟同一 store。
        let migrated = try Self.fetchOrders(
            at: storeURL,
            versionedSchema: BuyLedgerSchemaV8.self,
            migrationPlan: BuyLedgerMigrationPlan.self
        )

        // 3. 既有訂單與 V7 既有欄位全數存活。
        #expect(migrated.count == 2)

        let first = try #require(migrated.first { $0.id == "BL-MIG-001" })
        #expect(first.currency == "JPY")
        #expect(first.orderSource == "蝦皮")
        #expect(first.notes == "遷移前的備註")
        #expect(first.verificationStatus == "待對帳")
        #expect(first.category == "美妝")
        #expect(first.chargedAmount == 1_200)

        // V8 新增欄位 (V7 store 沒有) 應由 lightweight migration 以 default 補齊。
        #expect(first.campaignName == "")
        #expect(first.paymentReceiptStatus == PaymentReceiptStatus.pending.rawValue)
    }

    /// 已在 target (V8) 的 store 重新開啟時不應觸發遷移，資料與筆數原封不動。
    ///
    /// 此測試同時作為「V8 schema 指紋未被意外更動」的守門：若移除 V1~V6 時誤動了 top-level `@Model` 或 V7／V8 定義導致指紋改變，開啟既有 V8 store 會嘗試非預期的遷移或拋錯，本測試即失敗。
    @Test func v8StoreReopensWithoutMigration() throws {
        let storeURL = Self.makeTemporaryStoreURL()
        defer { Self.removeStore(at: storeURL) }

        // 1. 以 target V8 直接建立 store 並寫入一筆帶有 V8 專屬欄位的訂單。
        let order = LedgerOrder(
            id: "BL-V8-001",
            customer: LedgerCustomer(name: "原生 V8", initials: "V8", tier: .regular),
            status: .confirmed,
            currency: .twd,
            date: Date(timeIntervalSince1970: 1_700_000_000),
            items: [],
            itemCost: 0,
            domesticShipping: 0,
            internationalShipping: 0,
            foreignDomesticShipping: 0,
            cardFeeRate: 0,
            platformFeeRate: 0,
            paymentFeeRate: 0,
            chargedAmount: 0,
            cardlessDeductionAmount: 0,
            cardlessSupplementAmount: 0,
            orderSource: "蝦皮",
            category: "美妝",
            paymentMethod: "",
            notes: "",
            verificationStatus: "",
            campaignName: "春團",
            paymentReceiptStatus: .pending
        )
        do {
            let container = try Self.makeContainer(
                versionedSchema: BuyLedgerSchemaV8.self,
                migrationPlan: nil,
                url: storeURL
            )
            let context = ModelContext(container)
            context.insert(OrderRecord(order: order))
            try context.save()
        }

        // 2. 用收斂後的 plan 重新開啟同一 store。
        let reopened = try Self.fetchOrders(
            at: storeURL,
            versionedSchema: BuyLedgerSchemaV8.self,
            migrationPlan: BuyLedgerMigrationPlan.self
        )

        // 3. 已在 target 的 store 不觸發遷移，資料原封不動。
        #expect(reopened.count == 1)
        #expect(reopened.first?.id == "BL-V8-001")
        #expect(reopened.first?.campaignName == "春團")
    }
}

// MARK: - Helpers

private extension SchemaMigrationTests {

    // MARK: Store URL

    /// 建立每個測試獨立、不污染 production store 的 on-disk store URL。
    static func makeTemporaryStoreURL() -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("BuyLedgerMigrationTests", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("\(UUID().uuidString).store")
    }

    /// 清除 store 主檔與其 sidecar (`-wal` / `-shm`)。
    static func removeStore(at url: URL) {
        let fileManager = FileManager.default
        for suffix in ["", "-wal", "-shm"] {
            let candidate = URL(fileURLWithPath: url.path + suffix)
            try? fileManager.removeItem(at: candidate)
        }
    }

    // MARK: Container

    /// 以指定版本 schema、migration plan 與實體 URL 建立 ``ModelContainer``；明確關閉 CloudKit 以維持純本機行為。
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

    /// 以指定 schema／plan 開啟 store 並讀回全部 ``OrderRecord``。
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

    // MARK: Seeding

    /// 以 floor 版本 V7 的影子 ``OrderRecord`` 在實體 store 寫入兩筆訂單。
    ///
    /// 直接使用 ``BuyLedgerSchemaV7/OrderRecord`` (而非 top-level 型別) 才能在檔案落下「V7 指紋」的 store，供之後以 plan 開啟時觸發 V7 → V8 遷移。
    static func seedV7Store(at url: URL) throws {
        let container = try makeContainer(
            versionedSchema: BuyLedgerSchemaV7.self,
            migrationPlan: nil,
            url: url
        )
        let context = ModelContext(container)

        context.insert(
            BuyLedgerSchemaV7.OrderRecord(
                id: "BL-MIG-001",
                customer: LedgerCustomer(name: "遷移客戶", initials: "MG", tier: .regular),
                status: .confirmed,
                currency: "JPY",
                date: Date(timeIntervalSince1970: 1_700_000_000),
                items: [],
                itemCost: 1_000,
                domesticShipping: 0,
                internationalShipping: 0,
                foreignDomesticShipping: 0,
                cardFeeRate: 0,
                platformFeeRate: 0,
                paymentFeeRate: 0,
                chargedAmount: 1_200,
                cardlessDeductionAmount: 0,
                cardlessSupplementAmount: 0,
                orderSource: "蝦皮",
                category: "美妝",
                paymentMethod: "信用卡",
                notes: "遷移前的備註",
                verificationStatus: "待對帳"
            )
        )
        context.insert(
            BuyLedgerSchemaV7.OrderRecord(
                id: "BL-MIG-002",
                customer: LedgerCustomer(name: "遷移客戶二", initials: "M2", tier: .vip),
                status: .delivered,
                currency: "TWD",
                date: Date(timeIntervalSince1970: 1_700_100_000),
                items: [],
                itemCost: 0,
                domesticShipping: 0,
                internationalShipping: 0,
                foreignDomesticShipping: 0,
                cardFeeRate: 0,
                platformFeeRate: 0,
                paymentFeeRate: 0,
                chargedAmount: 0,
                cardlessDeductionAmount: 0,
                cardlessSupplementAmount: 0,
                orderSource: "",
                category: "雜貨",
                paymentMethod: "",
                notes: "",
                verificationStatus: ""
            )
        )
        try context.save()
    }
}
