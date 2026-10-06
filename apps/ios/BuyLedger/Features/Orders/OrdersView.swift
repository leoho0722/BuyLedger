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

    /// 訂單篩選所用的行事曆 (含時區)；測試可注入固定值
    @Dependency(\.calendar) private var calendar

    /// 篩選使用的目前時間；測試可注入固定值
    @Dependency(\.date) private var date

    /// 畫面的狀態與事件來源，由父層建立後傳入
    @Bindable var store: StoreOf<OrdersFeature>

    /// App 目前選用的顯示語系
    let language: AppLanguage

    // MARK: - Body

    /// 依版面分類顯示訂單瀏覽，並掛上編輯、AI 總結、合併的 sheet 與各項 alert
    var body: some View {
        platformContent
            .sheet(item: $store.scope(state: \.editOrder, action: \.editOrder)) {
                OrderEditView(store: $0)
            }
            .sheet(item: $store.scope(state: \.aiSummary, action: \.aiSummary)) {
                AISummaryView(store: $0)
            }
            .sheet(item: $store.scope(state: \.orderMerge, action: \.orderMerge)) {
                OrderMergeCandidateSheet(store: $0)
            }
            .alert($store.scope(state: \.deletionConfirmation, action: \.deletionConfirmation))
            .alert($store.scope(state: \.writeFailureAlert, action: \.writeFailureAlert))
            .alert($store.scope(state: \.aiDisabledAlert, action: \.aiDisabledAlert))
    }
}

// MARK: - Private Views

private extension OrdersView {

    /// 商品類別的選擇 sheet，選取後送出類別篩選，「全部」清除篩選
    var categoryPickerSheet: some View {
        OptionPickerSheet(
            title: "選擇商品類別",
            allowsAdd: false,
            searchable: true,
            emptyTitle: "沒有符合的類別",
            emptyDescription: "試試其他搜尋關鍵字。",
            options: store.availableCategories,
            selected: store.selectedCategory ?? "",
            onSelect: {
                store.send(.categoryFilterSelected($0))
            },
            clearOption: OptionPickerSheet.ClearOption(title: "全部") {
                store.send(.categoryFilterSelected(nil))
            }
        )
    }

    /// 付款方式的選擇 sheet，選取後送出付款方式篩選，「全部」清除篩選
    var paymentMethodPickerSheet: some View {
        OptionPickerSheet(
            title: "選擇付款方式",
            allowsAdd: false,
            searchable: true,
            emptyTitle: "沒有符合的付款方式",
            emptyDescription: "試試其他搜尋關鍵字。",
            options: store.availablePaymentMethods.map(\.name),
            selected: store.selectedPaymentMethod ?? "",
            onSelect: {
                store.send(.paymentMethodFilterSelected($0))
            },
            clearOption: OptionPickerSheet.ClearOption(title: "全部") {
                store.send(.paymentMethodFilterSelected(nil))
            }
        )
    }

    /// 寬版使用的「清單 + 詳情」兩欄佈局，並掛上搜尋、工具列與兩個篩選選擇 sheet
    @ViewBuilder
    var regularSplitContent: some View {
        // 先計算一次 filteredOrders，再傳給各區塊
        let filteredOrders = store.state.filteredOrders(referenceDate: date.now, calendar: calendar)
        let filteredIDs = filteredOrders.map(\.id)
        let isAllFilteredSelected = !filteredIDs.isEmpty
            && filteredIDs.allSatisfy { store.selectedOrderIDs.contains($0) }

        NavigationStack {
            HStack(spacing: 0) {
                OrdersRegularListColumn(orders: filteredOrders, store: store)
                    .frame(minWidth: 280, idealWidth: 320, maxWidth: 360)
                    .background(palette.background)

                Divider()

                OrdersRegularDetailColumn(orders: filteredOrders, store: store)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .background(palette.background)
            }
            .rootNavigationTitle(store.navigationTitleKey, language: language)
            // searchable 無穩定 identifier，UI 測試改查 searchFields
            .searchable(
                text: $store.searchText.sending(\.searchTextChanged),
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: Text("搜尋客戶、單號或商品")
            )
            .toolbar {
                OrdersToolbarContent(
                    store: store,
                    palette: palette,
                    filteredIDs: filteredIDs,
                    allFilteredSelected: isAllFilteredSelected
                )
            }
        }
        .task {
            await store.send(.task).finish()
        }
        .sheet(isPresented: $store.showsCategoryPicker) {
            categoryPickerSheet
        }
        .sheet(isPresented: $store.showsPaymentMethodPicker) {
            paymentMethodPickerSheet
        }
    }

    /// 依版面分類選擇對應的訂單瀏覽 view
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

// MARK: - Private Method

private extension OrdersView {

    /// 兩欄背景與工具列使用的色盤，隨目前外觀取得對應的顏色
    var palette: BLPalette {
        BLPalette()
    }
}

// MARK: - Preview

#Preview("訂單瀏覽") {
    let previewState: OrdersFeature.State = {
        var state = OrdersFeature.State()
        state.orders = LedgerOrder.sampleOrders
        state.hasLoaded = true
        state.selectedOrderID = LedgerOrder.sampleOrders.first?.id
        return state
    }()

    OrdersView(
        store: Store(initialState: previewState) {
            OrdersFeature()
        },
        language: .traditionalChinese
    )
}
