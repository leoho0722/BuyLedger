//
//  OrderEditPaymentSection.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/8.
//

import ComposableArchitecture
import SwiftUI

/// 客戶實付與無卡折抵、補款的收款金額區段
struct OrderEditPaymentSection: View {

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

private extension OrderEditPaymentSection {

    /// 客戶實付與付款方式需要的折抵、補款欄位
    @ViewBuilder
    var fields: some View {
        OrderEditDecimalField(
            title: "orders.edit.label.customerPayment",
            value: $store.chargedAmount,
            field: .chargedAmount,
            focusedField: focusedField,
            identifier: BLAccessibilityID.OrderEdit.chargedAmountField
        )

        if store.isSelectedPaymentMethodCardless {
            OrderEditDecimalField(
                title: "orders.detail.label.cardlessDeduction",
                value: $store.cardlessDeductionAmount,
                field: .cardlessDeduction,
                focusedField: focusedField
            )

            OrderEditDecimalField(
                title: "orders.detail.label.cardlessTopup",
                value: $store.draft.cardlessSupplementAmount,
                field: .cardlessSupplement,
                focusedField: focusedField
            )
        }
    }

    /// 收款金額的幣別標題
    var sectionHeader: some View {
        Text("orders.edit.label.receivedAmountNt")
    }

    /// 無卡計算方式與折抵金額已夾限的提示
    @ViewBuilder
    var sectionFooter: some View {
        if store.isSelectedPaymentMethodCardless || store.isCardlessDeductionCapped {
            VStack(alignment: .leading, spacing: BLSpacing.small) {
                if store.isSelectedPaymentMethodCardless {
                    Text("orders.edit.message.onlyCardlessPayment")
                        .blTextStyle(.footnote)
                        .foregroundStyle(Color.blSecondaryLabel)
                }

                if store.isCardlessDeductionCapped {
                    Text("orders.edit.message.cardlessDeductionCannot")
                        .blTextStyle(.footnote)
                        .foregroundStyle(Color.blSecondaryLabel)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    @Previewable @FocusState var focusedField: OrderEditFeature.State.Field?

    if let id = UUID(uuidString: "00000000-0000-0000-0000-000000000000") {
        Form {
            OrderEditPaymentSection(
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
