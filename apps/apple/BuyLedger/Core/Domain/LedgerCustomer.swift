//
//  LedgerCustomer.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import Foundation

/// 訂單中的客戶摘要資料。
struct LedgerCustomer: Codable, Equatable, Sendable {

    // MARK: - Data Properties

    /// 客戶顯示名稱。
    let name: String

    /// 頭像與列表使用的姓名縮寫。
    let initials: String

    /// 客戶分級。
    let tier: CustomerTier
}
