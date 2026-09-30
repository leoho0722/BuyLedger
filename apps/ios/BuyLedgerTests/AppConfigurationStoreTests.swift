//
//  AppConfigurationStoreTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/26.
//

import Foundation
import Testing

@testable import BuyLedger

/// 驗證 `Info.plist` 設定的讀取與正規化
struct AppConfigurationStoreTests {

    // MARK: - Tests

    /// 驗證 `Info.plist` 字串正規化：去除前後空白，缺少、空白或未展開的同名佔位值回傳 `nil`，
    /// 其他佔位字串原樣保留
    ///
    /// - Parameter scenario: 原始輸入與預期輸出
    /// - Throws: 建立目錄、序列化 plist 或寫檔失敗時丟出底層錯誤；載入測試 `Bundle` 失敗時
    ///   由 `#require` 丟出測試斷言錯誤
    @Test(arguments: Scenario.allCases)
    func string_設定字串含空白與佔位值_套用預期正規化(scenario: Scenario) throws {
        // Given
        let fixture = try BundleFixture(infoDictionary: scenario.infoDictionary)
        let store = AppConfigurationStore(bundle: fixture.bundle)

        // When
        let actualValues = scenario.keys.map { store.string(forKey: $0) }

        // Then
        #expect(actualValues == scenario.expectedValues)
    }
}

// MARK: - Nested Types

extension AppConfigurationStoreTests {

    /// `Info.plist` 字串正規化的固定測試案例
    enum Scenario: CaseIterable, Sendable {

        /// 前後空白應移除
        case trimsAPIKey

        /// 缺少的 `key` 應回傳 nil
        case returnsNilForMissingKey

        /// 空字串與全空白值都應回傳 nil
        case returnsNilForEmptyAndWhitespace

        /// 未展開的同名佔位字串應回傳 nil
        case returnsNilForUnexpandedPlaceholder

        /// 與 `key` 不同的佔位字串應保留
        case preservesDifferentPlaceholder

        /// 沒有佔位字串的一般值仍應移除前後空白
        case trimsLiteralWithoutPlaceholder

        /// 提供測試案例的原始 `Info.plist` 值
        var infoDictionary: [String: Any] {
            switch self {
            case .trimsAPIKey:
                ["OLLAMA_API_KEY": "  abc123  "]

            case .returnsNilForMissingKey:
                [:]

            case .returnsNilForEmptyAndWhitespace:
                [
                    "EMPTY_API_KEY": "",
                    "WHITESPACE_API_KEY": "   \n ",
                ]

            case .returnsNilForUnexpandedPlaceholder:
                ["OLLAMA_API_KEY": "$(OLLAMA_API_KEY)"]

            case .preservesDifferentPlaceholder:
                ["EXCHANGE_RATE_API_KEY": "$(OLLAMA_API_KEY)"]

            case .trimsLiteralWithoutPlaceholder:
                ["ENDPOINT": "  http://localhost:4000/api  "]
            }
        }

        /// 提供本案例要查詢的 `key`
        var keys: [String] {
            switch self {
            case .trimsAPIKey, .returnsNilForMissingKey, .returnsNilForUnexpandedPlaceholder:
                ["OLLAMA_API_KEY"]

            case .returnsNilForEmptyAndWhitespace:
                ["EMPTY_API_KEY", "WHITESPACE_API_KEY"]

            case .preservesDifferentPlaceholder:
                ["EXCHANGE_RATE_API_KEY"]

            case .trimsLiteralWithoutPlaceholder:
                ["ENDPOINT"]
            }
        }

        /// 提供本案例的字面預期值
        var expectedValues: [String?] {
            switch self {
            case .trimsAPIKey:
                ["abc123"]

            case .returnsNilForMissingKey, .returnsNilForUnexpandedPlaceholder:
                [nil]

            case .returnsNilForEmptyAndWhitespace:
                [nil, nil]

            case .preservesDifferentPlaceholder:
                ["$(OLLAMA_API_KEY)"]

            case .trimsLiteralWithoutPlaceholder:
                ["http://localhost:4000/api"]
            }
        }
    }

    /// 建立並清除獨立的測試 `Bundle`
    private final class BundleFixture {

        /// 提供測試 `Info.plist` 的 `Bundle`
        let bundle: Bundle

        /// 測試 `Bundle` 的暫存目錄
        private let directoryURL: URL

        /// 建立包含指定 `Info.plist` 內容的 `Bundle`
        ///
        /// - Parameter infoDictionary: 要寫入測試 `Bundle` 的 plist 字典
        /// - Throws: 建立目錄、序列化 plist 或寫檔失敗時丟出底層錯誤；`Bundle` 無法載入時
        ///   由 `#require` 丟出測試斷言錯誤
        init(infoDictionary: [String: Any]) throws {
            let fixtureID = UUID().uuidString
            let directoryName = "BuyLedgerTests.AppConfigurationStoreTests.\(fixtureID).bundle"
            let directoryURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(directoryName, isDirectory: true)
            try FileManager.default.createDirectory(
                at: directoryURL,
                withIntermediateDirectories: true
            )
            var bundleInfo = infoDictionary
            bundleInfo["CFBundleIdentifier"] = "com.leoho.BuyLedgerTests.\(fixtureID)"
            bundleInfo["CFBundlePackageType"] = "BNDL"
            let data = try PropertyListSerialization.data(
                fromPropertyList: bundleInfo,
                format: .xml,
                options: 0
            )
            try data.write(to: directoryURL.appendingPathComponent("Info.plist"))

            self.bundle = try #require(Bundle(url: directoryURL))
            self.directoryURL = directoryURL
        }

        /// 清除測試建立的暫存目錄
        deinit {
            try? FileManager.default.removeItem(at: directoryURL) // 清理失敗可忽略，因為只影響暫存測試資料
        }
    }
}
