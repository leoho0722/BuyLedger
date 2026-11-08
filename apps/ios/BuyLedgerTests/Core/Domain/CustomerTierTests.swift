//
//  CustomerTierTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/11/8.
//

import Foundation
import Testing

@testable import BuyLedger

/// `CustomerTier` 的單元測試
struct CustomerTierTests {

    /// 驗證新客與常客使用既有本地化鍵，並依 App 語言顯示分級名稱
    ///
    /// - Parameter scenario: 分級、語言與字面值預期
    @Test(arguments: [
        TitleScenario(
            tier: .new,
            language: .english,
            expectedKey: "customers.list.label.new",
            expectedText: "New"
        ),
        TitleScenario(
            tier: .new,
            language: .traditionalChinese,
            expectedKey: "customers.list.label.new",
            expectedText: "新客"
        ),
        TitleScenario(
            tier: .regular,
            language: .english,
            expectedKey: "customers.list.label.returning",
            expectedText: "Returning"
        ),
        TitleScenario(
            tier: .regular,
            language: .traditionalChinese,
            expectedKey: "customers.list.label.returning",
            expectedText: "常客"
        ),
    ])
    func title_新客與常客_依語言提供本地化文字(scenario: TitleScenario) {
        // Given
        let tier = scenario.tier

        // When
        let title = tier.title

        // Then
        guard case .localized(let resource) = title else {
            Issue.record("新客與常客應提供本地化文字")
            return
        }
        #expect(resource.key == scenario.expectedKey)
        #expect(scenario.language.resolve(resource) == scenario.expectedText)
    }

    /// 驗證 VIP 分級使用原文文字，不將 VIP 當成本地化鍵
    @Test
    func title_貴賓分級_保留原文文字() {
        // Given
        let tier = CustomerTier.vip

        // When
        let title = tier.title

        // Then
        guard case .verbatim(let text) = title else {
            Issue.record("VIP 分級應提供原文文字")
            return
        }
        #expect(text == "VIP")
    }
}

// MARK: - Nested Types

extension CustomerTierTests {

    /// 分級顯示文字的測試案例
    struct TitleScenario: Sendable {

        /// 要顯示的客戶分級
        let tier: CustomerTier

        /// 解析分級文字的 App 語言
        let language: AppLanguage

        /// 預期的本地化鍵
        let expectedKey: String

        /// 指定語言下的完整預期文字
        let expectedText: String
    }
}
