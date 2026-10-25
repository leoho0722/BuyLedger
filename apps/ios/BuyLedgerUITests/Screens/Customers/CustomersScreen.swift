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

    /// 捲動露出指定客戶名的客戶列後點擊，切到該客戶的訂單
    ///
    /// - Parameters:
    ///   - customerName: 客戶名稱
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func tapCustomer(customerName: String, file: StaticString = #filePath, line: UInt = #line) {
        let row = customerRow(customerName: customerName)
        guard app.scrollToHittable(row, within: rootElement) else {
            app.failWithDiagnostics("捲動後客戶列仍未穩定或不可點", file: file, line: line)
            return
        }
        row.tapAfterWaiting(in: app, file: file, line: line)
    }
}

// MARK: - Screen

extension CustomersScreen: Screen {

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
