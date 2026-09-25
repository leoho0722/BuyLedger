//
//  CustomerTopCard.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/23.
//

import SwiftUI

/// 客戶名單的 Top 客戶卡片，顯示名次、分級與累計消費
struct CustomerTopCard: View {

    // MARK: - Properties

    /// App 根層依語言偏好注入的 locale
    @Environment(\.locale) private var locale

    /// 名次 (1 / 2 / 3)
    let rank: Int

    /// 客戶資料
    let customer: CustomerRow

    // MARK: - Body

    /// Top 客戶卡片內容
    var body: some View {
        BLCard {
            VStack(alignment: .leading, spacing: BLSpacing.small) {
                header

                Divider()

                summary
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Private Views

private extension CustomerTopCard {

    /// 頭像、名稱、分級與名次
    var header: some View {
        HStack(spacing: BLSpacing.small) {
            BLAvatar(name: customer.name, initials: customer.initials, size: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(customer.name)
                    .font(BLTypographyStyle.subhead.font.weight(.semibold))
                    .foregroundStyle(palette.label)

                HStack(spacing: 4) {
                    if customer.tier == .vip {
                        Text("★ VIP")
                            .font(BLTypographyStyle.caption.font.weight(.semibold))
                            .foregroundStyle(palette.orange)
                    } else {
                        Text(LocalizedStringKey(customer.tier.title))
                            .blTextStyle(.caption)
                            .foregroundStyle(palette.secondaryLabel)
                    }

                    Text("·")
                        .foregroundStyle(palette.secondaryLabel)

                    Text("\(customer.orderCount) 單")
                        .blTextStyle(.caption)
                        .foregroundStyle(palette.secondaryLabel)
                }
            }

            Spacer()

            rankBadge
        }
    }

    /// 累計消費與最近訂單日期
    var summary: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text("累計消費")
                    .blTextStyle(.caption)
                    .foregroundStyle(palette.secondaryLabel)
                    .textCase(.uppercase)

                // 金額由卡片的 accessibilityValue 朗讀，這裡隱藏避免重複
                Text(BLFormatters.twd(customer.totalSpent, locale: locale))
                    .blTextStyle(.title3Bold)
                    .monospacedDigit()
                    .foregroundStyle(palette.label)
                    .accessibilityHidden(true)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("最近訂單")
                    .blTextStyle(.caption)
                    .foregroundStyle(palette.secondaryLabel)
                    .textCase(.uppercase)

                Text(BLFormatters.shortDate(customer.lastOrderDate, locale: locale))
                    .font(BLTypographyStyle.subhead.font.weight(.semibold))
                    .foregroundStyle(palette.label)
            }
        }
    }

    /// 名次膠囊，配色依名次決定
    var rankBadge: some View {
        let style = CustomerRankBadgeStyle.style(forRank: rank)

        return Text("#\(rank)")
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .font(BLTypographyStyle.caption.font.weight(.bold))
            .foregroundStyle(style.numeral(in: palette))
            .background(style.background(in: palette))
            .clipShape(Capsule())
    }
}

// MARK: - Private Method

private extension CustomerTopCard {

    /// 畫面色盤
    var palette: BLPalette {
        BLPalette()
    }
}

// MARK: - Preview

#Preview("Top 客戶卡片") {
    CustomerTopCard(
        rank: 1,
        customer: CustomerRow(
            name: "陳小美",
            initials: "陳",
            tier: .vip,
            orderCount: 12,
            totalSpent: 48_600,
            lastOrderDate: Date(timeIntervalSince1970: 1_777_000_000)
        )
    )
    .padding()
}
