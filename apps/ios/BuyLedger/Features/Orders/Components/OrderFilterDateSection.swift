//
//  OrderFilterDateSection.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import SwiftUI

/// 訂單篩選表單的日期區間區段
struct OrderFilterDateSection: View {

    // MARK: - Properties

    /// 畫面的狀態與事件來源，由父層建立後傳入
    let store: StoreOf<OrderFilterFeature>

    // MARK: - Body

    /// 顯示日期區間篩選的區段與選項列
    var body: some View {
        Section {
            ForEach(OrderDatePeriod.orderBrowsingCases) {
                datePeriodRow($0)
            }
        } header: {
            header
        }
    }
}

// MARK: - Private Views

private extension OrderFilterDateSection {

    /// 日期區間選項列
    ///
    /// - Parameter period: 該列代表的日期區間
    /// - Returns: 可選取的篩選列
    @ViewBuilder
    func datePeriodRow(_ period: OrderDatePeriod) -> some View {
        Button {
            store.send(.view(.filterPendingDatePeriodSelected(period)))
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: BLSpacing.small) {
                Image(systemName: "calendar")
                    .foregroundStyle(BLPalette().accent)

                Text(LocalizedStringKey(period.title))
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(.primary)

                Spacer()

                if store.pendingFilterSelection.datePeriod == period {
                    // 選取態改由標準選取特徵表達，勾選符號僅作視覺提示
                    Image(systemName: "checkmark")
                        .foregroundStyle(BLPalette().accent)
                        .accessibilityHidden(true)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(
            store.pendingFilterSelection.datePeriod == period ? .isSelected : []
        )
        .accessibilityIdentifier(BLAccessibilityID.Orders.filterDatePeriod(period.id))
    }

    /// 顯示此區段的篩選項目名稱
    var header: some View {
        Text("日期區間")
    }
}

// MARK: - Preview

#Preview("日期區間篩選") {
    List {
        OrderFilterDateSection(
            store: Store(
                initialState: OrderFilterPreviewFixtures.makeState(date: .all, category: nil)
            ) {
                OrderFilterFeature()
            }
        )
    }
}
