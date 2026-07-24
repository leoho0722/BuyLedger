//
//  OrdersScreen.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 訂單清單頁的 Page Object
///
/// 以 accessibility identifier 對外暴露新增、狀態篩選、搜尋與訂單列的語意操作，元素查詢細節不外洩給測試檔；
/// compact 分頁列與 regular 側邊欄兩種版面共用同一組 identifier，故 Page Object 不分版面
struct OrdersScreen: Screen {

    // MARK: - Data Properties

    /// 受測 App
    let app: XCUIApplication

    // MARK: - Computed Properties

    /// 判定訂單清單已就緒的根 identifier (清單捲動容器)
    var rootIdentifier: String {
        BLAccessibilityID.Orders.listRoot
    }

    /// 是否正顯示沒有符合條件訂單的空狀態
    var isEmptyStateShown: Bool {
        app.descendants(matching: .any)[BLAccessibilityID.Orders.listEmptyState].exists
    }

    /// 目前清單上可見的訂單列數量
    ///
    /// 訂單列以訂單編號為業務鍵、identifier 前綴固定，故以 BEGINSWITH 前綴計數；合併朗讀的列歸為 staticText，
    /// 用 any 查詢而非 otherElements
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
    ///
    /// - Parameter filterID: 狀態篩選的 id (「all」或某 `OrderStatus` 的 rawValue，皆為不隨語言變動的業務鍵)
    func selectStatusChip(filterID: String) {
        let chip = app.buttons[BLAccessibilityID.Orders.statusChip(filterID)]
        chip.waitUntilHittable()
        chip.tap()
    }

    /// 在系統搜尋欄輸入關鍵字
    ///
    /// 系統 `.searchable` 搜尋欄掛不上穩定 identifier，改以 `searchFields` 型別定位 (與 App 端註解一致)，跨語言皆有效
    /// - Parameter text: 要輸入的搜尋文字
    func search(_ text: String) {
        let field = app.searchFields.firstMatch
        field.waitUntilHittable()
        field.clearAndType(text, in: app)
    }

    /// 取指定訂單編號的清單列
    ///
    /// 合併朗讀的列歸為 staticText，故以 any 查詢而非 otherElements
    /// - Parameter orderID: 訂單編號這個業務鍵
    /// - Returns: 對應的列元素
    func orderRow(orderID: String) -> XCUIElement {
        app.descendants(matching: .any)[BLAccessibilityID.Orders.row(orderID: orderID)]
    }

    /// 點指定訂單編號的清單列進入詳情
    /// - Parameter orderID: 訂單編號這個業務鍵
    func tapOrder(orderID: String) {
        let row = orderRow(orderID: orderID)
        row.waitUntilHittable()
        row.tap()
    }

    /// 清單是否含指定訂單編號的列
    /// - Parameters:
    ///   - orderID: 訂單編號這個業務鍵
    ///   - timeout: 逾時秒數
    /// - Returns: 逾時前該列是否出現
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
    ///
    /// 未開啟 AI 時彈未開啟提示 alert、開啟時推出總結 sheet，分支由呼叫端斷言
    func tapAiSummary() {
        // AI 總結是「更多操作」選單內的項目，先開選單再點該項
        let menu = app.buttons[BLAccessibilityID.Orders.batchMenuButton]
        menu.waitUntilHittable()
        menu.tap()
        app.tapMenuItem(BLAccessibilityID.Orders.aiSummaryButton)
    }
}
