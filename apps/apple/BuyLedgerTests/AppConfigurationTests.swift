//
//  AppConfigurationTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/6/21.
//

import Foundation
import Testing
@testable import BuyLedger

struct AppConfigurationTests {

    // MARK: - Tests

    @Test func normalizeReturnsTrimmedValue() {
        #expect(AppConfiguration.normalize("  abc123  ", placeholder: "$(OLLAMA_API_KEY)") == "abc123")
    }

    @Test func normalizeReturnsNilForNil() {
        #expect(AppConfiguration.normalize(nil, placeholder: "$(OLLAMA_API_KEY)") == nil)
    }

    @Test func normalizeReturnsNilForEmptyOrWhitespace() {
        #expect(AppConfiguration.normalize("", placeholder: "$(OLLAMA_API_KEY)") == nil)
        #expect(AppConfiguration.normalize("   \n ", placeholder: "$(OLLAMA_API_KEY)") == nil)
    }

    @Test func normalizeReturnsNilForUnsubstitutedPlaceholder() {
        #expect(AppConfiguration.normalize("$(OLLAMA_API_KEY)", placeholder: "$(OLLAMA_API_KEY)") == nil)
    }

    @Test func normalizeKeepsValueWhenPlaceholderDiffers() {
        #expect(AppConfiguration.normalize("$(OLLAMA_API_KEY)", placeholder: "$(EXCHANGE_RATE_API_KEY)") == "$(OLLAMA_API_KEY)")
    }

    @Test func normalizeWithoutPlaceholderTrimsLiteral() {
        #expect(AppConfiguration.normalize("  http://localhost:4000/api  ") == "http://localhost:4000/api")
    }

    @Test func testValueProvidesNothing() {
        let configuration = AppConfiguration.testValue
        #expect(configuration.exchangeRateAPIKey() == nil)
        #expect(configuration.ollamaAPIKey() == nil)
    }
}
