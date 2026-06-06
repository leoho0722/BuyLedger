//
//  OrderPersistenceTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/5/2.
//

import Foundation
import SwiftData
import Testing
@testable import BuyLedger

@MainActor
struct OrderPersistenceTests {

    // MARK: - Tests

    @Test func fetchAllOnFreshContainerReturnsEmpty() async throws {
        let persistence = try makePersistence()

        let stored = try await persistence.fetchAll()
        #expect(stored.isEmpty)
    }

    @Test func seedIfEmptyInsertsSamplesOnce() async throws {
        let persistence = try makePersistence()
        let samples = LedgerOrder.sampleOrders

        let firstSeeded = try await persistence.seedIfEmpty(with: samples)
        #expect(firstSeeded == true)

        let afterFirst = try await persistence.fetchAll()
        #expect(afterFirst.count == samples.count)

        let secondSeeded = try await persistence.seedIfEmpty(with: samples)
        #expect(secondSeeded == false, "若資料表已非空，再次 seed 不應重複寫入")

        let afterSecond = try await persistence.fetchAll()
        #expect(afterSecond.count == samples.count)
    }

    @Test func fetchAllReturnsOrdersSortedByDateDescending() async throws {
        let persistence = try makePersistence()
        let samples = LedgerOrder.sampleOrders
        try await persistence.seedIfEmpty(with: samples)

        let fetched = try await persistence.fetchAll()

        let dates = fetched.map(\.date)
        let sorted = dates.sorted(by: >)
        #expect(dates == sorted)
    }

    @Test func upsertInsertsNewOrderWhenIdNotPresent() async throws {
        let persistence = try makePersistence()

        let order = LedgerOrder(
            id: "BL-TEST-001",
            customer: LedgerCustomer(name: "測試客戶", initials: "TC", tier: .new),
            status: .quoting,
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
            categories: ["美妝"],
            paymentMethod: "",
            notes: "建立時的備註",
            verificationStatus: "",
            campaignNames: [],
            paymentReceiptStatus: .pending,
            isCashOnDelivery: false,
            photos: [],
            mergedSourceIDs: []
        )

        try await persistence.upsert(order)

        let stored = try await persistence.fetchAll()
        #expect(stored.count == 1)
        #expect(stored.first?.id == "BL-TEST-001")
        #expect(stored.first?.customer.name == "測試客戶")
        #expect(stored.first?.notes == "建立時的備註", "備註應隨訂單一併持久化")
    }

    @Test func upsertUpdatesExistingOrderWithSameId() async throws {
        let persistence = try makePersistence()
        let original = LedgerOrder.sampleOrders[0]
        try await persistence.upsert(original)

        var modifiedCustomer = original.customer
        modifiedCustomer = LedgerCustomer(name: "改名後", initials: "RN", tier: .vip)
        let modified = LedgerOrder(
            id: original.id,
            customer: modifiedCustomer,
            status: .delivered,
            currency: original.currency,
            date: original.date,
            items: original.items,
            itemCost: original.itemCost,
            domesticShipping: original.domesticShipping,
            internationalShipping: original.internationalShipping,
            foreignDomesticShipping: 0,
            cardFeeRate: original.cardFeeRate,
            platformFeeRate: original.platformFeeRate,
            paymentFeeRate: 0,
            chargedAmount: 9_999,
            cardlessDeductionAmount: 0,
            cardlessSupplementAmount: 0,
            orderSource: original.orderSource,
            categories: original.categories,
            paymentMethod: original.paymentMethod,
            notes: "更新後的備註",
            verificationStatus: "",
            campaignNames: [],
            paymentReceiptStatus: .pending,
            isCashOnDelivery: false,
            photos: [],
            mergedSourceIDs: []
        )

        try await persistence.upsert(modified)

        let stored = try await persistence.fetchAll()
        #expect(stored.count == 1, "upsert 不應因為 id 相同而新增重複資料")
        #expect(stored.first?.customer.name == "改名後")
        #expect(stored.first?.status == .delivered)
        #expect(stored.first?.chargedAmount == 9_999)
        #expect(stored.first?.notes == "更新後的備註", "更新訂單時備註應一併寫回")
    }

    @Test func upsertPersistsVerificationStatusRoundTrip() async throws {
        let persistence = try makePersistence()

        let order = LedgerOrder(
            id: "BL-TEST-VS",
            customer: LedgerCustomer(name: "對帳測試", initials: "VS", tier: .regular),
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
            categories: ["美妝"],
            paymentMethod: "銀行匯款",
            notes: "",
            verificationStatus: "待對帳",
            campaignNames: [],
            paymentReceiptStatus: .pending,
            isCashOnDelivery: false,
            photos: [],
            mergedSourceIDs: []
        )

        try await persistence.upsert(order)

        let stored = try await persistence.fetchAll()
        #expect(stored.first?.verificationStatus == "待對帳", "對帳狀態應隨訂單一併 round-trip")
    }

