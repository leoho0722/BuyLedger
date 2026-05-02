//
//  OrderRowCompactView.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import SwiftUI

/// iPad 中間訂單清單欄使用的緊湊型訂單列。
///
/// 對應設計稿 iPad split view 中段欄的列樣式：頂部「客戶名稱 + 單號末三碼」、單行商品名、底部「狀態膠囊 + 獲利」，省略 iPhone 主列表上的日期與營收欄位以維持 320 px 內可讀。
struct OrderRowCompactView: View {

    // MARK: - View Properties

    /// 要顯示的訂單。
    let order: LedgerOrder

    /// 目前系統深淺色外觀。
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - View Body

    /// 訂單列的畫面內容。
    var body: some View {
        let palette = BLTheme.palette(for: colorScheme)
        let summary = order.summary

        HStack(alignment: .top, spacing: BLSpacing.small) {
            BLAvatar(
                name: order.customer.name,
                initials: order.customer.initials,
                size: 32
            )

            VStack(alignment: .leading, spacing: BLSpacing.extraSmall) {
                HStack(alignment: .firstTextBaseline, spacing: BLSpacing.small) {
                    Text(order.customer.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(palette.label)
                        .lineLimit(1)

                    Spacer(minLength: 0)

                    Text(String(order.id.suffix(3)))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(palette.tertiaryLabel)
                }

                Text(order.primaryItemDescription)
                    .font(.footnote)
                    .foregroundStyle(palette.secondaryLabel)
                    .lineLimit(1)

                HStack(alignment: .center, spacing: BLSpacing.small) {
                    BLStatusPill(order.status.title, tone: order.status.tone)

                    Spacer(minLength: 0)

                    Text(profitText(summary.profit))
                        .font(.footnote.weight(.semibold))
                        .monospacedDigit()
                        .foregroundStyle(summary.profit >= 0 ? palette.green : palette.red)
                }
            }
        }
        .padding(.vertical, BLSpacing.extraSmall)
    }
}

// MARK: - Private Method

private extension OrderRowCompactView {

    /// 將獲利金額格式化為帶正負號的字串。
    /// - Parameter profit: 獲利金額。
    /// - Returns: 含 `+` 或 `-` 前綴的格式化字串。
    func profitText(_ profit: Decimal) -> String {
        let formatted = OrderFormatters.twd(profit)

        return profit >= 0 ? "+\(formatted)" : formatted
    }
}

// MARK: - Preview

#Preview("緊湊型訂單列") {
    List {
        ForEach(LedgerOrder.sampleOrders.prefix(4)) { order in
            OrderRowCompactView(order: order)
        }
    }
    .listStyle(.plain)
    .frame(width: 320)
}
