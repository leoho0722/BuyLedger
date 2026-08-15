//
//  RootNavigationScreen.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 根導覽的 Page Object
struct RootNavigationScreen: Screen {

    // MARK: - Data Properties

    /// 受測 App
    let app: XCUIApplication

    /// 吸收兩種版面差異的導覽分流器
    let navigator: AppNavigator

    // MARK: - Init

    /// 由受測 App 建立，並據以組出導覽分流器
    init(app: XCUIApplication) {
        self.app = app
        self.navigator = AppNavigator(app: app)
    }

    // MARK: - Computed Properties

    /// 判定根導覽就緒的根 identifier
    /// - Returns: 根導覽使用的 identifier
    var rootIdentifier: String {
        BLAccessibilityID.Dashboard.root
    }
}

// MARK: - Internal Method

extension RootNavigationScreen {

    /// 切到總覽頁，待其就緒才回傳
    /// - Parameter timeout: 等待總覽頁就緒的秒數
    /// - Returns: 總覽頁是否在逾時前就緒
    @discardableResult
    func goToDashboard(timeout: TimeInterval = 10) -> Bool {
        go(to: .dashboard, timeout: timeout)
    }

    /// 切到訂單頁，待其就緒才回傳
    /// - Parameter timeout: 等待訂單頁就緒的秒數
    /// - Returns: 訂單頁是否在逾時前就緒
    @discardableResult
    func goToOrders(timeout: TimeInterval = 10) -> Bool {
        go(to: .orders, timeout: timeout)
    }

    /// 切到開團頁，待其就緒才回傳
    /// - Parameter timeout: 等待開團頁就緒的秒數
    /// - Returns: 開團頁是否在逾時前就緒
    @discardableResult
    func goToCampaigns(timeout: TimeInterval = 10) -> Bool {
        go(to: .campaigns, timeout: timeout)
    }

    /// 切到分析頁，待其就緒才回傳
    /// - Parameter timeout: 等待分析頁就緒的秒數
    /// - Returns: 分析頁是否在逾時前就緒
    @discardableResult
    func goToInsights(timeout: TimeInterval = 10) -> Bool {
        go(to: .insights, timeout: timeout)
    }

    /// 切到更多與設定頁，待其就緒才回傳
    /// - Parameter timeout: 等待更多頁就緒的秒數
    /// - Returns: 更多頁是否在逾時前就緒
    @discardableResult
    func goToMore(timeout: TimeInterval = 10) -> Bool {
        go(to: .more, timeout: timeout)
    }

    /// 查詢分頁是否為選取態，供選取態斷言使用
    /// - Parameter tab: 要查詢的分頁
    /// - Returns: 分頁是否為選取態
    func isTabSelected(_ tab: AppNavigator.Tab) -> Bool {
        if navigator.isSidebarLayout {
            return sidebarTabElement(for: tab).isSelected
        }
        if let identifier = destinationRootIdentifier(for: tab) {
            return app.descendants(matching: .any)[identifier].exists
        }
        return tabBarButtonElement(for: tab).isSelected
    }
}

// MARK: - Private Method

private extension RootNavigationScreen {

    /// 切到指定分頁並等待就緒
    /// - Parameters:
    ///   - tab: 目標分頁
    ///   - timeout: 等待目標分頁就緒的秒數
    /// - Returns: 目標分頁是否在逾時前就緒
    func go(to tab: AppNavigator.Tab, timeout: TimeInterval) -> Bool {
        navigator.selectTab(tab)
        if let identifier = destinationRootIdentifier(for: tab) {
            return app.descendants(matching: .any)[identifier].waitForExistence(timeout: timeout)
        }
        return selectionElement(for: tab).wait(
            for: NSPredicate(format: "isSelected == true"), timeout: timeout)
    }

    /// 目的地畫面的根 identifier
    /// - Parameter tab: 目標分頁
    /// - Returns: 目的地根 identifier；底部 tab bar 分頁回傳 `nil`
    func destinationRootIdentifier(for tab: AppNavigator.Tab) -> String? {
        switch tab {
        case .dashboard:
            BLAccessibilityID.Dashboard.root

        case .more:
            BLAccessibilityID.More.root

        case .orders, .campaigns, .insights:
            nil
        }
    }

    /// 依當前版面取承載選取態的元素
    /// - Parameter tab: 要查詢的分頁
    /// - Returns: 承載分頁選取態的 UI 元素
    func selectionElement(for tab: AppNavigator.Tab) -> XCUIElement {
        if navigator.isSidebarLayout {
            return sidebarTabElement(for: tab)
        }
        return tabBarButtonElement(for: tab)
    }

    /// 側邊欄的分頁列元素
    /// - Parameter tab: 要查詢的分頁
    /// - Returns: 側邊欄中的分頁元素
    func sidebarTabElement(for tab: AppNavigator.Tab) -> XCUIElement {
        // 分頁列是合併朗讀的 staticText，因此以 any 查詢。
        app.descendants(matching: .any)[BLAccessibilityID.Root.tab(tab.identifierKey)]
    }

    /// 分頁列的系統 tab bar 按鈕
    /// - Parameter tab: 要查詢的分頁
    /// - Returns: 底部分頁列中的按鈕
    func tabBarButtonElement(for tab: AppNavigator.Tab) -> XCUIElement {
        app.tabBars.buttons.element(boundBy: tab.rawValue)
    }
}
