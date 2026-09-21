//
//  BLProgressView.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/4/30.
//

import SwiftUI

/// 顯示標題、百分比與水平進度的元件
struct BLProgressView: View {

    // MARK: - Properties

    /// 目前套用的 locale，用於格式化進度百分比
    @Environment(\.locale) private var locale

    /// 進度列左側顯示的標題
    let title: String

    /// 進度值，建議範圍為 `0...1`
    let value: Double

    /// 可選的進度列色彩；未提供時使用主強調色
    var tint: Color? = nil

    /// 右側顯示文字；未提供時顯示百分比
    var trailingText: String? = nil

    // MARK: - Body

    /// 進度列的畫面內容
    var body: some View {
        // 先將數值限制在 0 到 1，避免超出進度範圍
        // 右側顯示的百分比取自同一個值，不夾會讓文字與進度條對不上
        ProgressView(value: clampedValue) {
            Text(LocalizedStringKey(title))
        } currentValueLabel: {
            currentValueLabel(clampedValue: clampedValue)
        }
        .progressViewStyle(BLProgressViewStyle(tint: tint))
    }
}

// MARK: - Private Views

private extension BLProgressView {

    /// 右側的當前值標籤：有自訂文字時優先，否則顯示百分比
    /// - Parameter clampedValue: 已夾在 `0...1` 的進度值
    /// - Returns: 當前值標籤 view
    @ViewBuilder
    func currentValueLabel(clampedValue: Double) -> some View {
        if let trailingText {
            Text(trailingText)
        } else {
            Text(
                BLFormatters.percent(
                    Decimal(clampedValue),
                    locale: locale,
                    fractionLength: 0
                )
            )
        }
    }
}

// MARK: - Computed Properties

private extension BLProgressView {

    /// 將進度限制在 `0...1`，讓進度條與右側文字使用同一數值
    var clampedValue: Double {
        min(max(value, 0), 1)
    }
}

// MARK: - Preview

#Preview("進度列") {
    let palette = BLPalette()

    VStack(spacing: BLSpacing.large) {
        BLProgressView(title: "月預算", value: 0.42)
        BLProgressView(title: "固定支出", value: 0.68, tint: palette.green)
        BLProgressView(title: "超支警示", value: 0.91, tint: palette.orange)
    }
    .padding()
}
