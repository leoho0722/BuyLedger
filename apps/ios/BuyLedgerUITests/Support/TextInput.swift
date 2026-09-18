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

    /// 依鍵盤狀態收起數字鍵盤並解除數字欄位焦點
    ///
    /// - Parameters:
    ///   - app: 受測 App
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Note:
    ///   - 軟體鍵盤在 App 視窗內時，點擊工具列完成鍵；完成鍵不可直接命中時，以其可及性 frame 的中心座標點擊，並等待數字鍵盤消失
    ///   - 軟體鍵盤不在 App 視窗內時 (硬體鍵盤接上)，送出 Return，並等待目標欄位的 `hasKeyboardFocus` 變為 `false`
    ///   - 兩條路徑的失敗都以 `failWithDiagnostics` 回報
    func dismissNumericKeyboard(
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard exists else {
            app.failWithDiagnostics(
                "數字鍵盤目標欄位不存在，無法解除焦點",
                file: file,
                line: line
            )
            return
        }

        let keyboardFrame = app.keyboards.firstMatch.frame
        let appWindowFrame = app.windows.firstMatch.frame
        let isSoftwareKeyboardVisible = !keyboardFrame.isEmpty
            && keyboardFrame.intersects(appWindowFrame)

        guard isSoftwareKeyboardVisible else {
            typeText(XCUIKeyboardKey.return.rawValue)
            if !wait(
                for: NSPredicate(format: "hasKeyboardFocus == false"),
                timeout: 5
            ) {
                app.failWithDiagnostics(
                    "硬體鍵盤模式下數字欄位仍保持 Keyboard Focused",
                    file: file,
                    line: line
                )
            }
            return
        }

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
