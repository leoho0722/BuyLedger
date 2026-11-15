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

    /// 篩選 sheet 的類別搜尋欄
    var filterSearchField: XCUIElement {
        app.textFields[BLAccessibilityID.Orders.filterSearchField].firstMatch
    }

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
        let field = filterSearchField
        return hasFilterSearchText ? (field.value as? String ?? "") : ""
    }
}

// MARK: - Internal Method

@MainActor
extension OrderFilterSheetScreen {

    /// 等待清除篩選按鈕存在後讀取其可用狀態
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 清除篩選按鈕是否可用
    /// - Throws: 按鈕在 5 秒內仍不存在時丟出 UITestError.stopped
    func isFilterClearEnabled(
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) -> Bool {
        let button = filterClearButton
        guard button.waitForExistence(timeout: 5) else {
            try app.stopWithDiagnostics("找不到篩選 sheet 的清除篩選按鈕", file: file, line: line)
        }
        return button.isEnabled
    }

    /// 判斷指定類別格是否處於選中狀態 (`isSelected` 對應 `.isSelected` trait)
    ///
    /// - Parameter name: 類別名稱
    /// - Returns: 格子是否存在且選中
    func isFilterCategorySelected(_ name: String) -> Bool {
        categoryGrid.filterCategoryCell(name).isSelected
    }

    /// 點篩選 sheet 內的類別格，必要時先捲到可點位置
    ///
    /// - Parameters:
    ///   - name: 類別名稱
    ///   - maxDrags: 輕拖次數上限
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    func tapFilterCategory(
        _ name: String,
        maxDrags: Int = 12,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        let cell = categoryGrid.filterCategoryCell(name)
        try ensureFilterSheetExpanded(for: cell, file: file, line: line)
        try categoryGrid.revealFilterCategory(
            name,
            within: filterSheet,
            file: file,
            line: line
        )
        try categoryGrid.scrollToTappable(
            cell,
            within: filterSheet,
            maxDrags: maxDrags,
            file: file,
            line: line
        )
        try cell.tapAfterWaiting(in: app, file: file, line: line)
    }

    /// 讀取組標題目前的展開值，為「已展開」或「已收合」；讀取前先露出標題，露不出時讓測試失敗
    ///
    /// - Parameters:
    ///   - kindID: 組別種類的識別值
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: accessibility value；取不到時為 `nil`
    /// - Throws: 組標題未能露出時丟出測試錯誤
    func filterGroupValue(
        _ kindID: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) -> String? {
        let header = categoryGrid.filterGroupHeader(kindID)
        try ensureFilterSheetExpanded(for: header, file: file, line: line)
        try categoryGrid.revealElement(
            header,
            within: filterSheet,
            file: file,
            line: line
        )
        return header.value as? String
    }

    /// 點組標題切換展開，必要時先捲到可點位置
    ///
    /// - Parameters:
    ///   - kindID: 組別種類的識別值
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    func tapFilterGroupHeader(
        _ kindID: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        let header = categoryGrid.filterGroupHeader(kindID)
        try ensureFilterSheetExpanded(for: header, file: file, line: line)
        try categoryGrid.revealElement(
            header,
            within: filterSheet,
            file: file,
            line: line
        )
        try categoryGrid.scrollToTappable(
            header,
            within: filterSheet,
            file: file,
            line: line
        )
        try header.tapAfterWaiting(in: app, file: file, line: line)
    }

    /// 選取日期 Menu 的指定期間
    ///
    /// - Parameters:
    ///   - periodID: 日期期間的識別值 (例如 `thisMonth`)
    ///   - label: identifier 缺失時回退使用的可見標籤，預設依 `periodID` 映射
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    func selectFilterDatePeriod(
        _ periodID: String,
        label: String? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        let menu = app.descendants(matching: .any)[BLAccessibilityID.Orders.filterDateMenuButton]
        try menu.tapAfterWaiting(in: app, file: file, line: line)
        let item = BLAccessibilityID.Orders.filterDatePeriod(periodID)
        let fallbackLabel = label ?? datePeriodLabel(for: periodID)
        try app.tapMenuItem(
            item,
            label: fallbackLabel,
            file: file,
            line: line
        )
    }

    /// 選取付款方式 Menu 的指定項目
    ///
    /// - Parameters:
    ///   - name: 付款方式名稱
    ///   - label: identifier 缺失時回退使用的可見標籤，預設為 `name`
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    func selectFilterPaymentMethod(
        _ name: String,
        label: String? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        let menuID = BLAccessibilityID.Orders.filterPaymentMethodMenuButton
        try app.descendants(matching: .any)[menuID].tapAfterWaiting(in: app, file: file, line: line)
        let item = BLAccessibilityID.Orders.filterPaymentMethodOption(name)
        let fallbackLabel = label ?? name
        try app.tapMenuItem(
            item,
            label: fallbackLabel,
            file: file,
            line: line
        )
    }

