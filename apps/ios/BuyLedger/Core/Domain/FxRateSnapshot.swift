//
//  FxRateSnapshot.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/2.
//

import Foundation

// MARK: - Static Properties

extension FxRateSnapshot {

    /// Preview 與測試使用的預設匯率快照
    static let fallback: FxRateSnapshot = {
        var rates: [CurrencyCode: Decimal] = [:]
        for (currency, rateToTwd) in FxRates.toTwd where currency != CurrencyCode.twd {
            // 把「1 currency = X TWD」轉成「1 TWD = (1/X) currency」
            if rateToTwd > 0 {
                rates[currency] = Decimal(1) / rateToTwd
            }
        }
        rates[CurrencyCode.twd] = 1

        return FxRateSnapshot(
            date: Date(timeIntervalSince1970: 0),
            base: .twd,
            rates: rates
        )
    }()
}
