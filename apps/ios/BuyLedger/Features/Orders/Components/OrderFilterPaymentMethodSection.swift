//
//  OrderFilterPaymentMethodSection.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import SwiftUI

/// 篩選表單的付款方式選單列，選項不受類別搜尋影響
struct OrderFilterPaymentMethodSection: View {

    // MARK: - Properties

    /// 畫面的狀態與事件來源
    @Bindable var store: StoreOf<OrderFilterFeature>

    // MARK: - Body

    /// 完整付款方式選單與目前暫存值
    var body: some View {
        Menu {
            paymentMethodPicker
        } label: {
            menuLabel
        }
        .buttonStyle(.plain)
        .menuOrder(.fixed)
        .accessibilityIdentifier(BLAccessibilityID.Orders.filterPaymentMethodMenuButton)
    }
}

// MARK: - Private Views

private extension OrderFilterPaymentMethodSection {

    /// 全部與可用付款方式以原生單選語意標記暫存值
    var paymentMethodPicker: some View {
        Picker(
            selection: $store.pendingFilterSelection.paymentMethod
                .sending(\.view.filterPendingPaymentMethodSelected)
        ) {
            Text("common.action.label.all")
                .tag(nil as String?)
                .accessibilityIdentifier(BLAccessibilityID.Orders.filterPaymentMethodAllOption)
                .accessibilityAddTraits(
                    store.pendingFilterSelection.paymentMethod == nil ? .isSelected : []
                )

            ForEach(store.availablePaymentMethodNames, id: \.self) {
                Text($0)
                    .tag(Optional($0))
                    .accessibilityIdentifier(BLAccessibilityID.Orders.filterPaymentMethodOption($0))
                    .accessibilityAddTraits(
                        store.pendingFilterSelection.paymentMethod == $0 ? .isSelected : []
                    )
            }
        } label: {
            Text("orders.list.label.paymentMethod")
        }
        .pickerStyle(.inline)
        .labelsHidden()
    }

    /// 付款標題、暫存值與指示箭頭對齊第一行基線，長文允許換行
    var menuLabel: some View {
        HStack(alignment: .firstTextBaseline, spacing: BLSpacing.small) {
            Image(systemName: "creditcard")
                .foregroundStyle(.blAccent)
                .accessibilityHidden(true)

            Text("orders.list.label.paymentMethod")
                .fixedSize(horizontal: false, vertical: true)
                .foregroundStyle(.blLabel)

            Spacer(minLength: BLSpacing.small)

            paymentMethodValue
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

    /// 付款方式名稱保持原文，未選取時使用本地化的全部
    @ViewBuilder
    var paymentMethodValue: some View {
        if let name = store.pendingFilterSelection.paymentMethod {
            Text(name)
        } else {
            Text("common.action.label.all")
        }
    }
}

// MARK: - Preview

#Preview("付款方式選單") {
    List {
        OrderFilterPaymentMethodSection(
            store: Store(
                initialState: OrderFilterPreviewFixtures.makeState(
                    date: .all,
                    category: nil,
                    paymentMethod: "銀行轉帳"
                )
            ) {
                OrderFilterFeature()
            }
        )
    }
}
