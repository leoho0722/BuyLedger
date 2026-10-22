//
//  OrderRegularSearchBarTests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/10/20.
//

import CoreGraphics
import XCTest

/// regular 訂單清單欄搜尋結束後的標題與位置守門
final class OrderRegularSearchBarTests: BLUITestCase {

    // MARK: - Properties

    /// `mergeCandidates` 中明確選取的訂單編號
    private static let orderID = "UITEST-MRG-001"

    /// 仍符合選取訂單的搜尋文字 (單號片段)
    private static let matchingSearchText = "MRG-001"

    /// regular 測試的版面限制與 compact 覆蓋來源
    private static let layoutScopeReason = """
    清單欄導覽列只適用 regular 版面
    compact 搜尋由 OrdersListTests 覆蓋
    """

    /// 直向收鍵盤與清除搜尋文字後，標題保留且搜尋欄與詳情導覽列不位移
    ///
    /// - Throws: 版面不適用、必要元素缺少或標題與位置改變時拋出測試錯誤
    @MainActor
    func testRegularSearch_直向收鍵盤並清除文字_標題保留且位置不變() throws(any Error) {
        // Given
        let app = launch(LaunchOptions(seed: .mergeCandidates))
        try XCTSkipUnless(isRegularLayout(app), Self.layoutScopeReason)
        let orders = try openSelectedOrder(in: app)
        let before = try searchBarPositions(of: orders, in: app, context: "直向搜尋前")

        // When
        let afterDismiss = try searchAndDismissKeyboard(orders, in: app, matching: before)
        let afterClear = try clearSearch(orders, in: app, matching: before)

        // Then
        try assertSearchBarPositions(
            afterDismiss,
            matches: before,
            in: app,
            context: "直向收鍵盤後"
        )
        try assertSearchBarPositions(
            afterClear,
            matches: before,
            in: app,
            context: "直向清除文字後"
        )
    }

    /// 橫向收鍵盤與清除搜尋文字後，標題保留且搜尋欄與詳情導覽列不位移
    ///
    /// - Throws: 版面不適用、必要元素缺少或標題與位置改變時拋出測試錯誤
    @MainActor
    func testRegularSearch_橫向收鍵盤並清除文字_標題保留且位置不變() throws(any Error) {
        // Given
        let app = launch(LaunchOptions(seed: .mergeCandidates))
        try XCTSkipUnless(isRegularLayout(app), Self.layoutScopeReason)
        let orders = try openSelectedOrder(in: app)
        try rotateToLandscape(app)
        let before = try searchBarPositions(of: orders, in: app, context: "橫向搜尋前")

        // When
        let afterDismiss = try searchAndDismissKeyboard(orders, in: app, matching: before)
        let afterClear = try clearSearch(orders, in: app, matching: before)

        // Then
        try assertSearchBarPositions(
            afterDismiss,
            matches: before,
            in: app,
            context: "橫向收鍵盤後"
        )
        try assertSearchBarPositions(
            afterClear,
            matches: before,
            in: app,
            context: "橫向清除文字後"
        )
    }
}

// MARK: - Nested Types

private extension OrderRegularSearchBarTests {

    /// 清單欄搜尋相關元素的標題與垂直位置
    struct SearchBarPositions {

        /// 清單欄導覽列的標題，沒有可見標題時為 `nil`
        let listTitle: String?

        /// 搜尋欄上緣
        let searchFieldMinY: CGFloat

        /// 詳情欄導覽列上緣
        let detailBarMinY: CGFloat

        /// 判斷與另一次量測的標題相同，且兩個上緣相差不超過 1 點
        ///
        /// - Parameter other: 用來比較的量測結果
        /// - Returns: 是否視為相同版面
        func matches(_ other: SearchBarPositions) -> Bool {
            listTitle == other.listTitle
                && abs(searchFieldMinY - other.searchFieldMinY) <= 1
                && abs(detailBarMinY - other.detailBarMinY) <= 1
        }
    }
}

// MARK: - Private Method

@MainActor
private extension OrderRegularSearchBarTests {

    /// 切到訂單並明確選取種子訂單，等待詳情內容就緒
    ///
    /// - Parameter app: 受測 App
    /// - Returns: 已選取訂單的清單 Page Object
    /// - Throws: 訂單分頁或詳情未就緒時拋出測試錯誤
    func openSelectedOrder(in app: XCUIApplication) throws(any Error) -> OrdersScreen {
        let root = RootNavigationScreen(app: app)
        try requireCondition(root.goToOrders(), in: app, "找不到元素：訂單分頁根容器")
        let orders = OrdersScreen(app: app)
        try requireCondition(orders.waitUntilReady(), in: app, "找不到元素：訂單清單根容器")
        orders.tapOrder(orderID: Self.orderID)
        let detail = OrderDetailScreen(app: app)
        try requireCondition(detail.waitUntilReady(), in: app, "找不到元素：選取訂單的詳情根容器")
        return orders
    }

    /// 輸入仍符合選取訂單的文字後以 Return 收起鍵盤，再取得穩定後的版面
    ///
    /// - Parameters:
    ///   - orders: 訂單清單的 Page Object
    ///   - app: 受測 App
    ///   - before: 搜尋前的版面，用來等待動畫結束
    /// - Returns: 收鍵盤後的版面
    /// - Throws: 搜尋欄不可互動或鍵盤未收起時拋出測試錯誤
    func searchAndDismissKeyboard(
        _ orders: OrdersScreen,
        in app: XCUIApplication,
        matching before: SearchBarPositions
    ) throws(any Error) -> SearchBarPositions {
        let field = try orders.hittableSearchField()
        field.clearAndType(Self.matchingSearchText, in: app)
        field.typeText(XCUIKeyboardKey.return.rawValue)
        try requireCondition(
            field.wait(for: NSPredicate(format: "hasKeyboardFocus == false"), timeout: 5),
            in: app,
            "按下 Return 後搜尋欄仍保有鍵盤焦點"
        )
        return try settledSearchBarPositions(
            of: orders,
            in: app,
            matching: before,
            context: "收鍵盤後"
        )
    }

