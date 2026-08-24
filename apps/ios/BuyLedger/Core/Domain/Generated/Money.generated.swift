//
//  Money.generated.swift
//  BuyLedger
//
//  此檔由 datamodel-gen 自動產生，請勿手動編輯
//  若要調整資料形狀，請改 shared/data-model/schema/ 後重新執行 `bun run generate`
//

import Foundation

/// 含幣別的金額
struct Money: Codable, Equatable, Sendable {

    // MARK: - Data Properties

    /// 金額
    let amount: Decimal

    /// 幣別
    let currency: CurrencyCode
}
