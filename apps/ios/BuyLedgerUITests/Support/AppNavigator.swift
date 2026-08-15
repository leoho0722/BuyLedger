//
//  AppNavigator.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 吸收 compact 分頁列與 regular 側邊欄兩套導覽樹的差異
struct AppNavigator {

    // MARK: - Data Properties

    /// 受測 App
    let app: XCUIApplication

    // MARK: - Computed Properties

    /// 目前是否為側邊欄版面 (iPad 全螢幕)
    /// - Returns: 目前是否使用側邊欄版面
    var isSidebarLayout: Bool {
        let sidebar = app.descendants(matching: .any)[BLAccessibilityID.Root.sidebar]
        if sidebar.waitForExistence(timeout: 5) {
            return true
        }
        return !app.tabBars.firstMatch.exists
    }
}

// MARK: - Internal Method

extension AppNavigator {

    /// 切換到指定分頁
    /// - Parameter tab: 目標分頁
    func selectTab(_ tab: Tab) {
        if isSidebarLayout {
            // 分頁列是合併朗讀的 staticText，因此以 any 查詢。
            let row = app.descendants(matching: .any)[BLAccessibilityID.Root.tab(tab.identifierKey)]
            row.waitUntilHittable()
            row.tap()
        } else {
            tabBarButton(for: tab).tap()
        }
    }
}

// MARK: - Nested Types

extension AppNavigator {

    /// 分頁列與側邊欄共用的分頁 key
    enum Tab: Int, CaseIterable {

        // MARK: - Cases

        /// 總覽頁
        case dashboard

        /// 訂單頁
        case orders

        /// 開團頁
        case campaigns

        /// 分析頁
        case insights

        /// 更多與設定頁
        case more

        // MARK: - Computed Properties

        /// 對應的 identifier key，與 App 端 `RootTab` 同序
        /// - Returns: 對應的 accessibility identifier key
        var identifierKey: BLAccessibilityID.Root.Tab {
            switch self {
            case .dashboard:
                .dashboard
            case .orders:
                .orders
            case .campaigns:
                .campaigns
            case .insights:
                .insights
            case .more:
                .more
            }
        }
    }
}

// MARK: - Private Method

private extension AppNavigator {

    /// 依宣告順序取底部分頁列的按鈕
    /// - Parameter tab: 要查詢的分頁
    /// - Returns: 底部分頁列中的按鈕
    func tabBarButton(for tab: Tab) -> XCUIElement {
        app.tabBars.buttons.element(boundBy: tab.rawValue)
    }
}
