//
//  AISummaryServiceTestSupport.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/27.
//

import Foundation

@testable import BuyLedger

/// 提供 AI 摘要 Service 測試共用的 HTTP client
enum AISummaryServiceTestSupport {}

// MARK: - Internal Method

extension AISummaryServiceTestSupport {

    /// 建立使用 `MockURLProtocol` 的 HTTP client
    ///
    /// - Returns: 使用 `.ephemeral` session 的 HTTP client
    static func makeHTTPClient() -> HTTPClient {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        return HTTPClient(session: URLSession(configuration: configuration))
    }
}
