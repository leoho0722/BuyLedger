//
//  BLUITestConfigurationInvalidValuesTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/3.
//

import Foundation
import Testing

@testable import BuyLedger

#if DEBUG

/// `BLUITestConfiguration` 的單元測試，涵蓋啟動參數值無效或缺漏時退回預設設定
struct BLUITestConfigurationInvalidValuesTests {

    /// 驗證種子情境無法辨識時退回空資料，且測試仍維持啟用
    @Test
    func init_種子情境無法辨識_退回空資料() {
        // Given
        let arguments = ["-BLUITest", "-BLUITestSeed", "notAProfile"]

        // When
        let configuration = BLUITestConfiguration(arguments: arguments)

        // Then
        #expect(configuration.seedProfile == .empty)
        #expect(configuration.isEnabled)
    }

    /// 驗證參考時間無法解析時，退回 2026 年 4 月 30 日 UTC 午夜的預設時間
    @Test
    func init_參考時間無法解析_退回預設時間() {
        // Given
        let arguments = ["-BLUITestNow", "yesterday"]
        let expectedReferenceDate = Date(timeIntervalSince1970: 1_777_507_200)

        // When
        let configuration = BLUITestConfiguration(arguments: arguments)

        // Then
        #expect(configuration.referenceDate == expectedReferenceDate)
    }

    /// 驗證語言、行事曆權限與載入失敗的旗標值都無法辨識時，三者各自退回預設值
    @Test
    func init_列舉旗標值無法辨識_退回預設設定() {
        // Given
        let arguments = [
            "-BLUITestLanguage",
            "klingon",
            "-BLUITestCalendarAccess",
            "maybe",
            "-BLUITestLoadFailure",
            "everything",
        ]

        // When
        let configuration = BLUITestConfiguration(arguments: arguments)

        // Then
        #expect(configuration.language == nil)
        #expect(configuration.calendarAccess == .granted)
        #expect(configuration.loadFailure == BLUITestLoadFailure.none)
    }

    /// 驗證種子旗標重複出現時，採用最後一次指定的情境
    @Test
    func init_重複種子旗標_採用最後值() {
        // Given
        let arguments = [
            "-BLUITestSeed",
            "empty",
            "-BLUITestSeed",
            "campaignsWithOrders",
        ]

        // When
        let configuration = BLUITestConfiguration(arguments: arguments)

        // Then
        #expect(configuration.seedProfile == .campaignsWithOrders)
    }

    /// 驗證月目標不是整數時忽略覆寫，月目標維持未設定 (`nil`)
    @Test
    func init_月目標不是整數_忽略覆寫() {
        // Given
        let arguments = ["-BLUITestMonthlyGoal", "abc"]

        // When
        let configuration = BLUITestConfiguration(arguments: arguments)

        // Then
        #expect(configuration.monthlyProfitGoalTWD == nil)
    }

    /// 驗證月目標為負數時忽略覆寫，為零時保留 0 作為覆寫值
    ///
    /// - Parameter scenario: 傳入的原始字串與預期的月目標覆寫結果
    @Test(arguments: [
        MonthlyGoalCase(rawGoal: "-5000", expectedGoal: nil),
        MonthlyGoalCase(rawGoal: "0", expectedGoal: 0),
    ])
    func init_月目標為負數或零_依邊界保留覆寫(scenario: MonthlyGoalCase) {
        // Given
        let arguments = ["-BLUITestMonthlyGoal", scenario.rawGoal]

        // When
        let configuration = BLUITestConfiguration(arguments: arguments)

        // Then
        #expect(configuration.monthlyProfitGoalTWD == scenario.expectedGoal)
    }

    /// 驗證幣別代號不是三碼英文字母時忽略覆寫，預設幣別維持未設定 (`nil`)
    ///
    /// - Parameter rawCode: 長度不是三碼、含數字或為空的幣別代號
    @Test(arguments: ["JP", "TWDX", "TW1", ""])
    func init_幣別不是三碼英文字母_忽略覆寫(rawCode: String) {
        // Given
        let arguments = ["-BLUITestDefaultCurrency", rawCode]

        // When
        let configuration = BLUITestConfiguration(arguments: arguments)

        // Then
        #expect(configuration.defaultCurrencyCode == nil)
    }

    /// 驗證種子旗標位於參數尾端、後面沒有值時不越界，退回空資料並保留測試啟用
    @Test
    func init_尾端旗標缺值_退回空資料() {
        // Given
        let arguments = ["-BLUITest", "-BLUITestSeed"]

        // When
        let configuration = BLUITestConfiguration(arguments: arguments)

        // Then
        #expect(configuration.isEnabled)
        #expect(configuration.seedProfile == .empty)
    }

    /// 驗證種子旗標後緊接語言旗標時，種子退回空資料，語言旗標仍解析為英文
    @Test
    func init_種子後接語言旗標_退回空資料並解析語言() {
        // Given
        let arguments = ["-BLUITestSeed", "-BLUITestLanguage", "english"]

        // When
        let configuration = BLUITestConfiguration(arguments: arguments)

        // Then
        #expect(configuration.seedProfile == .empty)
        #expect(configuration.language == .english)
    }

    /// 驗證種子旗標後緊接外部旗標時，外部旗標不被當成種子值，種子退回空資料
    @Test
    func init_種子後接外部旗標_視為缺值() {
        // Given
        let arguments = ["-BLUITestSeed", "-AppleLanguages", "(en)"]

        // When
        let configuration = BLUITestConfiguration(arguments: arguments)

        // Then
        #expect(configuration.seedProfile == .empty)
    }
}

// MARK: - Nested Types

extension BLUITestConfigurationInvalidValuesTests {

    /// 月目標邊界測試的案例，含原始字串與預期的套用結果
    struct MonthlyGoalCase: Sendable {

        /// 傳進 `-BLUITestMonthlyGoal` 的原始字串
        let rawGoal: String

        /// 套用後的月目標，`nil` 代表不覆寫預設值
        let expectedGoal: Int?
    }
}

#endif
