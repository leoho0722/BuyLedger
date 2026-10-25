//
//  CampaignDateSectionBuilderTestSupport.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/2.
//

import Foundation
import Testing

@testable import BuyLedger

/// 提供開團日期區段建構測試共用的時間與行事曆建立操作
enum CampaignDateSectionBuilderTestSupport {}

// MARK: - Internal Method

extension CampaignDateSectionBuilderTestSupport {

    /// 以給定的現在時間與 UTC 時區的行事曆建立日期脈絡
    ///
    /// - Parameter now: 帶 Z 時區的 ISO 8601 現在時間
    /// - Returns: 現在時間與 UTC 西曆組成的日期脈絡
    /// - Throws: 時間字串格式不符時丟出解析錯誤
    static func makeContext(now: String) throws -> CampaignDateContext {
        let currentDate = try makeDate(now)
        let calendar = try makeCalendar(secondsFromGMT: 0)
        return CampaignDateContext(now: currentDate, calendar: calendar)
    }

    /// 解析 ISO 8601 時間字串，讓測試的輸入與預期值都能直接寫成字面日期
    ///
    /// - Parameter text: 帶 Z 時區的 ISO 8601 時間字串
    /// - Returns: 對應的時間點
    /// - Throws: 字串格式不符時丟出解析錯誤
    static func makeDate(_ text: String) throws -> Date {
        try Date(text, strategy: .iso8601)
    }

    /// 建立固定與 UTC 時差的西曆
    ///
    /// - Parameter secondsFromGMT: 與 UTC 相差的秒數
    /// - Returns: 使用該時區的西曆
    /// - Throws: 該時差無法建立時區時由 `#require` 丟出測試斷言錯誤
    static func makeCalendar(secondsFromGMT: Int) throws -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(secondsFromGMT: secondsFromGMT))
        return calendar
    }
}
