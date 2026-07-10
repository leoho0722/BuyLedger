//
//  BLListRow.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/4/30.
//

import SwiftUI

/// 左側標題、右側值的標準列
struct BLListRow: View {

    // MARK: - View Properties

    /// 目前系統深淺色外觀
    @Environment(\.colorScheme) private var colorScheme

    /// 列左側顯示的標題
    let title: String

    /// 列右側顯示的值
    let value: String

    /// 列左側可選的 SF Symbols 名稱
    let systemImage: String?

    // MARK: - Init

    /// 建立標準列
    /// - Parameters:
    ///   - title: 列左側顯示的標題
    ///   - value: 列右側顯示的值
    ///   - systemImage: 列左側可選的 SF Symbols 名稱
    init(_ title: String, value: String, systemImage: String? = nil) {
        self.title = title
        self.value = value
        self.systemImage = systemImage
    }

    // MARK: - View Body

    /// 標準列的畫面內容
    var body: some View {
        let palette = BLTheme.palette(for: colorScheme)

        HStack(spacing: BLSpacing.medium) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(palette.accent)
                    .frame(width: 22)
            }

            Text(title)
                .font(.subheadline)
                .foregroundStyle(palette.label)

            Spacer(minLength: BLSpacing.large)

            Text(value)
                .font(.subheadline)
                .foregroundStyle(palette.secondaryLabel)
                .monospacedDigit()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
    }
}

// MARK: - Preview

#Preview("列表列") {
    BLCard(padding: 0) {
        VStack(spacing: 0) {
            BLListRow("本月預算", value: "$30,000", systemImage: "wallet.pass")
            Divider()
            BLListRow("已記帳", value: "128 筆", systemImage: "checklist")
            Divider()
            BLListRow("同步狀態", value: "CloudKit", systemImage: "icloud")
        }
    }
    .padding()
}
