//
//  FxRates.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/05/01.
//

import Foundation

/// 內建的匯率對照表 (皆為「1 單位來源幣別 = X TWD」)
enum FxRates {

    // MARK: - Properties

    /// Preview 使用的範例匯率
    static let toTWD: [CurrencyCode: Decimal] = [
        .twd: 1,
        .krw: Decimal(sign: .plus, exponent: -4, significand: 228),
        .jpy: Decimal(sign: .plus, exponent: -4, significand: 2105),
        .usd: Decimal(sign: .plus, exponent: -2, significand: 3245),
    ]
}
