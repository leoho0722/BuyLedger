//
//  CustomersScreen.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 客戶名單頁的 Page Object
struct CustomersScreen {

    // MARK: - Properties

    /// 受測 App
    let app: XCUIApplication
}

// MARK: - Internal Method

@MainActor
extension CustomersScreen {

    /// 從更多分頁導到客戶頁，等待清單、空狀態、載入中或載入失敗就緒
    ///
    /// - Parameters:
    ///   - app: 受測 App
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 客戶頁的 Page Object
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    @discardableResult
    static func open(
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) -> CustomersScreen {
        let root = RootNavigationScreen(app: app)
        try root.goToMore(file: file, line: line)

        let entry = app.descendants(matching: .any)[BLAccessibilityID.More.row(.customers)]
        try entry.tapAfterWaiting(in: app, file: file, line: line)

        try root.requireForeground(
            identifiers: [
                BLAccessibilityID.Customers.listEmptyState,
                BLAccessibilityID.Customers.listLoadFailureRetryButton,
                BLAccessibilityID.Customers.listLoading,
            ],
            identifierPrefixes: [
                BLAccessibilityID.Customers.row(customerName: ""),
                BLAccessibilityID.Customers.topCard(customerName: ""),
            ],
            message: "客戶清單前景內容未就緒",
            file: file,
            line: line
        )
        return CustomersScreen(app: app)
    }

    /// 捲動露出指定客戶名的客戶列後點擊，切到該客戶的訂單
    ///
    /// - Parameters:
    ///   - customerName: 客戶名稱
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    func tapCustomer(
        customerName: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        let row = customerRow(customerName: customerName)
        try app.scrollToHittable(row, within: rootElement, file: file, line: line)
        try row.tapAfterWaiting(in: app, file: file, line: line)
    }

    /// 等待客戶名單的空狀態出現
    ///
    /// - Parameter timeout: 等待空狀態出現的秒數
    /// - Returns: 空狀態是否在逾時前出現
    func hasEmptyState(timeout: TimeInterval = 10) -> Bool {
        app.descendants(matching: .any)[BLAccessibilityID.Customers.listEmptyState]
            .waitForExistence(timeout: timeout)
    }

    /// 等待客戶名單顯示載入中
    ///
    /// - Parameter timeout: 等待載入指示器出現的秒數
    /// - Returns: 載入指示器是否在逾時前出現
    func waitForLoading(timeout: TimeInterval = 10) -> Bool {
        app.descendants(matching: .any)[BLAccessibilityID.Customers.listLoading]
            .waitForExistence(timeout: timeout)
    }

    /// 點客戶名單載入失敗分支的重試按鈕
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 重試按鈕無法點擊時丟出測試錯誤
    func tapRetry(file: StaticString = #filePath, line: UInt = #line) throws(UITestError) {
        let button = app.buttons[BLAccessibilityID.Customers.listLoadFailureRetryButton]
        try button.tapAfterWaiting(in: app, file: file, line: line)
    }

    /// 等待指定客戶列可點並讀取其 accessibility label
    ///
    /// - Parameters:
    ///   - customerName: 客戶名稱
    ///   - timeout: 等待客戶列可點的秒數
    /// - Returns: 客戶列的 accessibility label；列未能就緒時為 `nil`
    func customerRowLabel(customerName: String, timeout: TimeInterval = 10) -> String? {
        let row = customerRow(customerName: customerName)
        guard row.waitUntilHittable(timeout: timeout) else {
            return nil
        }
        return row.label
    }
}

// MARK: - ScreenProtocol

extension CustomersScreen: ScreenProtocol {

    /// 判定客戶名單已就緒的根元素 identifier (捲動容器)
    var rootIdentifier: String {
        BLAccessibilityID.Customers.listRoot
    }
}

// MARK: - Private Method

@MainActor
private extension CustomersScreen {

    /// 取指定客戶名的客戶列
    ///
    /// - Parameter customerName: 客戶名稱
    /// - Returns: 對應的客戶列元素
    func customerRow(customerName: String) -> XCUIElement {
        app.descendants(matching: .any)[BLAccessibilityID.Customers.row(customerName: customerName)]
    }
}
