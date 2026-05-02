//
//  CustomerTier.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import Foundation

/// 客戶在代購流程中的分級。
enum CustomerTier: String, Codable, Sendable {

    // MARK: - Cases

    /// 第一次或近期新增的客戶。
    case new

    /// 一般常客。
    case regular

    /// 高價值或高頻率客戶。
    case vip

    // MARK: - Display Properties

    /// 顯示在介面中的分級名稱。
    var title: String {
        switch self {
        case .new:
            "新客"
        case .regular:
            "常客"
        case .vip:
            "VIP"
        }
    }
}
