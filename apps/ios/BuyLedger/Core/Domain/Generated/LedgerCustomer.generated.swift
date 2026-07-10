//
//  LedgerCustomer.generated.swift
//  BuyLedger
//
//  此檔由 datamodel-gen 自動產生，請勿手動編輯
//  若要調整資料形狀，請改 shared/data-model/schema/ 後重新執行 `bun run generate`
//

import Foundation

/// 訂單中的客戶摘要資料
struct LedgerCustomer: Codable, Equatable, Sendable {

    // MARK: - Data Properties

    /// 客戶顯示名稱
    let name: String

    /// 頭像與列表使用的姓名縮寫
    let initials: String

    /// 客戶分級
    let tier: CustomerTier
}
