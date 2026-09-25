//
//  OrdersScreen.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 訂單清單頁的 Page Object
struct OrdersScreen: Screen {

    // MARK: - Data Properties

    /// 受測 App
    let app: XCUIApplication

    // MARK: - Computed Properties

    /// 判定訂單清單已就緒的根 identifier (清單捲動容器)
    ///
    /// - Returns: 訂單清單根容器的 identifier
    var rootIdentifier: String {
        BLAccessibilityID.Orders.listRoot
    }

    /// 是否正顯示沒有符合條件訂單的空狀態
    ///
    /// - Returns: 是否顯示空狀態
    var isEmptyStateShown: Bool {
        app.descendants(matching: .any)[BLAccessibilityID.Orders.listEmptyState].exists
    }

    /// 目前清單上可見的訂單列數量
    ///
    /// - Returns: 目前可見的訂單列數量
    var visibleOrderCount: Int {
        let prefix = BLAccessibilityID.Orders.row(orderID: "")
        let predicate = NSPredicate(format: "identifier BEGINSWITH %@", prefix)

        return app.descendants(matching: .any).matching(predicate).count
    }
}

// MARK: - Internal Method

@MainActor
extension OrdersScreen {

    /// 點工具列的新增訂單
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func tapAddOrder(file: StaticString = #filePath, line: UInt = #line) {
        let button = app.buttons[BLAccessibilityID.Orders.addButton]
        button.tapAfterWaiting(in: app, file: file, line: line)
    }

    /// 選取指定狀態瀏覽膠囊
    ///
    /// - Parameters:
    ///   - filterID: 狀態篩選的 identifier
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func selectStatusChip(
        filterID: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let chip = app.buttons[BLAccessibilityID.Orders.statusChip(filterID)]
        chip.tapAfterWaiting(in: app, file: file, line: line)
    }

    /// 在系統搜尋欄輸入關鍵字
    ///
    /// - Parameters:
    ///   - text: 要輸入的搜尋文字
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func search(
        _ text: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let field = app.searchFields.firstMatch
        field.clearAndType(
            text,
            in: app,
            file: file,
            line: line
        )
    }

    /// 取指定訂單編號的清單列
    ///
    /// - Parameter orderID: 訂單編號
    /// - Returns: 對應的訂單列元素
    func orderRow(orderID: String) -> XCUIElement {
        app.descendants(matching: .any)[BLAccessibilityID.Orders.row(orderID: orderID)]
    }

    /// 點指定訂單編號的清單列進入詳情
    ///
    /// - Parameters:
    ///   - orderID: 訂單編號
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func tapOrder(
        orderID: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let row = orderRow(orderID: orderID)
        row.tapAfterWaiting(in: app, file: file, line: line)
    }

    /// 清單是否含指定訂單編號的列
    ///
    /// - Parameters:
    ///   - orderID: 訂單編號
    ///   - timeout: 等待訂單列出現的秒數
    /// - Returns: 訂單列是否在逾時前出現
    func hasOrder(orderID: String, timeout: TimeInterval = 5) -> Bool {
        orderRow(orderID: orderID).waitForExistence(timeout: timeout)
    }

    /// 開啟整合篩選 sheet (compact 版面工具列入口)
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func openFilterSheet(file: StaticString = #filePath, line: UInt = #line) {
        let button = app.buttons[BLAccessibilityID.Orders.filterButton]
        button.tapAfterWaiting(in: app, file: file, line: line)
    }

    /// 點工具列的 AI 商品明細總結入口
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 是否在逾時前點到 AI 商品明細總結項目
    @discardableResult
    func tapAiSummary(file: StaticString = #filePath, line: UInt = #line) -> Bool {
        // AI 總結是「更多操作」選單內的項目，先開選單再點該項
        let menu = app.buttons[BLAccessibilityID.Orders.batchMenuButton]
        menu.tapAfterWaiting(in: app, file: file, line: line)
        return app.tapMenuItem(
            BLAccessibilityID.Orders.aiSummaryButton,
            file: file,
            line: line
        )
    }
}
