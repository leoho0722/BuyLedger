//
//  OrdersScreen+CategoryPicker.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/10/18.
//

import XCTest

// MARK: - Computed Properties

@MainActor
extension OrdersScreen {

    /// regular 版面類別選擇器 sheet 的根元素
    var categoryPickerSheet: XCUIElement {
        app.descendants(matching: .any)[BLAccessibilityID.Orders.categoryPickerSheet]
    }

    /// regular 版面類別觸發鈕目前的標題，例如「類別：2 項」
    var categoryTriggerLabel: String {
        app.descendants(matching: .any)[BLAccessibilityID.Orders.categoryFilterButton].label
    }

    /// regular 版面付款方式 Menu 目前的標題，例如「付款方式：信用卡」
    var paymentMethodTriggerLabel: String {
        app.descendants(matching: .any)[BLAccessibilityID.Orders.paymentMethodMenuButton].label
    }

    /// 類別選擇器搜尋欄的清除鈕是否存在，以判斷搜尋欄是否仍有文字
    var hasCategoryPickerSearchText: Bool {
        app.buttons[BLAccessibilityID.Orders.categoryPickerSearchClearButton].firstMatch.exists
    }

    /// 類別選擇器搜尋欄目前的輸入值，空欄時回傳空字串
    var categoryPickerSearchValue: String {
        let field = app.textFields[BLAccessibilityID.Orders.categoryPickerSearchField].firstMatch
        return hasCategoryPickerSearchText ? (field.value as? String ?? "") : ""
    }
}

// MARK: - Internal Method

@MainActor
extension OrdersScreen {

    /// 點 regular 版面的類別觸發鈕開啟類別選擇器
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func openCategoryPicker(file: StaticString = #filePath, line: UInt = #line) {
        let trigger = app.descendants(matching: .any)[BLAccessibilityID.Orders.categoryFilterButton]
        trigger.tapAfterWaiting(in: app, file: file, line: line)
    }

    /// 點選類別選擇器內的類別格，必要時先露出格子再捲到可點位置
    ///
    /// - Parameters:
    ///   - name: 類別名稱
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func tapPickerCategory(_ name: String, file: StaticString = #filePath, line: UInt = #line) {
        let cell = filterCategoryCell(name)
        if !revealFilterCategory(name, within: categoryPickerSheet) {
            app.failWithDiagnostics("類別選擇器內找不到類別「\(name)」", file: file, line: line)
        }
        scrollToTappable(cell, within: categoryPickerSheet, maxDrags: 40)
        cell.tapAfterWaiting(in: app, file: file, line: line)
    }

    /// 判斷類別選擇器內指定類別是否選中
    ///
    /// - Parameter name: 類別名稱
    /// - Returns: 格子是否存在且選中
    func isPickerCategorySelected(_ name: String) -> Bool {
        filterCategoryCell(name).isSelected
    }

    /// 點類別選擇器內的組標題，切換展開；點前先捲到可點位置
    ///
    /// - Parameters:
    ///   - kindID: 組別種類的識別值
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func tapPickerGroupHeader(
        _ kindID: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let header = filterGroupHeader(kindID)
        if !revealElement(header, within: categoryPickerSheet) {
            app.failWithDiagnostics("類別選擇器內找不到組標題「\(kindID)」", file: file, line: line)
        }
        scrollToTappable(header, within: categoryPickerSheet, maxDrags: 40)
        header.tapAfterWaiting(in: app, file: file, line: line)
    }

    /// 讀取類別選擇器內組標題目前的展開值；讀取前先露出標題，露不出時讓測試失敗
    ///
    /// - Parameter kindID: 組別種類的識別值
    /// - Returns: 「已展開」或「已收合」；取不到時為 `nil`
    func pickerGroupValue(_ kindID: String) -> String? {
        let header = filterGroupHeader(kindID)
        if !revealElement(header, within: categoryPickerSheet) {
            app.failWithDiagnostics("類別選擇器內找不到組標題「\(kindID)」")
        }
        return header.value as? String
    }

    /// 在類別選擇器搜尋欄輸入文字
    ///
    /// - Parameters:
    ///   - text: 搜尋文字
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func typePickerSearch(_ text: String, file: StaticString = #filePath, line: UInt = #line) {
        let fieldID = BLAccessibilityID.Orders.categoryPickerSearchField
        let field = app.textFields[fieldID].firstMatch
        let clearID = BLAccessibilityID.Orders.categoryPickerSearchClearButton
        let clearButton = app.buttons[clearID].firstMatch
        typeSearchText(
            text,
            into: field,
            clearButton: clearButton,
            file: file,
            line: line
        )
    }

    /// 點類別選擇器搜尋欄的清除鈕
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func tapPickerClearSearch(file: StaticString = #filePath, line: UInt = #line) {
        let identifier = BLAccessibilityID.Orders.categoryPickerSearchClearButton
        app.buttons[identifier].firstMatch.tapAfterWaiting(in: app, file: file, line: line)
    }

    /// 點類別選擇器的「完成」，套用暫存類別並關閉
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func tapPickerDone(file: StaticString = #filePath, line: UInt = #line) {
        let identifier = BLAccessibilityID.Orders.categoryPickerDoneButton
        app.buttons[identifier].firstMatch.tapAfterWaiting(in: app, file: file, line: line)
    }

    /// 點類別選擇器的「取消」，有變更時會呈現捨棄確認
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func tapPickerCancel(file: StaticString = #filePath, line: UInt = #line) {
        let identifier = BLAccessibilityID.Orders.categoryPickerCancelButton
        app.buttons[identifier].firstMatch.tapAfterWaiting(in: app, file: file, line: line)
    }

    /// 下滑類別選擇器嘗試關閉，有未套用變更時應被擋下
    ///
    /// - Returns: 選擇器是否仍留在畫面上
    func categoryPickerBlocksSwipeDismiss() -> Bool {
        app.expectSheetBlocksSwipeDismiss(categoryPickerSheet)
    }

    /// 選取 regular 版面付款方式 Menu 的指定項目
    ///
    /// - Parameters:
    ///   - name: 付款方式名稱
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func selectPaymentMethodInRegularLayout(
        _ name: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let menuID = BLAccessibilityID.Orders.paymentMethodMenuButton
        app.descendants(matching: .any)[menuID].tapAfterWaiting(in: app, file: file, line: line)
        let item = BLAccessibilityID.Orders.paymentMethodMenuOption(name)
        _ = app.tapMenuItem(item, file: file, line: line)
    }
}
