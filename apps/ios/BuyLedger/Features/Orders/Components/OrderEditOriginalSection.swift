//
//  OrderEditOriginalSection.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/8.
//

import SwiftUI

/// 既有訂單的原始單號區段
struct OrderEditOriginalSection: View {

    // MARK: - Properties

    /// 編輯既有訂單時顯示的原始訂單
    let original: LedgerOrder?

    // MARK: - Body

    /// 組合區段或元件的內容
    var body: some View {
        Group {
            if let original {
                Section("orders.edit.label.originalOrders") {
                    orderIdentifier(original.displayID)
                }
            }
        }
    }
}

// MARK: - Private Views

private extension OrderEditOriginalSection {

    /// 原始訂單的短識別碼
    ///
    /// - Parameter identifier: 原始訂單的顯示識別碼
    /// - Returns: 保留等寬數字的系統標籤列
    func orderIdentifier(_ identifier: String) -> some View {
        LabeledContent("orders.list.label.orderNumber", value: identifier)
            .monospacedDigit()
    }
}

// MARK: - Preview

#Preview {
    Form {
        OrderEditOriginalSection(original: LedgerOrder.sampleOrders[0])
    }
}
