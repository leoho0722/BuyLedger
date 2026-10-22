//
//  RootNavigationScreen.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 根導覽的 Page Object
struct RootNavigationScreen {

    // MARK: - Properties

    /// 受測 App
    let app: XCUIApplication

    /// 吸收兩種版面差異的導覽分流器
    private let navigator: AppNavigator

    // MARK: - Init

    /// 由受測 App 建立，並據以組出導覽分流器
    ///
    /// - Parameter app: 受測 App
    init(app: XCUIApplication) {
        self.app = app
        self.navigator = AppNavigator(app: app)
    }
}

// MARK: - Internal Method

extension RootNavigationScreen {

    /// 切到總覽頁，待其就緒才回傳
    ///
    /// - Parameters:
    ///   - timeout: 等待總覽頁就緒的秒數
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 總覽頁是否在逾時前就緒
    @discardableResult
    func goToDashboard(
        timeout: TimeInterval = 10,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Bool {
        go(
            to: .dashboard,
            timeout: timeout,
            file: file,
            line: line
        )
    }

    /// 切到訂單頁，待其就緒才回傳
    ///
    /// - Parameters:
    ///   - timeout: 等待訂單頁就緒的秒數
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 訂單頁是否在逾時前就緒
    @discardableResult
    func goToOrders(
        timeout: TimeInterval = 10,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Bool {
        go(
            to: .orders,
            timeout: timeout,
            file: file,
            line: line
        )
    }

    /// 切到開團頁，待其就緒才回傳
    ///
    /// - Parameters:
    ///   - timeout: 等待開團頁就緒的秒數
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 開團頁是否在逾時前就緒
    @discardableResult
    func goToCampaigns(
        timeout: TimeInterval = 10,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Bool {
        go(
            to: .campaigns,
            timeout: timeout,
            file: file,
            line: line
        )
    }

    /// 切到分析頁，待其就緒才回傳
    ///
    /// - Parameters:
    ///   - timeout: 等待分析頁就緒的秒數
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 分析頁是否在逾時前就緒
    @discardableResult
    func goToInsights(
        timeout: TimeInterval = 10,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Bool {
        go(
            to: .insights,
            timeout: timeout,
            file: file,
            line: line
        )
    }

    /// 切到更多與設定頁，待其就緒才回傳
    ///
    /// - Parameters:
    ///   - timeout: 等待更多頁就緒的秒數
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 更多頁是否在逾時前就緒
    @discardableResult
    func goToMore(
        timeout: TimeInterval = 10,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Bool {
        go(
            to: .more,
            timeout: timeout,
            file: file,
            line: line
        )
    }
}

// MARK: - Screen

extension RootNavigationScreen: Screen {

    /// 以 `BLAccessibilityID.Dashboard.root` 指定根導覽的就緒判定，啟動後預設停在總覽頁
    ///
    /// - Returns: 總覽頁根元素的 `identifier`
    var rootIdentifier: String {
        BLAccessibilityID.Dashboard.root
    }
}

// MARK: - Private Method

private extension RootNavigationScreen {

    /// 切頁後優先等待目的地根容器，未指定根容器的分頁才依版面等待選取態
    ///
    /// - Parameters:
    ///   - tab: 目標分頁
    ///   - timeout: 等待目標分頁就緒的秒數
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 目標分頁是否在逾時前就緒
    func go(
        to tab: AppNavigator.Tab,
        timeout: TimeInterval,
        file: StaticString,
        line: UInt
    ) -> Bool {
        let isSidebarLayout = navigator.isSidebarLayout
        let identifier = destinationRootIdentifier(for: tab)
        navigator.selectTab(tab, file: file, line: line)
        let deadline = Date.now.addingTimeInterval(timeout)
        repeat {
            if let identifier {
                if app.descendants(matching: .any)[identifier].exists {
                    return true
                }
            } else {
                let selection = isSidebarLayout
                    ? sidebarTabElement(for: tab)
                    : tabBarButtonElement(for: tab)
                if selection.exists && selection.isSelected {
                    return true
                }
            }
            _ = XCTWaiter().wait(for: [XCTestExpectation()], timeout: 0.1)
        } while Date.now < deadline
        return false
    }

    /// 用於判定切頁就緒的目的地根 identifier
    ///
    /// - Parameter tab: 目標分頁
    /// - Returns: 目的地根 identifier；未指定根容器的分頁回傳 `nil` 並沿用選取態判斷
    func destinationRootIdentifier(for tab: AppNavigator.Tab) -> String? {
        switch tab {
        case .dashboard:
            BLAccessibilityID.Dashboard.root

        case .orders:
            BLAccessibilityID.Orders.listRoot

        case .more:
            BLAccessibilityID.More.root

        case .campaigns, .insights:
            nil
        }
    }

    /// 側邊欄的分頁列元素
    ///
    /// - Parameter tab: 要查詢的分頁
    /// - Returns: 側邊欄中的分頁元素
    func sidebarTabElement(for tab: AppNavigator.Tab) -> XCUIElement {
        // 分頁列是合併朗讀的 `staticText`，因此以 `.any` 查詢
        app.descendants(matching: .any)[BLAccessibilityID.Root.tab(tab.identifierKey)]
    }

    /// 分頁列的系統 tab bar 按鈕
    ///
    /// - Parameter tab: 要查詢的分頁
    /// - Returns: 底部分頁列中的按鈕
    func tabBarButtonElement(for tab: AppNavigator.Tab) -> XCUIElement {
        app.tabBars.buttons.element(boundBy: tab.rawValue)
    }
}
