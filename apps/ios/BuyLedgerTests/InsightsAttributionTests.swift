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
    
    // MARK: - Tests
    
    @Test func categoryBreakdownAttributesPreMergeAmountsFromLeafOrders() {
        // 只計入被合併的原始訂單，排除新訂單與報價單
        let orders = [
            Self.makeOrder(id: "A", status: .merged, categories: ["beauty"], charged: 1_000),
            Self.makeOrder(id: "B", status: .merged, categories: ["snacks"], charged: 2_000),
            Self.makeOrder(
                id: "M", status: .purchased, categories: ["beauty", "snacks"], charged: 3_000,
                mergedSourceIDs: ["A", "B"]),
            Self.makeOrder(id: "D", status: .quoting, categories: ["beauty"], charged: 400),
        ]
        
        let breakdown = InsightsStats.categoryBreakdown(orders: orders)
        
        #expect(breakdown.map(\.name) == ["snacks", "beauty"])
        #expect(breakdown.first { $0.name == "beauty" }?.profit == 1_000)
        #expect(breakdown.first { $0.name == "snacks" }?.profit == 2_000)
    }
    
    @Test func chainedMergeStaysSingleCounted() {
        // 連續合併仍只計一次：beauty = A + C、snacks = B
        let orders = [
            Self.makeOrder(id: "A", status: .merged, categories: ["beauty"], charged: 1_000),
            Self.makeOrder(id: "B", status: .merged, categories: ["snacks"], charged: 2_000),
            Self.makeOrder(
                id: "M1", status: .merged, categories: ["beauty", "snacks"], charged: 3_000,
                mergedSourceIDs: ["A", "B"]),
            Self.makeOrder(id: "C", status: .merged, categories: ["beauty"], charged: 500),
            Self.makeOrder(
                id: "M2", status: .shipping, categories: ["beauty", "snacks"], charged: 3_500,
                mergedSourceIDs: ["M1", "C"]),
        ]
        
        let breakdown = InsightsStats.categoryBreakdown(orders: orders)
        
        #expect(breakdown.first { $0.name == "beauty" }?.profit == 1_500)
        #expect(breakdown.first { $0.name == "snacks" }?.profit == 2_000)
    }
    
    @Test func orderRowCategoriesTagJoinsAndOmits() {
        // 多類別以「、」串接單一 capsule，空陣列與空白不顯示
        #expect(OrderRowView.categoriesTagText(for: ["服飾"]) == "服飾")
        #expect(OrderRowView.categoriesTagText(for: ["服飾", "美妝"]) == "服飾、美妝")
        #expect(OrderRowView.categoriesTagText(for: []).isEmpty)
        #expect(OrderRowView.categoriesTagText(for: ["   "]).isEmpty)
    }
    
    @Test func multiCategoryLeafCountsFullyInEachCategoryAndEmptyIsExcluded() {
        // 原始訂單的多個類別各自完整計入，無類別時不歸入卡片。
        let orders = [
            Self.makeOrder(
                id: "C", status: .delivered, categories: ["beauty", "snacks"], charged: 900),
            Self.makeOrder(id: "E", status: .delivered, categories: [], charged: 700),
        ]
        
        let breakdown = InsightsStats.categoryBreakdown(orders: orders)
        
        #expect(breakdown.map(\.name).sorted() == ["beauty", "snacks"])
        #expect(breakdown.allSatisfy { $0.profit == 900 })
    }
}

// MARK: - Helpers

private extension InsightsAttributionTests {
    
    /// 建立統計歸屬測試用的最小訂單；成本與費率皆 0，獲利即為 `charged`
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
