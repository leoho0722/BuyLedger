//
//  DashboardScreen.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 總覽頁的 Page Object
///
/// 以 accessibility identifier 對外暴露空狀態、KPI 卡與近期訂單的語意操作，元素查詢細節不外洩給測試檔
struct DashboardScreen: Screen {

    // MARK: - Data Properties

    /// 受測 App
    let app: XCUIApplication

    // MARK: - Computed Properties

    /// 判定畫面已就緒的根元素 identifier
    var rootIdentifier: String {
        BLAccessibilityID.Dashboard.root
    }

    /// 是否正顯示尚無資料的引導空狀態
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
    ///
    /// KPI 卡是合併朗讀的單一元素，主要數值放在該元素的 value
    /// - Parameter kpi: 目標 KPI 指標
    /// - Returns: 該卡 value 字串，元素不存在時回傳空字串
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
    /// - Parameter orderID: 訂單編號這個業務鍵
    /// - Returns: 對應的列元素
    func recentOrderRow(orderID: String) -> XCUIElement {
        // 合併朗讀的列在 XCUITest 歸為 staticText，故以 any 查詢而非 otherElements
        app.descendants(matching: .any)[BLAccessibilityID.Dashboard.recentOrderRow(orderID: orderID)]
    }

    /// 點近期訂單中指定訂單編號的列
    /// - Parameter orderID: 訂單編號這個業務鍵
    func tapRecentOrder(orderID: String) {
        let row = recentOrderRow(orderID: orderID)
        row.waitUntilHittable()
        row.tap()
    }
}
