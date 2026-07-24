//
//  Diagnostics.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 測試失敗時的診斷附件
///
/// 找不到元素就 `XCTFail` 是本專案的硬規則，但光有錯誤訊息難以事後歸因；
/// 這些 helper 把當下的截圖與可及性樹一併附進測試結果，讓失敗離線可查

// MARK: - Internal Method

extension XCTestCase {

    /// 把目前畫面截圖存成永久附件
    /// - Parameters:
    ///   - app: 受測 App
    ///   - name: 附件名稱
    func attachScreenshot(of app: XCUIApplication, named name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// 把目前的可及性樹存成永久附件，供比對元素查詢為何落空
    /// - Parameters:
    ///   - app: 受測 App
    ///   - name: 附件名稱
    func attachAccessibilityTree(of app: XCUIApplication, named name: String) {
        let attachment = XCTAttachment(string: app.debugDescription)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// 附上截圖與可及性樹後讓測試失敗，取代找不到元素就靜默 skip 的舊作法
    /// - Parameters:
    ///   - app: 受測 App
    ///   - message: 失敗原因
    ///   - file: 呼叫端檔案，交由 XCTest 定位
    ///   - line: 呼叫端行號，交由 XCTest 定位
    func failWithDiagnostics(
        in app: XCUIApplication,
        _ message: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        attachScreenshot(of: app, named: "失敗畫面")
        attachAccessibilityTree(of: app, named: "失敗時的可及性樹")
        XCTFail(message, file: file, line: line)
    }
}
