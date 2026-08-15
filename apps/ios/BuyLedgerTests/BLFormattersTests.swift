//
//  BLFormattersTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/7/30.
//

import Foundation
import Testing
@testable import BuyLedger

/// 驗證 ``BLFormatters`` 的既有呈現結果
struct BLFormattersTests {
    
    // MARK: - Tests
    
    @Test func twdFormatsPositiveAmountAsTwdCurrency() {
        #expect(BLFormatters.twd(Decimal(1_234), locale: Self.locale) == "NT$1,234")
    }
    
    @Test func twdFormatsZeroAmountAsTwdCurrency() {
        #expect(BLFormatters.twd(Decimal(0), locale: Self.locale) == "NT$0")
    }
    
    @Test func twdFormatsNegativeAmountAsTwdCurrency() {
        #expect(BLFormatters.twd(Decimal(-567), locale: Self.locale) == "-NT$567")
    }
    
    @Test func twdFormatsLargeAmountAsTwdCurrency() {
        #expect(BLFormatters.twd(Decimal(12_345_678), locale: Self.locale) == "NT$12,345,678")
    }
    
    @Test func twdOptionalFormatsPresentAmountSameAsNonOptionalOverload() {
        let amount: Decimal? = 1_234
        #expect(BLFormatters.twd(amount, locale: Self.locale) == "NT$1,234")
    }
    
    @Test func twdOptionalFormatsNilAsEmDashPlaceholder() {
        let amount: Decimal? = nil
        #expect(BLFormatters.twd(amount, locale: Self.locale) == "—")
    }
    
    @Test func percentFormatsPositiveRatioWithOneFractionDigit() {
        let ratio = Decimal(string: "0.654", locale: Self.posixLocale) ?? 0
        #expect(BLFormatters.percent(ratio, locale: Self.locale) == "65.4%")
    }
    
    @Test func percentFormatsZeroRatioWithOneFractionDigit() {
        #expect(BLFormatters.percent(Decimal(0), locale: Self.locale) == "0.0%")
    }
    
    @Test func percentFormatsNegativeRatioWithOneFractionDigit() {
        let ratio = Decimal(string: "-0.123", locale: Self.posixLocale) ?? 0
        #expect(BLFormatters.percent(ratio, locale: Self.locale) == "-12.3%")
    }
    
    @Test func percentFormatsLargeRatioAboveOneHundredPercent() {
        let ratio = Decimal(string: "12.5", locale: Self.posixLocale) ?? 0
        #expect(BLFormatters.percent(ratio, locale: Self.locale) == "1,250.0%")
    }
    
    @Test func percentScaledFormatsPositiveValueWithOneFractionDigit() {
        let value = Decimal(string: "65.4", locale: Self.posixLocale) ?? 0
        #expect(BLFormatters.percent(scaled: value, locale: Self.locale) == "65.4%")
    }
    
    @Test func percentScaledFormatsZeroValueWithOneFractionDigit() {
        #expect(BLFormatters.percent(scaled: Decimal(0), locale: Self.locale) == "0.0%")
    }
    
    @Test func percentScaledFormatsNegativeValueWithOneFractionDigit() {
        let value = Decimal(string: "-12.3", locale: Self.posixLocale) ?? 0
        #expect(BLFormatters.percent(scaled: value, locale: Self.locale) == "-12.3%")
    }
    
    @Test func percentScaledFormatsLargeValueWithOneFractionDigit() {
        let value = Decimal(string: "999.9", locale: Self.posixLocale) ?? 0
        #expect(BLFormatters.percent(scaled: value, locale: Self.locale) == "999.9%")
    }
    
    /// 驗證畫面格式化器委派共用金額格式化器
    @Test func orderAndCampaignFormattersTwdDelegateToBLFormatters() {
        #expect(OrderFormatters.twd(Decimal(1_234), locale: Self.locale) == "NT$1,234")
        #expect(CampaignFormatters.twd(Decimal(1_234), locale: Self.locale) == "NT$1,234")
    }
    
    /// 驗證畫面格式化器委派共用金額格式化器
    @Test func orderFormattersPercentDelegatesToBLFormatters() {
        let ratio = Decimal(string: "0.654", locale: Self.posixLocale) ?? 0
        #expect(OrderFormatters.percent(ratio, locale: Self.locale) == "65.4%")
    }
}

// MARK: - Static Properties

private extension BLFormattersTests {
    
    /// 測試固定使用的呈現 locale，與 ``OrderCalculationTests`` 既有慣例一致
    static let locale = Locale(identifier: "en")
    
    /// 解析字面值 `Decimal` 用的固定 locale，避免十進位字串解析受執行環境影響
    static let posixLocale = Locale(identifier: "en_US_POSIX")
}
