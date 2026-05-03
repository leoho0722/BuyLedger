//
//  BLPalette.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/4/30.
//

import SwiftUI

/// BuyLedger 在 SwiftUI 介面中使用的語意色彩。
///
/// 色彩以使用情境命名，讓功能畫面不需要直接依賴固定色碼。
struct BLPalette {
    
    // MARK: - Palette Properties
    
    /// 指示目前色盤是否使用深色外觀。
    let isDark: Bool
    
    /// App 主要背景色。
    var background: Color {
        isDark ? .black : Color(blHex: 0xF2F2F7)
    }
    
    /// 第二層背景色，適合列表或群組內容表面。
    var secondaryBackground: Color {
        isDark ? Color(blHex: 0x1C1C1E) : .white
    }
    
    /// 第三層背景色，適合嵌套區塊或輔助背景。
    var tertiaryBackground: Color {
        isDark ? Color(blHex: 0x2C2C2E) : Color(blHex: 0xF2F2F7)
    }
    
    /// 主要內容表面色。
    var surface: Color {
        isDark ? Color(blHex: 0x1C1C1E) : .white
    }
    
    /// 帶有較高視覺層級的內容表面色。
    var elevatedSurface: Color {
        isDark ? Color(blHex: 0x2C2C2E) : .white
    }
    
    /// 主要文字色。
    var label: Color {
        isDark ? .white : .black
    }
    
    /// 次要文字色。
    var secondaryLabel: Color {
        isDark ? Color.white.opacity(0.6) : Color.black.opacity(0.6)
    }
    
    /// 第三層文字色。
    var tertiaryLabel: Color {
        isDark ? Color.white.opacity(0.3) : Color.black.opacity(0.3)
    }
    
    /// 半透明分隔線色。
    var separator: Color {
        isDark ? Color.white.opacity(0.14) : Color.black.opacity(0.16)
    }
    
    /// 不透明分隔線色。
    var opaqueSeparator: Color {
        isDark ? Color(blHex: 0x38383A) : Color(blHex: 0xC6C6C8)
    }
    
    /// 第一層填色，適合可互動元件背景。
    var fillPrimary: Color {
        isDark ? Color(blHex: 0x787880).opacity(0.36) : Color(blHex: 0x787880).opacity(0.20)
    }
    
    /// 第二層填色，適合次要可互動元件背景。
    var fillSecondary: Color {
        isDark ? Color(blHex: 0x787880).opacity(0.32) : Color(blHex: 0x787880).opacity(0.16)
    }
    
    /// 第三層填色，適合搜尋框或分段控制背景。
    var fillTertiary: Color {
        isDark ? Color(blHex: 0x767680).opacity(0.24) : Color(blHex: 0x767680).opacity(0.12)
    }
    
    /// 第四層填色，適合低對比輔助背景。
    var fillQuaternary: Color {
        isDark ? Color(blHex: 0x767680).opacity(0.18) : Color(blHex: 0x747480).opacity(0.08)
    }
    
    /// App 主要強調色。
    var accent: Color {
        isDark ? Color(blHex: 0x0A84FF) : Color(blHex: 0x007AFF)
    }
    
    /// 成功狀態色。
    var green: Color {
        isDark ? Color(blHex: 0x30D158) : Color(blHex: 0x34C759)
    }
    
    /// 錯誤或破壞性狀態色。
    var red: Color {
        isDark ? Color(blHex: 0xFF453A) : Color(blHex: 0xFF3B30)
    }
    
    /// 警示狀態色。
    var orange: Color {
        isDark ? Color(blHex: 0xFF9F0A) : Color(blHex: 0xFF9500)
    }
    
    /// 注意或提示狀態色。
    var yellow: Color {
        isDark ? Color(blHex: 0xFFD60A) : Color(blHex: 0xFFCC00)
    }
    
    /// 輔助強調色。
    var purple: Color {
        isDark ? Color(blHex: 0xBF5AF2) : Color(blHex: 0xAF52DE)
    }
    
    /// 輔助強調色，適合標籤或圖表區段。
    var pink: Color {
        isDark ? Color(blHex: 0xFF375F) : Color(blHex: 0xFF2D55)
    }
    
    /// 輔助強調色，適合圖表或平台識別。
    var teal: Color {
        isDark ? Color(blHex: 0x64D2FF) : Color(blHex: 0x5AC8FA)
    }
    
    /// 資訊狀態色。
    var indigo: Color {
        isDark ? Color(blHex: 0x5E5CE6) : Color(blHex: 0x5856D6)
    }
    
    /// 半透明材質背景色。
    var glassBackground: Color {
        isDark ? Color(blHex: 0x1C1C1E).opacity(0.72) : Color.white.opacity(0.72)
    }
    
    /// 半透明材質邊框色。
    var glassBorder: Color {
        isDark ? Color.white.opacity(0.12) : Color.white.opacity(0.7)
    }
}

/// 依目前系統外觀產生對應的設計系統色盤。
enum BLTheme {
    
    // MARK: - Theme Method
    
    /// 回傳指定系統外觀對應的色盤。
    /// - Parameter colorScheme: 目前環境中的系統深淺色外觀。
    /// - Returns: 可供 SwiftUI view 使用的 `BLPalette`。
    static func palette(for colorScheme: ColorScheme) -> BLPalette {
        BLPalette(isDark: colorScheme == .dark)
    }
}

extension Color {
    
    // MARK: - Init
    
    /// 使用 sRGB 十六進位色碼建立 SwiftUI 色彩。
    /// - Parameters:
    ///   - hex: `0xRRGGBB` 格式的 sRGB 色碼。
    ///   - opacity: 色彩透明度，預設為 `1`。
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

// MARK: - Preview

#Preview("語意色彩") {
    let palette = BLPalette(isDark: false)
    let colors: [(String, Color)] = [
        ("Accent", palette.accent),
        ("Green", palette.green),
        ("Red", palette.red),
        ("Orange", palette.orange),
        ("Yellow", palette.yellow),
        ("Purple", palette.purple),
        ("Pink", palette.pink),
        ("Teal", palette.teal),
        ("Indigo", palette.indigo),
    ]
    
    LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: BLSpacing.medium)], spacing: BLSpacing.medium) {
        ForEach(colors.indices, id: \.self) { index in
            VStack(alignment: .leading, spacing: BLSpacing.small) {
                RoundedRectangle(cornerRadius: BLRadius.small, style: .continuous)
                    .fill(colors[index].1)
                    .frame(height: 48)
                
                Text(colors[index].0)
                    .font(.caption)
                    .foregroundStyle(palette.secondaryLabel)
            }
        }
    }
    .padding()
    .background(palette.background)
}
