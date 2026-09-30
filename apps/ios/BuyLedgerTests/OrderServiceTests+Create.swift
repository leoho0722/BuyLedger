//
//  OrderServiceTests+Create.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/26.
//

import Foundation
import Testing

@testable import BuyLedger

// MARK: - Tests

extension OrderServiceTests {

    /// 建立意圖會新增尚不存在的完整訂單
    ///
    /// - Throws: 建立時以 `OrderPersistenceError` 丟出 `.identifierCollision(id:)`、
    ///   `.storage(.fetchFailed(underlying:))` 或
    ///   `.storage(.saveFailed(underlying:))`；讀取失敗時丟出 `.fetchFailed(underlying:)`；
    ///   建立後未讀回訂單時由 `#require` 丟出測試斷言錯誤
    @Test
    func createOrder_識別值尚不存在_新增完整訂單() async throws {
        // Given
        let database = BuyLedgerDatabaseTests.makeInMemoryDatabase()
        let service = Self.makeService(database: database)
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
            reconciliationStatus: "",
            campaignNames: [],
            paymentReceiptStatus: .pending,
            isCashOnDelivery: false,
            photos: [],
            mergedSourceIDs: []
        )

        // When
        try await service.createOrder(order)

        // Then
        let storedOrders = try await service.fetchOrders()
        #expect(storedOrders.count == 1)
        let stored = try #require(storedOrders.first)
        #expect(stored.id == "BL-TEST-001")
        #expect(stored.customer.name == "測試客戶")
        #expect(stored.notes == "建立時的備註")
        let storedWithPhotos = try #require(try await Self.fetchOrder(id: order.id, from: database))
        #expect(
            LedgerOrder.normalizingItemIdentifiers(storedWithPhotos)
                == LedgerOrder.normalizingItemIdentifiers(order)
        )
    }

    /// 建立意圖遇到同編號會丟出撞號錯誤且逐欄保留既有訂單
    ///
    /// - Throws: 準備或讀取失敗時丟出 `.saveFailed(underlying:)` 或 `.fetchFailed(underlying:)`；
    ///   建立未丟錯誤、錯誤不是 `.identifierCollision(id:)` 或未讀回原訂單時由 `#require` 丟出測試斷言錯誤；
    ///   建立失敗時以 `OrderPersistenceError` 丟出 `.identifierCollision(id:)`、
    ///   `.storage(.fetchFailed(underlying:))` 或
    ///   `.storage(.saveFailed(underlying:))`
    @Test
    func createOrder_識別值已存在_丟出撞號並保留既有訂單() async throws {
        // Given
        let database = BuyLedgerDatabaseTests.makeInMemoryDatabase()
        let original = Self.makeFullFieldOrder(id: "ORDER-COLLISION", variant: .original)
        try await Self.seed([original], database: database)
        let service = Self.makeService(database: database)
        let duplicate = Self.makeFullFieldOrder(id: original.id, variant: .updated)
        var actualError: OrderPersistenceError?

        // When
        do throws(OrderPersistenceError) {
            try await service.createOrder(duplicate)
        } catch {
            actualError = error
        }

        // Then
        let error = try #require(actualError)
        let actualCollisionID: String?
        switch error {
        case .identifierCollision(let id):
            actualCollisionID = id

        case .storage:
            actualCollisionID = nil
        }
        let collisionID = try #require(actualCollisionID)
        #expect(collisionID == original.id)
        let storedOrders = try await service.fetchOrders()
        #expect(storedOrders.count == 1)
        let stored = try #require(try await Self.fetchOrder(id: original.id, from: database))
        #expect(
            LedgerOrder.normalizingItemIdentifiers(stored)
                == LedgerOrder.normalizingItemIdentifiers(original)
        )
        #expect(stored.photos == original.photos)
    }
}
