//
//  HTTPClient+Dependency.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/26.
//

import ComposableArchitecture
import Foundation

// MARK: - DependencyKey

/// 把 `HTTPClientProtocol` 註冊進 TCA 依賴系統：正式 App 用正式實作，Preview 用 stub；
/// 不宣告測試值，測 Service 時漏了以 `withDependencies` 注入 mock 就會直接失敗
enum HTTPClientKey: DependencyKey {

    /// App 執行時使用預設 `URLSession` 傳輸
    static var liveValue: any HTTPClientProtocol {
        HTTPClient(session: URLSession(configuration: .default))
    }

    #if DEBUG

    /// Preview 使用不連線的 HTTP client
    static var previewValue: any HTTPClientProtocol {
        PreviewHTTPClient()
    }

    #endif
}

// MARK: - DependencyValues

extension DependencyValues {

    /// 通用 HTTP 傳輸介面
    var httpClient: any HTTPClientProtocol {
        get { self[HTTPClientKey.self] }
        set { self[HTTPClientKey.self] = newValue }
    }
}
