//
//  BLCardShadow.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/31.
//

import SwiftUI

// MARK: - ViewModifier

/// 套用卡片陰影，並在深色模式改以分隔線表達層級
struct BLCardShadow: ViewModifier {

    // MARK: - View Properties

    /// 目前系統深淺色外觀
    @Environment(\.colorScheme) private var colorScheme

    /// 指示是否使用浮層陰影
    let floating: Bool

    // MARK: - View Body

    /// 回傳套用陰影後的內容
    func body(content: Content) -> some View {
        if colorScheme == .dark {
            content
        } else if floating {
            content.shadow(
                color: .black.opacity(0.18),
                radius: 32,
                x: 0,
                y: 12
            )
        } else {
            content.shadow(
                color: .black.opacity(0.06),
                radius: 3,
                x: 0,
                y: 1
            )
        }
    }
}

extension View {

    // MARK: - View Method

    /// 套用 BuyLedger 卡片陰影
    /// - Parameter floating: 傳入 `true` 時使用較高的浮層陰影
    /// - Returns: 套用陰影後的 view
    func blCardShadow(floating: Bool = false) -> some View {
        modifier(BLCardShadow(floating: floating))
    }
}

// MARK: - Preview

#Preview("卡片陰影") {
    VStack(alignment: .leading, spacing: BLSpacing.large) {
        Text("標準卡片陰影")
            .padding()
            .frame(maxWidth: .infinity)
            .background(.background)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: BLRadius.large,
                    style: .continuous
                )
            )
            .blCardShadow()

        Text("浮層卡片陰影")
            .padding()
            .frame(maxWidth: .infinity)
            .background(.background)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: BLRadius.large,
                    style: .continuous
                )
            )
            .blCardShadow(floating: true)
    }
    .padding()
}
