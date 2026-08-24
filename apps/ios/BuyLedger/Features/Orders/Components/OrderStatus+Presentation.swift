//
//  OrderStatus+Presentation.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import Foundation

// MARK: - Presentation Properties

extension OrderStatus {
    
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
