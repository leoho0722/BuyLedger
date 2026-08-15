//
//  FxRates.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import Foundation

/// 內建的匯率對照表 (皆為「1 單位來源幣別 = X TWD」)
enum FxRates {

    // MARK: - Static Properties

    /// Preview 使用的範例匯率
    static let toTwd: [CurrencyCode: Decimal] = [
        .twd: 1,
        .krw: Decimal(string: "0.0228") ?? 0,
        .jpy: Decimal(string: "0.2105") ?? 0,
        .usd: Decimal(string: "32.45") ?? 0,
    ]
}
