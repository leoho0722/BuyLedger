//
//  BLUITestConfigurationUITestSupport.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/11/15.
//

import XCTest

/// UI 測試替身相關測試共用的斷言
@MainActor
enum BLUITestConfigurationUITestSupport {

    // MARK: - Properties

    /// 系統彈窗所在的 SpringBoard bundle identifier
    private static let springboardBundleIdentifier = "com.apple.springboard"
}

// MARK: - Internal Method

@MainActor
extension BLUITestConfigurationUITestSupport {

    /// 確認 SpringBoard 沒有系統層級彈窗，有則附診斷失敗
    ///
    /// - Parameters:
    ///   - app: 受測 App，用於附上失敗診斷
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 出現系統層級彈窗時丟出測試錯誤
    static func assertNoSystemPrompt(
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        let springboard = XCUIApplication(bundleIdentifier: springboardBundleIdentifier)
        guard springboard.alerts.count == 0 else {
            try app.stopWithDiagnostics(
                "出現系統層級彈窗，UI 測試替身未接管授權",
                file: file,
                line: line
            )
        }
    }
}
