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
    ///
    /// - Note: 順序須與 App 端 `InsightsDateRange.allCases` 一致
    private static let rangeOrder = ["thirtyDays", "sixMonths", "twelveMonths"]

    /// 受測 App
    let app: XCUIApplication
}

// MARK: - Internal Method

@MainActor
extension InsightsScreen {

    /// 切到分析分頁，等待目前的前景內容、空狀態或載入失敗就緒
    ///
    /// - Parameters:
    ///   - app: 受測 App
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 已進入前景的分析畫面
    /// - Throws: 分頁無法切換或目的地未就緒時丟出測試錯誤
    @discardableResult
    static func open(
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) -> InsightsScreen {
        try RootNavigationScreen(app: app).goToInsights(file: file, line: line)
        return InsightsScreen(app: app)
    }

    /// 載入分析版面所需元素並回傳同一快照要讀取的 identifier
    ///
    /// - Parameters:
    ///   - category: 要納入快照的類別名稱
    ///   - campaignID: 要納入快照的開團識別值；無開團資料時為 `nil`
    /// - Returns: 版面測試必須出現在快照中的 identifier
    func prepareLayoutSnapshot(category: String, campaignID: String? = nil) -> [String] {
        var identifiers = [
            BLAccessibilityID.Insights.rangePicker,
            BLAccessibilityID.Insights.trendChart,
            BLAccessibilityID.Insights.categoryRankRow(category: category),
            BLAccessibilityID.Insights.costDonut,
            BLAccessibilityID.Insights.heatmap,
        ]
        if let campaignID {
            identifiers.append(BLAccessibilityID.Insights.campaignRankRow(campaignID: campaignID))
        }
        app.loadMissingElements(with: identifiers, within: rootElement)
        return identifiers
    }

    /// 等待分析頁顯示載入中
    ///
    /// - Parameter timeout: 等待載入指示器出現的秒數
    /// - Returns: 載入指示器是否在逾時前出現
    func waitForLoading(timeout: TimeInterval = 10) -> Bool {
        app.descendants(matching: .any)[BLAccessibilityID.Insights.loading]
            .waitForExistence(timeout: timeout)
    }

    /// 判斷指定開團排行列是否在目前 accessibility tree 上
    ///
    /// - Parameter campaignID: 開團識別值
    /// - Returns: 指定開團排行列是否存在
    func isCampaignRankPresent(campaignID: String) -> Bool {
        let identifier = BLAccessibilityID.Insights.campaignRankRow(campaignID: campaignID)
        return app.descendants(matching: .any)[identifier].exists
    }

    /// 切換趨勢期間
    ///
    /// - Parameters:
    ///   - rangeID: 趨勢期間的 identifier
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    func selectRange(
        _ rangeID: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        let byID = app.segmentedControls.buttons[BLAccessibilityID.Insights.rangeSegment(rangeID)]
        if byID.waitUntilHittable(timeout: 3) {
            try byID.tapAfterWaiting(in: app, file: file, line: line)
            return
        }

        if let index = Self.rangeOrder.firstIndex(of: rangeID) {
            let segments = app.segmentedControls.buttons
            guard segments.count == Self.rangeOrder.count else {
                let message = """
                    分析期間分段數 \(segments.count) 與宣告的 \(Self.rangeOrder.count) 個不符，\
                    無法依位置點選
                    """
                try app.stopWithDiagnostics(message, file: file, line: line)
            }
            let byIndex = segments.element(boundBy: index)
            try byIndex.tapAfterWaiting(in: app, file: file, line: line)
            guard Polling.wait(timeout: 3, until: { byIndex.isSelected }) else {
                let message = "點選第 \(index + 1) 個分析期間分段後未變成選取態"
                try app.stopWithDiagnostics(message, file: file, line: line)
            }
            return
        }
        let rangeIdentifier = BLAccessibilityID.Insights.rangeSegment(rangeID)
        let message = "找不到分析期間分段 identifier \(rangeIdentifier)"
        try app.stopWithDiagnostics(message, file: file, line: line)
    }

