//
//  TextInput.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

// MARK: - Internal Method

/// 文字輸入 helper
extension XCUIElement {

    /// 清空欄位既有內容後輸入新文字
    /// - Parameters:
    ///   - text: 要輸入的文字
    ///   - app: 受測 App
    func clearAndType(_ text: String, in app: XCUIApplication) {
        guard waitForExistence(timeout: 5) else {
            return
        }
        var focusAttempts = 0
        repeat {
            tap()
            focusAttempts += 1
        } while !app.keyboards.firstMatch.waitForExistence(timeout: 2) && focusAttempts < 3
        if let existing = value as? String, !existing.isEmpty {
            let deletes = String(repeating: XCUIKeyboardKey.delete.rawValue, count: existing.count)
            typeText(deletes)
        }
        typeText(text)
    }

    /// 點鍵盤工具列的完成鍵收起數字鍵盤
    /// - Parameters:
    ///   - app: 受測 App
    ///   - timeout: 等待完成鍵可互動的秒數
    func dismissNumericKeyboard(
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let doneButton = app.buttons[BLAccessibilityID.Common.keyboardDoneButton]
        guard doneButton.waitUntilHittable() else {
            // extension 取不到 test case，直接附診斷後 XCTFail
            XCTContext.runActivity(named: "收數字鍵盤失敗診斷") { activity in
                let screenshot = XCTAttachment(screenshot: app.screenshot())
                screenshot.name = "失敗畫面"
                screenshot.lifetime = .keepAlways
                activity.add(screenshot)

                let tree = XCTAttachment(string: app.debugDescription)
                tree.name = "失敗時的可及性樹"
                tree.lifetime = .keepAlways
                activity.add(tree)
            }
            XCTFail("找不到數字鍵盤工具列的完成鍵，無法收起鍵盤", file: file, line: line)
            return
        }
        doneButton.tap()
        // 等鍵盤收起後再返回，避免下一欄位誤判焦點。
        _ = app.keyboards.firstMatch.waitForDisappearance(timeout: 5)
    }
}
