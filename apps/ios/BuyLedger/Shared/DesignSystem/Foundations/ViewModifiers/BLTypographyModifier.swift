//
//  BLTypographyModifier.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/31.
//

import SwiftUI

// MARK: - ViewModifier

/// 套用 BuyLedger 文字層級的 view modifier
struct BLTypographyModifier: ViewModifier {
    
    // MARK: - View Properties
    
    /// 要套用的文字層級
    let style: BLTypographyStyle
    
    // MARK: - View Body
    
    /// 回傳套用字型與字距後的內容
    func body(content: Content) -> some View {
        content
            .font(style.font)
    }
}

// MARK: - View Method

extension View {
    
    /// 套用 BuyLedger 設計系統的文字樣式
    /// - Parameter style: 要套用的文字層級
    /// - Returns: 套用文字樣式後的 view
    func blTextStyle(_ style: BLTypographyStyle) -> some View {
        modifier(BLTypographyModifier(style: style))
    }
}

// MARK: - Preview

#Preview("文字層級") {
    VStack(alignment: .leading, spacing: BLSpacing.medium) {
        ForEach(BLTypographyStyle.allCases) { style in
            Text(style.rawValue)
                .blTextStyle(style)
        }
    }
    .padding()
}