    /// 判定指定分析期間分段是否為選取態
    ///
    /// - Parameter rangeID: 分析期間的 identifier key
    /// - Returns: 分段是否為選取態；依位置退回而分段數與宣告不符時為 `false`
    func isRangeSelected(_ rangeID: String) -> Bool {
        let byID = app.segmentedControls.buttons[BLAccessibilityID.Insights.rangeSegment(rangeID)]
        if byID.exists {
            return byID.isSelected
        }
        let segments = app.segmentedControls.buttons
        guard let index = Self.rangeOrder.firstIndex(of: rangeID),
              segments.count == Self.rangeOrder.count else {
            return false
        }
        return segments.element(boundBy: index).isSelected
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
    /// - Parameters:
    ///   - category: 類別名稱
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 類別獲利的 accessibility value；元素不存在時為 `nil`
    /// - Throws: 元素無法捲入可視範圍時丟出測試錯誤
    func categoryProfit(
        category: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) -> String? {
        let element = app.descendants(matching: .any)[
            BLAccessibilityID.Insights.categoryRankRow(category: category)
        ]
        return try accessibilityValue(of: element, file: file, line: line)
    }

    /// 將成本結構 donut 捲入可視範圍
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: donut 無法捲入可視範圍時丟出測試錯誤
    func revealCostDonut(file: StaticString = #filePath, line: UInt = #line) throws(UITestError) {
        let donut = app.descendants(matching: .other)[BLAccessibilityID.Insights.costDonut]
        guard donut.waitForExistence(timeout: 5) else {
            try app.stopWithDiagnostics("找不到成本結構 donut", file: file, line: line)
        }
        guard app.stableVisibleFrame(of: donut, within: rootElement) != nil else {
            try app.stopWithDiagnostics("成本結構 donut 無法捲入可視範圍", file: file, line: line)
        }
    }

    /// 將第一個類別排行列捲入可視範圍
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 類別排行列無法捲入可視範圍時丟出測試錯誤
    func revealFirstCategoryRank(
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        let prefix = BLAccessibilityID.Insights.categoryRankRow(category: "")
        let rows = app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier BEGINSWITH %@", prefix)
        )
        let row = rows.firstMatch
        guard row.waitForExistence(timeout: 5) else {
            try app.stopWithDiagnostics("找不到類別排行列", file: file, line: line)
        }
        guard app.stableVisibleFrame(of: row, within: rootElement) != nil else {
            try app.stopWithDiagnostics("類別排行列無法捲入可視範圍", file: file, line: line)
        }
    }

    /// 讀取指定開團排行列的毛利 accessibility value
    ///
    /// - Parameters:
    ///   - campaignID: 開團識別值
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 開團毛利的 accessibility value；元素不存在時為 `nil`
    /// - Throws: 元素無法捲入可視範圍時丟出測試錯誤
    func campaignProfit(
        campaignID: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) -> String? {
        let element = app.descendants(matching: .any)[
            BLAccessibilityID.Insights.campaignRankRow(campaignID: campaignID)
        ]
        return try accessibilityValue(of: element, file: file, line: line)
    }

    /// 等待指定開團的毛利排行列出現在可及性樹上
    ///
    /// - Parameter campaignID: 開團識別值
    /// - Returns: 是否找到該排行列
    /// - Note: 惰性容器中的畫面外排行列只確認存在，避免讀取無效框線
    func hasCampaignRank(campaignID: String) -> Bool {
        let row = app.descendants(matching: .any)[
            BLAccessibilityID.Insights.campaignRankRow(campaignID: campaignID)
        ]
        return row.waitForExistence(timeout: 10)
    }
}

// MARK: - ScreenProtocol

extension InsightsScreen: ScreenProtocol {

    /// 判定分析頁已就緒的根元素 identifier (分析內容捲動容器)
    var rootIdentifier: String {
        BLAccessibilityID.Insights.root
    }
}

// MARK: - Private Method

@MainActor
private extension InsightsScreen {

    /// 捲入分析頁可見範圍後讀取 accessibility value，不要求元素可點
    ///
    /// - Parameters:
    ///   - element: 要讀取的元素
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 元素的 accessibility value；元素不存在時為 `nil`
    /// - Throws: 元素無法捲入可視範圍時丟出測試錯誤
    func accessibilityValue(
        of element: XCUIElement,
        file: StaticString,
        line: UInt
    ) throws(UITestError) -> String? {
        guard element.waitForExistence(timeout: 10) else {
            return nil
        }
        try app.reveal(
            element,
            within: rootElement,
            isSwipingUp: true,
            maxGestures: 8,
            gestureStyle: .swipe,
            requiresVisibleFrame: true,
            requiresHittable: false,
            file: file,
            line: line
        )
        return element.value as? String
    }
}
