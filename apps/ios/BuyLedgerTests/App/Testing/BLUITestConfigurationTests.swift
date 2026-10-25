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

/// `BLUITestConfiguration` 的單元測試，涵蓋 UI 測試啟動參數的解析
struct BLUITestConfigurationTests {

    /// 驗證帶入開團寫入失敗旗標時，設定要求開團寫入失敗
    @Test
    func init_帶開團寫入失敗旗標_啟用寫入失敗() {
        // Given
        let arguments = ["-BLUITest", "-BLUITestCampaignWriteFailure"]

        // When
        let configuration = BLUITestConfiguration(arguments: arguments)

        // Then
        #expect(configuration.shouldFailCampaignWrites == true)
    }

    /// 驗證未帶開團寫入失敗旗標時，開團寫入維持正常、不設定失敗
    @Test
    func init_未帶開團寫入失敗旗標_不啟用寫入失敗() {
        // Given
        let arguments = ["-BLUITest"]

        // When
        let configuration = BLUITestConfiguration(arguments: arguments)

        // Then
        #expect(configuration.shouldFailCampaignWrites == false)
    }

    /// 驗證沒有任何啟動參數時，UI 測試停用，其餘設定皆為預設值
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

    /// 驗證啟動參數含執行檔路徑與 `-BLUITest` 時，啟用 UI 測試設定
    @Test
    func init_帶測試旗標_啟用測試設定() {
        // Given
        let arguments = ["/path/to/App", "-BLUITest"]

        // When
        let configuration = BLUITestConfiguration(arguments: arguments)

        // Then
        #expect(configuration.isEnabled)
    }

    /// 驗證未提供參考時間時，預設參考時間為 2026 年 4 月 30 日 UTC 午夜
    @Test
    func defaultReferenceDate_未提供時間覆寫_為四月底午夜() {
        // Given
        let expectedReferenceDate = Date(timeIntervalSince1970: 1_777_507_200)

        // When
        let referenceDate = BLUITestConfiguration.defaultReferenceDate

        // Then
        #expect(referenceDate == expectedReferenceDate)
    }

    /// 驗證提供全部有效旗標值時，種子、時間、語言與各項覆寫都套用
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

    /// 驗證 ISO8601 參考時間含小數秒時，解析結果保留小數秒
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

    /// 驗證明確指定不模擬載入失敗時，讀取維持正常
    @Test
    func init_明確指定無載入失敗_保留正常讀取() {
        // Given
        let arguments = ["-BLUITestLoadFailure", "none"]

        // When
        let configuration = BLUITestConfiguration(arguments: arguments)

        // Then
        #expect(configuration.loadFailure == BLUITestLoadFailure.none)
    }

    /// 驗證只有日期的參考時間解析為當日 UTC 午夜
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

    /// 驗證小寫或前後帶空白的幣別代號，會正規化為大寫的三碼代號
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

    /// 驗證帶入主檔寫入失敗旗標時，設定要求主檔寫入失敗
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
