//
//  OrderCompactDetailView.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import SwiftUI

/// 推入的訂單詳情與工具列
struct OrderCompactDetailView: View {

    // MARK: - Properties

    /// 推入路徑提供的詳情 store
    let store: StoreOf<OrderDetailFeature>

    // MARK: - Body

    /// 詳情區段的畫面骨架
    var body: some View {
        if let order = store.order {
            OrderDetailView(store: store)
                .navigationTitle(Text(verbatim: order.customer.name))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        OrderDetailMenu(kind: .status, layout: .compact, store: store)
                    }

                    ToolbarItem(placement: .primaryAction) {
                        OrderDetailMenu(kind: .more, layout: .compact, store: store)
                    }
                }
        }
    }
}

// MARK: - Preview

#Preview("推入訂單詳情") {
    NavigationStack {
        OrderCompactDetailView(
            store: Store(initialState: OrderDetailFeature.State(
                orderID: LedgerOrder.sampleOrders[0].id,
                orders: SharedReader(value: LedgerOrder.sampleOrders)
            )) {
                OrderDetailFeature()
            }
        )
    }
}
