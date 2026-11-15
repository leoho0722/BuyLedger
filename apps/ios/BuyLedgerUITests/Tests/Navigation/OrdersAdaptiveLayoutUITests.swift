//
//  OrdersAdaptiveLayoutUITests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/11/15.
//

import XCTest

/// 訂單清單與詳情在轉向、搜尋與篩選後的自適應版面 UI 測試，涵蓋選取與路徑保留、未選取提示、膠囊可達性與欄位框線
@MainActor
final class OrdersAdaptiveLayoutUITests: BLUITestCase {

    /// 驗證 iPad 同一訂單在並排與收合之間旋轉時，路徑與詳情內容都保持為當前訂單，改選另一筆後亦同
    ///
    /// - Throws: 根導覽、訂單清單、路徑標記或詳情內容不符合預期時丟出測試錯誤
    /// - Note: 對應驗收矩陣 N2
    /// - Note: 只驗證 iPad 同 ID 保留
    func testDetailSelectionChanged_並排選取後反覆轉向與改選_路徑與詳情同為當前訂單() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .fullOrders))
        let navigator = AppNavigator(app: app)
        try rotateToLandscape(app)
        let layout = try navigator.rootLayout()
        try XCTSkipUnless(layout == .regular, "需 iPad regular 根導覽")
        let orders = try OrdersScreen.open(in: app)
        try XCTSkipUnless(try ordersLayout(in: app) == .regular, "需 Orders 清單與詳情並排")

        // When
        try orders.tapOrder(orderID: "BL-2604-017")

        // Then
        try requireSelectedOrder("BL-2604-017", in: orders, app: app)
        try requireDetailShows("BL-2604-017", in: app)

        // When
        try rotateToPortrait(app)
        try XCTSkipUnless(try ordersLayout(in: app) != .regular, "直向仍為並排版面，此裝置直向不會收合")

        // Then
        try requireCondition(try ordersLayout(in: app) == .compact, in: app, "直向後 Orders 應為收合版面")
        try requireSelectedOrder("BL-2604-017", in: orders, app: app)
        try requireDetailShows("BL-2604-017", in: app)

        // When
        try rotateToLandscape(app)

        // Then
        try requireCondition(try ordersLayout(in: app) == .regular, in: app, "回到橫向後 Orders 應為並排版面")
        try requireSelectedOrder("BL-2604-017", in: orders, app: app)
        try requireDetailShows("BL-2604-017", in: app)

        // When
        try orders.tapOrder(orderID: "BL-2604-015")

        // Then
        try requireSelectedOrder("BL-2604-015", in: orders, app: app)
        try requireDetailShows("BL-2604-015", excluding: "BL-2604-017", in: app)

        // When
        try rotateToPortrait(app)

        // Then
        try requireCondition(try ordersLayout(in: app) == .compact, in: app, "直向後 Orders 應為收合版面")
        try requireSelectedOrder("BL-2604-015", in: orders, app: app)
        try requireDetailShows("BL-2604-015", excluding: "BL-2604-017", in: app)
    }

    /// 驗證首次進入訂單與轉向後都沒有自動選取，寬版顯示未選取提示、收合版顯示清單，點選訂單後才顯示詳情
    ///
    /// - Throws: 訂單清單、路徑標記、提示或詳情不符合預期時丟出測試錯誤
    /// - Note: 對應驗收矩陣 N3
    /// - Note: 寬版以未選取提示判定，收合版以清單可見判定
    /// - Note: 收合版的原生返回與返回後未選取由下列測試覆蓋
    ///   `OrdersNavigationUITests.testDetailSelectionChanged_收合版選取訂單後原生返回_詳情顯示營收4980且path清空`
    func testDetailSelectionChanged_首次進入訂單並轉向_點選前維持未選取() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .fullOrders))

        // When
        let orders = try OrdersScreen.open(in: app)
        try assertOrdersLayoutIsRecognized(in: app)

        // Then
        try requireOrdersUnselected(orders, in: app)

        // When
        try rotateToLandscape(app)

        // Then
        try assertOrdersLayoutIsRecognized(in: app)
        try requireOrdersUnselected(orders, in: app)

        // When
        try orders.tapOrder(orderID: "BL-2604-017")

        // Then
        try requireDetailShows("BL-2604-017", in: app)
    }

    /// 驗證搜尋仍命中已選訂單時保留選取與詳情，排除時清空路徑且搜尋恢復後不自動選取
    ///
    /// - Throws: 搜尋、路徑標記、詳情或無選取提示不符合預期時丟出測試錯誤
    /// - Note: 對應驗收矩陣 N4
    /// - Note: 排除段的斷言與 `OrdersNavigationUITests.testSearchTextChanged_搜尋排除詳情後恢復結果_清除path且不自動選取` 相同
    func testSearchTextChanged_並排已選取後搜尋命中與排除_命中保留選取且排除後清空() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .fullOrders))
        let orders = try OrdersScreen.open(in: app)
        try XCTSkipUnless(try ordersLayout(in: app) == .regular, "同步搜尋與詳情需 Orders 欄位並排")

        // When
        try orders.tapOrder(orderID: "BL-2604-017")

        // Then
        try requireDetailShows("BL-2604-017", in: app)

        // When
        try orders.search("Mika")

        // Then
        try requireSelectedOrder("BL-2604-017", in: orders, app: app)
        try requireDetailShows("BL-2604-017", in: app)

        // When
        try orders.search("ZZZ-NO-SUCH-ORDER")

        // Then
        let emptySelection = try requireValue(
            orders.pathProjectedOrderID(),
            in: app,
            "排除搜尋後 Orders path 標記不存在"
        )
        try requireCheckPassed(
            IdentifierCheck.verify(expected: "", observed: emptySelection),
            in: app
        )
        try assertUnselectedPromptVisible(orders, in: app)

        // When
        try orders.search("Mika")

        // Then
        let restoredSelection = try requireValue(
            orders.pathProjectedOrderID(),
            in: app,
            "搜尋恢復後 Orders path 標記不存在"
        )
        try requireCheckPassed(
            IdentifierCheck.verify(expected: "", observed: restoredSelection),
            in: app
        )
        try requireCondition(orders.hasOrder(orderID: "BL-2604-017"), in: app, "搜尋結果未恢復")
    }

    /// 驗證 iPhone 收合版的訂單篩選膠囊可捲動點選，點選後膠囊框線不進入底部分頁列與狀態列
    ///
    /// - Throws: 根導覽、膠囊列或框線不符合預期時丟出測試錯誤
    /// - Note: 對應驗收矩陣 L2
    /// - Note: 收合版的系統保留區以底部分頁列與狀態列判定
    func testStatusFilterSelected_iPhone收合版_膠囊可捲動點選且不進入系統列() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .fullOrders))
        let navigator = AppNavigator(app: app)
        let layout = try navigator.rootLayout()
        try XCTSkipUnless(layout == .compact, "膠囊可捲動點選的保留區案例只適用底部分頁列的 compact 版面")
        let orders = try OrdersScreen.open(in: app)

        // When
        try orders.selectStatusChip(filterID: "shipping")
        try orders.revealStatusChipFully(filterID: "shipping", in: app.windows.firstMatch)
        let isChipRevealed = orders.isStatusChipFullyVisible(
            filterID: "shipping",
            in: app.windows.firstMatch
        )

        // Then
        try requireCondition(
            orders.isRegularStatusChipSelected("shipping"),
            in: app,
            "捲動點選後狀態膠囊未選中"
        )
        try requireCondition(isChipRevealed, in: app, "狀態膠囊無法捲入視窗可視範圍")
        let window = try requireValidFrame(of: app.windows.firstMatch, in: app, context: "視窗框線")
        let chip = orders.statusChip("shipping")
        let chipFrame = try requireValue(
            app.stableVisibleFrame(of: chip, within: app.windows.firstMatch),
            in: app,
            "狀態膠囊框線不可用"
        )
        let tabBarFrame = try requireValidFrame(
            of: app.tabBars.firstMatch,
            in: app,
            context: "底部分頁列框線"
        )
        var reservedRegions = [tabBarFrame]
        let statusBar = app.statusBars.firstMatch
        if statusBar.exists {
            let statusBarFrame = try requireValidFrame(of: statusBar, in: app, context: "狀態列框線")
            reservedRegions.append(statusBarFrame)
        }
        try requireCheckPassed(
            BoundsCheck.verify(
                frame: chipFrame,
                container: window,
                reservedRegions: reservedRegions
            ),
            in: app
        )
    }

    /// 驗證訂單在根樣式切換與方向改變後保留選取；並排時清單與詳情框線互不重疊，收合時仍可辨識版面模式
    ///
    /// - Throws: 路徑標記、詳情或版面判定不符合預期時丟出測試錯誤
    /// - Note: 對應驗收矩陣 L3
    /// - Note: 分欄範圍依訂單前景模式判定
    func testRotateToLandscape_訂單已選取轉向往返_路徑保留且並排框線不重疊() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .fullOrders))
        let root = RootNavigationScreen(app: app)
        try requireCondition(root.waitUntilReady(), in: app, "根導覽未就緒，總覽頁根 identifier 逾時仍未出現")
        let navigator = AppNavigator(app: app)
        let initialTabCount = navigator.visibleRootTabCount()
        try requireCondition(
            !navigator.isSidebarMarkerVisible && initialTabCount == 5,
            in: app,
            "初始根導覽應為五個原生 Tabs，實際數量=\(initialTabCount)"
        )
        let orders = try OrdersScreen.open(in: app)
        try orders.tapOrder(orderID: "BL-2604-018")
        try requireSelectedOrder("BL-2604-018", in: orders, app: app)
        try assertOrdersLayoutIsRecognized(in: app)
        if try ordersLayout(in: app) == .regular {
            try assertOrdersSplitGeometry(orders, in: app)
        } else {
            try requireCondition(try ordersLayout(in: app) == .compact, in: app, "收合版面應可辨識為收合")
        }

        // When
        try rotateToLandscape(app)

        // Then
        try requireSelectedOrder("BL-2604-018", in: orders, app: app)
        try assertOrdersLayoutIsRecognized(in: app)
        if try ordersLayout(in: app) == .regular {
            try assertOrdersSplitGeometry(orders, in: app)
        } else {
            try requireCondition(try ordersLayout(in: app) == .compact, in: app, "收合版面應可辨識為收合")
        }
        try requireCondition(OrderDetailScreen(app: app).waitUntilReady(), in: app, "橫向後訂單詳情未保留")

        // When
        try rotateToPortrait(app)

        // Then
        try requireSelectedOrder("BL-2604-018", in: orders, app: app)
        try assertOrdersLayoutIsRecognized(in: app)
        if try ordersLayout(in: app) == .regular {
            try assertOrdersSplitGeometry(orders, in: app)
        } else {
            try requireCondition(try ordersLayout(in: app) == .compact, in: app, "收合版面應可辨識為收合")
        }
        try requireCondition(OrderDetailScreen(app: app).waitUntilReady(), in: app, "直向後訂單詳情未保留")
    }
}

