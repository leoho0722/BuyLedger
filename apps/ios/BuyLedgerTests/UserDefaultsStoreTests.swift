//
//  UserDefaultsStoreTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/26.
//

import Foundation
import Testing

@testable import BuyLedger

/// 驗證偏好儲存的技術讀寫介面
struct UserDefaultsStoreTests {

    // MARK: - Tests

    /// 驗證字串、浮點數與布林值可透過 `UserDefaults` 往返
    ///
    /// - Parameter scenario: 要驗證的儲存型別與固定值
    /// - Throws: 建立隔離 suite 失敗時由 `#require` 丟出測試失敗
    @Test(arguments: Scenario.allCases)
    func set_字串數字布林值_讀回相同值(scenario: Scenario) throws {
        // Given
        let fixture = try SuiteFixture(suiteName: scenario.suiteName)
        let store = UserDefaultsStore(suiteName: fixture.suiteName)

        // When
        let actualValue: StoredValue
        switch scenario {
        case .string:
            store.set("en", forKey: scenario.key)
            actualValue = .string(store.string(forKey: scenario.key))

        case .double:
            store.set(120_000.5, forKey: scenario.key)
            actualValue = .double(store.double(forKey: scenario.key))

        case .bool:
            store.set(true, forKey: scenario.key)
            actualValue = .bool(store.bool(forKey: scenario.key))
        }

        // Then
        #expect(actualValue == scenario.expectedValue)
    }

    /// 驗證 `hasValue(forKey:)` 區分缺少的 `key` 與已儲存的值
    ///
    /// - Throws: 建立隔離 suite 或必要條件不符時由 `#require` 丟出測試失敗
    @Test
    func hasValue_同一索引鍵有值與缺值_正確區分() throws {
        // Given
        let fixture = try SuiteFixture(suiteName: "BuyLedgerTests.UserDefaultsStoreTests.hasValue")
        let store = UserDefaultsStore(suiteName: fixture.suiteName)
        try #require(!store.hasValue(forKey: "goal"))

        // When
        store.set(0.0, forKey: "goal")
        let hasStoredValue = store.hasValue(forKey: "goal")

        // Then
        #expect(hasStoredValue)
    }
}

// MARK: - Nested Types

extension UserDefaultsStoreTests {

    /// 偏好往返測試使用的型別案例
    enum Scenario: CaseIterable, Sendable {

        /// 字串偏好
        case string

        /// 浮點數偏好
        case double

        /// 布林值偏好
        case bool

        /// 提供本案例使用的隔離 suite 名稱
        var suiteName: String {
            switch self {
            case .string:
                "BuyLedgerTests.UserDefaultsStoreTests.string"

            case .double:
                "BuyLedgerTests.UserDefaultsStoreTests.double"

            case .bool:
                "BuyLedgerTests.UserDefaultsStoreTests.bool"
            }
        }

        /// 提供本案例使用的偏好 `key`
        var key: String {
            switch self {
            case .string:
                "language"

            case .double:
                "goal"

            case .bool:
                "enabled"
            }
        }

        /// 提供本案例的固定預期值
        var expectedValue: StoredValue {
            switch self {
            case .string:
                .string("en")

            case .double:
                .double(120_000.5)

            case .bool:
                .bool(true)
            }
        }
    }

    /// 比較測試讀回的偏好值
    enum StoredValue: Equatable, Sendable {

        /// 字串值
        ///
        /// - Parameter string: 讀回的字串
        case string(String?)

        /// 浮點數值
        ///
        /// - Parameter double: 讀回的浮點數
        case double(Double)

        /// 布林值
        ///
        /// - Parameter bool: 讀回的布林值
        case bool(Bool)
    }

    /// 建立並清除獨立的 `UserDefaults` suite
    private final class SuiteFixture {

        /// 要使用的 suite 名稱
        let suiteName: String

        /// 清除 suite 所需的 `UserDefaults`
        private let userDefaults: UserDefaults

        /// 建立並清空指定的 suite
        ///
        /// - Parameter suiteName: 隔離測試資料的名稱
        /// - Throws: suite 無法建立時由 `#require` 丟出測試失敗
        init(suiteName: String) throws {
            let userDefaults = try #require(UserDefaults(suiteName: suiteName))
            userDefaults.removePersistentDomain(forName: suiteName)
            self.suiteName = suiteName
            self.userDefaults = userDefaults
        }

        /// 清除測試建立的 suite
        deinit {
            userDefaults.removePersistentDomain(forName: suiteName)
        }
    }
}
