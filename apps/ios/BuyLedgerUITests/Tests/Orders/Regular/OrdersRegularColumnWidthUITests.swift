//
//  OrdersRegularColumnWidthUITests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/10/20.
//

import XCTest

/// regular Orders 前景欄的可操作性與不互蓋 UI 測試
@MainActor
final class OrdersRegularColumnWidthUITests: BLUITestCase {

    /// 驗證橫向清單列與詳情摘要可互動，框線位於視窗內且不重疊
    ///
    /// - Throws: 版面不適用、必要元素缺少或前景錨點重疊時丟出測試錯誤
    func testOrderRow_橫向訂單列與詳情摘要_可互動且不重疊() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .mergeCandidates))
        let orders = try OrdersScreen.open(in: app)

        // When
        try rotateToLandscape(app)
        try XCTSkipUnless(
            try ordersLayout(in: app) == .regular,
            "前景欄不並排時不適用 regular 欄位案例"
        )
        let detail = try orders.tapOrder(orderID: OrdersSeedFixture.mergeOrderID)
        let rowFrame = try requireHittableFrame(
            of: orders.orderRow(orderID: OrdersSeedFixture.mergeOrderID),
            in: app,
            context: "選取的訂單列"
        )
        let summaryFrame = try requireHittableFrame(
            of: detail.summaryTile(.revenue),
            in: app,
            context: "詳情營收摘要"
        )
        let moreFrame = try requireHittableFrame(
            of: detail.moreButton,
            in: app,
            context: "詳情更多操作"
        )
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
        try requireCondition(
            windowFrame.contains(moreFrame),
            in: app,
            "詳情更多操作超出視窗"
        )
    }

    /// 驗證 regular 狀態膠囊選取後仍保留符合條件的 path
    ///
    /// - Throws: Orders 欄位、膠囊操作或 path 保留不符時丟出測試錯誤
    func testStatusFilterSelected_狀態膠囊可點_保留符合條件的path() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .fullOrders))
        let orders = try OrdersScreen.open(in: app)
        try XCTSkipUnless(
            try ordersLayout(in: app) == .regular,
            "狀態膠囊案例限 Orders 前景並排"
        )
        let detail = try orders.tapOrder(orderID: "BL-2604-018")
        let chipFrame = try requireHittableFrame(
            of: orders.statusChip("shipping"),
            in: app,
            context: "集運中狀態膠囊"
        )
        let windowFrame = try requireValidFrame(
            of: app.windows.firstMatch,
            in: app,
            context: "App 視窗"
        )
        try requireCondition(
            windowFrame.contains(chipFrame),
            in: app,
            "狀態膠囊超出可見視窗"
        )

        // When
        try orders.selectStatusChip(filterID: "shipping")

        // Then
        try requireCondition(
            orders.isRegularStatusChipSelected("shipping"),
            in: app,
            "集運中狀態膠囊應呈選取狀態"
        )
        let selectedOrderID = try requireValue(
            orders.pathProjectedOrderID(),
            in: app,
            "Orders path 選取標記不存在"
        )
        try requireCondition(
            selectedOrderID == "BL-2604-018",
            in: app,
            "篩選仍命中時應保留 BL-2604-018"
        )
        try requireCondition(
            detail.waitUntilReady(),
            in: app,
            "篩選仍命中後詳情工具列未保留"
        )
    }
}
