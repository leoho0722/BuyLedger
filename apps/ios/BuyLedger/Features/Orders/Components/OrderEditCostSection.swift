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
            title: "商品成本",
            value: $store.draft.itemCost,
            field: .itemCost,
            focusedField: focusedField
        )

        OrderEditDecimalField(
            title: "外國國內運費",
            value: $store.draft.foreignDomesticShipping,
            field: .foreignDomesticShipping,
            focusedField: focusedField
        )

        OrderEditDecimalField(
            title: "國際運費",
            value: $store.draft.internationalShipping,
            field: .internationalShipping,
            focusedField: focusedField
        )

        OrderEditDecimalField(
            title: "國內運費",
            value: $store.draft.domesticShipping,
            field: .domesticShipping,
            focusedField: focusedField
        )
    }

    /// 成本的幣別標題
    var sectionHeader: some View {
        Text("成本 (NT$)")
    }

    /// 貨到付款時的運費扣除說明
    @ViewBuilder
    var sectionFooter: some View {
        if store.isSelectedPaymentMethodCOD {
            Text("貨到付款：收款金額已含預估運費，獲利會自動扣除上方三種運費 (國內 + 國際 + 外國國內)。")
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
