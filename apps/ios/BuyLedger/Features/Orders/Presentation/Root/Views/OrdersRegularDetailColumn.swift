//
//  OrdersRegularDetailColumn.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/5.
//

import ComposableArchitecture
import SwiftUI

/// regular 版面三欄中的訂單詳情欄
struct OrdersRegularDetailColumn: View {

    // MARK: - Properties

    /// 畫面的狀態與事件來源，由父層建立後傳入
    @Bindable var store: StoreOf<OrdersFeature>

    // MARK: - Body

    /// `path` 詳情仍存在時顯示共用詳情畫面，否則顯示選擇提示
    var body: some View {
        if let pathID = store.detail.path.ids.last,
           let detailStore = store.scope(
               state: \.detail.path[id: pathID, case: \.detail],
               action: \.detail.path[id: pathID].detail
           ),
           detailStore.order != nil {
            OrderDetailView(store: detailStore)
        } else {
            emptyState
        }
    }
}

// MARK: - Private Views

private extension OrdersRegularDetailColumn {

    /// `path` 沒有可顯示訂單時的選擇提示
    var emptyState: some View {
        ContentUnavailableView(
            "orders.edit.label.selectOrders",
            systemImage: "list.bullet.rectangle"
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.blBackground)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(BLAccessibilityID.Orders.detailEmptyState)
    }
}

// MARK: - Preview

#Preview("訂單詳情欄") {
    let previewState: OrdersFeature.State = {
        var state = OrdersFeature.State(orders: LedgerOrder.sampleOrders)
        state.load.$hasLoaded.withLock {
            $0 = true
        }
        if let orderID = LedgerOrder.sampleOrders.first?.id {
            state.detail.showDetail(orderID: orderID)
        }
        return state
    }()

    NavigationStack {
        OrdersRegularDetailColumn(
            store: Store(initialState: previewState) {
                OrdersFeature()
            }
        )
    }
}
