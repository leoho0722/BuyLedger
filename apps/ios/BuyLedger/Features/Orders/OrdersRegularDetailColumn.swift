//
//  OrdersRegularDetailColumn.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/5.
//

import ComposableArchitecture
import SwiftUI

/// 寬版 (iPad 全螢幕) 訂單瀏覽的詳情欄，以系統導覽列顯示選取訂單的客戶名稱與操作選單
struct OrdersRegularDetailColumn: View {

    // MARK: - Properties

    /// 畫面的狀態與事件來源，由父層建立後傳入
    @Bindable var store: StoreOf<OrdersFeature>

    // MARK: - Body

    /// 有選取的訂單時顯示詳情，沒有時顯示選擇提示
    var body: some View {
        if let detailStore = store.scope(
            state: \.detail.regularDetail,
            action: \.detail.regularDetail
        ),
           let order = detailStore.order {
            detail(order: order, store: detailStore)
        } else {
            emptyState
        }
    }
}

// MARK: - Private Views

private extension OrdersRegularDetailColumn {

    /// 沒有可顯示的選取訂單時的選擇提示
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

    /// 選取訂單的詳情與系統導覽列
    ///
    /// - Parameters:
    ///   - order: 要顯示的訂單
    ///   - store: 右欄詳情的狀態與互動入口
    /// - Returns: 詳情 view
    func detail(order: LedgerOrder, store: StoreOf<OrderDetailFeature>) -> some View {
        OrderDetailView(store: store, layout: .wide)
            .navigationTitle(Text(verbatim: order.customer.name))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                OrderDetailToolbarContent(store: store)
            }
    }
}

// MARK: - Preview

#Preview("訂單詳情欄") {
    let previewState: OrdersFeature.State = {
        var state = OrdersFeature.State(orders: LedgerOrder.sampleOrders)
        state.load.$hasLoaded.withLock {
            $0 = true
        }
        state.list.selectedOrderID = LedgerOrder.sampleOrders.first?.id
        state.detail.syncRegularDetail(selectedOrderID: state.list.selectedOrderID)
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