    @Test func upsertPersistsPhotosRoundTrip() async throws {
        let persistence = try makePersistence()

        let photoA = Data([0xFF, 0xD8, 0xFF, 0xE0, 0x01])
        let photoB = Data([0xFF, 0xD8, 0xFF, 0xE0, 0x02])
        let order = LedgerOrder(
            id: "BL-TEST-PHOTO",
            customer: LedgerCustomer(name: "照片測試", initials: "PH", tier: .regular),
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
            categories: ["美妝"],
            paymentMethod: "",
            notes: "",
            verificationStatus: "",
            campaignNames: [],
            paymentReceiptStatus: .pending,
            isCashOnDelivery: false,
            photos: [photoA, photoB],
            mergedSourceIDs: []
        )

        try await persistence.upsert(order)

        let inserted = try await persistence.fetchAll()
        #expect(inserted.first?.photos == [photoA, photoB], "照片應隨訂單一併 round-trip 且 byte 級不變")

        let photoC = Data([0xFF, 0xD8, 0xFF, 0xE0, 0x03])
        let modified = LedgerOrder(
            id: order.id,
            customer: order.customer,
            status: order.status,
            currency: order.currency,
            date: order.date,
            items: order.items,
            itemCost: order.itemCost,
            domesticShipping: order.domesticShipping,
            internationalShipping: order.internationalShipping,
            foreignDomesticShipping: order.foreignDomesticShipping,
            cardFeeRate: order.cardFeeRate,
            platformFeeRate: order.platformFeeRate,
            paymentFeeRate: order.paymentFeeRate,
            chargedAmount: order.chargedAmount,
            cardlessDeductionAmount: order.cardlessDeductionAmount,
            cardlessSupplementAmount: order.cardlessSupplementAmount,
            orderSource: order.orderSource,
            categories: order.categories,
            paymentMethod: order.paymentMethod,
            notes: order.notes,
            verificationStatus: order.verificationStatus,
            campaignNames: order.campaignNames,
            paymentReceiptStatus: order.paymentReceiptStatus,
            isCashOnDelivery: order.isCashOnDelivery,
            photos: [photoC],
            mergedSourceIDs: []
        )

        try await persistence.upsert(modified)

        let updated = try await persistence.fetchAll()
        #expect(updated.count == 1, "同 id upsert 不應新增重複資料")
        #expect(updated.first?.photos == [photoC], "更新訂單時照片應一併覆寫")
    }

    @Test func renameVerificationStatusUpdatesMatchingOrders() async throws {
        let persistence = try makePersistence()
        let order = LedgerOrder(
            id: "BL-TEST-VS-RENAME",
            customer: LedgerCustomer(name: "對帳測試", initials: "VS", tier: .regular),
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
            categories: ["美妝"],
            paymentMethod: "銀行匯款",
            notes: "",
            verificationStatus: "待對帳",
            campaignNames: [],
            paymentReceiptStatus: .pending,
            isCashOnDelivery: false,
            photos: [],
            mergedSourceIDs: []
        )
        try await persistence.upsert(order)

        try await persistence.renameVerificationStatus(from: "待對帳", to: "對帳成功")

        let stored = try await persistence.fetchAll()
        #expect(stored.first?.verificationStatus == "對帳成功", "cascade 更名應更新引用該對帳狀態的訂單")
    }

    @Test func deleteRemovesOrderById() async throws {
        let persistence = try makePersistence()
        let samples = LedgerOrder.sampleOrders
        try await persistence.seedIfEmpty(with: samples)

        let removeID = samples[0].id
        try await persistence.delete(id: removeID)

        let stored = try await persistence.fetchAll()
        #expect(stored.count == samples.count - 1)
        #expect(!stored.contains(where: { $0.id == removeID }))
    }

    @Test func deleteUnknownIdIsNoOp() async throws {
        let persistence = try makePersistence()
        try await persistence.seedIfEmpty(with: LedgerOrder.sampleOrders)

        try await persistence.delete(id: "BL-DOES-NOT-EXIST")

        let stored = try await persistence.fetchAll()
        #expect(stored.count == LedgerOrder.sampleOrders.count)
    }

