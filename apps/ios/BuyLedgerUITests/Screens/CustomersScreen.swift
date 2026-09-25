//
//  CustomersScreen.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 客戶名單頁的 Page Object
struct CustomersScreen: Screen {

    // MARK: - Data Properties

    /// 受測 App
    let app: XCUIApplication

    // MARK: - Computed Properties

    /// 判定客戶名單已就緒的根 identifier (名單捲動容器)
    ///
    /// - Returns: 客戶名單根容器的 identifier
    var rootIdentifier: String {
        BLAccessibilityID.Customers.listRoot
    }

    /// 是否正顯示尚無客戶的空狀態
    ///
    /// - Returns: 是否顯示空狀態
    var isEmptyStateShown: Bool {
        app.descendants(matching: .any)[BLAccessibilityID.Customers.listEmptyState].exists
    }
}

// MARK: - Internal Method

@MainActor
extension CustomersScreen {

    /// 從更多分頁導到客戶頁
    ///
    /// - Parameters:
    ///   - app: 受測 App
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 客戶頁的 Page Object
    static func open(
        from app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> CustomersScreen {
        let root = RootNavigationScreen(app: app)
        root.goToMore(file: file, line: line)

        let entry = app.descendants(matching: .any)[BLAccessibilityID.More.row(.customers)]
        entry.tapAfterWaiting(in: app, file: file, line: line)

        return CustomersScreen(app: app)
    }

    /// 取指定客戶名的 Top 卡片
    ///
    /// - Parameter customerName: 客戶名稱
    /// - Returns: 對應的 Top 卡片元素
    func topCard(customerName: String) -> XCUIElement {
        app.descendants(matching: .any)[
            BLAccessibilityID.Customers.topCard(customerName: customerName)
        ]
    }

    /// 取指定客戶名的全部客戶列
    ///
    /// - Parameter customerName: 客戶名稱
    /// - Returns: 對應的客戶列元素
    func customerRow(customerName: String) -> XCUIElement {
        app.descendants(matching: .any)[BLAccessibilityID.Customers.row(customerName: customerName)]
    }

    /// 名單是否含指定客戶名的列
    ///
    /// - Parameters:
    ///   - customerName: 客戶名稱
    ///   - timeout: 等待客戶列出現的秒數
    /// - Returns: 客戶列是否在逾時前出現
    func hasCustomer(customerName: String, timeout: TimeInterval = 5) -> Bool {
        let row = customerRow(customerName: customerName)
        // 未渲染的列可能沒有有效 frame，只檢查是否存在
        var attempts = 0
        while !row.exists, attempts < 8 {
            rootElement.swipeUp()
            attempts += 1
        }
        return row.waitForExistence(timeout: timeout)
    }

    /// 點指定客戶名的客戶列，深連結到該客戶的訂單
    ///
    /// - Parameters:
    ///   - customerName: 客戶名稱
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func tapCustomer(
        customerName: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let row = customerRow(customerName: customerName)
        app.scrollToHittable(row, within: rootElement)
        row.tapAfterWaiting(in: app, file: file, line: line)
    }
}
