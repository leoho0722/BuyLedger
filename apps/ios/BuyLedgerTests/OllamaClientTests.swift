//
//  OllamaClientTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/5/27.
//

import Foundation
import Testing
@testable import BuyLedger

struct OllamaClientTests {

    // MARK: - parse(line:)

    @Test func parseExtractsContentFromStreamingLine() {
        let line = #"{"model":"gemma4:31b-cloud","message":{"role":"assistant","content":"Hello"},"done":false}"#
        let parsed = OllamaClient.parse(line: line)
        #expect(parsed?.content == "Hello")
        #expect(parsed?.done == false)
    }

    @Test func parseMarksDoneOnFinalLine() {
        let line = #"{"model":"m","message":{"role":"assistant","content":""},"done":true,"total_duration":123456}"#
        let parsed = OllamaClient.parse(line: line)
        #expect(parsed?.content == "")
        #expect(parsed?.done == true)
    }

    @Test func parseTreatsMissingMessageAsEmptyContent() {
        let line = #"{"model":"m","done":true}"#
        let parsed = OllamaClient.parse(line: line)
        #expect(parsed?.content == "")
        #expect(parsed?.done == true)
    }

    @Test func parseReturnsNilForBlankLine() {
        #expect(OllamaClient.parse(line: "   ") == nil)
        #expect(OllamaClient.parse(line: "") == nil)
    }

    @Test func parseReturnsNilForMalformedLine() {
        #expect(OllamaClient.parse(line: "this is not json") == nil)
        #expect(OllamaClient.parse(line: "{\"message\": ") == nil)
    }

    // MARK: - testValue

    @Test func testValueThrowsWhenInvoked() async {
        let client = OllamaClient.testValue
        await #expect(throws: APIError.self) {
            for try await _ in client.streamSummary("prompt", "model", "key") {}
        }
    }

    // MARK: - previewValue

    @Test func previewValueStreamsCannedMarkdown() async throws {
        let client = OllamaClient.previewValue
        var accumulated = ""
        for try await chunk in client.streamSummary("prompt", "model", "key") {
            accumulated += chunk
        }
        #expect(!accumulated.isEmpty)
    }
}
