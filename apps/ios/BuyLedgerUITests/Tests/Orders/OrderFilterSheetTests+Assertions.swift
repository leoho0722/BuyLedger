//
//  OrderFilterSheetTests+Assertions.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/10/18.
//

import XCTest

// MARK: - Internal Method

@MainActor
extension OrderFilterSheetTests {

    /// 切到訂單分頁並等待清單就緒
    ///
    /// - Parameters:
    ///   - app: 已啟動的 App
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 訂單清單的 Page Object
    func openOrders(
        _ app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> OrdersScreen {
        let root = RootNavigationScreen(app: app)
        if !root.goToOrders(file: file, line: line) {
            app.failWithDiagnostics("切到訂單分頁後畫面未就緒", file: file, line: line)
        }
        let orders = OrdersScreen(app: app)
        if !orders.waitUntilReady() {
            app.failWithDiagnostics("訂單清單根 identifier 逾時仍未出現", file: file, line: line)
        }
        return orders
    }

    /// 斷言篩選 sheet 內指定類別的選中狀態
    ///
    /// - Parameters:
    ///   - name: 類別名稱
    ///   - isSelected: 預期是否選中
    ///   - orders: 訂單清單的 Page Object
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func assertCategorySelected(
        _ name: String,
        isSelected: Bool,
        _ orders: OrdersScreen,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        if orders.isFilterCategorySelected(name) != isSelected {
            orders.app.failWithDiagnostics(
                "類別「\(name)」選中狀態應為 \(isSelected)",
                file: file,
                line: line
            )
        }
    }

    /// 斷言篩選入口的標題包含指定片段
    ///
    /// - Parameters:
    ///   - orders: 訂單清單的 Page Object
    ///   - fragment: 預期包含的文字
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func assertTrigger(
        _ orders: OrdersScreen,
        contains fragment: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        if !orders.filterTriggerLabel.contains(fragment) {
            orders.app.failWithDiagnostics(
                "篩選入口標題應包含「\(fragment)」，實際為「\(orders.filterTriggerLabel)」",
                file: file,
                line: line
            )
        }
    }

    /// 斷言清單實際列出的訂單編號與預期集合相同
    ///
    /// - Parameters:
    ///   - expected: 預期列出的訂單編號
    ///   - orders: 訂單清單的 Page Object
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func assertListedOrderIDs(
        _ expected: Set<String>,
        _ orders: OrdersScreen,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let listed = orders.collectListedOrderIDs()
        if listed != expected {
            orders.app.failWithDiagnostics(
                "清單應列出 \(expected.sorted())，實際為 \(listed.sorted())",
                file: file,
                line: line
            )
        }
    }
}
