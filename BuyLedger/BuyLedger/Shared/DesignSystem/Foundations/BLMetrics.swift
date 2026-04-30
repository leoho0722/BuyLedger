//
//  BLMetrics.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/4/30.
//

import SwiftUI

/// 設計系統共用圓角。
enum BLRadius {

    // MARK: - Radius Values

    /// 最小圓角，適合 macOS 工具列按鈕。
    static let extraSmall: CGFloat = 6

    /// 小圓角，適合列、chip 與輸入欄。
    static let small: CGFloat = 10

    /// 中圓角，適合 iOS 卡片與基礎控制項。
    static let medium: CGFloat = 12

    /// 大圓角，適合 iPadOS 與 macOS 卡片。
    static let large: CGFloat = 16

    /// 特大圓角，適合 sheet 或浮層頂部。
    static let extraLarge: CGFloat = 22

    /// 膠囊樣式圓角。
    static let pill: CGFloat = 999
}

/// 設計系統共用間距。
enum BLSpacing {

    // MARK: - Spacing Values

    /// 最小間距。
    static let extraSmall: CGFloat = 4

    /// 小間距。
    static let small: CGFloat = 8

    /// 中間距。
    static let medium: CGFloat = 12

    /// 大間距。
    static let large: CGFloat = 16

    /// 特大間距。
    static let extraLarge: CGFloat = 24

    /// 區段之間的標準間距。
    static let section: CGFloat = 32
}

/// 套用卡片陰影，並在深色模式改以分隔線表達層級。
struct BLCardShadow: ViewModifier {

    // MARK: - View Properties

    /// 目前系統深淺色外觀。
    @Environment(\.colorScheme) private var colorScheme

    /// 指示是否使用浮層陰影。
    let floating: Bool

    // MARK: - View Body

    /// 回傳套用陰影後的內容。
    func body(content: Content) -> some View {
        if colorScheme == .dark {
            content
        } else if floating {
            content.shadow(color: .black.opacity(0.18), radius: 32, x: 0, y: 12)
        } else {
            content.shadow(color: .black.opacity(0.06), radius: 3, x: 0, y: 1)
        }
    }
}

extension View {

    // MARK: - View Method

    /// 套用 BuyLedger 卡片陰影。
    /// - Parameter floating: 傳入 `true` 時使用較高的浮層陰影。
    /// - Returns: 套用陰影後的 view。
    func blCardShadow(floating: Bool = false) -> some View {
        modifier(BLCardShadow(floating: floating))
    }
}

// MARK: - Preview

#Preview("尺寸與陰影") {
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

        Text("標準卡片陰影")
            .padding()
            .frame(maxWidth: .infinity)
            .background(.background)
            .clipShape(RoundedRectangle(cornerRadius: BLRadius.large, style: .continuous))
            .blCardShadow()

        Text("浮層卡片陰影")
            .padding()
            .frame(maxWidth: .infinity)
            .background(.background)
            .clipShape(RoundedRectangle(cornerRadius: BLRadius.large, style: .continuous))
            .blCardShadow(floating: true)
    }
    .padding()
}
