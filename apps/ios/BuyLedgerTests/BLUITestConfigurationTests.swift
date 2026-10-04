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

    /// 開團寫入失敗旗標可開啟開團的寫入替身
    @Test
    func init_帶開團寫入失敗旗標_啟用寫入失敗() {
        // Given
        let arguments = ["-BLUITest", "-BLUITestCampaignWriteFailure"]

        // When
        let configuration = BLUITestConfiguration(arguments: arguments)

        // Then
        #expect(configuration.shouldFailCampaignWrites == true)
    }

    /// 未提供開團寫入失敗旗標時保留正常寫入
    @Test
    func init_未帶開團寫入失敗旗標_不啟用寫入失敗() {
        // Given
        let arguments = ["-BLUITest"]

        // When
        let configuration = BLUITestConfiguration(arguments: arguments)

        // Then
        #expect(configuration.shouldFailCampaignWrites == false)
    }

    /// 空的啟動參數會停用 UI 測試並保留所有預設值
    @Test
    func init_空啟動參數_停用測試並保留預設值() {
        // Given
        let arguments: [String] = []
        let expectedReferenceDate = Date(timeIntervalSince1970: 1_777_507_200)

        // When
        let configuration = BLUITestConfiguration(arguments: arguments)

        // Then
        #expect(configuration.isEnabled == false)
        #expect(configuration.seedProfile == .empty)
        #expect(configuration.referenceDate == expectedReferenceDate)
        #expect(configuration.language == nil)
        #expect(configuration.calendarAccess == .granted)
        #expect(configuration.loadFailure == BLUITestLoadFailure.none)
        #expect(configuration.shouldFailLookupWrites == false)
        #expect(configuration.shouldFailCampaignWrites == false)
        #expect(configuration.defaultCurrencyCode == nil)
        #expect(configuration.monthlyProfitGoalTWD == nil)
        #expect(configuration.shouldUseAISummary == false)
        #expect(configuration.isAppLockEnabled == false)
        #expect(configuration.biometricScenario == .success)
        #expect(configuration.persistenceMode == .inMemory)
        #expect(configuration.shouldResetPersistentStore == false)
    }

    /// UI 測試旗標會啟用啟動掛鉤
    @Test
    func init_帶測試旗標_啟用測試設定() {
        // Given
        let arguments = ["/path/to/App", "-BLUITest"]

        // When
        let configuration = BLUITestConfiguration(arguments: arguments)

        // Then
        #expect(configuration.isEnabled)
    }

    /// 預設參考時間固定為 2026 年 4 月 30 日 UTC 午夜
    @Test
    func defaultReferenceDate_未提供時間覆寫_為四月底午夜() {
        // Given
        let expectedReferenceDate = Date(timeIntervalSince1970: 1_777_507_200)

        // When
        let referenceDate = BLUITestConfiguration.defaultReferenceDate

        // Then
        #expect(referenceDate == expectedReferenceDate)
    }

    /// 有效的啟動參數會套用種子、時間、語言與各項覆寫設定
    @Test
    func init_提供有效旗標值_解析全部設定() {
        // Given
        let arguments = [
            "-BLUITest",
            "-BLUITestSeed",
            "campaignsWithOrders",
            "-BLUITestNow",
            "2026-01-15T08:30:00Z",
            "-BLUITestLanguage",
            "english",
            "-BLUITestCalendarAccess",
            "denied",
            "-BLUITestLoadFailure",
            "ordersFirstReadOnly",
            "-BLUITestLookupWriteFailure",
            "-BLUITestDefaultCurrency",
            "JPY",
            "-BLUITestMonthlyGoal",
            "80000",
        ]
        let expectedReferenceDate = Date(timeIntervalSince1970: 1_768_465_800)

        // When
        let configuration = BLUITestConfiguration(arguments: arguments)

        // Then
        #expect(configuration.isEnabled)
        #expect(configuration.seedProfile == .campaignsWithOrders)
        #expect(configuration.referenceDate == expectedReferenceDate)
        #expect(configuration.language == .english)
        #expect(configuration.calendarAccess == .denied)
        #expect(configuration.loadFailure == .ordersFirstReadOnly)
        #expect(configuration.shouldFailLookupWrites)
        #expect(configuration.defaultCurrencyCode == "JPY")
        #expect(configuration.monthlyProfitGoalTWD == 80_000)
    }

    /// 參考時間可接受含小數秒的 ISO8601 時間
    @Test
    func init_參考時間含小數秒_保留小數秒() {
        // Given
        let arguments = ["-BLUITestNow", "2026-01-15T08:30:00.250Z"]
        let expectedReferenceDate = Date(timeIntervalSince1970: 1_768_465_800.25)

        // When
        let configuration = BLUITestConfiguration(arguments: arguments)

        // Then
        #expect(configuration.referenceDate == expectedReferenceDate)
    }

    /// 明確指定不模擬載入失敗時保留正常讀取
    @Test
    func init_明確指定無載入失敗_保留正常讀取() {
        // Given
        let arguments = ["-BLUITestLoadFailure", "none"]

        // When
        let configuration = BLUITestConfiguration(arguments: arguments)

        // Then
        #expect(configuration.loadFailure == BLUITestLoadFailure.none)
    }

    /// 只有日期的參考時間會解析成 UTC 午夜
    @Test
    func init_參考時間只有日期_解析為午夜() {
        // Given
        let arguments = ["-BLUITestNow", "2026-01-15"]
        let expectedReferenceDate = Date(timeIntervalSince1970: 1_768_435_200)

        // When
        let configuration = BLUITestConfiguration(arguments: arguments)

        // Then
        #expect(configuration.referenceDate == expectedReferenceDate)
    }

    /// 幣別代號會去除前後空白並轉成大寫
    ///
    /// - Parameter rawCode: 小寫或帶空白的幣別代號
    @Test(arguments: ["twd", " twd \n"])
    func init_幣別小寫或含空白_正規化為大寫(rawCode: String) {
        // Given
        let arguments = ["-BLUITestDefaultCurrency", rawCode]

        // When
        let configuration = BLUITestConfiguration(arguments: arguments)

        // Then
        #expect(configuration.defaultCurrencyCode == "TWD")
    }

    /// 主檔寫入失敗旗標可開啟四種主檔的寫入替身
    @Test
    func init_帶主檔寫入失敗旗標_啟用寫入失敗() {
        // Given
        let arguments = ["-BLUITestLookupWriteFailure"]

        // When
        let configuration = BLUITestConfiguration(arguments: arguments)

        // Then
        #expect(configuration.shouldFailLookupWrites)
    }
}

#endif
