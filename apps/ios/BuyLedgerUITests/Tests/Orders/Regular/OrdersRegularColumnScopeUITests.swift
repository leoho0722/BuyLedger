//
//  OrdersRegularColumnScopeUITests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/10/20.
//

import CoreGraphics
import XCTest

/// regular 訂單清單、詳情與多選控制項的欄位歸屬 UI 測試
@MainActor
final class OrdersRegularColumnScopeUITests: BLUITestCase {

    /// 種子訂單的客戶名稱，不隨 App 語言變動
    private static let customerName = "林書宇"

    /// 驗證 regular 版面直向選取訂單後，清單控制項只佔用清單欄
    ///
    /// - Throws: 版面不適用、必要元素缺少或控制項越界時丟出測試錯誤
    func testDetailSelectionChanged_直向_清單控制項只在清單欄內() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .mergeCandidates))
        let orders = try OrdersScreen.open(in: app)
        try XCTSkipUnless(
            try ordersLayout(in: app) == .regular,
            OrdersRegularColumnScopeUITestSupport.layoutScopeReason
        )

        // When
        try orders.tapOrder(orderID: OrdersSeedFixture.mergeOrderID)

        // Then
        try OrdersRegularColumnScopeUITestSupport.assertListControls(
            orders,
            in: app,
            testCase: self,
            context: "直向"
        )
    }

    /// 驗證 regular 版面選取訂單後轉為橫向，清單控制項仍只佔用清單欄
    ///
    /// - Throws: 版面不符、元素缺少、轉向未完成或控制項越界時失敗
    func testRotateToLandscape_已選取訂單_清單控制項只在清單欄內() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .mergeCandidates))
        let orders = try OrdersScreen.open(in: app)
        try XCTSkipUnless(
            try ordersLayout(in: app) == .regular,
            OrdersRegularColumnScopeUITestSupport.layoutScopeReason
        )
        try orders.tapOrder(orderID: OrdersSeedFixture.mergeOrderID)

        // When
        try rotateToLandscape(app)

        // Then
        try OrdersRegularColumnScopeUITestSupport.assertListControls(
            orders,
            in: app,
            testCase: self,
            context: "橫向"
        )
    }

    /// 驗證 regular 版面直向時，選取訂單列與詳情欄依序並排且不重疊
    ///
    /// - Throws: 版面不適用、必要元素缺少或欄位重疊時丟出測試錯誤
    func testDetailSelectionChanged_直向_可見欄位依序並排且不重疊() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .mergeCandidates))
        let orders = try OrdersScreen.open(in: app)
        try XCTSkipUnless(
            try ordersLayout(in: app) == .regular,
            OrdersRegularColumnScopeUITestSupport.layoutScopeReason
        )

        // When
        try orders.tapOrder(orderID: OrdersSeedFixture.mergeOrderID)

        // Then
        try assertColumnOrder(in: app, context: "直向", isSidebarRequired: false)
    }

    /// 驗證橫向時側邊欄、清單與詳情三欄依序並排且不重疊
    ///
    /// - Throws: 版面不符、元素缺少、轉向未完成或欄位重疊時丟出測試錯誤
    func testRotateToLandscape_已選取訂單_三欄依序並排且不重疊() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .mergeCandidates))
        let orders = try OrdersScreen.open(in: app)
        try XCTSkipUnless(
            try ordersLayout(in: app) == .regular,
            OrdersRegularColumnScopeUITestSupport.layoutScopeReason
        )
        try orders.tapOrder(orderID: OrdersSeedFixture.mergeOrderID)

        // When
        try rotateToLandscape(app)

        // Then
        try assertColumnOrder(in: app, context: "橫向", isSidebarRequired: true)
    }

    /// 驗證選取訂單後，客戶名稱、狀態選單與更多選單都位於詳情導覽列
    ///
    /// - Throws: 版面不適用、詳情導覽列缺少或操作越界時丟出測試錯誤
    func testDetailSelectionChanged_選取訂單_詳情導覽列承載客戶與選單() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .mergeCandidates))
        let orders = try OrdersScreen.open(in: app)
        try XCTSkipUnless(
            try ordersLayout(in: app) == .regular,
            OrdersRegularColumnScopeUITestSupport.layoutScopeReason
        )

        // When
        let detail = try orders.tapOrder(orderID: OrdersSeedFixture.mergeOrderID)

        // Then
        try assertDetailNavigationBar(in: app, detail: detail)
        try requireCondition(
            orders.orderRow(orderID: OrdersSeedFixture.mergeOrderID).isSelected,
            in: app,
            "目前訂單列應帶選取特徵"
        )
    }

    /// 驗證進入多選後，清單控制項與詳情導覽列各自位於所屬欄位
    ///
    /// - Throws: 版面不適用、必要元素缺少或導覽列歸屬不符時丟出測試錯誤
    func testSelectionModeToggled_進入多選_清單控制項與詳情導覽列各自獨立()
    throws {
        // Given
        let app = try launch(LaunchOptions(seed: .mergeCandidates))
        let orders = try OrdersScreen.open(in: app)
        try XCTSkipUnless(
            try ordersLayout(in: app) == .regular,
            OrdersRegularColumnScopeUITestSupport.layoutScopeReason
        )
        let detail = try orders.tapOrder(orderID: OrdersSeedFixture.mergeOrderID)

        // When
        try orders.enterSelectionMode()

        // Then
        let bounds = try OrdersRegularColumnScopeUITestSupport.listColumnBounds(
            in: app,
            orders: orders,
            testCase: self,
            context: "多選"
        )
        for (element, name) in [
            (orders.selectAllButton, "全選"),
            (orders.batchStatusMenuButton, "批次狀態"),
            (orders.selectionDoneButton, "完成"),
        ] {
            try OrdersRegularColumnScopeUITestSupport.assertHorizontalBounds(
                of: element,
                between: bounds.lowerBound,
                and: bounds.upperBound,
                in: app,
                testCase: self,
                context: "多選控制項 \(name)"
            )
        }
        try assertDetailNavigationBar(in: app, detail: detail)
    }

    /// 驗證直向多選勾選一筆後，清單欄頂部顯示 1 且位於清單欄內
    ///
    /// - Throws: 版面不適用、已選筆數缺少、內容不符或越界時丟出測試錯誤
    func testOrderSelectionToggled_直向多選勾選一筆_清單欄頂部顯示已選筆數()
    throws {
        // Given
        let app = try launch(LaunchOptions(seed: .mergeCandidates))
        let orders = try OrdersScreen.open(in: app)
        try XCTSkipUnless(
            try ordersLayout(in: app) == .regular,
            OrdersRegularColumnScopeUITestSupport.layoutScopeReason
        )
        try orders.tapOrder(orderID: OrdersSeedFixture.mergeOrderID)
        try orders.enterSelectionMode()

        // When
        try orders.orderRow(orderID: OrdersSeedFixture.mergeOrderID).firstMatch
            .tapAfterWaiting(in: app)

        // Then
        let summary = try requireSingleSelectionSummary(orders, in: app)
        let bounds = try OrdersRegularColumnScopeUITestSupport.listColumnBounds(
            in: app,
            orders: orders,
            testCase: self,
            context: "直向"
        )
        try OrdersRegularColumnScopeUITestSupport.assertHorizontalBounds(
            of: summary,
            between: bounds.lowerBound,
            and: bounds.upperBound,
            in: app,
            testCase: self,
            context: "直向，已選筆數"
        )
    }

    /// 驗證 regular 版面多選勾選一筆後轉為橫向，清單欄頂部仍顯示 1
    ///
    /// - Throws: 版面不符、已選筆數缺少、轉向未完成或位置越界時失敗
    func testRotateToLandscape_多選勾選一筆_清單欄頂部顯示已選筆數() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .mergeCandidates))
        let orders = try OrdersScreen.open(in: app)
        try XCTSkipUnless(
            try ordersLayout(in: app) == .regular,
            OrdersRegularColumnScopeUITestSupport.layoutScopeReason
        )
        try orders.tapOrder(orderID: OrdersSeedFixture.mergeOrderID)
        try orders.enterSelectionMode()
        try orders.orderRow(orderID: OrdersSeedFixture.mergeOrderID).firstMatch
            .tapAfterWaiting(in: app)
        _ = try requireSingleSelectionSummary(orders, in: app)

        // When
        try rotateToLandscape(app)

        // Then
        let summary = try requireSingleSelectionSummary(orders, in: app)
        let bounds = try OrdersRegularColumnScopeUITestSupport.listColumnBounds(
            in: app,
            orders: orders,
            testCase: self,
            context: "橫向"
        )
        try OrdersRegularColumnScopeUITestSupport.assertHorizontalBounds(
            of: summary,
            between: bounds.lowerBound,
            and: bounds.upperBound,
            in: app,
            testCase: self,
            context: "橫向，已選筆數"
        )
    }

    /// 驗證搜尋無符合訂單時詳情顯示空狀態，原詳情與客戶標題都消失
    ///
    /// - Throws: 版面不符、標題不符、空狀態缺少或原詳情仍在時失敗
    func testSearchTextChanged_搜尋無符合訂單_詳情只顯示空狀態() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .mergeCandidates))
        let orders = try OrdersScreen.open(in: app)
        try XCTSkipUnless(
            try ordersLayout(in: app) == .regular,
            OrdersRegularColumnScopeUITestSupport.layoutScopeReason
        )
        let detail = try orders.tapOrder(orderID: OrdersSeedFixture.mergeOrderID)
        try assertDetailNavigationBar(in: app, detail: detail)

        // When
        try app.hittableSearchField().clearAndType("ZZZ-NO-SUCH-ORDER", in: app)

        // Then
        try requireCondition(
            orders.hasDetailEmptyState(timeout: 10),
            in: app,
            "找不到元素：詳情欄無選取空狀態"
        )
        for (element, name) in [
            (detail.statusMenuButton, "狀態選單"),
            (detail.moreButton, "更多選單"),
        ] {
            try requireCondition(
                element.waitForDisappearance(),
                in: app,
                "無選取時詳情\(name)仍存在"
            )
        }
        let customerBar = app.navigationBars.matching(identifier: Self.customerName).firstMatch
        try requireCondition(
            customerBar.waitForDisappearance(),
            in: app,
            "無選取時仍有原客戶「\(Self.customerName)」的詳情導覽列"
        )
    }
}

