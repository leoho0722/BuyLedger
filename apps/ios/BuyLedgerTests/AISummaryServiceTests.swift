//
//  AISummaryServiceTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/27.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// 驗證 AI 摘要 Service 的請求、金鑰與串流處理
struct AISummaryServiceTests {

    // MARK: - Tests

    /// 驗證合法串流行能取出文字內容，並標記尚未完成 (`done` 為 `false`)
    ///
    /// - Throws: 預期的解析結果不存在時由 `#require` 丟出測試失敗
    @Test
    func parse_合法串流行_擷取文字與未完成狀態() throws {
        // Given
        let line = #"{"model":"gemma4:31b-cloud","message":{"role":"assistant","content":"Hello"},"done":false}"#

        // When
        let actualParsed = AISummaryService.parse(line: line)

        // Then
        let parsed = try #require(actualParsed)
        #expect(parsed.content == "Hello")
        #expect(parsed.done == false)
    }

    /// 驗證串流最後一行取出空的文字內容，並標記串流完成 (`done` 為 `true`)
    ///
    /// - Throws: 預期的解析結果不存在時由 `#require` 丟出測試失敗
    @Test
    func parse_完成行_標記串流完成() throws {
        // Given
        let line = #"{"model":"m","message":{"role":"assistant","content":""},"done":true,"total_duration":123456}"#

        // When
        let actualParsed = AISummaryService.parse(line: line)

        // Then
        let parsed = try #require(actualParsed)
        #expect(parsed.content.isEmpty)
        #expect(parsed.done)
    }

    /// 驗證缺少 `message` 欄位的行仍可解析 (不回傳 `nil`)，文字內容為空且 `done` 為 `true`
    ///
    /// - Throws: 預期的解析結果不存在時由 `#require` 丟出測試失敗
    @Test
    func parse_缺少訊息_回傳空內容與完成狀態() throws {
        // Given
        let line = #"{"model":"m","done":true}"#

        // When
        let actualParsed = AISummaryService.parse(line: line)

        // Then
        let parsed = try #require(actualParsed)
        #expect(parsed.content.isEmpty)
        #expect(parsed.done)
    }

    /// 驗證空白、空字串、非 JSON 與被截斷的 JSON 行都回傳 `nil`，而不是空內容的解析結果
    ///
    /// - Parameter line: 要解析的空白或格式錯誤文字
    @Test(arguments: ["   ", "", "this is not json", "{\"message\": "])
    func parse_空白或格式錯誤行_忽略無效資料(line: String) {
        // Given

        // When
        let parsed = AISummaryService.parse(line: line)

        // Then
        #expect(parsed == nil)
    }

