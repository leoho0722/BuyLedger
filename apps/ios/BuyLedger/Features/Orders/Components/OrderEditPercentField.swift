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

    // MARK: - Init

    /// 建立與表單共用焦點的百分比欄位
    ///
    /// - Parameters:
    ///   - title: 欄位的本地化標題
    ///   - value: 草稿比例值的雙向綁定
    ///   - field: 對應的焦點欄位
    ///   - focusedField: 表單共用的焦點綁定
    init(
        title: String,
        value: Binding<Decimal>,
        field: OrderEditFeature.State.Field,
        focusedField: FocusState<OrderEditFeature.State.Field?>.Binding
    ) {
        self.title = title
        self.value = value
        self.field = field
        self.focusedField = focusedField
    }

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
        HStack(spacing: 4) {
            TextField(
                "",
                value: Self.percentageBinding(for: value),
                format: Decimal.FormatStyle.number.precision(.fractionLength(2)).grouping(.never)
            )
            .multilineTextAlignment(.trailing)
            .monospacedDigit()
            .labelsHidden()
            .keyboardType(.decimalPad)
            .focused(focusedField, equals: field)

            Text(verbatim: "%")
                .foregroundStyle(Color.blSecondaryLabel)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .frame(minHeight: BLHitTarget.minimum)
        .contentShape(.rect)
    }
}

// MARK: - Internal Method

extension OrderEditPercentField {

    /// 以畫面與測試共用的換算方式建立百分比綁定，相同費率不重複寫回
    ///
    /// - Parameter rate: 草稿中儲存比例值的綁定
    /// - Returns: 顯示與接收百分比的十進位綁定
    static func percentageBinding(for rate: Binding<Decimal>) -> Binding<Decimal> {
        Binding {
            OrderPercentConversion.percentage(from: rate.wrappedValue)
        } set: { newValue in
            let converted = OrderPercentConversion.rate(from: newValue)
            guard converted != rate.wrappedValue else {
                return
            }
            rate.wrappedValue = converted
        }
    }
}

// MARK: - Preview

#Preview {
    @Previewable @FocusState var focusedField: OrderEditFeature.State.Field?

    Form {
        OrderEditPercentField(
            title: "orders.edit.label.cardFee",
            value: .constant(0.015),
            field: .cardFeeRate,
            focusedField: $focusedField
        )
    }
}
