//
//  OrderEditFeesSection.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/8.
//

import ComposableArchitecture
import SwiftUI

/// 訂單三種費率的手續費區段
struct OrderEditFeesSection: View {

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

private extension OrderEditFeesSection {

    /// 刷卡、平台與金流費率的百分比欄位
    @ViewBuilder
    var fields: some View {
        OrderEditPercentField(
            title: "刷卡手續費 %",
            value: $store.draft.cardFeeRate,
            field: .cardFeeRate,
            focusedField: focusedField
        )

        OrderEditPercentField(
            title: "平台手續費 %",
            value: $store.draft.platformFeeRate,
            field: .platformFeeRate,
            focusedField: focusedField
        )

        OrderEditPercentField(
            title: "金流手續費 %",
            value: $store.draft.paymentFeeRate,
            field: .paymentFeeRate,
            focusedField: focusedField
        )
    }

    /// 手續費的百分比標題
    var sectionHeader: some View {
        Text("手續費 (%)")
    }

    /// 百分比輸入方式與有效範圍說明
    @ViewBuilder
    var sectionFooter: some View {
        Text("輸入百分比例如 1.5 表示 1.5%；超出 0%–100% 範圍會自動限制。")
            .blTextStyle(.footnote)
            .foregroundStyle(Color.blSecondaryLabel)
    }
}

// MARK: - Preview

#Preview {
    @Previewable @FocusState var focusedField: OrderEditFeature.State.Field?

    if let id = UUID(uuidString: "00000000-0000-0000-0000-000000000000") {
        Form {
            OrderEditFeesSection(
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
