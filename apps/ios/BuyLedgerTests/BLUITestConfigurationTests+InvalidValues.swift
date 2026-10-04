//
//  BLUITestConfigurationTests+InvalidValues.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/3.
//

import Foundation
import Testing

@testable import BuyLedger

#if DEBUG

extension BLUITestConfigurationTests {

    /// 無法辨識的種子情境會退回空資料並保留測試啟用狀態
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

    /// 無法解析的參考時間會退回固定預設時間
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

    /// 無法辨識的語言、行事曆權限與載入失敗情境會保留預設值
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

    /// 重複指定種子旗標時採用最後一次的值
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

    /// 非整數的月目標不會覆寫預設設定
    @Test
    func init_月目標不是整數_忽略覆寫() {
        // Given
        let arguments = ["-BLUITestMonthlyGoal", "abc"]

        // When
        let configuration = BLUITestConfiguration(arguments: arguments)

        // Then
        #expect(configuration.monthlyProfitGoalTWD == nil)
    }

    /// 月目標拒絕負數並保留零值
    ///
    /// - Parameters:
    ///   - rawGoal: 負數或零值的月目標
    ///   - expectedGoal: 負數時不覆寫，零值時保留零
    @Test(arguments: [("-5000", nil as Int?), ("0", 0)])
    func init_月目標為負數或零_依邊界保留覆寫(rawGoal: String, expectedGoal: Int?) {
        // Given
        let arguments = ["-BLUITestMonthlyGoal", rawGoal]

        // When
        let configuration = BLUITestConfiguration(arguments: arguments)

        // Then
        #expect(configuration.monthlyProfitGoalTWD == expectedGoal)
    }

    /// 非三碼英文字母的幣別代號不會覆寫預設設定
    ///
    /// - Parameter rawCode: 長度錯誤、含數字或空白的幣別代號
    @Test(arguments: ["JP", "TWDX", "TW1", ""])
    func init_幣別不是三碼英文字母_忽略覆寫(rawCode: String) {
        // Given
        let arguments = ["-BLUITestDefaultCurrency", rawCode]

        // When
        let configuration = BLUITestConfiguration(arguments: arguments)

        // Then
        #expect(configuration.defaultCurrencyCode == nil)
    }

    /// 種子旗標位於參數尾端時不越界並退回空資料
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

    /// 種子旗標後緊接語言旗標時視為缺值，語言仍能正常解析
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

    /// 非 UI 測試旗標也不可被吞成種子情境的值
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

#endif
