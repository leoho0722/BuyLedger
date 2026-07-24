//
//  RootNavigationScreen.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 根導覽的 Page Object
///
/// 對外只暴露「切到某分頁」的語意操作與選取態查詢，compact 分頁列與 regular 側邊欄的差異由內部持有的
/// ``AppNavigator`` 吸收，讓同一份流程測試在兩種版面都能跑
struct RootNavigationScreen: Screen {

    // MARK: - Data Properties

    /// 受測 App
    let app: XCUIApplication

    /// 吸收兩種版面差異的導覽分流器
    let navigator: AppNavigator

    // MARK: - Init

    /// 由受測 App 建立，並據以組出導覽分流器
    /// - Parameter app: 受測 App
    init(app: XCUIApplication) {
        self.app = app
        self.navigator = AppNavigator(app: app)
    }

    // MARK: - Computed Properties

    /// 判定根導覽就緒的根 identifier
    ///
    /// 啟動預設停在總覽，兩種版面都會呈現總覽頁根容器，故以它作為就緒判定；側邊欄容器僅 regular 版面存在、
    /// 分頁列版面又無穩定根 identifier，皆不適合當共用判定
    var rootIdentifier: String {
        BLAccessibilityID.Dashboard.root
    }
}

// MARK: - Internal Method

extension RootNavigationScreen {

    /// 切到總覽頁，待其就緒才回傳
    /// - Parameter timeout: 逾時秒數
    /// - Returns: 逾時前是否就緒
    @discardableResult
    func goToDashboard(timeout: TimeInterval = 10) -> Bool {
        go(to: .dashboard, timeout: timeout)
    }

    /// 切到訂單頁，待其就緒才回傳
    /// - Parameter timeout: 逾時秒數
    /// - Returns: 逾時前是否就緒
    @discardableResult
    func goToOrders(timeout: TimeInterval = 10) -> Bool {
        go(to: .orders, timeout: timeout)
    }

    /// 切到開團頁，待其就緒才回傳
    /// - Parameter timeout: 逾時秒數
    /// - Returns: 逾時前是否就緒
    @discardableResult
    func goToCampaigns(timeout: TimeInterval = 10) -> Bool {
        go(to: .campaigns, timeout: timeout)
    }

    /// 切到分析頁，待其就緒才回傳
    /// - Parameter timeout: 逾時秒數
    /// - Returns: 逾時前是否就緒
    @discardableResult
    func goToInsights(timeout: TimeInterval = 10) -> Bool {
        go(to: .insights, timeout: timeout)
    }

    /// 切到更多與設定頁，待其就緒才回傳
    /// - Parameter timeout: 逾時秒數
    /// - Returns: 逾時前是否就緒
    @discardableResult
    func goToMore(timeout: TimeInterval = 10) -> Bool {
        go(to: .more, timeout: timeout)
    }

    /// 查詢分頁是否為選取態，供選取態斷言使用
    ///
    /// 兩種版面判定方式不同：側邊欄版面直接讀 `root.tab.<key>` 列的 `isSelected` trait；分頁列版面依專案決議
    /// 以目的地畫面是否呈現間接判定 (系統 tab bar 按鈕不掛 identifier)。尚未發佈根 identifier 的分頁 (訂單／開團／
    /// 分析) 在分頁列版面沒有可等的畫面根，退回讀分頁按鈕自身的 `isSelected` trait
    /// - Parameter tab: 待查分頁
    /// - Returns: 該分頁目前是否選取
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
    ///
    /// 目的地有發佈根 identifier (總覽／更多) 時等其根元素出現，兩種版面共用此強訊號；尚未發佈根 identifier
    /// 的分頁 (訂單／開團／分析) 退而求其次等分頁進入選取態
    /// - Parameters:
    ///   - tab: 目標分頁
    ///   - timeout: 逾時秒數
    /// - Returns: 逾時前是否就緒
    func go(to tab: AppNavigator.Tab, timeout: TimeInterval) -> Bool {
        navigator.selectTab(tab)
        if let identifier = destinationRootIdentifier(for: tab) {
            return app.descendants(matching: .any)[identifier].waitForExistence(timeout: timeout)
        }
        return selectionElement(for: tab).wait(for: NSPredicate(format: "isSelected == true"), timeout: timeout)
    }

    /// 目的地畫面的根 identifier
    ///
    /// 目前只有總覽與更多發佈根 identifier；訂單／開團／分析尚未於 ``BLAccessibilityID`` 宣告根常數，回傳 `nil`，
    /// 待其補上後在此加入對應 case
    /// - Parameter tab: 目標分頁
    /// - Returns: 根 identifier，尚未發佈者為 `nil`
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
    ///
    /// 側邊欄版面回傳 `root.tab.<key>` 列；分頁列版面回傳系統 tab bar 按鈕，以宣告順序取按鈕 (與 ``AppNavigator``
    /// 的分頁列取法一致)
    /// - Parameter tab: 目標分頁
    /// - Returns: 可讀 `isSelected` 的元素
    func selectionElement(for tab: AppNavigator.Tab) -> XCUIElement {
        if navigator.isSidebarLayout {
            return sidebarTabElement(for: tab)
        }
        return tabBarButtonElement(for: tab)
    }

    /// 側邊欄的分頁列元素
    /// - Parameter tab: 目標分頁
    /// - Returns: `root.tab.<key>` 元素
    func sidebarTabElement(for tab: AppNavigator.Tab) -> XCUIElement {
        // 側邊欄分頁列是合併朗讀元素、歸為 staticText，故以 any 查詢而非 otherElements
        app.descendants(matching: .any)[BLAccessibilityID.Root.tab(tab.identifierKey)]
    }

    /// 分頁列的系統 tab bar 按鈕
    ///
    /// 系統按鈕沒有 identifier，只能靠位置；位置由 ``AppNavigator/Tab`` 的 `rawValue` 固定
    /// - Parameter tab: 目標分頁
    /// - Returns: 對應序位的 tab bar 按鈕
    func tabBarButtonElement(for tab: AppNavigator.Tab) -> XCUIElement {
        app.tabBars.buttons.element(boundBy: tab.rawValue)
    }
}
