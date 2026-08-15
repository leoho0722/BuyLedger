//
//  OrderCalculationTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/5/1.
//

import Foundation
import Testing
@testable import BuyLedger

/// 驗證訂單金額計算
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
            reconciliationStatus: "",
            campaignNames: [],
            paymentReceiptStatus: .pending,
            isCashOnDelivery: false,
            photos: [],
            mergedSourceIDs: []
        )
        
        let summary = OrderSummary(order: order)
        
        // 客人支付運費，totalCost 只含商品成本與手續費
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
                LedgerOrderItem(name: "測試商品", quantity: 1, unitPrice: 1_000)
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
            reconciliationStatus: "",
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
                LedgerOrderItem(name: "測試商品", quantity: 1, unitPrice: 10_000)
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
            reconciliationStatus: "",
            campaignNames: [],
            paymentReceiptStatus: .pending,
            isCashOnDelivery: false,
            photos: [],
            mergedSourceIDs: []
        )
        
        let summary = OrderSummary(order: order)
        
        // cardFee = 10_000 * 0.015 = 150；platformFee = 10_000 * 0.02 = 200。
        // paymentFee = 10_000 * 0.005 = 50；fees = 400
        #expect(summary.cardFee == 150)
        #expect(summary.platformFee == 200)
        #expect(summary.paymentFee == 50)
        #expect(summary.fees == 400)
        #expect(summary.cardFee + summary.platformFee + summary.paymentFee == summary.fees)
    }
    
    @Test func cardlessSupplementAndDeductionAdjustRevenueAndProfit() {
        // 補款 500、折抵 200 後 revenue 應為 10,300，手續費仍按 chargedAmount 計算
        let order = LedgerOrder(
            id: "BL-CARDLESS-001",
            customer: LedgerCustomer(name: "無卡測試", initials: "CL", tier: .regular),
            status: .delivered,
            currency: .twd,
            date: Date(timeIntervalSince1970: 1_777_145_600),
            items: [
                LedgerOrderItem(name: "測試商品", quantity: 1, unitPrice: 10_000)
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
            reconciliationStatus: "",
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
                LedgerOrderItem(name: "測試商品", quantity: 1, unitPrice: 1_000)
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
            reconciliationStatus: "",
            campaignNames: [],
            paymentReceiptStatus: .pending,
            isCashOnDelivery: false,
            photos: [],
            mergedSourceIDs: []
        )
        
        let summary = OrderSummary(order: order)
        
        // fees = 10_000 * 0.015 = 150 (基於 chargedAmount，不是 revenue)
        #expect(summary.fees == 150)
        // revenue 8,000、totalCost 150、profit 7,850
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
                )
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
            reconciliationStatus: "",
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
        // 國內、國際與來源國當地國內運費皆由客人支付，不計入我方成本。
        // totalCost 僅含 itemCost + fees
        let order = LedgerOrder(
            id: "BL-SHIP-001",
            customer: LedgerCustomer(name: "運費測試", initials: "SP", tier: .regular),
            status: .delivered,
            currency: .twd,
            date: Date(timeIntervalSince1970: 1_777_145_600),
            items: [
                LedgerOrderItem(name: "測試商品", quantity: 1, unitPrice: 5_000)
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
            reconciliationStatus: "",
            campaignNames: [],
            paymentReceiptStatus: .pending,
            isCashOnDelivery: false,
            photos: [],
            mergedSourceIDs: []
        )
        
        let summary = OrderSummary(order: order)
        
        // 運費不計成本，totalCost 3,000、profit 2,000
        #expect(summary.fees == 0)
        #expect(summary.totalCost == 3_000)
        #expect(summary.profit == 2_000)
    }
    
    @Test func cashOnDeliveryIncludesShippingInTotalCost() {
        // 貨到付款會把三種運費計入 totalCost
        let order = LedgerOrder(
            id: "BL-COD-001",
            customer: LedgerCustomer(name: "貨到付款測試", initials: "CD", tier: .regular),
            status: .delivered,
            currency: .twd,
            date: Date(timeIntervalSince1970: 1_777_145_600),
            items: [
                LedgerOrderItem(name: "測試商品", quantity: 1, unitPrice: 5_000)
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
            reconciliationStatus: "",
            campaignNames: [],
            paymentReceiptStatus: .pending,
            isCashOnDelivery: true,
            photos: [],
            mergedSourceIDs: []
        )
        
        let summary = OrderSummary(order: order)
        
        // 貨到付款的運費 800 計入成本，profit 為 1,200
        #expect(summary.fees == 0)
        #expect(summary.codShippingCost == 800)
        #expect(summary.totalCost == 3_800)
        #expect(summary.profit == 1_200)
        #expect(summary.margin == Decimal(1_200) / Decimal(5_000))
    }
    
    @Test func paymentFlagNormalizationIncludesAllThreeShippingCostsForCashOnDelivery() {
        // 三種運費都使用非零值，確認成本完整計入。
        let order = makePaymentFlagOrder(
            domesticShipping: 125,
            internationalShipping: 275,
            foreignDomesticShipping: 425,
            isCashOnDelivery: false
        )
        
        let corrected = order.applyingPaymentMethodFlags(
            isCardless: false,
            isBankTransfer: false,
            isCashOnDelivery: true
        )
        
        let before = order.summary
        let after = corrected.summary
        let shippingTotal = Decimal(125 + 275 + 425)
        
        #expect(after.codShippingCost == shippingTotal)
        #expect(after.totalCost - before.totalCost == shippingTotal)
        #expect(before.profit - after.profit == shippingTotal)
    }
    
    @Test func paymentFlagNormalizationClearsCardlessAmountsAndReconciliationStatus() {
        let order = makePaymentFlagOrder(
            cardlessDeductionAmount: 750,
            cardlessSupplementAmount: 250,
            reconciliationStatus: " 待對帳 ",
            isCardless: true
        )
        
        let corrected = order.applyingPaymentMethodFlags(
            isCardless: false,
            isBankTransfer: false,
            isCashOnDelivery: false
        )
        
        #expect(corrected.cardlessDeductionAmount == 0)
        #expect(corrected.cardlessSupplementAmount == 0)
        #expect(corrected.reconciliationStatus == "")
    }
    
    @Test func paymentFlagNormalizationRetainsReconciliationStatusForBankTransfer() {
        let order = makePaymentFlagOrder(reconciliationStatus: " 待對帳 ")
        
        let corrected = order.applyingPaymentMethodFlags(
            isCardless: false,
            isBankTransfer: true,
            isCashOnDelivery: false
        )
        
        #expect(corrected.reconciliationStatus == "待對帳")
    }
    
    @Test func paymentFlagNormalizationClampsCardlessDeductionToChargedAmount() {
        let order = makePaymentFlagOrder(
            chargedAmount: 1_000,
            cardlessDeductionAmount: 1_500,
            isCardless: false
        )
        
        let corrected = order.applyingPaymentMethodFlags(
            isCardless: true,
            isBankTransfer: false,
            isCashOnDelivery: false
        )
        
        #expect(corrected.cardlessDeductionAmount == 1_000)
        #expect(corrected.summary.revenue >= 0)
    }
    
    @Test func nonCashOnDeliveryHasZeroCodShippingCost() {
        // 非貨到付款時運費不計入總成本。
        let order = LedgerOrder(
            id: "BL-COD-002",
            customer: LedgerCustomer(name: "非貨到付款", initials: "NC", tier: .regular),
            status: .delivered,
            currency: .twd,
            date: Date(timeIntervalSince1970: 1_777_145_600),
            items: [
                LedgerOrderItem(name: "測試商品", quantity: 1, unitPrice: 5_000)
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
            reconciliationStatus: "",
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
    
    // MARK: - Margin Empty Value
    
    @Test func marginPercentIsEmptyWhenRevenueIsZeroAndFormattedWhenPositive() {
        let locale = Locale(identifier: "en")
        
        let zeroRevenueOrder = makeCardlessOrder(chargedAmount: 1_000, deduction: 1_000)
        let zeroRevenueSummary = OrderSummary(order: zeroRevenueOrder)
        #expect(zeroRevenueSummary.revenue == 0)
        #expect(OrderFormatters.marginPercent(zeroRevenueSummary, locale: locale) == "—")
        
        let positiveRevenueOrder = makeCardlessOrder(
            chargedAmount: 10_000, deduction: 0, itemCost: 6_000)
        let positiveRevenueSummary = OrderSummary(order: positiveRevenueOrder)
        #expect(positiveRevenueSummary.revenue > 0)
        #expect(
            OrderFormatters.marginPercent(positiveRevenueSummary, locale: locale)
                == OrderFormatters.percent(positiveRevenueSummary.margin, locale: locale)
        )
    }
    
    @Test func marginPercentIsEmptyForLegacyNegativeRevenueData() {
        // 舊資料的 revenue 可能為負，這時毛利率應保持空值
        let order = makeCardlessOrder(chargedAmount: 1_000, deduction: 1_500)
        let summary = OrderSummary(order: order)
        
        #expect(summary.revenue == -500)
        #expect(summary.profit == -500)
        #expect(summary.margin == 1)  // 兩負相除得正：未經處理的呈現會顯示「100%」這個假數字
        #expect(OrderFormatters.marginPercent(summary, locale: Locale(identifier: "en")) == "—")
    }
}

// MARK: - Private Method

private extension OrderCalculationTests {
    
    /// 建立同時涵蓋三種付款旗標的測試訂單
    /// - Parameters:
    ///   - chargedAmount: 客戶實付金額
    ///   - itemCost: 商品成本
    ///   - domesticShipping: 國內運費
    ///   - internationalShipping: 國際運費
    ///   - foreignDomesticShipping: 國外境內運費
    ///   - cardlessDeductionAmount: 無卡折抵金額
    ///   - cardlessSupplementAmount: 無卡補收金額
    ///   - reconciliationStatus: 對帳狀態
    ///   - isCardless: 是否為無卡付款
    ///   - isCashOnDelivery: 是否為貨到付款
    /// - Returns: 建立的測試訂單
    func makePaymentFlagOrder(
        chargedAmount: Decimal = 5_000,
        itemCost: Decimal = 3_000,
        domesticShipping: Decimal = 100,
        internationalShipping: Decimal = 500,
        foreignDomesticShipping: Decimal = 200,
        cardlessDeductionAmount: Decimal = 0,
        cardlessSupplementAmount: Decimal = 0,
        reconciliationStatus: String = "",
        isCardless: Bool = false,
        isCashOnDelivery: Bool = false
    ) -> LedgerOrder {
        LedgerOrder(
            id: "BL-FLAG-001",
            customer: LedgerCustomer(name: "旗標測試", initials: "FT", tier: .regular),
            status: .delivered,
            currency: .twd,
            date: Date(timeIntervalSince1970: 1_777_145_600),
            items: [LedgerOrderItem(name: "測試商品", quantity: 1, unitPrice: 5_000)],
            itemCost: itemCost,
            domesticShipping: domesticShipping,
            internationalShipping: internationalShipping,
            foreignDomesticShipping: foreignDomesticShipping,
            cardFeeRate: 0,
            platformFeeRate: 0,
            paymentFeeRate: 0,
            chargedAmount: chargedAmount,
            cardlessDeductionAmount: cardlessDeductionAmount,
            cardlessSupplementAmount: cardlessSupplementAmount,
            orderSource: "測試來源",
            categories: ["測試"],
            paymentMethod: isCardless ? "無卡存款" : "信用卡",
            notes: "",
            reconciliationStatus: reconciliationStatus,
            campaignNames: [],
            paymentReceiptStatus: .pending,
            isCashOnDelivery: isCashOnDelivery,
            photos: [],
            mergedSourceIDs: []
        )
    }
    
    /// 建立無卡付款方式的測試訂單
    /// - Parameters:
    ///   - chargedAmount: 客戶實付金額
    ///   - deduction: 無卡折抵金額
    ///   - itemCost: 商品成本
    /// - Returns: 建立的測試訂單
    func makeCardlessOrder(
        chargedAmount: Decimal,
        deduction: Decimal,
        itemCost: Decimal = 0
    ) -> LedgerOrder {
        LedgerOrder(
            id: "BL-CAP-TEST",
            customer: LedgerCustomer(name: "折抵測試", initials: "CT", tier: .regular),
            status: .delivered,
            currency: .twd,
            date: Date(timeIntervalSince1970: 1_777_145_600),
            items: [],
            itemCost: itemCost,
            domesticShipping: 0,
            internationalShipping: 0,
            foreignDomesticShipping: 0,
            cardFeeRate: 0,
            platformFeeRate: 0,
            paymentFeeRate: 0,
            chargedAmount: chargedAmount,
            cardlessDeductionAmount: deduction,
            cardlessSupplementAmount: 0,
            orderSource: "測試來源",
            categories: ["測試"],
            paymentMethod: "無卡存款",
            notes: "",
            reconciliationStatus: "",
            campaignNames: [],
            paymentReceiptStatus: .pending,
            isCashOnDelivery: false,
            photos: [],
            mergedSourceIDs: []
        )
    }
}
