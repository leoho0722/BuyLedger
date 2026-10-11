//
//  OrderEditCostSection.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/8.
//

import ComposableArchitecture
import SwiftUI

/// 商品成本與三種運費的成本區段
struct OrderEditCostSection: View {

    // MARK: - Properties

    /// 畫面的狀態與事件來源，由父層建立後傳入
    @Bindable var store: StoreOf<OrderEditFeature>

    /// 表單共用的鍵盤焦點綁定
    let focusedField: FocusState<OrderEditFeature.State.Field?>.Binding

    // MARK: - Body

    /// 組合區段或元件的內容
    var body: some View {
        Section {
            fields
        } header: {
            sectionHeader
        } footer: {
            sectionFooter
        }
    }
}

// MARK: - Private Views

private extension OrderEditCostSection {

    /// 商品成本、外國國內運費、國際運費與國內運費
    @ViewBuilder
    var fields: some View {
        OrderEditDecimalField(
            title: "orders.edit.label.itemCost",
            value: $store.draft.itemCost,
            field: .itemCost,
            focusedField: focusedField
        )

        OrderEditDecimalField(
            title: "orders.detail.label.foreignLocalShipping",
            value: $store.draft.foreignDomesticShipping,
            field: .foreignDomesticShipping,
            focusedField: focusedField
        )

        OrderEditDecimalField(
            title: "orders.detail.label.internationalShipping",
            value: $store.draft.internationalShipping,
            field: .internationalShipping,
            focusedField: focusedField
        )

        OrderEditDecimalField(
            title: "orders.detail.label.localShipping",
            value: $store.draft.domesticShipping,
            field: .domesticShipping,
            focusedField: focusedField
        )
    }

    /// 成本的幣別標題
    var sectionHeader: some View {
        Text("orders.edit.label.costNt")
    }

    /// 貨到付款時的運費扣除說明
    @ViewBuilder
    var sectionFooter: some View {
        if store.isSelectedPaymentMethodCOD {
            Text("orders.edit.message.cashDeliveryReceived")
                .blTextStyle(.footnote)
                .foregroundStyle(Color.blSecondaryLabel)
        }
    }
}

// MARK: - Preview

#Preview {
    @Previewable @FocusState var focusedField: OrderEditFeature.State.Field?

    if let id = UUID(uuidString: "00000000-0000-0000-0000-000000000000") {
        Form {
            OrderEditCostSection(
                store: Store(
                    initialState: OrderEditFeature.State(
                        id: id,
                        currentDate: Date(timeIntervalSince1970: 0)
                    )
                ) {
                    OrderEditFeature()
                },
                focusedField: $focusedField
            )
        }
    }
}
