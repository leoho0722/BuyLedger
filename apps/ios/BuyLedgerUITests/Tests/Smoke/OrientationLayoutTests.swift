//
//  OrientationLayoutTests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/10/4.
//

import XCTest

/// 裝置轉為橫向後的根導覽與訂單版面 UI 測試，並附上橫向的首頁、訂單與分析頁截圖
@MainActor
final class OrientationLayoutTests: BLUITestCase {

    /// 驗證轉為橫向後，根導覽與訂單篩選各自符合裝置版面
    ///
    /// - Throws: 轉向未完成，或根導覽與訂單篩選的版面不符預期時丟出測試錯誤
    /// - Note: 根導覽依 `AppNavigator` 判定，訂單篩選依 `PlatformScope` 判定，兩者分開斷言
    func testRotateToLandscape_含開團與訂單資料_根導覽與訂單篩選符合裝置版面() throws {
        // Given
        let app = launch(LaunchOptions(seed: .campaignsWithOrders))
        let root = RootNavigationScreen(app: app)
        try requireCondition(root.waitUntilReady(), in: app, "直向啟動後根導覽未就緒")
        try requireCondition(root.goToOrders(), in: app, "直向切到訂單分頁後畫面未就緒")
        let navigator = AppNavigator(app: app)
        let rootLayout = try requireValue(navigator.rootLayout, in: app, "直向啟動後根導覽版面無法判定")
        let isOrdersRegular = isRegularLayout(app)

        // When
        try rotateToLandscape(app)

        // Then
        try assertRootNavigation(navigator: navigator, in: app, expected: rootLayout)
        try assertOrdersFilter(in: app, isRegular: isOrdersRegular)
    }

    /// 驗證首頁轉為橫向後仍就緒並附上截圖，供人工確認排列
    ///
    /// - Throws: 轉向未完成，或畫面與元素未就緒時丟出測試錯誤
    func testRotateToLandscape_含開團與訂單資料_首頁附上橫向截圖() throws {
        // Given
        let app = launch(LaunchOptions(seed: .campaignsWithOrders))
        let root = RootNavigationScreen(app: app)
        try requireCondition(root.waitUntilReady(), in: app, "直向啟動後根導覽未就緒")
        try requireCondition(root.goToDashboard(), in: app, "直向切到首頁後畫面未就緒")

        // When
        try rotateToLandscape(app)

        // Then
        try captureDashboard(in: app)
    }

    /// 驗證訂單頁轉為橫向後仍就緒並附上截圖，供人工確認排列
    ///
    /// - Throws: 轉向未完成，或畫面與元素未就緒時丟出測試錯誤
    func testRotateToLandscape_含開團與訂單資料_訂單頁附上橫向截圖() throws {
        // Given
        let app = launch(LaunchOptions(seed: .campaignsWithOrders))
        let root = RootNavigationScreen(app: app)
        try requireCondition(root.waitUntilReady(), in: app, "直向啟動後根導覽未就緒")
        try requireCondition(root.goToOrders(), in: app, "直向切到訂單頁後畫面未就緒")

        // When
        try rotateToLandscape(app)

        // Then
        try captureOrders(in: app)
    }

    /// 驗證分析頁轉為橫向後仍就緒並附上截圖，供人工確認排列
    ///
    /// - Throws: 轉向未完成，或畫面與元素未就緒時丟出測試錯誤
    func testRotateToLandscape_含開團與訂單資料_分析頁附上橫向截圖() throws {
        // Given
        let app = launch(LaunchOptions(seed: .campaignsWithOrders))
        let root = RootNavigationScreen(app: app)
        try requireCondition(root.waitUntilReady(), in: app, "直向啟動後根導覽未就緒")
        try requireCondition(root.goToInsights(), in: app, "直向切到分析頁後畫面未就緒")

        // When
        try rotateToLandscape(app)

        // Then
        try captureInsights(in: app)
    }
}

// MARK: - Private Method

private extension OrientationLayoutTests {

    /// 斷言轉為橫向後的根導覽呈現：版面類別維持直向判定類別，compact 額外斷言有底部分頁列且無側邊欄
    ///
    /// - Parameters:
    ///   - navigator: 根導覽 helper
    ///   - app: 受測 App
    ///   - expected: 預期的根導覽版面類別
    /// - Throws: 根導覽呈現不符預期時丟出測試錯誤
    func assertRootNavigation(
        navigator: AppNavigator,
        in app: XCUIApplication,
        expected: AppNavigator.RootLayout
    ) throws {
        let actual = navigator.rootLayout
        let actualDescription = actual.map { String(describing: $0) } ?? "nil"
        try requireCondition(
            actual == expected,
            in: app,
            "橫向根導覽版面不符預期 (預期: \(expected), 實際: \(actualDescription))"
        )
        switch expected {
        case .regular:
            // 側邊欄與頂部分頁列都屬 regular 版面，前述 `rootLayout` 已核驗，此處不另斷言
            break

        case .compact:
            try requireCondition(
                app.tabBars.firstMatch.waitForExistence(timeout: 10),
                in: app,
                "compact 版面橫向沒有底部分頁列"
            )
            try requireCondition(!navigator.isSidebarLayout, in: app, "compact 版面橫向出現側邊欄")
        }
    }

