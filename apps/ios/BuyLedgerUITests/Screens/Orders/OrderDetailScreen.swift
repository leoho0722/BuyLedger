//
//  OrderDetailScreen.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 訂單詳情頁的 Page Object
struct OrderDetailScreen {

    // MARK: - Properties

    /// 受測 App
    let app: XCUIApplication
}

// MARK: - Computed Properties

@MainActor
extension OrderDetailScreen {

    /// 詳情導覽列的更多操作按鈕
    var moreButton: XCUIElement {
        app.buttons[BLAccessibilityID.Orders.detailMoreButton]
    }

    /// 詳情導覽列的訂單狀態選單
    var statusMenuButton: XCUIElement {
        app.buttons[BLAccessibilityID.Orders.detailStatusMenuButton]
    }
}

// MARK: - Internal Method

@MainActor
extension OrderDetailScreen {

    /// 取得指定種類的詳情財務摘要卡
    ///
    /// - Parameter tile: 財務摘要卡種類
    /// - Returns: 對應的摘要卡元素
    func summaryTile(_ tile: BLAccessibilityID.Orders.SummaryTile) -> XCUIElement {
        app.descendants(matching: .any)[BLAccessibilityID.Orders.detailSummaryTile(tile)]
    }

    /// 詳情根元素目前顯示的訂單識別碼
    ///
    /// - Returns: 詳情根的可及性值；根元素不存在或沒有值時為缺值
    func displayedOrderID() -> String? {
        let element = app.descendants(matching: .any)[BLAccessibilityID.Orders.detailRoot]
            .firstMatch
        guard element.exists else {
            return nil
        }
        return element.value as? String
    }

    /// 開啟更多選單後進入訂單編輯表單
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 已就緒的編輯表單
    /// - Throws: 更多選單或編輯表單未就緒時丟出測試錯誤
    @discardableResult
    func openEdit(
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) -> OrderEditScreen {
        try openMoreMenu(file: file, line: line)
        return try tapEdit(file: file, line: line)
    }

    /// 開啟更多選單後進入合併候選清單
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 已就緒的合併候選清單
    /// - Throws: 更多選單或候選清單未就緒時丟出測試錯誤
    @discardableResult
    func openMerge(
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) -> MergeFlowScreen {
        try openMoreMenu(file: file, line: line)
        return try tapMerge(file: file, line: line)
    }

    /// 讀取指定財務摘要卡的 accessibility value
    ///
    /// - Parameter tile: 要讀取的摘要卡種類
    /// - Returns: 該卡的 accessibility value；元素不存在時為 `nil`
    func summaryValue(_ tile: BLAccessibilityID.Orders.SummaryTile) -> String? {
        let element = summaryTile(tile)
        guard element.waitForExistence(timeout: 10) else {
            return nil
        }
        return element.value as? String
    }

    /// 開啟「更多」操作選單 (編輯／合併／刪除)
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    func openMoreMenu(file: StaticString = #filePath, line: UInt = #line) throws(UITestError) {
        let button = moreButton
        try button.tapAfterWaiting(in: app, file: file, line: line)
    }

    /// 點更多選單的編輯
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 已就緒的目的地 Page Object
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    @discardableResult
    func tapEdit(
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) -> OrderEditScreen {
        try app.tapMenuItem(BLAccessibilityID.Orders.detailEditButton, file: file, line: line)
        let screen = OrderEditScreen(app: app)
        try screen.requireReady(file: file, line: line)
        return screen
    }

    /// 點更多選單的合併
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 已就緒的目的地 Page Object
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    @discardableResult
    func tapMerge(
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) -> MergeFlowScreen {
        try app.tapMenuItem(BLAccessibilityID.Orders.detailMergeButton, file: file, line: line)
        let screen = MergeFlowScreen(app: app)
        try screen.requireReady(file: file, line: line)
        return screen
    }

    /// 點更多選單的刪除
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    func tapDelete(file: StaticString = #filePath, line: UInt = #line) throws(UITestError) {
        try app.tapMenuItem(BLAccessibilityID.Orders.detailDeleteButton, file: file, line: line)
        guard waitForDeleteConfirmation() else {
            try app.stopWithDiagnostics("訂單刪除確認未呈現", file: file, line: line)
        }
    }

    /// 等待刪除確認 alert 呈現
    ///
    /// - Parameter timeout: 等待 alert 出現的秒數
    /// - Returns: alert 是否在逾時前出現
    func waitForDeleteConfirmation(timeout: TimeInterval = 5) -> Bool {
        app.alertPresented(timeout: timeout)
    }

    /// 等待刪除確認 alert 消失
    ///
    /// - Parameter timeout: 等待 alert 消失的秒數
    /// - Returns: alert 是否在逾時前消失
    func waitForDeleteConfirmationDismissal(timeout: TimeInterval = 5) -> Bool {
        app.alertDismissed(timeout: timeout)
    }

    /// 點刪除確認 alert 的取消按鈕
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    func cancelDelete(file: StaticString = #filePath, line: UInt = #line) throws(UITestError) {
        try app.tapAlertButton(label: "取消", file: file, line: line)
    }
}

// MARK: - ScreenProtocol

extension OrderDetailScreen: ScreenProtocol {

    /// 判定詳情頁已就緒的根 identifier (詳情捲動容器)
    var rootIdentifier: String {
        BLAccessibilityID.Orders.detailRoot
    }
}
