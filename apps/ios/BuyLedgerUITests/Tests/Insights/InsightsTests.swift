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