    /// 在類別搜尋欄輸入文字
    ///
    /// - Parameters:
    ///   - text: 搜尋文字
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    func typeFilterSearch(
        _ text: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        let field = filterSearchField
        try ensureFilterSheetExpanded(for: field, file: file, line: line)
        let clearID = BLAccessibilityID.Orders.filterSearchClearButton
        let clearButton = app.buttons[clearID].firstMatch
        try app.typeSearchText(
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
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    func tapFilterClearSearch(
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        let buttonID = BLAccessibilityID.Orders.filterSearchClearButton
        let button = app.buttons[buttonID].firstMatch
        try button.tapAfterWaiting(in: app, file: file, line: line)
    }

    /// 點篩選 sheet 的「清除篩選」
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    func tapFilterClear(file: StaticString = #filePath, line: UInt = #line) throws(UITestError) {
        let button = filterClearButton
        try button.tapAfterWaiting(in: app, file: file, line: line)
    }

    /// 點篩選 sheet 的「套用」
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    func tapFilterApply(file: StaticString = #filePath, line: UInt = #line) throws(UITestError) {
        let button = app.buttons[BLAccessibilityID.Orders.filterApplyButton].firstMatch
        try button.tapAfterWaiting(in: app, file: file, line: line)
    }

    /// 點篩選 sheet 的「取消」，有未套用變更時會呈現捨棄確認
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    func tapFilterCancel(file: StaticString = #filePath, line: UInt = #line) throws(UITestError) {
        let button = app.buttons[BLAccessibilityID.Orders.filterCancelButton].firstMatch
        try button.tapAfterWaiting(in: app, file: file, line: line)
    }

    /// 下滑篩選 sheet 嘗試關閉，無未套用變更時應關閉；全高時第一下可能只收回到半高，若尚未關閉則補第二次下滑
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    func dismissFilterSheetBySwipe(
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        try app.dismissSheetBySwipe(
            filterSheet,
            timeout: 2,
            file: file,
            line: line
        )
    }

    /// 下滑篩選 sheet 嘗試關閉，有未套用變更時應被擋下
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    func filterSheetBlocksSwipeDismiss(
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        try app.expectSheetBlocksSwipeDismiss(filterSheet, file: file, line: line)
    }
}

// MARK: - ScreenProtocol

extension OrderFilterSheetScreen: ScreenProtocol {

    /// 判定篩選 sheet 已呈現的根 identifier
    var rootIdentifier: String {
        BLAccessibilityID.Orders.filterSheet
    }
}

// MARK: - Private Method

@MainActor
private extension OrderFilterSheetScreen {

    /// 篩選 sheet 的清除篩選按鈕，供點擊與可用狀態查詢共用
    var filterClearButton: XCUIElement {
        app.buttons[BLAccessibilityID.Orders.filterClearButton].firstMatch
    }

    /// 此畫面的類別格查詢與捲動互動
    var categoryGrid: CategoryGridInteraction {
        CategoryGridInteraction(app: app)
    }

    /// 系統表單控點 (Grabber) 按鈕，存在於支援多種呈現高度的 sheet 上緣
    var sheetGrabber: XCUIElement {
        let predicate = NSPredicate(
            format: "label == %@ OR label == %@ OR label == %@",
            "表單控點",
            "Grabber",
            "Sheet Grabber"
        )
        let button = app.buttons.matching(predicate).firstMatch
        if button.exists {
            return button
        }
        return app.descendants(matching: .any).matching(predicate).firstMatch
    }

    /// 確保目標元素已在畫面上可點，若未可點且篩選 sheet 未達全高，則拖曳把手展開並確認高度變大
    ///
    /// - Parameters:
    ///   - target: 要在畫面上點擊或操作的目標元素
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 取不到必要框線或 sheet 無法展開時丟出測試錯誤
    func ensureFilterSheetExpanded(
        for target: XCUIElement,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        if target.isHittableOnScreen {
            return
        }
        _ = filterSheet.waitUntilStableAndHittable(timeout: 2, sampleInterval: 0.1) // 後續以框線判定是否需要展開
        guard let sheetFrame = filterSheet.snapshotFrame,
              let windowFrame = app.windows.firstMatch.snapshotFrame else {
            try app.stopWithDiagnostics("取不到篩選 sheet 或視窗框線，無法判定展開高度", file: file, line: line)
        }
        if sheetFrame.height >= windowFrame.height * 0.75 {
            return
        }

        let initialHeight = sheetFrame.height
        let destination = app.windows.firstMatch.coordinate(
            withNormalizedOffset: CGVector(dx: 0.5, dy: 0.05)
        )

        for _ in 0..<2 {
            let grabber = sheetGrabber
            if grabber.exists {
                let start = grabber.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
                start.press(forDuration: 0.1, thenDragTo: destination)
            } else {
                let start = filterSheet.coordinate(
                    withNormalizedOffset: CGVector(dx: 0.5, dy: 0.02)
                )
                start.press(forDuration: 0.1, thenDragTo: destination)
            }

            let hasExpanded = Polling.wait(timeout: 2, interval: 0.1) {
                guard let current = filterSheet.snapshotFrame else {
                    return false
                }
                return current.height >= initialHeight * 1.2
            }
            if hasExpanded {
                // 後續捲動會再確認可點
                _ = filterSheet.waitUntilStableAndHittable(timeout: 2, sampleInterval: 0.1)
                return
            }
        }

        let sheetDesc = filterSheet.snapshotFrame.map { "\($0)" } ?? "nil"
        let windowDesc = app.windows.firstMatch.snapshotFrame.map { "\($0)" } ?? "nil"
        try app.stopWithDiagnostics(
            "篩選 sheet 拖曳兩次後仍未展開 (sheet 框線: \(sheetDesc), 視窗框線: \(windowDesc))",
            file: file,
            line: line
        )
    }

    /// 依日期期間識別值取得對應的正體中文可見標籤字面值
    ///
    /// - Parameter periodID: 日期期間識別值
    /// - Returns: 可見標籤字串
    func datePeriodLabel(for periodID: String) -> String? {
        switch periodID {
        case "all":
            return "全部時間"

        case "thisWeek":
            return "本週"

        case "thisMonth":
            return "本月"

        case "lastMonth":
            return "上月"

        default:
            return nil
        }
    }
}
