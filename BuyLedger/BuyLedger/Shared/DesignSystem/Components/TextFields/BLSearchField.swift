//
//  BLSearchField.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/4/30.
//

import SwiftUI

/// 帶有搜尋圖示的輸入欄。
struct BLSearchField: View {
    
    // MARK: - View Properties
    
    /// 目前系統深淺色外觀。
    @Environment(\.colorScheme) private var colorScheme
    
    /// 欄位尚未輸入時顯示的提示文字。
    let placeholder: String
    
    /// 欄位文字的雙向繫結。
    @Binding var text: String
    
    // MARK: - View Body
    
    /// 搜尋輸入欄的畫面內容。
    var body: some View {
        let palette = BLTheme.palette(for: colorScheme)
        
        HStack(spacing: BLSpacing.small) {
            Image(systemName: "magnifyingglass")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(palette.secondaryLabel)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .font(.subheadline)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(palette.fillTertiary)
        .clipShape(
            RoundedRectangle(
                cornerRadius: BLRadius.small,
                style: .continuous
            )
        )
    }
}

// MARK: - ViewBuilder

private extension BLSearchField {}

// MARK: - Preview

#Preview("搜尋輸入欄") {
    BLSearchField(placeholder: "搜尋交易", text: .constant("咖啡"))
        .padding()
}
