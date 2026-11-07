//
//  XCUIElement+FocusTap.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/11/5.
//

import XCTest

// MARK: - 點擊取得焦點

@MainActor
extension XCUIElement {

    /// 點欄位左側取得焦點，等鍵盤或數字面板就位後返回
    ///
    /// - Parameters:
    ///   - app: 受測 App
    ///   - dx: 欄位內點擊位置的水平比例，預設靠近左緣
    ///   - timeout: 各階段等待框線或鍵盤就緒的秒數
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 欄位已取得焦點且鍵盤框線連續三次相同時為真
    @discardableResult
    func tapLeftToFocus(
        in app: XCUIApplication,
        dx: CGFloat = 0.04,
        timeout: TimeInterval = 10,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Bool {
        let target = firstMatch
        guard target.waitUntilStableAndHittable(
            timeout: timeout,
            sampleInterval: 0.2,
            requiredSamples: 3
        ) else {
            app.failWithDiagnostics("點欄位左側前，欄位框線未穩定或仍不可點", file: file, line: line)
            return false
        }
        target.coordinate(withNormalizedOffset: CGVector(dx: dx, dy: 0.5)).tap()

        let focusPredicate = NSPredicate(format: "hasKeyboardFocus == true")
        var previousFrame: CGRect?
        var matchingFrames = 0
        let hasSettledKeyboard = pollUntil(timeout: timeout) {
            let snapshot = try? target.snapshot() // 失敗可忽略，因為欄位所在的列可能暫時被回收
            if let snapshot,
               focusPredicate.evaluate(with: snapshot),
               let currentFrame = app.presentedKeyboardFrame {
                matchingFrames = currentFrame == previousFrame ? matchingFrames + 1 : 1
                previousFrame = currentFrame
                return matchingFrames >= 3
            }
            previousFrame = nil
            matchingFrames = 0
            return false
        }
        guard hasSettledKeyboard else {
            app.failWithDiagnostics("點欄位左側後，未取得鍵盤焦點或鍵盤與數字 Popover 框線未穩定", file: file, line: line)
            return false
        }
        return true
    }
}
