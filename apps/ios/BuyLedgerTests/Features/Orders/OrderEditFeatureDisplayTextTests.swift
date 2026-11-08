//
//  OrderEditFeatureDisplayTextTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/11/6.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// `OrderEditFeature.State` 顯示文字的單元測試，守住數量、幣別標題與完整訂購時間
struct OrderEditFeatureDisplayTextTests {

    /// 驗證商品數量在中英文都保留原本標籤、空格與數字
    ///
    /// - Parameter testCase: 數量、語言與字面值預期文字
    @Test(arguments: [
        QuantityDisplayCase(quantity: 1, localeIdentifier: "zh-Hant-TW", expected: "數量 1"),
        QuantityDisplayCase(quantity: 3, localeIdentifier: "zh-Hant-TW", expected: "數量 3"),
        QuantityDisplayCase(quantity: 1, localeIdentifier: "en-US", expected: "Quantity 1"),
        QuantityDisplayCase(quantity: 3, localeIdentifier: "en-US", expected: "Quantity 3"),
    ])
    func itemQuantityDisplayText_語言與數量不同_保留標籤和數字(testCase: QuantityDisplayCase) {
        // Given
        let state = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        let locale = Locale(identifier: testCase.localeIdentifier)

        // When
        let resource = state.itemQuantityDisplayText(testCase.quantity)

        // Then
        #expect(resource.key == "orders.detail.label.quantity")
        #expect(AppLanguage.resolve(resource, locale: locale) == testCase.expected)
    }

    /// 驗證商品明細標題依語言翻譯，並原樣帶入草稿幣別與半形括號
    ///
    /// - Parameter testCase: 幣別、語言與字面值預期標題
    @Test(arguments: [
        ItemDetailsTitleCase(
            currency: .twd,
            localeIdentifier: "zh-Hant-TW",
            expected: "商品明細 (TWD)"
        ),
        ItemDetailsTitleCase(
            currency: CurrencyCode(rawValue: "USD"),
            localeIdentifier: "zh-Hant-TW",
            expected: "商品明細 (USD)"
        ),
        ItemDetailsTitleCase(
            currency: .twd,
            localeIdentifier: "en-US",
            expected: "Item Details (TWD)"
        ),
        ItemDetailsTitleCase(
            currency: CurrencyCode(rawValue: "USD"),
            localeIdentifier: "en-US",
            expected: "Item Details (USD)"
        ),
    ])
    func itemDetailsTitle_語言與草稿幣別不同_保留標題和幣別(testCase: ItemDetailsTitleCase) {
        // Given
        var state = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        state.draft.currency = testCase.currency
        let locale = Locale(identifier: testCase.localeIdentifier)

        // When
        let resource = state.itemDetailsTitle()

        // Then
        #expect(resource.key == "orders.edit.label.itemDetailsCurrency")
        #expect(AppLanguage.resolve(resource, locale: locale) == testCase.expected)
    }

    /// 驗證中英文訂購日期說明沿用注入的 UTC 加十四小時，並保留西曆及秒數
    ///
    /// - Parameter testCase: 語言與字面值預期日期說明
    /// - Throws: 無法建立測試時區時由 `#require` 丟出測試錯誤
    @Test(arguments: [
        OrderDateTimestampCase(
            localeIdentifier: "zh-Hant-TW",
            expected: "訂購日期：2026/04/30 14:00:37"
        ),
        OrderDateTimestampCase(
            localeIdentifier: "en-US",
            expected: "Order Date: 2026/04/30 14:00:37"
        ),
    ])
    func orderDateTimestampText_語言與注入時區不同_保留完整時間戳(testCase: OrderDateTimestampCase) throws {
        // Given
        var calendar = Calendar(identifier: .buddhist)
        calendar.timeZone = try #require(TimeZone(secondsFromGMT: 14 * 60 * 60))
        let state = OrderEditFeature.State(
            id: UUID(0),
            options: OrderEditOptions(calendar: calendar),
            currentDate: TestDependencies.fixedNow.addingTimeInterval(37)
        )
        let locale = Locale(identifier: testCase.localeIdentifier)

        // When
        let resource = state.orderDateTimestampText(locale: locale)

        // Then
        #expect(resource.key == "orders.edit.label.orderDateTimestamp")
        #expect(AppLanguage.resolve(resource, locale: locale) == testCase.expected)
    }
}

// MARK: - Nested Types

extension OrderEditFeatureDisplayTextTests {

    /// 商品數量顯示文字的輸入與預期結果
    struct QuantityDisplayCase: Sendable {

        /// 商品數量
        let quantity: Int

        /// 畫面套用的語言與地區
        let localeIdentifier: String

        /// 含標籤與數量的預期文字
        let expected: String
    }

    /// 商品明細標題的輸入與預期結果
    struct ItemDetailsTitleCase: Sendable {

        /// 草稿目前使用的幣別
        let currency: CurrencyCode

        /// 畫面套用的語言與地區
        let localeIdentifier: String

        /// 含標籤與幣別的預期標題
        let expected: String
    }

    /// 訂購日期說明的語言與預期結果
    struct OrderDateTimestampCase: Sendable {

        /// 畫面套用的語言與地區
        let localeIdentifier: String

        /// 含標籤與完整時間戳的預期文字
        let expected: String
    }
}