    /// 驗證預覽替身會輸出固定的 Markdown 摘要
    ///
    /// - Throws: 預覽串流失敗時由 stream 丟出錯誤
    @Test
    func previewValue_假資料串流_輸出固定摘要() async throws {
        // Given
        let service = AISummaryService.previewValue

        // When
        var chunks: [String] = []
        for try await chunk in service.streamSummary("prompt", "model", "key") {
            chunks.append(chunk)
        }

        // Then
        #expect(
            chunks == [
                "## 商品明細總結\n\n",
                "本批訂單共涵蓋多個品項，以下為重點觀察：\n\n",
                "- **熱門品項**：藍牙耳機 x3、保溫瓶 x2\n",
                "- **類別分佈**：以 3C 配件為主\n",
                "- **金額區間**：單價集中在 NT$300–1,200\n",
            ]
        )
    }

    /// 驗證摘要請求包含模型、訊息、授權與串流設定
    ///
    /// - Throws: 請求本文不是合法 JSON 時丟出 `JSONSerialization` 的解析錯誤；沒有丟出 `APIError`
    ///   (預期為 `.transport` 錯誤)、沒有記錄到請求、請求沒有本文、本文不是 JSON 物件或
    ///   `messages` 形狀不符時由 `#require` 丟出測試斷言錯誤
    @Test
    func streamSummary_指定模型提示與金鑰_送出串流請求() async throws {
        // Given
        let httpClient = MockHTTPClient()
        let service = withDependencies {
            $0.httpClient = httpClient
        } operation: {
            AISummaryService.liveValue
        }
        var actualError: (any Error)?

        // When
        do {
            for try await _ in service.streamSummary(
                "摘要提示",
                "gemma4:31b-cloud",
                "summary-test-key"
            ) {}
        } catch {
            actualError = error
        }

        // Then
        let error = try #require(actualError as? APIError)
        let isTransportError: Bool
        switch error {
        case .transport:
            isTransportError = true

        case .http, .decoding, .apiError, .quotaExceeded, .invalidKey:
            isTransportError = false
        }
        #expect(isTransportError)
        #expect(httpClient.bytesCallCount == 1)
        let request = try #require(httpClient.bytesReceivedArguments.first)
        #expect(request.url?.absoluteString == "https://ollama.com/api/chat")
        #expect(request.httpMethod == "POST")
        #expect(request.timeoutInterval == 60)
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer summary-test-key")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
        let body = try #require(request.httpBody)
        let object = try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])
        #expect(object["model"] as? String == "gemma4:31b-cloud")
        #expect(object["stream"] as? Bool == true)
        let messages = try #require(object["messages"] as? [[String: String]])
        #expect(messages.map { $0["role"] } == ["user"])
        #expect(messages.map { $0["content"] } == ["摘要提示"])
    }

    /// 驗證 Service 會依 HTTP 狀態分類金鑰與其他錯誤
    ///
    /// - Parameters:
    ///   - statusCode: 固定回傳的 HTTP 狀態碼
    ///   - expectedError: 預期的錯誤分類
    /// - Throws: 預期的 API 錯誤未出現時由 `#require` 丟出測試失敗
    @Test(arguments: [
        (401, ErrorClassification.invalidKey),
        (403, .invalidKey),
        (500, .http(statusCode: 500)),
    ])
    func streamSummary_非成功狀態碼_依狀態分類錯誤(
        statusCode: Int,
        expectedError: ErrorClassification
    ) async throws {
        // Given
        let apiKey = "summary-status-\(statusCode)"
        let authorization = "Bearer \(apiKey)"
        MockURLProtocol.setStub(
            authorization: authorization,
            statusCode: statusCode,
            body: Data("error".utf8)
        )
        let service = withDependencies {
            $0.httpClient = makeHTTPClient()
        } operation: {
            AISummaryService.liveValue
        }
        var actualError: (any Error)?

        // When
        do {
            for try await _ in service.streamSummary("prompt", "model", apiKey) {}
        } catch {
            actualError = error
        }

        // Then
        let error = try #require(actualError as? APIError)
        let actualErrorClassification: ErrorClassification
        switch error {
        case .invalidKey:
            actualErrorClassification = .invalidKey

        case .http(let statusCode):
            actualErrorClassification = .http(statusCode: statusCode)

        case .transport, .decoding, .apiError, .quotaExceeded:
            actualErrorClassification = .other
        }
        #expect(actualErrorClassification == expectedError)
    }

    /// 驗證摘要串流依序輸出各段內容，略過空內容與無法解析的行，收到 `done` 後不再輸出
    ///
    /// - Throws: 迭代時連線失敗丟出 `APIError.transport(underlying:)`
    @Test
    func streamSummary_收到多段內容與完成行_依序輸出並結束() async throws {
        // Given
        let apiKey = "summary-stream-success"
        let responseBody = Data(
            #"""
            {"message":{"content":"第一段"},"done":false}
            {"message":{"content":""},"done":false}
            not json
            {"message":{"content":"第二段"},"done":true}
            {"message":{"content":"不應輸出"},"done":false}

            """#.utf8
        )
        MockURLProtocol.setStub(
            authorization: "Bearer \(apiKey)",
            statusCode: 200,
            body: responseBody
        )
        let service = withDependencies {
            $0.httpClient = makeHTTPClient()
        } operation: {
            AISummaryService.liveValue
        }

        // When
        var chunks: [String] = []
        for try await chunk in service.streamSummary("prompt", "model", apiKey) {
            chunks.append(chunk)
        }

        // Then
        #expect(chunks == ["第一段", "第二段"])
    }

    /// 驗證讀取 API 金鑰時向設定來源查詢一次 `OLLAMA_API_KEY`，並回傳該來源提供的值
    @Test
    func apiKey_設定來源含Ollama金鑰_回傳金鑰並記錄查詢鍵() {
        // Given
        let configurationStore = MockAppConfigurationStore()
        configurationStore.stringResult = ["OLLAMA_API_KEY": "ollama-test-key"]
        let service = withDependencies {
            $0.appConfigurationStore = configurationStore
        } operation: {
            AISummaryService.liveValue
        }

        // When
        let apiKey = service.apiKey()

        // Then
        #expect(apiKey == "ollama-test-key")
        #expect(configurationStore.stringCallCount == 1)
        #expect(configurationStore.stringReceivedArguments == ["OLLAMA_API_KEY"])
    }
}

// MARK: - Nested Types

extension AISummaryServiceTests {

    /// Service 錯誤的測試分類
    ///
    /// - Note: 用於測試方法的參數型別，須為 internal
    enum ErrorClassification: Equatable, Sendable {

        /// 回應 401 與 403 都應歸為金鑰無效 (`APIError.invalidKey`)
        case invalidKey

        /// 其他非 2xx 狀態碼保留原碼 (`APIError.http(statusCode:)`)
        ///
        /// - Parameter statusCode: 回應的 HTTP 狀態碼
        case http(statusCode: Int)

        /// 上述兩類以外的 `APIError` (`transport`、`decoding`、`apiError`、`quotaExceeded`)，
        /// 測試預期不會出現
        case other
    }
}

// MARK: - Internal Method

extension AISummaryServiceTests {

    /// 建立使用 `MockURLProtocol` 的 HTTP client
    ///
    /// - Returns: 使用 `.ephemeral` session 的 HTTP client
    func makeHTTPClient() -> HTTPClient {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        return HTTPClient(session: URLSession(configuration: configuration))
    }
}
