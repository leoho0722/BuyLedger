//
//  AISummaryServiceTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/27.
//

import Foundation
import Testing

@testable import BuyLedger

/// `AISummaryService` 的單元測試，以替身 `URLProtocol` 與設定來源取代網路與正式設定
struct AISummaryServiceTests {

    /// 驗證 `previewValue` 的 `streamSummary` 依序輸出固定的五段 Markdown 摘要片段
    ///
    /// - Throws: 預覽串流失敗時由 stream 丟出錯誤
    @Test
    func previewValue_假資料串流_輸出固定摘要() async throws {
        // Given
        let service = AISummaryService.previewValue

        // When
        var chunks: [String] = []
        for try await chunk in service.streamSummary(
            "prompt",
            .anthropic,
            "model",
            "key"
        ) {
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

    /// 驗證 `streamSummary` 以 Anthropic Messages API 的格式送出串流請求，金鑰只放在標頭
    ///
    /// - Throws: 沒有記錄到請求、請求沒有本文、本文不是 JSON 物件或 `messages` 形狀不符時由 `#require`
    ///   丟出測試斷言錯誤；請求本文不是合法 JSON 時由 `JSONSerialization` 丟出解析錯誤
    /// - Note: 請求方法為 POST，端點為 `https://api.anthropic.com/v1/messages`
    /// - Note: `x-api-key` 標頭為 API 金鑰，網址不含金鑰
    /// - Note: JSON 本文的 `model` 為指定模型，`max_tokens` 為 16000，`stream` 為 `true`
    /// - Note: JSON 本文的 `messages` 只有一則 `user` 訊息，內容為提示，沒有 `system`
    @Test
    func streamSummary_指定模型提示與金鑰_送出串流請求() async throws {
        // Given
        let apiKey = "summary-request-contract"
        let events = Self.makeSuccessEvents(texts: ["摘要"])
        MockChatURLProtocol.setStub(apiKey: apiKey, statusCode: 200, body: Self.makeSSEBody(events))
        let service = AISummaryServiceTestSupport.makeService()

        // When
        for try await _ in service.streamSummary(
            "摘要提示",
            .anthropic,
            "claude-haiku-5-5",
            apiKey
        ) {}

        // Then
        let request = try #require(MockChatURLProtocol.lastRequest(apiKey: apiKey))
        #expect(request.method == "POST")
        #expect(request.url?.absoluteString == "https://api.anthropic.com/v1/messages")
        #expect(request.url?.absoluteString.contains(apiKey) == false)
        #expect(request.headers["x-api-key"] == apiKey)
        let body = try #require(request.body)
        let object = try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])
        #expect(object["model"] as? String == "claude-haiku-5-5")
        #expect(object["max_tokens"] as? Int == 16_000)
        #expect(object["stream"] as? Bool == true)
        #expect(object["system"] == nil)
        let messages = try #require(object["messages"] as? [[String: String]])
        #expect(messages == [["role": "user", "content": "摘要提示"]])
    }

    /// 驗證摘要串流依序輸出各段內容，略過空字串片段，收到結束事件後不再輸出
    ///
    /// - Throws: 迭代時連線失敗丟出 `APIError.transport(underlying:)`
    @Test
    func streamSummary_收到多段內容與結束事件_依序輸出並結束() async throws {
        // Given
        let apiKey = "summary-stream-success"
        var events = Self.makeSuccessEvents(texts: ["第一段", "", "第二段"])
        events.append(.textDelta("不應輸出"))
        MockChatURLProtocol.setStub(apiKey: apiKey, statusCode: 200, body: Self.makeSSEBody(events))
        let service = AISummaryServiceTestSupport.makeService()

        // When
        var chunks: [String] = []
        for try await chunk in service.streamSummary(
            "prompt",
            .anthropic,
            "model",
            apiKey
        ) {
            chunks.append(chunk)
        }

        // Then
        #expect(chunks == ["第一段", "第二段"])
    }

