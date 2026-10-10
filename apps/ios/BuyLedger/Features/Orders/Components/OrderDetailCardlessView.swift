//
//  OrderDetailCardlessView.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/9.
//

import SwiftUI

/// 詳情中的無卡折抵與補款明細卡片
struct OrderDetailCardlessView: View {

    // MARK: - Properties

    /// App 目前選用的語系
    @Environment(\.locale) private var locale

    /// 目前詳情顯示的訂單
    let order: LedgerOrder

    // MARK: - Body

    /// 畫面骨架，內容由下方的具名區段組成
    var body: some View {
        adjustmentsCard
    }
}

// MARK: - Private Views

private extension OrderDetailCardlessView {

    /// 無卡明細卡片，由父層在有折抵或補款金額時顯示
    var adjustmentsCard: some View {
        BLCard {
            VStack(alignment: .leading, spacing: BLSpacing.small) {
                Text("無卡明細")
                    .font(BLTypographyStyle.footnote.font.weight(.semibold))
                    .foregroundStyle(palette.secondaryLabel)
                    .textCase(.uppercase)

                HStack {
                    Text("無卡折抵金額")
                        .blTextStyle(.subhead)
                        .foregroundStyle(palette.label)

                    Spacer()

                    Text(OrderFormatters.minusTWD(order.cardlessDeductionAmount, locale: locale))
                        .font(BLTypographyStyle.subhead.font.weight(.semibold))
                        .monospacedDigit()
                        .foregroundStyle(palette.red)
                }
                .accessibilityElement(children: .combine)

                HStack {
                    Text("無卡補款金額")
                        .blTextStyle(.subhead)
                        .foregroundStyle(palette.label)

                    Spacer()

                    Text(OrderFormatters.plusTWD(order.cardlessSupplementAmount, locale: locale))
                        .font(BLTypographyStyle.subhead.font.weight(.semibold))
                        .monospacedDigit()
                        .foregroundStyle(palette.green)
                }
                .accessibilityElement(children: .combine)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Private Method

private extension OrderDetailCardlessView {

    /// 無卡明細使用的目前外觀色盤
    var palette: BLPalette {
        BLPalette()
    }
}

// MARK: - Preview

#Preview("詳情中的無卡折抵與補款明細卡片") {
    OrderDetailCardlessView(order: LedgerOrder.sampleOrders[0])
}
