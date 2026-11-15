//
//  RootNavigationRegularColumnsUITests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/11/15.
//

import CoreGraphics
import XCTest

/// 訂單 regular 分頁的根導覽切換與側邊欄欄位歸屬 UI 測試
@MainActor
final class RootNavigationRegularColumnsUITests: BLUITestCase {

    /// 驗證直向叫出的側邊欄覆蓋清單且不推移清單欄
    ///
    /// - Throws: 版面不符、側邊欄並排、元素缺少或位置不符時丟出測試錯誤
    /// - Note: 側邊欄直接並排時沒有收起狀態，以 `XCTSkip` 宣告不適用
    func testRevealSidebarIfCollapsed_直向叫出收起的側邊欄_覆蓋清單且不推移清單欄()
    throws {
        // Given
        let app = try launch(LaunchOptions(seed: .mergeCandidates))
        let root = RootNavigationScreen(app: app)
        try root.goToOrders()
        try XCTSkipUnless(
            try ordersLayout(in: app) == .regular,
            OrdersRegularColumnScopeUITestSupport.layoutScopeReason
        )
        let orders = OrdersScreen(app: app)
        let row = orders.orderRow(orderID: OrdersSeedFixture.mergeOrderID)
        if let sidebarFrame = try sidebarColumnFrame(in: app, context: "選取前") {
            let rowFrame = try requireValidFrame(
                of: row,
                in: app,
                context: "叫出側邊欄前，訂單列"
            )
            try XCTSkipIf(
                sidebarFrame.maxX <= rowFrame.minX + 1,
                "側邊欄直接並排時沒有收起狀態；"
                    + "並排欄位順序由直向欄位測試覆蓋"
            )
        }
        try orders.tapOrder(orderID: OrdersSeedFixture.mergeOrderID)
        let rowBefore = try requireHittableFrame(
            of: row,
            in: app,
            context: "叫出側邊欄前，選取訂單列"
        )
        if let sidebarFrame = try sidebarColumnFrame(in: app, context: "選取後") {
            try requireCondition(
                sidebarFrame.maxX <= rowBefore.minX + 1,
                in: app,
                "前提不成立：選取訂單後側邊欄仍覆蓋清單"
            )
        }

        // When
        try AppNavigator(app: app).revealSidebarIfCollapsed()

        // Then
        let revealedSidebarFrame = try sidebarColumnFrame(in: app, context: "叫出後")
        let sidebarFrame = try requireValue(
            revealedSidebarFrame,
            in: app,
            "找不到叫出後的側邊欄欄位邊界"
        )
        let rowAfter = try requireValidFrame(
            of: row,
            in: app,
            context: "叫出側邊欄後，選取訂單列"
        )
        try requireCondition(
            abs(rowAfter.minX - rowBefore.minX) <= 1
                && sidebarFrame.maxX > rowAfter.minX,
            in: app,
            "位置越界：直向叫出的側邊欄沒有覆蓋清單，或清單被推移，"
                + "叫出前訂單列 \(rowBefore)，"
                + "叫出後訂單列 \(rowAfter)，側邊欄 \(sidebarFrame)"
        )
    }

