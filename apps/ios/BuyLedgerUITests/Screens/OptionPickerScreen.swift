//
//  OptionPickerScreen.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 選項選擇器 (``OptionPickerSheet``) 的 Page Object
struct OptionPickerScreen: Screen {

    // MARK: - Properties

    /// 受測 App
    let app: XCUIApplication

    // MARK: - Computed Properties

    /// 判定選擇器已就緒的根 identifier (選項清單容器)
    ///
    /// - Returns: 選項清單根容器的 identifier
    var rootIdentifier: String {
        BLAccessibilityID.OptionPicker.root
    }
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
    func selectOption(
        _ value: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let row = app.descendants(matching: .any)[BLAccessibilityID.OptionPicker.optionRow(value)]
        if !row.isHittable {
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
    func search(
        _ text: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard let field = app.searchFields.allElementsBoundByIndex.first(where: \.isHittable) else {
            app.failWithDiagnostics(
                "找不到可互動的選項搜尋欄",
                file: file,
                line: line
            )
            return
        }
        field.clearAndType(
            text,
            in: app,
            file: file,
            line: line
        )
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
        guard row.waitForExistence(timeout: 10) else {
            app.failWithDiagnostics(
                "選項列「\(value)」逾時仍未出現",
                file: file,
                line: line
            )
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

    /// 點多選模式的「完成」結束選取
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func tapDone(file: StaticString = #filePath, line: UInt = #line) {
        let button = app.buttons[BLAccessibilityID.OptionPicker.doneButton]
        button.tapAfterWaiting(in: app, file: file, line: line)
    }
}
