//
//  BLPhotoThumbnailButtonStyle.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/20.
//

import SwiftUI

/// BLPhotoThumbnail 使用的按鈕樣式：不改變影像著色，只在按下時給視覺回饋
struct BLPhotoThumbnailButtonStyle {

    // MARK: - Properties

    /// 是否已開啟「減少動態效果」
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
}

// MARK: - ButtonStyle

extension BLPhotoThumbnailButtonStyle: ButtonStyle {

    /// 回傳套用樣式後的按鈕內容
    /// - Parameter configuration: 按鈕目前的互動狀態
    /// - Returns: 套用樣式後的按鈕內容
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.72 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(
                reduceMotion ? nil : .snappy(duration: 0.14),
                value: configuration.isPressed
            )
    }
}
