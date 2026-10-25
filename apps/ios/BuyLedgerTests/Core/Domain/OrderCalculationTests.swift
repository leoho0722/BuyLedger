//
//  OrderCalculationTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/5/1.
//

import Foundation
import Testing

@testable import BuyLedger

/// `OrderSummary` 的單元測試，涵蓋手續費、運費、無卡金額與毛利率的計算
struct OrderCalculationTests {

    /// 驗證含刷卡手續費與運費的訂單，運費不計入總成本，手續費 177、總成本 9,069、毛利 2,731
    ///
    /// - Throws: 預期毛利率字串無法轉為數值時丟出測試錯誤
    @Test
    func init_含刷卡手續費與運費_彙總手續費成本毛利與毛利率() throws {
        // Given
        let expectedMargin = try #require(
            Decimal(string: "0.23144067796610169491525423728813559322")
        )
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

        // 客人支付運費，totalCost 只含商品成本與手續費

        // When
        let summary = OrderSummary(order: order)

        // Then
        #expect(summary.revenue == 11_800)
        #expect(summary.cardFee == 177)
        #expect(summary.platformFee == 0)
        #expect(summary.paymentFee == 0)
        #expect(summary.fees == 177)
        #expect(summary.totalCost == 9_069)
        #expect(summary.profit == 2_731)
        #expect(summary.margin == expectedMargin)
    }

    /// 驗證平台手續費的小數部分無條件進位，手續費 30.03 進為 31，總成本與毛利隨之計算
    @Test
    func init_平台手續費有小數_無條件進位為整數() {
        // Given
        let order = LedgerOrder(
            id: "BL-2605-001",
            customer: LedgerCustomer(name: "測試客戶", initials: "TT", tier: .regular),
            status: .delivered,
            currency: .twd,
            date: Date(timeIntervalSince1970: 1_777_145_600),
            items: [LedgerOrderItem(name: "測試商品", quantity: 1, unitPrice: 1_000)],
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

        // 1_001 * 0.03 = 30.03，無條件進位 → 31

        // When
        let summary = OrderSummary(order: order)

        // Then
        #expect(summary.platformFee == 31)
        #expect(summary.cardFee == 0)
        #expect(summary.paymentFee == 0)
        #expect(summary.fees == 31)
        #expect(summary.totalCost == 831)
        #expect(summary.profit == 170)
    }

    /// 驗證刷卡、平台與付款三種手續費分項暴露，且三者加總等於 `fees`
    @Test
    func init_三種手續費同時存在_分項暴露且加總等於手續費() {
        // Given
        let order = LedgerOrder(
            id: "BL-FEE-001",
            customer: LedgerCustomer(name: "手續費測試", initials: "FE", tier: .regular),
            status: .delivered,
            currency: .twd,
            date: Date(timeIntervalSince1970: 1_777_145_600),
            items: [LedgerOrderItem(name: "測試商品", quantity: 1, unitPrice: 10_000)],
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

        // cardFee = 10_000 * 0.015 = 150；platformFee = 10_000 * 0.02 = 200
        // paymentFee = 10_000 * 0.005 = 50；fees = 400

        // When
        let summary = OrderSummary(order: order)

        // Then
        #expect(summary.cardFee == 150)
        #expect(summary.platformFee == 200)
        #expect(summary.paymentFee == 50)
        #expect(summary.fees == 400)
        #expect(summary.cardFee + summary.platformFee + summary.paymentFee == summary.fees)
    }

    /// 驗證無卡補款與折抵會調整營收與毛利，營收為 10,300、毛利為 4,300
    ///
    /// - Throws: 預期毛利率字串無法轉為數值時丟出測試錯誤
    @Test
    func init_含無卡補款與折抵_營收與毛利反映調整金額() throws {
        // Given
        let expectedMargin = try #require(
            Decimal(string: "0.41747572815533980582524271844660194174")
        )
        // 補款 500、折抵 200 後 revenue 應為 10,300，手續費仍按 chargedAmount 計算
        let order = LedgerOrder(
            id: "BL-CARDLESS-001",
            customer: LedgerCustomer(name: "無卡測試", initials: "CL", tier: .regular),
            status: .delivered,
            currency: .twd,
            date: Date(timeIntervalSince1970: 1_777_145_600),
            items: [LedgerOrderItem(name: "測試商品", quantity: 1, unitPrice: 10_000)],
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

        // When
        let summary = OrderSummary(order: order)

        // Then
        #expect(summary.revenue == 10_300)
        #expect(summary.fees == 0)
        #expect(summary.totalCost == 6_000)
        #expect(summary.profit == 4_300)
        #expect(summary.margin == expectedMargin)
    }

    /// 驗證無卡折抵不影響手續費基準，手續費仍以實付金額 10,000 計算為 150
    @Test
    func init_含無卡折抵與補款_手續費仍以實付金額為基準() {
        // Given
        // 折抵與補款不應影響手續費的基準 (仍以 chargedAmount 計算)
        let order = LedgerOrder(
            id: "BL-CARDLESS-002",
            customer: LedgerCustomer(name: "刷卡＋無卡", initials: "MX", tier: .regular),
            status: .delivered,
            currency: .twd,
            date: Date(timeIntervalSince1970: 1_777_145_600),
            items: [LedgerOrderItem(name: "測試商品", quantity: 1, unitPrice: 1_000)],
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
            paymentMethod: "orders.detail.label.cardless",
            notes: "",
            reconciliationStatus: "",
            campaignNames: [],
            paymentReceiptStatus: .pending,
            isCashOnDelivery: false,
            photos: [],
            mergedSourceIDs: []
        )

        // fees = 10_000 * 0.015 = 150 (基於 chargedAmount，不是 revenue)

        // When
        let summary = OrderSummary(order: order)

        // Then
        #expect(summary.fees == 150)
        // revenue 8,000、totalCost 150、profit 7,850
        #expect(summary.revenue == 8_000)
        #expect(summary.totalCost == 150)
        #expect(summary.profit == 7_850)
    }

    /// 驗證報價單未收款時，營收與毛利率為零，商品成本仍計入總成本
    @Test
    func init_報價單未收款_營收為零且毛利率為零() {
        // Given
        let order = LedgerOrder(
            id: "BL-2604-015",
            customer: LedgerCustomer(name: "Joyce 黃", initials: "JH", tier: .vip),
            status: .quoting,
            currency: CurrencyCode(rawValue: "EUR"),
            date: Date(timeIntervalSince1970: 1_776_713_600),
            items: [
                LedgerOrderItem(name: "Polène Numéro Un Nano 米色", quantity: 1, unitPrice: 390),
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

        // 國際運費 850 由客人支付，不計入 totalCost；chargedAmount = 0 故 fees = 0
        // totalCost = itemCost 13_728；profit = 0 - 13_728 = -13_728

        // When
        let summary = OrderSummary(order: order)

        // Then
        #expect(summary.revenue == 0)
        #expect(summary.fees == 0)
        #expect(summary.totalCost == 13_728)
        #expect(summary.profit == -13_728)
        #expect(summary.margin == 0)
    }

    /// 驗證含三種運費的訂單，運費由客人支付，總成本與毛利不受運費影響
    @Test
    func init_含三種運費_運費不計入總成本() {
        // Given
        // 國內、國際與來源國當地國內運費皆由客人支付，不計入我方成本
        // totalCost 僅含 itemCost + fees
        let order = LedgerOrder(
            id: "BL-SHIP-001",
            customer: LedgerCustomer(name: "運費測試", initials: "SP", tier: .regular),
            status: .delivered,
            currency: .twd,
            date: Date(timeIntervalSince1970: 1_777_145_600),
            items: [LedgerOrderItem(name: "測試商品", quantity: 1, unitPrice: 5_000)],
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

        // 運費不計成本，totalCost 3,000、profit 2,000

        // When
        let summary = OrderSummary(order: order)

        // Then
        #expect(summary.fees == 0)
        #expect(summary.totalCost == 3_000)
        #expect(summary.profit == 2_000)
    }

    /// 驗證貨到付款時，三種運費合計 800 計入總成本
    @Test
    func init_貨到付款_三種運費計入總成本() {
        // Given
        // 貨到付款會把三種運費計入 totalCost
        let order = LedgerOrder(
            id: "BL-COD-001",
            customer: LedgerCustomer(name: "貨到付款測試", initials: "CD", tier: .regular),
            status: .delivered,
            currency: .twd,
            date: Date(timeIntervalSince1970: 1_777_145_600),
            items: [LedgerOrderItem(name: "測試商品", quantity: 1, unitPrice: 5_000)],
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
            paymentMethod: "orders.list.label.cashDelivery",
            notes: "",
            reconciliationStatus: "",
            campaignNames: [],
            paymentReceiptStatus: .pending,
            isCashOnDelivery: true,
            photos: [],
            mergedSourceIDs: []
        )

        // 貨到付款的運費 800 計入成本，profit 為 1,200

        // When
        let summary = OrderSummary(order: order)

        // Then
        #expect(summary.fees == 0)
        #expect(summary.codShippingCost == 800)
        #expect(summary.totalCost == 3_800)
        #expect(summary.profit == 1_200)
        #expect(summary.margin == Decimal(string: "0.24"))
    }

    /// 驗證付款方式改為貨到付款後，三種運費合計計入成本，毛利減少相同金額
    @Test
    func applyingPaymentMethodFlags_改為貨到付款_三種運費計入成本() {
        // Given
        let shippingTotal = Decimal(825)
        // 三種運費都使用非零值，確認成本完整計入
        let order = makePaymentFlagOrder(
            domesticShipping: 125,
            internationalShipping: 275,
            foreignDomesticShipping: 425,
            isCashOnDelivery: false
        )

        // When
        let corrected = order.applyingPaymentMethodFlags(
            PaymentMethodFlags(isCardless: false, isBankTransfer: false, isCashOnDelivery: true)
        )
        let before = order.summary
        let after = corrected.summary

        // Then
        #expect(after.codShippingCost == shippingTotal)
        #expect(after.totalCost - before.totalCost == shippingTotal)
        #expect(before.profit - after.profit == shippingTotal)
    }

    /// 驗證三種付款旗標全部關閉時，無卡折抵與補款歸零，對帳狀態清空
    @Test
    func applyingPaymentMethodFlags_全部旗標關閉_清空無卡金額與對帳狀態() {
        // Given
        let order = makePaymentFlagOrder(
            cardlessDeductionAmount: 750,
            cardlessSupplementAmount: 250,
            reconciliationStatus: " 待對帳 ",
            isCardless: true
        )

        // When
        let corrected = order.applyingPaymentMethodFlags(.none)

        // Then
        #expect(corrected.cardlessDeductionAmount == 0)
        #expect(corrected.cardlessSupplementAmount == 0)
        #expect(corrected.reconciliationStatus == "")
    }

    /// 驗證改為銀行轉帳時保留對帳狀態，並去除前後空白
    @Test
    func applyingPaymentMethodFlags_改為銀行轉帳_保留對帳狀態() {
        // Given
        let order = makePaymentFlagOrder(reconciliationStatus: " 待對帳 ")

        // When
        let corrected = order.applyingPaymentMethodFlags(
            PaymentMethodFlags(isCardless: false, isBankTransfer: true, isCashOnDelivery: false)
        )

        // Then
        #expect(corrected.reconciliationStatus == "待對帳")
    }

    /// 驗證改為無卡時，折抵金額上限為實付金額，超過部分不計入折抵
    @Test
    func applyingPaymentMethodFlags_改為無卡且折抵超過實付_折抵上限為實付金額() {
        // Given
        let order = makePaymentFlagOrder(
            chargedAmount: 1_000,
            cardlessDeductionAmount: 1_500,
            isCardless: false
        )

        // When
        let corrected = order.applyingPaymentMethodFlags(
            PaymentMethodFlags(isCardless: true, isBankTransfer: false, isCashOnDelivery: false)
        )

        // Then
        #expect(corrected.cardlessDeductionAmount == 1_000)
        #expect(corrected.summary.revenue == 0)
    }

    /// 驗證非貨到付款時，貨到付款運費為零，運費不計入總成本
    @Test
    func init_非貨到付款_貨到付款運費為零() {
        // Given
        // 非貨到付款時運費不計入總成本
        let order = LedgerOrder(
            id: "BL-COD-002",
            customer: LedgerCustomer(name: "非貨到付款", initials: "NC", tier: .regular),
            status: .delivered,
            currency: .twd,
            date: Date(timeIntervalSince1970: 1_777_145_600),
            items: [LedgerOrderItem(name: "測試商品", quantity: 1, unitPrice: 5_000)],
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

        // When
        let summary = OrderSummary(order: order)

        // Then
        #expect(summary.codShippingCost == 0)
        #expect(summary.totalCost == 3_000)
        #expect(summary.profit == 2_000)
    }

    /// 驗證營收為零時，毛利率不計算，改顯示占位符號
    @Test
    func marginPercent_營收為零_顯示空值() {
        // Given
        let order = makeCardlessOrder(chargedAmount: 1_000, deduction: 1_000)
        let locale = Locale(identifier: "en")

        // When
        let summary = OrderSummary(order: order)

        // Then
        #expect(summary.revenue == 0)
        #expect(OrderFormatters.marginPercent(summary, locale: locale) == "—")
    }

    /// 驗證營收為正時毛利率以百分比格式顯示，實付 10,000 與商品成本 6,000 顯示為 40.0%
    @Test
    func marginPercent_營收為正_顯示百分比() {
        // Given
        let order = makeCardlessOrder(chargedAmount: 10_000, deduction: 0, itemCost: 6_000)
        let locale = Locale(identifier: "en")

        // When
        let summary = OrderSummary(order: order)

        // Then
        #expect(summary.revenue > 0)
        #expect(OrderFormatters.marginPercent(summary, locale: locale) == "40.0%")
    }

    /// 驗證舊資料營收為負時，毛利率顯示占位符號，不把兩負相除的結果當作百分比
    @Test
    func marginPercent_舊資料營收為負_顯示空值() {
        // Given
        // 舊資料的 revenue 可能為負，這時毛利率應保持空值
        let order = makeCardlessOrder(chargedAmount: 1_000, deduction: 1_500)

        // When
        let summary = OrderSummary(order: order)

        // Then
        #expect(summary.revenue == -500)
        #expect(summary.profit == -500)
        #expect(summary.margin == 1)  // 兩負相除得正：未經處理的呈現會顯示「100%」這個假數字
        #expect(OrderFormatters.marginPercent(summary, locale: Locale(identifier: "en")) == "—")
    }
}

// MARK: - Private Method

private extension OrderCalculationTests {

    /// 建立同時涵蓋三種付款旗標的測試訂單
    ///
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
    ///
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
