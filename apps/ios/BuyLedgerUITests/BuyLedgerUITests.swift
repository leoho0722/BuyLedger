//
//  BuyLedgerUITests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/4/29.
//

import XCTest

final class BuyLedgerUITests: XCTestCase {

    override func setUpWithError() throws {
        // UI 測試發生失敗時立即停止，避免後續步驟在錯誤狀態上連鎖失敗
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {}

    @MainActor
    func testLaunchDoesNotCrash() throws {
        // 啟動 App 作為冒煙測試：確認主流程能順利啟動且不崩潰
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))
    }

    @MainActor
    func testLaunchPerformance() throws {
        // 測量 App 啟動所需時間
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
