//
//  OrderFilterPaymentMethodSection.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import SwiftUI

/// 訂單篩選表單的付款方式區段
struct OrderFilterPaymentMethodSection: View {

    // MARK: - Properties

    /// 畫面的狀態與事件來源，由父層建立後傳入
    @Bindable var store: StoreOf<OrderFilterFeature>

    // MARK: - Body

    /// 顯示付款方式篩選的區段與選項列
    var body: some View {
        Section {
            paymentMethodClearRow

            optionRows
        } header: {
            header
        }
    }
}

// MARK: - Private Views

private extension OrderFilterPaymentMethodSection {

    /// 清除付款方式篩選，點選後保留篩選表單
    @ViewBuilder
    var paymentMethodClearRow: some View {
        Button {
            store.send(.view(.filterPendingPaymentMethodSelected(nil)))
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: BLSpacing.small) {
                Image(systemName: "creditcard")
                    .foregroundStyle(.blAccent)

                Text("common.action.label.all")
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(.primary)

                Spacer()

                if store.pendingFilterSelection.paymentMethod == nil {
                    // 選取態改由標準選取特徵表達，勾選符號僅作視覺提示
                    Image(systemName: "checkmark")
                        .foregroundStyle(.blAccent)
                        .accessibilityHidden(true)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(
            store.pendingFilterSelection.paymentMethod == nil ? .isSelected : []
        )
    }

    /// 顯示付款方式名稱與勾選狀態
    ///
    /// - Parameter paymentMethod: 該列代表的付款方式名稱
    /// - Returns: 可選取的篩選列
    @ViewBuilder
    func paymentMethodRow(_ paymentMethod: String) -> some View {
        Button {
            store.send(.view(.filterPendingPaymentMethodSelected(paymentMethod)))
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: BLSpacing.small) {
                Image(systemName: "creditcard")
                    .foregroundStyle(.blAccent)

                Text(paymentMethod)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(.primary)

                Spacer()

                if store.pendingFilterSelection.paymentMethod == paymentMethod {
                    // 選取態改由標準選取特徵表達，勾選符號僅作視覺提示
                    Image(systemName: "checkmark")
                        .foregroundStyle(.blAccent)
                        .accessibilityHidden(true)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(
            store.pendingFilterSelection.paymentMethod == paymentMethod ? .isSelected : []
        )
    }

    /// 沒有符合付款方式時的空狀態列
    @ViewBuilder
    var paymentMethodEmptyStateRow: some View {
        ContentUnavailableView(
            "orders.list.label.matchingPaymentMethods",
            systemImage: "tray",
            description: Text("orders.filter.message.tryAnother")
        )
    }

    /// 符合搜尋的選項，沒有符合項目時顯示空狀態
    @ViewBuilder
    var optionRows: some View {
        if store.filterSheetFilteredPaymentMethods.isEmpty {
            paymentMethodEmptyStateRow
        } else {
            ForEach(store.filterSheetFilteredPaymentMethods, id: \.self) {
                paymentMethodRow($0)
            }
        }
    }

    /// 顯示此區段的篩選項目名稱
    var header: some View {
        Text("orders.list.label.paymentMethod")
    }
}

// MARK: - Preview

#Preview("付款方式篩選") {
    List {
        OrderFilterPaymentMethodSection(
            store: Store(
                initialState: OrderFilterPreviewFixtures.makeState(date: .all, category: nil)
            ) {
                OrderFilterFeature()
            }
        )
    }
}
