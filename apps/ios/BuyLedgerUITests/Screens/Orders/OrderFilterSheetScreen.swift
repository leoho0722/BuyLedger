//
//  OrderFilterSheetScreen.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/10/18.
//

import XCTest

/// compact 版面整合篩選 sheet 的 Page Object
struct OrderFilterSheetScreen {

    // MARK: - Properties

    /// 受測 App
    let app: XCUIApplication
}

// MARK: - Computed Properties

@MainActor
extension OrderFilterSheetScreen {

    /// 篩選 sheet 的根元素，以 identifier 定位
    var filterSheet: XCUIElement {
        app.descendants(matching: .any)[BLAccessibilityID.Orders.filterSheet]
    }

    /// 類別搜尋欄是否仍有文字，以清除鈕是否存在判斷
    var hasFilterSearchText: Bool {
        app.buttons[BLAccessibilityID.Orders.filterSearchClearButton].firstMatch.exists
    }

    /// 類別搜尋欄目前的輸入值，空欄時回傳空字串
    var filterSearchFieldValue: String {
        let field = app.textFields[BLAccessibilityID.Orders.filterSearchField].firstMatch
        return hasFilterSearchText ? (field.value as? String ?? "") : ""
    }
}

// MARK: - Internal Method

@MainActor
extension OrderFilterSheetScreen {

    /// 判斷指定類別格是否處於選中狀態 (`isSelected` 對應 `.isSelected` trait)
    ///
    /// - Parameter name: 類別名稱
    /// - Returns: 格子是否存在且選中
    func isFilterCategorySelected(_ name: String) -> Bool {
        orders.filterCategoryCell(name).isSelected
    }

    /// 點篩選 sheet 內的類別格，必要時先捲到可點位置
    ///
    /// - Parameters:
    ///   - name: 類別名稱
    ///   - maxDrags: 輕拖次數上限
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func tapFilterCategory(
        _ name: String,
        maxDrags: Int = 12,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let cell = orders.filterCategoryCell(name)
        if !orders.revealFilterCategory(name) {
            app.failWithDiagnostics("篩選 sheet 內找不到類別「\(name)」", file: file, line: line)
        }
        orders.scrollToTappable(cell, within: filterSheet, maxDrags: maxDrags)
        cell.tapAfterWaiting(in: app, file: file, line: line)
    }

    /// 讀取組標題目前的展開值，為「已展開」或「已收合」；讀取前先露出標題，露不出時讓測試失敗
    ///
    /// - Parameter kindID: 組別種類的識別值
    /// - Returns: accessibility value；取不到時為 `nil`
    func filterGroupValue(_ kindID: String) -> String? {
        let header = orders.filterGroupHeader(kindID)
        if !orders.revealElement(header, within: filterSheet) {
            app.failWithDiagnostics("篩選 sheet 內找不到組標題「\(kindID)」")
        }
        return header.value as? String
    }

    /// 點組標題切換展開，必要時先捲到可點位置
    ///
    /// - Parameters:
    ///   - kindID: 組別種類的識別值
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func tapFilterGroupHeader(
        _ kindID: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let header = orders.filterGroupHeader(kindID)
        if !orders.revealElement(header, within: filterSheet) {
            app.failWithDiagnostics("篩選 sheet 內找不到組標題「\(kindID)」", file: file, line: line)
        }
        orders.scrollToTappable(header, within: filterSheet)
        header.tapAfterWaiting(in: app, file: file, line: line)
    }

    /// 選取日期 Menu 的指定期間
    ///
    /// - Parameters:
    ///   - periodID: 日期期間的識別值 (例如 `thisMonth`)
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func selectFilterDatePeriod(
        _ periodID: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let menu = app.descendants(matching: .any)[BLAccessibilityID.Orders.filterDateMenuButton]
        menu.tapAfterWaiting(in: app, file: file, line: line)
        let item = BLAccessibilityID.Orders.filterDatePeriod(periodID)
        _ = app.tapMenuItem(item, file: file, line: line)
    }

    /// 選取付款方式 Menu 的指定項目
    ///
    /// - Parameters:
    ///   - name: 付款方式名稱
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func selectFilterPaymentMethod(
        _ name: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let menuID = BLAccessibilityID.Orders.filterPaymentMethodMenuButton
        app.descendants(matching: .any)[menuID].tapAfterWaiting(in: app, file: file, line: line)
        let item = BLAccessibilityID.Orders.filterPaymentMethodOption(name)
        _ = app.tapMenuItem(item, file: file, line: line)
    }

    /// 在類別搜尋欄輸入文字
    ///
    /// - Parameters:
    ///   - text: 搜尋文字
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func typeFilterSearch(_ text: String, file: StaticString = #filePath, line: UInt = #line) {
        let field = app.textFields[BLAccessibilityID.Orders.filterSearchField].firstMatch
        let clearID = BLAccessibilityID.Orders.filterSearchClearButton
        let clearButton = app.buttons[clearID].firstMatch
        orders.typeSearchText(
            text,
            into: field,
            clearButton: clearButton,
            file: file,
            line: line
        )
    }

    /// 點搜尋欄的清除鈕
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func tapFilterClearSearch(file: StaticString = #filePath, line: UInt = #line) {
        let buttonID = BLAccessibilityID.Orders.filterSearchClearButton
        let button = app.buttons[buttonID].firstMatch
        button.tapAfterWaiting(in: app, file: file, line: line)
    }

    /// 點篩選 sheet 的「清除篩選」
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func tapFilterClear(file: StaticString = #filePath, line: UInt = #line) {
        let button = app.buttons[BLAccessibilityID.Orders.filterClearButton].firstMatch
        button.tapAfterWaiting(in: app, file: file, line: line)
    }

    /// 點篩選 sheet 的「套用」
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func tapFilterApply(file: StaticString = #filePath, line: UInt = #line) {
        let button = app.buttons[BLAccessibilityID.Orders.filterApplyButton].firstMatch
        button.tapAfterWaiting(in: app, file: file, line: line)
    }

    /// 點篩選 sheet 的「取消」，有未套用變更時會呈現捨棄確認
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func tapFilterCancel(file: StaticString = #filePath, line: UInt = #line) {
        let button = app.buttons[BLAccessibilityID.Orders.filterCancelButton].firstMatch
        button.tapAfterWaiting(in: app, file: file, line: line)
    }

    /// 下滑篩選 sheet 嘗試關閉，無未套用變更時應關閉
    ///
    /// - Returns: sheet 是否在逾時前關閉
    func dismissFilterSheetBySwipe() -> Bool {
        app.dismissSheetBySwipe(filterSheet)
    }

    /// 下滑篩選 sheet 嘗試關閉，有未套用變更時應被擋下
    ///
    /// - Returns: sheet 是否仍留在畫面上
    func filterSheetBlocksSwipeDismiss() -> Bool {
        app.expectSheetBlocksSwipeDismiss(filterSheet)
    }
}

// MARK: - Screen

extension OrderFilterSheetScreen: Screen {

    /// 判定篩選 sheet 已呈現的根 identifier
    var rootIdentifier: String {
        BLAccessibilityID.Orders.filterSheet
    }
}

// MARK: - Private Method

@MainActor
private extension OrderFilterSheetScreen {

    /// 承載兩個 sheet 共用的類別格查詢、捲動與搜尋輸入 helper 的訂單清單 Page Object
    var orders: OrdersScreen {
        OrdersScreen(app: app)
    }
}
