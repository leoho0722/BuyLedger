//
//  DashboardLayoutSmokeTests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/10/30.
//

import XCTest

/// 總覽固定內容順序、KPI 欄數與數值可由輔助功能讀取的 UI 測試
@MainActor
final class DashboardLayoutSmokeTests: BLUITestCase {

    /// 驗證標準字級時四項 KPI 以兩欄排列，摘要、開團與近期訂單
    /// 仍保持垂直順序
    ///
    /// - Throws: 畫面元素缺少、KPI 值不符或版面順序錯誤時丟出測試錯誤
    func testDashboardLayout_標準字級_四項KPI兩欄且內容順序固定() throws {
        // Given
        let context = try openDashboard()

        // When
        let layout = try readLayout(on: context.screen, in: context.app)

        // Then
        try assertKPIValues(layout.values, in: context.app)
        try requireCondition(
            isAbove(layout.frames.date, layout.frames.hero)
                && isAbove(layout.frames.hero, layout.frames.revenue)
                && isSameRow(layout.frames.revenue, layout.frames.cost)
                && isSameRow(layout.frames.grossMargin, layout.frames.activeOrders)
                && isSameColumn(layout.frames.revenue, layout.frames.grossMargin)
                && isSameColumn(layout.frames.cost, layout.frames.activeOrders)
                && isAbove(layout.frames.revenue, layout.frames.grossMargin)
                && isAbove(layout.frames.grossMargin, layout.frames.campaign)
                && isAbove(layout.frames.activeOrders, layout.frames.campaign)
                && isAbove(layout.frames.campaign, layout.frames.recentOrder),
            in: context.app,
            "總覽摘要、四項 KPI、開團與近期訂單未依序排列"
        )
    }

    /// 驗證最大輔助字級時四項 KPI 依序單欄顯示，數值可由輔助功能讀取
    ///
    /// - Throws: 畫面元素缺少、KPI 值不符或版面順序錯誤時丟出測試錯誤
    func testDashboardLayout_最大輔助字級_四項KPI單欄且數值可由輔助功能讀取() throws {
        // Given
        let context = try openDashboard(contentSizeCategory: .accessibilityExtraExtraExtraLarge)

        // When
        let layout = try readLayout(on: context.screen, in: context.app)

        // Then
        try assertKPIValues(layout.values, in: context.app)
        try requireCondition(
            isAbove(layout.frames.date, layout.frames.hero)
                && isAbove(layout.frames.hero, layout.frames.revenue)
                && isAbove(layout.frames.revenue, layout.frames.cost)
                && isAbove(layout.frames.cost, layout.frames.grossMargin)
                && isAbove(layout.frames.grossMargin, layout.frames.activeOrders)
                && isAbove(layout.frames.activeOrders, layout.frames.campaign)
                && isAbove(layout.frames.campaign, layout.frames.recentOrder),
            in: context.app,
            "最大輔助字級的總覽 KPI 未逐列顯示或內容順序錯誤"
        )
    }
}

// MARK: - Nested Types

private extension DashboardLayoutSmokeTests {

    /// 總覽語意元素的快照框線
    struct LayoutFrames {

        /// 日期副標框線
        let date: CGRect

        /// 本月摘要 hero 框線
        let hero: CGRect

        /// 營業額 KPI 框線
        let revenue: CGRect

        /// 成本 KPI 框線
        let cost: CGRect

        /// 毛利率 KPI 框線
        let grossMargin: CGRect

        /// 進行中訂單 KPI 框線
        let activeOrders: CGRect

        /// 開團列框線
        let campaign: CGRect

        /// 近期訂單列框線
        let recentOrder: CGRect
    }

    /// 營收歸屬種子下四項 KPI 的 accessibility value
    struct KPIValues {

        /// 營業額
        let revenue: String

        /// 成本
        let cost: String

        /// 毛利率
        let grossMargin: String

        /// 進行中訂單數
        let activeOrders: String
    }
}

// MARK: - Private Method

private extension DashboardLayoutSmokeTests {

    /// 啟動固定營收歸屬資料並等待總覽就緒
    ///
    /// - Parameter contentSizeCategory: 要套用的 UIKit 動態字級
    /// - Returns: 已就緒的 App 與總覽畫面
    /// - Throws: 根導覽或總覽未就緒時丟出測試錯誤
    func openDashboard(
        contentSizeCategory: LaunchOptions.ContentSizeCategory? = nil
    ) throws -> (app: XCUIApplication, screen: DashboardScreen) {
        let app = launch(
            LaunchOptions(seed: .revenueAttribution, contentSizeCategory: contentSizeCategory)
        )
        let root = RootNavigationScreen(app: app)
        try requireCondition(root.waitUntilReady(), in: app, "根導覽未就緒")
        try requireCondition(root.goToDashboard(), in: app, "總覽分頁未就緒")

        let screen = DashboardScreen(app: app)
        try requireCondition(screen.waitUntilReady(), in: app, "總覽內容未就緒")
        return (app, screen)
    }

