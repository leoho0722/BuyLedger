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

    /// App 根層依語言偏好注入的 `locale`
    @Environment(\.locale) private var locale

    /// 刷卡手續費 TWD
    let cardFeeTWD: Decimal

    /// 總成本 TWD
    let costTWD: Decimal

    /// 當地運費折合 TWD
    let domesticTWD: Decimal

    /// 是否有可用匯率資料
    let hasUsableRate: Bool

    /// 國際運費 TWD
    let internationalShippingTWD: Decimal

    /// 商品本金折合 TWD
    let itemTWD: Decimal

    /// 金流手續費 TWD
    let paymentFeeTWD: Decimal

    /// 平台手續費 TWD
    let platformFeeTWD: Decimal

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
                Label(
                    "quote.calculator.label.exchangeRateAvailable",
                    systemImage: "dollarsign.arrow.circlepath"
                )
            } description: {
                Text("quote.calculator.message.networkConnectionNeeded")
            }
            .frame(maxWidth: .infinity)
        }
    }

    /// 有可用匯率時的成本拆解內容
    var usableContent: some View {
        BLCard {
            VStack(alignment: .leading, spacing: BLSpacing.medium) {
                Text("orders.detail.label.costBreakdown")
                    .font(BLTypographyStyle.caption.font.weight(.semibold))
                    .foregroundStyle(.blSecondaryLabel)
                    .textCase(.uppercase)

                ForEach(items) {
                    breakdownRow(item: $0)
                }

                Divider()

                HStack {
                    Text("orders.detail.label.totalCost")
                        .font(BLTypographyStyle.subhead.font.weight(.semibold))
                        .foregroundStyle(.blLabel)

                    Spacer()

                    Text(BLFormatters.twd(costTWD, locale: locale))
                        .font(BLTypographyStyle.subhead.font.bold())
                        .monospacedDigit()
                        .foregroundStyle(.blLabel)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// 組出成本拆解的一列，顯示比例與 TWD 金額
    ///
    /// - Parameter item: 成本拆解項目
    /// - Returns: 成本拆解列 view
    @ViewBuilder
    func breakdownRow(item: BreakdownItem) -> some View {
        BLProgressView(
            tint: item.color,
            title: item.label,
            trailingText: BLFormatters.twd(item.value, locale: locale),
            value: QuoteFormatters.costShare(of: item.value, costTWD: costTWD)
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

    /// 成本拆解項目清單
    var items: [BreakdownItem] {
        [
            BreakdownItem(label: "orders.detail.label.itemCost", value: itemTWD, color: .blAccent),
            BreakdownItem(
                label: "quote.calculator.label.localShipping",
                value: domesticTWD,
                color: .blTeal
            ),
            BreakdownItem(
                label: "orders.detail.label.internationalShipping",
                value: internationalShippingTWD,
                color: .blPurple
            ),
            BreakdownItem(
                label: "orders.detail.label.cardFee",
                value: cardFeeTWD,
                color: .blOrange
            ),
            BreakdownItem(
                label: "orders.detail.label.paymentProcessingFee",
                value: paymentFeeTWD,
                color: .blPink
            ),
            BreakdownItem(
                label: "orders.detail.label.platformFee",
                value: platformFeeTWD,
                color: .blIndigo
            ),
        ]
    }
}

// MARK: - Preview

#Preview("可試算") {
    QuoteBreakdownCard(
        cardFeeTWD: 48,
        costTWD: 3_770,
        domesticTWD: 130,
        hasUsableRate: true,
        internationalShippingTWD: 180,
        itemTWD: 3_250,
        paymentFeeTWD: 65,
        platformFeeTWD: 97
    )
    .padding()
}

#Preview("無可用匯率") {
    QuoteBreakdownCard(
        cardFeeTWD: 0,
        costTWD: 180,
        domesticTWD: 0,
        hasUsableRate: false,
        internationalShippingTWD: 180,
        itemTWD: 0,
        paymentFeeTWD: 0,
        platformFeeTWD: 0
    )
    .padding()
}
