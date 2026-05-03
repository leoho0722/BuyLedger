//
//  TestDependencies.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/5/3.
//

import ComposableArchitecture
import Foundation

/// 為 snapshot 與 unit test 提供可重現的依賴注入。
///
/// 任何使用 ``@Dependency(\.date)`` 的 reducer / view，在測試時都應透過此處的固定值或 helper 注入，
/// 避免「跨日跑出不同結果」「不同機器跑出不同 Locale 字串」這類隱性 flake。
enum TestDependencies {

    // MARK: - Static Properties

    /// 預設使用的固定「現在」時間（2026-04-30 00:00:00 UTC）。
    ///
    /// 落在 ``LedgerOrder/sampleOrders`` 的當月區間內，方便 Dashboard / Insights / Orders 的「本月」「近 30 天」等統計值有非零內容。
    static let fixedNow: Date = {
        var components = DateComponents()
        components.calendar = Calendar(identifier: .gregorian)
        components.timeZone = TimeZone(secondsFromGMT: 0)
        components.year = 2026
        components.month = 4
        components.day = 30
        return components.date!
    }()

    // MARK: - Static Method

    /// 在 ``fixedNow`` 注入 `\.date` 的 scope 中執行 operation。
    ///
    /// SnapshotTesting 與 SwiftUI render 都是同步流程，可以在單一 closure 內完成 view 建構與 `assertSnapshot` 呼叫。
    /// - Parameter operation: 需要在固定依賴下執行的 closure。
    /// - Returns: closure 的回傳值。
    static func withFixedNow<T>(_ operation: () throws -> T) rethrows -> T {
        try withDependencies {
            $0.date = .constant(fixedNow)
        } operation: {
            try operation()
        }
    }
}
