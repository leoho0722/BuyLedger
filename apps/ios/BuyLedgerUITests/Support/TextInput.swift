//
//  TextInput.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

// MARK: - Internal Method

/// 文字輸入 helper
///
/// 數字鍵盤 (numberPad/decimalPad) 沒有 return 鍵，清空重填與收鍵盤這兩個常見動作
/// 收攏在這裡，各測試不必各寫一套
extension XCUIElement {

    /// 清空欄位既有內容後輸入新文字
    ///
    /// 先點欄位右緣聚焦並讓游標落到內容尾端，再依現值長度倒退刪除，避免舊值與新值黏在一起;
    /// 空欄的 `value` 可能回傳 placeholder，多送的刪除鍵對空欄無副作用。全 App 負載下單次點擊可能來不及
    /// 建立鍵盤焦點、`typeText` 會以「無鍵盤焦點」失敗，故點後等鍵盤升起確認焦點，逾時就重點 (最多三次)
    /// - Parameters:
    ///   - text: 要輸入的新文字
    ///   - app: 受測 App，供等待鍵盤升起以確認焦點
    func clearAndType(_ text: String, in app: XCUIApplication) {
        var focusAttempts = 0
        repeat {
            coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
            focusAttempts += 1
        } while !app.keyboards.firstMatch.waitForExistence(timeout: 2) && focusAttempts < 3
        if let existing = value as? String, !existing.isEmpty {
            let deletes = String(repeating: XCUIKeyboardKey.delete.rawValue, count: existing.count)
            typeText(deletes)
        }
        typeText(text)
    }

    /// 點鍵盤工具列的完成鍵收起數字鍵盤
    ///
    /// numberPad/decimalPad 沒有 return 鍵，只能靠工具列的完成鍵收起；
    /// 找不到該鍵時附診斷讓測試失敗、不靜默略過
    /// - Parameters:
    ///   - app: 受測 App
    ///   - file: 呼叫端檔案，交由 XCTest 定位
    ///   - line: 呼叫端行號，交由 XCTest 定位
    func dismissNumericKeyboard(
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let doneButton = app.buttons[BLAccessibilityID.Common.keyboardDoneButton]
        guard doneButton.waitUntilHittable() else {
            // failWithDiagnostics 是 XCTestCase 的方法，XCUIElement extension 取不到 test case，
            // 故以相同素材 (截圖 + 可及性樹) 就地附診斷後 XCTFail
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
        // 等鍵盤確實收掉再返回:負載下鍵盤收合有延遲，若殘留會讓下一個欄位的 clearAndType 誤判「有鍵盤 = 已聚焦」而漏聚焦
        _ = app.keyboards.firstMatch.waitForDisappearance(timeout: 5)
    }
}
