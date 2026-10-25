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
