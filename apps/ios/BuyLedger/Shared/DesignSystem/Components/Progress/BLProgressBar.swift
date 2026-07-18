//
//  BLProgressBar.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/4/30.
//

import SwiftUI

/// 顯示標題、百分比與水平進度的元件
struct BLProgressBar: View {

    // MARK: - View Properties

    /// 目前系統深淺色外觀
    @Environment(\.colorScheme) private var colorScheme

    /// 進度列左側顯示的標題
    let title: String

    /// 進度值，建議範圍為 `0...1`
    let value: Double

    /// 可選的進度列色彩；未提供時使用主強調色
    var tint: Color? = nil

    /// 可選的右側顯示文字；提供時會取代預設的百分比顯示，方便顯示金額或自訂格式的字串
    var trailingText: String? = nil

    // MARK: - View Body

    /// 進度列的畫面內容
    var body: some View {
        let palette = BLTheme.palette(for: colorScheme)
        let clampedValue = min(max(value, 0), 1)

        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(LocalizedStringKey(title))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(palette.label)

                Spacer()

                if let trailingText {
                    Text(trailingText)
                        .font(.caption)
                        .foregroundStyle(palette.secondaryLabel)
                        .monospacedDigit()
                } else {
                    Text(clampedValue, format: .percent.precision(.fractionLength(0)))
                        .font(.caption)
                        .foregroundStyle(palette.secondaryLabel)
                        .monospacedDigit()
                }
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(palette.fillQuaternary)

                    Capsule()
                        .fill(tint ?? palette.accent)
                        .frame(width: proxy.size.width * clampedValue)
                }
            }
            .frame(height: 6)
        }
    }
}

// MARK: - Preview

#Preview("進度列") {
    VStack(spacing: BLSpacing.large) {
        BLProgressBar(title: "月預算", value: 0.42)
        BLProgressBar(title: "固定支出", value: 0.68, tint: .green)
        BLProgressBar(title: "超支警示", value: 0.91, tint: .orange)
    }
    .padding()
}
