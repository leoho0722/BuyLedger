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
    /// - Returns: 訂單清單根容器的 identifier
    var rootIdentifier: String {
        BLAccessibilityID.Orders.listRoot
    }

    /// 是否正顯示沒有符合條件訂單的空狀態
    /// - Returns: 是否顯示空狀態
    var isEmptyStateShown: Bool {
        app.descendants(matching: .any)[BLAccessibilityID.Orders.listEmptyState].exists
    }

    /// 目前清單上可見的訂單列數量
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
    func tapAddOrder() {
        let button = app.buttons[BLAccessibilityID.Orders.addButton]
        button.waitUntilHittable()
        button.tap()
    }

    /// 選取指定狀態瀏覽膠囊
    /// - Parameter filterID: 狀態篩選的 identifier
    func selectStatusChip(filterID: String) {
        let chip = app.buttons[BLAccessibilityID.Orders.statusChip(filterID)]
        chip.waitUntilHittable()
        chip.tap()
    }

    /// 在系統搜尋欄輸入關鍵字
    /// - Parameter text: 要輸入的搜尋文字
    func search(_ text: String) {
        let field = app.searchFields.firstMatch
        field.waitUntilHittable()
        field.clearAndType(text, in: app)
    }

    /// 取指定訂單編號的清單列
    /// - Parameter orderID: 訂單編號
    /// - Returns: 對應的訂單列元素
    func orderRow(orderID: String) -> XCUIElement {
        app.descendants(matching: .any)[BLAccessibilityID.Orders.row(orderID: orderID)]
    }

    /// 點指定訂單編號的清單列進入詳情
    /// - Parameter orderID: 訂單編號
    func tapOrder(orderID: String) {
        let row = orderRow(orderID: orderID)
        row.waitUntilHittable()
        row.tap()
    }

    /// 清單是否含指定訂單編號的列
    /// - Parameters:
    ///   - orderID: 訂單編號
    ///   - timeout: 等待訂單列出現的秒數
    /// - Returns: 訂單列是否在逾時前出現
    @discardableResult
    func hasOrder(orderID: String, timeout: TimeInterval = 5) -> Bool {
        orderRow(orderID: orderID).waitForExistence(timeout: timeout)
    }

    /// 開啟整合篩選 sheet (compact 版面工具列入口)
    func openFilterSheet() {
        let button = app.buttons[BLAccessibilityID.Orders.filterButton]
        button.waitUntilHittable()
        button.tap()
    }

    /// 點工具列的 AI 商品明細總結入口
    func tapAiSummary() {
        // AI 總結是「更多操作」選單內的項目，先開選單再點該項
        let menu = app.buttons[BLAccessibilityID.Orders.batchMenuButton]
        menu.waitUntilHittable()
        menu.tap()
        app.tapMenuItem(BLAccessibilityID.Orders.aiSummaryButton)
    }
}
