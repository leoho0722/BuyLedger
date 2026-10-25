//
//  AppLanguageTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/23.
//

import Foundation
import Testing

@testable import BuyLedger

/// `AppLanguage` 的單元測試，涵蓋 locale、顯示名稱與持久化值的解析
struct AppLanguageTests {

    // MARK: - Properties

    /// 各語言對應的固定識別字與顯示名稱
    private static let languageCases = [
        LanguageCase(
            language: .traditionalChinese,
            expectedIdentifier: "zh-Hant",
            expectedTitle: "正體中文"
        ),
        LanguageCase(language: .english, expectedIdentifier: "en", expectedTitle: "English"),
    ]

    /// 驗證各支援語言的 `localeIdentifier` 固定為 `zh-Hant` 或 `en`
    ///
    /// - Parameter scenario: App 語言與對應的識別字、顯示名稱
    @Test(arguments: Self.languageCases)
    func localeIdentifier_支援的各語言_回傳固定的識別字(scenario: LanguageCase) {
        // Given
        let language = scenario.language

        // When
        let identifier = language.localeIdentifier

        // Then
        #expect(identifier == scenario.expectedIdentifier)
    }

    /// 驗證各支援語言的 `locale` 識別字為 `zh-Hant` 或 `en`
    ///
    /// - Parameter scenario: App 語言與對應的識別字、顯示名稱
    @Test(arguments: Self.languageCases)
    func locale_支援的各語言_回傳對應的地區設定(scenario: LanguageCase) {
        // Given
        let language = scenario.language

        // When
        let locale = language.locale

        // Then
        #expect(locale.identifier == scenario.expectedIdentifier)
    }

    /// 驗證各支援語言的 `title` 以原文自稱顯示，即「正體中文」與 English
    ///
    /// - Parameter scenario: App 語言與對應的識別字、顯示名稱
    @Test(arguments: Self.languageCases)
    func title_支援的各語言_顯示原文自稱(scenario: LanguageCase) {
        // Given
        let language = scenario.language

        // When
        let title = language.title

        // Then
        #expect(title == scenario.expectedTitle)
    }

    /// 驗證儲存值缺少、為空字串或不受支援時回退正體中文，已知的英文值則保留英文
    ///
    /// - Parameter scenario: 儲存值的輸入情境與預期語言
    @Test(arguments: StoredLanguageScenario.allCases)
    func init_未知或缺少的儲存值_回退正體中文(scenario: StoredLanguageScenario) {
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

    /// 語言屬性的輸入與字面預期值
    struct LanguageCase: Sendable {

        /// 受測的 App 語言
        let language: AppLanguage

        /// 預期的地區識別字
        let expectedIdentifier: String

        /// 預期的語言自稱
        let expectedTitle: String
    }

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
            switch self {
            case .missing, .empty, .unsupported:
                .traditionalChinese

            case .english:
                .english
            }
        }
    }
}
