//
//  InsightsAttributionTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/6/6.
//

import Foundation
import Testing
@testable import BuyLedger

@MainActor
struct InsightsAttributionTests {

    // MARK: - Tests

    @Test func categoryBreakdownAttributesPreMergeAmountsFromLeafOrders() {
        // spec「attribution matrix」：合併產生的訂單不入組，已合併葉端舊單以原始類別與金額入帳，報價中葉端不入組
        let orders = [
            Self.makeOrder(id: "A", status: .merged, categories: ["beauty"], charged: 1_000),
            Self.makeOrder(id: "B", status: .merged, categories: ["snacks"], charged: 2_000),
            Self.makeOrder(id: "M", status: .purchased, categories: ["beauty", "snacks"], charged: 3_000, mergedSourceIDs: ["A", "B"]),
            Self.makeOrder(id: "D", status: .quoting, categories: ["beauty"], charged: 400),
        ]

        let breakdown = InsightsView.categoryBreakdown(orders: orders)

        #expect(breakdown.map(\.name) == ["snacks", "beauty"])
        #expect(breakdown.first { $0.name == "beauty" }?.profit == 1_000)
        #expect(breakdown.first { $0.name == "snacks" }?.profit == 2_000)
    }

    @Test func chainedMergeStaysSingleCounted() {
        // spec「chained merge stays single-counted」：A+B → M1、M1+C → M2；beauty = A + C、snacks = B
        let orders = [
            Self.makeOrder(id: "A", status: .merged, categories: ["beauty"], charged: 1_000),
            Self.makeOrder(id: "B", status: .merged, categories: ["snacks"], charged: 2_000),
            Self.makeOrder(id: "M1", status: .merged, categories: ["beauty", "snacks"], charged: 3_000, mergedSourceIDs: ["A", "B"]),
            Self.makeOrder(id: "C", status: .merged, categories: ["beauty"], charged: 500),
            Self.makeOrder(id: "M2", status: .shipping, categories: ["beauty", "snacks"], charged: 3_500, mergedSourceIDs: ["M1", "C"]),
        ]

        let breakdown = InsightsView.categoryBreakdown(orders: orders)

        #expect(breakdown.first { $0.name == "beauty" }?.profit == 1_500)
        #expect(breakdown.first { $0.name == "snacks" }?.profit == 2_000)
    }

    @Test func orderRowCategoriesTagJoinsAndOmits() {
        // spec「category rendering by value」：多類別以「、」串接單一 capsule；空陣列與純空白不渲染
        #expect(OrderRowView.categoriesTagText(for: ["服飾"]) == "服飾")
        #expect(OrderRowView.categoriesTagText(for: ["服飾", "美妝"]) == "服飾、美妝")
        #expect(OrderRowView.categoriesTagText(for: []).isEmpty)
        #expect(OrderRowView.categoriesTagText(for: ["   "]).isEmpty)
    }

    @Test func multiCategoryLeafCountsFullyInEachCategoryAndEmptyIsExcluded() {
        // 防衛性規則：葉端多類別全額計入每一類；類別為空的葉端訂單不歸入任何卡片
        let orders = [
            Self.makeOrder(id: "C", status: .delivered, categories: ["beauty", "snacks"], charged: 900),
            Self.makeOrder(id: "E", status: .delivered, categories: [], charged: 700),
        ]

        let breakdown = InsightsView.categoryBreakdown(orders: orders)

        #expect(breakdown.map(\.name).sorted() == ["beauty", "snacks"])
        #expect(breakdown.allSatisfy { $0.profit == 900 })
    }
}

// MARK: - Helpers

private extension InsightsAttributionTests {

    /// 建立統計歸屬測試用的最小訂單；成本與費率皆 0，獲利即為 `charged`
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
            verificationStatus: "",
            campaignNames: [],
            paymentReceiptStatus: .pending,
            isCashOnDelivery: false,
            photos: [],
            mergedSourceIDs: mergedSourceIDs
        )
    }
}
