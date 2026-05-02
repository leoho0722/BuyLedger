//
//  FxRates.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import Foundation

/// 內建的匯率對照表（皆為「1 單位來源幣別 = X TWD」）。
///
/// 僅供 SwiftUI Preview、單元測試與 ``FxRateSnapshot/fallback`` 使用，**runtime 不再讀取**——一律以 ``ExchangeRateClient`` 取得的 snapshot 為準，無 snapshot 時 view 顯示「—」。`convertibleCurrencies` 是純粹的 UI 排序，與匯率值無關，runtime 仍可使用。
enum FxRates {

    // MARK: - Static Properties

    /// 對應到設計稿 `tokens.jsx` 的範例匯率，方便對照截圖。
    static let toTwd: [CurrencyCode: Decimal] = [
        .twd: 1,
        .krw: 0.0228,
        .jpy: 0.2105,
        .usd: 32.45,
        .eur: 35.20,
    ]

    /// 顯示在匯率工具中可選擇的來源幣別（順序固定）。
    static let convertibleCurrencies: [CurrencyCode] = [.krw, .jpy, .usd, .eur]

    // MARK: - Static Method

    /// 取得 1 單位來源幣別等於多少 TWD 的匯率。
    /// - Parameter currency: 來源幣別。
    /// - Returns: 對應 TWD 的匯率，未定義時回傳 `1`。
    static func rate(for currency: CurrencyCode) -> Decimal {
        toTwd[currency] ?? 1
    }
}
