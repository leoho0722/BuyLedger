//
//  TestDependencies+Calendar.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/3.
//

import Foundation
import Testing

// MARK: - Internal Method

extension TestDependencies {

    /// 建立固定 UTC 西曆，避免機器時區影響提醒的日期與提示位移
    ///
    /// - Returns: 時區為 UTC 的西曆
    /// - Throws: 無法建立 UTC 時區時由 `try #require` 丟出測試錯誤
    static func makeUTCCalendar() throws(any Error) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(secondsFromGMT: 0))
        return calendar
    }
}
