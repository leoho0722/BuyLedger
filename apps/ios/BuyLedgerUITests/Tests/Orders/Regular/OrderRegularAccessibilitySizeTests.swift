//
//  OrderRegularAccessibilitySizeTests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/10/20.
//

import CoreGraphics
import XCTest

/// regular 訂單篩選區在標準與最大輔助字級的捲動歸屬守門
final class OrderRegularAccessibilitySizeTests: BLUITestCase {

    // MARK: - Properties

    /// regular 測試的版面限制與 compact 覆蓋來源
    private static let layoutScopeReason = """
    篩選區歸屬只適用 regular 版面
    compact 篩選由 OrderFilterSheetTests 覆蓋
    """

    /// 直向最大輔助字級的篩選控制項位於清單捲動區內，並依序排列
    ///
    /// - Throws: 版面不適用、必要元素缺少或篩選控制項越界時拋出測試錯誤
    @MainActor
    func testRegularFilters_直向最大輔助字級_篩選區在清單捲動範圍內且不重疊() throws(any Error) {
        // Given
        let options = LaunchOptions(
            seed: .categoryFilter,
            contentSizeCategory: .accessibilityExtraExtraExtraLarge
        )
        let app = launch(options)
        try XCTSkipUnless(isRegularLayout(app), Self.layoutScopeReason)

        // When
        try openOrders(in: app)

        // Then
        try assertScrollableFilters(in: app)
    }

    /// 橫向最大輔助字級的篩選控制項位於清單捲動區內，並依序排列
    ///
    /// - Throws: 版面不適用、必要元素缺少或篩選控制項越界時拋出測試錯誤
    @MainActor
    func testRegularFilters_橫向最大輔助字級_篩選區在清單捲動範圍內且不重疊() throws(any Error) {
        // Given
        let options = LaunchOptions(
            seed: .categoryFilter,
            contentSizeCategory: .accessibilityExtraExtraExtraLarge
        )
        let app = launch(options)
        try XCTSkipUnless(isRegularLayout(app), Self.layoutScopeReason)

        // When
        try openOrders(in: app)
        try rotateToLandscape(app)

        // Then
        try assertScrollableFilters(in: app)
    }

    /// 標準字級的篩選區仍固定在清單捲動區上方
    ///
    /// - Throws: 版面不適用、必要元素缺少或篩選區進入捲動範圍時拋出測試錯誤
    @MainActor
    func testRegularFilters_標準字級_篩選區固定在清單捲動範圍上方() throws(any Error) {
        // Given
        let app = launch(LaunchOptions(seed: .categoryFilter))
        try XCTSkipUnless(isRegularLayout(app), Self.layoutScopeReason)

        // When
        try openOrders(in: app)

        // Then
        let list = app.descendants(matching: .any)[BLAccessibilityID.Orders.listRoot]
        let listFrame = try requireValidFrame(of: list, in: app, context: "訂單清單捲動範圍")
        let clearButton = app
            .descendants(matching: .any)[BLAccessibilityID.Orders.clearFiltersButton]
        let clearFrame = try requireValidFrame(of: clearButton, in: app, context: "清除篩選")
        try requireCondition(
            clearFrame.maxY <= listFrame.minY + 1,
            in: app,
            """
            位置越界：標準字級的清除篩選不在清單捲動範圍上方
            清除篩選 frame = \(clearFrame)，清單捲動範圍 frame = \(listFrame)
            """
        )
    }
}

// MARK: - Private Method

@MainActor
private extension OrderRegularAccessibilitySizeTests {

    /// 切到訂單分頁並等待清單根容器就緒
    ///
    /// - Parameter app: 受測 App
    /// - Throws: 訂單分頁或清單根容器未就緒時拋出測試錯誤
    func openOrders(in app: XCUIApplication) throws(any Error) {
        let root = RootNavigationScreen(app: app)
        try requireCondition(root.goToOrders(), in: app, "找不到元素：訂單分頁根容器")
        let orders = OrdersScreen(app: app)
        try requireCondition(orders.waitUntilReady(), in: app, "找不到元素：訂單清單根容器")
    }

    /// 逐項確認篩選控制項位於捲動範圍內，且與前一項沒有重疊
    ///
    /// - Parameter app: 受測 App
    /// - Throws: 必要元素缺少、篩選控制項越界或相鄰控制項重疊時拋出測試錯誤
    func assertScrollableFilters(in app: XCUIApplication) throws(any Error) {
        let list = app.descendants(matching: .any)[BLAccessibilityID.Orders.listRoot]
        let listFrame = try requireValidFrame(of: list, in: app, context: "訂單清單捲動範圍")
        let filters: [(identifier: String, name: String)] = [
            (BLAccessibilityID.Orders.statusChip("all"), "狀態膠囊"),
            (BLAccessibilityID.Orders.dateChip("all"), "全部時間膠囊"),
            (BLAccessibilityID.Orders.paymentMethodMenuButton, "付款方式"),
            (BLAccessibilityID.Orders.categoryFilterButton, "類別"),
            (BLAccessibilityID.Orders.clearFiltersButton, "清除篩選"),
        ]
        var previous: (name: String, frame: CGRect)?
        for (identifier, name) in filters {
            let element = app.descendants(matching: .any)[identifier]
            let frame = try requireValidFrame(of: element, in: app, context: name)
            try requireCondition(
                frame.minY >= listFrame.minY - 1,
                in: app,
                """
                位置越界：\(name) 不在清單捲動範圍內
                \(name) frame = \(frame)，清單捲動範圍 frame = \(listFrame)
                """
            )
            if let previous {
                try requireCondition(
                    previous.frame.maxY <= frame.minY + 1,
                    in: app,
                    """
                    位置越界：\(previous.name) 與 \(name) 重疊
                    \(previous.name) frame = \(previous.frame)，\(name) frame = \(frame)
                    """
                )
            }
            previous = (name, frame)
        }
    }
}
