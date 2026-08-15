//
//  OptionPickerScreen.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 選項選擇器 (``OptionPickerSheet``) 的 Page Object
struct OptionPickerScreen: Screen {

    // MARK: - Data Properties

    /// 受測 App
    let app: XCUIApplication

    // MARK: - Computed Properties

    /// 判定選擇器已就緒的根 identifier (選項清單容器)
    /// - Returns: 選項清單根容器的 identifier
    var rootIdentifier: String {
        BLAccessibilityID.OptionPicker.root
    }
}

// MARK: - Internal Method

@MainActor
extension OptionPickerScreen {

    /// 點選指定原始值的選項列
    /// - Parameter value: 選項的原始值
    func selectOption(_ value: String) {
        let row = app.descendants(matching: .any)[BLAccessibilityID.OptionPicker.optionRow(value)]
        if !row.isHittable {
            app.scrollToHittable(row, within: rootElement)
        }
        row.waitUntilHittable()
        row.tap()
    }

    /// 點「新增」開啟新增流程
    func tapAdd() {
        let button = app.buttons[BLAccessibilityID.OptionPicker.addButton]
        button.waitUntilHittable()
        button.tap()
    }

    /// 點多選模式的「完成」結束選取
    func tapDone() {
        let button = app.buttons[BLAccessibilityID.OptionPicker.doneButton]
        button.waitUntilHittable()
        button.tap()
    }
}
