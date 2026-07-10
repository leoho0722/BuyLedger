//
//  AISummaryFeatureTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/5/27.
//

import ComposableArchitecture
import Foundation
import Testing
@testable import BuyLedger

@MainActor
struct AISummaryFeatureTests {

    // MARK: - Helpers

    private func keyedConfiguration(_ key: String?) -> AppConfiguration {
        AppConfiguration(exchangeRateAPIKey: { nil }, ollamaAPIKey: { key })
    }

    // MARK: - Tests

    @Test func streamingAccumulatesChunksThenFinishes() async {
        let store = TestStore(initialState: AISummaryFeature.State(prompt: "p", model: "m")) {
            AISummaryFeature()
        } withDependencies: {
            $0.appConfiguration = keyedConfiguration("k")
            $0[OllamaClient.self] = OllamaClient(streamSummary: { _, _, _ in
                AsyncThrowingStream { continuation in
                    continuation.yield("# 標題\n")
                    continuation.yield("- 項目 A\n")
                    continuation.yield("- 項目 B")
                    continuation.finish()
                }
            })
        }

        await store.send(.task) {
            $0.phase = .streaming
        }
        await store.receive(\.chunkReceived, "# 標題\n") {
            $0.summaryText = "# 標題\n"
        }
        await store.receive(\.chunkReceived, "- 項目 A\n") {
            $0.summaryText = "# 標題\n- 項目 A\n"
        }
        await store.receive(\.chunkReceived, "- 項目 B") {
            $0.summaryText = "# 標題\n- 項目 A\n- 項目 B"
        }
        await store.receive(\.streamFinished) {
            $0.phase = .finished
        }
    }

    @Test func missingKeyFailsImmediately() async {
        let store = TestStore(initialState: AISummaryFeature.State(prompt: "p", model: "m")) {
            AISummaryFeature()
        } withDependencies: {
            $0.appConfiguration = keyedConfiguration(nil)
        }

        await store.send(.task) {
            $0.phase = .failed
            $0.errorMessage = "尚未設定 OLLAMA_API_KEY。"
        }
    }

    @Test func apiErrorEntersFailedState() async {
        let store = TestStore(initialState: AISummaryFeature.State(prompt: "p", model: "m")) {
            AISummaryFeature()
        } withDependencies: {
            $0.appConfiguration = keyedConfiguration("k")
            $0[OllamaClient.self] = OllamaClient(streamSummary: { _, _, _ in
                AsyncThrowingStream { continuation in
                    continuation.finish(throwing: APIError.invalidKey)
                }
            })
        }

        await store.send(.task) {
            $0.phase = .streaming
        }
        await store.receive(\.streamFailed, "API key 無效或未設定，請確認 OLLAMA_API_KEY。") {
            $0.phase = .failed
            $0.errorMessage = "API key 無效或未設定，請確認 OLLAMA_API_KEY。"
        }
    }

    @Test func transportErrorMapsToFriendlyMessage() async {
        let store = TestStore(initialState: AISummaryFeature.State(prompt: "p", model: "m")) {
            AISummaryFeature()
        } withDependencies: {
            $0.appConfiguration = keyedConfiguration("k")
            $0[OllamaClient.self] = OllamaClient(streamSummary: { _, _, _ in
                AsyncThrowingStream { continuation in
                    continuation.yield("部分內容")
                    continuation.finish(throwing: APIError.transport(message: "boom"))
                }
            })
        }

        await store.send(.task) {
            $0.phase = .streaming
        }
        await store.receive(\.chunkReceived, "部分內容") {
            $0.summaryText = "部分內容"
        }
        await store.receive(\.streamFailed, "連線發生問題，請檢查網路後再試。") {
            $0.phase = .failed
            $0.errorMessage = "連線發生問題，請檢查網路後再試。"
        }
    }
}
