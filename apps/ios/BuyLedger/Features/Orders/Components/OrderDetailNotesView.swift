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

    /// 詳情採用的窄欄或寬欄版面
    let layout: OrderDetailView.OrderDetailLayout

    /// 目前詳情顯示的訂單
    let order: LedgerOrder

    // MARK: - Body

    /// 詳情區段的畫面骨架
    var body: some View {
        switch layout {
        case .compact:
            compactNotes

        case .wide:
            wideNotesCard
        }
    }
}

// MARK: - Private Views

private extension OrderDetailNotesView {

    /// 窄欄版面的唯讀備註卡片，由父層判斷有備註時顯示
    @ViewBuilder
    var compactNotes: some View {
        VStack(alignment: .leading, spacing: BLSpacing.small) {
            Text("備註")
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

    /// 寬欄版面的唯讀備註卡片
    var wideNotesCard: some View {
        BLCard {
            VStack(alignment: .leading, spacing: BLSpacing.small) {
                Text("備註")
                    .font(BLTypographyStyle.footnote.font.weight(.semibold))
                    .foregroundStyle(palette.secondaryLabel)
                    .textCase(.uppercase)

                Text(order.notes)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .blTextStyle(.subhead)
                    .foregroundStyle(palette.label)
                    .textSelection(.enabled)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Private Method

private extension OrderDetailNotesView {

    /// 依目前外觀取得的色盤
    var palette: BLPalette {
        BLPalette()
    }
}

// MARK: - Preview

#Preview("訂單詳情區段") {
    OrderDetailNotesView(layout: .compact, order: LedgerOrder.sampleOrders[0])
}
