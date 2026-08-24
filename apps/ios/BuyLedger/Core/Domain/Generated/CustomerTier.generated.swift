//
//  CustomerTier.generated.swift
//  BuyLedger
//
//  此檔由 datamodel-gen 自動產生，請勿手動編輯
//  若要調整資料形狀，請改 shared/data-model/schema/ 後重新執行 `bun run generate`
//

import Foundation

/// 客戶分級
enum CustomerTier: String, Codable, Sendable {

    // MARK: - Cases

    /// 新客戶
    case new

    /// 一般客戶
    case regular

    /// 高價值或高頻客戶
    case vip
}
