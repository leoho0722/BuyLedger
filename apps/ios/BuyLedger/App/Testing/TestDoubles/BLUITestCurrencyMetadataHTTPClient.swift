//
//  BLUITestCurrencyMetadataHTTPClient.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/26.
//

#if DEBUG

import Foundation

/// 回傳固定支援幣別回應的 UI 測試 HTTP client
struct BLUITestCurrencyMetadataHTTPClient {}

// MARK: - HTTPClientProtocol

extension BLUITestCurrencyMetadataHTTPClient: HTTPClientProtocol {

    /// 回傳固定的支援幣別清單與 HTTP 200 狀態
    ///
    /// - Parameter request: 要送出的 API 請求
    /// - Returns: 固定的幣別 JSON 與 HTTP 回應
    /// - Throws: 請求路徑不符、固定回應建立失敗或 JSON 序列化失敗時丟出 `.transport(underlying:)`
    func data(for request: URLRequest) async throws(APIError) -> (Data, HTTPURLResponse) {
        guard request.url?.path.hasSuffix("/codes") == true else {
            throw .transport(
                underlying: NSError(
                    domain: "com.leoho.BuyLedger.ui-test",
                    code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "固定幣別 client 不支援此請求路徑。"]
                )
            )
        }

        guard let responseURL = URL(string: "https://v6.exchangerate-api.com/v6/codes") else {
            throw .transport(
                underlying: NSError(
                    domain: "com.leoho.BuyLedger.ui-test",
                    code: 2,
                    userInfo: [NSLocalizedDescriptionKey: "固定幣別回應 URL 無效。"]
                )
            )
        }
        guard let response = HTTPURLResponse(
            url: responseURL,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        ) else {
            throw .transport(
                underlying: NSError(
                    domain: "com.leoho.BuyLedger.ui-test",
                    code: 3,
                    userInfo: [NSLocalizedDescriptionKey: "無法建立固定幣別 HTTP 回應。"]
                )
            )
        }

        let responseObject: [String: Any] = [
            "result": "success",
            "supported_codes": BLUITestStubs.stubSupportedCodes.map { [$0, $0] },
        ]
        let body: Data
        do {
            body = try JSONSerialization.data(withJSONObject: responseObject)
        } catch {
            throw .transport(underlying: error as NSError)
        }
        return (body, response)
    }

    /// 固定替身不提供串流回應
    ///
    /// - Parameter request: 要送出的 API 請求
    /// - Returns: 串流回應 (固定替身不提供)
    /// - Throws: 固定替身不支援串流時丟出 `.transport(underlying:)`
    func bytes(
        for request: URLRequest
    ) async throws(APIError) -> (URLSession.AsyncBytes, HTTPURLResponse) {
        throw .transport(
            underlying: NSError(
                domain: "com.leoho.BuyLedger.ui-test",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "固定幣別 client 不支援串流。"]
            )
        )
    }
}

#endif
