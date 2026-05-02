//
//  OrderStatus.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import Foundation

/// 訂單在代購流程中的目前狀態。
enum OrderStatus: String, CaseIterable, Codable, Identifiable, Sendable {

    // MARK: - Cases

    /// 正在報價，尚未成立正式訂單。
    case quoting

    /// 客戶已確認訂單。
    case confirmed

    /// 已完成海外下單。
    case purchased

    /// 商品正在集運或國際運送。
    case shipping

    /// 商品已交付客戶。
    case delivered

    /// 訂單已取消。
    case cancelled

    // MARK: - Identifiable Properties

    /// 狀態的穩定識別值。
    var id: String { rawValue }

    // MARK: - Display Properties

    /// 顯示在介面中的狀態名稱。
    var title: String {
        switch self {
        case .quoting:
            "報價中"
        case .confirmed:
            "已確認"
        case .purchased:
            "已下單"
        case .shipping:
            "集運中"
        case .delivered:
            "已交付"
        case .cancelled:
            "已取消"
        }
    }
}
