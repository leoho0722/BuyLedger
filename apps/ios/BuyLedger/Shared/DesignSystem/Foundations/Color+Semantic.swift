//
//  Color+Semantic.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/16.
//

import SwiftUI

// MARK: - Computed Properties

extension ShapeStyle where Self == Color {

    /// App 主要背景色
    static var blBackground: Color {
        Color(uiColor: .systemGroupedBackground)
    }

    /// 第二層背景色，適合列表或群組內容表面
    static var blSecondaryBackground: Color {
        Color(uiColor: .secondarySystemGroupedBackground)
    }

    /// 未分組的系統背景色，供全畫面阻斷畫面使用
    static var blPlainBackground: Color {
        Color(uiColor: .systemBackground)
    }

    /// 主要內容表面色
    static var blSurface: Color {
        Color(uiColor: .secondarySystemGroupedBackground)
    }

    /// 主要文字色
    static var blLabel: Color {
        Color(uiColor: .label)
    }

    /// 次要文字色
    ///
    /// - Note: 系統的次要標籤色在淺色外觀下未達文字對比下限，因此以主要文字色加 0.6 不透明度取代
    static var blSecondaryLabel: Color {
        Color(uiColor: .label).opacity(0.6)
    }

    /// 第三層文字色；僅供停用態與 placeholder，不可用於承載資訊的文字
    static var blTertiaryLabel: Color {
        Color(uiColor: .tertiaryLabel)
    }

    /// 半透明分隔線色
    static var blSeparator: Color {
        Color(uiColor: .separator)
    }

    /// 第三層填色，適合搜尋框或分段控制背景
    static var blFillTertiary: Color {
        Color(uiColor: .tertiarySystemFill)
    }

    /// 第四層填色，適合低對比輔助背景
    static var blFillQuaternary: Color {
        Color(uiColor: .quaternarySystemFill)
    }

    /// App 主要強調色
    static var blAccent: Color {
        Color(uiColor: .systemBlue)
    }

    /// 成功狀態色
    static var blGreen: Color {
        Color(uiColor: .systemGreen)
    }

    /// 錯誤或破壞性狀態色
    static var blRed: Color {
        Color(uiColor: .systemRed)
    }

    /// 警示狀態色
    static var blOrange: Color {
        Color(uiColor: .systemOrange)
    }

    /// 注意或提示狀態色
    static var blYellow: Color {
        Color(uiColor: .systemYellow)
    }

    /// 輔助強調色
    static var blPurple: Color {
        Color(uiColor: .systemPurple)
    }

    /// 輔助強調色，適合標籤或圖表區段
    static var blPink: Color {
        Color(uiColor: .systemPink)
    }

    /// 輔助強調色，適合圖表或平台識別
    static var blTeal: Color {
        Color(uiColor: .systemTeal)
    }

    /// 資訊狀態色
    static var blIndigo: Color {
        Color(uiColor: .systemIndigo)
    }
}

// MARK: - Preview

#Preview("語意色彩") {
    let colors: [(String, Color)] = [
        ("Accent", .blAccent),
        ("Green", .blGreen),
        ("Red", .blRed),
        ("Orange", .blOrange),
        ("Yellow", .blYellow),
        ("Purple", .blPurple),
        ("Pink", .blPink),
        ("Teal", .blTeal),
        ("Indigo", .blIndigo),
    ]

    LazyVGrid(
        columns: [GridItem(.adaptive(minimum: 96), spacing: BLSpacing.medium)],
        spacing: BLSpacing.medium
    ) {
        ForEach(colors.indices, id: \.self) { index in
            VStack(alignment: .leading, spacing: BLSpacing.small) {
                RoundedRectangle(cornerRadius: BLRadius.small, style: .continuous)
                    .frame(height: 48)
                    .foregroundStyle(colors[index].1)

                Text(colors[index].0)
                    .blTextStyle(.caption)
                    .foregroundStyle(.blSecondaryLabel)
            }
        }
    }
    .padding()
    .background(.blBackground)
}
