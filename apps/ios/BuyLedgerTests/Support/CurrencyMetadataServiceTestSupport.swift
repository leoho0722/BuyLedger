//
//  CurrencyMetadataServiceTestSupport.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/26.
//

import ComposableArchitecture
import Foundation
import SwiftData
import Testing

@testable import BuyLedger

/// 提供幣別與網路測試共用的設定來源、HTTP 回應、幣別主檔 Service 與快取資料
enum CurrencyMetadataServiceTestSupport {}

// MARK: - Internal Method

extension CurrencyMetadataServiceTestSupport {

    /// 建立 HTTP client 測試使用的成功回應
    ///
    /// - Parameter body: HTTP 回應內容
    /// - Returns: 回應內容與 HTTP 200 狀態
    /// - Throws: 固定 URL 或 `HTTPURLResponse` 無法建立時由 `#require` 丟出測試斷言錯誤
    static func makeHTTPResponse(body: Data) throws -> (Data, HTTPURLResponse) {
        let url = try #require(URL(string: "https://example.com/resource"))
        let response = try #require(
            HTTPURLResponse(
                url: url,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )
        )
        return (body, response)
    }

    /// 以指定依賴與 API key 字串建立正式幣別主檔 Service，設定來源由 API key 自動包裝
    ///
    /// - Parameters:
    ///   - database: 要注入的資料庫
    ///   - httpClient: 要注入的 HTTP client
    ///   - apiKey: 要提供給 Service 的 API key
    ///   - now: 測試使用的固定時間
    /// - Returns: 已注入測試依賴的正式 Service
    static func makeService(
        database: any BuyLedgerDatabaseProtocol,
        httpClient: MockHTTPClient,
        apiKey: String?,
        now: Date
    ) -> CurrencyMetadataService {
        let configurationStore = Self.makeConfigurationStore(apiKey: apiKey)
        return Self.makeService(
            database: database,
            httpClient: httpClient,
            configurationStore: configurationStore,
            now: now
        )
    }

    /// 以指定依賴與現成的設定來源建立正式幣別主檔 Service，供測試檢查設定來源的讀取紀錄
    ///
    /// - Parameters:
    ///   - database: 要注入的資料庫
    ///   - httpClient: 要注入的 HTTP client
    ///   - configurationStore: 要注入的設定來源
    ///   - now: 測試使用的固定時間
    /// - Returns: 已注入測試依賴的正式 Service
    static func makeService(
        database: any BuyLedgerDatabaseProtocol,
        httpClient: MockHTTPClient,
        configurationStore: MockAppConfigurationStore,
        now: Date
    ) -> CurrencyMetadataService {
        withDependencies {
            $0.buyLedgerDatabase = database
            $0.httpClient = httpClient
            $0.appConfigurationStore = configurationStore
            $0.date = .constant(now)
        } operation: {
            CurrencyMetadataService.liveValue
        }
    }

    /// 建立回傳指定 API key 的設定來源
    ///
    /// - Parameter apiKey: 要回傳的 API key，`nil` 代表未設定
    /// - Returns: 可記錄讀取 `key` 的設定來源
    static func makeConfigurationStore(apiKey: String?) -> MockAppConfigurationStore {
        let configurationStore = MockAppConfigurationStore()
        if let apiKey {
            configurationStore.stringResult = [
                ExchangeRateEndpoint.apiKeyConfigurationKey: apiKey,
            ]
        }
        return configurationStore
    }

    /// 在資料庫中建立指定時間的幣別快取
    ///
    /// - Parameters:
    ///   - codes: 要寫入的幣別代碼
    ///   - date: 快取更新時間
    ///   - database: 要寫入的資料庫
    /// - Throws: 儲存失敗時丟出
    ///   `.storage(.saveFailed(underlying:))`
    static func seedCache(
        _ codes: [String],
        at date: Date,
        in database: any BuyLedgerDatabaseProtocol
    ) async throws(CurrencyMetadataPersistenceError) {
        try await database.write { context throws(CurrencyMetadataPersistenceError) in
            for code in codes {
                context.insert(CurrencyMetadataRecord(code: code, lastUpdated: date))
            }
        }
    }
}
