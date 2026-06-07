//
//  APIKeyProviderTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/5/27.
//

import Foundation
import Testing
@testable import BuyLedger

struct APIKeyProviderTests {

    // MARK: - Tests

    @Test func normalizeReturnsTrimmedKey() {
        #expect(APIKeyProvider.normalize("  abc123  ", placeholder: "$(OLLAMA_API_KEY)") == "abc123")
    }

    @Test func normalizeReturnsNilForNil() {
        #expect(APIKeyProvider.normalize(nil, placeholder: "$(OLLAMA_API_KEY)") == nil)
    }

    @Test func normalizeReturnsNilForEmptyOrWhitespace() {
        #expect(APIKeyProvider.normalize("", placeholder: "$(OLLAMA_API_KEY)") == nil)
        #expect(APIKeyProvider.normalize("   \n ", placeholder: "$(OLLAMA_API_KEY)") == nil)
    }

    @Test func normalizeReturnsNilForUnsubstitutedPlaceholder() {
        #expect(APIKeyProvider.normalize("$(OLLAMA_API_KEY)", placeholder: "$(OLLAMA_API_KEY)") == nil)
    }

    @Test func normalizeKeepsValueWhenPlaceholderDiffers() {
        #expect(APIKeyProvider.normalize("$(OLLAMA_API_KEY)", placeholder: "$(EXCHANGE_RATE_API_KEY)") == "$(OLLAMA_API_KEY)")
    }

    @Test func testValueProvidesNoKeys() {
        let provider = APIKeyProvider.testValue
        #expect(provider.exchangeRateAPIKey() == nil)
        #expect(provider.ollamaAPIKey() == nil)
    }
}
