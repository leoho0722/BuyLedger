//
//  AISummaryServiceTestSupport.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/27.
//

import ComposableArchitecture
import Foundation

@testable import BuyLedger

/// 提供 AI 摘要 Service 測試共用的 Service 建立方式
enum AISummaryServiceTestSupport {}

// MARK: - Internal Method

extension AISummaryServiceTestSupport {

    /// 建立使用 `MockChatURLProtocol` 的正式 Service，`URLSession` 與設定來源都以注入的替身取代
    ///
    /// - Parameter configurationStore: 取代正式設定來源的替身；不需要讀取金鑰的測試不傳，
    ///   傳入預設的空替身
    /// - Returns: 以替身 `URLSession` 與設定來源建立的 `AISummaryService`
    static func makeService(
        configurationStore: MockAppConfigurationStore = MockAppConfigurationStore()
    ) -> AISummaryService {
        let urlSession = makeURLSession()
        return withDependencies {
            $0.urlSession = urlSession
            $0.appConfigurationStore = configurationStore
        } operation: {
            AISummaryService.liveValue
        }
    }
}

// MARK: - Private Method

private extension AISummaryServiceTestSupport {

    /// 建立使用 `MockChatURLProtocol` 的 `URLSession`
    ///
    /// - Returns: 使用 `.ephemeral` 設定的 `URLSession`
    static func makeURLSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockChatURLProtocol.self]
        return URLSession(configuration: configuration)
    }
}
