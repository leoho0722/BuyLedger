//
//  CustomersFeatureTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/7/12.
//

import Foundation
import Testing
@testable import BuyLedger

@MainActor
struct CustomersFeatureTests {

    // MARK: - Tests

    @Test func aggregatesOrdersByCustomerRankedBySpendDescending() {
        // SBE (spec Example)：Amy(300, 3/1)、Amy(200, 3/5)、Bob(400, 3/2)、Cara(100, 3/3)
        // → Amy(count=2, total=500, last=3/5)、Bob(count=1, total=400, last=3/2)、Cara(count=1, total=100, last=3/3)
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

    // MARK: - Helper

    /// 建立僅填入客戶彙總相關欄位的訂單；成本／費率欄位皆為 0，使 `summary.revenue == chargedAmount`
    private func makeOrder(
        id: String,
        customer: String,
        charged: Decimal,
        date: Date
    ) -> LedgerOrder {
        LedgerOrder(
            id: id,
            customer: LedgerCustomer(name: customer, initials: "XX", tier: .regular),
            status: .confirmed,
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
            verificationStatus: "",
            campaignNames: [],
            paymentReceiptStatus: .pending,
            isCashOnDelivery: false,
            photos: [],
            mergedSourceIDs: []
        )
    }

    /// 以固定 gregorian/UTC 曆建立指定年月日的日期，確保跨機器一致
    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        return calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }
}