    /// 以搜尋欄的清除鈕清空文字，再取得穩定後的版面
    ///
    /// - Parameters:
    ///   - orders: 訂單清單的 Page Object
    ///   - app: 受測 App
    ///   - before: 搜尋前的版面，用來等待動畫結束
    /// - Returns: 清除文字後的版面
    /// - Throws: 清除鈕不可互動時拋出測試錯誤
    func clearSearch(
        _ orders: OrdersScreen,
        in app: XCUIApplication,
        matching before: SearchBarPositions
    ) throws(any Error) -> SearchBarPositions {
        // 清除鈕的標籤隨系統語言變動，改取搜尋欄內唯一的按鈕
        let clearButton = try orders.hittableSearchField().buttons.firstMatch
        _ = try requireHittableFrame(of: clearButton, in: app, context: "搜尋欄清除鈕")
        clearButton.tap()
        return try settledSearchBarPositions(
            of: orders,
            in: app,
            matching: before,
            context: "清除文字後"
        )
    }

    /// 在逾時內重複量測，直到與搜尋前相同或逾時，回傳最後一次量測
    ///
    /// - Parameters:
    ///   - orders: 訂單清單的 Page Object
    ///   - app: 受測 App
    ///   - before: 搜尋前的版面
    ///   - context: 失敗訊息中的檢查情境
    /// - Returns: 最後一次量測的版面
    /// - Throws: 必要元素缺少時拋出測試錯誤
    func settledSearchBarPositions(
        of orders: OrdersScreen,
        in app: XCUIApplication,
        matching before: SearchBarPositions,
        context: String
    ) throws(any Error) -> SearchBarPositions {
        let deadline = Date.now.addingTimeInterval(5)
        var layout = try searchBarPositions(of: orders, in: app, context: context)
        while !layout.matches(before), Date.now < deadline {
            // 導覽列在搜尋狀態切換時有動畫，讓出 run loop 後重量
            RunLoop.current.run(until: Date.now.addingTimeInterval(0.25))
            layout = try searchBarPositions(of: orders, in: app, context: context)
        }
        return layout
    }

    /// 量測清單欄導覽列標題、搜尋欄與詳情欄導覽列的位置
    ///
    /// - Parameters:
    ///   - orders: 訂單清單的 Page Object
    ///   - app: 受測 App
    ///   - context: 失敗訊息中的檢查情境
    /// - Returns: 目前的版面
    /// - Throws: 清單根容器、搜尋欄或詳情欄導覽列缺少時拋出測試錯誤
    func searchBarPositions(
        of orders: OrdersScreen,
        in app: XCUIApplication,
        context: String
    ) throws(any Error) -> SearchBarPositions {
        let list = app.descendants(matching: .any)[BLAccessibilityID.Orders.listRoot]
        let listFrame = try requireValidFrame(of: list, in: app, context: "\(context)，訂單清單根容器")
        let navigationBars = app.navigationBars.allElementsBoundByIndex.filter(\.isHittableOnScreen)
        let listBar = navigationBars.first { $0.frame.maxX <= listFrame.maxX + 1 }
        let detailBar = try requireValue(
            navigationBars.first { $0.frame.minX >= listFrame.maxX - 1 },
            in: app,
            "找不到元素：\(context)，詳情欄導覽列"
        )
        let searchField = try orders.hittableSearchField()
        return SearchBarPositions(
            listTitle: listBar.flatMap(visibleTitle(of:)),
            searchFieldMinY: searchField.frame.minY,
            detailBarMinY: detailBar.frame.minY
        )
    }

    /// 取得導覽列上可見的標題文字
    ///
    /// - Parameter navigationBar: 清單欄導覽列
    /// - Returns: 導覽列 identifier 對應的標題在畫面上可見時回傳該文字，否則為 `nil`
    func visibleTitle(of navigationBar: XCUIElement) -> String? {
        let title = navigationBar.identifier
        guard !title.isEmpty, navigationBar.staticTexts[title].isHittableOnScreen else {
            return nil
        }
        return title
    }

    /// 確認搜尋結束後的標題與位置與搜尋前相同
    ///
    /// - Parameters:
    ///   - layout: 搜尋結束後的版面
    ///   - before: 搜尋前的版面
    ///   - app: 受測 App
    ///   - context: 失敗訊息中的檢查情境
    /// - Throws: 標題消失或位置改變時拋出測試錯誤
    func assertSearchBarPositions(
        _ layout: SearchBarPositions,
        matches before: SearchBarPositions,
        in app: XCUIApplication,
        context: String
    ) throws(any Error) {
        try requireCondition(before.listTitle != nil, in: app, "找不到元素：搜尋前清單欄導覽列沒有可見標題")
        try requireCondition(
            layout.matches(before),
            in: app,
            """
            位置越界：\(context)，標題或位置與搜尋前不同
            搜尋前：標題 \(before.listTitle ?? "無")，搜尋欄上緣 \(before.searchFieldMinY)，\
            詳情導覽列上緣 \(before.detailBarMinY)
            \(context)：標題 \(layout.listTitle ?? "無")，搜尋欄上緣 \(layout.searchFieldMinY)，\
            詳情導覽列上緣 \(layout.detailBarMinY)
            """
        )
    }
}
