//
//  AppNavigator.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 吸收 compact 分頁列與 regular 側邊欄兩套導覽樹的差異
struct AppNavigator {

    // MARK: - Properties

    /// 受測 App
    let app: XCUIApplication
}

// MARK: - Nested Types

extension AppNavigator {

    /// 分頁列與側邊欄共用的分頁 key
    enum Tab: Int, CaseIterable {

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

        /// 對應的 identifier key，與 App 端 `RootTab` 同序
        ///
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

// MARK: - Computed Properties

extension AppNavigator {

    /// 目前是否為側邊欄版面 (regular)，等側邊欄或底部分頁列其中之一出現後判斷
    ///
    /// - Returns: 目前是否使用側邊欄版面
    /// - Note: 側邊欄出現即為 regular，分頁列出現即為 compact
    /// - Note: 兩者都未出現時讓測試失敗
    var isSidebarLayout: Bool {
        let sidebar = app.descendants(matching: .any)[BLAccessibilityID.Root.sidebar]
        let tabBar = app.tabBars.firstMatch
        let deadline = Date.now.addingTimeInterval(10)
        while Date.now < deadline {
            if sidebar.exists {
                return true
            }
            if tabBar.exists {
                return false
            }
            _ = XCTWaiter().wait(for: [XCTestExpectation()], timeout: 0.1)
        }
        app.failWithDiagnostics("10 秒內側邊欄與底部分頁列皆未出現，無法判斷版面")
        return false
    }
}

// MARK: - Internal Method

extension AppNavigator {

    /// 切換到指定分頁
    ///
    /// - Parameters:
    ///   - tab: 目標分頁
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func selectTab(_ tab: Tab, file: StaticString = #filePath, line: UInt = #line) {
        if isSidebarLayout {
            // 分頁列是合併朗讀的 `staticText`，因此以 `.any` 查詢
            let tabIdentifier = BLAccessibilityID.Root.tab(tab.identifierKey)
            let elementName = "identifier 為 \(tabIdentifier) 的分頁"
            let row = app.descendants(matching: .any)[tabIdentifier]
            row.tapAfterWaiting(
                in: app,
                elementName: elementName,
                file: file,
                line: line
            )
        } else {
            tabBarButton(for: tab).tapAfterWaiting(
                in: app,
                elementName: "底部分頁索引 \(tab.rawValue)",
                file: file,
                line: line
            )
        }
    }
}

// MARK: - Private Method

private extension AppNavigator {

    /// 依宣告順序取底部分頁列的按鈕
    ///
    /// - Parameter tab: 要查詢的分頁
    /// - Returns: 底部分頁列中的按鈕
    func tabBarButton(for tab: Tab) -> XCUIElement {
        app.tabBars.buttons.element(boundBy: tab.rawValue)
    }
}
