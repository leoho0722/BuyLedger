//
//  InsightsAttributionTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/6/6.
//

import Foundation
import Testing

@testable import BuyLedger

/// 驗證分析歸屬計算
@MainActor
struct InsightsAttributionTests {

    /// 只計入被合併的原始訂單金額，排除新訂單與報價單
    @Test
    func categoryBreakdown_合併訂單與報價單_只計被合併的原始訂單() {
        // Given
        let orders = [
            Self.makeOrder(
                id: "A",
                status: .merged,
                categories: ["beauty"],
                charged: 1_000
            ),
            Self.makeOrder(
                id: "B",
                status: .merged,
                categories: ["snacks"],
                charged: 2_000
            ),
            Self.makeOrder(
                id: "M",
                status: .purchased,
                categories: ["beauty", "snacks"],
                charged: 3_000,
                mergedSourceIDs: ["A", "B"]
            ),
            Self.makeOrder(
                id: "D",
                status: .quoting,
                categories: ["beauty"],
                charged: 400
            ),
        ]

        // When
        let breakdown = InsightsStats.categoryBreakdown(orders: orders)

        // Then
        #expect(breakdown.map(\.name) == ["snacks", "beauty"])
        #expect(breakdown.first { $0.name == "beauty" }?.profit == 1_000)
        #expect(breakdown.first { $0.name == "snacks" }?.profit == 2_000)
    }

    /// 連續合併後各原始訂單仍只計一次，beauty 為 A 加 C，snacks 為 B
    @Test
    func categoryBreakdown_連續合併_各原始訂單只計一次() {
        // Given
        let orders = [
            Self.makeOrder(
                id: "A",
                status: .merged,
                categories: ["beauty"],
                charged: 1_000
            ),
            Self.makeOrder(
                id: "B",
                status: .merged,
                categories: ["snacks"],
                charged: 2_000
            ),
            Self.makeOrder(
                id: "M1",
                status: .merged,
                categories: ["beauty", "snacks"],
                charged: 3_000,
                mergedSourceIDs: ["A", "B"]
            ),
            Self.makeOrder(
                id: "C",
                status: .merged,
                categories: ["beauty"],
                charged: 500
            ),
            Self.makeOrder(
                id: "M2",
                status: .shipping,
                categories: ["beauty", "snacks"],
                charged: 3_500,
                mergedSourceIDs: ["M1", "C"]
            ),
        ]

        // When
        let breakdown = InsightsStats.categoryBreakdown(orders: orders)

        // Then
        #expect(breakdown.first { $0.name == "beauty" }?.profit == 1_500)
        #expect(breakdown.first { $0.name == "snacks" }?.profit == 2_000)
    }

    /// 多個類別以頓號串接成單一文字，空陣列與空白項目不顯示
    ///
    /// - Parameters:
    ///   - categories: 商品類別
    ///   - expected: 預期顯示的標籤文字
    @Test(arguments: [
        (categories: ["服飾"], expected: "服飾"),
        (categories: ["服飾", "美妝"], expected: "服飾、美妝"),
        (categories: [String](), expected: ""),
        (categories: ["   "], expected: ""),
    ])
    func categoriesTagText_類別數量與空白_頓號串接或省略(categories: [String], expected: String) {
        // Given

        // When
        let text = OrderFormatters.categoriesTagText(for: categories)

        // Then
        #expect(text == expected)
    }

    /// 原始訂單的多個類別各自完整計入，沒有類別的訂單不歸入任何類別
    @Test
    func categoryBreakdown_多類別與無類別訂單_各類別完整計入無類別排除() {
        // Given
        let orders = [
            Self.makeOrder(
                id: "C",
                status: .delivered,
                categories: ["beauty", "snacks"],
                charged: 900
            ),
            Self.makeOrder(
                id: "E",
                status: .delivered,
                categories: [],
                charged: 700
            ),
        ]

        // When
        let breakdown = InsightsStats.categoryBreakdown(orders: orders)

        // Then
        #expect(breakdown.map(\.name).sorted() == ["beauty", "snacks"])
        #expect(breakdown.allSatisfy { $0.profit == 900 })
    }
}

// MARK: - Private Method

private extension InsightsAttributionTests {

    /// 建立統計歸屬測試用的最小訂單；成本與費率皆 0，獲利即為 `charged`
    ///
    /// - Parameters:
    ///   - id: 訂單識別值
    ///   - status: 訂單狀態
    ///   - categories: 商品類別
    ///   - charged: 客戶實付金額
    ///   - mergedSourceIDs: 被合併的來源訂單編號
    /// - Returns: 建立的測試訂單
    static func makeOrder(
        id: String,
        status: OrderStatus,
        categories: [String],
        charged: Decimal,
        mergedSourceIDs: [String] = []
    ) -> LedgerOrder {
        LedgerOrder(
            id: id,
            customer: LedgerCustomer(name: "客戶", initials: "XX", tier: .regular),
            status: status,
            currency: .twd,
            date: Date(timeIntervalSince1970: 0),
            items: [],
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
            orderSource: "蝦皮",
            categories: categories,
            paymentMethod: "信用卡",
            notes: "",
            reconciliationStatus: "",
            campaignNames: [],
            paymentReceiptStatus: .pending,
            isCashOnDelivery: false,
            photos: [],
            mergedSourceIDs: mergedSourceIDs
        )
    }
}
