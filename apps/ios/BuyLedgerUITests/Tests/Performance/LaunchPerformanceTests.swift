//
//  LaunchPerformanceTests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 啟動效能量測
///
/// `measure` 預設跑五次啟動、耗時長，獨立成效能測試計畫、不進主回歸集合
final class LaunchPerformanceTests: XCTestCase {

    // MARK: - Tests

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