    /// 斷言轉為橫向後的訂單篩選呈現：regular 不顯示整合篩選鈕，compact 顯示整合篩選鈕
    ///
    /// - Parameters:
    ///   - app: 受測 App
    ///   - isRegular: 訂單前景是否為 regular 欄位呈現
    /// - Throws: 訂單清單未就緒或篩選鈕狀態不符預期時丟出測試錯誤
    func assertOrdersFilter(in app: XCUIApplication, isRegular: Bool) throws {
        try requireCondition(OrdersScreen(app: app).waitUntilReady(), in: app, "訂單清單未就緒")
        if isRegular {
            if filterButton(in: app).waitForExistence(timeout: 2) {
                failWithDiagnostics(in: app, "regular 版面橫向不應顯示整合篩選鈕")
            }
        } else {
            try requireCondition(
                filterButton(in: app).waitForExistence(timeout: 10),
                in: app,
                "compact 版面橫向的訂單頁沒有整合篩選鈕"
            )
        }
    }

    /// 取整合篩選鈕，以任意元素類型查詢，避免類型不符被誤判為不存在
    ///
    /// - Parameter app: 受測 App
    /// - Returns: 整合篩選鈕元素
    func filterButton(in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any)[BLAccessibilityID.Orders.filterButton]
    }

    /// 先附首頁截圖，再確認營收 KPI 卡並捲入畫面附上第二張截圖
    ///
    /// - Parameter app: 受測 App
    /// - Throws: 首頁或 KPI 卡未就緒，或視窗已不是橫向時丟出測試錯誤
    func captureDashboard(in app: XCUIApplication) throws {
        let dashboard = DashboardScreen(app: app)
        try attachScreenshot(named: "橫向首頁", of: app)
        try requireCondition(dashboard.kpiValue(.revenue) != nil, in: app, "橫向首頁沒有營收 KPI 卡")

        let tile = app.descendants(matching: .any)[BLAccessibilityID.Dashboard.kpiTile(.revenue)]
        scrollIntoView(tile, within: dashboard.rootElement, in: app)
        try attachScreenshot(named: "橫向首頁 KPI 卡", of: app)
    }

    /// 確認視窗仍是橫向後附上 App 的截圖 (橫向時只擷取到部分畫面)，附件保留在 result bundle
    ///
    /// - Parameters:
    ///   - name: 附件名稱
    ///   - app: 受測 App
    /// - Throws: 視窗已不是橫向時丟出測試錯誤
    func attachScreenshot(named name: String, of app: XCUIApplication) throws {
        let isLandscape = waitForLandscapeWindow(of: app, timeout: 5)
        try requireCondition(isLandscape, in: app, "截圖「\(name)」前視窗不是橫向")

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// 捲動目標進入畫面 (以大步幅的無慣性拖曳)；捲不到不算失敗，露出與否由截圖人工確認
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
    /// - Throws: 訂單頁或訂單列未就緒，或視窗已不是橫向時丟出測試錯誤
    func captureOrders(in app: XCUIApplication) throws {
        try requireCondition(OrdersScreen(app: app).waitUntilReady(), in: app, "訂單清單未就緒")

        let rowPrefix = BLAccessibilityID.Orders.row(orderID: "")
        let firstRow = rows(withIdentifierPrefix: rowPrefix, in: app).firstMatch
        try requireCondition(firstRow.waitUntilHittable(), in: app, "訂單清單沒有可點的訂單列")
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

    /// 捲動分析頁的類別排行與成本結構卡片進入畫面，依序各附一張截圖
    ///
    /// - Parameter app: 受測 App
    /// - Throws: 分析頁、類別排行列或成本結構圖未就緒，或視窗已不是橫向時丟出測試錯誤
    func captureInsights(in app: XCUIApplication) throws {
        let insights = InsightsScreen(app: app)
        try requireCondition(insights.waitUntilReady(), in: app, "分析頁未就緒")

        let rowPrefix = BLAccessibilityID.Insights.categoryRankRow(category: "")
        let categoryRow = rows(withIdentifierPrefix: rowPrefix, in: app).firstMatch
        try requireCondition(categoryRow.waitForExistence(timeout: 10), in: app, "分析頁沒有類別排行列")
        scrollIntoView(categoryRow, within: insights.rootElement, in: app)
        try attachScreenshot(named: "橫向分析頁 類別排行", of: app)

        try requireCondition(insights.revealCostDonut(), in: app, "分析頁沒有成本結構圖")
        try attachScreenshot(named: "橫向分析頁 成本結構", of: app)
    }
}
