//
//  BLStatusHue.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/8/1.
//

import SwiftUI

/// 訂單狀態在代購流程中的階段色相
enum BLStatusHue {}

// MARK: - Internal Method

extension BLStatusHue {
    
    /// 回傳指定訂單狀態在側邊欄智慧分組色點使用的色相
    /// - Parameters:
    ///   - status: 訂單狀態
    ///   - palette: 目前外觀使用的色盤
    /// - Returns: 色相
    static func color(for status: OrderStatus, in palette: BLPalette) -> Color {
        switch status {
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
}
