//
//  InsightsTests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 分析頁的進入、圖表容器與期間切換流程測試
final class InsightsTests: BLUITestCase {

    // MARK: - Static Properties

    /// 三個期間的 rawValue，依 App 端 `InsightsDateRange` 宣告順序排列
    private static let rangeIDs = ["thirtyDays", "sixMonths", "twelveMonths"]

    // MARK: - Tests

    /// 切到分析分頁後畫面就緒 (insightsRange 有跨月資料)
    @MainActor
    func testInsightsReadyWithSeed() {
        let app = launch(LaunchOptions(seed: .insightsRange))
        let insights = openInsights(app)

        _ = insights
    }

    /// 走勢圖與成本結構 donut 兩個容器都存在
    @MainActor
    func testTrendAndDonutContainersExist() {
        let app = launch(LaunchOptions(seed: .insightsRange))
        let insights = openInsights(app)

        if !insights.trendChartExists {
            failWithDiagnostics(in: app, "走勢圖容器逾時仍未出現")
        }
        if !insights.costDonutExists {
            failWithDiagnostics(in: app, "成本結構 donut 容器逾時仍未出現")
        }
    }

    /// 切換三個期間後畫面仍就緒且對應分段保持選取
    @MainActor
    func testRangeSwitchingKeepsReady() {
        let app = launch(LaunchOptions(seed: .insightsRange))
        let insights = openInsights(app)

        for rangeID in Self.rangeIDs {
            insights.selectRange(rangeID)
            if !insights.waitUntilReady() {
                failWithDiagnostics(
                    in: app,
                    "切到期間「\(rangeID)」後分析頁根 identifier「\(insights.rootIdentifier)」逾時仍未出現"
                )
            }
            XCTAssertTrue(
                insights.isRangeSelected(rangeID),
                "切到期間「\(rangeID)」後對應分段應為選取態"
            )
        }
    }

    /// 合併訂單的總覽、趨勢、類別與開團獲利口徑一致
    ///
    /// - Throws: 必要的 accessibility value 不存在或無法解析時拋出測試錯誤
    @MainActor
    func testRevenueAttributionMatchesAcrossViews() throws(any Error) {
        // Given：營收歸屬資料已載入總覽頁
        let app = launch(LaunchOptions(seed: .revenueAttribution))
        let root = RootNavigationScreen(app: app)
        let dashboard = DashboardScreen(app: app)

        try requireCondition(
            root.goToDashboard() && dashboard.waitUntilReady(),
            in: app,
            "營收歸屬驗收的總覽頁未就緒"
        )

        let overviewProfit = try readNumericAmount(
            dashboard.kpiValue(.netProfit),
            in: app,
            description: "總覽淨獲利 KPI 卡"
        )
        // When：切換至開團與分析頁讀取各層獲利
        try requireCondition(
            root.goToCampaigns(),
            in: app,
            "營收歸屬驗收的開團頁未就緒"
        )
        let campaigns = CampaignsScreen(app: app)
        try requireCondition(
            campaigns.waitUntilReady()
                && campaigns.hasCampaign(campaignID: "UITEST-REV-CAM-001")
                && campaigns.hasCampaign(campaignID: "UITEST-REV-CAM-002"),
            in: app,
            "營收歸屬驗收的開團未載入"
        )

        let insights = openInsights(app)
        let trendProfit = try readNumericAmount(
            insights.totalProfitValue(),
            in: app,
            description: "趨勢卡總獲利"
        )
        let categoryAProfit = try readNumericAmount(
            insights.categoryProfit(category: "美妝"),
            in: app,
            description: "美妝類別排行"
        )
        let categoryBProfit = try readNumericAmount(
            insights.categoryProfit(category: "服飾"),
            in: app,
            description: "服飾類別排行"
        )
        let campaignAProfit = try readNumericAmount(
            insights.campaignProfit(campaignID: "UITEST-REV-CAM-001"),
            in: app,
            description: "開團 UITEST-REV-CAM-001 排行"
        )
        let campaignBProfit = try readNumericAmount(
            insights.campaignProfit(campaignID: "UITEST-REV-CAM-002"),
            in: app,
            description: "開團 UITEST-REV-CAM-002 排行"
        )

        // Then：總覽、類別與開團獲利合計一致
        XCTAssertEqual(overviewProfit, 6_730, "總覽應只計入合併結果的獲利")
        XCTAssertEqual(trendProfit, overviewProfit, "趨勢總獲利應與總覽一致")
        XCTAssertEqual(categoryAProfit, 3_850, "美妝類別應只計入來源訂單獲利")
        XCTAssertEqual(categoryBProfit, 2_880, "服飾類別應只計入來源訂單獲利")
        XCTAssertEqual(categoryAProfit + categoryBProfit, overviewProfit, "類別獲利合計應與總覽一致")
        XCTAssertEqual(campaignAProfit, 3_850, "美妝開團應只計入來源訂單獲利")
        XCTAssertEqual(campaignBProfit, 2_880, "服飾開團應只計入來源訂單獲利")
        XCTAssertEqual(campaignAProfit + campaignBProfit, overviewProfit, "開團獲利合計應與總覽一致")
    }

