//
//  OrdersCompactView.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import ComposableArchitecture
import SwiftUI

/// 窄版訂單瀏覽畫面，包含清單與推入詳情
struct OrdersCompactView: View {

    // MARK: - Properties

    /// 日期區段標題使用的顯示語系
    @Environment(\.locale) private var locale

    /// 畫面的狀態與事件來源，由父層建立後傳入
    @Bindable var store: StoreOf<OrdersFeature>

    /// App 目前選用的顯示語系
    let language: AppLanguage

    // MARK: - Body

    /// 訂單瀏覽畫面內容
    var body: some View {
        navigationContent
    }
}

// MARK: - Private Views

private extension OrdersCompactView {

    /// 訂單清單與推入詳情共用的導覽宿主
    var navigationContent: some View {
        @Bindable var listStore = store.scope(state: \.list, action: \.list)
        let palette = BLPalette()
        let sections = listStore.state.dateSections(locale: locale)
        return NavigationStack(path: $store.scope(state: \.detail.path, action: \.detail.path)) {
            OrdersCompactListView(palette: palette, sections: sections, store: listStore)
                // 載入結果由多個分頁共用，不隨畫面消失而取消
                .task {
                    listStore.send(.view(.task))
                }
                // 搜尋欄無穩定識別值，UI 測試改查 `searchFields`
                .searchable(
                    text: $listStore.searchText.sending(\.view.searchTextChanged),
                    placement: .navigationBarDrawer(displayMode: .always),
                    prompt: Text("搜尋客戶、單號或商品")
                )
                .rootNavigationTitle(listStore.navigationTitleKey, language: language)
                .toolbar {
                    OrdersToolbarContent(
                        isAllFilteredSelected: listStore.isAllFilteredSelected,
                        filteredIDs: listStore.filteredIDs,
                        palette: palette,
                        store: listStore
                    )
                }
                .alert(alertBinding(isDetail: false))
                .sheet(item: $listStore.scope(state: \.$filterSheet, action: \.filterSheet)) {
                    OrderFilterSheet(store: $0)
                }
        } destination: { pathStore in
            switch pathStore.case {
            case .detail(let detailStore):
                OrderCompactDetailView(store: detailStore)
                    .alert(alertBinding(isDetail: true))
            }
        }
    }
}

// MARK: - Nested Types

private extension OrdersCompactView {

    /// 最上層畫面持有的唯一對話框綁定
    typealias AlertBinding = Binding<
        Store<
            AlertState<OrdersPresentationFeature.Destination.Alert>,
            OrdersPresentationFeature.Destination.Alert
        >?
    >
}

// MARK: - Private Method

private extension OrdersCompactView {

    /// 唯一對話框只交給目前最上層的清單或推入詳情
    ///
    /// - Parameter isDetail: 是否為推入的詳情畫面
    /// - Returns: 最上層畫面的對話框綁定，其餘為常數 `nil`
    func alertBinding(isDetail: Bool) -> AlertBinding {
        guard isDetail == !store.detail.path.isEmpty else {
            return .constant(nil)
        }
        @Bindable var presentation = store.scope(state: \.presentation, action: \.presentation)
        return $presentation.scope(state: \.$destination, action: \.destination).alert
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

    OrdersCompactView(
        store: Store(initialState: previewState) {
            OrdersFeature()
        },
        language: .traditionalChinese
    )
}
