//
//  OrderRegularColumnWidthTests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/10/20.
//

import CoreGraphics
import XCTest

/// regular 訂單清單欄與詳情欄的欄寬守門 UI 測試
@MainActor
final class OrderRegularColumnWidthTests: BLUITestCase {

    // MARK: - Properties

    /// `mergeCandidates` 中明確選取的訂單編號
    private static let orderID = "UITEST-MRG-001"

    /// 側邊欄收起或覆蓋時的清單欄寬度
    private static let standardListWidth: CGFloat = 320

    /// 版面不符時略過測試的原因，說明 compact 清單由哪個測試覆蓋
    private static let layoutScopeReason = """
    欄寬只適用 regular 版面
    compact 清單由 OrdersListTests 覆蓋
    """

    /// 驗證 regular 版面橫向且側邊欄並排時，清單欄與詳情欄平分側邊欄右側的寬度，兩欄寬度相差不超過 2 點
    ///
    /// - Throws: 版面不適用、必要元素缺少或兩欄寬度不符時丟出測試錯誤
    func testRegularColumnWidth_橫向側邊欄並排_清單與詳情各佔一半() throws {
        // Given
        let app = launch(LaunchOptions(seed: .mergeCandidates))
        try XCTSkipUnless(isRegularLayout(app), Self.layoutScopeReason)
        try openSelectedOrder(in: app)

        // When
        try rotateToLandscape(app)

        // Then
        let sidebar = app.descendants(matching: .any)[BLAccessibilityID.Root.sidebar]
        try requireCondition(sidebar.waitForExistence(timeout: 10), in: app, "找不到元素：橫向的側邊欄")
        let widths = try settledColumnWidths(in: app, context: "橫向") {
            abs($0.list - $0.detail) <= 2
        }
        try requireCondition(
            abs(widths.list - widths.detail) <= 2,
            in: app,
            "欄寬不符：橫向清單欄 \(widths.list)、詳情欄 \(widths.detail)，應相差不超過 2 點"
        )
        let sidebarFrame = try requireValidFrame(of: sidebar, in: app, context: "橫向的側邊欄")
        try assertColumnsFill(
            widths,
            from: sidebarFrame.maxX,
            in: app,
            context: "橫向側邊欄右側"
        )
    }

    /// 驗證 regular 版面直向時清單欄為標準寬度 320 點，轉到橫向再轉回直向後清單欄仍為 320 點且兩欄都顯示
    ///
    /// - Throws: 版面不適用、必要元素缺少、欄寬不符或轉向後欄位消失時丟出測試錯誤
    /// - Note: 情境流程：受測的就是往返轉向，轉到橫向後兩欄仍顯示是前置確認，轉回直向為受測動作
    func testRegularColumnWidth_直向轉橫向再轉回_清單維持標準寬且兩欄仍顯示() throws {
        // Given
        let app = launch(LaunchOptions(seed: .mergeCandidates))
        try XCTSkipUnless(isRegularLayout(app), Self.layoutScopeReason)
        try openSelectedOrder(in: app)
        let portraitBefore = try settledColumnWidths(in: app, context: "直向") {
            abs($0.list - Self.standardListWidth) <= 1
        }
        try rotateToLandscape(app)
        try assertColumnsShown(in: app, context: "轉到橫向後")

        // When
        try rotateToPortrait(app)

        // Then
        try assertColumnsShown(in: app, context: "轉回直向後")
        let portraitAfter = try settledColumnWidths(in: app, context: "轉回直向") {
            abs($0.list - Self.standardListWidth) <= 1
        }
        let window = try requireValidFrame(of: app.windows.firstMatch, in: app, context: "App 視窗")
        for (widths, context) in [(portraitBefore, "直向"), (portraitAfter, "轉回直向")] {
            try requireCondition(
                abs(widths.list - Self.standardListWidth) <= 1,
                in: app,
                "欄寬不符：\(context)清單欄 \(widths.list)，應為 \(Self.standardListWidth) 點"
            )
            try assertColumnsFill(
                widths,
                from: window.minX,
                in: app,
                context: "\(context)視窗"
            )
        }
    }
}

// MARK: - Nested Types

private extension OrderRegularColumnWidthTests {

    /// 清單欄與詳情欄的量測結果
    struct ColumnWidths {

        /// 清單欄寬度
        let list: CGFloat

        /// 清單欄左緣
        let listMinX: CGFloat

        /// 詳情欄寬度
        let detail: CGFloat

        /// 詳情欄右緣
        let detailMaxX: CGFloat
    }
}

// MARK: - Private Method

private extension OrderRegularColumnWidthTests {

