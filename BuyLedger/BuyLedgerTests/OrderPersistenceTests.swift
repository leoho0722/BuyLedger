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
            cardFeeRate: 0,
            platformFeeRate: 0,
            chargedAmount: 0,
            category: "美妝",
            paymentMethod: ""
        )

        try await persistence.upsert(order)
        
        let stored = try await persistence.fetchAll()
        #expect(stored.count == 1)
        #expect(stored.first?.id == "BL-TEST-001")
        #expect(stored.first?.customer.name == "測試客戶")
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
            cardFeeRate: original.cardFeeRate,
            platformFeeRate: original.platformFeeRate,
            chargedAmount: 9_999,
            category: original.category,
            paymentMethod: original.paymentMethod
        )
        
        try await persistence.upsert(modified)
        
        let stored = try await persistence.fetchAll()
        #expect(stored.count == 1, "upsert 不應因為 id 相同而新增重複資料")
        #expect(stored.first?.customer.name == "改名後")
        #expect(stored.first?.status == .delivered)
        #expect(stored.first?.chargedAmount == 9_999)
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
