//
//  BLMetrics.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/4/30.
//

import SwiftUI

/// 設計系統共用圓角
enum BLRadius {

    // MARK: - Radius Values

    /// 最小圓角，適合工具列按鈕
    static let extraSmall: CGFloat = 6

    /// 小圓角，適合列、chip 與輸入欄
    static let small: CGFloat = 10

    /// 中圓角，適合 iOS 卡片與基礎控制項
    static let medium: CGFloat = 12

    /// 大圓角，適合 iPadOS 卡片
    static let large: CGFloat = 16

    /// 特大圓角，適合 sheet 或浮層頂部
    static let extraLarge: CGFloat = 22

    /// 膠囊樣式圓角
    static let pill: CGFloat = 999
}

/// 設計系統共用間距
enum BLSpacing {

    // MARK: - Spacing Values

    /// 最小間距
    static let extraSmall: CGFloat = 4

    /// 小間距
    static let small: CGFloat = 8

    /// 中間距
    static let medium: CGFloat = 12

    /// 大間距
    static let large: CGFloat = 16

    /// 特大間距
    static let extraLarge: CGFloat = 24

    /// 區段之間的標準間距
    static let section: CGFloat = 32
}

// MARK: - Preview

#Preview("尺寸與圓角") {
    VStack(alignment: .leading, spacing: BLSpacing.large) {
        HStack(spacing: BLSpacing.medium) {
            RoundedRectangle(cornerRadius: BLRadius.extraSmall)
                .fill(.blue)
                .frame(width: 44, height: 44)

            RoundedRectangle(cornerRadius: BLRadius.medium)
                .fill(.green)
                .frame(width: 44, height: 44)

            RoundedRectangle(cornerRadius: BLRadius.extraLarge)
                .fill(.orange)
                .frame(width: 44, height: 44)
        }
    }
    .padding()
}
