//
//  InsightsLayoutSmokeTests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/10/30.
//

import XCTest

/// 分析頁固定卡片順序與選擇性開團卡片的 UI 測試
@MainActor
final class InsightsLayoutSmokeTests: BLUITestCase {

    /// 驗證沒有開團資料時分析卡片依固定順序顯示且不建立空開團卡
    ///
    /// - Throws: 必要分析元素缺少、開團列錯誤出現或順序不符時失敗
    func testInsightsLayout_沒有開團資料_卡片固定順序且隱藏開團() throws {
        // Given
        let context = try openInsights(seed: .insightsRange)

        // When
        let frames = try readFrames(on: context.screen, in: context.app)
        let hasCampaign = context.screen.isCampaignRankPresent(campaignID: "UITEST-REV-CAM-001")

        // Then
        try requireCondition(!hasCampaign, in: context.app, "沒有開團資料時出現開團排行")
        try requireCondition(
            isAbove(frames.range, frames.trend)
                && isAbove(frames.trend, frames.category)
                && isAbove(frames.category, frames.cost)
                && isAbove(frames.cost, frames.heatmap),
            in: context.app,
            "無開團資料的分析卡片順序錯誤"
        )
    }

    /// 驗證有開團資料時開團毛利卡出現在成本與熱力圖之間
    ///
    /// - Throws: 必要分析元素缺少或卡片順序不符時丟出測試錯誤
    func testInsightsLayout_有開團資料_開團卡位於成本與熱力圖之間() throws {
        // Given
        let context = try openInsights(seed: .revenueAttribution)

        // When
        let frames = try readFrames(
            on: context.screen,
            in: context.app,
            campaignID: "UITEST-REV-CAM-001"
        )
        let campaignFrame = try requireValue(frames.campaign, in: context.app, "找不到營收驗收開團排行有效框線")

        // Then
        try requireCondition(
            isAbove(frames.range, frames.trend)
                && isAbove(frames.trend, frames.category)
                && isAbove(frames.category, frames.cost)
                && isAbove(frames.cost, campaignFrame)
                && isAbove(campaignFrame, frames.heatmap),
            in: context.app,
            "有開團資料的開團排行未位於成本與熱力圖之間"
        )
    }
}

// MARK: - Nested Types

private extension InsightsLayoutSmokeTests {

    /// 分析固定內容的語意元素快照框線
    struct LayoutFrames {

        /// 期間選擇器框線
        let range: CGRect

        /// 趨勢卡框線
        let trend: CGRect

        /// 美妝類別排行列框線
        let category: CGRect

        /// 成本圓餅圖框線
        let cost: CGRect

        /// 熱力圖框線
        let heatmap: CGRect

        /// 開團排行列框線；沒有開團資料時為 `nil`
        let campaign: CGRect?
    }
}

// MARK: - Private Method

private extension InsightsLayoutSmokeTests {

    /// 啟動指定分析種子並等待分析畫面就緒
    ///
    /// - Parameter seed: 分析頁需要的固定種子
    /// - Returns: 已就緒的 App 與分析畫面
    /// - Throws: 根導覽或分析頁未就緒時丟出測試錯誤
    func openInsights(
        seed: LaunchOptions.SeedProfile
    ) throws -> (app: XCUIApplication, screen: InsightsScreen) {
        let app = launch(LaunchOptions(seed: seed))
        let root = RootNavigationScreen(app: app)
        try requireCondition(root.waitUntilReady(), in: app, "根導覽未就緒")
        try requireCondition(root.goToInsights(), in: app, "分析分頁未就緒")

        let screen = InsightsScreen(app: app)
        try requireCondition(screen.waitUntilReady(), in: app, "分析內容未就緒")
        return (app, screen)
    }

    /// 讀取期間、趨勢、類別、成本與熱力圖的有效快照框線
    ///
    /// - Parameters:
    ///   - screen: 分析 Page Object
    ///   - app: 受測 App
    ///   - campaignID: 開團排行識別碼；傳 `nil` 時不量測開團排行
    /// - Returns: 固定內容的快照框線
    /// - Throws: 任一元素不存在或沒有有效框線時丟出測試錯誤
    func readFrames(
        on screen: InsightsScreen,
        in app: XCUIApplication,
        campaignID: String? = nil
    ) throws -> LayoutFrames {
        let identifiers = screen.prepareLayoutSnapshot(campaignID: campaignID)
        let snapshot = try app.framesInSingleSnapshot(for: identifiers, within: screen.rootElement)
        try requireCondition(
            snapshot.missingIdentifiers.isEmpty && snapshot.duplicateIdentifiers.isEmpty,
            in: app,
            """
            分析快照缺少 identifier: \(snapshot.missingIdentifiers)
            重複 identifier: \(snapshot.duplicateIdentifiers)
            """
        )

        let campaignFrame: CGRect?
        if let campaignID {
            campaignFrame = snapshot.frames[
                BLAccessibilityID.Insights.campaignRankRow(campaignID: campaignID)
            ]
        } else {
            campaignFrame = nil
        }
        return LayoutFrames(
            range: try requireValue(
                snapshot.frames[BLAccessibilityID.Insights.rangePicker],
                in: app,
                "找不到分析期間選擇器有效框線"
            ),
            trend: try requireValue(
                snapshot.frames[BLAccessibilityID.Insights.trendChart],
                in: app,
                "找不到分析趨勢卡有效框線"
            ),
            category: try requireValue(
                snapshot.frames[BLAccessibilityID.Insights.categoryRankRow(category: "美妝")],
                in: app,
                "找不到美妝類別排行有效框線"
            ),
            cost: try requireValue(
                snapshot.frames[BLAccessibilityID.Insights.costDonut],
                in: app,
                "找不到成本圓餅圖有效框線"
            ),
            heatmap: try requireValue(
                snapshot.frames[BLAccessibilityID.Insights.heatmap],
                in: app,
                "找不到下單熱力圖有效框線"
            ),
            campaign: campaignFrame
        )
    }

    /// 判斷第一個元素是否在第二個元素上方且沒有垂直重疊
    ///
    /// - Parameters:
    ///   - first: 上方元素框線
    ///   - second: 下方元素框線
    /// - Returns: 上下順序是否成立
    func isAbove(_ first: CGRect, _ second: CGRect) -> Bool {
        first.maxY <= second.minY
    }
}
