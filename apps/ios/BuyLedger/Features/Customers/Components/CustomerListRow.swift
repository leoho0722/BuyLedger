//
//  CustomerListRow.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/23.
//

import SwiftUI

/// 客戶名單的單列：姓名、分級、累計消費與最近訂單日期
struct CustomerListRow: View {

    // MARK: - Properties

    /// 頭像基準尺寸；列間分隔線的縮排由它推導，呼叫端不另寫死
    static let avatarSize: CGFloat = 36

    /// App 根層依語言偏好注入的 locale
    @Environment(\.locale) private var locale

    /// 隨 Dynamic Type 縮放的頭像尺寸
    @ScaledMetric(relativeTo: .body) private var avatarSize: CGFloat = CustomerListRow.avatarSize

    /// 客戶資料
    let customer: CustomerRow

    // MARK: - Body

    /// 客戶列內容
    var body: some View {
        HStack(spacing: BLSpacing.small) {
            BLAvatar(name: customer.name, initials: customer.initials, size: avatarSize)

            identity

            Spacer()

            amounts
        }
        .padding(.horizontal, BLSpacing.large)
        .padding(.vertical, BLSpacing.medium)
    }
}

// MARK: - Private Views

private extension CustomerListRow {

    /// 姓名與分級、筆數
    var identity: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(customer.name)
                .font(BLTypographyStyle.subhead.font.weight(.semibold))
                .foregroundStyle(palette.label)

            HStack(spacing: 4) {
                Text(LocalizedStringKey(customer.tier.title))
                    .blTextStyle(.caption)
                    .foregroundStyle(
                        customer.tier == .vip
                            ? palette.orange
                            : palette.secondaryLabel
                    )

                Text("·")
                    .foregroundStyle(palette.secondaryLabel)

                Text("\(customer.orderCount) 單")
                    .blTextStyle(.caption)
                    .foregroundStyle(palette.secondaryLabel)
            }
        }
    }

    /// 累計消費與最近訂單日期
    var amounts: some View {
        VStack(alignment: .trailing, spacing: 2) {
            // 金額已放入呼叫端的 accessibilityValue，避免重複朗讀
            Text(BLFormatters.twd(customer.totalSpent, locale: locale))
                .font(BLTypographyStyle.subhead.font.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(palette.label)
                .accessibilityHidden(true)

            Text(BLFormatters.shortDate(customer.lastOrderDate, locale: locale))
                .blTextStyle(.caption)
                .foregroundStyle(palette.secondaryLabel)
        }
    }
}

// MARK: - Internal Method

extension CustomerListRow {

    /// 讓列間分隔線對齊文字起點的左側縮排
    ///
    /// - Parameter avatarSize: 已隨 Dynamic Type 縮放的頭像尺寸
    /// - Returns: 分隔線的左側縮排
    static func dividerInset(avatarSize: CGFloat) -> CGFloat {
        BLSpacing.large + avatarSize + BLSpacing.small
    }
}

// MARK: - Private Method

private extension CustomerListRow {

    /// 畫面色盤
    var palette: BLPalette {
        BLPalette()
    }
}

// MARK: - Preview

#Preview("客戶列") {
    VStack(spacing: 0) {
        CustomerListRow(
            customer: CustomerRow(
                name: "陳小美",
                initials: "陳",
                tier: .vip,
                orderCount: 12,
                totalSpent: 48_600,
                lastOrderDate: Date(timeIntervalSince1970: 1_777_000_000)
            )
        )

        Divider()
            .padding(.leading, CustomerListRow.dividerInset(avatarSize: CustomerListRow.avatarSize))

        CustomerListRow(
            customer: CustomerRow(
                name: "林大同",
                initials: "林",
                tier: .regular,
                orderCount: 3,
                totalSpent: 5_200,
                lastOrderDate: Date(timeIntervalSince1970: 1_776_000_000)
            )
        )
    }
}