    /// 驗證回答因輸出上限被截斷時，保留已收到的內容並正常結束，不當成失敗
    ///
    /// - Throws: 迭代時連線失敗丟出 `APIError.transport(underlying:)`
    @Test
    func streamSummary_因輸出上限結束_保留已收內容並正常結束() async throws {
        // Given
        let apiKey = "summary-stream-max-tokens"
        let events = Self.makeSuccessEvents(texts: ["第一段"], stopReason: "max_tokens")
        MockChatURLProtocol.setStub(apiKey: apiKey, statusCode: 200, body: Self.makeSSEBody(events))
        let service = AISummaryServiceTestSupport.makeService()

        // When
        var chunks: [String] = []
        for try await chunk in service.streamSummary(
            "prompt",
            .anthropic,
            "model",
            apiKey
        ) {
            chunks.append(chunk)
        }

        // Then
        #expect(chunks == ["第一段"])
    }

    /// 驗證模型拒答時，已收到的內容保留，並以 `.apiError(code: "refused")` 結束
    ///
    /// - Throws: 預期的 API 錯誤未出現時由 `#require` 丟出測試失敗
    @Test
    func streamSummary_模型拒答_以拒答錯誤結束() async throws {
        // Given
        let apiKey = "summary-stream-refusal"
        let events = Self.makeSuccessEvents(texts: ["第一段"], stopReason: "refusal")
        MockChatURLProtocol.setStub(apiKey: apiKey, statusCode: 200, body: Self.makeSSEBody(events))
        let service = AISummaryServiceTestSupport.makeService()
        var chunks: [String] = []
        var actualError: (any Error)?

        // When
        do {
            for try await chunk in service.streamSummary(
                "prompt",
                .anthropic,
                "model",
                apiKey
            ) {
                chunks.append(chunk)
            }
        } catch {
            actualError = error
        }

        // Then
        let error = try #require(actualError as? APIError)
        #expect(chunks == ["第一段"])
        #expect(Self.classification(of: error) == .apiError(code: "refused"))
    }

    /// 驗證回應在沒有結束事件時就結束，已收到的內容保留，並以 `.decoding` 結束，不當成正常完成
    ///
    /// - Throws: 預期的 API 錯誤未出現時由 `#require` 丟出測試失敗
    @Test
    func streamSummary_回應缺少結束事件_以解碼錯誤結束() async throws {
        // Given
        let apiKey = "summary-stream-missing-finish"
        let events: [SSEEvent] = [.messageStart(), .textBlockStart(), .textDelta("第一段")]
        MockChatURLProtocol.setStub(apiKey: apiKey, statusCode: 200, body: Self.makeSSEBody(events))
        let service = AISummaryServiceTestSupport.makeService()
        var chunks: [String] = []
        var actualError: (any Error)?

        // When
        do {
            for try await chunk in service.streamSummary(
                "prompt",
                .anthropic,
                "model",
                apiKey
            ) {
                chunks.append(chunk)
            }
        } catch {
            actualError = error
        }

        // Then
        let error = try #require(actualError as? APIError)
        #expect(chunks == ["第一段"])
        #expect(Self.classification(of: error) == .decoding)
    }

    /// 驗證消費端在收到第一段後取消時，已收到的內容保留，串流正常結束而不丟出錯誤
    ///
    /// - Throws: 串流丟出錯誤時，由消費 task 的結果丟出
    /// - Note: 回應只送出到第一段文字，連線維持開啟，所以只有取消能讓串流結束
    @Test(.timeLimit(.minutes(1)))
    func streamSummary_收到第一段後取消消費_保留已收內容並正常結束() async throws {
        // Given
        let apiKey = "summary-stream-cancelled"
        let events: [SSEEvent] = [.messageStart(), .textBlockStart(), .textDelta("第一段")]
        MockChatURLProtocol.setUnfinishedStub(
            apiKey: apiKey,
            statusCode: 200,
            body: Self.makeSSEBody(events)
        )
        let service = AISummaryServiceTestSupport.makeService()
        let stream = service.streamSummary(
            "prompt",
            .anthropic,
            "model",
            apiKey
        )

        // When
        let consumer = Task {
            var chunks: [String] = []
            for try await chunk in stream {
                chunks.append(chunk)
                _ = withUnsafeCurrentTask { $0?.cancel() }
            }
            return chunks
        }
        let chunks = try await consumer.value

        // Then
        #expect(chunks == ["第一段"])
    }

