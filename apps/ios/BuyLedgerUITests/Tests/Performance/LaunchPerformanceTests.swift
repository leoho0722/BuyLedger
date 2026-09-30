//
//  LaunchPerformanceTests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 啟動效能量測
final class LaunchPerformanceTests: XCTestCase {

    // MARK: - Tests

    @MainActor
    func testLaunchPerformance() {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