// MARK: - Private Method

private extension OrdersAdaptiveLayoutUITests {

    /// 等待詳情根的可及性值顯示指定訂單，並確認未保留舊訂單
    ///
    /// - Parameters:
    ///   - orderID: 詳情應呈現的訂單編號
    ///   - staleOrderID: 不應再呈現的舊訂單編號
    ///   - app: 受測 App
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 詳情未顯示指定訂單或仍顯示舊訂單時丟出測試錯誤
    func requireDetailShows(
        _ orderID: String,
        excluding staleOrderID: String? = nil,
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        let detail = OrderDetailScreen(app: app)
        let isExpectedOrder = Polling.wait(timeout: 10) { detail.displayedOrderID() == orderID }
        guard isExpectedOrder else {
            try app.stopWithDiagnostics(
                "訂單詳情逾時仍未呈現編號 \(orderID)",
                file: file,
                line: line
            )
        }
        if let staleOrderID, detail.displayedOrderID() == staleOrderID {
            try app.stopWithDiagnostics(
                "訂單詳情仍顯示舊訂單 \(staleOrderID)",
                file: file,
                line: line
            )
        }
    }

    /// 確認 Orders 導覽路徑標記與期望的訂單識別碼一致
    ///
    /// - Parameters:
    ///   - orderID: 期望的訂單識別碼
    ///   - orders: 訂單清單 Page Object
    ///   - app: 受測 App
    /// - Throws: 路徑標記缺失或識別碼不符時丟出測試錯誤
    func requireSelectedOrder(
        _ orderID: String,
        in orders: OrdersScreen,
        app: XCUIApplication
    ) throws(UITestError) {
        let actual = try requireValue(orders.pathProjectedOrderID(), in: app, "Orders 導覽路徑標記不存在")
        try requireCheckPassed(IdentifierCheck.verify(expected: orderID, observed: actual), in: app)
    }

