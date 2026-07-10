//
//  FxRateSnapshot.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/2.
//
//  資料形狀 (date / base / rates) 由 Generated/FxRateSnapshot.generated.swift 產生；
//  本檔僅保留手寫業務邏輯 (預設快照 fallback)
//  改欄位請改 shared/data-model/schema/ 後重新 generate
//

import Foundation

// MARK: - Static Properties

extension FxRateSnapshot {

    /// 預設快照：使用 ``FxRates/toTwd`` 為基礎組成的範例 snapshot，僅供 SwiftUI Preview (``ExchangeRateClient/previewValue``) 與單元測試使用
    ///
    /// **runtime 不應讀取此值**——若 API 失敗，feature 應顯示錯誤訊息、所有匯率欄位顯示「—」，避免讓使用者誤以為看到的是即時匯率
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
