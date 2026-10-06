//
//  OrientationLayoutTests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/10/4.
//

import UIKit
import XCTest

/// 裝置轉為橫向後的根導覽與訂單版面測試，並附上橫向的首頁、訂單與分析頁截圖
final class OrientationLayoutTests: BLUITestCase {

    /// iPhone 轉為橫向後維持底部分頁列與整合篩選鈕，iPad 維持側邊欄且不顯示整合篩選鈕
    ///
    /// - Throws: 轉向未完成，或根導覽與訂單篩選的版面不符預期時拋出測試錯誤
    @MainActor
    func testRotateToLandscape_含開團與訂單資料_根導覽與訂單篩選符合裝置版面() throws(any Error) {
        // Given
        let app = launch(LaunchOptions(seed: .campaignsWithOrders))
        let root = RootNavigationScreen(app: app)
        try requireCondition(root.waitUntilReady(), in: app, "直向啟動後根導覽未就緒")

        // When
        try rotateToLandscape(app)

        // Then
        if UIDevice.current.userInterfaceIdiom == .pad {
            try assertRegularLayout(in: app)
        } else {
            try assertCompactLayout(in: app)
        }
    }

    /// 轉為橫向後依序附上首頁、訂單頁與分析頁的截圖，供人工確認各頁排列
    ///
    /// - Throws: 轉向未完成，或任一頁的畫面與元素未就緒時拋出測試錯誤
    @MainActor
    func testRotateToLandscape_含開團與訂單資料_首頁訂單與分析頁附上橫向截圖() throws(any Error) {
        // Given
        let app = launch(LaunchOptions(seed: .campaignsWithOrders))
        let root = RootNavigationScreen(app: app)
        try requireCondition(root.waitUntilReady(), in: app, "直向啟動後根導覽未就緒")

        // When
        try rotateToLandscape(app)

        // Then
        try captureDashboard(in: app)
        try captureOrders(in: app)
        try captureInsights(in: app)
    }
}

// MARK: - Private Method

@MainActor
private extension OrientationLayoutTests {

    /// 轉為橫向並等到 App 視窗寬大於高，完成後附上橫向視窗的點數尺寸
    ///
    /// - Parameter app: 受測 App
    /// - Throws: 逾時仍未轉為橫向時拋出測試錯誤
    func rotateToLandscape(_ app: XCUIApplication) throws(any Error) {
        // 先註冊還原再轉向，測試失敗時方向也會轉回直向
        addTeardownBlock { XCUIDevice.shared.orientation = .portrait }
        XCUIDevice.shared.orientation = .landscapeLeft
        try requireCondition(waitForLandscapeWindow(of: app), in: app, "轉向後 App 視窗寬仍未大於高")

        let size = app.windows.firstMatch.frame.size
        let sizeText = "landscape window size: \(size.width) x \(size.height)"
        let attachment = XCTAttachment(string: sizeText)
        attachment.name = "橫向視窗點數尺寸"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// 在逾時內輪詢 App 視窗，直到寬大於高
    ///
    /// - Parameters:
    ///   - app: 受測 App
    ///   - timeout: 等待視窗轉為橫向的秒數
    /// - Returns: 視窗是否在逾時前轉為橫向
    func waitForLandscapeWindow(of app: XCUIApplication, timeout: TimeInterval = 15) -> Bool {
        let window = app.windows.firstMatch
        guard window.waitForExistence(timeout: timeout) else {
            return false
        }

        let deadline = Date().addingTimeInterval(timeout)
        repeat {
            let size = window.frame.size
            if size.width > size.height {
                return true
            }
            // 轉向動畫期間視窗尺寸尚未定案，讓出 run loop 後重查
            RunLoop.current.run(until: Date().addingTimeInterval(0.25))
        } while Date() < deadline
        return false
    }

    /// 斷言 iPad 橫向仍是側邊欄版面：有側邊欄，訂單頁沒有整合篩選鈕
    ///
    /// - Parameter app: 受測 App
    /// - Throws: 缺側邊欄或訂單清單未就緒時拋出測試錯誤
    func assertRegularLayout(in app: XCUIApplication) throws(any Error) {
        let sidebar = app.descendants(matching: .any)[BLAccessibilityID.Root.sidebar]
        try requireCondition(sidebar.waitForExistence(timeout: 10), in: app, "iPad 橫向沒有側邊欄")

        let root = RootNavigationScreen(app: app)
        try requireCondition(root.goToOrders(), in: app, "切到訂單分頁後畫面未就緒")
        try requireCondition(OrdersScreen(app: app).waitUntilReady(), in: app, "訂單清單未就緒")
        if filterButton(in: app).waitForExistence(timeout: 2) {
            failWithDiagnostics(in: app, "iPad 橫向不應顯示整合篩選鈕")
        }
    }

    /// 取整合篩選鈕，以任意元素類型查詢，避免類型不符被誤判為不存在
    ///
    /// - Parameter app: 受測 App
    /// - Returns: 整合篩選鈕元素
    func filterButton(in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any)[BLAccessibilityID.Orders.filterButton]
    }

