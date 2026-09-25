//
//  FxRateSnapshot.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/2.
//

import Foundation

// MARK: - Properties

extension FxRateSnapshot {

    /// Preview 與測試使用的預設匯率快照
    static let fallback: FxRateSnapshot = {
        var rates: [CurrencyCode: Decimal] = [:]
        for (currency, rateToTWD) in FxRates.toTWD where currency != CurrencyCode.twd {
            // 把「1 currency = X TWD」轉成「1 TWD = (1/X) currency」
            if rateToTWD > 0 {
                rates[currency] = Decimal(1) / rateToTWD
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

// MARK: - Internal Method

extension FxRateSnapshot {

    /// 將快照中的匯率換算成一單位指定幣別對應的新台幣金額
    ///
    /// - Parameter currency: 要換算的幣別
    /// - Returns: 一單位指定幣別的新台幣匯率，無法換算時為 `nil`
    func twdRate(for currency: CurrencyCode) -> Decimal? {
        if currency == .twd {
            return 1
        }

        if base == .twd, let rate = rates[currency], rate > 0 {
            return 1 / rate
        }

        if base == currency {
            return rates[.twd]
        }

        return nil
    }
}
