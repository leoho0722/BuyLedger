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

    /// 畫面的狀態與事件來源，由父層建立後傳入
    let store: StoreOf<OrderListFeature>

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

    /// 可橫向捲動的訂單狀態篩選列
    var statusChipStrip: some View {
        ScrollView(.horizontal) {
            HStack(spacing: BLSpacing.small) {
                ForEach(OrderStatusFilter.orderBrowsingCases) {
                    statusChip($0)
                }
            }
        }
        .scrollIndicators(.hidden)
    }

    /// 可橫向捲動的日期區間篩選列
    var dateChipStrip: some View {
        ScrollView(.horizontal) {
            HStack(spacing: BLSpacing.small) {
                ForEach(OrderDatePeriod.orderBrowsingCases) {
                    dateChip($0)
                }
            }
        }
        .scrollIndicators(.hidden)
    }

    /// 顯示並切換單一訂單狀態篩選
    ///
    /// - Parameter filter: 要呈現的狀態篩選
    /// - Returns: 狀態篩選按鈕
    func statusChip(_ filter: OrderStatusFilter) -> some View {
        BLFilterChip(
            title: LocalizedStringKey(filter.title),
            isSelected: store.selectedStatus == filter
        ) {
            store.send(.view(.statusFilterSelected(filter)))
        }
        .accessibilityIdentifier(BLAccessibilityID.Orders.statusChip(filter.id))
    }

    /// 顯示並切換單一日期區間篩選
    ///
    /// - Parameter period: 要呈現的日期區間
    /// - Returns: 日期區間篩選按鈕
    func dateChip(_ period: OrderDatePeriod) -> some View {
        BLFilterChip(
            title: LocalizedStringKey(period.title),
            isSelected: store.selectedDatePeriod == period,
            style: .accent,
            icon: "calendar"
        ) {
            store.send(.view(.datePeriodSelected(period)))
        }
    }

    /// 付款方式篩選的觸發鈕，顯示目前選取的付款方式，沒有選取時顯示「全部」
    var paymentMethodFilterTrigger: some View {
        BLFilterChip(
            title: OrderFormatters.paymentMethodFilterTitle(store.selectedPaymentMethod),
            isSelected: store.hasPaymentMethodFilter,
            style: .purple,
            icon: "creditcard",
            trailingIcon: "chevron.down",
            isExpanded: true
        ) {
            store.send(.view(.paymentMethodPickerTapped))
        }
    }

    /// 商品類別篩選的觸發鈕，顯示目前選取的類別，沒有選取時顯示「全部」
    var categoryFilterTrigger: some View {
        BLFilterChip(
            title: OrderFormatters.categoryFilterTitle(store.selectedCategory),
            isSelected: store.hasCategoryFilter,
            style: .purple,
            icon: "tag",
            trailingIcon: "chevron.down",
            isExpanded: true
        ) {
            store.send(.view(.categoryPickerTapped))
        }
    }

    /// 清單上方的狀態、日期、付款方式與類別篩選，以及持續性載入失敗訊息
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
            // 一次性操作失敗由容器的對話框呈現，兩者不共用欄位
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
    /// - Returns: 可開啟詳情的訂單列
    func detailRow(order: LedgerOrder) -> some View {
        Button {
            store.send(.view(.orderSelected(order.id)))
        } label: {
            OrderRowView(order: order)
                .padding(.horizontal, BLSpacing.large)
                .padding(.vertical, BLSpacing.extraSmall)
                .contentShape(Rectangle())
                .accessibilityIdentifier(BLAccessibilityID.Orders.row(orderID: order.id))
        }
        .buttonStyle(.plain)
        .contextMenu {
            OrderDetailRowMenu(
                detail: OrderDetailFeature.State(orderID: order.id, orders: store.$orders)
            ) {
                store.send(.view(.mergeOrderTapped(order.id)))
            } onDelete: {
                store.send(.view(.deleteOrderTapped(order.id)))
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
    let previewState: OrderListFeature.State = {
        let state = OrderListFeature.State(orders: SharedReader(value: LedgerOrder.sampleOrders))
        state.$hasLoaded = SharedReader(value: true)
        return state
    }()

    OrdersRegularListColumn(
        orders: LedgerOrder.sampleOrders,
        store: Store(initialState: previewState) {
            OrderListFeature()
        }
    )
}
