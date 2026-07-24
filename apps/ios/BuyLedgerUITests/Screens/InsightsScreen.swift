//
//  InsightsScreen.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 分析頁的 Page Object
///
/// 以 accessibility identifier 對外暴露期間切換、走勢圖與成本結構容器、開團排行的語意操作，元素查詢細節不外洩給測試檔；
/// compact 分頁列與 regular 側邊欄兩種版面共用同一組 identifier，故 Page Object 不分版面
struct InsightsScreen: Screen {

    // MARK: - Data Properties

    /// 受測 App
    let app: XCUIApplication

    // MARK: - Static Properties

    /// segmented control 各分段的宣告序位，對齊 App 端 `InsightsDateRange` 的 case 宣告順序
    ///
    /// 供期間識別碼未穿透到分段按鈕時的序位後備定位使用 (語言中立、不讀顯示文字)；App 端調整期間順序時此處要一併更新
    private static let rangeOrder = ["thirtyDays", "sixMonths", "twelveMonths"]

    // MARK: - Computed Properties

    /// 判定分析頁已就緒的根 identifier (分析內容捲動容器)
    var rootIdentifier: String {
        BLAccessibilityID.Insights.root
    }

    /// 是否正顯示尚無足夠資料的空狀態
    var isEmptyStateShown: Bool {
        app.descendants(matching: .any)[BLAccessibilityID.Insights.emptyState].exists
    }

    /// 走勢圖容器是否存在
    var trendChartExists: Bool {
        app.descendants(matching: .any)[BLAccessibilityID.Insights.trendChart].waitForExistence(timeout: 10)
    }

    /// 成本結構 donut 容器是否存在
    ///
    /// donut 位於捲動內容中段，可能落在初始可視範圍外；先直接查，查不到再捲向它後複查
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
    ///
    /// 期間選項識別碼掛在 segmented `Picker` 的 tag 內容上；segmented control 未必把該識別碼穿透到分段按鈕，
    /// 故識別碼定位失敗時退回依 ``rangeOrder`` 的序位取分段按鈕 (語言中立、不讀顯示文字)
    /// - Parameter rangeID: `InsightsDateRange` 的 rawValue (`thirtyDays` / `sixMonths` / `twelveMonths`)
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
    ///
    /// 排行卡位於捲動內容下段，先在分析內容捲動容器內捲到可點再點
    /// - Parameter campaignID: 開團 id 這個業務鍵
    func tapCampaignRank(campaignID: String) {
        let row = app.descendants(matching: .any)[BLAccessibilityID.Insights.campaignRankRow(campaignID: campaignID)]
        app.scrollToHittable(row, within: rootElement)
        row.waitUntilHittable()
        row.tap()
    }
}
