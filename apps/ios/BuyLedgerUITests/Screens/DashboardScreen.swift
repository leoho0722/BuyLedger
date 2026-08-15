//
//  DashboardScreen.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 總覽頁的 Page Object
struct DashboardScreen: Screen {

    // MARK: - Data Properties

    /// 受測 App
    let app: XCUIApplication

    // MARK: - Computed Properties

    /// 判定畫面已就緒的根元素 identifier
    /// - Returns: 總覽頁根元素的 identifier
    var rootIdentifier: String {
        BLAccessibilityID.Dashboard.root
    }

    /// 是否正顯示尚無資料的引導空狀態
    /// - Returns: 是否顯示空狀態
    var isEmptyStateShown: Bool {
        app.descendants(matching: .any)[BLAccessibilityID.Dashboard.emptyState].exists
    }
}

// MARK: - Internal Method

@MainActor
extension DashboardScreen {

    /// 點空狀態的「建立第一筆訂單」
    func tapCreateFirstOrder() {
        let button = app.buttons[BLAccessibilityID.Dashboard.emptyStateActionButton]
        button.waitUntilHittable()
        button.tap()
    }

    /// 讀取指定 KPI 卡的 accessibility value
    /// - Parameter kpi: 要讀取的 KPI 種類
    /// - Returns: KPI 卡的 accessibility value；元素不存在時為空字串
    func kpiValue(_ kpi: BLAccessibilityID.Dashboard.KPI) -> String {
        // 合併朗讀的卡片在 XCUITest 歸為 staticText，故以 any 查詢而非 otherElements
        let tile = app.descendants(matching: .any)[BLAccessibilityID.Dashboard.kpiTile(kpi)]
        guard tile.waitForExistence(timeout: 10) else {
            return ""
        }
        return (tile.value as? String) ?? ""
    }

    /// 點近期訂單的「查看全部」
    func tapSeeAllRecentOrders() {
        let button = app.buttons[BLAccessibilityID.Dashboard.recentOrdersSeeAllButton]
        button.waitUntilHittable()
        button.tap()
    }

    /// 取近期訂單中指定訂單編號的列
    /// - Parameter orderID: 訂單編號
    /// - Returns: 對應的近期訂單列元素
    func recentOrderRow(orderID: String) -> XCUIElement {
        // 合併朗讀的列在 XCUITest 歸為 staticText，故以 any 查詢而非 otherElements
        app.descendants(matching: .any)[
            BLAccessibilityID.Dashboard.recentOrderRow(orderID: orderID)
        ]
    }

    /// 點近期訂單中指定訂單編號的列
    /// - Parameter orderID: 訂單編號
    func tapRecentOrder(orderID: String) {
        let row = recentOrderRow(orderID: orderID)
        row.waitUntilHittable()
        row.tap()
    }
}