    /// 空資料庫時，分析頁顯示尚無足夠資料的空狀態
    @MainActor
    func testEmptySeedShowsEmptyState() {
        let app = launch(LaunchOptions(seed: .empty))

        let root = RootNavigationScreen(app: app)
        if !root.goToInsights(file: #filePath, line: #line) {
            failWithDiagnostics(
                in: app,
                "切到分析分頁後畫面未就緒",
                file: #filePath,
                line: #line
            )
        }

        assertEmptyState(BLAccessibilityID.Insights.emptyState, in: app)
    }
}

// MARK: - Private Method

private extension InsightsTests {

    /// 讀取並解析畫面上的金額 accessibility value
    ///
    /// - Parameters:
    ///   - value: 待讀取的 accessibility value
    ///   - app: 受測 App
    ///   - description: 失敗訊息中的元素描述
    /// - Returns: 可比較的整數金額
    /// - Throws: 元素不存在、值為空或無法解析時拋出測試錯誤
    func readNumericAmount(
        _ value: String?,
        in app: XCUIApplication,
        description: String
    ) throws(any Error) -> Int {
        let rawValue = try requireValue(
            value,
            in: app,
            "\(description)的元素不存在"
        )
        try requireCondition(
            !rawValue.isEmpty,
            in: app,
            "\(description)的 accessibility value 為空"
        )
        return try requireValue(
            numericAmount(rawValue),
            in: app,
            "\(description)沒有可解析的 accessibility value"
        )
    }

    /// 從 UI 顯示的金額字串擷取整數，忽略幣別符號與千分位分隔符
    ///
    /// - Parameter value: accessibility value
    /// - Returns: 可比較的整數金額；無法解析時回傳 nil
    func numericAmount(_ value: String) -> Int? {
        let normalized = value.filter { $0.isNumber || $0 == "-" }
        return Int(normalized)
    }

    /// 切到分析分頁並等內容就緒，回傳分析頁 Page Object
    ///
    /// - Parameters:
    ///   - app: 受測 App
    ///   - file: 失敗時回報的來源檔案
    ///   - line: 失敗時回報的來源行號
    /// - Returns: 已就緒的分析頁 Page Object
    @MainActor
    func openInsights(
        _ app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> InsightsScreen {
        let root = RootNavigationScreen(app: app)
        if !root.goToInsights(file: file, line: line) {
            failWithDiagnostics(in: app, "切到分析分頁後畫面未就緒", file: file, line: line)
        }

        let insights = InsightsScreen(app: app)
        if !insights.waitUntilReady() {
            failWithDiagnostics(
                in: app,
                "分析頁根 identifier「\(insights.rootIdentifier)」逾時仍未出現",
                file: file,
                line: line
            )
        }
        return insights
    }
}
