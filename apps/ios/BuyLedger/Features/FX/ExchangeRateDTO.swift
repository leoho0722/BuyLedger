//
//  ExchangeRateDTO.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/2.
//

import Foundation

// MARK: - Latest Response DTO

/// `https://v6.exchangerate-api.com/v6/{KEY}/latest/{BASE}` 的回應 schema
///
/// 即使 HTTP 200，`result` 也可能是 `"error"`，此時 `error_type` 會帶上具體類別。`Decodable` 全欄位都標 optional 以容錯不同情境
struct ExchangeRateLatestResponse: Decodable, Sendable {

    // MARK: - Data Properties

    /// API 回應狀態 ("success" / "error")
    let result: String

    /// 錯誤類別 (僅 result == "error" 時才存在)
    let errorType: String?

    /// 報價時間 UNIX timestamp
    let timeLastUpdateUnix: TimeInterval?

    /// 基準幣別
    let baseCode: String?

    /// 各目標幣別的匯率
    let conversionRates: [String: Double]?

    // MARK: - CodingKeys

    /// 把 API 的 snake_case 欄位映射成 camelCase 屬性
    enum CodingKeys: String, CodingKey {

        case result

        case errorType = "error-type"

        case timeLastUpdateUnix = "time_last_update_unix"

        case baseCode = "base_code"

        case conversionRates = "conversion_rates"
    }
}

// MARK: - Internal Method

extension ExchangeRateLatestResponse {

    /// 把 DTO 轉成領域層 ``FxRateSnapshot``
    ///
    /// `CurrencyCode` 改成 struct wrapper 後不再 filter 未知幣別；API 回傳的所有 ISO 4217 code 都被保留進 snapshot，view 端可依當下 cache 決定顯示哪些
    /// - Parameters:
    ///   - base: 請求時使用的基準幣別
    ///   - fallbackDate: API 未回 `time_last_update_unix` 時採用的快照時間；caller 應從 `@Dependency(\.date)` 取得以維持可測試性
    /// - Returns: 對應的快照
    func toSnapshot(base: CurrencyCode, fallbackDate: Date) -> FxRateSnapshot {
        let rawRates = conversionRates ?? [:]
        var converted: [CurrencyCode: Decimal] = [:]
        for (key, value) in rawRates {
            converted[CurrencyCode(rawValue: key)] = Decimal(value)
        }

        let date = timeLastUpdateUnix
            .map { Date(timeIntervalSince1970: $0) } ?? fallbackDate

        return FxRateSnapshot(date: date, base: base, rates: converted)
    }
}

// MARK: - Codes Response DTO

/// `https://v6.exchangerate-api.com/v6/{KEY}/codes` 的回應 schema
///
/// `supported_codes` 是 `[[ "USD", "United States Dollar" ], ...]`
///
/// 本 App 只使用 ISO 4217 code，name 一律用 `Locale.localizedString(forCurrencyCode:)` 在 view 端計算以跟隨手機 locale
struct ExchangeRateCodesResponse: Decodable, Sendable {

    // MARK: - Data Properties

    /// API 回應狀態 ("success" / "error")
    let result: String

    /// 錯誤類別 (僅 result == "error" 時才存在)
    let errorType: String?

    /// `[[code, name], …]` 形式的支援幣別清單
    let supportedCodes: [[String]]?

    // MARK: - CodingKeys

    /// 把 API 的 snake_case 欄位映射成 camelCase 屬性
    enum CodingKeys: String, CodingKey {

        case result

        case errorType = "error-type"

        case supportedCodes = "supported_codes"
    }
}