    /// 驗證 `streamSummary` 遇到非成功狀態碼 (本文不是 JSON) 時，依 LKAIKit 的狀態碼預設分類轉成 App 的錯誤
    ///
    /// - Parameter scenario: 固定回傳的 HTTP 狀態碼與預期的錯誤分類
    /// - Throws: 預期的 API 錯誤未出現時由 `#require` 丟出測試失敗
    @Test(arguments: [
        HTTPStatusErrorScenario(
            statusCode: 400,
            expectedClassification: .apiError(code: "invalid_request")
        ),
        HTTPStatusErrorScenario(statusCode: 401, expectedClassification: .invalidKey),
        HTTPStatusErrorScenario(statusCode: 402, expectedClassification: .quotaExceeded),
        HTTPStatusErrorScenario(statusCode: 403, expectedClassification: .invalidKey),
        HTTPStatusErrorScenario(statusCode: 429, expectedClassification: .http(statusCode: 429)),
        HTTPStatusErrorScenario(statusCode: 500, expectedClassification: .http(statusCode: 500)),
        HTTPStatusErrorScenario(statusCode: 529, expectedClassification: .http(statusCode: 529)),
    ])
    func streamSummary_非成功狀態碼_依狀態分類錯誤(scenario: HTTPStatusErrorScenario) async throws {
        // Given
        let apiKey = "summary-status-\(scenario.statusCode)"
        MockChatURLProtocol.setStub(
            apiKey: apiKey,
            statusCode: scenario.statusCode,
            body: Data("error".utf8)
        )
        let service = AISummaryServiceTestSupport.makeService()
        var actualError: (any Error)?

        // When
        do {
            for try await _ in service.streamSummary(
                "prompt",
                .anthropic,
                "model",
                apiKey
            ) {}
        } catch {
            actualError = error
        }

        // Then
        let error = try #require(actualError as? APIError)
        #expect(Self.classification(of: error) == scenario.expectedClassification)
    }

    /// 驗證 `apiKey(.anthropic)` 向設定來源查詢一次 `ANTHROPIC_API_KEY`，並回傳該來源提供的值
    @Test
    func apiKey_設定來源含Anthropic金鑰_回傳金鑰並記錄查詢鍵() {
        // Given
        let configurationStore = MockAppConfigurationStore()
        configurationStore.stringResult = ["ANTHROPIC_API_KEY": "anthropic-test-key"]
        let service = AISummaryServiceTestSupport.makeService(
            configurationStore: configurationStore
        )

        // When
        let apiKey = service.apiKey(.anthropic)

        // Then
        #expect(apiKey == "anthropic-test-key")
        #expect(configurationStore.stringCallCount == 1)
        #expect(configurationStore.stringReceivedArguments == ["ANTHROPIC_API_KEY"])
    }
}

// MARK: - Nested Types

extension AISummaryServiceTests {

    /// `APIError` 的測試分類，供斷言比對錯誤屬於哪一類
    ///
    /// - Note: 用於測試方法的參數型別，須為 `internal`
    enum ErrorClassification: Equatable, Sendable {

        /// 金鑰無效 (`APIError.invalidKey`)
        case invalidKey

        /// 配額耗盡 (`APIError.quotaExceeded`)
        case quotaExceeded

        /// 非 2xx 狀態碼保留原碼 (`APIError.http(statusCode:)`)
        ///
        /// - Parameter statusCode: 回應的 HTTP 狀態碼
        case http(statusCode: Int)

        /// API 業務錯誤 (`APIError.apiError(code:)`)
        ///
        /// - Parameter code: 錯誤代碼
        case apiError(code: String)

        /// 網路層錯誤 (`APIError.transport(underlying:)`)，保留底層 `NSError` 的網域與代碼
        ///
        /// - Parameters:
        ///   - domain: 底層 `NSError` 的網域
        ///   - code: 底層 `NSError` 的代碼
        case transport(domain: String, code: Int)

        /// 回應無法解讀 (`APIError.decoding(underlying:)`)
        case decoding
    }

    /// 一組固定 HTTP 狀態碼與預期錯誤分類的測試資料
    struct HTTPStatusErrorScenario: Sendable {

