//
//  OrdersRegularListContent.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/29.
//

import ComposableArchitecture
import SwiftUI

/// 寬版訂單清單欄的導覽列、搜尋與工具列
struct OrdersRegularListContent: View {

    // MARK: - Properties

    /// 訂單畫面的狀態與事件來源
    @Bindable var store: StoreOf<OrdersFeature>

    /// App 目前選用的顯示語系
    let language: AppLanguage

    // MARK: - Body

    /// 與 `OrdersView` regular 清單欄共用的內容及修飾
    var body: some View {
        listContent
    }
}

// MARK: - Private Views

private extension OrdersRegularListContent {

    /// 寬版清單欄與其搜尋及工具列；清單快照只取一次，清單與工具列共用
    var listContent: some View {
        @Bindable var listStore = store.scope(state: \.list, action: \.list)
        let snapshot = listStore.state.listSnapshot()

        return OrdersRegularListColumn(
            store: listStore,
            orders: snapshot.orders,
            selectedOrderID: store.selectedOrderID,
            selection: selection
        )
            .background(.blBackground)
            .task {
                listStore.send(.view(.task))
            }
            .blSearchable(
                text: $listStore.searchText.sending(\.view.searchTextChanged),
                prompt: Text("orders.list.placeholder.searchCustomersOrder")
            )
            .rootNavigationTitle("orders.list.title", language: language)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                OrdersToolbarContent(
                    isAllFilteredSelected: snapshot.isAllSelected,
                    filteredIDs: snapshot.ids,
                    store: listStore
                )
            }
            .alert(OrdersView.alertBinding(store: store, isDetail: false))
    }
}

// MARK: - Private Method

private extension OrdersRegularListContent {

    /// 讓原生清單選取直接投影到訂單詳情 `path`
    var selection: Binding<LedgerOrder.ID?>? {
        guard !store.list.isSelecting else {
            return nil
        }
        return Binding {
            store.selectedOrderID
        } set: {
            store.send(.view(.detailSelectionChanged($0)))
        }
    }
}

// MARK: - Preview

#Preview("寬版訂單清單") {
    let previewState: OrdersFeature.State = {
        let state = OrdersFeature.State(orders: LedgerOrder.sampleOrders)
        state.load.$hasLoaded.withLock {
            $0 = true
        }
        return state
    }()

    NavigationStack {
        OrdersRegularListContent(
            store: Store(initialState: previewState) {
                OrdersFeature()
            },
            language: .traditionalChinese
        )
    }
    .environment(\.horizontalSizeClass, .regular)
    .environment(\.verticalSizeClass, .regular)
}