    /// 確認訂單未選取，且版面對應的未選取呈現可見
    ///
    /// - Parameters:
    ///   - orders: 訂單清單 Page Object
    ///   - app: 受測 App
    /// - Throws: 路徑標記缺失、已有選取，或版面對應的未選取呈現不可見時丟出測試錯誤
    func requireOrdersUnselected(
        _ orders: OrdersScreen,
        in app: XCUIApplication
    ) throws(UITestError) {
        let selection = try requireValue(
            orders.pathProjectedOrderID(),
            in: app,
            "Orders path 選取標記不存在"
        )
        try requireCheckPassed(IdentifierCheck.verify(expected: "", observed: selection), in: app)
        if try ordersLayout(in: app) == .regular {
            try assertUnselectedPromptVisible(orders, in: app)
        } else {
            try requireCondition(orders.hasOrder(orderID: "BL-2604-017"), in: app, "收合版未選取時訂單清單應可見")
        }
    }

    /// 確認寬版詳情欄顯示未選取提示
    ///
    /// - Parameters:
    ///   - orders: 訂單清單 Page Object
    ///   - app: 受測 App
    /// - Throws: 提示未出現或沒有有效框線時丟出測試錯誤
    func assertUnselectedPromptVisible(
        _ orders: OrdersScreen,
        in app: XCUIApplication
    ) throws(UITestError) {
        try requireCondition(
            orders.hasDetailEmptyState(),
            in: app,
            "寬版未選取時未顯示詳情選取提示"
        )
    }

