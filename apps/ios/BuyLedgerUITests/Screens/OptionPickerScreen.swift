//
//  OptionPickerScreen.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 選項選擇器 (``OptionPickerSheet``) 的 Page Object
struct OptionPickerScreen {

    // MARK: - Properties

    /// 受測 App
    let app: XCUIApplication
}

// MARK: - Internal Method

@MainActor
extension OptionPickerScreen {

    /// 點選指定原始值的選項列
    ///
    /// - Parameters:
    ///   - value: 選項的原始值
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func selectOption(_ value: String, file: StaticString = #filePath, line: UInt = #line) {
        let row = app.descendants(matching: .any)[BLAccessibilityID.OptionPicker.optionRow(value)]
        if !row.isHittableOnScreen {
            app.scrollToHittable(row, within: rootElement)
        }
        row.tapAfterWaiting(in: app, file: file, line: line)
    }

    /// 以搜尋欄輸入關鍵字
    ///
    /// - Parameters:
    ///   - text: 要搜尋的關鍵字
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func search(_ text: String, file: StaticString = #filePath, line: UInt = #line) {
        if let field = app.searchFields.allElementsBoundByIndex.first(where: \.isHittableOnScreen) {
            field.clearAndType(
                text,
                in: app,
                file: file,
                line: line
            )
        } else {
            app.failWithDiagnostics("找不到可互動的選項搜尋欄", file: file, line: line)
        }
    }

    /// 讀取指定選項列的 accessibility label
    ///
    /// - Parameters:
    ///   - value: 選項的原始值
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 選項列的 accessibility label；列不存在時為 `nil`
    func optionLabel(
        for value: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> String? {
        let row = app.descendants(matching: .any)[BLAccessibilityID.OptionPicker.optionRow(value)]
        if !row.waitForExistence(timeout: 10) {
            app.failWithDiagnostics("選項列「\(value)」逾時仍未出現", file: file, line: line)
            return nil
        }
        return row.label
    }

    /// 點「新增」開啟新增流程
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func tapAdd(file: StaticString = #filePath, line: UInt = #line) {
        let button = app.buttons[BLAccessibilityID.OptionPicker.addButton]
        button.tapAfterWaiting(in: app, file: file, line: line)
    }

    /// 清空新增 alert 的名稱欄並填入名稱
    ///
    /// - Parameters:
    ///   - name: 要新增的選項名稱
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func typeNewOptionName(_ name: String, file: StaticString = #filePath, line: UInt = #line) {
        // SwiftUI alert 內的 TextField 不帶出 identifier，改取 alert 內唯一的文字欄
        let field = app.alerts.firstMatch.textFields.firstMatch
        field.clearAndType(
            name,
            in: app,
            file: file,
            line: line
        )
    }

    /// 點新增 alert 的確認鍵送出名稱
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func confirmAdd(file: StaticString = #filePath, line: UInt = #line) {
        app.tapAlertButton(
            BLAccessibilityID.OptionPicker.addAlertConfirmButton,
            file: file,
            line: line
        )
    }

    /// 點多選模式的「完成」結束選取
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func tapDone(file: StaticString = #filePath, line: UInt = #line) {
        let button = app.buttons[BLAccessibilityID.OptionPicker.doneButton]
        button.tapAfterWaiting(in: app, file: file, line: line)
    }

    /// 走宿主堆疊的 Back 返回推入選擇器的表單，不選取任何選項
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func tapBack(file: StaticString = #filePath, line: UInt = #line) {
        // sheet 底層畫面 (如推入的訂單詳情) 的返回鍵仍在可及性樹上，只點畫面上可互動的那一個
        let backButtons = app.navigationBars.buttons
            .matching(identifier: BLAccessibilityID.Common.backButton)
        let deadline = Date.now.addingTimeInterval(10)
        while Date.now < deadline {
            if let back = backButtons.allElementsBoundByIndex.first(where: \.isHittableOnScreen) {
                back.tap()
                return
            }
            _ = XCTWaiter().wait(for: [XCTestExpectation()], timeout: 0.2)
        }
        app.failWithDiagnostics("找不到可互動的選擇器返回鍵", file: file, line: line)
    }
}

// MARK: - Screen

extension OptionPickerScreen: Screen {

    /// 判定選擇器已就緒的根 identifier (選項清單容器)
    var rootIdentifier: String {
        BLAccessibilityID.OptionPicker.root
    }
}
