//
//  TextInput.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

// MARK: - Text Input

/// 文字輸入 helper
extension XCUIElement {

    /// 清空欄位既有內容後輸入新文字
    ///
    /// - Parameters:
    ///   - text: 要輸入的文字
    ///   - app: 受測 App
    ///   - timeout: 等待欄位可互動的秒數
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func clearAndType(
        _ text: String,
        in app: XCUIApplication,
        timeout: TimeInterval = 5,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        tapAfterWaiting(
            in: app,
            timeout: timeout,
            file: file,
            line: line
        )
        var isKeyboardVisible = app.keyboards.firstMatch.waitForExistence(timeout: 2)
        var focusAttempts = 0
        while !isKeyboardVisible && focusAttempts < 3 {
            tap()
            focusAttempts += 1
            isKeyboardVisible = app.keyboards.firstMatch.waitForExistence(timeout: 2)
        }
        if !isKeyboardVisible {
            app.failWithDiagnostics(
                "點擊 identifier 為 \(identifier) 的輸入欄後鍵盤未出現",
                file: file,
                line: line
            )
            return
        }
        if let existing = value as? String, !existing.isEmpty {
            let deletes = String(repeating: XCUIKeyboardKey.delete.rawValue, count: existing.count)
            typeText(deletes)
        }
        typeText(text)
    }

    /// 點鍵盤工具列的完成鍵收起數字鍵
    ///
    /// - Parameters:
    ///   - app: 受測 App
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Note: 完成鍵不可直接命中時，以其可及性 frame 的中心座標點擊
    func dismissNumericKeyboard(
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let doneButton = app.buttons[BLAccessibilityID.Common.keyboardDoneButton]
        if !doneButton.waitForExistence(timeout: 10) {
            app.failWithDiagnostics(
                "數字鍵盤工具列的完成鍵未出現",
                file: file,
                line: line
            )
            return
        }

        if doneButton.isHittable {
            doneButton.tap()
        } else {
            doneButton
                .coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
                .tap()
        }

        // 等鍵盤收起後再返回，避免下一欄位誤判焦點。
        if !app.keyboards.firstMatch.waitForDisappearance(timeout: 5) {
            app.failWithDiagnostics(
                "數字鍵盤工具列的完成鍵未能收起鍵盤",
                file: file,
                line: line
            )
        }
    }
}
