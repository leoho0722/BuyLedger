//
//  TestDependencies.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/5/3.
//

import ComposableArchitecture
import Foundation
import Testing

/// 為 snapshot 與 unit test 提供可重現的依賴注入
enum TestDependencies {

    // MARK: - Properties

    /// 預設使用的固定「現在」時間 (2026-04-30 00:00:00 UTC)
    static let fixedNow = Date(timeIntervalSince1970: 1_777_507_200)

    /// 預設使用的固定行事曆 (`.gregorian` + UTC)
    static let fixedCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }()
}

// MARK: - Internal Method

extension TestDependencies {

    /// 建立固定 UTC 西曆，避免機器時區影響提醒的日期與時間計算
    ///
    /// - Returns: 時區為 UTC 的西曆
    /// - Throws: 無法建立 UTC 時區時由 `#require` 丟出測試錯誤
    static func makeUTCCalendar() throws -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(secondsFromGMT: 0))
        return calendar
    }

    /// 建立帶固定 `domain` 與 `code` 的底層錯誤替身
    ///
    /// - Parameter message: 要放入錯誤描述的文字
    /// - Returns: 可供持久化與網路測試使用的底層錯誤
    static func makeUnderlyingError(message: String) -> NSError {
        NSError(
            domain: "com.leoho.BuyLedger.tests",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: message]
        )
    }

    /// 在 `fixedNow` 注入固定時間、行事曆與時區後執行操作
    ///
    /// - Parameter operation: 要執行的操作
    /// - Returns: 操作的結果
    /// - Throws: 操作丟出的錯誤
    static func withFixedNow<Value>(_ operation: () throws -> Value) rethrows -> Value {
        try withDependencies {
            $0.date = .constant(fixedNow)
            $0.calendar = fixedCalendar
            $0.timeZone = fixedCalendar.timeZone
        } operation: {
            try operation()
        }
    }
}
