//
//  BLHeroCardBackground.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/7/30.
//

import SwiftUI

/// Hero 卡的底色，使用設計系統的漸層
struct BLHeroCardBackground {}

// MARK: - Computed Properties

extension BLHeroCardBackground {

    /// 漸層端點色彩，需符合白字對比度
    static var gradientColors: [Color] {
        BLPalette.heroGradient
    }
}

// MARK: - ViewModifier

extension BLHeroCardBackground: ViewModifier {

    /// 回傳套用漸層底色與圓角裁切後的內容
    /// - Parameter content: 要套用底色的內容
    /// - Returns: 套用漸層底色與圓角裁切後的 view
    func body(content: Content) -> some View {
        content
            .background(
                LinearGradient(
                    colors: Self.gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: BLRadius.large, style: .continuous))
    }
}

// MARK: - blHeroCardBackground

extension View {

    /// 套用 BuyLedger 彩底 hero 卡底色 (漸層 + 圓角裁切)
    /// - Returns: 套用底色後的 view
    func blHeroCardBackground() -> some View {
        modifier(BLHeroCardBackground())
    }
}

// MARK: - Preview

#Preview("Hero 卡底色") {
    VStack(alignment: .leading, spacing: BLSpacing.extraSmall) {
        Text("建議售價")
            .font(BLTypographyStyle.caption.font.weight(.semibold))
            .textCase(.uppercase)

        Text("NT$ 1,234")
            .font(.system(size: 40, weight: .bold))
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(BLSpacing.large)
    .padding()
    .foregroundStyle(.white)
    .blHeroCardBackground()
    .blCardShadow()
}
