//
//  InsightsScreen.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 分析頁的 Page Object
struct InsightsScreen: Screen {

    // MARK: - Data Properties

    /// 受測 App
    let app: XCUIApplication

    // MARK: - Static Properties

    /// 分段的宣告序位，對齊 InsightsDateRange
    private static let rangeOrder = ["thirtyDays", "sixMonths", "twelveMonths"]

    // MARK: - Computed Properties

    /// 判定分析頁已就緒的根 identifier (分析內容捲動容器)
    /// - Returns: 分析頁根容器的 identifier
    var rootIdentifier: String {
        BLAccessibilityID.Insights.root
    }

    /// 是否正顯示尚無足夠資料的空狀態
    /// - Returns: 是否顯示空狀態
    var isEmptyStateShown: Bool {
        app.descendants(matching: .any)[BLAccessibilityID.Insights.emptyState].exists
    }

    /// 走勢圖容器是否存在
    /// - Returns: 走勢圖容器是否在逾時前出現
    var trendChartExists: Bool {
        app.descendants(matching: .any)[BLAccessibilityID.Insights.trendChart].waitForExistence(
            timeout: 10)
    }

    /// 成本結構 donut 容器是否存在
    /// - Returns: 成本結構容器是否存在
    var costDonutExists: Bool {
        let donut = app.descendants(matching: .any)[BLAccessibilityID.Insights.costDonut]
        if donut.waitForExistence(timeout: 5) {
            return true
        }
        app.scrollToHittable(donut, within: rootElement, maxSwipes: 6)
        return donut.exists
    }
}

// MARK: - Internal Method

@MainActor
extension InsightsScreen {

    /// 切換趨勢期間
    /// - Parameter rangeID: 趨勢期間的 identifier
    func selectRange(_ rangeID: String) {
        let byID = app.segmentedControls.buttons[BLAccessibilityID.Insights.rangeSegment(rangeID)]
        if byID.waitUntilHittable(timeout: 3) {
            byID.tap()
            return
        }

        guard let index = Self.rangeOrder.firstIndex(of: rangeID) else {
            return
        }
        let byIndex = app.segmentedControls.buttons.element(boundBy: index)
        byIndex.waitUntilHittable()
        byIndex.tap()
    }

    /// 點指定開團 id 的每團毛利排行列，深連結到該開團詳情
    /// - Parameter campaignID: 開團 id
    func tapCampaignRank(campaignID: String) {
        let row = app.descendants(matching: .any)[
            BLAccessibilityID.Insights.campaignRankRow(campaignID: campaignID)
        ]
        app.scrollToHittable(row, within: rootElement)
        row.waitUntilHittable()
        row.tap()
    }
}