    @Test func mergeOrdersInsertsNewAndMarksSourcesMergedInOneOperation() async throws {
        // 取兩筆同客戶同幣別的樣本作來源 (林書宇, KRW)。
        let persistence = try makePersistence()
        let samples = LedgerOrder.sampleOrders
        try await persistence.seedIfEmpty(with: samples)

        let primaryID = "BL-2604-018"
        let secondaryID = "BL-2604-012"
        let primary = samples.first { $0.id == primaryID }!
        let secondary = samples.first { $0.id == secondaryID }!

        // 以純函式計算合併草稿後組出新訂單。
        let draft = OrderMerge.makeDraft(
            primary: primary,
            secondary: secondary,
            now: Date(timeIntervalSince1970: 1_777_000_000),
            isCardless: { _ in false }
        )
        let merged = LedgerOrder(
            id: "BL-MERGED-001",
            customer: draft.customer,
            status: draft.status,
            currency: draft.currency,
            date: draft.date,
            items: draft.items,
            itemCost: draft.itemCost,
            domesticShipping: draft.domesticShipping,
            internationalShipping: draft.internationalShipping,
            foreignDomesticShipping: draft.foreignDomesticShipping,
            cardFeeRate: draft.cardFeeRate,
            platformFeeRate: draft.platformFeeRate,
            paymentFeeRate: draft.paymentFeeRate,
            chargedAmount: draft.chargedAmount,
            cardlessDeductionAmount: draft.cardlessDeductionAmount,
            cardlessSupplementAmount: draft.cardlessSupplementAmount,
            orderSource: draft.orderSource,
            categories: draft.categories,
            paymentMethod: draft.paymentMethod,
            notes: draft.notes,
            verificationStatus: draft.verificationStatus,
            campaignNames: draft.campaignNames,
            paymentReceiptStatus: draft.paymentReceiptStatus,
            isCashOnDelivery: draft.isCashOnDelivery,
            photos: draft.photos,
            mergedSourceIDs: draft.mergeSourceIDs
        )

        try await persistence.mergeOrders(newOrder: merged, consumedIDs: [primaryID, secondaryID])

        let stored = try await persistence.fetchAll()

        // 新訂單存在且記錄兩筆來源 id。
        let storedMerged = stored.first { $0.id == "BL-MERGED-001" }
        #expect(storedMerged != nil)
        #expect(storedMerged?.mergedSourceIDs == [primaryID, secondaryID])
        #expect(storedMerged?.categories == ["美妝", "服飾"])
        #expect(storedMerged?.chargedAmount == 17_480)

        // 兩筆來源訂單同一操作內轉「已合併」，其餘訂單不受影響。
        #expect(stored.first { $0.id == primaryID }?.status == .merged)
        #expect(stored.first { $0.id == secondaryID }?.status == .merged)
        #expect(stored.count == samples.count + 1)
        let untouched = stored.filter { ![primaryID, secondaryID, "BL-MERGED-001"].contains($0.id) }
        #expect(untouched.allSatisfy { $0.status != .merged })
    }

    @Test func renameCategoryRewritesElementsInsideArrays() async throws {
        // 多類別訂單僅目標元素改名 (保序)；未含目標的訂單不受影響。
        let persistence = try makePersistence()
        try await persistence.upsert(Self.makeArrayOrder(id: "BL-CAT-1", categories: ["美妝", "服飾"]))
        try await persistence.upsert(Self.makeArrayOrder(id: "BL-CAT-2", categories: ["服飾"]))

        try await persistence.renameCategory(from: "美妝", to: "彩妝保養")

        let stored = try await persistence.fetchAll()
        #expect(stored.first { $0.id == "BL-CAT-1" }?.categories == ["彩妝保養", "服飾"])
        #expect(stored.first { $0.id == "BL-CAT-2" }?.categories == ["服飾"])
    }

    @Test func renameCampaignRewritesElementsInsideArrays() async throws {
        // 多開團訂單僅目標元素改名 (保序)。
        let persistence = try makePersistence()
        try await persistence.upsert(Self.makeArrayOrder(id: "BL-CAMP-1", categories: ["美妝"], campaignNames: ["三月日本團", "四月韓國團"]))
        try await persistence.upsert(Self.makeArrayOrder(id: "BL-CAMP-2", categories: ["美妝"], campaignNames: []))

        try await persistence.renameCampaign(from: "三月日本團", to: "三月日本團 (補)")

        let stored = try await persistence.fetchAll()
        #expect(stored.first { $0.id == "BL-CAMP-1" }?.campaignNames == ["三月日本團 (補)", "四月韓國團"])
        #expect(stored.first { $0.id == "BL-CAMP-2" }?.campaignNames == [])
    }
}

// MARK: - Helpers

private extension OrderPersistenceTests {

    /// 用 in-memory 的 ``ModelContainer`` 建立每個測試獨立的 ``OrderPersistence``。
    /// - Returns: 不污染 production store 的測試 actor。
    func makePersistence() throws -> OrderPersistence {
        let container = try PersistenceContainer.make(inMemoryOnly: true)
        return OrderPersistence(modelContainer: container)
    }

    /// 建立陣列 rename 測試用的最小訂單。
    static func makeArrayOrder(
        id: String,
        categories: [String],
        campaignNames: [String] = []
    ) -> LedgerOrder {
        LedgerOrder(
            id: id,
            customer: LedgerCustomer(name: "客戶", initials: "XX", tier: .regular),
            status: .confirmed,
            currency: .twd,
            date: Date(timeIntervalSince1970: 1_770_000_000),
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
            categories: categories,
            paymentMethod: "信用卡",
            notes: "",
            verificationStatus: "",
            campaignNames: campaignNames,
            paymentReceiptStatus: .pending,
            isCashOnDelivery: false,
            photos: [],
            mergedSourceIDs: []
        )
    }
}
