//
//  OrderCostBreakdownTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/7.
//

import Foundation
import Testing

@testable import BuyLedger

/// 訂單成本組成的金額、順序與語意色調測試
struct OrderCostBreakdownTests {

    /// 驗證一般訂單保留商品與三種手續費，排除三種運費
    @Test
    func components_一般訂單_不含運費() {
        // Given
        let order = LedgerOrder.fixture(
            date: TestDependencies.fixedNow,
            itemCost: 100,
            domesticShipping: 11,
            internationalShipping: 22,
            foreignDomesticShipping: 33,
            cardFeeRate: Decimal(1) / 100,
            platformFeeRate: Decimal(5) / 1_000,
            paymentFeeRate: Decimal(2) / 100,
            chargedAmount: 1_010
        )

        // When
        let components = OrderCostBreakdown.components(for: order)

        // Then
        #expect(
            components.map(\.title) == [
                "orders.detail.label.itemCost",
                "orders.detail.label.cardFee",
                "orders.detail.label.platformFee",
                "orders.detail.label.paymentProcessingFee",
            ]
        )
        #expect(components.map(\.value) == [100, Decimal(101) / 10, 6, Decimal(202) / 10])
        #expect(components.map(\.tone) == [.accent, .orange, .teal, .purple])
    }

    /// 驗證貨到付款的七項成本保留原始標題、金額與色調順序
    @Test
    func components_貨到付款_含三種運費與七種色調() {
        // Given
        let order = LedgerOrder.fixture(
            date: TestDependencies.fixedNow,
            itemCost: 100,
            domesticShipping: 11,
            internationalShipping: 22,
            foreignDomesticShipping: 33,
            cardFeeRate: Decimal(1) / 100,
            platformFeeRate: Decimal(2) / 100,
            paymentFeeRate: Decimal(3) / 100,
            chargedAmount: 1_000,
            isCashOnDelivery: true
        )
        let titles = [
            "orders.detail.label.itemCost",
            "orders.detail.label.cardFee",
            "orders.detail.label.platformFee",
            "orders.detail.label.paymentProcessingFee",
            "orders.detail.label.localShipping",
            "orders.detail.label.internationalShipping",
            "orders.detail.label.foreignLocalShipping",
        ]
        let tones: [OrderCostBreakdown.Tone] = [
            .accent,
            .orange,
            .teal,
            .purple,
            .indigo,
            .pink,
            .yellow,
        ]

        // When
        let components = OrderCostBreakdown.components(for: order)

        // Then
        #expect(components.map(\.title) == titles)
        #expect(components.map(\.id) == titles)
        #expect(components.map(\.value) == [100, 10, 20, 30, 11, 22, 33])
        #expect(components.map(\.tone) == tones)
    }

    /// 驗證零值與負值的成本項目不出現在拆解清單
    ///
    /// - Parameter value: 零或負的測試金額與費率
    @Test(arguments: [Decimal(0), Decimal(-1)])
    func components_非正值項目_全部篩掉(value: Decimal) {
        // Given
        let order = LedgerOrder.fixture(
            date: TestDependencies.fixedNow,
            itemCost: value,
            domesticShipping: value,
            internationalShipping: value,
            foreignDomesticShipping: value,
            cardFeeRate: value,
            platformFeeRate: value,
            paymentFeeRate: value,
            chargedAmount: 1,
            isCashOnDelivery: true
        )

        // When
        let components = OrderCostBreakdown.components(for: order)

        // Then
        #expect(components.isEmpty)
    }

    /// 驗證篩掉零值後仍保留正值項目的標題與對應色調
    @Test
    func components_零值與極小正值混合_只保留正值() {
        // Given
        let order = LedgerOrder.fixture(
            date: TestDependencies.fixedNow,
            itemCost: Decimal(1) / 100,
            internationalShipping: Decimal(1) / 100,
            paymentFeeRate: Decimal(1) / 100,
            chargedAmount: 1,
            isCashOnDelivery: true
        )

        // When
        let components = OrderCostBreakdown.components(for: order)

        // Then
        #expect(
            components.map(\.title) == [
                "orders.detail.label.itemCost",
                "orders.detail.label.paymentProcessingFee",
                "orders.detail.label.internationalShipping",
            ]
        )
        #expect(components.map(\.value) == [Decimal(1) / 100, Decimal(1) / 100, Decimal(1) / 100])
        #expect(components.map(\.tone) == [.accent, .purple, .pink])
    }

    /// 驗證圈狀圖區段依成本順序產生名稱、金額、本地化描述與語意色調
    @Test
    func donutSlices_多項成本_依序產生各區段的字面值() {
        // Given
        let components = Self.makeDonutComponents()
        let locale = Locale(identifier: "en")

        // When
        let slices = OrderCostBreakdown.donutSlices(for: components, locale: locale)

        // Then
        #expect(
            slices == [
                OrderCostBreakdown.DonutSlice(
                    label: "orders.detail.label.itemCost",
                    value: 1_200,
                    valueDescription: "NT$1,200",
                    tone: .accent
                ),
                OrderCostBreakdown.DonutSlice(
                    label: "orders.detail.label.cardFee",
                    value: 300,
                    valueDescription: "NT$300",
                    tone: .orange
                ),
            ]
        )
    }

    /// 驗證沒有成本項目時回傳空的區段清單
    @Test
    func donutSlices_沒有成本項目_回傳空陣列() {
        // Given
        let components: [OrderCostBreakdown.Component] = []
        let locale = Locale(identifier: "en")

        // When
        let slices = OrderCostBreakdown.donutSlices(for: components, locale: locale)

        // Then
        #expect(slices.isEmpty)
    }
}

// MARK: - Private Method

private extension OrderCostBreakdownTests {

    /// 建立商品金額與刷卡手續費兩項成本，供圈狀圖區段測試使用
    ///
    /// - Returns: 依商品金額、刷卡手續費順序排列的成本項目
    static func makeDonutComponents() -> [OrderCostBreakdown.Component] {
        [
            OrderCostBreakdown.Component(
                title: "orders.detail.label.itemCost",
                value: 1_200,
                tone: .accent
            ),
            OrderCostBreakdown.Component(
                title: "orders.detail.label.cardFee",
                value: 300,
                tone: .orange
            ),
        ]
    }
}
