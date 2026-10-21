//
//  OrderDetailNotesView.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/9.
//

import SwiftUI

/// 詳情中唯讀的備註卡片
struct OrderDetailNotesView: View {

    // MARK: - Properties

    /// 目前詳情顯示的訂單
    let order: LedgerOrder

    // MARK: - Body

    /// 呈現備註標題與內文，並允許選取內文文字
    var body: some View {
        notesSection
    }
}

// MARK: - Private Views

private extension OrderDetailNotesView {

    /// 顯示唯讀備註卡片，由父層判斷有備註時呈現
    @ViewBuilder
    var notesSection: some View {
        VStack(alignment: .leading, spacing: BLSpacing.small) {
            Text("orders.detail.label.notes")
                .blTextStyle(.headline)

            BLCard {
                Text(order.notes)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .blTextStyle(.subhead)
                    .textSelection(.enabled)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Preview

#Preview("訂單詳情區段") {
    OrderDetailNotesView(order: LedgerOrder.sampleOrders[0])
}
