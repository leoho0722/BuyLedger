//
//  LedgerOrder+Samples.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import Foundation

extension LedgerOrder {

    // MARK: - Sample Data

    /// SwiftUI Preview、單元測試以及 ``OrderRepository/previewValue`` 使用的本機訂單範例。
    ///
    /// **runtime 不會自動 seed**——`OrderRepository.liveValue` 預設不填充 sample 資料，使用者首次啟動會看到空狀態，必須自行新增訂單。
    nonisolated static let sampleOrders: [LedgerOrder] = [
        LedgerOrder(
            id: "BL-2604-018",
            customer: LedgerCustomer(
                name: "林書宇",
                initials: "SY",
                tier: .vip
            ),
            status: .shipping,
            currency: .krw,
            date: sampleDate(year: 2026, month: 4, day: 26),
            items: [
                LedgerOrderItem(
                    name: "Tamburins 香水 Chamo 50ml",
                    quantity: 1,
                    unitPrice: 95_000
                ),
                LedgerOrderItem(
                    name: "Gentle Monster Her 02",
                    quantity: 1,
                    unitPrice: 295_000
                ),
            ],
            itemCost: decimal("390000") * decimal("0.0228"),
            domesticShipping: 80,
            internationalShipping: 320,
            foreignDomesticShipping: 0,
            cardFeeRate: decimal("0.015"),
            platformFeeRate: 0,
            paymentFeeRate: 0,
            chargedAmount: 11_800,
            cardlessDeductionAmount: 0,
            cardlessSupplementAmount: 0,
            orderSource: "蝦皮",
            categories: ["美妝"],
            paymentMethod: "信用卡",
            notes: "客戶指定到貨後先拍照確認，再安排出貨。",
            verificationStatus: "",
            campaignNames: [],
            paymentReceiptStatus: .pending,
            isCashOnDelivery: false,
            photos: [],
            mergedSourceIDs: []
        ),
        LedgerOrder(
            id: "BL-2604-017",
            customer: LedgerCustomer(
                name: "Mika 周",
                initials: "MZ",
                tier: .regular
            ),
            status: .purchased,
            currency: .jpy,
            date: sampleDate(year: 2026, month: 4, day: 24),
            items: [
                LedgerOrderItem(
                    name: "Snidel 春季針織外套 (M)",
                    quantity: 1,
                    unitPrice: 18_700
                ),
            ],
            itemCost: decimal("18700") * decimal("0.2105"),
            domesticShipping: 0,
            internationalShipping: 380,
            foreignDomesticShipping: 0,
            cardFeeRate: decimal("0.015"),
            platformFeeRate: 0,
            paymentFeeRate: 0,
            chargedAmount: 4_980,
            cardlessDeductionAmount: 0,
            cardlessSupplementAmount: 0,
            orderSource: "官方網站",
            categories: ["服飾"],
            paymentMethod: "銀行轉帳",
            notes: "",
            verificationStatus: "",
            campaignNames: [],
            paymentReceiptStatus: .pending,
            isCashOnDelivery: false,
            photos: [],
            mergedSourceIDs: []
        ),
        LedgerOrder(
            id: "BL-2604-016",
            customer: LedgerCustomer(
                name: "Ariel 陳",
                initials: "AC",
                tier: .regular
            ),
            status: .delivered,
            currency: .krw,
            date: sampleDate(year: 2026, month: 4, day: 22),
            items: [
                LedgerOrderItem(
                    name: "Aesop Rōzu Eau de Parfum 50ml",
                    quantity: 1,
                    unitPrice: 220_000
                ),
                LedgerOrderItem(
                    name: "Hera Black Cushion #21",
                    quantity: 2,
                    unitPrice: 68_000
                ),
            ],
            itemCost: decimal("356000") * decimal("0.0228"),
            domesticShipping: 0,
            internationalShipping: 290,
            foreignDomesticShipping: 0,
            cardFeeRate: decimal("0.015"),
            platformFeeRate: decimal("0.03"),
            paymentFeeRate: 0,
            chargedAmount: 9_890,
            cardlessDeductionAmount: 0,
            cardlessSupplementAmount: 0,
            orderSource: "Instagram",
            categories: ["美妝"],
            paymentMethod: "信用卡",
            notes: "",
            verificationStatus: "",
            campaignNames: [],
            paymentReceiptStatus: .pending,
            isCashOnDelivery: false,
            photos: [],
            mergedSourceIDs: []
        ),
        LedgerOrder(
            id: "BL-2604-015",
            customer: LedgerCustomer(
                name: "Joyce 黃",
                initials: "JH",
                tier: .vip
            ),
            status: .quoting,
            currency: CurrencyCode(rawValue: "EUR"),
            date: sampleDate(year: 2026, month: 4, day: 21),
            items: [
                LedgerOrderItem(
                    name: "Polène Numéro Un Nano 米色",
                    quantity: 1,
                    unitPrice: 390
                ),
            ],
            itemCost: decimal("390") * decimal("35.2"),
            domesticShipping: 0,
            internationalShipping: 850,
            foreignDomesticShipping: 0,
            cardFeeRate: decimal("0.015"),
            platformFeeRate: 0,
            paymentFeeRate: 0,
            chargedAmount: 0,
            cardlessDeductionAmount: 0,
            cardlessSupplementAmount: 0,
            orderSource: "代購社團",
            categories: ["精品"],
            paymentMethod: "",
            notes: "報價中，待客戶確認顏色後再下單。",
            verificationStatus: "",
            campaignNames: [],
            paymentReceiptStatus: .pending,
            isCashOnDelivery: false,
            photos: [],
            mergedSourceIDs: []
        ),
        LedgerOrder(
            id: "BL-2604-014",
            customer: LedgerCustomer(
                name: "Vivi 王",
                initials: "VW",
                tier: .regular
            ),
            status: .confirmed,
            currency: .jpy,
            date: sampleDate(year: 2026, month: 4, day: 20),
            items: [
                LedgerOrderItem(
                    name: "Sulwhasoo 滋陰生 60ml",
                    quantity: 1,
                    unitPrice: 27_000
                ),
                LedgerOrderItem(
                    name: "Innisfree 綠茶精華 80ml",
                    quantity: 1,
                    unitPrice: 4_500
                ),
            ],
            itemCost: decimal("31500") * decimal("0.2105"),
            domesticShipping: 250,
            internationalShipping: 320,
            foreignDomesticShipping: 0,
            cardFeeRate: decimal("0.015"),
            platformFeeRate: 0,
            paymentFeeRate: 0,
            chargedAmount: 8_650,
            cardlessDeductionAmount: 0,
            cardlessSupplementAmount: 0,
            orderSource: "蝦皮",
            categories: ["美妝"],
            paymentMethod: "LINE Pay",
            notes: "已收訂金，尾款到貨後結清。",
            verificationStatus: "",
            campaignNames: [],
            paymentReceiptStatus: .pending,
            isCashOnDelivery: false,
            photos: [],
            mergedSourceIDs: []
        ),
        LedgerOrder(
            id: "BL-2604-013",
            customer: LedgerCustomer(name: "Iris 楊", initials: "IY", tier: .new),
            status: .delivered,
            currency: .usd,
            date: sampleDate(year: 2026, month: 4, day: 18),
            items: [
                LedgerOrderItem(
                    name: "Le Labo Santal 33 50ml",
                    quantity: 1,
                    unitPrice: 218
                ),
            ],
            itemCost: decimal("218") * decimal("32.45"),
            domesticShipping: 0,
            internationalShipping: 380,
            foreignDomesticShipping: 0,
            cardFeeRate: decimal("0.015"),
            platformFeeRate: decimal("0.03"),
            paymentFeeRate: 0,
            chargedAmount: 8_420,
            cardlessDeductionAmount: 0,
            cardlessSupplementAmount: 0,
            orderSource: "官方網站",
            categories: ["美妝"],
            paymentMethod: "Apple Pay",
            notes: "",
            verificationStatus: "",
            campaignNames: [],
            paymentReceiptStatus: .pending,
            isCashOnDelivery: false,
            photos: [],
            mergedSourceIDs: []
        ),
        LedgerOrder(
            id: "BL-2604-012",
            customer: LedgerCustomer(
                name: "林書宇",
                initials: "SY",
                tier: .vip
            ),
            status: .delivered,
            currency: .krw,
            date: sampleDate(year: 2026, month: 4, day: 15),
            items: [
                LedgerOrderItem(
                    name: "Adererror 標準 Logo Tee 黑",
                    quantity: 2,
                    unitPrice: 89_000
                ),
            ],
            itemCost: decimal("178000") * decimal("0.0228"),
            domesticShipping: 60,
            internationalShipping: 280,
            foreignDomesticShipping: 0,
            cardFeeRate: decimal("0.015"),
            platformFeeRate: 0,
            paymentFeeRate: 0,
            chargedAmount: 5_680,
            cardlessDeductionAmount: 0,
            cardlessSupplementAmount: 0,
            orderSource: "Instagram",
            categories: ["服飾"],
            paymentMethod: "信用卡",
            notes: "",
            verificationStatus: "",
            campaignNames: [],
            paymentReceiptStatus: .pending,
            isCashOnDelivery: false,
            photos: [],
            mergedSourceIDs: []
        ),
        LedgerOrder(
            id: "BL-2604-011",
            customer: LedgerCustomer(
                name: "Mika 周",
                initials: "MZ",
                tier: .regular
            ),
            status: .shipping,
            currency: .krw,
            date: sampleDate(year: 2026, month: 4, day: 12),
            items: [
                LedgerOrderItem(
                    name: "Hince 絲絨唇釉 #07",
                    quantity: 1,
                    unitPrice: 22_000
                ),
                LedgerOrderItem(
                    name: "Matin Kim 寬版牛仔褲 (S)",
                    quantity: 1,
                    unitPrice: 79_000
                ),
            ],
            itemCost: decimal("101000") * decimal("0.0228"),
            domesticShipping: 60,
            internationalShipping: 300,
            foreignDomesticShipping: 0,
            cardFeeRate: decimal("0.015"),
            platformFeeRate: 0,
            paymentFeeRate: 0,
            chargedAmount: 4_360,
            cardlessDeductionAmount: 0,
            cardlessSupplementAmount: 0,
            orderSource: "Instagram",
            categories: ["美妝", "服飾"],
            paymentMethod: "信用卡",
            notes: "原訂單 A 備註。\n----------\n原訂單 B 備註。",
            verificationStatus: "",
            campaignNames: ["四月韓國團", "三月日本團"],
            paymentReceiptStatus: .pending,
            isCashOnDelivery: false,
            photos: [],
            mergedSourceIDs: ["BL-2603-905", "BL-2603-906"]
        ),
    ]
}

// MARK: - Private Method

private extension LedgerOrder {

    /// 建立固定時區的範例日期。
    /// - Parameters:
    ///   - year: 年份。
    ///   - month: 月份。
    ///   - day: 日期。
    /// - Returns: 可重現的範例日期。
    nonisolated static func sampleDate(year: Int, month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.calendar = Calendar(identifier: .gregorian)
        components.timeZone = TimeZone(secondsFromGMT: 0)
        components.year = year
        components.month = month
        components.day = day

        return components.date ?? Date(timeIntervalSince1970: 0)
    }

    /// 將固定範例資料字串轉為 `Decimal`。
    /// - Parameter value: 十進位數字字串。
    /// - Returns: 可用於金額計算的十進位數值。
    nonisolated static func decimal(_ value: String) -> Decimal {
        Decimal(string: value, locale: Locale(identifier: "en_US_POSIX")) ?? 0
    }
}
