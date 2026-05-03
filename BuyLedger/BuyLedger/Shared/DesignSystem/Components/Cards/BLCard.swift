//
//  BLCard.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/4/30.
//

import SwiftUI

/// 使用設計系統表面色、圓角與分隔線的卡片容器。
struct BLCard<Content: View>: View {
    
    // MARK: - View Properties
    
    /// 目前系統深淺色外觀。
    @Environment(\.colorScheme) private var colorScheme
    
    /// 內容與卡片邊界之間的距離。
    let padding: CGFloat
    
    /// 卡片圓角半徑。
    let radius: CGFloat
    
    /// 卡片內顯示的內容。
    let content: Content
    
    // MARK: - Init
    
    /// 建立卡片容器。
    /// - Parameters:
    ///   - padding: 內容與卡片邊界之間的距離。
    ///   - radius: 卡片圓角半徑。
    ///   - content: 要放入卡片中的內容。
    init(
        padding: CGFloat = BLSpacing.large,
        radius: CGFloat = BLRadius.large,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.radius = radius
        self.content = content()
    }
    
    // MARK: - View Body
    
    /// 卡片的畫面內容。
    var body: some View {
        let palette = BLTheme.palette(for: colorScheme)
        
        content
            .padding(padding)
            .background(palette.surface)
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(palette.separator, lineWidth: 0.5)
            }
            .blCardShadow()
    }
}

// MARK: - ViewBuilder

private extension BLCard {}

// MARK: - Preview

#Preview("卡片") {
    BLCard {
        VStack(alignment: .leading, spacing: BLSpacing.small) {
            Text("本月支出")
                .blTextStyle(.headline)
            
            Text("$12,480")
                .blTextStyle(.title2)
                .monospacedDigit()
            
            Text("較上月減少 8%")
                .blTextStyle(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    .padding()
}
