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
            orderSource: "",
            categories: ["美妝"],
            paymentMethod: "",
            notes: "",
            verificationStatus: "",
            campaignNames: [],
            paymentReceiptStatus: .pending,
            isCashOnDelivery: false,
            photos: [],
            mergedSourceIDs: []
        )

        let summary = OrderSummary(order: order)

        // 運費 (domestic 80 + international 320) 由客人支付，不計入 totalCost
        // fees = 11_800 * 0.015 = 177；totalCost = itemCost 8_892 + fees 177 = 9_069
        #expect(summary.revenue == 11_800)
        #expect(summary.cardFee == 177)
        #expect(summary.platformFee == 0)
        #expect(summary.paymentFee == 0)
        #expect(summary.fees == 177)
        #expect(summary.totalCost == 9_069)
        #expect(summary.profit == 2_731)
        #expect(summary.margin == Decimal(2_731) / Decimal(11_800))
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
            orderSource: "",
            categories: ["測試"],
            paymentMethod: "",
            notes: "",
            verificationStatus: "",
            campaignNames: [],
            paymentReceiptStatus: .pending,
            isCashOnDelivery: false,
            photos: [],
            mergedSourceIDs: []
        )

        let summary = OrderSummary(order: order)

        // 1_001 * 0.03 = 30.03，無條件進位 → 31
        #expect(summary.platformFee == 31)
        #expect(summary.cardFee == 0)
        #expect(summary.paymentFee == 0)
        #expect(summary.fees == 31)
        #expect(summary.totalCost == 831)
        #expect(summary.profit == 170)
    }

    @Test func feesSplitIntoCardPlatformAndPayment() {
        // 三種手續費同時存在時，summary 應分別暴露各分項，且加總等於 fees
        let order = LedgerOrder(
            id: "BL-FEE-001",
            customer: LedgerCustomer(name: "手續費測試", initials: "FE", tier: .regular),
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
            cardFeeRate: Decimal(string: "0.015") ?? 0,
            platformFeeRate: Decimal(string: "0.02") ?? 0,
            paymentFeeRate: Decimal(string: "0.005") ?? 0,
            chargedAmount: Decimal(10_000),
            cardlessDeductionAmount: 0,
            cardlessSupplementAmount: 0,
            orderSource: "",
            categories: ["測試"],
            paymentMethod: "",
            notes: "",
            verificationStatus: "",
            campaignNames: [],
            paymentReceiptStatus: .pending,
            isCashOnDelivery: false,
            photos: [],
            mergedSourceIDs: []
        )

        let summary = OrderSummary(order: order)

        // cardFee = 10_000 * 0.015 = 150；platformFee = 10_000 * 0.02 = 200；
        // paymentFee = 10_000 * 0.005 = 50；fees = 400
        #expect(summary.cardFee == 150)
        #expect(summary.platformFee == 200)
        #expect(summary.paymentFee == 50)
        #expect(summary.fees == 400)
        #expect(summary.cardFee + summary.platformFee + summary.paymentFee == summary.fees)
    }

    @Test func cardlessSupplementAndDeductionAdjustRevenueAndProfit() {
        // 客戶實付 10_000，另以無卡補款 500、無卡折抵 200；
        // revenue = 10_000 + 500 - 200 = 10_300；fees 仍以 chargedAmount = 10_000 為基準
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
            orderSource: "",
            categories: ["測試"],
            paymentMethod: "無卡存款",
            notes: "",
            verificationStatus: "",
            campaignNames: [],
            paymentReceiptStatus: .pending,
            isCashOnDelivery: false,
            photos: [],
            mergedSourceIDs: []
        )

        let summary = OrderSummary(order: order)

        #expect(summary.revenue == 10_300)
        #expect(summary.fees == 0)
        #expect(summary.totalCost == 6_000)
        #expect(summary.profit == 4_300)
        #expect(summary.margin == Decimal(4_300) / Decimal(10_300))
    }

    @Test func cardlessAmountsDoNotAffectFeesBaseline() {
        // 折抵與補款不應影響手續費的基準 (仍以 chargedAmount 計算)
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
            orderSource: "",
            categories: ["測試"],
            paymentMethod: "無卡",
            notes: "",
            verificationStatus: "",
            campaignNames: [],
            paymentReceiptStatus: .pending,
            isCashOnDelivery: false,
            photos: [],
            mergedSourceIDs: []
        )

        let summary = OrderSummary(order: order)

        // fees = 10_000 * 0.015 = 150 (基於 chargedAmount，不是 revenue)
        #expect(summary.fees == 150)
        // revenue = 10_000 - 2_000 = 8_000；totalCost = 0 + 150 = 150；profit = 7_850
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
            orderSource: "",
            categories: ["精品"],
            paymentMethod: "",
            notes: "",
            verificationStatus: "",
            campaignNames: [],
            paymentReceiptStatus: .pending,
            isCashOnDelivery: false,
            photos: [],
            mergedSourceIDs: []
        )

        let summary = OrderSummary(order: order)

        // 國際運費 850 由客人支付，不計入 totalCost；chargedAmount = 0 故 fees = 0
        // totalCost = itemCost 13_728；profit = 0 - 13_728 = -13_728
        #expect(summary.revenue == 0)
        #expect(summary.fees == 0)
        #expect(summary.totalCost == 13_728)
        #expect(summary.profit == -13_728)
        #expect(summary.margin == 0)
    }

    @Test func shippingIsExcludedFromTotalCost() {
        // 國內、國際與來源國當地國內運費皆由客人支付，不計入我方成本；
        // totalCost 僅含 itemCost + fees
        let order = LedgerOrder(
            id: "BL-SHIP-001",
            customer: LedgerCustomer(name: "運費測試", initials: "SP", tier: .regular),
            status: .delivered,
            currency: .twd,
            date: Date(timeIntervalSince1970: 1_777_145_600),
            items: [
                LedgerOrderItem(name: "測試商品", quantity: 1, unitPrice: 5_000),
            ],
            itemCost: Decimal(3_000),
            domesticShipping: 100,
            internationalShipping: 500,
            foreignDomesticShipping: 200,
            cardFeeRate: 0,
            platformFeeRate: 0,
            paymentFeeRate: 0,
            chargedAmount: Decimal(5_000),
            cardlessDeductionAmount: 0,
            cardlessSupplementAmount: 0,
            orderSource: "",
            categories: ["測試"],
            paymentMethod: "",
            notes: "",
            verificationStatus: "",
            campaignNames: [],
            paymentReceiptStatus: .pending,
            isCashOnDelivery: false,
            photos: [],
            mergedSourceIDs: []
        )

        let summary = OrderSummary(order: order)

        // 運費合計 800 全數排除；totalCost = itemCost 3_000，profit = 5_000 - 3_000 = 2_000
        #expect(summary.fees == 0)
        #expect(summary.totalCost == 3_000)
        #expect(summary.profit == 2_000)
    }

    @Test func cashOnDeliveryIncludesShippingInTotalCost() {
        // 貨到付款：收款金額已含預估運費，三種運費 (國內 + 國際 + 外國國內) 計入總成本
        // 與 shippingIsExcludedFromTotalCost 對照：完全相同的訂單，差別只在 isCashOnDelivery == true
        let order = LedgerOrder(
            id: "BL-COD-001",
            customer: LedgerCustomer(name: "貨到付款測試", initials: "CD", tier: .regular),
            status: .delivered,
            currency: .twd,
            date: Date(timeIntervalSince1970: 1_777_145_600),
            items: [
                LedgerOrderItem(name: "測試商品", quantity: 1, unitPrice: 5_000),
            ],
            itemCost: Decimal(3_000),
            domesticShipping: 100,
            internationalShipping: 500,
            foreignDomesticShipping: 200,
            cardFeeRate: 0,
            platformFeeRate: 0,
            paymentFeeRate: 0,
            chargedAmount: Decimal(5_000),
            cardlessDeductionAmount: 0,
            cardlessSupplementAmount: 0,
            orderSource: "",
            categories: ["測試"],
            paymentMethod: "貨到付款",
            notes: "",
            verificationStatus: "",
            campaignNames: [],
            paymentReceiptStatus: .pending,
            isCashOnDelivery: true,
            photos: [],
            mergedSourceIDs: []
        )

        let summary = OrderSummary(order: order)

        // fees = 0；三種運費合計 800 計入總成本：totalCost = itemCost 3_000 + 運費 800 = 3_800
        // profit = revenue 5_000 - totalCost 3_800 = 1_200
        #expect(summary.fees == 0)
        #expect(summary.codShippingCost == 800)
        #expect(summary.totalCost == 3_800)
        #expect(summary.profit == 1_200)
        #expect(summary.margin == Decimal(1_200) / Decimal(5_000))
    }

    @Test func nonCashOnDeliveryHasZeroCodShippingCost() {
        // 對照組：同一筆運費結構，非貨到付款時 codShippingCost 為 0、運費不計入總成本
        let order = LedgerOrder(
            id: "BL-COD-002",
            customer: LedgerCustomer(name: "非貨到付款", initials: "NC", tier: .regular),
            status: .delivered,
            currency: .twd,
            date: Date(timeIntervalSince1970: 1_777_145_600),
            items: [
                LedgerOrderItem(name: "測試商品", quantity: 1, unitPrice: 5_000),
            ],
            itemCost: Decimal(3_000),
            domesticShipping: 100,
            internationalShipping: 500,
            foreignDomesticShipping: 200,
            cardFeeRate: 0,
            platformFeeRate: 0,
            paymentFeeRate: 0,
            chargedAmount: Decimal(5_000),
            cardlessDeductionAmount: 0,
            cardlessSupplementAmount: 0,
            orderSource: "",
            categories: ["測試"],
            paymentMethod: "信用卡",
            notes: "",
            verificationStatus: "",
            campaignNames: [],
            paymentReceiptStatus: .pending,
            isCashOnDelivery: false,
            photos: [],
            mergedSourceIDs: []
        )

        let summary = OrderSummary(order: order)

        #expect(summary.codShippingCost == 0)
        #expect(summary.totalCost == 3_000)
        #expect(summary.profit == 2_000)
    }
}