// MARK: - Private Method

private extension OrdersRegularColumnScopeUITests {

    /// 以原生側邊欄導覽列取得側邊欄欄界，不用品牌標記估算欄寬
    ///
    /// - Parameters:
    ///   - app: 受測 App
    ///   - context: 方向或側邊欄切換階段
    /// - Returns: 側邊欄可見時的 NavigationBar 框線，否則為 `nil`
    /// - Throws: 側邊欄標記存在但導覽列缺少或欄界超出視窗時丟出測試錯誤
    func sidebarColumnFrame(in app: XCUIApplication, context: String) throws -> CGRect? {
        let sidebarMarker = app.descendants(matching: .any)[BLAccessibilityID.Root.sidebar]
            .firstMatch
        let sidebarNavigationBar = app.navigationBars
            .containing(.button, identifier: SystemAccessibilityID.sidebarToggleButton)
            .firstMatch
        guard sidebarMarker.exists || sidebarNavigationBar.exists else {
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

    /// 依方向檢查側邊欄可見性，並以訂單列確認可見欄位沒有重疊
    ///
    /// - Parameters:
    ///   - app: 受測 App
    ///   - context: 目前的視窗方向
    ///   - isSidebarRequired: 目前方向是否要求側邊欄顯示
    /// - Throws: 任一欄位缺少或範圍重疊時丟出測試錯誤
    func assertColumnOrder(
        in app: XCUIApplication,
        context: String,
        isSidebarRequired: Bool
    ) throws {
        let row = OrdersScreen(app: app).orderRow(orderID: OrdersSeedFixture.mergeOrderID)
        let rowFrame = try requireHittableFrame(
            of: row,
            in: app,
            context: "\(context)，選取訂單列"
        )
        let detailFrame = try requireValue(
            foregroundOrdersDetailFrame(in: app),
            in: app,
            "找不到\(context)詳情欄的前景內容框線"
        )
        let sidebarFrame = try sidebarColumnFrame(in: app, context: context)
        if isSidebarRequired {
            let requiredSidebarFrame = try requireValue(
                sidebarFrame,
                in: app,
                "找不到\(context)原生側邊欄欄位邊界"
            )
            try requireCondition(
                requiredSidebarFrame.maxX <= rowFrame.minX + 1,
                in: app,
                "位置越界：\(context)，側邊欄 frame = \(requiredSidebarFrame)，"
                    + "選取訂單列 frame = \(rowFrame)"
            )
        } else if let sidebarFrame {
            try requireCondition(
                sidebarFrame.maxX <= rowFrame.minX + 1,
                in: app,
                "位置越界：\(context)，側邊欄 frame = \(sidebarFrame)，"
                    + "選取訂單列 frame = \(rowFrame)"
            )
        }
        try requireCondition(
            rowFrame.maxX <= detailFrame.minX + 1,
            in: app,
            "位置越界：\(context)，選取訂單列 frame = \(rowFrame)，"
                + "詳情內容 frame = \(detailFrame)"
        )
    }

    /// 確認客戶名稱與兩個選單都位於清單欄右側的詳情導覽列
    ///
    /// - Parameter app: 受測 App
    /// - Throws: 清單根容器或導覽列缺少，或選單位置不符時丟出測試錯誤
    func assertDetailNavigationBar(
        in app: XCUIApplication,
        detail: OrderDetailScreen
    ) throws {
        let orders = OrdersScreen(app: app)
        try requireCondition(
            app.waitForNavigationBarTitle(Self.customerName),
            in: app,
            "找不到詳情導覽列標題「\(Self.customerName)」"
        )
        let listFrame = try requireHittableFrame(
            of: orders.rootElement,
            in: app,
            context: "詳情導覽列定位的清單根容器"
        )
        let bar = app.navigationBars.matching(identifier: Self.customerName).firstMatch
        let barFrame = try requireHittableFrame(
            of: bar,
            in: app,
            context: "詳情導覽列「\(Self.customerName)」"
        )
        for (menu, name) in [
            (detail.statusMenuButton, "狀態選單"),
            (detail.moreButton, "更多選單"),
        ] {
            try OrdersRegularColumnScopeUITestSupport.assertHorizontalBounds(
                of: menu,
                within: bar,
                in: app,
                testCase: self,
                context: "詳情導覽列\(name)"
            )
            let menuFrame = try requireHittableFrame(of: menu, in: app, context: name)
            try requireCondition(
                menuFrame.minX >= listFrame.maxX - 1,
                in: app,
                "位置越界：詳情\(name)位於清單欄內，"
                    + "選單 frame = \(menuFrame)，清單 frame = \(listFrame)"
            )
            try requireCondition(
                menuFrame.minY >= barFrame.minY - 1 && menuFrame.maxY <= barFrame.maxY + 1,
                in: app,
                "位置越界：詳情\(name)不在詳情導覽列內，"
                    + "選單 frame = \(menuFrame)，導覽列 frame = \(barFrame)"
            )
        }
    }

    /// 等清單欄頂部的已選筆數只反映一筆後回傳該元素
    ///
    /// - Parameter orders: 訂單清單的 Page Object
    /// - Returns: 已選筆數元素
    /// - Throws: 已選筆數逾時未顯示獨立數字 1 時丟出測試錯誤
    func requireSingleSelectionSummary(
        _ orders: OrdersScreen,
        in app: XCUIApplication
    ) throws -> XCUIElement {
        let summary = orders.selectionSummary
        let singleCount = NSPredicate(format: "label MATCHES %@", "(.*[^0-9])?1([^0-9].*)?")
        try requireCondition(
            summary.wait(for: singleCount, timeout: 5),
            in: app,
            "已選筆數沒有反映勾選的一筆：實際為「\(summary.label)」"
        )
        return summary
    }
}
