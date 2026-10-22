//
//  OrdersView.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import ComposableArchitecture
import SwiftUI

/// 訂單列表與詳情畫面
struct OrdersView: View {

    // MARK: - Properties

    /// 目前版面分類，用來區分窄版 (含 iPhone 橫向) 與寬版 (iPad 全螢幕) 佈局
    @Environment(\.blLayoutClass) private var layoutClass

    /// 畫面的狀態與事件來源，由父層建立後傳入
    @Bindable var store: StoreOf<OrdersFeature>

    /// App 目前選用的顯示語系
    let language: AppLanguage

    // MARK: - Body

    /// 依版面分類顯示訂單瀏覽，並共用編輯、AI 總結與合併表單的呈現
    var body: some View {
        @Bindable var presentation = store.scope(state: \.presentation, action: \.presentation)

        platformContent
            .sheet(
                item: $presentation.scope(state: \.$destination, action: \.destination).edit,
                onDismiss: sendFormSheetDismissed
            ) {
                OrderEditView(store: $0)
            }
            .sheet(
                item: $presentation.scope(state: \.$destination, action: \.destination).aiSummary,
                onDismiss: sendFormSheetDismissed
            ) {
                AISummaryView(store: $0)
            }
            .sheet(
                item: $presentation.scope(state: \.$destination, action: \.destination).merge,
                onDismiss: sendFormSheetDismissed
            ) {
                OrderMergeCandidateSheet(store: $0)
            }
    }
}

// MARK: - Private Views

private extension OrdersView {

    /// 寬版的訂單清單欄，承載搜尋、工具列與篩選選擇器
    @ViewBuilder
    var regularListContent: some View {
        @Bindable var listStore = store.scope(state: \.list, action: \.list)
        @Bindable var presentation = store.scope(state: \.presentation, action: \.presentation)
        let snapshot = listStore.state.listSnapshot()

        OrdersRegularListColumn(store: listStore, orders: snapshot.orders)
            .background(.blBackground)
            // 載入結果由多個分頁共用，不隨畫面消失而取消
            .task {
                listStore.send(.view(.task))
            }
            // 搜尋欄無穩定識別值，UI 測試改查 `searchFields`
            .searchable(
                text: $listStore.searchText.sending(\.view.searchTextChanged),
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: Text("orders.list.placeholder.searchCustomersOrder")
            )
            // 多選筆數由清單欄頂部顯示，標題固定為訂單
            .rootNavigationTitle("orders.list.title", language: language)
            // 大標題在搜尋結束後會留白且不顯示標題，並把搜尋欄下推
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                OrdersToolbarContent(
                    isAllFilteredSelected: snapshot.isAllSelected,
                    filteredIDs: snapshot.ids,
                    store: listStore
                )
            }
            .alert($presentation.scope(state: \.$destination, action: \.destination).alert)
            .sheet(
                item: $listStore.scope(state: \.$destination, action: \.destination).filterSheet
            ) {
                OrderFilterSheet(store: $0)
            }
            .sheet(
                item: $listStore.scope(state: \.$destination, action: \.destination).categoryPicker
            ) {
                OrderCategoryPickerSheet(store: $0)
            }
    }

    /// 依版面分類選擇對應的訂單瀏覽內容
    @ViewBuilder
    var platformContent: some View {
        switch layoutClass {
        case .compact:
            OrdersCompactView(store: store, language: language)

        case .regular:
            regularListContent
        }
    }
}

// MARK: - Private Method

private extension OrdersView {

    /// 表單的關閉動畫完成後通知容器取出暫存通知
    func sendFormSheetDismissed() {
        store.send(.view(.formSheetDismissed))
    }
}

// MARK: - Preview

#Preview("訂單瀏覽") {
    let previewState: OrdersFeature.State = {
        let state = OrdersFeature.State(orders: LedgerOrder.sampleOrders)
        state.load.$hasLoaded.withLock {
            $0 = true
        }
        return state
    }()

    // 固定寬版清單欄：compact 分支自帶 NavigationStack，外層再包會疊成兩層
    NavigationStack {
        OrdersView(
            store: Store(initialState: previewState) {
                OrdersFeature()
            },
            language: .traditionalChinese
        )
        .environment(\.blLayoutClass, .regular)
    }
}
