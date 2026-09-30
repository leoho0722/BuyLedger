//
//  AppLanguageTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/23.
//

import Foundation
import Testing

@testable import BuyLedger

/// 驗證 AppLanguage 的 locale 與持久化行為
@MainActor
struct AppLanguageTests {

    // MARK: - Tests

    /// 驗證支援語言使用穩定的 locale identifier
    @Test(arguments: AppLanguage.allCases)
    func languageUsesSupportedLocaleIdentifiers(language: AppLanguage) {
        // Given
        let expectedIdentifier = language == .traditionalChinese ? "zh-Hant" : "en"

        // When
        let identifier = language.localeIdentifier

        // Then
        #expect(identifier == expectedIdentifier)
    }

    /// 驗證語言能建立對應的 Foundation locale
    @Test(arguments: AppLanguage.allCases)
    func languageProvidesMatchingLocale(language: AppLanguage) {
        // Given
        let expectedIdentifier = language == .traditionalChinese ? "zh-Hant" : "en"

        // When
        let locale = language.locale

        // Then
        #expect(locale.identifier == expectedIdentifier)
    }

    /// 驗證語言標題使用本地化資源
    @Test(arguments: AppLanguage.allCases)
    func languageTitlesUseLocalizedResources(language: AppLanguage) {
        // Given
        let expectedTitle = language == .traditionalChinese ? "正體中文" : "English"

        // When
        let title = String(localized: language.title)

        // Then
        #expect(title == expectedTitle)
    }

    /// 驗證未知或缺少的儲存值會回退正體中文
    @Test(arguments: StoredLanguageScenario.allCases)
    func languageStoredValueFallsBack(scenario: StoredLanguageScenario) {
        // Given
        let storedValue = scenario.storedValue

        // When
        let language = AppLanguage(storedValue: storedValue)

        // Then
        #expect(language == scenario.expectedLanguage)
    }
}

// MARK: - Nested Types

extension AppLanguageTests {

    /// AppLanguage 的持久化輸入情境
    enum StoredLanguageScenario: CaseIterable {

        /// 沒有儲存值
        case missing

        /// 空字串
        case empty

        /// 不支援的值
        case unsupported

        /// 英文值
        case english

        /// 此情境的儲存值
        var storedValue: String? {
            switch self {
            case .missing:
                nil

            case .empty:
                ""

            case .unsupported:
                "unsupported"

            case .english:
                "english"
            }
        }

        /// 此情境預期的語言
        var expectedLanguage: AppLanguage {
            self == .english ? .english : .traditionalChinese
        }
    }
}
