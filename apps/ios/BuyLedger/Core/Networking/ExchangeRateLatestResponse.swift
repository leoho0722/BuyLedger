//
//  ExchangeRateLatestResponse.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/19.
//

import Foundation

/// 最新匯率 API 的回應資料
struct ExchangeRateLatestResponse: Decodable, Sendable {

    // MARK: - Properties

    /// `API` 回應狀態 (`success` 或 `error`)
    let result: String

    /// 錯誤類別，只有 `result == "error"` 時存在
    let errorType: String?

    /// 報價時間的 UNIX timestamp
    let timeLastUpdateUnix: TimeInterval?

    /// 基準幣別
    let baseCode: String?

    /// 各目標幣別的匯率
    let conversionRates: [String: Double]?
}

// MARK: - Nested Types

extension ExchangeRateLatestResponse {

    /// 將回應的 `snake_case` 欄位對應到 Swift 屬性
    enum CodingKeys: String, CodingKey {

        /// 回應處理結果
        case result

        /// 服務錯誤類別
        case errorType = "error-type"

        /// 最後更新時間
        case timeLastUpdateUnix = "time_last_update_unix"

        /// 基準幣別
        case baseCode = "base_code"

        /// 各目標幣別匯率
        case conversionRates = "conversion_rates"
    }
}

// MARK: - Internal Method

extension ExchangeRateLatestResponse {

    /// 把 DTO 轉成領域層 ``FxRateSnapshot``
    /// - Parameters:
    ///   - base: 請求時使用的基準幣別
    ///   - fallbackDate: API 未提供時間時使用的快照時間
    /// - Returns: 對應的快照
    func toSnapshot(base: CurrencyCode, fallbackDate: Date) -> FxRateSnapshot {
        let rawRates = conversionRates ?? [:]
        var converted: [CurrencyCode: Decimal] = [:]
        for (key, value) in rawRates {
            converted[CurrencyCode(rawValue: key)] = Decimal(value)
        }

        let date = timeLastUpdateUnix.map { timestamp in
            Date(timeIntervalSince1970: timestamp)
        } ?? fallbackDate

        return FxRateSnapshot(date: date, base: base, rates: converted)
    }
}
