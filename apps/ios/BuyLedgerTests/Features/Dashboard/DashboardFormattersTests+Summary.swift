//
//  DashboardFormattersTests+Summary.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/16.
//

import SwiftUI
import Testing

@testable import BuyLedger

extension DashboardFormattersTests {

    /// 少於兩個月的走勢無法比較首尾，回傳無資料的標題鍵
    @Test
    func sparklineSummary_不足兩點_顯示無資料的標題鍵() {
        // Given
        let points: [Double] = [100]
        let expected = LocalizedStringKey("dashboard.overview.label.monthlyProfitTrend")

        // When
        let text = DashboardFormatters.sparklineSummary(
            points,
            locale: AppLanguage.traditionalChinese.locale
        )

        // Then
        #expect(text == expected)
    }

    /// 末點高於首點時採用上升的敘述，並帶入點數、最低與最高獲利
    @Test
    func sparklineSummary_末點高於首點_顯示上升敘述() {
        // Given
        let points: [Double] = [100, 300]
        let expected = LocalizedStringKey("月獲利走勢圖，共 2 個月，整體上升，最低 $100，最高 $300")

        // When
        let text = DashboardFormatters.sparklineSummary(
            points,
            locale: AppLanguage.traditionalChinese.locale
        )

        // Then
        #expect(text == expected)
    }

    /// 末點低於首點時採用下降的英文敘述
    @Test
    func sparklineSummary_末點低於首點_顯示下降敘述() {
        // Given
        let points: [Double] = [300, 100]
        let expected = LocalizedStringKey(
            "Monthly profit trend chart, 2 months in total, overall downward, lowest NT$100, highest NT$300"
        )

        // When
        let text = DashboardFormatters.sparklineSummary(points, locale: AppLanguage.english.locale)

        // Then
        #expect(text == expected)
    }

    /// 末點與首點相同時採用持平的敘述
    @Test
    func sparklineSummary_末點等於首點_顯示持平敘述() {
        // Given
        let points: [Double] = [200, 200]
        let expected = LocalizedStringKey("月獲利走勢圖，共 2 個月，整體持平，最低 $200，最高 $200")

        // When
        let text = DashboardFormatters.sparklineSummary(
            points,
            locale: AppLanguage.traditionalChinese.locale
        )

        // Then
        #expect(text == expected)
    }

    /// 日期子標依記錄的曆法與時區格式化，2026 年 4 月 30 日為星期四
    @Test
    func dateSubtitle_注入的曆法與時區_顯示月日與星期() {
        // Given
        let context = DashboardDateContext(
            now: Date(timeIntervalSince1970: 1_777_507_200),
            calendar: TestDependencies.fixedCalendar
        )

        // When
        let text = DashboardFormatters.dateSubtitle(
            for: context,
            locale: AppLanguage.traditionalChinese.locale
        )

        // Then
        #expect(text == "4月30日星期四")
    }

    /// 日期以記錄的時區換算，UTC 的 5 月 12 日 17:30 在臺北已是 5 月 13 日
    ///
    /// - Throws: 時區識別字無法解析時丟出
    @Test
    func dateSubtitle_接近午夜的其他時區_換算為記錄時區的日期() throws {
        // Given
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "Asia/Taipei"))
        let context = DashboardDateContext(
            now: Date(timeIntervalSince1970: 1_778_607_000),
            calendar: calendar
        )

        // When
        let text = DashboardFormatters.dateSubtitle(
            for: context,
            locale: AppLanguage.traditionalChinese.locale
        )

        // Then
        #expect(text == "5月13日星期三")
    }

    /// 記錄的曆法為希伯來曆時，月份與日數以希伯來曆呈現，不再使用西曆的月名
    ///
    /// - Note: 2026 年 4 月 30 日 (星期四) 為希伯來曆伊雅月 13 日；英文的希伯來曆格式日數在月名之前
    @Test
    func dateSubtitle_希伯來曆_顯示希伯來月份與日數() {
        // Given
        var calendar = Calendar(identifier: .hebrew)
        calendar.timeZone = .gmt
        let context = DashboardDateContext(
            now: Date(timeIntervalSince1970: 1_777_550_400),
            calendar: calendar
        )

        // When
        let text = DashboardFormatters.dateSubtitle(
            for: context,
            locale: AppLanguage.english.locale
        )

        // Then
        #expect(text == "Thursday, 13 Iyar")
    }
}