    /// 讀取總覽日期、摘要、KPI、開團與近期訂單框線
    ///
    /// - Parameters:
    ///   - screen: 總覽 Page Object
    ///   - app: 受測 App
    /// - Returns: 全部必要語意元素的快照框線
    /// - Throws: 任一元素不存在或沒有有效框線時丟出測試錯誤
    func readLayout(
        on screen: DashboardScreen,
        in app: XCUIApplication
    ) throws -> (frames: LayoutFrames, values: KPIValues) {
        let identifiers = screen.prepareLayoutSnapshot(
            campaignID: "UITEST-REV-CAM-001",
            orderID: "UITEST-REV-RESULT"
        )
        let snapshot = try app.framesInSingleSnapshot(for: identifiers, within: screen.rootElement)
        try requireCondition(
            snapshot.missingIdentifiers.isEmpty && snapshot.duplicateIdentifiers.isEmpty,
            in: app,
            """
            總覽快照缺少 identifier: \(snapshot.missingIdentifiers)
            重複 identifier: \(snapshot.duplicateIdentifiers)
            """
        )
        let date = try requireValue(
            snapshot.frames[BLAccessibilityID.Dashboard.currentDateSubtitle],
            in: app,
            "找不到總覽日期副標框線"
        )
        let hero = try requireValue(
            snapshot.frames[BLAccessibilityID.Dashboard.kpiTile(.netProfit)],
            in: app,
            "找不到摘要 hero 框線"
        )
        let revenueFrame = try requireValue(
            snapshot.frames[BLAccessibilityID.Dashboard.kpiTile(.revenue)],
            in: app,
            "找不到營業額 KPI 框線"
        )
        let revenueValue = try requireValue(screen.kpiValue(.revenue), in: app, "找不到營業額 KPI 值")
        let costFrame = try requireValue(
            snapshot.frames[BLAccessibilityID.Dashboard.kpiTile(.cost)],
            in: app,
            "找不到成本 KPI 框線"
        )
        let costValue = try requireValue(screen.kpiValue(.cost), in: app, "找不到成本 KPI 值")
        let marginFrame = try requireValue(
            snapshot.frames[BLAccessibilityID.Dashboard.kpiTile(.grossMargin)],
            in: app,
            "找不到毛利率 KPI 框線"
        )
        let marginValue = try requireValue(screen.kpiValue(.grossMargin), in: app, "找不到毛利率 KPI 值")
        let ordersFrame = try requireValue(
            snapshot.frames[BLAccessibilityID.Dashboard.kpiTile(.activeOrders)],
            in: app,
            "找不到進行中訂單 KPI 框線"
        )
        let ordersValue = try requireValue(
            screen.kpiValue(.activeOrders),
            in: app,
            "找不到進行中訂單 KPI 值"
        )
        let campaign = try requireValue(
            snapshot.frames[
                BLAccessibilityID.Dashboard.ongoingCampaignRow(campaignID: "UITEST-REV-CAM-001")
            ],
            in: app,
            "找不到營收驗收開團列有效框線"
        )
        let recentOrder = try requireValue(
            snapshot.frames[
                BLAccessibilityID.Dashboard.recentOrderRow(orderID: "UITEST-REV-RESULT")
            ],
            in: app,
            "找不到近期合併訂單列有效框線"
        )
        return (
            frames: LayoutFrames(
                date: date,
                hero: hero,
                revenue: revenueFrame,
                cost: costFrame,
                grossMargin: marginFrame,
                activeOrders: ordersFrame,
                campaign: campaign,
                recentOrder: recentOrder
            ),
            values: KPIValues(
                revenue: revenueValue,
                cost: costValue,
                grossMargin: marginValue,
                activeOrders: ordersValue
            )
        )
    }

    /// 比對固定種子下的營業額、成本、毛利率與進行中訂單數是否符合預期
    ///
    /// - Parameters:
    ///   - values: 已讀取的 KPI 值
    ///   - app: 受測 App
    /// - Throws: 任一 KPI 值與固定種子預期不符時丟出測試錯誤
    func assertKPIValues(_ values: KPIValues, in app: XCUIApplication) throws {
        try requireCondition(values.revenue.contains("18,000"), in: app, "營業額 KPI 不含 18,000")
        try requireCondition(values.cost.contains("11,270"), in: app, "成本 KPI 不含 11,270")
        try requireCondition(values.grossMargin.contains("37.4"), in: app, "毛利率 KPI 不含 37.4%")
        try requireCondition(values.activeOrders == "0", in: app, "進行中訂單 KPI 不為 0")
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

    /// 判斷兩個元素是否處於同列且水平分離
    ///
    /// - Parameters:
    ///   - leading: 預期位於左側的元素框線
    ///   - trailing: 預期位於右側的元素框線
    /// - Returns: 兩個框線是否同列且不重疊
    func isSameRow(_ leading: CGRect, _ trailing: CGRect) -> Bool {
        leading.minX < trailing.minX
            && leading.maxX <= trailing.minX
            && leading.minY < trailing.maxY
            && trailing.minY < leading.maxY
    }

    /// 判斷兩個元素的左緣是否對齊
    ///
    /// - Parameters:
    ///   - upper: 上方元素框線
    ///   - lower: 下方元素框線
    /// - Returns: 左緣差距是否不超過一個 point
    func isSameColumn(_ upper: CGRect, _ lower: CGRect) -> Bool {
        abs(upper.minX - lower.minX) <= 1
    }
}
