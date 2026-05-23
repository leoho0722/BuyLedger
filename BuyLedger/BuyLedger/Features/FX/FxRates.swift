//
//  FxRates.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import Foundation

/// 內建的匯率對照表（皆為「1 單位來源幣別 = X TWD」）。
///
/// 僅供 SwiftUI Preview、單元測試與 ``FxRateSnapshot/fallback`` 使用，**runtime 不再讀取**——一律以 ``ExchangeRateClient`` 取得的 snapshot 為準，無 snapshot 時 view 顯示「—」。
///
/// 改成幣別由 API 主檔提供後，這份對照表縮小成「常用幣別 + 對應 fallback rate」字典，僅供 ``FxRateSnapshot/fallback`` 在 Preview 與測試中組出範例 snapshot。
enum FxRates {

    // MARK: - Static Properties

    /// 對應到設計稿 `tokens.jsx` 的範例匯率，方便對照截圖。Key 用 `CurrencyCode`（struct wrapper），等同 ISO 4217 code。
    static let toTwd: [CurrencyCode: Decimal] = [
        .twd: 1,
        .krw: Decimal(string: "0.0228") ?? 0,
        .jpy: Decimal(string: "0.2105") ?? 0,
        .usd: Decimal(string: "32.45") ?? 0,
    ]
}
