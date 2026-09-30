//
//  ExchangeRateEndpoint.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/26.
//

import Foundation

/// 共用 ExchangeRate-API 請求、解碼與服務錯誤分類
enum ExchangeRateEndpoint {

    // MARK: - Properties

    /// ExchangeRate-API 憑證在 `Info.plist` 中的設定名稱
    static let apiKeyConfigurationKey = "EXCHANGE_RATE_API_KEY"
}

// MARK: - Internal Method

extension ExchangeRateEndpoint {

    /// 發出指定路徑的請求並解碼 JSON 回應
    ///
    /// - Parameters:
    ///   - responseType: 要解碼的回應型別
    ///   - path: v6 API 網址中的相對路徑
    ///   - apiKey: 放入 Authorization header 的金鑰
    ///   - httpClient: 傳送請求與解碼回應的 HTTP client
    /// - Returns: 解碼後的 API 回應
    /// - Throws: 金鑰含控制字元、URL 無效或傳輸失敗時丟出 `.transport(underlying:)`；
    ///   HTTP 狀態碼非 2xx 時丟出 `.http(statusCode:)`；解碼失敗時丟出 `.decoding(underlying:)`
    static func fetch<Response: Decodable & Sendable>(
        _ responseType: Response.Type,
        path: String,
        apiKey: String,
        using httpClient: any HTTPClientProtocol
    ) async throws(APIError) -> Response {
        guard !apiKey.unicodeScalars.contains(where: CharacterSet.controlCharacters.contains) else {
            throw Self.invalidRequestError()
        }

        let urlString = "https://v6.exchangerate-api.com/v6/\(path)"
        guard let url = URL(string: urlString) else {
            throw Self.invalidRequestError()
        }

        let data = try await httpClient.send(
            url: url,
            headers: ["Authorization": "Bearer \(apiKey)"],
            timeout: 15
        )
        return try httpClient.decode(responseType, from: data)
    }

    /// 把 ExchangeRate-API 的服務結果轉成單一錯誤分類
    ///
    /// - Parameters:
    ///   - result: API 回傳的結果欄位
    ///   - errorType: API 回傳的錯誤代碼
    /// - Returns: 無效憑證時回傳 `.invalidKey`；配額用盡時回傳 `.quotaExceeded`；
    ///   其他服務錯誤時回傳 `.apiError(code:)`
    static func serviceError(result: String, errorType: String?) -> APIError {
        guard result == "error" else {
            return .apiError(code: "unexpected-result-\(result)")
        }

        switch errorType ?? "unknown" {
        case "invalid-key", "inactive-account":
            return .invalidKey

        case "quota-reached":
            return .quotaExceeded

        case let code:
            return .apiError(code: code)
        }
    }
}

// MARK: - Private Method

private extension ExchangeRateEndpoint {

    /// 建立拒絕不安全 key 或無效 URL 時使用的 transport 錯誤
    ///
    /// - Returns: 帶 networking 診斷資訊的 transport 錯誤
    static func invalidRequestError() -> APIError {
        .transport(
            underlying: NSError(
                domain: "com.leoho.BuyLedger.networking",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "URL 組合失敗。"]
            )
        )
    }
}