        /// 固定回傳的 HTTP 狀態碼
        let statusCode: Int

        /// 預期的錯誤分類
        let expectedClassification: ErrorClassification
    }

    /// Anthropic 串流回應的一個 SSE 事件
    struct SSEEvent: Sendable {

        /// 事件名稱，放在 `event:` 行
        let name: String

        /// 事件資料的 JSON 文字，放在 `data:` 行
        let data: String

        /// `message_start` 事件，內容是一則還沒有任何內容的助理訊息
        ///
        /// - Returns: `message_start` 事件
        static func messageStart() -> Self {
            Self(
                name: "message_start",
                data: #"{"type":"message_start","message":{"id":"msg_1","type":"message","role":"assistant","content":[],"model":"claude-haiku-5-5","stop_reason":null,"stop_sequence":null}}"#
            )
        }

        /// 開始一個文字區塊的 `content_block_start` 事件
        ///
        /// - Returns: `content_block_start` 事件
        static func textBlockStart() -> Self {
            Self(
                name: "content_block_start",
                data: #"{"type":"content_block_start","index":0,"content_block":{"type":"text","text":""}}"#
            )
        }

        /// 一段文字的 `content_block_delta` 事件
        ///
        /// - Parameter text: 這一段的文字
        /// - Returns: `content_block_delta` 事件
        static func textDelta(_ text: String) -> Self {
            Self(
                name: "content_block_delta",
                data: #"{"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":"\#(text)"}}"#
            )
        }

        /// 結束文字區塊的 `content_block_stop` 事件
        ///
        /// - Returns: `content_block_stop` 事件
        static func blockStop() -> Self {
            Self(name: "content_block_stop", data: #"{"type":"content_block_stop","index":0}"#)
        }

        /// 帶結束原因的 `message_delta` 事件
        ///
        /// - Parameter stopReason: `stop_reason` 的值
        /// - Returns: `message_delta` 事件
        static func messageDelta(stopReason: String) -> Self {
            Self(
                name: "message_delta",
                data: #"{"type":"message_delta","delta":{"stop_reason":"\#(stopReason)","stop_sequence":null}}"#
            )
        }

        /// 表示整則訊息結束的 `message_stop` 事件
        ///
        /// - Returns: `message_stop` 事件
        static func messageStop() -> Self {
            Self(name: "message_stop", data: #"{"type":"message_stop"}"#)
        }
    }
}

// MARK: - Private Method

private extension AISummaryServiceTests {

    /// 組出一次完整回答的 SSE 事件：開始、各段文字、結束原因與結束
    ///
    /// - Parameters:
    ///   - texts: 依序輸出的文字片段
    ///   - stopReason: `message_delta` 的 `stop_reason`，預設為 `end_turn`
    /// - Returns: 依序排列的 SSE 事件
    static func makeSuccessEvents(texts: [String], stopReason: String = "end_turn") -> [SSEEvent] {
        var events: [SSEEvent] = [.messageStart(), .textBlockStart()]
        events += texts.map { SSEEvent.textDelta($0) }
        events += [.blockStop(), .messageDelta(stopReason: stopReason), .messageStop()]
        return events
    }

    /// 把 SSE 事件依序排成回應本文，每個事件是 `event: <名稱>`、`data: <JSON>` 與一個空行
    ///
    /// - Parameter events: 依序排列的 SSE 事件
    /// - Returns: 回應本文
    static func makeSSEBody(_ events: [SSEEvent]) -> Data {
        let text = events.map { "event: \($0.name)\ndata: \($0.data)\n\n" }.joined()
        return Data(text.utf8)
    }

    /// 把 `APIError` 轉成測試用的分類
    ///
    /// - Parameter error: 要分類的 App 錯誤
    /// - Returns: 對應的測試分類
    static func classification(of error: APIError) -> ErrorClassification {
        switch error {
        case .invalidKey:
            .invalidKey

        case .quotaExceeded:
            .quotaExceeded

        case .http(let statusCode):
            .http(statusCode: statusCode)

        case .apiError(let code):
            .apiError(code: code)

        case .transport(let underlying):
            .transport(domain: (underlying as NSError).domain, code: (underlying as NSError).code)

        case .decoding:
            .decoding
        }
    }
}
