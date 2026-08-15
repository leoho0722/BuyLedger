//
//  ExchangeRateDTO.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/2.
//

import Foundation

// MARK: - Latest Response DTO

/// 最新匯率 API 的回應資料
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
        
        let date =
        timeLastUpdateUnix
            .map { Date(timeIntervalSince1970: $0) } ?? fallbackDate
        
        return FxRateSnapshot(date: date, base: base, rates: converted)
    }
}

// MARK: - Codes Response DTO

/// 支援幣別 API 的回應資料
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
