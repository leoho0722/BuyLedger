//
//  OrdersFilterControlsView.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/30.
//

import ComposableArchitecture
import SwiftUI

/// Orders 窄版與寬版共用的狀態膠囊列與整合篩選按鈕
struct OrdersFilterControlsView: View {

    // MARK: - Properties

    /// 篩選摘要使用的顯示語系
    @Environment(\.locale) private var locale

    /// 訂單清單的篩選與互動狀態
    @Bindable var store: StoreOf<OrderListFeature>

    /// 是否顯示整合篩選按鈕
    let isUnifiedFilterTriggerShown: Bool

    /// 狀態膠囊列的水平內距
    let statusChipHorizontalInset: CGFloat

    /// 狀態膠囊的尺寸，依所在版面保留原有外觀
    let statusChipSize: BLFilterChip.Size

    /// 整合篩選按鈕的水平內距
    let unifiedFilterHorizontalInset: CGFloat

    // MARK: - Body

    /// 依呼叫端的尺寸與可見需求呈現狀態膠囊與整合篩選按鈕
    var body: some View {
        VStack(alignment: .leading, spacing: BLSpacing.medium) {
            statusChipStrip

            if isUnifiedFilterTriggerShown {
                unifiedFilterTrigger
            }
        }
    }
}

// MARK: - Private Views

private extension OrdersFilterControlsView {

    /// 可橫向捲動的訂單狀態篩選列
    var statusChipStrip: some View {
        ScrollView(.horizontal) {
            HStack(spacing: BLSpacing.small) {
                ForEach(OrderStatusFilter.orderBrowsingCases) {
                    statusChip($0)
                }
            }
            .padding(.horizontal, statusChipHorizontalInset)
        }
        .scrollIndicators(.hidden)
    }

    /// 顯示並切換單一訂單狀態篩選
    ///
    /// - Parameter filter: 要呈現的狀態篩選
    /// - Returns: 狀態篩選按鈕
    func statusChip(_ filter: OrderStatusFilter) -> some View {
        BLFilterChip(
            isSelected: store.selectedStatus == filter,
            size: statusChipSize,
            title: filter.title
        ) {
            store.send(.view(.statusFilterSelected(filter)))
        }
        .accessibilityIdentifier(BLAccessibilityID.Orders.statusChip(filter.id))
    }

    /// 顯示日期、類別與付款方式的整合篩選按鈕
    @ViewBuilder
    var unifiedFilterTrigger: some View {
        let language = AppLanguage(locale: locale)
        let summaryText = store.state.filterSummary(language: language)
        let formattedTitle = LocalizedStringResource(
            "orders.filter.label.filterSummary",
            defaultValue: "\(summaryText)"
        )

        BLFilterChip(
            icon: "line.3.horizontal.decrease",
            isExpanded: true,
            isSelected: store.committedFilterSelection.isActive,
            size: .large,
            style: .purple,
            title: formattedTitle,
            trailingIcon: "chevron.down"
        ) {
            store.send(.view(.filterSheetTapped))
        }
        .padding(.horizontal, unifiedFilterHorizontalInset)
        .accessibilityIdentifier(BLAccessibilityID.Orders.filterButton)
    }
}

// MARK: - Preview

#Preview("Orders 篩選控制") {
    OrdersFilterControlsView(
        store: Store(initialState: OrderListFeature.State(orders: SharedReader(value: []))) {
            OrderListFeature()
        },
        isUnifiedFilterTriggerShown: true,
        statusChipHorizontalInset: BLSpacing.large,
        statusChipSize: .large,
        unifiedFilterHorizontalInset: BLSpacing.large
    )
}