    /// 驗證 regular 版面直向切到總覽後，訂單欄位消失且總覽佔滿視窗寬度
    ///
    /// - Throws: 版面不適用、分頁未就緒或總覽範圍不符時丟出測試錯誤
    func testTabSelected_切到總覽_訂單欄位消失且總覽佔滿() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .mergeCandidates))
        let root = RootNavigationScreen(app: app)
        try root.goToOrders()
        try XCTSkipUnless(
            try ordersLayout(in: app) == .regular,
            OrdersRegularColumnScopeUITestSupport.layoutScopeReason
        )
        let orders = OrdersScreen(app: app)
        let detail = try orders.tapOrder(orderID: OrdersSeedFixture.mergeOrderID)
        try rotateToPortrait(app)

        // When
        try root.goToDashboard()

        // Then
        try requireCondition(
            orders.rootElement.waitForDisappearance(),
            in: app,
            "切到總覽後訂單清單仍存在"
        )
        try requireCondition(
            detail.rootElement.waitForDisappearance(),
            in: app,
            "切到總覽後訂單詳情仍存在"
        )
        try requireCondition(
            orders.waitForDetailEmptyStateDismissal(),
            in: app,
            "切到總覽後訂單詳情空狀態仍存在"
        )
        try assertDashboardFillsPortraitWindow(in: app)
    }

    /// 驗證 regular 版面從總覽切回訂單後，清單控制項歸屬正確且詳情保留
    ///
    /// - Throws: 版面不適用、分頁未就緒或欄位歸屬不符時丟出測試錯誤
    func testTabSelected_切回訂單_清單控制項歸屬正確且詳情保留() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .mergeCandidates))
        let root = RootNavigationScreen(app: app)
        try root.goToOrders()
        try XCTSkipUnless(
            try ordersLayout(in: app) == .regular,
            OrdersRegularColumnScopeUITestSupport.layoutScopeReason
        )
        let orders = OrdersScreen(app: app)
        let detail = try orders.tapOrder(orderID: OrdersSeedFixture.mergeOrderID)
        try root.goToDashboard()

        // When
        try root.goToOrders()

        // Then
        try OrdersRegularColumnScopeUITestSupport.assertListControls(
            orders,
            in: app,
            testCase: self,
            context: "切回訂單後 (直向)"
        )
        try requireCondition(
            detail.waitUntilReady(),
            in: app,
            "找不到元素：切回訂單後詳情欄未保留選取訂單的詳情"
        )
        let projectedOrderID = orders.pathProjectedOrderID()
        try requireCondition(
            projectedOrderID == "UITEST-MRG-001",
            in: app,
            "切回訂單後預期 path 投影 UITEST-MRG-001，"
                + "實際為 \(String(describing: projectedOrderID))"
        )
    }
}

// MARK: - Private Method

private extension RootNavigationRegularColumnsUITests {

    /// 以原生側邊欄導覽列取得側邊欄欄界，不用品牌標記估算欄寬
    ///
    /// - Parameters:
    ///   - app: 受測 App
    ///   - context: 方向或側邊欄切換階段
    /// - Returns: 側邊欄可見時的 NavigationBar 框線，否則為 `nil`
    /// - Throws: 側邊欄標記存在但導覽列缺少或欄界超出視窗時丟出測試錯誤
    func sidebarColumnFrame(in app: XCUIApplication, context: String) throws -> CGRect? {
        let sidebarNavigationBar = app.navigationBars
            .containing(.button, identifier: SystemAccessibilityID.sidebarToggleButton)
            .firstMatch
        guard sidebarNavigationBar.exists else {
            return nil
        }

        let sidebarFrame = try requireValidFrame(
            of: sidebarNavigationBar,
            in: app,
            context: "\(context)，原生側邊欄導覽列"
        )
        let windowFrame = try requireValidFrame(
            of: app.windows.firstMatch,
            in: app,
            context: "\(context)，側邊欄欄界視窗"
        )
        try requireCondition(
            sidebarFrame.minX >= windowFrame.minX - 1
                && sidebarFrame.maxX <= windowFrame.maxX + 1,
            in: app,
            "側邊欄導覽列欄界超出視窗："
                + "導覽列 \(sidebarFrame)，視窗 \(windowFrame)"
        )
        return sidebarFrame
    }

    /// 確認直向總覽左右緣貼齊視窗，沒有左側空隙也沒有右側截斷
    ///
    /// - Parameter app: 受測 App
    /// - Throws: 總覽或視窗範圍無法取得，或左右緣未貼齊時丟出測試錯誤
    func assertDashboardFillsPortraitWindow(in app: XCUIApplication) throws {
        let windowFrame = try requireValidFrame(
            of: app.windows.firstMatch,
            in: app,
            context: "總覽佔滿的視窗"
        )
        let dashboardFrame = try requireValidFrame(
            of: DashboardScreen(app: app).rootElement,
            in: app,
            context: "切到總覽後的總覽內容"
        )
        try requireCondition(
            abs(dashboardFrame.minX - windowFrame.minX) <= 1
                && abs(dashboardFrame.maxX - windowFrame.maxX) <= 1,
            in: app,
            "位置越界：切到總覽後總覽未貼齊直向視窗左右緣，"
                + "總覽 frame = \(dashboardFrame)，視窗 frame = \(windowFrame)"
        )
    }
}
