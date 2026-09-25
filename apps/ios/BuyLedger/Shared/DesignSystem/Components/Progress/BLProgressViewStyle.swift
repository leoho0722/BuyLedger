//
//  BLProgressViewStyle.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/20.
//

import SwiftUI

/// ``BLProgressView`` 的外觀：標題在左、當前值在右，進度軌道在下
struct BLProgressViewStyle {

    // MARK: - Properties

    /// 可選的進度列色彩；未提供時使用主強調色
    let tint: Color?

    /// 可選的軌道色彩；未提供時使用系統填色，適合一般淺色表面
    var track: Color? = nil
}

// MARK: - Computed Properties

private extension BLProgressViewStyle {

    /// 目前外觀對應的色盤
    var palette: BLPalette {
        BLPalette()
    }
}

// MARK: - ProgressViewStyle

extension BLProgressViewStyle: ProgressViewStyle {

    /// 回傳套用樣式後的進度列內容
    ///
    /// - Parameter configuration: 進度列目前的呈現狀態
    /// - Returns: 套用樣式後的進度列內容
    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            // 只有呼叫端提供標題或目前值標籤時才顯示這一列
            // 純量測的 `ProgressView(value:)` 沒有標籤，省略以避免多出一段
            // 空列間距
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
