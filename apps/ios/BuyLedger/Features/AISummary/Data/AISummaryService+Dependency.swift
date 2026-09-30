//
//  AISummaryService+Dependency.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/27.
//

import ComposableArchitecture
import Foundation

// MARK: - DependencyKey

extension AISummaryService: DependencyKey {

    /// 正式 App 使用注入的 HTTP client 與設定來源執行 AI 摘要；
    /// 必須是 computed property，測試才能用 `withDependencies` 換掉 HTTP client 與設定來源
    static var liveValue: Self {
        @Dependency(\.httpClient) var httpClient
        @Dependency(\.appConfigurationStore) var configurationStore

        return Self(
            streamSummary: { prompt, model, apiKey in
                AsyncThrowingStream<String, any Error> { [httpClient] continuation in
                    let task = Task {
                        do {
                            let bodyData = try JSONEncoder().encode(
                                OllamaChatRequest(
                                    model: model,
                                    messages: [
                                        OllamaChatRequest.Message(role: "user", content: prompt),
                                    ],
                                    stream: true
                                )
                            )

                            let bytes = try await httpClient.stream(
                                url: Self.chatURL,
                                method: .post,
                                headers: [
                                    "Authorization": "Bearer \(apiKey)",
                                    "Content-Type": "application/json",
                                ],
                                body: bodyData
                            )

                            for try await line in bytes.lines {
                                try Task.checkCancellation()
                                guard let parsed = Self.parse(line: line) else {
                                    continue
                                }
                                if !parsed.content.isEmpty {
                                    continuation.yield(parsed.content)
                                }
                                if parsed.done {
                                    continuation.finish()
                                    return
                                }
                            }
                            continuation.finish()
                        } catch is CancellationError {
                            // sheet 關閉導致取消，視為正常結束
                            continuation.finish()
                        } catch let apiError as APIError {
                            switch apiError {
                            case .http(statusCode: 401), .http(statusCode: 403):
                                continuation.finish(throwing: APIError.invalidKey)

                            case .transport, .http, .decoding, .apiError, .quotaExceeded,
                                    .invalidKey:
                                continuation.finish(throwing: apiError)
                            }
                        } catch {
                            continuation.finish(
                                throwing: APIError.transport(underlying: error as NSError)
                            )
                        }
                    }

                    continuation.onTermination = { _ in
                        task.cancel()
                    }
                }
            },
            apiKey: {
                configurationStore.string(forKey: Self.apiKeyConfigurationKey)
            }
        )
    }

    /// 測試預設值；每個 closure 都必須由測試明確覆寫
    static var testValue: Self {
        let emptyStream = AsyncThrowingStream<String, any Error> {
            $0.finish()
        }

        return Self(
            streamSummary: unimplemented(
                "AISummaryService.streamSummary",
                placeholder: emptyStream
            ),
            apiKey: unimplemented("AISummaryService.apiKey", placeholder: nil)
        )
    }
}

// MARK: - DependencyValues

extension DependencyValues {

    /// 供 reducer 以 `@Dependency(\.aiSummaryService)` 取得的 AI Summary Service
    var aiSummaryService: AISummaryService {
        get { self[AISummaryService.self] }
        set { self[AISummaryService.self] = newValue }
    }
}
