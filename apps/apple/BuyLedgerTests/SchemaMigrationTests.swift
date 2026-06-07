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

    /// floor 版本 (V7) 的 store 開啟後，應以 lightweight 逐段遷到 V10、再以 custom 遷到 target (V11) 並保留所有既有訂單與欄位；新增欄位以 default 補齊、單選欄位映射為陣列。
    @Test func v7StoreMigratesToV11PreservingOrders() throws {
        let storeURL = Self.makeTemporaryStoreURL()
        defer { Self.removeStore(at: storeURL) }

        // 1. 以 floor 版本 V7 schema 在實體檔案寫入訂單。
        try Self.seedV7Store(at: storeURL)

        // 2. 用收斂後的 plan (target V11 + BuyLedgerMigrationPlan) 開啟同一 store。
        let migrated = try Self.fetchOrders(
            at: storeURL,
            versionedSchema: BuyLedgerSchemaV11.self,
            migrationPlan: BuyLedgerMigrationPlan.self
        )

        // 3. 既有訂單與 V7 既有欄位全數存活。
        #expect(migrated.count == 2)

        let first = try #require(migrated.first { $0.id == "BL-MIG-001" })
        #expect(first.currency == "JPY")
        #expect(first.orderSource == "蝦皮")
        #expect(first.notes == "遷移前的備註")
        #expect(first.verificationStatus == "待對帳")
        #expect(first.categories == ["美妝"])
        #expect(first.chargedAmount == 1_200)

        // V8 新增欄位 (V7 store 沒有) 由 lightweight 補 default 後，V11 再映射為空陣列 (未歸團)。
        #expect(first.campaignNames.isEmpty)
        #expect(first.paymentReceiptStatus == PaymentReceiptStatus.pending.rawValue)
        // V9 新增欄位 (V7 store 沒有) 同樣以 default 補齊。
        #expect(first.isCashOnDelivery == false)
        // V10 新增欄位 (V7 store 沒有) 以 default 空陣列補齊。
        #expect(first.photos.isEmpty)
        // V11 新增欄位一律初始化為空陣列。
        #expect(first.mergedSourceIDs.isEmpty)
    }

    /// V8 store 開啟後，應以 lightweight 逐段遷到 V10、再以 custom 遷到 target (V11)，保留 V8 欄位、新欄位以 default 補齊、單選欄位映射為陣列。
    @Test func v8StoreMigratesToV11AddingDefaults() throws {
        let storeURL = Self.makeTemporaryStoreURL()
        defer { Self.removeStore(at: storeURL) }

        // 1. 以 V8 影子型別在實體檔案落下「V8 指紋」store。
        try Self.seedV8Store(at: storeURL)

        // 2. 用收斂後的 plan (target V11) 開啟同一 store。
        let migrated = try Self.fetchOrders(
            at: storeURL,
            versionedSchema: BuyLedgerSchemaV11.self,
            migrationPlan: BuyLedgerMigrationPlan.self
        )

        // 3. V8 資料存活、新欄位以 default 補齊，單選值映射為單元素陣列。
        #expect(migrated.count == 1)
        let order = try #require(migrated.first { $0.id == "BL-V8-001" })
        #expect(order.campaignNames == ["春團"])
        #expect(order.categories == ["美妝"])
        #expect(order.paymentReceiptStatus == PaymentReceiptStatus.pending.rawValue)
        #expect(order.isCashOnDelivery == false)
        #expect(order.photos.isEmpty)
        #expect(order.mergedSourceIDs.isEmpty)
    }

    /// V9 store 開啟後，應以 lightweight 遷到 V10、再以 custom 遷到 target (V11)：既有訂單與欄位值完整保留，`photos` 以 default 空陣列補齊、單選欄位映射為陣列。
    @Test func v9StoreMigratesToV11WithEmptyPhotos() throws {
        let storeURL = Self.makeTemporaryStoreURL()
        defer { Self.removeStore(at: storeURL) }

        // 1. 以 V9 影子型別在實體檔案落下「V9 指紋」store (3 筆訂單)。
        try Self.seedV9Store(at: storeURL)

        // 2. 用收斂後的 plan (target V11) 開啟同一 store。
        let migrated = try Self.fetchOrders(
            at: storeURL,
            versionedSchema: BuyLedgerSchemaV11.self,
            migrationPlan: BuyLedgerMigrationPlan.self
        )

        // 3. 3 筆訂單與其欄位值完整保留，photos 以 default 空陣列補齊。
        #expect(migrated.count == 3)

        let first = try #require(migrated.first { $0.id == "BL-V9-001" })
        #expect(first.campaignNames == ["春團"])
        #expect(first.isCashOnDelivery == true)
        #expect(first.chargedAmount == 1_500)
        #expect(first.photos.isEmpty)

        let second = try #require(migrated.first { $0.id == "BL-V9-002" })
        #expect(second.orderSource == "Instagram")
        #expect(second.categories == ["服飾"])
        #expect(second.photos.isEmpty)

        let third = try #require(migrated.first { $0.id == "BL-V9-003" })
        #expect(third.notes == "V9 時代的備註")
        #expect(third.photos.isEmpty)
    }

    /// V10 store 開啟後，應觸發 V10 → V11 的 custom dump-and-restore：非空的 `category` / `campaignName` 映射為單元素陣列、空字串映射為空陣列、`mergedSourceIDs` 一律空陣列，其餘欄位 (含照片 data) 完整保留。
    @Test func v10StoreMigratesToV11MappingSingleValuesToLists() throws {
        let storeURL = Self.makeTemporaryStoreURL()
        defer { Self.removeStore(at: storeURL) }

        // 1. 以 V10 影子型別落下「V10 指紋」store；三筆訂單覆蓋映射表的三種組合。
        let photo = Data([0xFF, 0xD8, 0xFF, 0xE0, 0x10])
        try Self.seedV10Store(at: storeURL, photo: photo)

        // 2. 用收斂後的 plan (target V11) 開啟同一 store，觸發 custom stage。
        let migrated = try Self.fetchOrders(
            at: storeURL,
            versionedSchema: BuyLedgerSchemaV11.self,
            migrationPlan: BuyLedgerMigrationPlan.self
        )

        // 3. 映射表：(category, campaignName) → (categories, campaignNames, mergedSourceIDs)。
        #expect(migrated.count == 3)

        // ("美妝", "春團") → (["美妝"], ["春團"], [])
        let both = try #require(migrated.first { $0.id == "BL-V10-001" })
        #expect(both.categories == ["美妝"])
        #expect(both.campaignNames == ["春團"])
        #expect(both.mergedSourceIDs.isEmpty)
        #expect(both.isCashOnDelivery == true)
        #expect(both.photos == [photo])

        // ("服飾", "") → (["服飾"], [], [])
        let categoryOnly = try #require(migrated.first { $0.id == "BL-V10-002" })
        #expect(categoryOnly.categories == ["服飾"])
        #expect(categoryOnly.campaignNames.isEmpty)
        #expect(categoryOnly.mergedSourceIDs.isEmpty)

        // ("", "") → ([], [], [])
        let neither = try #require(migrated.first { $0.id == "BL-V10-003" })
        #expect(neither.categories.isEmpty)
        #expect(neither.campaignNames.isEmpty)
        #expect(neither.mergedSourceIDs.isEmpty)
    }

    /// 已在 target (V11) 的 store 重新開啟時不應觸發遷移，資料與筆數原封不動 (含陣列欄位與照片 data)。
    ///
    /// 此測試同時作為「V11 schema 指紋未被意外更動」的守門：若改動 top-level `@Model` 或 V7～V11 定義導致指紋改變，開啟既有 V11 store 會嘗試非預期的遷移或拋錯，本測試即失敗。
    @Test func v11StoreReopensWithoutMigration() throws {
        let storeURL = Self.makeTemporaryStoreURL()
        defer { Self.removeStore(at: storeURL) }

        // 1. 以 target V11 直接建立 store 並寫入一筆多類別/多開團、帶合併來源的訂單。
        let photo = Data([0xFF, 0xD8, 0xFF, 0xE0, 0x10])
        let order = LedgerOrder(
            id: "BL-V11-001",
            customer: LedgerCustomer(name: "原生 V11", initials: "VX", tier: .regular),
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
            verificationStatus: "",
            campaignNames: ["春團", "夏團"],
            paymentReceiptStatus: .pending,
            isCashOnDelivery: true,
            photos: [photo],
            mergedSourceIDs: ["BL-SRC-001", "BL-SRC-002"]
        )
        do {
            let container = try Self.makeContainer(
                versionedSchema: BuyLedgerSchemaV11.self,
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
            versionedSchema: BuyLedgerSchemaV11.self,
            migrationPlan: BuyLedgerMigrationPlan.self
        )

        // 3. 已在 target 的 store 不觸發遷移，資料原封不動 (含陣列欄位與照片 data)。
        #expect(reopened.count == 1)
        #expect(reopened.first?.id == "BL-V11-001")
        #expect(reopened.first?.categories == ["美妝", "服飾"])
        #expect(reopened.first?.campaignNames == ["春團", "夏團"])
        #expect(reopened.first?.mergedSourceIDs == ["BL-SRC-001", "BL-SRC-002"])
        #expect(reopened.first?.isCashOnDelivery == true)
        #expect(reopened.first?.photos == [photo])
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

    /// 以 V8 影子 ``BuyLedgerSchemaV8/OrderRecord`` 在實體 store 寫入一筆訂單，落下「V8 指紋」store 供 V8 → V10 遷移測試。
    ///
    /// 直接使用 ``BuyLedgerSchemaV8/OrderRecord`` (而非 top-level 型別) 才能落下不含 `isCashOnDelivery` 的 V8 指紋；top-level ``OrderRecord`` 已是 V10 (含 `photos`)。
    static func seedV8Store(at url: URL) throws {
        let container = try makeContainer(
            versionedSchema: BuyLedgerSchemaV8.self,
            migrationPlan: nil,
            url: url
        )
        let context = ModelContext(container)

        context.insert(
            BuyLedgerSchemaV8.OrderRecord(
                id: "BL-V8-001",
                customer: LedgerCustomer(name: "原生 V8", initials: "V8", tier: .regular),
                status: .confirmed,
                currency: "TWD",
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
                paymentReceiptStatus: PaymentReceiptStatus.pending.rawValue
            )
        )
        try context.save()
    }

    /// 以 V10 影子 ``BuyLedgerSchemaV10/OrderRecord`` 在實體 store 寫入三筆訂單，落下「V10 指紋」store 供 V10 → V11 custom 遷移測試；三筆覆蓋 (category, campaignName) 映射表的三種組合。
    /// - Parameters:
    ///   - url: store 位置。
    ///   - photo: 第一筆訂單要附上的照片 data，用於驗證 dump-and-restore 不掉資料。
    static func seedV10Store(at url: URL, photo: Data) throws {
        let container = try makeContainer(
            versionedSchema: BuyLedgerSchemaV10.self,
            migrationPlan: nil,
            url: url
        )
        let context = ModelContext(container)

        context.insert(
            BuyLedgerSchemaV10.OrderRecord(
                id: "BL-V10-001",
                customer: LedgerCustomer(name: "原生 V10", initials: "VX", tier: .regular),
                status: .confirmed,
                currency: "TWD",
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
                category: "美妝",
                paymentMethod: "貨到付款",
                notes: "",
                verificationStatus: "",
                campaignName: "春團",
                paymentReceiptStatus: PaymentReceiptStatus.pending.rawValue,
                isCashOnDelivery: true,
                photos: [photo]
            )
        )
        context.insert(
            BuyLedgerSchemaV10.OrderRecord(
                id: "BL-V10-002",
                customer: LedgerCustomer(name: "原生 V10 二", initials: "X2", tier: .vip),
                status: .shipping,
                currency: "KRW",
                date: Date(timeIntervalSince1970: 1_700_100_000),
                items: [],
                itemCost: 800,
                domesticShipping: 0,
                internationalShipping: 0,
                foreignDomesticShipping: 0,
                cardFeeRate: 0,
                platformFeeRate: 0,
                paymentFeeRate: 0,
                chargedAmount: 990,
                cardlessDeductionAmount: 0,
                cardlessSupplementAmount: 0,
                orderSource: "Instagram",
                category: "服飾",
                paymentMethod: "信用卡",
                notes: "",
                verificationStatus: "",
                campaignName: ""
            )
        )
        context.insert(
            BuyLedgerSchemaV10.OrderRecord(
                id: "BL-V10-003",
                customer: LedgerCustomer(name: "原生 V10 三", initials: "X3", tier: .new),
                status: .quoting,
                currency: "JPY",
                date: Date(timeIntervalSince1970: 1_700_200_000),
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
                category: "",
                paymentMethod: "",
                notes: "",
                verificationStatus: "",
                campaignName: ""
            )
        )
        try context.save()
    }

    /// 以 V9 影子 ``BuyLedgerSchemaV9/OrderRecord`` 在實體 store 寫入三筆訂單，落下「V9 指紋」store 供 V9 → V10 遷移測試。
    ///
    /// 直接使用 ``BuyLedgerSchemaV9/OrderRecord`` (而非 top-level 型別) 才能落下不含 `photos` 的 V9 指紋；top-level ``OrderRecord`` 已是 V10 (含該欄位)。
    static func seedV9Store(at url: URL) throws {
        let container = try makeContainer(
            versionedSchema: BuyLedgerSchemaV9.self,
            migrationPlan: nil,
            url: url
        )
        let context = ModelContext(container)

        context.insert(
            BuyLedgerSchemaV9.OrderRecord(
                id: "BL-V9-001",
                customer: LedgerCustomer(name: "原生 V9", initials: "V9", tier: .regular),
                status: .confirmed,
                currency: "TWD",
                date: Date(timeIntervalSince1970: 1_700_000_000),
                items: [],
                itemCost: 0,
                domesticShipping: 100,
                internationalShipping: 200,
                foreignDomesticShipping: 0,
                cardFeeRate: 0,
                platformFeeRate: 0,
                paymentFeeRate: 0,
                chargedAmount: 1_500,
                cardlessDeductionAmount: 0,
                cardlessSupplementAmount: 0,
                orderSource: "蝦皮",
                category: "美妝",
                paymentMethod: "貨到付款",
                notes: "",
                verificationStatus: "",
                campaignName: "春團",
                paymentReceiptStatus: PaymentReceiptStatus.pending.rawValue,
                isCashOnDelivery: true
            )
        )
        context.insert(
            BuyLedgerSchemaV9.OrderRecord(
                id: "BL-V9-002",
                customer: LedgerCustomer(name: "原生 V9 二", initials: "92", tier: .vip),
                status: .shipping,
                currency: "KRW",
                date: Date(timeIntervalSince1970: 1_700_100_000),
                items: [],
                itemCost: 800,
                domesticShipping: 0,
                internationalShipping: 0,
                foreignDomesticShipping: 0,
                cardFeeRate: 0,
                platformFeeRate: 0,
                paymentFeeRate: 0,
                chargedAmount: 990,
                cardlessDeductionAmount: 0,
                cardlessSupplementAmount: 0,
                orderSource: "Instagram",
                category: "服飾",
                paymentMethod: "信用卡",
                notes: "",
                verificationStatus: ""
            )
        )
        context.insert(
            BuyLedgerSchemaV9.OrderRecord(
                id: "BL-V9-003",
                customer: LedgerCustomer(name: "原生 V9 三", initials: "93", tier: .new),
                status: .delivered,
                currency: "JPY",
                date: Date(timeIntervalSince1970: 1_700_200_000),
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
                notes: "V9 時代的備註",
                verificationStatus: ""
            )
        )
        try context.save()
    }
}
