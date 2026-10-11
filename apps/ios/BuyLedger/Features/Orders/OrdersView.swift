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

    /// 寬版清單偏好的欄寬，隨文字大小調整
    @ScaledMetric(relativeTo: .body) private var idealListWidth: CGFloat = 320

    /// 寬版清單的欄寬上限，隨文字大小調整
    @ScaledMetric(relativeTo: .body) private var maximumListWidth: CGFloat = 360

    /// 寬版清單的欄寬下限，隨文字大小調整
    @ScaledMetric(relativeTo: .body) private var minimumListWidth: CGFloat = 280

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

    /// 商品類別選擇器，選取後套用篩選，「全部」清除篩選
    var categoryPickerSheet: some View {
        OptionPickerSheet(
            title: "orders.list.label.category1",
            allowsAdd: false,
            searchable: true,
            emptyTitle: "orders.list.label.matchingCategories",
            emptyDescription: "orders.list.message.tryAnotherSearch",
            options: listStore.availableCategories,
            selected: listStore.selectedCategory ?? "",
            onSelect: {
                listStore.send(.view(.categoryFilterSelected($0)))
            },
            clearOption: OptionPickerSheet.ClearOption(title: "common.action.label.all") {
                listStore.send(.view(.categoryFilterSelected(nil)))
            }
        )
    }

    /// 付款方式選擇器，選取後套用篩選，「全部」清除篩選
    var paymentMethodPickerSheet: some View {
        OptionPickerSheet(
            title: "orders.list.label.selectPaymentMethod",
            allowsAdd: false,
            searchable: true,
            emptyTitle: "orders.list.label.matchingPaymentMethods",
            emptyDescription: "orders.list.message.tryAnotherSearch",
            options: listStore.availablePaymentMethodNames,
            selected: listStore.selectedPaymentMethod ?? "",
            onSelect: {
                listStore.send(.view(.paymentMethodFilterSelected($0)))
            },
            clearOption: OptionPickerSheet.ClearOption(title: "common.action.label.all") {
                listStore.send(.view(.paymentMethodFilterSelected(nil)))
            }
        )
    }

    /// 寬版的清單與詳情兩欄佈局，共用搜尋、工具列與篩選選擇器
    @ViewBuilder
    var regularSplitContent: some View {
        @Bindable var listStore = store.scope(state: \.list, action: \.list)
        let filteredOrders = listStore.filteredOrders

        NavigationStack {
            HStack(spacing: 0) {
                OrdersRegularListColumn(orders: filteredOrders, store: listStore)
                    .frame(
                        minWidth: minimumListWidth,
                        idealWidth: idealListWidth,
                        maxWidth: maximumListWidth
                    )
                    .background(palette.background)
                    .alert(regularAlertBinding(isDetail: false))

                Divider()

                OrdersRegularDetailColumn(store: store)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .background(palette.background)
                    .alert(regularAlertBinding(isDetail: true))
            }
            // 搜尋欄無穩定識別值，UI 測試改查 `searchFields`
            .searchable(
                text: $listStore.searchText.sending(\.view.searchTextChanged),
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: Text("orders.list.placeholder.searchCustomersOrder")
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
        }
        // 載入結果由多個分頁共用，不隨畫面消失而取消
        .task {
            listStore.send(.view(.task))
        }
        .sheet(item: $listStore.scope(state: \.$filterSheet, action: \.filterSheet)) {
            OrderFilterSheet(store: $0)
        }
        .sheet(isPresented: $listStore.isCategoryPickerPresented) {
            categoryPickerSheet
        }
        .sheet(isPresented: $listStore.isPaymentMethodPickerPresented) {
            paymentMethodPickerSheet
        }
    }

    /// 依版面分類選擇對應的訂單瀏覽內容
    @ViewBuilder
    var platformContent: some View {
        switch layoutClass {
        case .compact:
            OrdersCompactView(store: store, language: language)

        case .regular:
            regularSplitContent
        }
    }
}

// MARK: - Nested Types

private extension OrdersView {

    /// 最上層畫面持有的唯一對話框綁定
    typealias AlertBinding = Binding<
        Store<
            AlertState<OrdersPresentationFeature.Destination.Alert>,
            OrdersPresentationFeature.Destination.Alert
        >?
    >
}

// MARK: - Private Method

private extension OrdersView {

    /// 清單子 Feature 的狀態與互動入口
    var listStore: StoreOf<OrderListFeature> {
        store.scope(state: \.list, action: \.list)
    }

    /// 兩欄背景與工具列使用的色盤，隨目前外觀取得對應的顏色
    var palette: BLPalette {
        BLPalette()
    }

    /// 寬版雙欄只在有詳情時由詳情呈現對話框，空清單則交由清單呈現
    ///
    /// - Parameter isDetail: 是否為右側詳情欄
    /// - Returns: 最上層欄位的對話框綁定，其餘為常數 `nil`
    func regularAlertBinding(isDetail: Bool) -> AlertBinding {
        let hasDetail = store.detail.regularDetail?.order != nil
        guard isDetail == hasDetail else {
            return .constant(nil)
        }
        @Bindable var presentation = store.scope(state: \.presentation, action: \.presentation)
        return $presentation.scope(state: \.$destination, action: \.destination).alert
    }

    /// 表單的關閉動畫完成後通知容器取出暫存通知
    func sendFormSheetDismissed() {
        store.send(.view(.formSheetDismissed))
    }
}

// MARK: - Preview

#Preview("訂單瀏覽") {
    let previewState: OrdersFeature.State = {
        var state = OrdersFeature.State(orders: LedgerOrder.sampleOrders)
        state.load.$hasLoaded.withLock {
            $0 = true
        }
        state.list.selectedOrderID = LedgerOrder.sampleOrders.first?.id
        state.detail.syncRegularDetail(selectedOrderID: state.list.selectedOrderID)
        return state
    }()

    OrdersView(
        store: Store(initialState: previewState) {
            OrdersFeature()
        },
        language: .traditionalChinese
    )
}
