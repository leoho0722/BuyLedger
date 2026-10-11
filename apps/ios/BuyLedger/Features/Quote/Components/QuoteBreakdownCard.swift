//
//  QuoteBreakdownCard.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/23.
//

import SwiftUI

/// 報價試算的成本拆解卡片
struct QuoteBreakdownCard: View {

    // MARK: - Properties

    /// 是否有可用匯率資料
    let hasUsableRate: Bool

    /// 商品本金折合 TWD
    let itemTWD: Decimal

    /// 當地運費折合 TWD
    let domesticTWD: Decimal

    /// 國際運費 TWD
    let internationalShippingTWD: Decimal

    /// 刷卡手續費 TWD
    let cardFeeTWD: Decimal

    /// 金流手續費 TWD
    let paymentFeeTWD: Decimal

    /// 平台手續費 TWD
    let platformFeeTWD: Decimal

    /// 總成本 TWD
    let costTWD: Decimal

    /// App 根層依語言偏好注入的 locale
    @Environment(\.locale) private var locale

    // MARK: - Body

    /// 成本拆解卡片內容
    @ViewBuilder
    var body: some View {
        if hasUsableRate {
            usableContent
        } else {
            unavailableContent
        }
    }
}

// MARK: - Private Views

private extension QuoteBreakdownCard {

    /// 無匯率時顯示的說明性空狀態
    var unavailableContent: some View {
        BLCard {
            ContentUnavailableView {
                Label("quote.calculator.label.exchangeRateAvailable", systemImage: "dollarsign.arrow.circlepath")
            } description: {
                Text("quote.calculator.message.networkConnectionNeeded")
            }
            .frame(maxWidth: .infinity)
        }
    }

    /// 有可用匯率時的成本拆解內容
    var usableContent: some View {
        let total = max(costTWD, 1)

        return BLCard {
            VStack(alignment: .leading, spacing: BLSpacing.medium) {
                Text("orders.detail.label.costBreakdown")
                    .font(BLTypographyStyle.caption.font.weight(.semibold))
                    .foregroundStyle(palette.secondaryLabel)
                    .textCase(.uppercase)

                ForEach(items) { item in
                    breakdownRow(item: item, total: total)
                }

                Divider()

                HStack {
                    Text("orders.detail.label.totalCost")
                        .font(BLTypographyStyle.subhead.font.weight(.semibold))
                        .foregroundStyle(palette.label)

                    Spacer()

                    Text(BLFormatters.twd(costTWD, locale: locale))
                        .font(BLTypographyStyle.subhead.font.bold())
                        .monospacedDigit()
                        .foregroundStyle(palette.label)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// 成本拆解的一列，顯示比例與 TWD 金額
    ///
    /// - Parameters:
    ///   - item: 成本拆解項目
    ///   - total: 用來計算占比的總成本
    /// - Returns: 成本拆解列 view
    @ViewBuilder
    func breakdownRow(item: BreakdownItem, total: Decimal) -> some View {
        let fraction = total > 0 ? item.value / total : 0
        let fractionDouble = NSDecimalNumber(decimal: fraction).doubleValue

        BLProgressView(
            title: item.label,
            value: fractionDouble,
            tint: item.color,
            trailingText: BLFormatters.twd(item.value, locale: locale)
        )
    }
}

// MARK: - Nested Types

private extension QuoteBreakdownCard {

    /// 成本拆解的一列資料
    struct BreakdownItem: Identifiable {

        /// 拆解項目名稱
        let label: String

        /// 拆解項目金額
        let value: Decimal

        /// 進度條與分類的識別色
        let color: Color

        /// 以標籤作為穩定識別值
        var id: String {
            label
        }
    }
}

// MARK: - Private Method

private extension QuoteBreakdownCard {

    /// 目前外觀使用的色盤
    var palette: BLPalette {
        BLPalette()
    }

    /// 成本拆解項目清單
    var items: [BreakdownItem] {
        [
            BreakdownItem(label: "orders.detail.label.itemCost", value: itemTWD, color: palette.accent),
            BreakdownItem(label: "quote.calculator.label.localShipping", value: domesticTWD, color: palette.teal),
            BreakdownItem(
                label: "orders.detail.label.internationalShipping",
                value: internationalShippingTWD,
                color: palette.purple
            ),
            BreakdownItem(label: "orders.detail.label.cardFee", value: cardFeeTWD, color: palette.orange),
            BreakdownItem(label: "orders.detail.label.paymentProcessingFee", value: paymentFeeTWD, color: palette.pink),
            BreakdownItem(label: "orders.detail.label.platformFee", value: platformFeeTWD, color: palette.indigo),
        ]
    }
}

// MARK: - Preview

#Preview("可試算") {
    QuoteBreakdownCard(
        hasUsableRate: true,
        itemTWD: 3_250,
        domesticTWD: 130,
        internationalShippingTWD: 180,
        cardFeeTWD: 48,
        paymentFeeTWD: 65,
        platformFeeTWD: 97,
        costTWD: 3_770
    )
    .padding()
}

#Preview("無可用匯率") {
    QuoteBreakdownCard(
        hasUsableRate: false,
        itemTWD: 0,
        domesticTWD: 0,
        internationalShippingTWD: 180,
        cardFeeTWD: 0,
        paymentFeeTWD: 0,
        platformFeeTWD: 0,
        costTWD: 180
    )
    .padding()
}
