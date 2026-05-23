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
            foreignDomesticShipping: 0,
            cardFeeRate: Decimal(string: "0.015") ?? 0,
            platformFeeRate: 0,
            paymentFeeRate: 0,
            chargedAmount: Decimal(11_800),
            cardlessDeductionAmount: 0,
            cardlessSupplementAmount: 0,
            category: "美妝",
            paymentMethod: ""
        )

        let summary = OrderSummary(order: order)

        #expect(summary.revenue == 11_800)
        #expect(summary.fees == 177)
        #expect(summary.totalCost == 9_469)
        #expect(summary.profit == 2_331)
        #expect(summary.margin == Decimal(2_331) / Decimal(11_800))
    }
    
    @Test func platformFeeRoundsUpToInteger() {
        let order = LedgerOrder(
            id: "BL-2605-001",
            customer: LedgerCustomer(name: "測試客戶", initials: "TT", tier: .regular),
            status: .delivered,
            currency: .twd,
            date: Date(timeIntervalSince1970: 1_777_145_600),
            items: [
                LedgerOrderItem(name: "測試商品", quantity: 1, unitPrice: 1_000),
            ],
            itemCost: Decimal(800),
            domesticShipping: 0,
            internationalShipping: 0,
            foreignDomesticShipping: 0,
            cardFeeRate: 0,
            platformFeeRate: Decimal(string: "0.03") ?? 0,
            paymentFeeRate: 0,
            chargedAmount: Decimal(1_001),
            cardlessDeductionAmount: 0,
            cardlessSupplementAmount: 0,
            category: "測試",
            paymentMethod: ""
        )

        let summary = OrderSummary(order: order)

        // 1_001 * 0.03 = 30.03，無條件進位 → 31
        #expect(summary.fees == 31)
        #expect(summary.totalCost == 831)
        #expect(summary.profit == 170)
    }

    @Test func cardlessSupplementAndDeductionAdjustRevenueAndProfit() {
        // 客戶實付 10_000，另以無卡補款 500、無卡折抵 200；
        // revenue = 10_000 + 500 - 200 = 10_300；fees 仍以 chargedAmount = 10_000 為基準。
        let order = LedgerOrder(
            id: "BL-CARDLESS-001",
            customer: LedgerCustomer(name: "無卡測試", initials: "CL", tier: .regular),
            status: .delivered,
            currency: .twd,
            date: Date(timeIntervalSince1970: 1_777_145_600),
            items: [
                LedgerOrderItem(name: "測試商品", quantity: 1, unitPrice: 10_000),
            ],
            itemCost: Decimal(6_000),
            domesticShipping: 0,
            internationalShipping: 0,
            foreignDomesticShipping: 0,
            cardFeeRate: 0,
            platformFeeRate: 0,
            paymentFeeRate: 0,
            chargedAmount: Decimal(10_000),
            cardlessDeductionAmount: Decimal(200),
            cardlessSupplementAmount: Decimal(500),
            category: "測試",
            paymentMethod: "無卡存款"
        )

        let summary = OrderSummary(order: order)

        #expect(summary.revenue == 10_300)
        #expect(summary.fees == 0)
        #expect(summary.totalCost == 6_000)
        #expect(summary.profit == 4_300)
        #expect(summary.margin == Decimal(4_300) / Decimal(10_300))
    }

    @Test func cardlessAmountsDoNotAffectFeesBaseline() {
        // 折抵與補款不應影響手續費的基準 (仍以 chargedAmount 計算)。
        let order = LedgerOrder(
            id: "BL-CARDLESS-002",
            customer: LedgerCustomer(name: "刷卡＋無卡", initials: "MX", tier: .regular),
            status: .delivered,
            currency: .twd,
            date: Date(timeIntervalSince1970: 1_777_145_600),
            items: [
                LedgerOrderItem(name: "測試商品", quantity: 1, unitPrice: 1_000),
            ],
            itemCost: 0,
            domesticShipping: 0,
            internationalShipping: 0,
            foreignDomesticShipping: 0,
            cardFeeRate: Decimal(string: "0.015") ?? 0,
            platformFeeRate: 0,
            paymentFeeRate: 0,
            chargedAmount: Decimal(10_000),
            cardlessDeductionAmount: Decimal(2_000),
            cardlessSupplementAmount: Decimal(0),
            category: "測試",
            paymentMethod: "無卡"
        )

        let summary = OrderSummary(order: order)

        // fees = 10_000 * 0.015 = 150 (基於 chargedAmount，不是 revenue)。
        #expect(summary.fees == 150)
        // revenue = 10_000 - 2_000 = 8_000；totalCost = 0 + 150 = 150；profit = 7_850。
        #expect(summary.revenue == 8_000)
        #expect(summary.totalCost == 150)
        #expect(summary.profit == 7_850)
    }

    @Test func quotingOrderWithoutChargeKeepsZeroMargin() {
        let order = LedgerOrder(
            id: "BL-2604-015",
            customer: LedgerCustomer(
                name: "Joyce 黃",
                initials: "JH",
                tier: .vip
            ),
            status: .quoting,
            currency: CurrencyCode(rawValue: "EUR"),
            date: Date(timeIntervalSince1970: 1_776_713_600),
            items: [
                LedgerOrderItem(
                    name: "Polène Numéro Un Nano 米色",
                    quantity: 1,
                    unitPrice: 390
                ),
            ],
            itemCost: Decimal(13_728),
            domesticShipping: 0,
            internationalShipping: 850,
            foreignDomesticShipping: 0,
            cardFeeRate: Decimal(string: "0.015") ?? 0,
            platformFeeRate: 0,
            paymentFeeRate: 0,
            chargedAmount: 0,
            cardlessDeductionAmount: 0,
            cardlessSupplementAmount: 0,
            category: "精品",
            paymentMethod: ""
        )
        
        let summary = OrderSummary(order: order)
        
        #expect(summary.revenue == 0)
        #expect(summary.fees == 0)
        #expect(summary.totalCost == 14_578)
        #expect(summary.profit == -14_578)
        #expect(summary.margin == 0)
    }
}
