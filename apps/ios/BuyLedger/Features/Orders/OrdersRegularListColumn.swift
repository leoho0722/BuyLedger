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

    /// App 根層依語言偏好注入的 `locale`
    @Environment(\.locale) private var locale

    /// 畫面的狀態與事件來源，由父層建立後傳入
    @Bindable var store: StoreOf<OrderListFeature>

    /// 已套用篩選的訂單，由父層單次求值後傳入
    let orders: [LedgerOrder]

    // MARK: - Body

    /// 清單欄骨架：上方是篩選區，下方是可捲動的訂單內容
    var body: some View {
        VStack(spacing: 0) {
            listHeader

            ScrollView {
                listContent
            }
            .background(.blBackground)
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

    /// 顯示付款方式單選選單，選取後立即套用，前置勾號由系統選擇器提供
    ///
    /// - Parameter names: 可供選取的付款方式名稱清單
    /// - Returns: 付款方式選單視圖
    func paymentMethodFilterTrigger(names: [String]) -> some View {
        Menu {
            Picker(
                selection: $store.selectedPaymentMethod.sending(\.view.paymentMethodFilterSelected)
            ) {
                Text("common.action.label.all")
                    .tag(nil as String?)
                    .accessibilityIdentifier(BLAccessibilityID.Orders.paymentMethodMenuAllOption)
                    .accessibilityAddTraits(store.selectedPaymentMethod == nil ? .isSelected : [])

                ForEach(names, id: \.self) {
                    Text($0)
                        .tag(Optional($0))
                        .accessibilityIdentifier(
                            BLAccessibilityID.Orders.paymentMethodMenuOption($0)
                        )
                        .accessibilityAddTraits(
                            store.selectedPaymentMethod == $0 ? .isSelected : []
                        )
                }
            } label: {
                Text("orders.list.label.selectPaymentMethod")
            }
            .pickerStyle(.inline)
            .labelsHidden()
        } label: {
            BLFilterChipLabel(
                icon: "creditcard",
                isExpanded: true,
                isSelected: store.hasPaymentMethodFilter,
                style: .purple,
                title: OrderFormatters.paymentMethodFilterTitle(
                    store.selectedPaymentMethod,
                    locale: locale
                ),
                trailingIcon: "chevron.down"
            )
        }
        .buttonStyle(.plain)
        .menuIndicator(.hidden)
        .menuOrder(.fixed)
        .accessibilityAddTraits(store.hasPaymentMethodFilter ? .isSelected : [])
        .accessibilityIdentifier(BLAccessibilityID.Orders.paymentMethodMenuButton)
    }

    /// 商品類別篩選的觸發鈕，顯示目前選取的類別，沒有選取時顯示「全部」
    var categoryFilterTrigger: some View {
        Button {
            store.send(.view(.categoryPickerTapped))
        } label: {
            BLFilterChipLabel(
                icon: "tag",
                isExpanded: true,
                isSelected: store.hasCategoryFilter,
                style: .purple,
                title: OrderFormatters.categoryFilterTitle(
                    store.selectedCategories,
                    locale: locale
                ),
                trailingIcon: "chevron.down"
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(store.hasCategoryFilter ? .isSelected : [])
        .accessibilityIdentifier(BLAccessibilityID.Orders.categoryFilterButton)
    }

    /// 立即清除三項篩選，原本皆為預設時由系統停用
    var clearFiltersButton: some View {
        Button {
            store.send(.view(.clearFiltersTapped))
        } label: {
            Label("orders.filter.button.clearFilters", systemImage: "arrow.counterclockwise")
                .fixedSize(horizontal: false, vertical: true)
                .frame(minHeight: BLHitTarget.minimum)
                .labelStyle(.titleAndIcon)
                .blTextStyle(.subhead)
                .contentShape(Rectangle())
        }
        .disabled(!store.committedFilterSelection.isActive)
        .accessibilityIdentifier(BLAccessibilityID.Orders.clearFiltersButton)
    }

    /// 清單上方的篩選、清除入口與持續性載入失敗訊息
    var listHeader: some View {
        let paymentMethodNames = store.availablePaymentMethodNames
        return VStack(alignment: .leading, spacing: BLSpacing.medium) {
            statusChipStrip

            dateChipStrip

            if !paymentMethodNames.isEmpty {
                paymentMethodFilterTrigger(names: paymentMethodNames)
            }

            if store.hasAvailableCategories {
                categoryFilterTrigger
            }

            clearFiltersButton

            // 持續性載入失敗才走這裡
            // 一次性操作失敗由容器的對話框呈現，兩者不共用欄位
            if case .failed(let message) = store.loadState {
                Text(LocalizedStringKey(message))
                    .blTextStyle(.footnote)
                    .foregroundStyle(.blRed)
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
                        OrderSelectableRow(store: store, order: order)
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
            ProgressView("orders.list.label.loadOrders")
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, BLSpacing.large)
        } else if orders.isEmpty {
            ContentUnavailableView("orders.list.label.matchingOrders", systemImage: "tray")
                .padding(.top, BLSpacing.extraLarge)
                .accessibilityIdentifier(BLAccessibilityID.Orders.listEmptyState)
        } else {
            orderListCard
                .padding(.horizontal, BLSpacing.medium)
                .padding(.bottom, BLSpacing.medium)
        }
    }

    /// 顯示並切換單一訂單狀態篩選
    ///
    /// - Parameter filter: 要呈現的狀態篩選
    /// - Returns: 狀態篩選按鈕
    func statusChip(_ filter: OrderStatusFilter) -> some View {
        BLFilterChip(
            isSelected: store.selectedStatus == filter,
            title: LocalizedStringKey(filter.title)
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
            icon: "calendar",
            isSelected: store.selectedDatePeriod == period,
            style: .accent,
            title: LocalizedStringKey(period.title)
        ) {
            store.send(.view(.datePeriodSelected(period)))
        }
        .accessibilityIdentifier(BLAccessibilityID.Orders.dateChip(period.id))
    }

    /// 顯示一般模式的訂單列，點擊開啟詳情，長按顯示合併與刪除選單
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

// MARK: - Preview

#Preview("訂單清單欄") {
    let previewState: OrderListFeature.State = {
        let state = OrderListFeature.State(orders: SharedReader(value: LedgerOrder.sampleOrders))
        state.$hasLoaded = SharedReader(value: true)
        return state
    }()

    OrdersRegularListColumn(
        store: Store(initialState: previewState) {
            OrderListFeature()
        },
        orders: LedgerOrder.sampleOrders
    )
}
