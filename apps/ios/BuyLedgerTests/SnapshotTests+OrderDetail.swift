//
//  SnapshotTests+OrderDetail.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/5.
//

import ComposableArchitecture
import SnapshotTesting
import SwiftUI
import Testing

@testable import BuyLedger

extension SnapshotTests {

    /// 訂單詳情的成本圖表把刷卡、平台、金流三種手續費分別列出
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
}
