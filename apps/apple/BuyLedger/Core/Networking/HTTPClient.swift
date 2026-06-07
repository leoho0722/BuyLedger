//
//  HTTPClient.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/2.
//

import ComposableArchitecture
import Foundation

/// 通用 HTTP 客戶端依賴。
///
/// 抽象化 `URLSession` 的細節，讓上層 client 只關心「發 request、拿 (Data, HTTPURLResponse)」。
/// 測試時可注入 closure 直接回傳預先準備好的 fixture，無需架設 mock server。
struct HTTPClient: Sendable {

    // MARK: - Dependency Properties

    /// 對應到 `URLSession.shared.data(for:)` 的可注入封裝。
    var data: @Sendable (URLRequest) async throws -> (Data, HTTPURLResponse)
}

extension HTTPClient: DependencyKey {

    // MARK: - Dependency Values

    /// App 執行時使用 `URLSession.shared`。
    nonisolated static let liveValue: HTTPClient = HTTPClient(
        data: { request in
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.transport(message: "回應不是 HTTPURLResponse。")
            }

            return (data, httpResponse)
        }
    )

    /// 測試與 Preview 使用：永遠拋出 `transport` 錯誤，避免意外打到真實網路。
    nonisolated static let testValue: HTTPClient = HTTPClient(
        data: { _ in
            throw APIError.transport(message: "HTTPClient.testValue 被呼叫；請在測試中以 withDependencies 注入。")
        }
    )

    nonisolated static let previewValue: HTTPClient = testValue
}

extension DependencyValues {

    // MARK: - Dependency Values

    /// 通用 HTTP 客戶端。
    var httpClient: HTTPClient {
        get { self[HTTPClient.self] }
        set { self[HTTPClient.self] = newValue }
    }
}
