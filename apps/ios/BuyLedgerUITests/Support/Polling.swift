//
//  Polling.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/11/14.
//

import Foundation
import XCTest

/// UI 測試內等待條件或刻意觀察固定時長的入口
@MainActor
enum Polling {}

// MARK: - Internal Method

extension Polling {

    /// 輪詢條件直到成立或逾時
    ///
    /// - Parameters:
    ///   - timeout: 等待條件成立的秒數
    ///   - interval: 每次檢查之間的秒數
    ///   - condition: 要等待成立的條件
    /// - Returns: 條件是否在逾時前成立
    static func wait(
        timeout: TimeInterval,
        interval: TimeInterval = 0.2,
        until condition: () -> Bool
    ) -> Bool {
        let deadline = Date.now.addingTimeInterval(max(timeout, 0))
        while true {
            if condition() {
                return true
            }
            let remaining = deadline.timeIntervalSinceNow
            guard remaining > 0 else {
                return false
            }
            waitForEmptyExpectation(timeout: min(max(interval, 0.01), remaining))
        }
    }

    /// 等待一段刻意保留的固定觀察時間
    ///
    /// - Parameter duration: 固定等待的秒數
    /// - Note: 呼叫此方法時要在呼叫點註明觀察這段時間的理由
    static func pause(for duration: TimeInterval) {
        waitForEmptyExpectation(timeout: max(duration, 0))
    }
}

// MARK: - Private Method

/// 集中執行輪詢與固定觀察時間共用的等待
private extension Polling {

    /// 以空期望等待指定時間
    ///
    /// - Parameter timeout: 等待的秒數
    static func waitForEmptyExpectation(timeout: TimeInterval) {
        guard timeout > 0 else {
            return
        }
        _ = XCTWaiter().wait(for: [XCTestExpectation()], timeout: timeout)
    }
}
