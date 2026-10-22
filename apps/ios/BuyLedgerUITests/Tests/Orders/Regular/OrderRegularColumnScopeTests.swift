//
//  OrderRegularColumnScopeTests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/10/20.
//

import XCTest

/// regular 訂單分頁的清單、詳情與側邊欄歸屬守門
final class OrderRegularColumnScopeTests: BLUITestCase {

    // MARK: - Properties

    /// `mergeCandidates` 中明確選取的訂單編號
    static let orderID = "UITEST-MRG-001"

    /// 種子訂單的客戶名稱，不隨 App 語言變動
    static let customerName = "林書宇"

    /// regular 測試的版面限制與 compact 覆蓋來源
    private static let layoutScopeReason = """
    欄位歸屬只適用 regular 版面；compact 清單由 OrdersListTests 覆蓋
    compact 詳情由 OrderDetailTests 與 OrderDetailMenuTests 覆蓋
    """

    /// 清單搜尋、筆數與操作在兩個方向都只佔用清單欄
    ///
    /// - Throws: 版面不適用、必要元素缺少或控制項越界時拋出測試錯誤
    @MainActor
    func testRegularColumns_選取訂單_清單控制項只在清單欄內() throws {
        // Given
        let app = launch(LaunchOptions(seed: .mergeCandidates))
        try XCTSkipUnless(isRegularLayout(app), Self.layoutScopeReason)

        // When
        let orders = try openSelectedOrder(in: app)

        // Then
        try assertListControls(orders, in: app, context: "直向")
        try rotateToLandscape(app)
        try assertListControls(orders, in: app, context: "橫向")
    }

    /// 直向允許側邊欄收起，橫向要求三欄依序並排且不重疊
    ///
    /// - Throws: 版面不適用、必要元素缺少或欄位重疊時拋出測試錯誤
    @MainActor
    func testRegularColumns_依方向顯示側邊欄_可見欄位依序並排且不重疊() throws {
        // Given
        let app = launch(LaunchOptions(seed: .mergeCandidates))
        try XCTSkipUnless(isRegularLayout(app), Self.layoutScopeReason)

        // When
        _ = try openSelectedOrder(in: app)

        // Then
        try assertColumnOrder(in: app, context: "直向", isSidebarRequired: false)
        try assertRevealedSidebarOverlays(in: app)
        try rotateToLandscape(app)
        try assertColumnOrder(in: app, context: "橫向", isSidebarRequired: true)
    }

    /// 詳情欄獨立的系統導覽列顯示客戶名稱與訂單操作
    ///
    /// - Throws: 版面不適用、詳情導覽列缺少或操作越界時拋出測試錯誤
    @MainActor
    func testRegularColumns_選取訂單_詳情導覽列承載客戶與選單() throws {
        // Given
        let app = launch(LaunchOptions(seed: .mergeCandidates))
        try XCTSkipUnless(isRegularLayout(app), Self.layoutScopeReason)

        // When
        _ = try openSelectedOrder(in: app)

        // Then
        try assertDetailNavigationBar(in: app)
    }

    /// 多選控制項留在清單欄，詳情欄仍保有原訂單的導覽列
    ///
    /// - Throws: 版面不適用、必要元素缺少或導覽列歸屬不符時拋出測試錯誤
    @MainActor
    func testRegularColumns_進入多選_清單控制項與詳情導覽列各自獨立() throws {
        // Given
        let app = launch(LaunchOptions(seed: .mergeCandidates))
        try XCTSkipUnless(isRegularLayout(app), Self.layoutScopeReason)
        let orders = try openSelectedOrder(in: app)

        // When
        try orders.enterSelectionMode()

        // Then
        let bounds = try listColumnBounds(in: app, context: "多選")
        for identifier in [
            BLAccessibilityID.Orders.selectAllButton,
            BLAccessibilityID.Orders.batchStatusMenuButton,
            BLAccessibilityID.Orders.selectionDoneButton,
        ] {
            try assertHorizontalBounds(
                of: app.descendants(matching: .any)[identifier],
                between: bounds.lowerBound,
                and: bounds.upperBound,
                in: app,
                context: "多選控制項 \(identifier)"
            )
        }
        try assertDetailNavigationBar(in: app)
    }

