//
//  OrderRegularColumnScopeTests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/10/20.
//

import CoreGraphics
import XCTest

/// regular 訂單分頁的清單、詳情與側邊欄歸屬守門 UI 測試
@MainActor
final class OrderRegularColumnScopeTests: BLUITestCase {

    // MARK: - Properties

    /// `mergeCandidates` 中明確選取的訂單編號
    private static let orderID = "UITEST-MRG-001"

    /// 種子訂單的客戶名稱，不隨 App 語言變動
    private static let customerName = "林書宇"

    /// 版面不符時略過測試的原因，說明 compact 清單與詳情由哪些測試覆蓋
    private static let layoutScopeReason = """
    欄位歸屬只適用 regular 版面；compact 清單由 OrdersListTests 覆蓋
    compact 詳情由 OrderDetailTests 與 OrderDetailMenuTests 覆蓋
    """

    /// 驗證 regular 版面直向選取訂單後，清單的搜尋欄、筆數、新增與清單更多選單都只佔用清單欄
    ///
    /// - Throws: 版面不適用、必要元素缺少或控制項越界時丟出測試錯誤
    func testRegularColumns_直向_清單控制項只在清單欄內() throws {
        // Given
        let app = launch(LaunchOptions(seed: .mergeCandidates))
        try XCTSkipUnless(isRegularLayout(app), Self.layoutScopeReason)

        // When
        let orders = try openSelectedOrder(in: app)

        // Then
        try assertListControls(orders, in: app, context: "直向")
    }

    /// 驗證 regular 版面選取訂單後轉為橫向，清單的搜尋欄、筆數、新增與清單更多選單都只佔用清單欄
    ///
    /// - Throws: 版面不適用、必要元素缺少、轉向未完成或控制項越界時丟出測試錯誤
    func testRegularColumns_橫向_清單控制項只在清單欄內() throws {
        // Given
        let app = launch(LaunchOptions(seed: .mergeCandidates))
        try XCTSkipUnless(isRegularLayout(app), Self.layoutScopeReason)
        let orders = try openSelectedOrder(in: app)

        // When
        try rotateToLandscape(app)

        // Then
        try assertListControls(orders, in: app, context: "橫向")
    }

    /// 驗證 regular 版面直向時，選取的訂單列與詳情欄依序並排且不重疊，側邊欄收起時不要求顯示
    ///
    /// - Throws: 版面不適用、必要元素缺少或欄位重疊時丟出測試錯誤
    func testRegularColumns_直向_可見欄位依序並排且不重疊() throws {
        // Given
        let app = launch(LaunchOptions(seed: .mergeCandidates))
        try XCTSkipUnless(isRegularLayout(app), Self.layoutScopeReason)

        // When
        _ = try openSelectedOrder(in: app)

        // Then
        try assertColumnOrder(in: app, context: "直向", isSidebarRequired: false)
    }

