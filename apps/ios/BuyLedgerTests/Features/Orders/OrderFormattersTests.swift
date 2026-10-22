//
//  OrderFormattersTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import Foundation
import Testing

@testable import BuyLedger

/// 驗證訂單畫面的金額正負號、類別文字與朗讀用收款損益格式
struct OrderFormattersTests {

    // MARK: - Properties

    /// 測試固定使用的呈現 locale，與 `BLFormattersTests` 既有慣例一致
    private static let locale = Locale(identifier: "en")

    /// 正數金額前面加上 `+`，符號與金額之間沒有空格
    @Test
    func signedTWD_正數金額_前面加上加號() {
        // Given
        let amount = Decimal(1_234)

        // When
        let text = OrderFormatters.signedTWD(amount, locale: Self.locale)

        // Then
        #expect(text == "+NT$1,234")
    }

    /// 零也屬於非負數，前面加上 `+`
    @Test
    func signedTWD_零_前面加上加號() {
        // Given
        let amount = Decimal(0)

        // When
        let text = OrderFormatters.signedTWD(amount, locale: Self.locale)

        // Then
        #expect(text == "+NT$0")
    }

    /// 負數金額保留金額本身的負號，不另外加上 `+`
    @Test
    func signedTWD_負數金額_保留負號() {
        // Given
        let amount = Decimal(-567)

        // When
        let text = OrderFormatters.signedTWD(amount, locale: Self.locale)

        // Then
        #expect(text == "-NT$567")
    }

    /// 減號格式不論金額多寡，前面一律加上 `-`
    @Test
    func minusTWD_正數金額_前面加上減號() {
        // Given
        let amount = Decimal(567)

        // When
        let text = OrderFormatters.minusTWD(amount, locale: Self.locale)

        // Then
        #expect(text == "-NT$567")
    }

    /// 加號格式不論金額多寡，前面一律加上 `+`
    @Test
    func plusTWD_正數金額_前面加上加號() {
        // Given
        let amount = Decimal(567)

        // When
        let text = OrderFormatters.plusTWD(amount, locale: Self.locale)

        // Then
        #expect(text == "+NT$567")
    }

    /// 多個類別依原順序以頓號連接
    @Test
    func categoriesTagText_多個類別_以頓號連接() {
        // Given
        let categories = ["服飾", "美妝"]

        // When
        let text = OrderFormatters.categoriesTagText(for: categories)

        // Then
        #expect(text == "服飾、美妝")
    }

    /// 空白與空字串項目不顯示，有效項目前後的空白會被修剪
    @Test
    func categoriesTagText_含空白與空字串_略過無效項目() {
        // Given
        let categories = [" 服飾 ", "", "   ", "美妝"]

        // When
        let text = OrderFormatters.categoriesTagText(for: categories)

        // Then
        #expect(text == "服飾、美妝")
    }

    /// 沒有類別時回傳空字串，讓列不顯示 tag
    @Test
    func categoriesTagText_沒有類別_回傳空字串() {
        // Given
        let categories: [String] = []

        // When
        let text = OrderFormatters.categoriesTagText(for: categories)

        // Then
        #expect(text == "")
    }

    /// 正數獲利的收款與獲利以空格分隔，獲利前面加上 `+`
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

    /// 負數獲利保留金額本身的負號，不另外加上 `+`
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

    /// 零獲利屬於非負數，前面加上 `+`
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
