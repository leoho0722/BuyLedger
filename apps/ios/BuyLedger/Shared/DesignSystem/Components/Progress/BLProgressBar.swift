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
    
    /// 進度列左側顯示的標題
    let title: String
    
    /// 進度值，建議範圍為 `0...1`
    let value: Double
    
    /// 可選的進度列色彩；未提供時使用主強調色
    var tint: Color? = nil
    
    /// 右側顯示文字；未提供時顯示百分比
    var trailingText: String? = nil
    
    // MARK: - View Body
    
    /// 進度列的畫面內容
    var body: some View {
        // 先將數值限制在 0 到 1，避免超出進度範圍。
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
struct BLProgressBarStyle: ProgressViewStyle {
    
    // MARK: - View Properties
    
    /// 可選的進度列色彩；未提供時使用主強調色
    let tint: Color?
    
    /// 可選的軌道色彩；未提供時使用系統填色，適合一般淺色表面
    var track: Color? = nil
    
    // MARK: - View Body
    
    /// 回傳套用樣式後的進度列內容
    func makeBody(configuration: Configuration) -> some View {
        let palette = BLPalette()
        
        VStack(alignment: .leading, spacing: 5) {
            // 只有呼叫端提供標題或目前值標籤時才顯示這一列。
            // 純量測的 ProgressView(value:) 沒有標籤，省略以避免多出一段空列間距
            if configuration.label != nil || configuration.currentValueLabel != nil {
                HStack {
                    configuration.label
                        .font(BLTypographyStyle.caption.font.weight(.semibold))
                        .foregroundStyle(palette.label)
                    
                    Spacer()
                    
                    configuration.currentValueLabel
                        .blTextStyle(.caption)
                        .foregroundStyle(palette.secondaryLabel)
                        .monospacedDigit()
                }
            }
            
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(track ?? palette.fillQuaternary)
                    
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
    let palette = BLPalette()
    
    VStack(spacing: BLSpacing.large) {
        BLProgressBar(title: "月預算", value: 0.42)
        BLProgressBar(title: "固定支出", value: 0.68, tint: palette.green)
        BLProgressBar(title: "超支警示", value: 0.91, tint: palette.orange)
    }
    .padding()
}
