//
//  CustomersScreen.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 客戶名單頁的 Page Object
///
/// 以 accessibility identifier 對外暴露 Top 卡、客戶列與空狀態的語意操作，元素查詢細節不外洩給測試檔；
/// 客戶名同時是列的業務鍵 (``CustomerRow`` 以姓名為 id)，切換語言後 identifier 不變，故 Page Object 不分版面
struct CustomersScreen: Screen {

    // MARK: - Data Properties

    /// 受測 App
    let app: XCUIApplication

    // MARK: - Computed Properties

    /// 判定客戶名單已就緒的根 identifier (名單捲動容器)
    var rootIdentifier: String {
        BLAccessibilityID.Customers.listRoot
    }

    /// 是否正顯示尚無客戶的空狀態
    var isEmptyStateShown: Bool {
        app.descendants(matching: .any)[BLAccessibilityID.Customers.listEmptyState].exists
    }
}

// MARK: - Internal Method

@MainActor
extension CustomersScreen {

    /// 從更多分頁導到客戶頁
    ///
    /// 客戶名單是「更多」分頁下的 push 目的地：先切到更多分頁再點客戶列；
    /// 是否成功抵達交由呼叫端以 ``Screen/waitUntilReady(timeout:)`` 判定並附診斷
    /// - Parameter app: 受測 App
    /// - Returns: 客戶頁 Page Object
    static func open(from app: XCUIApplication) -> CustomersScreen {
        let root = RootNavigationScreen(app: app)
        root.goToMore()

        let entry = app.descendants(matching: .any)[BLAccessibilityID.More.row(.customers)]
        entry.waitUntilHittable()
        entry.tap()

        return CustomersScreen(app: app)
    }

    /// 取指定客戶名的 Top 卡片
    ///
    /// 合併朗讀的卡片歸為 staticText，故以 any 查詢而非 otherElements
    /// - Parameter customerName: 客戶名這個業務鍵
    /// - Returns: 對應的 Top 卡片元素
    func topCard(customerName: String) -> XCUIElement {
        app.descendants(matching: .any)[BLAccessibilityID.Customers.topCard(customerName: customerName)]
    }

    /// 取指定客戶名的全部客戶列
    ///
    /// 合併朗讀的列歸為 staticText，故以 any 查詢而非 otherElements
    /// - Parameter customerName: 客戶名這個業務鍵
    /// - Returns: 對應的客戶列元素
    func customerRow(customerName: String) -> XCUIElement {
        app.descendants(matching: .any)[BLAccessibilityID.Customers.row(customerName: customerName)]
    }

    /// 名單是否含指定客戶名的列
    ///
    /// 全部客戶列以 `LazyVStack` 呈現，落在可視範圍外的列尚未進 accessibility 樹；先直接查，查不到再捲向它後複查
    /// - Parameters:
    ///   - customerName: 客戶名這個業務鍵
    ///   - timeout: 逾時秒數
    /// - Returns: 逾時前該列是否出現
    @discardableResult
    func hasCustomer(customerName: String, timeout: TimeInterval = 5) -> Bool {
        let row = customerRow(customerName: customerName)
        // LazyVStack 尚未渲染的列可能有無效 frame，查 hittability 會直接報錯；這裡只向上滑並查存在，不查可點
        var attempts = 0
        while !row.exists, attempts < 8 {
            rootElement.swipeUp()
            attempts += 1
        }
        return row.waitForExistence(timeout: timeout)
    }

    /// 點指定客戶名的客戶列，深連結到該客戶的訂單
    ///
    /// 名單在 Top 卡之下，可能落在可視範圍外，先在名單捲動容器內捲到可點再點
    /// - Parameter customerName: 客戶名這個業務鍵
    func tapCustomer(customerName: String) {
        let row = customerRow(customerName: customerName)
        app.scrollToHittable(row, within: rootElement)
        row.waitUntilHittable()
        row.tap()
    }
}
