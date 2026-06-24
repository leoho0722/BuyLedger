//
//  BLTone.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/4/30.
//

import SwiftUI

/// 表示元件在介面中的語意強度與狀態
///
/// 功能模組應自行將商業狀態轉換成語意狀態，設計系統不直接認識訂單、
/// 客戶或帳本等領域模型
enum BLTone: CaseIterable {

    // MARK: - Cases

    /// 中性狀態
    case neutral

    /// 主要強調狀態
    case accent

    /// 成功狀態
    case success

    /// 警示狀態
    case warning

    /// 破壞性或錯誤狀態
    case destructive

    /// 資訊提示狀態
    case informative

    // MARK: - Tone Method

    /// 回傳語意狀態的前景色
    /// - Parameter palette: 目前外觀對應的色盤
    /// - Returns: 適合文字、圖示或指示點使用的色彩
    func foreground(in palette: BLPalette) -> Color {
        switch self {
        case .neutral:
            palette.secondaryLabel
        case .accent:
            palette.accent
        case .success:
            palette.green
        case .warning:
            palette.orange
        case .destructive:
            palette.red
        case .informative:
            palette.indigo
        }
    }

    /// 回傳語意狀態的背景色
    /// - Parameter palette: 目前外觀對應的色盤
    /// - Returns: 適合 badge、pill 或輕量狀態容器使用的色彩
    func background(in palette: BLPalette) -> Color {
        switch self {
        case .neutral:
            palette.fillTertiary
        case .accent, .success, .warning, .destructive, .informative:
            foreground(in: palette).opacity(0.14)
        }
    }
}

// MARK: - Preview

#Preview("語意狀態") {
    let samples: [(String, BLTone)] = [
        ("Neutral", .neutral),
        ("Accent", .accent),
        ("Success", .success),
        ("Warning", .warning),
        ("Destructive", .destructive),
        ("Informative", .informative),
    ]

    VStack(alignment: .leading, spacing: BLSpacing.small) {
        ForEach(samples.indices, id: \.self) { index in
            BLStatusPill(samples[index].0, tone: samples[index].1)
        }
    }
    .padding()
}
