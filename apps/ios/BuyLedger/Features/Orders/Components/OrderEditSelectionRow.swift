//
//  OrderEditSelectionRow.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/8.
//

import SwiftUI

/// 保留系統按壓高亮的訂單選擇列
struct OrderEditSelectionRow<Value: View>: View {

    // MARK: - Properties

    /// 開啟對應選擇器的動作
    let action: () -> Void

    /// UI 測試使用的原有識別碼
    let identifier: String

    /// 列的本地化標題
    let title: LocalizedStringKey

    /// 選取值或尚未選取的提示
    let value: Value

    // MARK: - Init

    /// 建立選擇列，保留呼叫端的選取值呈現與無障礙文字
    ///
    /// - Parameters:
    ///   - title: 列的本地化標題
    ///   - identifier: 原有的 UI 測試識別碼
    ///   - action: 點擊列時執行的動作
    ///   - value: 選取值或提示文字
    init(
        title: LocalizedStringKey,
        identifier: String,
        action: @escaping () -> Void,
        @ViewBuilder value: () -> Value
    ) {
        self.title = title
        self.identifier = identifier
        self.action = action
        self.value = value()
    }

    // MARK: - Body

    /// 組合區段或元件的內容
    var body: some View {
        Button(action: action) {
            rowLabel
        }
        .accessibilityIdentifier(identifier)
    }
}

// MARK: - Private Views

private extension OrderEditSelectionRow {

    /// 標題、目前值與裝飾性導覽箭頭
    var rowLabel: some View {
        HStack(spacing: BLSpacing.small) {
            Text(title)
                .foregroundStyle(.primary)

            Spacer(minLength: BLSpacing.small)

            value
                .foregroundStyle(Color.blSecondaryLabel)

            Image(systemName: "chevron.right")
                .font(BLTypographyStyle.caption.font.weight(.semibold))
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
        }
        // 系統按鈕會把標籤染成強調色，以文字色為基準讓階層樣式維持原本的灰階
        .foregroundStyle(BLPalette().label)
        .contentShape(Rectangle())
    }
}

// MARK: - Preview

#Preview {
    Form {
        OrderEditSelectionRow(
            title: "orders.detail.label.orderSource",
            identifier: BLAccessibilityID.OrderEdit.sourceRow,
            action: {
            }
        ) {
            Text("orders.edit.label.selectSource")
        }
    }
}
