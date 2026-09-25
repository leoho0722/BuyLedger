//
//  OrderStatus+Presentation.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import SwiftUI

// MARK: - Presentation Properties

extension OrderStatus {

    /// 回傳側邊欄智慧分組使用的狀態色點顏色
    /// - Parameter palette: 目前外觀使用的色盤
    /// - Returns: 狀態色點顏色
    func sidebarHue(in palette: BLPalette) -> Color {
        switch self {
        case .quoting:
            palette.teal
        case .confirmed:
            palette.accent
        case .purchased:
            palette.indigo
        case .shipping:
            palette.orange
        case .partiallyArrived:
            palette.purple
        case .arrived:
            palette.yellow
        case .delivered:
            palette.green
        case .pickedUp:
            palette.pink
        case .cancelled:
            palette.red
        case .merged:
            palette.teal
        }
    }

    /// 對應設計系統語意狀態
    var tone: BLTone {
        switch self {
        case .quoting:
            .informative
        case .confirmed:
            .accent
        case .purchased:
            // 採購完成是正常進度，使用一般資訊色。
            .informative
        case .shipping:
            .informative
        case .partiallyArrived:
            .warning
        case .arrived:
            .accent
        case .delivered:
            .success
        case .pickedUp:
            .success
        case .cancelled:
            .destructive
        case .merged:
            .neutral
        }
    }
}
