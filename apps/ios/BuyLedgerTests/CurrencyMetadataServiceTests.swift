//
//  CurrencyMetadataServiceTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/26.
//

import ComposableArchitecture
import Foundation
import SwiftData
import Testing

@testable import BuyLedger

/// 驗證幣別主檔 Service 的 API 分類與快取行為
struct CurrencyMetadataServiceTests {

    // MARK: - Tests

    /// 金鑰含控制字元時不送出支援幣別請求，並回報原有診斷錯誤
    ///
    /// - Throws: 沒有取得預期的 `.api(.transport(underlying:))` 時由 `#require` 丟出測試斷言錯誤
    @Test
    func refreshIfStale_金鑰含控制字元_送出前拒絕且不洩漏憑證() async throws {
        // Given
        let httpClient = MockHTTPClient()
        let database = BuyLedgerDatabaseTests.makeInMemoryDatabase()
        let service = Self.makeService(
            database: database,
            httpClient: httpClient,
            apiKey: "network-test-fake-key\u{0000}",
            now: TestDependencies.fixedNow
        )
        var actualError: CurrencyMetadataServiceError?

        // When
        do throws(CurrencyMetadataServiceError) {
            _ = try await service.refreshIfStale(0)
        } catch {
            actualError = error
        }

        // Then
        let error = try #require(actualError)
        let underlying: (any Error & Sendable)?
        switch error {
        case .api(.transport(let actualUnderlying)):
            underlying = actualUnderlying

        case .api(.http), .api(.decoding), .api(.apiError), .api(.quotaExceeded), .api(.invalidKey),
                .persistence:
            underlying = nil
        }
        let diagnosticError = try #require(underlying) as NSError
        #expect(diagnosticError.domain == "com.leoho.BuyLedger.networking")
        #expect(diagnosticError.code == 1)
        #expect(diagnosticError.localizedDescription == "URL 組合失敗。")
        #expect(httpClient.dataCallCount == 0)
        #expect(httpClient.dataReceivedArguments.isEmpty)
    }

    /// 成功取得支援幣別時只把金鑰放在 Authorization header
    ///
    /// - Throws: API 失敗時丟出 `.api(.invalidKey)`、`.api(.transport(underlying:))`、
    ///   `.api(.http(statusCode:))`、`.api(.decoding(underlying:))`、`.api(.quotaExceeded)` 或
    ///   `.api(.apiError(code:))`；快取讀取失敗時丟出
    ///   `.persistence(.storage(.fetchFailed(underlying:)))`；空清單時丟出
    ///   `.persistence(.emptyCodeList)`；寫入失敗時丟出
    ///   `.persistence(.storage(.saveFailed(underlying:)))`；response fixture 建立失敗、沒有記錄到
    ///   請求或請求缺少 URL 時由 `#require` 丟出測試斷言錯誤
    @Test
    func refreshIfStale_成功請求_金鑰只放授權標頭() async throws {
        // Given
        let key = "unit-test-live-key-codes"
        let responseJSON = #"{"result":"success","supported_codes":[["USD","US Dollar"]]}"#
        let responseBody = Data(responseJSON.utf8)
        let httpClient = MockHTTPClient()
        httpClient.dataResult = .success(try Self.makeHTTPResponse(body: responseBody))
        let database = BuyLedgerDatabaseTests.makeInMemoryDatabase()
        let service = Self.makeService(
            database: database,
            httpClient: httpClient,
            apiKey: key,
            now: TestDependencies.fixedNow
        )

        // When
        let didRefresh = try await service.refreshIfStale(0)

        // Then
        let codes = try await service.fetchCodes()
        #expect(didRefresh)
        #expect(codes == [.usd])
        let request = try #require(httpClient.dataReceivedArguments.first)
        let requestURLString = try #require(request.url?.absoluteString)
        #expect(requestURLString == "https://v6.exchangerate-api.com/v6/codes")
        #expect(!requestURLString.contains(key))
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer \(key)")
    }

