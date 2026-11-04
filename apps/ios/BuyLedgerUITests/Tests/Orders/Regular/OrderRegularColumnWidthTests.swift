//
//  OrderRegularColumnWidthTests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/10/20.
//

import XCTest

/// regular Orders 前景欄的可操作性與不互蓋 UI 測試
@MainActor
final class OrderRegularColumnWidthTests: BLUITestCase {

    // MARK: - Properties

    /// `mergeCandidates` 中明確選取的訂單編號
    private static let orderID = "UITEST-MRG-001"

    /// 驗證清單列與詳情摘要在橫向並排且可互動，框線位於視窗內且不重疊
    ///
    /// - Throws: 版面不適用、必要元素缺少或前景錨點重疊時丟出測試錯誤
    func testRegularColumns_橫向訂單列與詳情摘要_可互動且不重疊() throws {
        // Given
        let app = launch(LaunchOptions(seed: .mergeCandidates))
        let orders = try openOrders(in: app)
        try rotateToLandscape(app)
        orders.tapOrder(orderID: Self.orderID)
        try requireCondition(
            OrderDetailScreen(app: app).waitUntilReady(),
            in: app,
            "選取合併候選訂單後詳情未就緒"
        )
        try XCTSkipUnless(isRegularLayout(app), "前景欄不並排時不適用 regular 欄位案例")

        // When
        let row = orders.orderRow(orderID: Self.orderID)
        let rowFrame = try requireHittableFrame(of: row, in: app, context: "選取的訂單列")
        let summary = app.descendants(matching: .any)[
            BLAccessibilityID.Orders.detailSummaryTile(.revenue)
        ]
        let summaryFrame = try requireHittableFrame(of: summary, in: app, context: "詳情營收摘要")
        let moreButton = app.buttons[BLAccessibilityID.Orders.detailMoreButton].firstMatch
        let moreFrame = try requireHittableFrame(of: moreButton, in: app, context: "詳情更多操作")
        let windowFrame = try requireValidFrame(
            of: app.windows.firstMatch,
            in: app,
            context: "App 視窗"
        )

        // Then
        try requireCondition(
            windowFrame.contains(rowFrame) && windowFrame.contains(summaryFrame),
            in: app,
            "清單列與詳情摘要必須完整落在 App 視窗內"
        )
        try requireCheckPassed(
            BoundsCheck.verify(
                frame: rowFrame,
                container: windowFrame,
                reservedRegions: [summaryFrame]
            ),
            in: app
        )
        try requireCondition(windowFrame.contains(moreFrame), in: app, "詳情更多操作超出視窗")
    }

    /// 驗證 regular 狀態膠囊位於可互動範圍，選取後仍保留符合條件的 path
    ///
    /// - Throws: Orders 欄位、膠囊操作或 path 保留不符合預期時丟出測試錯誤
    func testRegularColumns_狀態膠囊可點_保留符合條件的path() throws {
        // Given
        let app = launch(LaunchOptions(seed: .fullOrders))
        let orders = try openOrders(in: app)
        orders.tapOrder(orderID: "BL-2604-018")
        try requireCondition(OrderDetailScreen(app: app).waitUntilReady(), in: app, "選取集運中訂單後詳情未就緒")
        try XCTSkipUnless(isRegularLayout(app), "狀態膠囊案例限 Orders 前景並排")

        let chipID = BLAccessibilityID.Orders.statusChip("shipping")
        let chip = app.buttons[chipID].firstMatch
        let chipFrame = try requireHittableFrame(of: chip, in: app, context: "集運中狀態膠囊")
        let windowFrame = try requireValidFrame(
            of: app.windows.firstMatch,
            in: app,
            context: "App 視窗"
        )
        try requireCondition(windowFrame.contains(chipFrame), in: app, "狀態膠囊超出可見視窗")

        // When
        orders.selectStatusChip(filterID: "shipping")

        // Then
        try requireCondition(
            orders.isRegularStatusChipSelected("shipping"),
            in: app,
            "集運中狀態膠囊應呈選取狀態"
        )
        let selectedOrderID = try requireValue(
            orders.pathProjectedOrderID,
            in: app,
            "Orders path 選取標記不存在"
        )
        try requireCondition(selectedOrderID == "BL-2604-018", in: app, "篩選仍命中詳情時應保留 BL-2604-018")
        try requireCondition(
            OrderDetailScreen(app: app).waitUntilReady(),
            in: app,
            "篩選仍命中後詳情工具列未保留"
        )
    }
}

// MARK: - Private Method

private extension OrderRegularColumnWidthTests {

    /// 切到 Orders 並等待清單前景就緒
    ///
    /// - Parameter app: 已啟動的受測 App
    /// - Returns: 訂單清單 Page Object
    /// - Throws: 根分頁或清單根未就緒時丟出測試錯誤
    func openOrders(in app: XCUIApplication) throws -> OrdersScreen {
        let navigator = AppNavigator(app: app)
        try requireCondition(navigator.tapRootTab(.orders), in: app, "無法切到訂單分頁")
        let orders = OrdersScreen(app: app)
        try requireCondition(orders.waitUntilReady(), in: app, "訂單清單未就緒")
        return orders
    }
}
