//
//  OrdersRegularListColumn.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/5.
//

import ComposableArchitecture
import SwiftUI

/// 寬版 (iPad 全螢幕) 訂單瀏覽的清單欄，上方是篩選區，下方是卡片化的訂單列
struct OrdersRegularListColumn: View {

    // MARK: - Properties

    /// 已套用篩選的訂單，由父層單次求值後傳入
    let orders: [LedgerOrder]

    /// 畫面的狀態與事件來源，由父層傳入
    let store: StoreOf<OrdersFeature>

    // MARK: - Body

    /// 清單欄骨架：上方是篩選區，下方是可捲動的訂單內容
    var body: some View {
        VStack(spacing: 0) {
            listHeader

            ScrollView {
                listContent
            }
            .background(palette.background)
            .accessibilityIdentifier(BLAccessibilityID.Orders.listRoot)
        }
    }
}

// MARK: - Private Views

private extension OrdersRegularListColumn {

    /// 橫向滾動的訂單狀態 chip 列
    var statusChipStrip: some View {
        ScrollView(.horizontal) {
            HStack(spacing: BLSpacing.small) {
                ForEach(OrderStatusFilter.orderBrowsingCases) { filter in
                    BLFilterChip(
                        title: LocalizedStringKey(filter.title),
                        isSelected: store.selectedStatus == filter
                    ) {
                        store.send(.statusFilterSelected(filter))
                    }
                    .accessibilityIdentifier(BLAccessibilityID.Orders.statusChip(filter.id))
                }
            }
        }
        .scrollIndicators(.hidden)
    }

    /// 橫向滾動的日期區間 chip 列
    var dateChipStrip: some View {
        ScrollView(.horizontal) {
            HStack(spacing: BLSpacing.small) {
                ForEach(OrderDatePeriod.orderBrowsingCases) { period in
                    BLFilterChip(
                        title: LocalizedStringKey(period.title),
                        isSelected: store.selectedDatePeriod == period,
                        style: .accent,
                        icon: "calendar"
                    ) {
                        store.send(.datePeriodSelected(period))
                    }
                }
            }
        }
        .scrollIndicators(.hidden)
    }

    /// 付款方式篩選的觸發鈕，顯示目前選取的付款方式，沒有選取時顯示「全部」
    @ViewBuilder
    var paymentMethodFilterTrigger: some View {
        let isSelected = store.selectedPaymentMethod != nil
        let currentLabel = store.selectedPaymentMethod ?? "全部"

        BLFilterChip(
            title: "付款方式：\(currentLabel)",
            isSelected: isSelected,
            style: .purple,
            icon: "creditcard",
            trailingIcon: "chevron.down",
            isExpanded: true
        ) {
            store.send(.paymentMethodPickerTapped)
        }
    }

    /// 商品類別篩選的觸發鈕，顯示目前選取的類別，沒有選取時顯示「全部」
    @ViewBuilder
    var categoryFilterTrigger: some View {
        let isSelected = store.selectedCategory != nil
        let currentLabel = store.selectedCategory ?? "全部"

        BLFilterChip(
            title: "類別：\(currentLabel)",
            isSelected: isSelected,
            style: .purple,
            icon: "tag",
            trailingIcon: "chevron.down",
            isExpanded: true
        ) {
            store.send(.categoryPickerTapped)
        }
    }

    /// 清單上方的篩選區：狀態與日期 chip、付款方式與類別觸發鈕，以及持續性載入失敗訊息
    var listHeader: some View {
        VStack(alignment: .leading, spacing: BLSpacing.medium) {
            statusChipStrip

            dateChipStrip

            if !store.availablePaymentMethods.isEmpty {
                paymentMethodFilterTrigger
            }

            if !store.availableCategories.isEmpty {
                categoryFilterTrigger
            }

            // 持續性載入失敗才走這裡
            // 一次性操作失敗改以 writeFailureAlert 對話框呈現，兩者不共用欄位
            if case .failed(let message) = store.loadState {
                Text(LocalizedStringKey(message))
                    .blTextStyle(.footnote)
                    .foregroundStyle(palette.red)
            }
        }
        .padding(.top, BLSpacing.small)
        .padding(.horizontal, BLSpacing.medium)
        .padding(.bottom, BLSpacing.medium)
    }

    /// 卡片化的訂單列表，逐列呈現訂單並以分隔線隔開
    var orderListCard: some View {
        BLCard(padding: 0) {
            VStack(spacing: 0) {
                ForEach(Array(orders.enumerated()), id: \.element.id) { index, order in
                    if store.isSelecting {
                        OrderSelectableRow(order: order, palette: palette, store: store)
                    } else {
                        detailRow(order: order)
                    }

                    if index < orders.count - 1 {
                        Divider()
                            .padding(.leading, BLListMetrics.dividerInset)
                    }
                }
            }
        }
    }

    /// 清單欄的捲動內容，依載入中、沒有符合的訂單與有訂單三種情況切換
    @ViewBuilder
    var listContent: some View {
        if store.isLoading {
            ProgressView("載入訂單")
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, BLSpacing.large)
        } else if orders.isEmpty {
            ContentUnavailableView("沒有符合條件的訂單", systemImage: "tray")
                .padding(.top, BLSpacing.extraLarge)
                .accessibilityIdentifier(BLAccessibilityID.Orders.listEmptyState)
        } else {
            orderListCard
                .padding(.horizontal, BLSpacing.medium)
                .padding(.bottom, BLSpacing.medium)
        }
    }

    /// 一般模式的訂單列，點擊開啟詳情，長按顯示合併與刪除選單
    ///
    /// - Parameter order: 要呈現的訂單
    /// - Returns: 可選取詳情的訂單列 view
    func detailRow(order: LedgerOrder) -> some View {
        Button {
            store.send(.orderSelected(order.id))
        } label: {
            OrderRowView(order: order)
                .padding(.horizontal, BLSpacing.large)
                .padding(.vertical, BLSpacing.extraSmall)
                .contentShape(Rectangle())
                .accessibilityIdentifier(BLAccessibilityID.Orders.row(orderID: order.id))
        }
        .buttonStyle(.plain)
        .contextMenu {
            if order.status != .merged, order.status != .cancelled {
                Button {
                    store.send(.mergeOrderTapped(order.id))
                } label: {
                    Label("合併訂單", systemImage: "arrow.triangle.merge")
                }
            }

            Button(role: .destructive) {
                store.send(.deleteOrderTapped(order.id))
            } label: {
                Label("刪除訂單", systemImage: "trash")
            }
        }
    }
}

// MARK: - Private Method

private extension OrdersRegularListColumn {

    /// 清單欄背景與文字使用的色盤，隨目前外觀取得對應的顏色
    var palette: BLPalette {
        BLPalette()
    }
}

// MARK: - Preview

#Preview("訂單清單欄") {
    let previewState: OrdersFeature.State = {
        var state = OrdersFeature.State()
        state.orders = LedgerOrder.sampleOrders
        state.hasLoaded = true
        return state
    }()

    OrdersRegularListColumn(
        orders: LedgerOrder.sampleOrders,
        store: Store(initialState: previewState) {
            OrdersFeature()
        }
    )
}
