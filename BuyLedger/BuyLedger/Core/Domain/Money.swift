//
//  Money.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import Foundation

/// 帶有幣別的金額值。
struct Money: Codable, Equatable {

    // MARK: - Data Properties

    /// 金額數值。
    let amount: Decimal

    /// 金額所屬幣別。
    let currency: CurrencyCode
}
