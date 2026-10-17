//
//  BLProgressView.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/4/30.
//

import SwiftUI

/// 顯示標題、目前值與水平進度條的進度列，整列一起朗讀
///
/// - Note: 標題與目前值由本元件繪製，進度條與進度值由系統 `ProgressView` (進度元件)
///   搭配 `BLProgressViewStyle` (進度條外觀樣式) 提供
struct BLProgressView: View {

    // MARK: - Properties

    /// 目前套用的 `locale`，用於格式化進度百分比
    @Environment(\.locale) private var locale

    /// 可選的進度列色彩；未提供時使用主強調色
    var tint: Color? = nil

    /// 進度列左側顯示的標題
    let title: String

    /// 右側顯示文字；未提供時顯示百分比
    var trailingText: String? = nil

    /// 進度值，建議範圍為 `0...1`
    let value: Double

    // MARK: - Body

    /// 上方顯示標題與目前值，下方顯示進度條，整個元件合併成一個朗讀單位
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            header

            progressBar
        }
        // 讓父層合併朗讀與單獨聚焦都能讀到「標題、目前值」
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Private Views

private extension BLProgressView {

    /// 左側顯示標題，右側顯示目前值
    var header: some View {
        HStack {
            Text(LocalizedStringKey(title))
                .font(BLTypographyStyle.caption.font.weight(.semibold))
                .foregroundStyle(.blLabel)

            Spacer()

            currentValueLabel(clampedValue: clampedValue)
                .blTextStyle(.caption)
                .foregroundStyle(.blSecondaryLabel)
                .monospacedDigit()
        }
    }

    /// 以水平進度條顯示完成比例
    var progressBar: some View {
        ProgressView(value: clampedValue)
            .progressViewStyle(BLProgressViewStyle(tint: tint))
    }

    /// 右側的當前值標籤：有自訂文字時優先，否則顯示百分比
    ///
    /// - Parameter clampedValue: 已夾在 `0...1` 的進度值
    /// - Returns: 右側顯示的目前值
    @ViewBuilder
    func currentValueLabel(clampedValue: Double) -> some View {
        if let trailingText {
            Text(trailingText)
        } else {
            Text(BLFormatters.percent(Decimal(clampedValue), locale: locale, fractionLength: 0))
        }
    }
}

// MARK: - Private Method

private extension BLProgressView {

    /// 將進度限制在 `0...1`，讓進度條與右側文字使用同一數值
    var clampedValue: Double {
        min(max(value, 0), 1)
    }
}

// MARK: - Preview

#Preview("進度列") {
    VStack(spacing: BLSpacing.large) {
        BLProgressView(title: "月預算", value: 0.42)

        BLProgressView(tint: .blGreen, title: "固定支出", value: 0.68)

        BLProgressView(tint: .blOrange, title: "超支警示", value: 0.91)
    }
    .padding()
}
