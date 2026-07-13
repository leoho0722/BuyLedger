//
//  Color+Extensions.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/4/30.
//

import SwiftUI

// MARK: - Init

extension Color {

    /// 使用 sRGB 十六進位色碼建立 SwiftUI 色彩
    /// - Parameters:
    ///   - hex: `0xRRGGBB` 格式的 sRGB 色碼
    ///   - opacity: 色彩透明度，預設為 `1`
    init(blHex hex: UInt, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}
