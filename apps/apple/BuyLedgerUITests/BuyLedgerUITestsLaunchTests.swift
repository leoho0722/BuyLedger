//
//  BuyLedgerUITestsLaunchTests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/4/29.
//

import XCTest

final class BuyLedgerUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        // 如需在啟動後、截圖前執行額外步驟 (例如登入測試帳號或導覽到特定畫面)，可在此插入。

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
