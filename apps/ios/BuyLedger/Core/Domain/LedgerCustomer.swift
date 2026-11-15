//
//  LedgerCustomer.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/11/15.
//

/// 訂單中的客戶資料
struct LedgerCustomer: Codable, Equatable, Sendable {

    // MARK: - Properties

    /// 客戶顯示名稱
    let name: String

    /// 顯示在頭像上的姓名縮寫
    let initials: String

    /// 客戶分級
    let tier: CustomerTier
}
