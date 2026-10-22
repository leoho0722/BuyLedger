//
//  OrderFilterDateSection.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import SwiftUI

/// 篩選表單的日期選單列，只更新暫存日期
struct OrderFilterDateSection: View {

    // MARK: - Properties

    /// 畫面的狀態與事件來源
    @Bindable var store: StoreOf<OrderFilterFeature>

    // MARK: - Body

    /// 日期選單與目前暫存值
    var body: some View {
        Menu {
            datePicker
        } label: {
            menuLabel
        }
        .buttonStyle(.plain)
        .menuOrder(.fixed)
        .accessibilityIdentifier(BLAccessibilityID.Orders.filterDateMenuButton)
    }
}

// MARK: - Private Views

private extension OrderFilterDateSection {

    /// 以原生單選語意標記目前暫存日期
    var datePicker: some View {
        Picker(
            selection: $store.pendingFilterSelection.datePeriod
                .sending(\.view.filterPendingDatePeriodSelected)
        ) {
            ForEach(OrderDatePeriod.orderBrowsingCases) {
                Text(LocalizedStringKey($0.title))
                    .tag($0)
                    .accessibilityIdentifier(BLAccessibilityID.Orders.filterDatePeriod($0.id))
                    .accessibilityAddTraits(
                        store.pendingFilterSelection.datePeriod == $0 ? .isSelected : []
                    )
            }
        } label: {
            Text("orders.list.label.dateRange")
        }
        .pickerStyle(.inline)
        .labelsHidden()
    }

    /// 日期標題、暫存值與指示箭頭對齊第一行基線，長文允許換行
    var menuLabel: some View {
        HStack(alignment: .firstTextBaseline, spacing: BLSpacing.small) {
            Image(systemName: "calendar")
                .foregroundStyle(.blAccent)
                .accessibilityHidden(true)

            Text("orders.list.label.dateRange")
                .fixedSize(horizontal: false, vertical: true)
                .foregroundStyle(.blLabel)

            Spacer(minLength: BLSpacing.small)

            Text(LocalizedStringKey(store.pendingFilterSelection.datePeriod.title))
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.trailing)
                .foregroundStyle(.blSecondaryLabel)

            Image(systemName: "chevron.up.chevron.down")
                .foregroundStyle(.blAccent)
                .accessibilityHidden(true)
        }
        .frame(maxWidth: .infinity, minHeight: BLHitTarget.minimum, alignment: .leading)
        .blTextStyle(.body)
        .contentShape(Rectangle())
    }
}

// MARK: - Preview

#Preview("日期區間選單") {
    List {
        OrderFilterDateSection(
            store: Store(
                initialState: OrderFilterPreviewFixtures.makeState(date: .thisMonth, category: nil)
            ) {
                OrderFilterFeature()
            }
        )
    }
}
