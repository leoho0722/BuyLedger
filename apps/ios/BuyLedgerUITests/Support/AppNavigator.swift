//
//  AppNavigator.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 吸收 compact 分頁列與 regular 側邊欄兩套導覽樹的差異
///
/// iPhone 走底部分頁列、iPad 全螢幕走側邊欄，元素樹完全不同；對外只暴露「切到某分頁」等語意操作，
/// 讓同一份流程測試在兩種版面都能跑
struct AppNavigator {

    // MARK: - Data Properties

    /// 受測 App
    let app: XCUIApplication

    // MARK: - Computed Properties

    /// 目前是否為側邊欄版面 (iPad 全螢幕)
    ///
    /// 啟動後側邊欄與分頁列的渲染有時間差，故先等其一出現再判定，避免瞬時查詢誤判成分頁列版面
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
    ///
    /// 側邊欄版面點 `root.tab.<key>` 的列；分頁列版面因系統 tab bar 按鈕掛不上 identifier，
    /// 改依 ``Tab`` 的宣告順序取按鈕，切換後由呼叫端等目的地畫面的根 identifier 確認
    /// - Parameter tab: 目標分頁
    func selectTab(_ tab: Tab) {
        if isSidebarLayout {
            // 側邊欄的分頁列是合併朗讀元素、歸為 staticText，故以 any 查詢而非 otherElements
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
    ///
    /// 系統 tab bar 的按鈕沒有 identifier，只能靠位置；位置由 ``Tab`` 的 `rawValue` 固定，
    /// 分頁順序若改動，等目的地 identifier 的斷言會失敗而非默默點錯
    /// - Parameter tab: 目標分頁，其 `rawValue` 即按鈕在分頁列的位置
    /// - Returns: 對應位置的分頁列按鈕
    func tabBarButton(for tab: Tab) -> XCUIElement {
        app.tabBars.buttons.element(boundBy: tab.rawValue)
    }
}
