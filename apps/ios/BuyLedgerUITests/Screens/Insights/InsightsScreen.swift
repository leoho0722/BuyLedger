//
//  InsightsScreen.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 分析頁的 Page Object
struct InsightsScreen {

    // MARK: - Properties

    /// 分段的宣告序位，對齊 `InsightsDateRange`
    private static let rangeOrder = ["thirtyDays", "sixMonths", "twelveMonths"]

    /// 受測 App
    let app: XCUIApplication
}

// MARK: - Internal Method

@MainActor
extension InsightsScreen {

    /// 切換趨勢期間
    ///
    /// - Parameters:
    ///   - rangeID: 趨勢期間的 identifier
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func selectRange(_ rangeID: String, file: StaticString = #filePath, line: UInt = #line) {
        let byID = app.segmentedControls.buttons[BLAccessibilityID.Insights.rangeSegment(rangeID)]
        if byID.waitUntilHittable(timeout: 3) {
            byID.tap()
            return
        }

        if let index = Self.rangeOrder.firstIndex(of: rangeID) {
            let byIndex = app.segmentedControls.buttons.element(boundBy: index)
            byIndex.tapAfterWaiting(in: app, file: file, line: line)
            return
        }
        let rangeIdentifier = BLAccessibilityID.Insights.rangeSegment(rangeID)
        let message = "找不到分析期間分段 identifier \(rangeIdentifier)"
        app.failWithDiagnostics(message, file: file, line: line)
    }

    /// 判定指定分析期間分段是否為選取態
    ///
    /// - Parameter rangeID: 分析期間的 identifier key
    /// - Returns: 分段是否為選取態
    func isRangeSelected(_ rangeID: String) -> Bool {
        let byID = app.segmentedControls.buttons[BLAccessibilityID.Insights.rangeSegment(rangeID)]
        if byID.exists {
            return byID.isSelected
        }
        guard let index = Self.rangeOrder.firstIndex(of: rangeID) else {
            return false
        }
        return app.segmentedControls.buttons.element(boundBy: index).isSelected
    }

    /// 讀取趨勢卡總獲利的 accessibility value
    ///
    /// - Returns: 趨勢卡總獲利的 accessibility value；元素不存在時為 `nil`
    func totalProfitValue() -> String? {
        let element = app.descendants(matching: .any)[BLAccessibilityID.Insights.trendTotalProfit]
        guard element.waitForExistence(timeout: 10) else {
            return nil
        }
        return element.value as? String
    }

    /// 讀取指定類別排行列的獲利 accessibility value
    ///
    /// - Parameter category: 類別名稱
    /// - Returns: 類別獲利的 accessibility value；元素不存在時為 `nil`
    func categoryProfit(category: String) -> String? {
        let element = app.descendants(matching: .any)[
            BLAccessibilityID.Insights.categoryRankRow(category: category)
        ]
        return accessibilityValue(of: element)
    }

    /// 捲到成本結構 donut，回傳它是否出現
    ///
    /// - Returns: 成本結構 donut 是否在等待或捲動後出現
    @discardableResult
    func revealCostDonut() -> Bool {
        let donut = app.descendants(matching: .any)[BLAccessibilityID.Insights.costDonut]
        if donut.waitForExistence(timeout: 5) {
            return true
        }
        app.scrollToHittable(donut, within: rootElement, maxSwipes: 6)
        return donut.exists
    }

    /// 讀取指定開團排行列的毛利 accessibility value
    ///
    /// - Parameter campaignID: 開團識別值
    /// - Returns: 開團毛利的 accessibility value；元素不存在時為 `nil`
    func campaignProfit(campaignID: String) -> String? {
        let element = app.descendants(matching: .any)[
            BLAccessibilityID.Insights.campaignRankRow(campaignID: campaignID)
        ]
        return accessibilityValue(of: element)
    }

    /// 等待指定開團的毛利排行列出現在可及性樹上
    ///
    /// - Parameter campaignID: 開團識別值
    /// - Returns: 是否找到該排行列
    /// - Note: 排行在惰性容器內，畫面外的列查 `isHittable` 會因 `frame` 無效而報錯，只確認列已出現
    func hasCampaignRank(campaignID: String) -> Bool {
        let row = app.descendants(matching: .any)[
            BLAccessibilityID.Insights.campaignRankRow(campaignID: campaignID)
        ]
        return row.waitForExistence(timeout: 10)
    }
}

// MARK: - Screen

extension InsightsScreen: Screen {

    /// 判定分析頁已就緒的根元素 identifier (分析內容捲動容器)
    var rootIdentifier: String {
        BLAccessibilityID.Insights.root
    }
}

// MARK: - Private Method

@MainActor
private extension InsightsScreen {

    /// 嘗試將元素捲入分析頁可見範圍，再讀取 accessibility value，不要求元素可點
    ///
    /// - Parameter element: 要讀取的元素
    /// - Returns: 元素的 accessibility value；元素不存在時為 `nil`
    func accessibilityValue(of element: XCUIElement) -> String? {
        guard element.waitForExistence(timeout: 10) else {
            return nil
        }

        for _ in 0..<8 {
            let elementFrame = element.frame
            if !elementFrame.isEmpty && rootElement.frame.intersects(elementFrame) {
                break
            }
            rootElement.swipeUp()
        }

        return element.value as? String
    }
}
