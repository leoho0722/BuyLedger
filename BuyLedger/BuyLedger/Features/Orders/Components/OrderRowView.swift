//
//  OrderRowView.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import SwiftUI

/// 訂單列表中的單列摘要。
struct OrderRowView: View {

    // MARK: - View Properties

    /// 要顯示的訂單。
    let order: LedgerOrder

    // MARK: - View Body

    /// 訂單列的畫面內容。
    var body: some View {
        let summary = order.summary

        HStack(spacing: BLSpacing.medium) {
            BLAvatar(
                name: order.customer.name,
                initials: order.customer.initials,
                size: 40
            )

            VStack(alignment: .leading, spacing: BLSpacing.extraSmall) {
                HStack(spacing: BLSpacing.extraSmall) {
                    Text(order.customer.name)
                        .font(.subheadline.weight(.semibold))

                    Text("·")
                        .foregroundStyle(.tertiary)

                    Text(String(order.id.suffix(3)))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }

                Text(order.itemSummary)
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                HStack(spacing: BLSpacing.small) {
                    BLStatusPill(order.status.title, tone: order.status.tone)

                    Text(OrderFormatters.shortDate(order.date))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: BLSpacing.medium)

            VStack(alignment: .trailing, spacing: BLSpacing.extraSmall) {
                Text(OrderFormatters.twd(summary.revenue))
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()

                Text("\(summary.profit >= 0 ? "+" : "")\(OrderFormatters.twd(summary.profit))")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(summary.profit >= 0 ? .green : .red)
                    .monospacedDigit()
            }
        }
        .padding(.vertical, BLSpacing.extraSmall)
    }
}

// MARK: - ViewBuilder

private extension OrderRowView {}

// MARK: - Preview

#Preview("訂單列") {
    List {
        OrderRowView(order: LedgerOrder.sampleOrders[0])
    }
}
