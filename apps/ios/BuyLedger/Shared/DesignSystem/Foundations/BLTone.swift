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
}

// MARK: - Display Properties

extension BLTone {

    /// 疊在卡片或列背景之上的文字色
    ///
    /// 選色判準是「這個色彩最終疊在什麼底色上」：文字疊在 ``background`` 或卡片表面時走這一軌
    var onSurface: Color {
        namedColor(role: "SurfaceText")
    }

    /// 搭配 ``onSurface`` 的淡底色
    ///
    /// 適合 badge、pill 或輕量狀態容器
    var background: Color {
        namedColor(role: "SoftBackground")
    }

    /// 純圖形元素使用的指示色
    ///
    /// 適合狀態點、進度條填色與實心徽章底色；不供文字使用
    var indicator: Color {
        namedColor(role: "Indicator")
    }

    /// 疊在 ``indicator`` 實心底色之上的文字色
    var onIndicator: Color {
        namedColor(role: "OnIndicator")
    }
}

// MARK: - Private Method

private extension BLTone {

    /// 此語意狀態在 asset catalog 內的資源名稱片段
    var resourceName: String {
        switch self {
        case .neutral:
            "Neutral"
        case .accent:
            "Accent"
        case .success:
            "Success"
        case .warning:
            "Warning"
        case .destructive:
            "Destructive"
        case .informative:
            "Informative"
        }
    }

    /// 回傳指定用途的具名色彩資源
    ///
    /// 走 asset catalog 而非程式碼算色，才能同時表達 Any / Dark 外觀與 Increase Contrast 變體
    /// - Parameter role: 色彩用途的資源名稱片段
    /// - Returns: 由系統依當前 trait 解析的具名色彩
    func namedColor(role: String) -> Color {
        Color("BLTone\(resourceName)\(role)", bundle: .assets)
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
