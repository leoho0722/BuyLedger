//
//  OrderRegularColumnScopeTests+Assertions.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/10/20.
//

import CoreGraphics
import XCTest

// MARK: - Internal Method

@MainActor
extension OrderRegularColumnScopeTests {

    /// 切到訂單並明確選取種子訂單，等待詳情內容就緒
    ///
    /// - Parameter app: 受測 App
    /// - Returns: 已選取訂單的清單 Page Object
    /// - Throws: 訂單分頁或詳情未就緒時拋出測試錯誤
    func openSelectedOrder(in app: XCUIApplication) throws -> OrdersScreen {
        let root = RootNavigationScreen(app: app)
        try requireCondition(root.goToOrders(), in: app, "切到訂單分頁後畫面未就緒")
        let orders = OrdersScreen(app: app)
        try requireCondition(orders.waitUntilReady(), in: app, "找不到元素：訂單清單根容器")
        orders.tapOrder(orderID: Self.orderID)
        let detail = OrderDetailScreen(app: app)
        try requireCondition(detail.waitUntilReady(), in: app, "找不到元素：選取訂單的詳情根容器")
        return orders
    }

    /// 確認清單有自己的導覽列，搜尋、筆數與一般模式操作都位於清單欄內
    ///
    /// - Parameters:
    ///   - orders: 訂單清單的 Page Object
    ///   - app: 受測 App
    ///   - context: 方向或分頁切換階段
    /// - Throws: 必要元素缺少或任一控制項越界時拋出測試錯誤
    func assertListControls(
        _ orders: OrdersScreen,
        in app: XCUIApplication,
        context: String
    ) throws {
        let bounds = try listColumnBounds(in: app, context: context)
        let controls: [(XCUIElement, String)] = [
            (try orders.hittableSearchField(), "搜尋欄"),
            (app.descendants(matching: .any)[BLAccessibilityID.Orders.orderCountLabel], "筆數"),
            (app.buttons[BLAccessibilityID.Orders.addButton], "新增訂單"),
            (app.buttons[BLAccessibilityID.Orders.batchMenuButton], "清單更多選單"),
        ]
        for (element, name) in controls {
            try assertHorizontalBounds(
                of: element,
                between: bounds.lowerBound,
                and: bounds.upperBound,
                in: app,
                context: "\(context)，\(name)"
            )
        }
        let hasListNavigationBar = app.navigationBars.allElementsBoundByIndex
            .filter(\.isHittableOnScreen)
            .contains { $0.frame.maxX <= bounds.upperBound + 1 }
        try requireCondition(hasListNavigationBar, in: app, "位置越界：清單欄沒有自己的導覽列")
    }

    /// 以側邊欄或視窗左緣與清單根容器右緣取得清單欄的水平範圍
    ///
    /// - Parameters:
    ///   - app: 受測 App
    ///   - context: 方向或分頁切換階段
    /// - Returns: 清單欄的左右界
    /// - Throws: 左界錨點或清單根容器無法取得時拋出測試錯誤
    func listColumnBounds(
        in app: XCUIApplication,
        context: String
    ) throws -> (lowerBound: CGFloat, upperBound: CGFloat) {
        let sidebar = app.descendants(matching: .any)[BLAccessibilityID.Root.sidebar]
        let hasSidebar = sidebar.exists
        let anchor = hasSidebar ? sidebar : app.windows.firstMatch
        let anchorFrame = try requireValidFrame(of: anchor, in: app, context: "\(context)，清單欄左界錨點")
        let lowerBound = hasSidebar ? anchorFrame.maxX : anchorFrame.minX
        let list = app.descendants(matching: .any)[BLAccessibilityID.Orders.listRoot]
        let listFrame = try requireValidFrame(of: list, in: app, context: "\(context)，訂單清單根容器")
        return (lowerBound, listFrame.maxX)
    }

    /// 依方向檢查側邊欄可見性，並以訂單列確認可見欄位沒有重疊
    ///
    /// - Parameters:
    ///   - app: 受測 App
    ///   - context: 目前的視窗方向
    ///   - isSidebarRequired: 目前方向是否要求側邊欄顯示
    /// - Throws: 任一欄位缺少或範圍重疊時拋出測試錯誤
    func assertColumnOrder(
        in app: XCUIApplication,
        context: String,
        isSidebarRequired: Bool
    ) throws {
        let sidebar = app.descendants(matching: .any)[BLAccessibilityID.Root.sidebar]
        let row = OrdersScreen(app: app).orderRow(orderID: Self.orderID)
        let detail = app.descendants(matching: .any)[BLAccessibilityID.Orders.detailRoot]
        let rowFrame = try requireHittableFrame(of: row, in: app, context: "\(context)，選取訂單列")
        let detailFrame = try requireValidFrame(of: detail, in: app, context: "\(context)，詳情欄")
        if isSidebarRequired || sidebar.exists {
            let sidebarFrame = try requireValidFrame(of: sidebar, in: app, context: "\(context)側邊欄")
            try requireCondition(
                sidebarFrame.maxX <= rowFrame.minX + 1,
                in: app,
                "位置越界：\(context)，側邊欄 frame = \(sidebarFrame)，選取訂單列 frame = \(rowFrame)"
            )
        }
        try requireCondition(
            rowFrame.maxX <= detailFrame.minX + 1,
            in: app,
            "位置越界：\(context)，選取訂單列 frame = \(rowFrame)，詳情欄 frame = \(detailFrame)"
        )
    }

