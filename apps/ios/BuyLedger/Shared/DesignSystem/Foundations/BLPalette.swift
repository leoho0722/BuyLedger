//
//  BLPalette.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/4/30.
//

import SwiftUI

/// BuyLedger 在 SwiftUI 介面中使用的語意色彩
struct BLPalette {
    
    // MARK: - Static Properties
    
    /// 彩底 hero 卡的漸層端點 (由淺至深)，總覽頁與報價頁主卡共用同一組資源
    static var heroGradient: [Color] {
        [
            Color("BLHeroGradientStart", bundle: .assets),
            Color("BLHeroGradientEnd", bundle: .assets),
        ]
    }
    
    // MARK: - Display Properties
    
    /// App 主要背景色
    var background: Color {
        Color(uiColor: .systemGroupedBackground)
    }
    
    /// 第二層背景色，適合列表或群組內容表面
    var secondaryBackground: Color {
        Color(uiColor: .secondarySystemGroupedBackground)
    }
    
    /// 第三層背景色，適合嵌套區塊或輔助背景
    var tertiaryBackground: Color {
        Color(uiColor: .tertiarySystemGroupedBackground)
    }
    
    /// 未分組的系統背景色，供全畫面阻斷畫面使用
    var plainBackground: Color {
        Color(uiColor: .systemBackground)
    }
    
    /// 主要內容表面色
    var surface: Color {
        Color(uiColor: .secondarySystemGroupedBackground)
    }
    
    /// 帶有較高視覺層級的內容表面色
    var elevatedSurface: Color {
        Color(uiColor: .tertiarySystemBackground)
    }
    
    /// 主要文字色
    var label: Color {
        Color(uiColor: .label)
    }
    
    /// 次要文字色
    var secondaryLabel: Color {
        Color(uiColor: .label).opacity(0.6)
    }
    
    /// 第三層文字色；僅供停用態與 placeholder，不可用於承載資訊的文字
    var tertiaryLabel: Color {
        Color(uiColor: .tertiaryLabel)
    }
    
    /// 半透明分隔線色
    var separator: Color {
        Color(uiColor: .separator)
    }
    
    /// 不透明分隔線色
    var opaqueSeparator: Color {
        Color(uiColor: .opaqueSeparator)
    }
    
    /// 第一層填色，適合可互動元件背景
    var fillPrimary: Color {
        Color(uiColor: .systemFill)
    }
    
    /// 第二層填色，適合次要可互動元件背景
    var fillSecondary: Color {
        Color(uiColor: .secondarySystemFill)
    }
    
    /// 第三層填色，適合搜尋框或分段控制背景
    var fillTertiary: Color {
        Color(uiColor: .tertiarySystemFill)
    }
    
    /// 第四層填色，適合低對比輔助背景
    var fillQuaternary: Color {
        Color(uiColor: .quaternarySystemFill)
    }
    
    /// App 主要強調色
    var accent: Color {
        Color(uiColor: .systemBlue)
    }
    
    /// 成功狀態色
    var green: Color {
        Color(uiColor: .systemGreen)
    }
    
    /// 錯誤或破壞性狀態色
    var red: Color {
        Color(uiColor: .systemRed)
    }
    
    /// 警示狀態色
    var orange: Color {
        Color(uiColor: .systemOrange)
    }
    
    /// 注意或提示狀態色
    var yellow: Color {
        Color(uiColor: .systemYellow)
    }
    
    /// 輔助強調色
    var purple: Color {
        Color(uiColor: .systemPurple)
    }
    
    /// 輔助強調色，適合標籤或圖表區段
    var pink: Color {
        Color(uiColor: .systemPink)
    }
    
    /// 輔助強調色，適合圖表或平台識別
    var teal: Color {
        Color(uiColor: .systemTeal)
    }
    
    /// 資訊狀態色
    var indigo: Color {
        Color(uiColor: .systemIndigo)
    }
}

// MARK: - Preview

#Preview("語意色彩") {
    let palette = BLPalette()
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
    
    LazyVGrid(
        columns: [GridItem(.adaptive(minimum: 96), spacing: BLSpacing.medium)],
        spacing: BLSpacing.medium
    ) {
        ForEach(colors.indices, id: \.self) { index in
            VStack(alignment: .leading, spacing: BLSpacing.small) {
                RoundedRectangle(cornerRadius: BLRadius.small, style: .continuous)
                    .fill(colors[index].1)
                    .frame(height: 48)
                
                Text(colors[index].0)
                    .blTextStyle(.caption)
                    .foregroundStyle(palette.secondaryLabel)
            }
        }
    }
    .padding()
    .background(palette.background)
}
