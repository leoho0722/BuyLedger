//
//  SnapshotOrderDetailTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/5.
//

import ComposableArchitecture
import SnapshotTesting
import SwiftUI
import Testing

@testable import BuyLedger

/// `OrderDetailView` 的快照測試，涵蓋成本明細區段的內容
@MainActor
struct SnapshotOrderDetailTests {

    /// 驗證訂單詳情的成本明細把刷卡、平台、金流三種手續費分別列出，畫面符合基準圖
    ///
    /// - Throws: 手續費字面值無法轉成 `Decimal` 時由 `#require` 丟出
    @Test
    func orderDetailView_成本明細內容_符合基準圖() throws {
        try TestDependencies.withFixedNow {
            // Given
            let cardFeeRate = try #require(Decimal(string: "0.015"))
            let platformFeeRate = try #require(Decimal(string: "0.03"))
            let paymentFeeRate = try #require(Decimal(string: "0.005"))
            let order = LedgerOrder(
                id: "BL-FEE-SNAP-001",
                customer: LedgerCustomer(name: "手續費拆解", initials: "FB", tier: .vip),
                status: .delivered,
                currency: .jpy,
                date: Date(timeIntervalSince1970: 1_777_145_600),
                items: [
                    LedgerOrderItem(name: "示範商品", quantity: 1, unitPrice: 30_000),
                ],
                itemCost: Decimal(6_000),
                domesticShipping: 0,
                internationalShipping: 0,
                foreignDomesticShipping: 0,
                cardFeeRate: cardFeeRate,
                platformFeeRate: platformFeeRate,
                paymentFeeRate: paymentFeeRate,
                chargedAmount: Decimal(10_000),
                cardlessDeductionAmount: 0,
                cardlessSupplementAmount: 0,
                orderSource: "示範",
                categories: ["美妝"],
                paymentMethod: "信用卡",
                notes: "",
                reconciliationStatus: "",
                campaignNames: [],
                paymentReceiptStatus: .pending,
                isCashOnDelivery: false,
                photos: [],
                mergedSourceIDs: []
            )
            let state = OrderDetailFeature.State(
                orderID: order.id,
                orders: SharedReader(value: [order])
            )

            // When
            let view = OrderDetailView(
                store: Store(initialState: state) {
                    OrderDetailFeature()
                }
            )
                .environment(\.locale, AppLanguage.traditionalChinese.locale)
                .frame(width: 393, height: 852)

            // Then
            assertSnapshot(of: view, as: .image)
        }
    }

