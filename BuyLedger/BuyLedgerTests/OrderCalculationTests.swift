//
//  OrderCalculationTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/5/1.
//

import Foundation
import Testing
@testable import BuyLedger

@MainActor
struct OrderCalculationTests {

    // MARK: - Tests

    @Test func summaryIncludesFeesCostProfitAndMargin() {
        let order = LedgerOrder(
            id: "BL-2604-018",
            customer: LedgerCustomer(name: "林書宇", initials: "SY", tier: .vip),
            status: .shipping,
            currency: .krw,
            date: Date(timeIntervalSince1970: 1_777_145_600),
            items: [
                LedgerOrderItem(name: "Tamburins 香水 Chamo 50ml", quantity: 1, unitPrice: 95_000),
                LedgerOrderItem(name: "Gentle Monster Her 02", quantity: 1, unitPrice: 295_000),
            ],
            itemCost: Decimal(8_892),
            domesticShipping: 80,
            internationalShipping: 320,
            cardFeeRate: Decimal(string: "0.015") ?? 0,
            platformFeeRate: 0,
            chargedAmount: Decimal(11_800),
            category: "美妝"
        )

        let summary = OrderSummary(order: order)

        #expect(summary.revenue == 11_800)
        #expect(summary.fees == 177)
        #expect(summary.totalCost == 9_469)
        #expect(summary.profit == 2_331)
        #expect(summary.margin == Decimal(2_331) / Decimal(11_800))
    }

    @Test func quotingOrderWithoutChargeKeepsZeroMargin() {
        let order = LedgerOrder(
            id: "BL-2604-015",
            customer: LedgerCustomer(name: "Joyce 黃", initials: "JH", tier: .vip),
            status: .quoting,
            currency: .eur,
            date: Date(timeIntervalSince1970: 1_776_713_600),
            items: [
                LedgerOrderItem(name: "Polène Numéro Un Nano 米色", quantity: 1, unitPrice: 390),
            ],
            itemCost: Decimal(13_728),
            domesticShipping: 0,
            internationalShipping: 850,
            cardFeeRate: Decimal(string: "0.015") ?? 0,
            platformFeeRate: 0,
            chargedAmount: 0,
            category: "精品"
        )

        let summary = OrderSummary(order: order)

        #expect(summary.revenue == 0)
        #expect(summary.fees == 0)
        #expect(summary.totalCost == 14_578)
        #expect(summary.profit == -14_578)
        #expect(summary.margin == 0)
    }
}
