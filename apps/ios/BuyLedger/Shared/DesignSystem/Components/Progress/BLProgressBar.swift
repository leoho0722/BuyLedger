//
//  BLProgressBar.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/4/30.
//

import SwiftUI

/// 顯示標題、百分比與水平進度的元件
///
/// 內部以系統 `ProgressView` 實作，因此輔助技術讀到的是帶當前值的進度語意，
/// 而非兩段各自獨立的文字；外觀由 ``BLProgressBarStyle`` 這個 `ProgressViewStyle` 承擔
struct BLProgressBar: View {

    // MARK: - View Properties

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
        // 系統進度視圖本身也會截斷超界值，但這裡仍先夾住：
        // 右側顯示的百分比取自同一個值，不夾會讓文字與進度條對不上
        let clampedValue = min(max(value, 0), 1)

        ProgressView(value: clampedValue) {
            Text(LocalizedStringKey(title))
        } currentValueLabel: {
            currentValueLabel(clampedValue: clampedValue)
        }
        .progressViewStyle(BLProgressBarStyle(tint: tint))
    }
}

// MARK: - ViewBuilder

private extension BLProgressBar {

    /// 右側的當前值標籤：有自訂文字時優先，否則顯示百分比
    /// - Parameter clampedValue: 已夾在 `0...1` 的進度值
    /// - Returns: 當前值標籤 view
    @ViewBuilder
    func currentValueLabel(clampedValue: Double) -> some View {
        if let trailingText {
            Text(trailingText)
        } else {
            Text(clampedValue, format: .percent.precision(.fractionLength(0)))
        }
    }
}

// MARK: - ProgressViewStyle

/// ``BLProgressBar`` 的外觀：標題在左、當前值在右，進度軌道在下
///
/// 走 `ProgressViewStyle` 這個系統擴充點而非自繪整個元件，外觀可完全自訂的同時
/// 保住 `ProgressView` 原生的進度語意
struct BLProgressBarStyle: ProgressViewStyle {

    // MARK: - View Properties

    /// 目前系統深淺色外觀
    @Environment(\.colorScheme) private var colorScheme

    /// 可選的進度列色彩；未提供時使用主強調色
    let tint: Color?

    // MARK: - View Body

    /// 回傳套用樣式後的進度列內容
    func makeBody(configuration: Configuration) -> some View {
        let palette = BLTheme.palette(for: colorScheme)

        VStack(alignment: .leading, spacing: 5) {
            HStack {
                configuration.label
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(palette.label)

                Spacer()

                configuration.currentValueLabel
                    .font(.caption)
                    .foregroundStyle(palette.secondaryLabel)
                    .monospacedDigit()
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(palette.fillQuaternary)

                    Capsule()
                        .fill(tint ?? palette.accent)
                        .frame(width: proxy.size.width * (configuration.fractionCompleted ?? 0))
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