    /// 驗證 393 點寬最大輔助字級下，詳情標頭與卡片都留在內容區內
    ///
    /// - Throws: 找不到樣本訂單時由 `#require` 丟出
    /// - Note: 使用訂單 BL-2604-017 重現日圓標頭
    /// - Note: 以 1800 點高度納入下方卡片
    @Test
    func orderDetailView_393點寬最大輔助字級_標頭與卡片留在畫面內() throws {
        try TestDependencies.withFixedNow {
            // Given
            let order = try #require(
                LedgerOrder.sampleOrders.first {
                    $0.id == "BL-2604-017"
                }
            )
            let state = OrderDetailFeature.State(
                orderID: order.id,
                orders: SharedReader(value: [order])
            )

            // When
            let view = OrderDetailView(
                store: Store(initialState: state) {
                    OrderDetailFeature()
                }
            )
                .environment(\.locale, AppLanguage.traditionalChinese.locale)
                .environment(\.dynamicTypeSize, .accessibility5)
                .frame(width: 393, height: 1800)

            // Then
            assertSnapshot(of: view, as: .image)
        }
    }

    /// 驗證成本卡圓餅圖與中心文字在卡片內，畫面符合基準圖
    ///
    /// - Throws: 找不到樣本訂單時由 `#require` 丟出
    /// - Note: 使用訂單 BL-2604-017 的完整成本明細
    /// - Note: 快照高度為 1800 點，納入圖下方的中心文字與完整圖例
    @Test
    func orderDetailCostView_393點寬最大輔助字級_成本卡圓餅圖與中心文字在卡片內() throws {
        try TestDependencies.withFixedNow {
            // Given
            let order = try #require(
                LedgerOrder.sampleOrders.first {
                    $0.id == "BL-2604-017"
                }
            )
            let detail = OrderDetailFeature.State(
                orderID: order.id,
                orders: SharedReader(value: [order])
            )

            // When
            let view = OrderDetailCostView(components: detail.costComponents, order: order)
                .environment(\.locale, AppLanguage.traditionalChinese.locale)
                .environment(\.dynamicTypeSize, .accessibility5)
                .frame(width: 393, height: 1800, alignment: .top)

            // Then
            assertSnapshot(of: view, as: .image)
        }
    }

    /// 驗證頁面內容寬 361 點 (393 點扣左右各 16 點邊距) 的最大輔助字級下，成本圖例與商品明細的金額保持單行不斷字
    ///
    /// - Throws: 找不到樣本訂單時由 `#require` 丟出
    /// - Note: 使用訂單 BL-2604-017，圖例與商品明細依頁面相同的順序與間距排列
    /// - Note: 快照高度為 1800 點，納入成本圖例與商品明細
    @Test
    func orderDetailSections_頁面內容寬361最大輔助字級_成本圖例與商品金額不斷字() throws {
        try TestDependencies.withFixedNow {
            // Given
            let order = try #require(
                LedgerOrder.sampleOrders.first {
                    $0.id == "BL-2604-017"
                }
            )
            let detail = OrderDetailFeature.State(
                orderID: order.id,
                orders: SharedReader(value: [order])
            )

            // When
            let view = VStack(alignment: .leading, spacing: BLSpacing.large) {
                OrderDetailCostView(components: detail.costComponents, order: order)
                    .frame(maxWidth: .infinity, alignment: .leading)

                OrderDetailItemsView(order: order)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(width: 361, height: 1800, alignment: .top)
            .environment(\.locale, AppLanguage.traditionalChinese.locale)
            .environment(\.dynamicTypeSize, .accessibility5)

            // Then
            assertSnapshot(of: view, as: .image)
        }
    }

    /// 驗證頁面內容寬 361 點的最大輔助字級下，大額外幣的成本圖例與商品小計完整顯示，金額不被卡片裁切
    ///
    /// - Throws: 手續費字面值無法轉成 `Decimal` 時由 `#require` 丟出
    /// - Note: 以訂單 BL-2604-017 為底，改為韓元並把商品成本與小計設為 12,345,678
    /// - Note: 快照高度為 1800 點，納入大額金額的完整列
    @Test
    func orderDetailSections_頁面內容寬361最大輔助字級_大額金額完整不裁切() throws {
        try TestDependencies.withFixedNow {
            // Given
            let cardFeeRate = try #require(Decimal(string: "0.015"))
            let order = LedgerOrder(
                id: "BL-2604-017",
                customer: LedgerCustomer(name: "Mika 周", initials: "MZ", tier: .regular),
                status: .purchased,
                currency: .krw,
                date: Date(timeIntervalSince1970: 1_777_145_600),
                items: [
                    LedgerOrderItem(
                        id: UUID(0),
                        name: "Snidel 春季針織外套 (M)",
                        quantity: 1,
                        unitPrice: 12_345_678
                    ),
                ],
                itemCost: Decimal(12_345_678),
                domesticShipping: 0,
                internationalShipping: 380,
                foreignDomesticShipping: 0,
                cardFeeRate: cardFeeRate,
                platformFeeRate: 0,
                paymentFeeRate: 0,
                chargedAmount: 4_980,
                cardlessDeductionAmount: 0,
                cardlessSupplementAmount: 0,
                orderSource: "官方網站",
                categories: ["服飾"],
                paymentMethod: "銀行轉帳",
                notes: "",
                reconciliationStatus: "",
                campaignNames: [],
                paymentReceiptStatus: .pending,
                isCashOnDelivery: false,
                photos: [],
                mergedSourceIDs: []
            )
            let detail = OrderDetailFeature.State(
                orderID: order.id,
                orders: SharedReader(value: [order])
            )

            // When
            let view = VStack(alignment: .leading, spacing: BLSpacing.large) {
                OrderDetailCostView(components: detail.costComponents, order: order)
                    .frame(maxWidth: .infinity, alignment: .leading)

                OrderDetailItemsView(order: order)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(width: 361, height: 1800, alignment: .top)
            .environment(\.locale, AppLanguage.traditionalChinese.locale)
            .environment(\.dynamicTypeSize, .accessibility5)

            // Then
            assertSnapshot(of: view, as: .image)
        }
    }
}
