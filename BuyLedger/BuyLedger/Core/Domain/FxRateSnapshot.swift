//
//  FxRateSnapshot.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/2.
//

import Foundation

/// 單一基準幣別在某個時間點的所有匯率快照。
///
/// `rates` 以「1 unit of base = X target」表示；之後做歷史走勢時會把多筆 ``FxRateSnapshot`` 串成 sparkline。
struct FxRateSnapshot: Equatable, Sendable {

    // MARK: - Data Properties

    /// 報價時間。
    let date: Date

    /// 基準幣別。
    let base: CurrencyCode

    /// 對其他幣別的匯率（key 為目標幣別，value 為「1 base = value target」）。
    let rates: [CurrencyCode: Decimal]

    // MARK: - Static Properties

    /// 預設快照：使用 ``FxRates/toTwd`` 為基礎組成的範例 snapshot，僅供 SwiftUI Preview（``ExchangeRateClient/previewValue``）與單元測試使用。
    ///
    /// **runtime 不應讀取此值**——若 API 失敗，feature 應顯示錯誤訊息、所有匯率欄位顯示「—」，避免讓使用者誤以為看到的是即時匯率。
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
