//
//  OrderEditPercentField.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/8.
//

import SwiftUI

/// 隨動態字級調整版面的百分比輸入欄
struct OrderEditPercentField: View {

    // MARK: - Properties

    /// 目前的動態字級
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// 對應的表單焦點欄位
    let field: OrderEditFeature.State.Field

    /// 表單共用的鍵盤焦點綁定
    let focusedField: FocusState<OrderEditFeature.State.Field?>.Binding

    /// 欄位的本地化標題
    let title: String

    /// 草稿中 0 至 1 比例值的雙向綁定
    let value: Binding<Decimal>

    // MARK: - Body

    /// 組合區段或元件的內容
    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: BLSpacing.small) {
                    fieldTitle

                    numberField
                }
            } else {
                HStack(alignment: .center, spacing: BLSpacing.small) {
                    fieldTitle

                    numberField
                }
            }
        }
    }
}

// MARK: - Private Views

private extension OrderEditPercentField {

    /// 長標題換行並撐高整列
    var fieldTitle: some View {
        Text(LocalizedStringKey(title))
            .fixedSize(horizontal: false, vertical: true)
    }

    /// 百分比數值與符號，沿用共用的比例換算綁定
    var numberField: some View {
        HStack(spacing: BLSpacing.extraSmall) {
            TextField(
                "",
                value: OrderPercentConversion.percentageBinding(for: value),
                format: Decimal.FormatStyle.number.precision(.fractionLength(2)).grouping(.never)
            )
            .multilineTextAlignment(.trailing)
            .monospacedDigit()
            .labelsHidden()
            .keyboardType(.decimalPad)
            .focused(focusedField, equals: field)

            Text(verbatim: "%")
                .foregroundStyle(.blSecondaryLabel)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .frame(minHeight: BLHitTarget.minimum)
        .contentShape(.rect)
    }
}

// MARK: - Preview

#Preview {
    @Previewable @FocusState var focusedField: OrderEditFeature.State.Field?

    Form {
        OrderEditPercentField(
            field: .cardFeeRate,
            focusedField: $focusedField,
            title: "orders.edit.label.cardFee",
            value: .constant(0.015)
        )
    }
}
