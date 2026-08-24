//
//  BLTone.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/4/30.
//

import SwiftUI

/// 表示元件在介面中的語意強度與狀態
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
    var onSurface: Color {
        namedColor(role: "SurfaceText")
    }
    
    /// 搭配 ``onSurface`` 的淡底色
    var background: Color {
        namedColor(role: "SoftBackground")
    }
    
    /// 純圖形元素使用的指示色
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