    /// 確認並排時詳情內容錨點與清單框線不重疊，非並排時失敗
    ///
    /// - Parameters:
    ///   - orders: 訂單清單 Page Object
    ///   - app: 受測 App
    /// - Throws: 非並排、詳情錨點缺席或與清單框線重疊時丟出測試錯誤
    /// - Note: 詳情根容器在 iPadOS 27 會延伸到清單欄底下，因此以摘要格、更多按鈕或空狀態提示判定詳情欄位置
    func assertOrdersSplitGeometry(
        _ orders: OrdersScreen,
        in app: XCUIApplication
    ) throws(UITestError) {
        try requireCondition(
            try ordersLayout(in: app) == .regular,
            in: app,
            "並排框線檢查需要 Orders 清單與詳情並排"
        )
        let window = try requireValidFrame(of: app.windows.firstMatch, in: app, context: "視窗框線")
        let listFrame = try requireValidFrame(
            of: orders.rootElement,
            in: app,
            context: "並排訂單清單框線"
        )
        let detailFrame = try requireValue(
            foregroundOrdersDetailFrame(in: app),
            in: app,
            "找不到並排訂單詳情內容錨點"
        )
        try requireCheckPassed(
            BoundsCheck.verify(frame: detailFrame, container: window, reservedRegions: [listFrame]),
            in: app
        )
    }
}