    /// 多選勾選一筆後，兩個方向的清單欄頂部都顯示已選筆數
    ///
    /// - Throws: 版面不適用、已選筆數缺少、內容不符或越界時拋出測試錯誤
    @MainActor
    func testRegularColumns_多選勾選一筆_清單欄頂部顯示已選筆數() throws {
        // Given
        let app = launch(LaunchOptions(seed: .mergeCandidates))
        try XCTSkipUnless(isRegularLayout(app), Self.layoutScopeReason)
        let orders = try openSelectedOrder(in: app)
        try orders.enterSelectionMode()

        // When
        // 多選列的 identifier 同時落在按鈕與內層摘要，取第一個點擊
        orders.orderRow(orderID: Self.orderID).firstMatch.tapAfterWaiting(in: app)

        // Then
        let summary = app.staticTexts[BLAccessibilityID.Orders.selectionSummary]
        try requireCondition(
            summary.wait(for: NSPredicate(format: "label CONTAINS %@", "1"), timeout: 5),
            in: app,
            "已選筆數沒有反映勾選的一筆：實際為「\(summary.label)」"
        )
        let portraitBounds = try listColumnBounds(in: app, context: "直向")
        try assertHorizontalBounds(
            of: summary,
            between: portraitBounds.lowerBound,
            and: portraitBounds.upperBound,
            in: app,
            context: "直向，已選筆數"
        )
        try rotateToLandscape(app)
        let landscapeBounds = try listColumnBounds(in: app, context: "橫向")
        try assertHorizontalBounds(
            of: summary,
            between: landscapeBounds.lowerBound,
            and: landscapeBounds.upperBound,
            in: app,
            context: "橫向，已選筆數"
        )
    }

    /// 搜尋沒有結果時，詳情空狀態取代原訂單的選單與客戶標題
    ///
    /// - Throws: 版面不適用、空狀態缺少或原詳情仍存在時拋出測試錯誤
    @MainActor
    func testRegularColumns_搜尋無符合訂單_詳情只顯示空狀態() throws {
        // Given
        let app = launch(LaunchOptions(seed: .mergeCandidates))
        try XCTSkipUnless(isRegularLayout(app), Self.layoutScopeReason)
        let orders = try openSelectedOrder(in: app)

        // When
        try orders.hittableSearchField().clearAndType("ZZZ-NO-SUCH-ORDER", in: app)

        // Then
        let emptyState = app.descendants(matching: .any)[BLAccessibilityID.Orders.detailEmptyState]
        try requireCondition(emptyState.waitForExistence(timeout: 10), in: app, "找不到元素：詳情欄無選取空狀態")
        for identifier in [
            BLAccessibilityID.Orders.detailStatusMenuButton,
            BLAccessibilityID.Orders.detailMoreButton,
        ] {
            try requireCondition(
                app.descendants(matching: .any)[identifier].firstMatch.waitForDisappearance(),
                in: app,
                "無選取時詳情選單仍存在：\(identifier)"
            )
        }
        let navigationBars = try rightHandNavigationBars(in: app)
        try requireCondition(
            !navigationBars.contains { $0.identifier == Self.customerName },
            in: app,
            "無選取時清單欄右側仍有原客戶「\(Self.customerName)」的詳情導覽列"
        )
    }

    /// 總覽佔滿側邊欄以外的內容，切回訂單後清單控制項仍留在清單欄
    ///
    /// - Throws: 版面不適用、分頁未就緒或切換前後的水平範圍不符時拋出測試錯誤
    @MainActor
    func testRegularColumns_切換總覽再返回_兩欄總覽與訂單欄位歸屬正確() throws {
        // Given
        let app = launch(LaunchOptions(seed: .mergeCandidates))
        try XCTSkipUnless(isRegularLayout(app), Self.layoutScopeReason)
        _ = try openSelectedOrder(in: app)
        let root = RootNavigationScreen(app: app)

        // When
        try requireCondition(root.goToDashboard(), in: app, "切到總覽後畫面未就緒")

        // Then
        let orders = OrdersScreen(app: app)
        for identifier in [
            BLAccessibilityID.Orders.listRoot,
            BLAccessibilityID.Orders.detailRoot,
            BLAccessibilityID.Orders.detailEmptyState,
        ] {
            try requireCondition(
                app.descendants(matching: .any)[identifier].firstMatch.waitForDisappearance(),
                in: app,
                "切到總覽後訂單欄位仍存在：\(identifier)"
            )
        }
        try assertHorizontalFill(
            of: app.descendants(matching: .any)[BLAccessibilityID.Dashboard.root],
            after: app.descendants(matching: .any)[BLAccessibilityID.Root.sidebar],
            to: app.windows.firstMatch,
            in: app,
            context: "切到總覽後的兩欄版面"
        )
        try requireCondition(root.goToOrders(), in: app, "切回訂單後畫面未就緒")
        try assertListControls(orders, in: app, context: "切回訂單後 (直向)")
        let detail = app.descendants(matching: .any)[BLAccessibilityID.Orders.detailRoot]
        let detailEmptyState = app
            .descendants(matching: .any)[BLAccessibilityID.Orders.detailEmptyState]
        try requireCondition(
            detail.waitForExistence(timeout: 10) || detailEmptyState.exists,
            in: app,
            "找不到元素：切回訂單後的詳情欄"
        )
    }
}
