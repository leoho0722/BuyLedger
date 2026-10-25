//
//  OrderCategoryPickerScreen.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/10/18.
//

import XCTest

/// regular 版面類別選擇器 sheet 的 Page Object
struct OrderCategoryPickerScreen {

    // MARK: - Properties

    /// 受測 App
    let app: XCUIApplication
}

// MARK: - Computed Properties

@MainActor
extension OrderCategoryPickerScreen {

    /// regular 版面類別選擇器 sheet 的根元素
    var categoryPickerSheet: XCUIElement {
        app.descendants(matching: .any)[BLAccessibilityID.Orders.categoryPickerSheet]
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
extension OrderCategoryPickerScreen {

    /// 點選類別選擇器內的類別格，必要時先露出格子再捲到可點位置
    ///
    /// - Parameters:
    ///   - name: 類別名稱
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func tapPickerCategory(_ name: String, file: StaticString = #filePath, line: UInt = #line) {
        let cell = orders.filterCategoryCell(name)
        if !orders.revealFilterCategory(name, within: categoryPickerSheet) {
            app.failWithDiagnostics("類別選擇器內找不到類別「\(name)」", file: file, line: line)
        }
        orders.scrollToTappable(cell, within: categoryPickerSheet, maxDrags: 40)
        cell.tapAfterWaiting(in: app, file: file, line: line)
    }

    /// 判斷類別選擇器內指定類別是否選中
    ///
    /// - Parameter name: 類別名稱
    /// - Returns: 格子是否存在且選中
    func isPickerCategorySelected(_ name: String) -> Bool {
        orders.filterCategoryCell(name).isSelected
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
        let header = orders.filterGroupHeader(kindID)
        if !orders.revealElement(header, within: categoryPickerSheet) {
            app.failWithDiagnostics("類別選擇器內找不到組標題「\(kindID)」", file: file, line: line)
        }
        orders.scrollToTappable(header, within: categoryPickerSheet, maxDrags: 40)
        header.tapAfterWaiting(in: app, file: file, line: line)
    }

    /// 讀取類別選擇器內組標題目前的展開值；讀取前先露出標題，露不出時讓測試失敗
    ///
    /// - Parameter kindID: 組別種類的識別值
    /// - Returns: 「已展開」或「已收合」；取不到時為 `nil`
    func pickerGroupValue(_ kindID: String) -> String? {
        let header = orders.filterGroupHeader(kindID)
        if !orders.revealElement(header, within: categoryPickerSheet) {
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
        orders.typeSearchText(
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
}

// MARK: - Screen

extension OrderCategoryPickerScreen: Screen {

    /// 判定類別選擇器已呈現的根 identifier
    var rootIdentifier: String {
        BLAccessibilityID.Orders.categoryPickerSheet
    }
}

// MARK: - Private Method

@MainActor
private extension OrderCategoryPickerScreen {

    /// 承載兩個 sheet 共用的類別格查詢、捲動與搜尋輸入 helper 的訂單清單 Page Object
    var orders: OrdersScreen {
        OrdersScreen(app: app)
    }
}
