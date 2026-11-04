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

    /// 載入分析版面所需元素並回傳同一快照要讀取的 identifier
    ///
    /// - Parameter campaignID: 要納入快照的開團識別值；無開團資料時為 `nil`
    /// - Returns: 版面測試必須出現在快照中的 identifier
    func prepareLayoutSnapshot(campaignID: String? = nil) -> [String] {
        var identifiers = [
            BLAccessibilityID.Insights.rangePicker,
            BLAccessibilityID.Insights.trendChart,
            BLAccessibilityID.Insights.categoryRankRow(category: "美妝"),
            BLAccessibilityID.Insights.costDonut,
            BLAccessibilityID.Insights.heatmap,
        ]
        if let campaignID {
            identifiers.append(BLAccessibilityID.Insights.campaignRankRow(campaignID: campaignID))
        }
        app.loadMissingElements(with: identifiers, within: rootElement)
        return identifiers
    }

    /// 將分析期間選擇器捲入可視區後讀取框線
    ///
    /// - Returns: 選擇器框線；元素尚未出現或無有效框線時為 `nil`
    func rangePickerFrame() -> CGRect? {
        frame(for: BLAccessibilityID.Insights.rangePicker)
    }

    /// 將趨勢卡捲入可視區後讀取框線
    ///
    /// - Returns: 趨勢卡框線；元素尚未出現或無有效框線時為 `nil`
    func trendChartFrame() -> CGRect? {
        frame(for: BLAccessibilityID.Insights.trendChart)
    }

    /// 將指定類別排行列捲入可視區後讀取框線
    ///
    /// - Parameter category: 類別名稱
    /// - Returns: 類別列框線；元素尚未出現或無有效框線時為 `nil`
    func categoryRowFrame(category: String) -> CGRect? {
        frame(for: BLAccessibilityID.Insights.categoryRankRow(category: category))
    }

    /// 將成本圓餅圖捲入可視區後讀取框線
    ///
    /// - Returns: 圓餅圖框線；元素尚未出現或無有效框線時為 `nil`
    func costDonutFrame() -> CGRect? {
        frame(for: BLAccessibilityID.Insights.costDonut)
    }

    /// 將指定開團排行列捲入可視區後讀取框線
    ///
    /// - Parameter campaignID: 開團識別值
    /// - Returns: 開團列框線；元素尚未出現或無有效框線時為 `nil`
    func campaignRankFrame(campaignID: String) -> CGRect? {
        frame(for: BLAccessibilityID.Insights.campaignRankRow(campaignID: campaignID))
    }

    /// 判斷指定開團排行列是否在目前 accessibility tree 上
    ///
    /// - Parameter campaignID: 開團識別值
    /// - Returns: 指定開團排行列是否存在
    func isCampaignRankPresent(campaignID: String) -> Bool {
        let identifier = BLAccessibilityID.Insights.campaignRankRow(campaignID: campaignID)
        return app.descendants(matching: .any)[identifier].exists
    }

    /// 將熱力圖容器捲入可視區後讀取框線
    ///
    /// - Returns: 熱力圖框線；元素尚未出現或無有效框線時為 `nil`
    func heatmapFrame() -> CGRect? {
        frame(for: BLAccessibilityID.Insights.heatmap)
    }

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

    /// 捲到成本結構 donut，回傳它是否可點
    ///
    /// - Returns: 成本結構 donut 是否在等待或捲動後可點
    func revealCostDonut() -> Bool {
        let donut = app.descendants(matching: .other)[BLAccessibilityID.Insights.costDonut]
        guard donut.waitForExistence(timeout: 5) else {
            return false
        }
        return app.stableVisibleFrame(of: donut, within: rootElement) != nil
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

    /// 將語意識別碼對應元素捲入可視區後讀取穩定框線
    ///
    /// - Parameter identifier: accessibility identifier
    /// - Returns: 元素穩定且可見的框線；元素不存在或無效時為 `nil`
    func frame(for identifier: String) -> CGRect? {
        let element = app.descendants(matching: .any)[identifier]
        return app.stableVisibleFrame(of: element, within: rootElement)
    }

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