    /// 側邊欄收起時從左緣叫出，確認它覆蓋在清單上而不縮窄清單欄
    ///
    /// - Parameter app: 受測 App
    /// - Throws: 側邊欄叫不出來、選取訂單列被推移或側邊欄沒有蓋住清單時拋出測試錯誤
    /// - Note: 系統直接並排側邊欄時 (較寬的 iPad 直向) 沒有收起狀態可驗，直接返回
    func assertRevealedSidebarOverlays(in app: XCUIApplication) throws {
        let sidebar = app.descendants(matching: .any)[BLAccessibilityID.Root.sidebar]
        guard !sidebar.exists else {
            return
        }
        let row = OrdersScreen(app: app).orderRow(orderID: Self.orderID)
        let rowBefore = try requireHittableFrame(of: row, in: app, context: "叫出側邊欄前，選取訂單列")
        try requireCondition(
            AppNavigator(app: app).revealSidebarIfCollapsed(),
            in: app,
            "左緣滑動未能叫出側邊欄"
        )
        let sidebarFrame = try requireValidFrame(of: sidebar, in: app, context: "叫出的側邊欄")
        let rowAfter = try requireValidFrame(of: row, in: app, context: "叫出側邊欄後，選取訂單列")
        try requireCondition(
            abs(rowAfter.minX - rowBefore.minX) <= 1 && sidebarFrame.maxX > rowAfter.minX,
            in: app,
            """
            位置越界：直向叫出的側邊欄沒有覆蓋清單，或清單被推移
            叫出前訂單列 \(rowBefore)，叫出後訂單列 \(rowAfter)，側邊欄 \(sidebarFrame)
            """
        )
    }

    /// 確認清單右側有客戶命名的導覽列，且詳情操作都位於其中
    ///
    /// - Parameter app: 受測 App
    /// - Throws: 詳情導覽列缺少、標題不符或操作越界時拋出測試錯誤
    func assertDetailNavigationBar(in app: XCUIApplication) throws {
        var navigationBar: XCUIElement?
        let deadline = Date.now.addingTimeInterval(10)
        repeat {
            navigationBar = try rightHandNavigationBars(in: app).first
            if navigationBar != nil {
                break
            }
            _ = XCTWaiter().wait(for: [XCTestExpectation()], timeout: 0.2)
        } while Date.now < deadline
        let bar = try requireValue(navigationBar, in: app, "找不到詳情導覽列：清單欄右側應有獨立的系統導覽列")
        try requireCondition(
            bar.identifier == Self.customerName,
            in: app,
            "詳情導覽列標題不符：預期「\(Self.customerName)」，實際為「\(bar.identifier)」"
        )
        let barFrame = try requireHittableFrame(of: bar, in: app, context: "詳情導覽列")
        for identifier in [
            BLAccessibilityID.Orders.detailStatusMenuButton,
            BLAccessibilityID.Orders.detailMoreButton,
        ] {
            try assertHorizontalBounds(
                of: app.buttons[identifier],
                within: bar,
                in: app,
                context: "詳情導覽列選單 \(identifier)"
            )
            let menuFrame = try requireHittableFrame(
                of: app.buttons[identifier],
                in: app,
                context: "詳情導覽列選單 \(identifier)"
            )
            try requireCondition(
                menuFrame.minY >= barFrame.minY - 1 && menuFrame.maxY <= barFrame.maxY + 1,
                in: app,
                """
                位置越界：詳情選單不在詳情導覽列內
                選單 \(identifier) frame = \(menuFrame)，詳情導覽列 frame = \(barFrame)
                """
            )
        }
    }

    /// 取得左緣位於清單欄右側的可互動系統導覽列
    ///
    /// - Parameter app: 受測 App
    /// - Returns: 與清單欄不重疊的導覽列
    /// - Throws: 清單根容器無法取得時拋出測試錯誤
    func rightHandNavigationBars(in app: XCUIApplication) throws -> [XCUIElement] {
        let list = app.descendants(matching: .any)[BLAccessibilityID.Orders.listRoot]
        let listFrame = try requireHittableFrame(of: list, in: app, context: "詳情導覽列定位的清單根容器")
        return app.navigationBars.allElementsBoundByIndex
            .filter(\.isHittableOnScreen)
            .filter { $0.frame.minX >= listFrame.maxX - 1 }
    }
}