    /// 斷言 iPhone 橫向仍是分頁列版面：有底部分頁列、沒有側邊欄，訂單頁有整合篩選鈕
    ///
    /// - Parameter app: 受測 App
    /// - Throws: 分頁列缺席、出現側邊欄或缺整合篩選鈕時拋出測試錯誤
    func assertCompactLayout(in app: XCUIApplication) throws(any Error) {
        try requireCondition(
            app.tabBars.firstMatch.waitForExistence(timeout: 10),
            in: app,
            "iPhone 橫向沒有底部分頁列"
        )
        try requireCondition(!AppNavigator(app: app).isSidebarLayout, in: app, "iPhone 橫向出現側邊欄")

        let root = RootNavigationScreen(app: app)
        try requireCondition(root.goToOrders(), in: app, "切到訂單分頁後畫面未就緒")
        try requireCondition(
            filterButton(in: app).waitForExistence(timeout: 10),
            in: app,
            "iPhone 橫向的訂單頁沒有整合篩選鈕"
        )
    }

    /// 等首頁 KPI 卡出現後附上截圖，再把 KPI 卡捲進畫面附上第二張
    ///
    /// - Parameter app: 受測 App
    /// - Throws: 首頁或 KPI 卡未就緒，或視窗已不是橫向時拋出測試錯誤
    func captureDashboard(in app: XCUIApplication) throws(any Error) {
        let root = RootNavigationScreen(app: app)
        let dashboard = DashboardScreen(app: app)
        try requireCondition(root.goToDashboard(), in: app, "切到首頁分頁後畫面未就緒")
        try requireCondition(dashboard.kpiValue(.revenue) != nil, in: app, "橫向首頁沒有營收 KPI 卡")
        try attachScreenshot(named: "橫向首頁", of: app)

        let tile = app.descendants(matching: .any)[BLAccessibilityID.Dashboard.kpiTile(.revenue)]
        scrollIntoView(tile, within: dashboard.rootElement, in: app)
        try attachScreenshot(named: "橫向首頁 KPI 卡", of: app)
    }

    /// 確認視窗仍是橫向後附上整個 App 的截圖，附件保留在 result bundle
    ///
    /// - Parameters:
    ///   - name: 附件名稱
    ///   - app: 受測 App
    /// - Throws: 視窗已不是橫向時拋出測試錯誤
    func attachScreenshot(named name: String, of app: XCUIApplication) throws(any Error) {
        let isLandscape = waitForLandscapeWindow(of: app, timeout: 5)
        try requireCondition(isLandscape, in: app, "截圖「\(name)」前視窗不是橫向")

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// 以大步幅的無慣性拖曳把目標捲進畫面；捲不到不算失敗，露出與否由截圖人工確認
    ///
    /// - Parameters:
    ///   - element: 要捲進畫面的目標元素
    ///   - container: 可捲動的容器
    ///   - app: 受測 App
    func scrollIntoView(
        _ element: XCUIElement,
        within container: XCUIElement,
        in app: XCUIApplication
    ) {
        app.scrollToHittableGently(
            element,
            within: container,
            startY: 0.8,
            endY: 0.3
        )
    }

    /// 等訂單清單出現訂單列後附上截圖
    ///
    /// - Parameter app: 受測 App
    /// - Throws: 訂單頁或訂單列未就緒，或視窗已不是橫向時拋出測試錯誤
    func captureOrders(in app: XCUIApplication) throws(any Error) {
        let root = RootNavigationScreen(app: app)
        try requireCondition(root.goToOrders(), in: app, "切到訂單分頁後畫面未就緒")
        try requireCondition(OrdersScreen(app: app).waitUntilReady(), in: app, "訂單清單未就緒")

        let rowPrefix = BLAccessibilityID.Orders.row(orderID: "")
        let firstRow = rows(withIdentifierPrefix: rowPrefix, in: app).firstMatch
        try requireCondition(firstRow.waitForExistence(timeout: 10), in: app, "訂單清單沒有訂單列")
        try attachScreenshot(named: "橫向訂單頁", of: app)
    }

    /// 取 identifier 以指定前綴開頭的一組列元素
    ///
    /// - Parameters:
    ///   - prefix: 列 identifier 的共同前綴
    ///   - app: 受測 App
    /// - Returns: identifier 以前綴開頭的元素查詢
    func rows(withIdentifierPrefix prefix: String, in app: XCUIApplication) -> XCUIElementQuery {
        let predicate = NSPredicate(format: "identifier BEGINSWITH %@", prefix)
        return app.descendants(matching: .any).matching(predicate)
    }

    /// 把分析頁的類別排行與成本結構卡片依序捲進畫面，各附一張截圖
    ///
    /// - Parameter app: 受測 App
    /// - Throws: 分析頁、類別排行列或成本結構圖未就緒，或視窗已不是橫向時拋出測試錯誤
    func captureInsights(in app: XCUIApplication) throws(any Error) {
        let root = RootNavigationScreen(app: app)
        let insights = InsightsScreen(app: app)
        try requireCondition(root.goToInsights(), in: app, "切到分析分頁後畫面未就緒")
        try requireCondition(insights.waitUntilReady(), in: app, "分析頁未就緒")

        let rowPrefix = BLAccessibilityID.Insights.categoryRankRow(category: "")
        let categoryRow = rows(withIdentifierPrefix: rowPrefix, in: app).firstMatch
        try requireCondition(categoryRow.waitForExistence(timeout: 10), in: app, "分析頁沒有類別排行列")
        scrollIntoView(categoryRow, within: insights.rootElement, in: app)
        try attachScreenshot(named: "橫向分析頁 類別排行", of: app)

        try requireCondition(insights.costDonutExists, in: app, "分析頁沒有成本結構圖")
        let donut = app.descendants(matching: .any)[BLAccessibilityID.Insights.costDonut]
        scrollIntoView(donut, within: insights.rootElement, in: app)
        try attachScreenshot(named: "橫向分析頁 成本結構", of: app)
    }
}
