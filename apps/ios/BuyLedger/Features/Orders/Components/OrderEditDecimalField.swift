//
//  OrderEditDecimalField.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/8.
//

import SwiftUI

/// 隨動態字級調整版面的整數金額輸入欄
struct OrderEditDecimalField: View {

    // MARK: - Properties

    /// 目前的動態字級
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// 對應的表單焦點欄位
    let field: OrderEditFeature.State.Field

    /// 表單共用的鍵盤焦點綁定
    let focusedField: FocusState<OrderEditFeature.State.Field?>.Binding

    /// UI 測試定位用的識別碼，未指定時沿用空值
    let identifier: String?

    /// 欄位的本地化標題
    let title: String

    /// 金額的雙向綁定
    let value: Binding<Decimal>

    // MARK: - Init

    /// 建立與表單共用焦點的整數金額欄位
    ///
    /// - Parameters:
    ///   - title: 欄位的本地化標題
    ///   - value: 金額的雙向綁定
    ///   - field: 對應的焦點欄位
    ///   - focusedField: 表單共用的焦點綁定
    ///   - identifier: UI 測試使用的識別碼
    init(
        title: String,
        value: Binding<Decimal>,
        field: OrderEditFeature.State.Field,
        focusedField: FocusState<OrderEditFeature.State.Field?>.Binding,
        identifier: String? = nil
    ) {
        self.title = title
        self.value = value
        self.field = field
        self.focusedField = focusedField
        self.identifier = identifier
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

private extension OrderEditDecimalField {

    /// 長標題換行並撐高整列
    var fieldTitle: some View {
        Text(LocalizedStringKey(title))
            .fixedSize(horizontal: false, vertical: true)
    }

    /// 整數數值輸入，保留鍵盤、對齊、焦點與命中區
    var numberField: some View {
        TextField("", value: value, format: .number.precision(.fractionLength(0)).grouping(.never))
            .frame(maxWidth: .infinity, alignment: .trailing)
            .frame(minHeight: BLHitTarget.minimum)
            .multilineTextAlignment(.trailing)
            .monospacedDigit()
            .labelsHidden()
            .keyboardType(.numberPad)
            .focused(focusedField, equals: field)
            .contentShape(.rect)
            .accessibilityIdentifier(identifier ?? "")
    }
}

// MARK: - Preview

#Preview {
    @Previewable @FocusState var focusedField: OrderEditFeature.State.Field?

    Form {
        OrderEditDecimalField(
            title: "客戶實付",
            value: .constant(1000),
            field: .chargedAmount,
            focusedField: $focusedField,
            identifier: BLAccessibilityID.OrderEdit.chargedAmountField
        )
    }
}
