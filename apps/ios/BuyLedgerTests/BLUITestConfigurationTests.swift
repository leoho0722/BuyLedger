//
//  BLUITestConfigurationTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/7/24.
//

import Foundation
import Testing
@testable import BuyLedger

#if DEBUG
    
    /// 驗證 UI 測試啟動參數的解析規則
    struct BLUITestConfigurationTests {
        
        // MARK: - Tests
        
        @Test func emptyArgumentsProduceDisabledConfigurationWithDefaults() {
            let configuration = BLUITestConfiguration(arguments: [])
            
            #expect(configuration.isEnabled == false)
            #expect(configuration.seedProfile == .empty)
            #expect(configuration.referenceDate == BLUITestConfiguration.defaultReferenceDate)
            #expect(configuration.language == nil)
            #expect(configuration.calendarAccess == .granted)
            #expect(configuration.loadFailure == BLUITestLoadFailure.none)
            #expect(configuration.defaultCurrencyCode == nil)
            #expect(configuration.monthlyProfitGoalTwd == nil)
        }
        
        @Test func uiTestFlagEnablesConfiguration() {
            let configuration = BLUITestConfiguration(arguments: ["/path/to/App", "-BLUITest"])
            
            #expect(configuration.isEnabled)
        }
        
        @Test func defaultReferenceDateIsEndOfApril2026InUTC() {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime]
            
            #expect(
                BLUITestConfiguration.defaultReferenceDate
                    == formatter.date(from: "2026-04-30T00:00:00Z"))
        }
        
        @Test func allFlagsAreParsedFromWellFormedArguments() {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime]
            let configuration = BLUITestConfiguration(arguments: [
                "-BLUITest",
                "-BLUITestSeed", "campaignsWithOrders",
                "-BLUITestNow", "2026-01-15T08:30:00Z",
                "-BLUITestLanguage", "english",
                "-BLUITestCalendarAccess", "denied",
                "-BLUITestLoadFailure", "ordersFirstReadOnly",
                "-BLUITestDefaultCurrency", "JPY",
                "-BLUITestMonthlyGoal", "80000",
            ])
            
            #expect(configuration.isEnabled)
            #expect(configuration.seedProfile == .campaignsWithOrders)
            #expect(configuration.referenceDate == formatter.date(from: "2026-01-15T08:30:00Z"))
            #expect(configuration.language == .english)
            #expect(configuration.calendarAccess == .denied)
            #expect(configuration.loadFailure == .ordersFirstReadOnly)
            #expect(configuration.defaultCurrencyCode == "JPY")
            #expect(configuration.monthlyProfitGoalTwd == 80_000)
        }
        
        @Test func referenceDateAcceptsFractionalSeconds() {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            let configuration = BLUITestConfiguration(arguments: [
                "-BLUITestNow", "2026-01-15T08:30:00.250Z",
            ])
            
            #expect(configuration.referenceDate == formatter.date(from: "2026-01-15T08:30:00.250Z"))
        }
        
        @Test func unknownSeedProfileFallsBackToEmpty() {
            let configuration = BLUITestConfiguration(arguments: [
                "-BLUITest", "-BLUITestSeed", "notAProfile",
            ])
            
            #expect(configuration.seedProfile == .empty)
            #expect(configuration.isEnabled)
        }
        
        @Test func unparsableReferenceDateFallsBackToDefault() {
            let configuration = BLUITestConfiguration(arguments: ["-BLUITestNow", "yesterday"])
            
            #expect(configuration.referenceDate == BLUITestConfiguration.defaultReferenceDate)
        }
        
        @Test func unknownLanguageAndCalendarAccessFallBackToDefaults() {
            let configuration = BLUITestConfiguration(arguments: [
                "-BLUITestLanguage", "klingon",
                "-BLUITestCalendarAccess", "maybe",
                "-BLUITestLoadFailure", "everything",
            ])
            
            #expect(configuration.language == nil)
            #expect(configuration.calendarAccess == .granted)
            #expect(configuration.loadFailure == BLUITestLoadFailure.none)
        }
        
        @Test func explicitNoneLoadFailureIsParsed() {
            // 確認 `none` 不會被當成未提供值。
            let configuration = BLUITestConfiguration(arguments: ["-BLUITestLoadFailure", "none"])
            
            #expect(configuration.loadFailure == BLUITestLoadFailure.none)
        }
        
        @Test func referenceDateAcceptsDateOnlyValueAsMidnightUTC() {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime]
            let configuration = BLUITestConfiguration(arguments: ["-BLUITestNow", "2026-01-15"])
            
            #expect(configuration.referenceDate == formatter.date(from: "2026-01-15T00:00:00Z"))
        }
        
        @Test func duplicatedFlagUsesLastValue() {
            let configuration = BLUITestConfiguration(arguments: [
                "-BLUITestSeed", "empty",
                "-BLUITestSeed", "campaignsWithOrders",
            ])
            
            #expect(configuration.seedProfile == .campaignsWithOrders)
        }
        
        @Test func nonIntegerMonthlyGoalFallsBackToNil() {
            let configuration = BLUITestConfiguration(arguments: ["-BLUITestMonthlyGoal", "abc"])
            
            #expect(configuration.monthlyProfitGoalTwd == nil)
        }
        
        @Test func negativeMonthlyGoalIsRejectedButZeroIsKept() {
            let negative = BLUITestConfiguration(arguments: ["-BLUITestMonthlyGoal", "-5000"])
            let zero = BLUITestConfiguration(arguments: ["-BLUITestMonthlyGoal", "0"])
            
            #expect(negative.monthlyProfitGoalTwd == nil)
            #expect(zero.monthlyProfitGoalTwd == 0)
        }
        
        @Test func currencyCodeIsUppercasedAndTrimmed() {
            let lowercased = BLUITestConfiguration(arguments: ["-BLUITestDefaultCurrency", "twd"])
            let padded = BLUITestConfiguration(arguments: ["-BLUITestDefaultCurrency", " twd \n"])
            
            #expect(lowercased.defaultCurrencyCode == "TWD")
            #expect(padded.defaultCurrencyCode == "TWD")
        }
        
        @Test func currencyCodeIsRejectedWhenNotThreeAsciiLetters() {
            let tooShort = BLUITestConfiguration(arguments: ["-BLUITestDefaultCurrency", "JP"])
            let tooLong = BLUITestConfiguration(arguments: ["-BLUITestDefaultCurrency", "TWDX"])
            let withDigit = BLUITestConfiguration(arguments: ["-BLUITestDefaultCurrency", "TW1"])
            let empty = BLUITestConfiguration(arguments: ["-BLUITestDefaultCurrency", ""])
            
            #expect(tooShort.defaultCurrencyCode == nil)
            #expect(tooLong.defaultCurrencyCode == nil)
            #expect(withDigit.defaultCurrencyCode == nil)
            #expect(empty.defaultCurrencyCode == nil)
        }
        
        @Test func trailingFlagWithoutValueDoesNotCrash() {
            // 旗標是陣列最後一個元素，取值時不可越界
            let configuration = BLUITestConfiguration(arguments: ["-BLUITest", "-BLUITestSeed"])
            
            #expect(configuration.isEnabled)
            #expect(configuration.seedProfile == .empty)
        }
        
        @Test func flagFollowedByAnotherFlagIsTreatedAsMissingValue() {
            let configuration = BLUITestConfiguration(arguments: [
                "-BLUITestSeed",
                "-BLUITestLanguage", "english",
            ])
            
            #expect(configuration.seedProfile == .empty)
            #expect(configuration.language == .english)
        }
        
        @Test func flagFollowedByForeignFlagIsTreatedAsMissingValue() {
            // 非 BLUITest 的旗標 (如 `-AppleLanguages`) 也不可被當成值吞掉
            let configuration = BLUITestConfiguration(arguments: [
                "-BLUITestSeed",
                "-AppleLanguages", "(en)",
            ])
            
            #expect(configuration.seedProfile == .empty)
        }
    }
    
#endif
