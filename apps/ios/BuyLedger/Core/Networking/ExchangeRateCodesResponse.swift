//
//  ExchangeRateCodesResponse.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/09/19.
//

import Foundation

/// 支援幣別 API 的回應資料
struct ExchangeRateCodesResponse: Decodable, Sendable {

    // MARK: - Properties

    /// `API` 回應狀態 (`success` 或 `error`)
    let result: String

    /// 錯誤類別，只有 `result == "error"` 時存在
    let errorType: String?

    /// `[[code, name], …]` 形式的支援幣別清單
    let supportedCodes: [[String]]?
}

// MARK: - Nested Types

extension ExchangeRateCodesResponse {

    /// 將回應的 `snake_case` 欄位對應到 Swift 屬性
    enum CodingKeys: String, CodingKey {

        /// 回應處理結果
        case result

        /// 服務錯誤類別
        case errorType = "error-type"

        /// 支援的幣別清單
        case supportedCodes = "supported_codes"
    }
}
