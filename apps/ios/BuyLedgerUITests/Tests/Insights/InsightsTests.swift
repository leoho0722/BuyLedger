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

    /// 切換三個期間後畫面仍就緒 (只驗結構、不驗數值)
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
        }
    }

    /// 合併訂單的總覽、趨勢、類別與開團獲利口徑一致
    @MainActor
    func testRevenueAttributionIsConsistentAcrossOverviewTrendCategoryAndCampaign() {
        let app = launch(LaunchOptions(seed: .revenueAttribution))
        let root = RootNavigationScreen(app: app)
        let dashboard = DashboardScreen(app: app)

        guard root.goToDashboard(), dashboard.waitUntilReady() else {
            failWithDiagnostics(in: app, "營收歸屬驗收的總覽頁未就緒")
            return
        }

        guard let overviewProfit = numericAmount(dashboard.kpiValue(.netProfit)) else {
            failWithDiagnostics(in: app, "總覽淨獲利沒有可解析的 accessibility value")
            return
        }
        XCTAssertEqual(overviewProfit, 6_730, "總覽應只計入合併結果的獲利")

        guard root.goToCampaigns() else {
            failWithDiagnostics(in: app, "營收歸屬驗收的開團頁未就緒")
            return
        }
        let campaigns = CampaignsScreen(app: app)
        guard campaigns.waitUntilReady(),
              campaigns.hasCampaign(campaignID: "UITEST-REV-CAM-001"),
              campaigns.hasCampaign(campaignID: "UITEST-REV-CAM-002") else {
            failWithDiagnostics(in: app, "營收歸屬驗收的兩筆開團未載入")
            return
        }

        let insights = openInsights(app)
        guard let trendProfit = numericAmount(insights.totalProfitValue()) else {
            failWithDiagnostics(in: app, "趨勢卡總獲利沒有可解析的 accessibility value")
            return
        }
        XCTAssertEqual(trendProfit, overviewProfit, "趨勢總獲利應與總覽一致")

        guard let categoryAProfit = numericAmount(insights.categoryProfit(category: "美妝")),
              let categoryBProfit = numericAmount(insights.categoryProfit(category: "服飾")) else {
            failWithDiagnostics(in: app, "類別排行沒有可解析的獲利 accessibility value")
            return
        }
        XCTAssertEqual(categoryAProfit, 3_850, "美妝類別應只計入來源訂單獲利")
        XCTAssertEqual(categoryBProfit, 2_880, "服飾類別應只計入來源訂單獲利")
        XCTAssertEqual(categoryAProfit + categoryBProfit, overviewProfit, "類別獲利合計應與總覽一致")

        guard let campaignAProfit = numericAmount(
            insights.campaignProfit(campaignID: "UITEST-REV-CAM-001")
        ), let campaignBProfit = numericAmount(
            insights.campaignProfit(campaignID: "UITEST-REV-CAM-002")
        ) else {
            failWithDiagnostics(in: app, "開團排行沒有可解析的獲利 accessibility value")
            return
        }
        XCTAssertEqual(campaignAProfit, 3_850, "美妝開團應只計入來源訂單獲利")
        XCTAssertEqual(campaignBProfit, 2_880, "服飾開團應只計入來源訂單獲利")
        XCTAssertEqual(campaignAProfit + campaignBProfit, overviewProfit, "開團獲利合計應與總覽一致")
    }

    /// 空資料庫時，分析頁顯示尚無足夠資料的空狀態
    @MainActor
    func testEmptySeedShowsEmptyState() {
        let app = launch(LaunchOptions(seed: .empty))

        let root = RootNavigationScreen(app: app)
        if !root.goToInsights() {
            failWithDiagnostics(in: app, "切到分析分頁後畫面未就緒")
        }

        assertEmptyState(BLAccessibilityID.Insights.emptyState, in: app)
    }
}

// MARK: - Private Method

private extension InsightsTests {

    /// 從 UI 顯示的金額字串擷取整數，忽略幣別符號與千分位分隔符
    /// - Parameter value: accessibility value
    /// - Returns: 可比較的整數金額；無法解析時回傳 nil
    func numericAmount(_ value: String) -> Int? {
        let normalized = value.filter { $0.isNumber || $0 == "-" }
        return Int(normalized)
    }

    /// 切到分析分頁並等內容就緒，回傳分析頁 Page Object
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
        if !root.goToInsights() {
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
