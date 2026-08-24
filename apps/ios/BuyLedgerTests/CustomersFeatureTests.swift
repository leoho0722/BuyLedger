//
//  CustomersFeatureTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/7/12.
//

import ComposableArchitecture
import Foundation
import Testing
@testable import BuyLedger

/// 驗證客戶彙總
@MainActor
struct CustomersFeatureTests {
    
    // MARK: - Tests
    
    @Test func aggregatesOrdersByCustomerRankedBySpendDescending() {
        // Amy 消費最高，排序應為 Amy、Bob、Cara
        let orders = [
            makeOrder(id: "1", customer: "Amy", charged: 300, date: date(2026, 3, 1)),
            makeOrder(id: "2", customer: "Amy", charged: 200, date: date(2026, 3, 5)),
            makeOrder(id: "3", customer: "Bob", charged: 400, date: date(2026, 3, 2)),
            makeOrder(id: "4", customer: "Cara", charged: 100, date: date(2026, 3, 3)),
        ]
        let state = CustomersFeature.State(orders: orders)
        
        #expect(state.customers.map(\.name) == ["Amy", "Bob", "Cara"])
        
        let amy = state.customers.first { $0.name == "Amy" }
        #expect(amy?.orderCount == 2)
        #expect(amy?.totalSpent == 500)
        #expect(amy?.lastOrderDate == date(2026, 3, 5))
        
        let bob = state.customers.first { $0.name == "Bob" }
        #expect(bob?.orderCount == 1)
        #expect(bob?.totalSpent == 400)
        #expect(bob?.lastOrderDate == date(2026, 3, 2))
        
        let cara = state.customers.first { $0.name == "Cara" }
        #expect(cara?.orderCount == 1)
        #expect(cara?.totalSpent == 100)
        #expect(cara?.lastOrderDate == date(2026, 3, 3))
    }
    
    @Test func emptyOrdersYieldsEmptyCustomerList() {
        let state = CustomersFeature.State(orders: [])
        
        #expect(state.customers.isEmpty)
    }
    
    @Test func totalSpentAndOrderCountExcludeCancelledAndMergeResultOrders() {
        let orders = [
            makeOrder(id: "confirmed", customer: "Amy", charged: 100, date: date(2026, 3, 1)),
            makeOrder(
                id: "cancelled", customer: "Amy", charged: 200, date: date(2026, 3, 2),
                status: .cancelled),
            makeOrder(
                id: "result", customer: "Amy", charged: 500, date: date(2026, 3, 3),
                mergedSourceIDs: ["sourceA", "sourceB"]),
            makeOrder(
                id: "sourceA", customer: "Amy", charged: 100, date: date(2026, 3, 4),
                status: .confirmed),
            makeOrder(
                id: "sourceB", customer: "Amy", charged: 200, date: date(2026, 3, 5),
                status: .confirmed),
        ]
        
        let amy = CustomerRow.aggregate(orders: orders).first { $0.name == "Amy" }
        #expect(amy?.orderCount == 2)
        #expect(amy?.totalSpent == 600)
        #expect(amy?.lastOrderDate == date(2026, 3, 5))
    }
    
    @Test func customerWithOnlyCancelledOrdersRemainsListedWithZeroSpend() {
        let orders = [
            makeOrder(
                id: "cancelled", customer: "Amy", charged: 200, date: date(2026, 3, 2),
                status: .cancelled)
        ]
        
        let amy = CustomerRow.aggregate(orders: orders).first { $0.name == "Amy" }
        
        #expect(amy?.orderCount == 0)
        #expect(amy?.totalSpent == 0)
    }
    
    /// 驗證客戶點選只送出 delegate
    @Test func customerTappedDelegateMutatesNoState() async {
        let store = TestStore(initialState: CustomersFeature.State()) {
            CustomersFeature()
        }
        
        await store.send(.delegate(.customerTapped("Alice")))
    }
    
    // MARK: - Helper
    
    /// 建立客戶彙總測試用訂單
    /// - Parameters:
    ///   - id: 訂單識別值
    ///   - customer: 客戶名稱
    ///   - charged: 客戶實付金額
    ///   - date: 訂單日期
    ///   - status: 訂單狀態
    ///   - mergedSourceIDs: 被合併的來源訂單編號
    /// - Returns: 建立的測試訂單
    private func makeOrder(
        id: String,
        customer: String,
        charged: Decimal,
        date: Date,
        status: OrderStatus = .confirmed,
        mergedSourceIDs: [String] = []
    ) -> LedgerOrder {
        LedgerOrder(
            id: id,
            customer: LedgerCustomer(name: customer, initials: "XX", tier: .regular),
            status: status,
            currency: .twd,
            date: date,
            items: [LedgerOrderItem(name: "item", quantity: 1, unitPrice: 0)],
            itemCost: 0,
            domesticShipping: 0,
            internationalShipping: 0,
            foreignDomesticShipping: 0,
            cardFeeRate: 0,
            platformFeeRate: 0,
            paymentFeeRate: 0,
            chargedAmount: charged,
            cardlessDeductionAmount: 0,
            cardlessSupplementAmount: 0,
            orderSource: "",
            categories: [],
            paymentMethod: "",
            notes: "",
            reconciliationStatus: "",
            campaignNames: [],
            paymentReceiptStatus: .pending,
            isCashOnDelivery: false,
            photos: [],
            mergedSourceIDs: mergedSourceIDs
        )
    }
    
    /// 以固定 gregorian/UTC 曆建立指定年月日的日期，確保跨機器一致
    /// - Parameters:
    ///   - year: 西元年
    ///   - month: 月份
    ///   - day: 日期
    /// - Returns: 指定日期 UTC 零時的時間值
    private func date(
        _ year: Int,
        _ month: Int,
        _ day: Int
    ) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        return calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }
}
