//
//  OptionPickerScreen.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 選項選擇器 (``OptionPickerSheet``) 的 Page Object
///
/// 訂單編輯、設定、匯率、報價共用同一個選擇器元件，同一時刻只會有一個在畫面上，故不分呼叫來源共用這組 identifier；
/// 以 accessibility identifier 對外暴露選項點選、開啟新增、多選完成的語意操作，元素查詢細節不外洩給測試檔
struct OptionPickerScreen: Screen {

    // MARK: - Data Properties

    /// 受測 App
    let app: XCUIApplication

    // MARK: - Computed Properties

    /// 判定選擇器已就緒的根 identifier (選項清單容器)
    var rootIdentifier: String {
        BLAccessibilityID.OptionPicker.root
    }
}

// MARK: - Internal Method

@MainActor
extension OptionPickerScreen {

    /// 點選指定原始值的選項列
    ///
    /// 選項列是 `List` 內的 Button，XCUITest 可能歸為 button 或 staticText，故以 any 查詢；離屏時先捲入可點位置。
    /// 單選模式點列即套用並自動關閉，多選模式點列 toggle 勾選、需另以 ``tapDone()`` 結束
    /// - Parameter value: 選項的原始字串這個業務鍵 (顯示名稱與排序變動都不影響定位)
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
