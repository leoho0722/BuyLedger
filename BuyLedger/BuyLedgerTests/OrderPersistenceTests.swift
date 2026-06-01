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
            category: "美妝",
            paymentMethod: "",
            notes: "建立時的備註",
            verificationStatus: "",
            campaignName: "",
            paymentReceiptStatus: .pending,
            isCashOnDelivery: false
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
            category: original.category,
            paymentMethod: original.paymentMethod,
            notes: "更新後的備註",
            verificationStatus: "",
            campaignName: "",
            paymentReceiptStatus: .pending,
            isCashOnDelivery: false
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
            category: "美妝",
            paymentMethod: "銀行匯款",
            notes: "",
            verificationStatus: "待對帳",
            campaignName: "",
            paymentReceiptStatus: .pending,
            isCashOnDelivery: false
        )

        try await persistence.upsert(order)

        let stored = try await persistence.fetchAll()
        #expect(stored.first?.verificationStatus == "待對帳", "對帳狀態應隨訂單一併 round-trip")
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
            category: "美妝",
            paymentMethod: "銀行匯款",
            notes: "",
            verificationStatus: "待對帳",
            campaignName: "",
            paymentReceiptStatus: .pending,
            isCashOnDelivery: false
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
}

// MARK: - Helpers

private extension OrderPersistenceTests {

    /// 用 in-memory 的 ``ModelContainer`` 建立每個測試獨立的 ``OrderPersistence``。
    /// - Returns: 不污染 production store 的測試 actor。
    func makePersistence() throws -> OrderPersistence {
        let container = try PersistenceContainer.make(inMemoryOnly: true)
        return OrderPersistence(modelContainer: container)
    }
}
