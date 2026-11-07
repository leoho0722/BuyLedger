//
//  OrdersCompactView.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import ComposableArchitecture
import SwiftUI

/// 窄版訂單瀏覽的清單內容，導覽由外層 Orders split 宿主持有
struct OrdersCompactView: View {

    // MARK: - Properties

    /// 日期區段標題使用的顯示語系
    @Environment(\.locale) private var locale

    /// 畫面的狀態與事件來源，由父層建立後傳入
    @Bindable var store: StoreOf<OrdersFeature>

    /// App 目前選用的顯示語系
    let language: AppLanguage

    // MARK: - Body

    /// 訂單窄版清單內容
    var body: some View {
        navigationContent
    }
}

// MARK: - Private Views

private extension OrdersCompactView {

    /// 訂單清單與搜尋、工具列
    var navigationContent: some View {
        @Bindable var listStore = store.scope(state: \.list, action: \.list)
        let snapshot = listStore.state.listSnapshot()
        let sections = OrdersListQuery.dateSections(
            orders: snapshot.orders,
            context: listStore.dateContext,
            locale: locale
        )
        let selection: Binding<LedgerOrder.ID?>? = listStore.isSelecting
            ? nil
            : detailSelectionBinding

        return OrdersCompactListView(store: listStore, sections: sections, selection: selection)
            .task {
                listStore.send(.view(.task))
            }
            .blSearchable(
                text: $listStore.searchText.sending(\.view.searchTextChanged),
                prompt: Text("orders.list.placeholder.searchCustomersOrder")
            )
            .rootNavigationTitle(listStore.navigationTitleKey, language: language)
            .navigationBarTitleDisplayMode(.large)
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

private extension OrdersCompactView {

    /// 將原生清單選取讀寫轉送到唯一詳情 `path`
    var detailSelectionBinding: Binding<LedgerOrder.ID?> {
        Binding {
            store.selectedOrderID
        } set: {
            store.send(.view(.detailSelectionChanged($0)))
        }
    }
}

// MARK: - Preview

#Preview("iPhone 訂單瀏覽") {
    let previewState: OrdersFeature.State = {
        let state = OrdersFeature.State(orders: LedgerOrder.sampleOrders)
        state.load.$hasLoaded.withLock {
            $0 = true
        }
        return state
    }()

    NavigationStack {
        OrdersCompactView(
            store: Store(initialState: previewState) {
                OrdersFeature()
            },
            language: .traditionalChinese
        )
    }
}
