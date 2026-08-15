//
//  TestDependencies.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/5/3.
//

import ComposableArchitecture
import Foundation

/// 為 snapshot 與 unit test 提供可重現的依賴注入
enum TestDependencies {
    
    // MARK: - Static Properties
    
    /// 預設使用的固定「現在」時間 (2026-04-30 00:00:00 UTC)
    static let fixedNow: Date = {
        var components = DateComponents()
        components.calendar = Calendar(identifier: .gregorian)
        components.timeZone = TimeZone(secondsFromGMT: 0)
        components.year = 2026
        components.month = 4
        components.day = 30
        return components.date!
    }()
    
    /// 預設使用的固定行事曆 (gregorian + UTC)
    static let fixedCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }()
}

// MARK: - Internal Method

extension TestDependencies {
    
    /// 在 ``fixedNow`` 注入 `\.date` 的 scope 中執行 operation
    /// - Parameter operation: 要執行的操作
    /// - Returns: operation 的結果
    /// - Throws: operation 拋出的錯誤
    static func withFixedNow<T>(_ operation: () throws(any Error) -> T) rethrows -> T {
        try withDependencies {
            $0.date = .constant(fixedNow)
            $0.calendar = fixedCalendar
        } operation: {
            try operation()
        }
    }
}
