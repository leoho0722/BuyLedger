//
//  InsightsUITests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 分析頁期間切換、營收歸屬與空狀態的 UI 測試
@MainActor
final class InsightsUITests: BLUITestCase {

    // MARK: - Properties

    /// 最後一個期間之前依序切換的兩個期間 `rawValue`，順序同 App 端 `InsightsDateRange` 的宣告順序
    private static let precedingRangeIDs = ["thirtyDays", "sixMonths"]

    /// 最後切換的期間 `rawValue`，即 `InsightsDateRange` 宣告順序中的最後一個
    private static let lastRangeID = "twelveMonths"

    /// 驗證依序切換三個期間時，每次切換後分析頁都就緒且對應分段保持選取
    ///
    /// - Throws: 前兩個期間切換後畫面未就緒或分段未選取時丟出測試錯誤
    /// - Note: 情境流程：受測的就是依序切換，前兩次切換放 Given，最後一次切換為受測動作
    func testSelectRange_依序切換三個期間_畫面就緒且分段選取() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .insightsRange))
        let insights = try InsightsScreen.open(in: app)
        // 前兩次切換當下就確認，失敗時的診斷截圖停在出錯的期間
        for rangeID in Self.precedingRangeIDs {
            try insights.selectRange(rangeID)
            try requireCondition(
                insights.waitUntilReady() && insights.isRangeSelected(rangeID),
                in: app,
                "切到期間「\(rangeID)」後分析頁未就緒或分段未選取"
            )
        }

        // When
        try insights.selectRange(Self.lastRangeID)

        // Then
        if !insights.waitUntilReady() {
            failWithDiagnostics(in: app, "切到期間「\(Self.lastRangeID)」後分析頁根容器逾時仍未出現")
        }
        if !insights.isRangeSelected(Self.lastRangeID) {
            failWithDiagnostics(in: app, "切到期間「\(Self.lastRangeID)」後對應分段未呈現選取態")
        }
    }

    /// 驗證合併訂單後，總覽與趨勢的總獲利皆為 6,730，美妝與服飾類別的獲利分別為 3,850 與 2,880，兩個開團也分別為 3,850 與 2,880，合計都等於 6,730
    ///
    /// - Throws: 必要的 accessibility value 不存在或無法解析時丟出測試錯誤
    /// - Note: 先在總覽與開團頁確認營收歸屬資料已載入，再切到分析頁比對數字
    func testTask_合併訂單_總覽趨勢類別與開團獲利一致() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .revenueAttribution))
        let dashboard = try DashboardScreen.open(in: app)
        try requireCondition(dashboard.waitUntilReady(), in: app, "營收歸屬驗收的總覽頁未就緒")
        let overviewProfit = try readNumericAmount(
            dashboard.kpiValue(.netProfit),
            in: app,
            description: "總覽淨獲利 KPI 卡"
        )

        let campaigns = try CampaignsScreen.open(in: app)
        try requireCondition(
            campaigns.waitUntilReady()
                && campaigns.hasCampaign(campaignID: "UITEST-REV-CAM-001")
                && campaigns.hasCampaign(campaignID: "UITEST-REV-CAM-002"),
            in: app,
            "營收歸屬驗收的開團未載入"
        )

        // When
        let insights = try InsightsScreen.open(in: app)
        let trendProfit = try readNumericAmount(
            insights.totalProfitValue(),
            in: app,
            description: "趨勢卡總獲利"
        )
        let categoryAProfit = try readNumericAmount(
            try insights.categoryProfit(category: "美妝"),
            in: app,
            description: "美妝類別排行"
        )
        let categoryBProfit = try readNumericAmount(
            try insights.categoryProfit(category: "服飾"),
            in: app,
            description: "服飾類別排行"
        )
        let campaignAProfit = try readNumericAmount(
            try insights.campaignProfit(campaignID: "UITEST-REV-CAM-001"),
            in: app,
            description: "開團 UITEST-REV-CAM-001 排行"
        )
        let campaignBProfit = try readNumericAmount(
            try insights.campaignProfit(campaignID: "UITEST-REV-CAM-002"),
            in: app,
            description: "開團 UITEST-REV-CAM-002 排行"
        )

        // Then
        XCTAssertEqual(overviewProfit, 6_730, "總覽應只計入合併結果的獲利")
        XCTAssertEqual(trendProfit, 6_730, "趨勢總獲利應與總覽一致")
        XCTAssertEqual(categoryAProfit, 3_850, "美妝類別應只計入來源訂單獲利")
        XCTAssertEqual(categoryBProfit, 2_880, "服飾類別應只計入來源訂單獲利")
        XCTAssertEqual(categoryAProfit + categoryBProfit, 6_730, "類別獲利合計應與總覽一致")
        XCTAssertEqual(campaignAProfit, 3_850, "美妝開團應只計入來源訂單獲利")
        XCTAssertEqual(campaignBProfit, 2_880, "服飾開團應只計入來源訂單獲利")
        XCTAssertEqual(campaignAProfit + campaignBProfit, 6_730, "開團獲利合計應與總覽一致")
    }

    /// 驗證空資料時進入分析頁，顯示尚無足夠資料的空狀態
    ///
    /// - Throws: 分析頁未就緒或空狀態未出現時丟出測試錯誤
    func testTask_空資料_顯示空狀態() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .empty))

        // When
        try InsightsScreen.open(in: app)

        // Then
        try assertEmptyState(BLAccessibilityID.Insights.emptyState, in: app)
    }
}

// MARK: - Private Method

private extension InsightsUITests {

    /// 讀取並解析畫面上的金額 accessibility value
    ///
    /// - Parameters:
    ///   - value: 待讀取的 accessibility value
    ///   - app: 受測 App
    ///   - description: 失敗訊息中的元素描述
    /// - Returns: 可比較的整數金額
    /// - Throws: 元素不存在、值為空或無法解析時丟出測試錯誤
    func readNumericAmount(
        _ value: String?,
        in app: XCUIApplication,
        description: String
    ) throws(UITestError) -> Int {
        let rawValue = try requireValue(value, in: app, "\(description)的元素不存在")
        try requireCondition(!rawValue.isEmpty, in: app, "\(description)的 accessibility value 為空")
        return try requireValue(
            numericAmount(rawValue),
            in: app,
            "\(description)沒有可解析的 accessibility value"
        )
    }

    /// 從 UI 顯示的金額字串擷取整數，忽略幣別符號與千分位分隔符
    ///
    /// - Parameter value: accessibility value
    /// - Returns: 可比較的整數金額；無法解析時回傳 `nil`
    func numericAmount(_ value: String) -> Int? {
        let normalized = value.filter { $0.isNumber || $0 == "-" }
        return Int(normalized)
    }
}
