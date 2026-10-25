//
//  LaunchPerformanceTests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// App 冷啟動時間的效能 UI 測試
@MainActor
final class LaunchPerformanceTests: XCTestCase {

    /// 驗證冷啟動 App 時，以 `XCTApplicationLaunchMetric` 量測啟動時間
    func testLaunch_冷啟動_量測啟動時間() {
        // Given

        // When
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }

        // Then
        // 量測結果記錄在 result bundle，沒有上限斷言
    }
}
