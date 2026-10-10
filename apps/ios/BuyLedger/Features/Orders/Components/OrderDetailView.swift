//
//  OrderDetailView.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import ComposableArchitecture
import SwiftUI

/// 訂單詳情與成本拆解，內容從唯讀的 `OrderDetailFeature` 取得
struct OrderDetailView: View {

    // MARK: - Properties

    /// 畫面的狀態與事件來源，由父層建立後傳入
    let store: StoreOf<OrderDetailFeature>

    /// 詳情頁的版面樣式，預設採用窄欄版面
    var layout: OrderDetailLayout = .compact

    // MARK: - Body

    /// 詳情區段的畫面骨架
    var body: some View {
        if let order = store.order {
            OrderDetailContentView(
                campaignNamesText: store.campaignNamesText,
                categoriesText: store.categoriesText,
                costComponents: store.costComponents,
                hasCardlessAdjustments: store.hasCardlessAdjustments,
                hasCostBreakdown: store.hasCostBreakdown,
                hasNotes: store.hasNotes,
                layout: layout,
                order: order,
                orderSourceText: store.orderSourceText
            )
        }
    }
}

// MARK: - Nested Types

extension OrderDetailView {

    /// 訂單詳情採用的版面樣式
    enum OrderDetailLayout {

        /// iPhone 推入詳情的窄欄
        case compact

        /// iPad 右欄的寬欄
        case wide
    }
}

// MARK: - Preview

#Preview("訂單詳情 · 窄欄") {
    NavigationStack {
        OrderDetailView(
            store: Store(
                initialState: OrderDetailFeature.State(
                    orderID: LedgerOrder.sampleOrders[0].id,
                    orders: SharedReader(value: LedgerOrder.sampleOrders)
                )
            ) {
                OrderDetailFeature()
            }
        )
    }
}

#Preview("訂單詳情 · 寬欄") {
    OrderDetailView(
        store: Store(
            initialState: OrderDetailFeature.State(
                orderID: LedgerOrder.sampleOrders[0].id,
                orders: SharedReader(value: LedgerOrder.sampleOrders)
            )
        ) {
            OrderDetailFeature()
        },
        layout: .wide
    )
    .frame(width: 720, height: 720)
}