    /// 驗證 regular 版面直向側邊欄收起時，從左緣叫出的側邊欄覆蓋在清單上，清單的選取列位置不變
    ///
    /// - Throws: 版面不適用或側邊欄並排時略過；必要元素缺少、側邊欄前置未收起、叫出失敗或欄位位置不符時丟出測試錯誤
    /// - Note: 系統直接並排側邊欄時 (較寬的 iPad 直向) 沒有收起狀態可驗，以 `XCTSkip` 宣告不適用
    func testRegularColumns_直向叫出收起的側邊欄_覆蓋清單且不推移清單欄() throws {
        // Given
        let app = launch(LaunchOptions(seed: .mergeCandidates))
        try XCTSkipUnless(isRegularLayout(app), Self.layoutScopeReason)
        _ = try openSelectedOrder(in: app)
        let sidebar = app.descendants(matching: .any)[BLAccessibilityID.Root.sidebar]
        let row = OrdersScreen(app: app).orderRow(orderID: Self.orderID)
        let rowBefore = try requireHittableFrame(of: row, in: app, context: "叫出側邊欄前，選取訂單列")
        if sidebar.exists {
            let sidebarFrame = try requireValidFrame(of: sidebar, in: app, context: "叫出前的側邊欄")
            try XCTSkipIf(
                sidebarFrame.maxX <= rowBefore.minX + 1,
                "側邊欄直接並排時沒有收起狀態；並排的欄位順序由 testRegularColumns_直向_可見欄位依序並排且不重疊 覆蓋"
            )
            try requireCondition(false, in: app, "選取訂單後側邊欄仍覆蓋清單，未建立側邊欄收起的前提")
        }

        // When
        let isSidebarRevealed = AppNavigator(app: app).revealSidebarIfCollapsed()

        // Then
        try requireCondition(isSidebarRevealed, in: app, "左緣滑動未能叫出側邊欄")
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

    /// 驗證 regular 版面選取訂單後轉為橫向，側邊欄、清單與詳情三欄依序並排且不重疊
    ///
    /// - Throws: 版面不適用、必要元素缺少、轉向未完成或欄位重疊時丟出測試錯誤
    func testRegularColumns_橫向_三欄依序並排且不重疊() throws {
        // Given
        let app = launch(LaunchOptions(seed: .mergeCandidates))
        try XCTSkipUnless(isRegularLayout(app), Self.layoutScopeReason)
        _ = try openSelectedOrder(in: app)

        // When
        try rotateToLandscape(app)

        // Then
        try assertColumnOrder(in: app, context: "橫向", isSidebarRequired: true)
    }

    /// 驗證 regular 版面選取訂單後，詳情欄的系統導覽列標題為客戶名稱，狀態選單與更多選單位於該導覽列內
    ///
    /// - Throws: 版面不適用、詳情導覽列缺少或操作越界時丟出測試錯誤
    func testRegularColumns_選取訂單_詳情導覽列承載客戶與選單() throws {
        // Given
        let app = launch(LaunchOptions(seed: .mergeCandidates))
        try XCTSkipUnless(isRegularLayout(app), Self.layoutScopeReason)

        // When
        _ = try openSelectedOrder(in: app)

        // Then
        try assertDetailNavigationBar(in: app)
    }

    /// 驗證 regular 版面進入多選後，全選、批次狀態與完成鈕留在清單欄，詳情欄仍保有原訂單的導覽列
    ///
    /// - Throws: 版面不適用、必要元素缺少或導覽列歸屬不符時丟出測試錯誤
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

    /// 驗證 regular 版面直向多選勾選一筆後，清單欄頂部的已選筆數顯示 1 且位於清單欄內
    ///
    /// - Throws: 版面不適用、已選筆數缺少、內容不符或越界時丟出測試錯誤
    func testRegularColumns_直向多選勾選一筆_清單欄頂部顯示已選筆數() throws {
        // Given
        let app = launch(LaunchOptions(seed: .mergeCandidates))
        try XCTSkipUnless(isRegularLayout(app), Self.layoutScopeReason)
        let orders = try openSelectedOrder(in: app)
        try orders.enterSelectionMode()

        // When
        // 多選列的 identifier 同時落在按鈕與內層摘要，取第一個點擊
        orders.orderRow(orderID: Self.orderID).firstMatch.tapAfterWaiting(in: app)

        // Then
        let summary = try requireSingleSelectionSummary(in: app)
        let bounds = try listColumnBounds(in: app, context: "直向")
        try assertHorizontalBounds(
            of: summary,
            between: bounds.lowerBound,
            and: bounds.upperBound,
            in: app,
            context: "直向，已選筆數"
        )
    }

    /// 驗證 regular 版面多選勾選一筆後轉為橫向，清單欄頂部的已選筆數仍顯示 1 且位於清單欄內
    ///
    /// - Throws: 版面不適用、已選筆數缺少、轉向未完成、內容不符或越界時丟出測試錯誤
    func testRegularColumns_橫向多選勾選一筆_清單欄頂部顯示已選筆數() throws {
        // Given
        let app = launch(LaunchOptions(seed: .mergeCandidates))
        try XCTSkipUnless(isRegularLayout(app), Self.layoutScopeReason)
        let orders = try openSelectedOrder(in: app)
        try orders.enterSelectionMode()
        orders.orderRow(orderID: Self.orderID).firstMatch.tapAfterWaiting(in: app)
        _ = try requireSingleSelectionSummary(in: app)

        // When
        try rotateToLandscape(app)

        // Then
        let summary = try requireSingleSelectionSummary(in: app)
        let bounds = try listColumnBounds(in: app, context: "橫向")
        try assertHorizontalBounds(
            of: summary,
            between: bounds.lowerBound,
            and: bounds.upperBound,
            in: app,
            context: "橫向，已選筆數"
        )
    }

    /// 驗證 regular 版面搜尋無符合訂單時，詳情欄顯示空狀態，原訂單的狀態選單、更多選單與客戶導覽列都消失
    ///
    /// - Throws: 版面不適用、搜尋前詳情導覽列不符、空狀態缺少或原詳情仍存在時丟出測試錯誤
    func testRegularColumns_搜尋無符合訂單_詳情只顯示空狀態() throws {
        // Given
        let app = launch(LaunchOptions(seed: .mergeCandidates))
        try XCTSkipUnless(isRegularLayout(app), Self.layoutScopeReason)
        let orders = try openSelectedOrder(in: app)
        // 詳情選單與客戶導覽列先確認存在，之後的消失斷言才有對照
        try assertDetailNavigationBar(in: app)

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

    /// 驗證 regular 版面切到總覽後，訂單的清單與詳情欄消失且總覽佔滿側邊欄以外的區域
    ///
    /// - Throws: 版面不適用、分頁未就緒或切換前後的水平範圍不符時丟出測試錯誤
    func testRegularColumns_切到總覽_訂單欄位消失且總覽佔滿() throws {
        // Given
        let app = launch(LaunchOptions(seed: .mergeCandidates))
        try XCTSkipUnless(isRegularLayout(app), Self.layoutScopeReason)
        _ = try openSelectedOrder(in: app)
        let root = RootNavigationScreen(app: app)

        // When
        try requireCondition(root.goToDashboard(), in: app, "切到總覽後畫面未就緒")

        // Then
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
    }

    /// 驗證 regular 版面從總覽切回訂單後，清單控制項仍在清單欄內，詳情欄保留選取的訂單
    ///
    /// - Throws: 版面不適用、分頁未就緒或欄位歸屬不符時丟出測試錯誤
    func testRegularColumns_切回訂單_清單控制項歸屬正確且詳情保留() throws {
        // Given
        let app = launch(LaunchOptions(seed: .mergeCandidates))
        try XCTSkipUnless(isRegularLayout(app), Self.layoutScopeReason)
        let orders = try openSelectedOrder(in: app)
        let root = RootNavigationScreen(app: app)
        try requireCondition(root.goToDashboard(), in: app, "切到總覽後畫面未就緒")

        // When
        try requireCondition(root.goToOrders(), in: app, "切回訂單後畫面未就緒")

        // Then
        try assertListControls(orders, in: app, context: "切回訂單後 (直向)")
        let detail = app.descendants(matching: .any)[BLAccessibilityID.Orders.detailRoot]
        try requireCondition(
            detail.waitForExistence(timeout: 10),
            in: app,
            "找不到元素：切回訂單後詳情欄未保留選取訂單的詳情"
        )
    }
}

// MARK: - Private Method

private extension OrderRegularColumnScopeTests {

    /// 切到訂單並明確選取種子訂單，等待詳情內容就緒
    ///
    /// - Parameter app: 受測 App
    /// - Returns: 已選取訂單的清單 Page Object
    /// - Throws: 訂單分頁或詳情未就緒時丟出測試錯誤
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
    /// - Throws: 必要元素缺少或任一控制項越界時丟出測試錯誤
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
    /// - Throws: 左界錨點或清單根容器無法取得時丟出測試錯誤
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
    /// - Throws: 任一欄位缺少或範圍重疊時丟出測試錯誤
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

    /// 確認清單右側有客戶命名的導覽列，且詳情操作都位於其中
    ///
    /// - Parameter app: 受測 App
    /// - Throws: 詳情導覽列缺少、標題不符或操作越界時丟出測試錯誤
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
    /// - Throws: 清單根容器無法取得時丟出測試錯誤
    func rightHandNavigationBars(in app: XCUIApplication) throws -> [XCUIElement] {
        let list = app.descendants(matching: .any)[BLAccessibilityID.Orders.listRoot]
        let listFrame = try requireHittableFrame(of: list, in: app, context: "詳情導覽列定位的清單根容器")
        return app.navigationBars.allElementsBoundByIndex
            .filter(\.isHittableOnScreen)
            .filter { $0.frame.minX >= listFrame.maxX - 1 }
    }

    /// 等清單欄頂部的已選筆數只反映一筆後回傳該元素
    ///
    /// - Parameter app: 受測 App
    /// - Returns: 已選筆數元素
    /// - Throws: 已選筆數在逾時內未顯示恰為 1 的數字時丟出測試錯誤
    /// - Note: 只比對數字 1 前後不接其他數字，文案模板不入斷言，「10」等多位數不會通過
    func requireSingleSelectionSummary(in app: XCUIApplication) throws -> XCUIElement {
        let summary = app.staticTexts[BLAccessibilityID.Orders.selectionSummary]
        let singleCount = NSPredicate(format: "label MATCHES %@", "(.*[^0-9])?1([^0-9].*)?")
        try requireCondition(
            summary.wait(for: singleCount, timeout: 5),
            in: app,
            "已選筆數沒有反映勾選的一筆：實際為「\(summary.label)」"
        )
        return summary
    }
}