    /// 配額用盡回應仍歸類為 `.quotaExceeded`
    ///
    /// - Throws: `refreshIfStale` 沒有丟出錯誤，或 fixture 建立失敗時由 `#require` 丟出
    ///   測試斷言錯誤
    @Test
    func refreshIfStale_配額耗盡回應_歸類為配額錯誤() async throws {
        // Given
        let responseBody = Data(#"{"result":"error","error-type":"quota-reached"}"#.utf8)
        let httpClient = MockHTTPClient()
        httpClient.dataResult = .success(try Self.makeHTTPResponse(body: responseBody))
        let service = Self.makeService(
            database: BuyLedgerDatabaseTests.makeInMemoryDatabase(),
            httpClient: httpClient,
            apiKey: "network-test-key",
            now: TestDependencies.fixedNow
        )
        var actualError: CurrencyMetadataServiceError?

        // When
        do throws(CurrencyMetadataServiceError) {
            _ = try await service.refreshIfStale(0)
        } catch {
            actualError = error
        }

        // Then
        let error = try #require(actualError)
        let isQuotaExceeded: Bool
        switch error {
        case .api(.quotaExceeded):
            isQuotaExceeded = true

        case .api(.transport), .api(.http), .api(.decoding), .api(.apiError), .api(.invalidKey),
                .persistence:
            isQuotaExceeded = false
        }
        #expect(isQuotaExceeded)
        #expect(httpClient.dataCallCount == 1)
    }

    /// 無法辨識的支援幣別結果會保留原始結果字串
    ///
    /// - Throws: `refreshIfStale` 沒有丟出錯誤，或 fixture 建立失敗時由 `#require` 丟出
    ///   測試斷言錯誤
    @Test
    func refreshIfStale_未知結果_分類為服務錯誤() async throws {
        // Given
        let responseBody = Data(#"{"result":"partial"}"#.utf8)
        let httpClient = MockHTTPClient()
        httpClient.dataResult = .success(try Self.makeHTTPResponse(body: responseBody))
        let service = Self.makeService(
            database: BuyLedgerDatabaseTests.makeInMemoryDatabase(),
            httpClient: httpClient,
            apiKey: "network-test-key",
            now: TestDependencies.fixedNow
        )
        var actualError: CurrencyMetadataServiceError?

        // When
        do throws(CurrencyMetadataServiceError) {
            _ = try await service.refreshIfStale(0)
        } catch {
            actualError = error
        }

        // Then
        let error = try #require(actualError)
        let actualCode: String?
        switch error {
        case .api(.apiError(let code)):
            actualCode = code

        case .api(.transport), .api(.http), .api(.decoding), .api(.quotaExceeded),
                .api(.invalidKey), .persistence:
            actualCode = nil
        }
        #expect(actualCode == "unexpected-result-partial")
        #expect(httpClient.dataCallCount == 1)
    }
}

// MARK: - Internal Method

extension CurrencyMetadataServiceTests {

    /// 以指定依賴與 API key 字串建立正式幣別主檔 Service，設定來源由 API key 自動包裝
    ///
    /// - Parameters:
    ///   - database: 要注入的資料庫
    ///   - httpClient: 要注入的 HTTP client
    ///   - apiKey: 要提供給 Service 的 API key
    ///   - now: 測試使用的固定時間
    /// - Returns: 已擷取測試依賴的正式 Service
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
    /// - Returns: 已擷取測試依賴的正式 Service
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
    /// - Parameter apiKey: 要回傳的 API key，nil 代表未設定
    /// - Returns: 可記錄讀取 key 的設定來源
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

    /// 建立 HTTP client 測試使用的成功回應
    ///
    /// - Parameter body: HTTP 回應內容
    /// - Returns: 回應內容與 HTTP 200 狀態
    /// - Throws: 固定 URL 或 `HTTPURLResponse` 無法建立時由 `#require` 丟出測試斷言錯誤
    static func makeHTTPResponse(body: Data) throws(any Error) -> (Data, HTTPURLResponse) {
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
}