    /// 切到訂單並明確選取種子訂單，等待詳情內容就緒
    ///
    /// - Parameter app: 受測 App
    /// - Throws: 訂單分頁或詳情未就緒時丟出測試錯誤
    func openSelectedOrder(in app: XCUIApplication) throws {
        let root = RootNavigationScreen(app: app)
        try requireCondition(root.goToOrders(), in: app, "找不到元素：訂單分頁根容器")
        let orders = OrdersScreen(app: app)
        try requireCondition(orders.waitUntilReady(), in: app, "找不到元素：訂單清單根容器")
        orders.tapOrder(orderID: Self.orderID)
        let detail = OrderDetailScreen(app: app)
        try requireCondition(detail.waitUntilReady(), in: app, "找不到元素：選取訂單的詳情根容器")
    }

    /// 在逾時內重複量測兩欄寬度，直到符合預期或逾時，回傳最後一次量測
    ///
    /// - Parameters:
    ///   - app: 受測 App
    ///   - context: 失敗訊息中的檢查情境
    ///   - isExpected: 判斷量測結果是否已符合預期
    /// - Returns: 最後一次量測的兩欄寬度
    /// - Throws: 必要元素缺少時丟出測試錯誤
    func settledColumnWidths(
        in app: XCUIApplication,
        context: String,
        until isExpected: (ColumnWidths) -> Bool
    ) throws -> ColumnWidths {
        let deadline = Date.now.addingTimeInterval(5)
        var widths = try columnWidths(in: app, context: context)
        while !isExpected(widths), Date.now < deadline {
            // 欄寬在量到視窗座標後才更新，讓出 run loop 後重量
            RunLoop.current.run(until: Date.now.addingTimeInterval(0.25))
            widths = try columnWidths(in: app, context: context)
        }
        return widths
    }

    /// 量測清單欄與詳情欄的寬度
    ///
    /// - Parameters:
    ///   - app: 受測 App
    ///   - context: 失敗訊息中的檢查情境
    /// - Returns: 兩欄寬度與清單欄左緣
    /// - Throws: 清單根容器、選取訂單列或詳情根容器缺少時丟出測試錯誤
    /// - Note: iPadOS 26 的 `Orders.listRoot` 左緣延伸到側邊欄底下，清單欄寬改以左右內距相同的訂單列中心推算
    func columnWidths(in app: XCUIApplication, context: String) throws -> ColumnWidths {
        let list = app.descendants(matching: .any)[BLAccessibilityID.Orders.listRoot]
        let listFrame = try requireValidFrame(of: list, in: app, context: "\(context)，訂單清單根容器")
        let row = OrdersScreen(app: app).orderRow(orderID: Self.orderID)
        let rowFrame = try requireHittableFrame(of: row, in: app, context: "\(context)，選取訂單列")
        let detail = app.descendants(matching: .any)[BLAccessibilityID.Orders.detailRoot]
        let detailFrame = try requireValidFrame(of: detail, in: app, context: "\(context)，訂單詳情欄")
        let listWidth = (listFrame.maxX - rowFrame.midX) * 2
        return ColumnWidths(
            list: listWidth,
            listMinX: listFrame.maxX - listWidth,
            detail: detailFrame.width,
            detailMaxX: detailFrame.maxX
        )
    }

    /// 確認清單欄從指定左界開始，詳情欄延伸到視窗右緣
    ///
    /// - Parameters:
    ///   - widths: 兩欄的量測結果
    ///   - leadingEdge: 清單欄應貼齊的左界 (並排側邊欄右緣或視窗左緣)
    ///   - app: 受測 App
    ///   - context: 失敗訊息中的檢查情境
    /// - Throws: 清單欄沒有貼齊左界或詳情欄沒有延伸到視窗右緣時丟出測試錯誤
    func assertColumnsFill(
        _ widths: ColumnWidths,
        from leadingEdge: CGFloat,
        in app: XCUIApplication,
        context: String
    ) throws {
        let window = try requireValidFrame(of: app.windows.firstMatch, in: app, context: "App 視窗")
        try requireCondition(
            abs(widths.listMinX - leadingEdge) <= 2 && abs(widths.detailMaxX - window.maxX) <= 1,
            in: app,
            """
            欄寬不符：清單欄與詳情欄沒有填滿\(context)到視窗右緣
            左界 \(leadingEdge)，清單欄左緣 \(widths.listMinX)，詳情欄右緣 \(widths.detailMaxX)，\
            視窗右緣 \(window.maxX)
            """
        )
    }

    /// 確認清單欄與詳情欄都仍在畫面上且可互動
    ///
    /// - Parameters:
    ///   - app: 受測 App
    ///   - context: 失敗訊息中的檢查情境
    /// - Throws: 任一欄位消失時丟出測試錯誤
    func assertColumnsShown(in app: XCUIApplication, context: String) throws {
        for (identifier, name) in [
            (BLAccessibilityID.Orders.listRoot, "訂單清單欄"),
            (BLAccessibilityID.Orders.detailRoot, "訂單詳情欄"),
        ] {
            _ = try requireHittableFrame(
                of: app.descendants(matching: .any)[identifier],
                in: app,
                context: "\(context)，\(name)"
            )
        }
    }
}
