//
//  OrderDetailToolbarContent.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/20.
//

import ComposableArchitecture
import SwiftUI

/// 訂單詳情的狀態與更多操作工具列
struct OrderDetailToolbarContent: ToolbarContent {

    // MARK: - Properties

    /// 提供操作選項與委派入口的詳情 store
    let store: StoreOf<OrderDetailFeature>

    // MARK: - Body

    /// 顯示狀態更新與更多操作選單
    var body: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            OrderDetailMenu(kind: .status, store: store)
        }

        ToolbarItem(placement: .primaryAction) {
            OrderDetailMenu(kind: .more, store: store)
        }
    }
}

// MARK: - Preview

#Preview("訂單詳情工具列") {
    NavigationStack {
        Color.clear
            .toolbar {
                OrderDetailToolbarContent(
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
}
