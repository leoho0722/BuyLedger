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

    /// App 根層依語言偏好注入的 `locale`
    @Environment(\.locale) private var locale

    /// 頭像尺寸，隨 Dynamic Type 縮放
    @ScaledMetric(relativeTo: .body) private var avatarSize: CGFloat = 44

    /// 客戶資料
    let customer: CustomerRow

    /// 名次 (1 / 2 / 3)
    let rank: Int

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
            // 姓名就在同一卡片內，頭像屬重複資訊；標為裝飾避免被朗讀兩次
            BLAvatar(
                name: customer.name,
                initials: customer.initials,
                size: avatarSize,
                isDecorative: true
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(customer.name)
                    .font(BLTypographyStyle.subhead.font.weight(.semibold))
                    .foregroundStyle(.blLabel)

                HStack(spacing: BLSpacing.extraSmall) {
                    if customer.tier == .vip {
                        Text(verbatim: "★ VIP")
                            .font(BLTypographyStyle.caption.font.weight(.semibold))
                            .foregroundStyle(.blOrange)
                    } else {
                        Text(LocalizedStringKey(customer.tier.title))
                            .blTextStyle(.caption)
                            .foregroundStyle(.blSecondaryLabel)
                    }

                    Text(verbatim: "·")
                        .foregroundStyle(.blSecondaryLabel)

                    Text(
                        AppLanguage.format(
                            "customers.list.label.orderCount",
                            customer.orderCount,
                            locale: locale
                        )
                    )
                        .blTextStyle(.caption)
                        .foregroundStyle(.blSecondaryLabel)
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
                Text("customers.list.label.totalSpending")
                    .blTextStyle(.caption)
                    .foregroundStyle(.blSecondaryLabel)
                    .textCase(.uppercase)

                // 金額由卡片的 `accessibilityValue` 朗讀，這裡隱藏避免重複
                Text(BLFormatters.twd(customer.totalSpent, locale: locale))
                    .blTextStyle(.title3Bold)
                    .monospacedDigit()
                    .foregroundStyle(.blLabel)
                    .accessibilityHidden(true)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("customers.list.label.recentOrders")
                    .blTextStyle(.caption)
                    .foregroundStyle(.blSecondaryLabel)
                    .textCase(.uppercase)

                Text(BLFormatters.shortDate(customer.lastOrderDate, locale: locale))
                    .font(BLTypographyStyle.subhead.font.weight(.semibold))
                    .foregroundStyle(.blLabel)
            }
        }
    }

    /// 名次膠囊，配色依名次決定
    var rankBadge: some View {
        let style = CustomerRankBadgeStyle.style(forRank: rank)

        return Text(verbatim: CustomerFormatters.rankLabel(rank))
            .padding(.horizontal, BLSpacing.small)
            .padding(.vertical, 2)
            .font(BLTypographyStyle.caption.font.weight(.bold))
            .foregroundStyle(style.numeral)
            .background(style.background)
            .clipShape(Capsule())
    }
}

// MARK: - Preview

#Preview("Top 客戶卡片") {
    CustomerTopCard(
        customer: CustomerRow(
            name: "陳小美",
            initials: "陳",
            tier: .vip,
            orderCount: 12,
            totalSpent: 48_600,
            lastOrderDate: Date(timeIntervalSince1970: 1_777_000_000)
        ),
        rank: 1
    )
    .padding()
}
