//
//  OrderFormattersTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import Foundation
import Testing

@testable import BuyLedger

/// `OrderFormatters` 的單元測試，涵蓋金額正負號、類別文字與朗讀用的收款損益格式
struct OrderFormattersTests {

    // MARK: - Properties

    /// 測試固定使用的英文呈現 locale，與 `BLFormattersTests` 既有慣例一致
    private static let locale = Locale(identifier: "en")

    /// 驗證手續費輸入 resource 依 App 語言呈現數字與百分比
    ///
    /// - Parameter scenario: 測試語言與預期說明
    @Test(arguments: [
        FeeInputMessageCase(
            language: .traditionalChinese,
            expected: "輸入百分比例如 1.5 表示 1.5%；超出 0% ~ 100% 範圍會自動限制。"
        ),
        FeeInputMessageCase(
            language: .english,
            expected: "Enter 1.5 for 1.5%. Values outside 0% ~ 100% are automatically limited."
        ),
    ])
    func feeRateInputMessage_各語言_顯示相符說明(scenario: FeeInputMessageCase) {
        // Given
        let locale = scenario.language.locale

        // When
        let message = OrderFormatters.feeRateInputMessage(locale: locale)
        let value = AppLanguage.resolve(message, locale: locale)

        // Then
        #expect(message.key == "orders.edit.message.feeRateInputNotice")
        #expect(value == scenario.expected)
    }

    /// 驗證付款方式標題保留使用者名稱並依 App 語言解析
    ///
    /// - Parameter testCase: 付款方式、App 語言與標題預期
    @Test(arguments: [
        PaymentMethodFilterTitleCase(
            paymentMethod: nil,
            language: .traditionalChinese,
            expected: "付款方式：全部"
        ),
        PaymentMethodFilterTitleCase(
            paymentMethod: nil,
            language: .english,
            expected: "Payment Method: All"
        ),
        PaymentMethodFilterTitleCase(
            paymentMethod: "common.action.label.all",
            language: .english,
            expected: "Payment Method: common.action.label.all"
        ),
    ])
    func paymentMethodFilterTitle_付款方式名稱等於Key_保留原文(testCase: PaymentMethodFilterTitleCase) {
        // Given
        let paymentMethod = testCase.paymentMethod

        // When
        let title = OrderFormatters.paymentMethodFilterTitle(
            paymentMethod,
            locale: testCase.language.locale
        )
        let value = testCase.language.resolve(title)

        // Then
        #expect(title.key == "orders.filter.label.paymentMethodFormat")
        #expect(value == testCase.expected)
    }

    /// 驗證正數金額前面加上加號，符號與金額之間沒有空格
    @Test
    func signedTWD_正數金額_前面加上加號() {
        // Given
        let amount = Decimal(1_234)

        // When
        let text = OrderFormatters.signedTWD(amount, locale: Self.locale)

        // Then
        #expect(text == "+NT$1,234")
    }

    /// 驗證零金額也屬於非負數，前面加上加號
    @Test
    func signedTWD_零_前面加上加號() {
        // Given
        let amount = Decimal(0)

        // When
        let text = OrderFormatters.signedTWD(amount, locale: Self.locale)

        // Then
        #expect(text == "+NT$0")
    }

    /// 驗證負數金額保留本身的負號，不另外加上加號
    @Test
    func signedTWD_負數金額_保留負號() {
        // Given
        let amount = Decimal(-567)

        // When
        let text = OrderFormatters.signedTWD(amount, locale: Self.locale)

        // Then
        #expect(text == "-NT$567")
    }

    /// 驗證減號格式不論金額多寡，正數金額前面也加上減號
    @Test
    func minusTWD_正數金額_前面加上減號() {
        // Given
        let amount = Decimal(567)

        // When
        let text = OrderFormatters.minusTWD(amount, locale: Self.locale)

        // Then
        #expect(text == "-NT$567")
    }

    /// 驗證加號格式不論金額多寡，正數金額前面也加上加號
    @Test
    func plusTWD_正數金額_前面加上加號() {
        // Given
        let amount = Decimal(567)

        // When
        let text = OrderFormatters.plusTWD(amount, locale: Self.locale)

        // Then
        #expect(text == "+NT$567")
    }

    /// 驗證多個類別依原順序以頓號連接成一段文字
    @Test
    func categoriesTagText_多個類別_以頓號連接() {
        // Given
        let categories = ["服飾", "美妝"]

        // When
        let text = OrderFormatters.categoriesTagText(for: categories)

        // Then
        #expect(text == "服飾、美妝")
    }

    /// 驗證空白與空字串的類別不顯示，有效類別前後的空白會先被修剪再連接
    @Test
    func categoriesTagText_含空白與空字串_略過無效項目() {
        // Given
        let categories = [" 服飾 ", "", "   ", "美妝"]

        // When
        let text = OrderFormatters.categoriesTagText(for: categories)

        // Then
        #expect(text == "服飾、美妝")
    }

    /// 驗證沒有類別時回傳空字串 (畫面依此決定是否顯示類別標籤)
    @Test
    func categoriesTagText_沒有類別_回傳空字串() {
        // Given
        let categories: [String] = []

        // When
        let text = OrderFormatters.categoriesTagText(for: categories)

        // Then
        #expect(text == "")
    }

    /// 驗證正數獲利時，收款與獲利以空格分隔，獲利前面加上加號
    @Test
    func revenueAndProfitText_正數獲利_收款與加號獲利以空格連接() {
        // Given
        let revenue = Decimal(1_000)
        let profit = Decimal(200)

        // When
        let text = OrderFormatters.revenueAndProfitText(
            revenue: revenue,
            profit: profit,
            locale: Self.locale
        )

        // Then
        #expect(text == "NT$1,000 +NT$200")
    }

    /// 驗證負數獲利保留本身的負號，不另外加上加號，收款與獲利仍以空格分隔
    @Test
    func revenueAndProfitText_負數獲利_保留負號() {
        // Given
        let revenue = Decimal(1_000)
        let profit = Decimal(-567)

        // When
        let text = OrderFormatters.revenueAndProfitText(
            revenue: revenue,
            profit: profit,
            locale: Self.locale
        )

        // Then
        #expect(text == "NT$1,000 -NT$567")
    }

    /// 驗證零獲利屬於非負數，前面加上加號
    @Test
    func revenueAndProfitText_零獲利_前面加上加號() {
        // Given
        let revenue = Decimal(500)
        let profit = Decimal(0)

        // When
        let text = OrderFormatters.revenueAndProfitText(
            revenue: revenue,
            profit: profit,
            locale: Self.locale
        )

        // Then
        #expect(text == "NT$500 +NT$0")
    }
}

// MARK: - Nested Types

extension OrderFormattersTests {

    /// 付款方式篩選標題的語言與固定文字案例
    struct PaymentMethodFilterTitleCase: Sendable {

        /// 要顯示的付款方式名稱；`nil` 代表全部
        let paymentMethod: String?

        /// 使用的 App 語言
        let language: AppLanguage

        /// 依語言解析後的固定文字
        let expected: String
    }

    /// 本地化說明測試使用的語言與預期字串
    struct FeeInputMessageCase: Sendable {

        /// 測試使用的 App 語言
        let language: AppLanguage

        /// 該語言的完整預期說明
        let expected: String
    }
}
