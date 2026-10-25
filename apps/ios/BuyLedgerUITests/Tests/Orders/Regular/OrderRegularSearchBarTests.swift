//
//  OrderRegularSearchBarTests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/10/20.
//

import CoreGraphics
import XCTest

/// regular 訂單清單欄搜尋結束後的標題與位置守門 UI 測試
@MainActor
final class OrderRegularSearchBarTests: BLUITestCase {

    // MARK: - Properties

    /// `mergeCandidates` 中明確選取的訂單編號
    private static let orderID = "UITEST-MRG-001"

    /// 仍符合選取訂單的搜尋文字 (單號片段)
    private static let matchingSearchText = "MRG-001"

    /// regular 清單欄導覽列固定的標題 (測試計畫鎖定正體中文)
    private static let listTitle = "訂單"

    /// 版面不符時略過測試的原因，說明 compact 搜尋由哪個測試覆蓋
    private static let layoutScopeReason = """
    清單欄導覽列只適用 regular 版面
    compact 搜尋由 OrdersListTests 覆蓋
    """

    /// 驗證 regular 版面直向時，搜尋後收鍵盤仍保留清單欄標題，搜尋欄與詳情導覽列位置也不變
    ///
    /// - Throws: 版面不適用、必要元素缺少或標題與位置改變時丟出測試錯誤
    func testRegularSearch_直向收鍵盤_標題保留且位置不變() throws {
        // Given
        let app = launch(LaunchOptions(seed: .mergeCandidates))
        try XCTSkipUnless(isRegularLayout(app), Self.layoutScopeReason)
        let orders = try openSelectedOrder(in: app)
        let before = try searchBarPositions(of: orders, in: app, context: "直向搜尋前")
        try requireCondition(
            before.listTitle == Self.listTitle,
            in: app,
            "搜尋前清單欄導覽列標題應為「\(Self.listTitle)」，實際為「\(before.listTitle ?? "無")」"
        )

        // When
        try searchAndDismissKeyboard(orders, in: app)

        // Then
        let after = try settledSearchBarPositions(
            of: orders,
            in: app,
            matching: before,
            context: "直向收鍵盤後"
        )
        try assertSearchBarPositions(
            after,
            matches: before,
            in: app,
            context: "直向收鍵盤後"
        )
    }

    /// 驗證 regular 版面直向時，搜尋後清除文字仍保留清單欄標題，搜尋欄與詳情導覽列位置也不變
    ///
    /// - Throws: 版面不適用、必要元素缺少或標題與位置改變時丟出測試錯誤
    func testClearSearch_直向搜尋後清除文字_標題保留且位置不變() throws {
        // Given
        let app = launch(LaunchOptions(seed: .mergeCandidates))
        try XCTSkipUnless(isRegularLayout(app), Self.layoutScopeReason)
        let orders = try openSelectedOrder(in: app)
        let before = try searchBarPositions(of: orders, in: app, context: "直向搜尋前")
        try requireCondition(
            before.listTitle == Self.listTitle,
            in: app,
            "搜尋前清單欄導覽列標題應為「\(Self.listTitle)」，實際為「\(before.listTitle ?? "無")」"
        )
        try searchAndDismissKeyboard(orders, in: app)

        // When
        try clearSearch(orders, in: app)

        // Then
        let after = try settledSearchBarPositions(
            of: orders,
            in: app,
            matching: before,
            context: "直向清除文字後"
        )
        try assertSearchBarPositions(
            after,
            matches: before,
            in: app,
            context: "直向清除文字後"
        )
    }

    /// 驗證 regular 版面橫向時，搜尋後收鍵盤仍保留清單欄標題，搜尋欄與詳情導覽列位置也不變
    ///
    /// - Throws: 版面不適用、必要元素缺少或標題與位置改變時丟出測試錯誤
    func testRegularSearch_橫向收鍵盤_標題保留且位置不變() throws {
        // Given
        let app = launch(LaunchOptions(seed: .mergeCandidates))
        try XCTSkipUnless(isRegularLayout(app), Self.layoutScopeReason)
        let orders = try openSelectedOrder(in: app)
        try rotateToLandscape(app)
        let before = try searchBarPositions(of: orders, in: app, context: "橫向搜尋前")
        try requireCondition(
            before.listTitle == Self.listTitle,
            in: app,
            "搜尋前清單欄導覽列標題應為「\(Self.listTitle)」，實際為「\(before.listTitle ?? "無")」"
        )

        // When
        try searchAndDismissKeyboard(orders, in: app)

        // Then
        let after = try settledSearchBarPositions(
            of: orders,
            in: app,
            matching: before,
            context: "橫向收鍵盤後"
        )
        try assertSearchBarPositions(
            after,
            matches: before,
            in: app,
            context: "橫向收鍵盤後"
        )
    }

    /// 驗證 regular 版面橫向時，搜尋後清除文字仍保留清單欄標題，搜尋欄與詳情導覽列位置也不變
    ///
    /// - Throws: 版面不適用、必要元素缺少或標題與位置改變時丟出測試錯誤
    func testClearSearch_橫向搜尋後清除文字_標題保留且位置不變() throws {
        // Given
        let app = launch(LaunchOptions(seed: .mergeCandidates))
        try XCTSkipUnless(isRegularLayout(app), Self.layoutScopeReason)
        let orders = try openSelectedOrder(in: app)
        try rotateToLandscape(app)
        let before = try searchBarPositions(of: orders, in: app, context: "橫向搜尋前")
        try requireCondition(
            before.listTitle == Self.listTitle,
            in: app,
            "搜尋前清單欄導覽列標題應為「\(Self.listTitle)」，實際為「\(before.listTitle ?? "無")」"
        )
        try searchAndDismissKeyboard(orders, in: app)

        // When
        try clearSearch(orders, in: app)

        // Then
        let after = try settledSearchBarPositions(
            of: orders,
            in: app,
            matching: before,
            context: "橫向清除文字後"
        )
        try assertSearchBarPositions(
            after,
            matches: before,
            in: app,
            context: "橫向清除文字後"
        )
    }
}

// MARK: - Nested Types

private extension OrderRegularSearchBarTests {

    /// 清單欄標題與搜尋欄、詳情導覽列垂直位置的量測結果，用來比對搜尋前後版面是否相同
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

private extension OrderRegularSearchBarTests {

    /// 切到訂單並明確選取種子訂單，等待詳情內容就緒
    ///
    /// - Parameter app: 受測 App
    /// - Returns: 已選取訂單的清單 Page Object
    /// - Throws: 訂單分頁或詳情未就緒時丟出測試錯誤
    func openSelectedOrder(in app: XCUIApplication) throws -> OrdersScreen {
        let root = RootNavigationScreen(app: app)
        try requireCondition(root.goToOrders(), in: app, "找不到元素：訂單分頁根容器")
        let orders = OrdersScreen(app: app)
        try requireCondition(orders.waitUntilReady(), in: app, "找不到元素：訂單清單根容器")
        orders.tapOrder(orderID: Self.orderID)
        let detail = OrderDetailScreen(app: app)
        try requireCondition(detail.waitUntilReady(), in: app, "找不到元素：選取訂單的詳情根容器")
        return orders
    }

    /// 量測清單欄導覽列標題、搜尋欄與詳情欄導覽列的位置
    ///
    /// - Parameters:
    ///   - orders: 訂單清單的 Page Object
    ///   - app: 受測 App
    ///   - context: 失敗訊息中的檢查情境
    /// - Returns: 目前的版面
    /// - Throws: 清單根容器、搜尋欄或詳情欄導覽列缺少時丟出測試錯誤
    func searchBarPositions(
        of orders: OrdersScreen,
        in app: XCUIApplication,
        context: String
    ) throws -> SearchBarPositions {
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

    /// 輸入仍符合選取訂單的文字後以 Return 收起鍵盤
    ///
    /// - Parameters:
    ///   - orders: 訂單清單的 Page Object
    ///   - app: 受測 App
    /// - Throws: 搜尋欄不可互動或鍵盤未收起時丟出測試錯誤
    func searchAndDismissKeyboard(_ orders: OrdersScreen, in app: XCUIApplication) throws {
        let field = try orders.hittableSearchField()
        orders.typeSearchText(
            Self.matchingSearchText,
            into: field,
            clearButton: field.buttons.firstMatch
        )
        field.typeText(XCUIKeyboardKey.return.rawValue)
        try requireCondition(
            field.wait(for: NSPredicate(format: "hasKeyboardFocus == false"), timeout: 5),
            in: app,
            "按下 Return 後搜尋欄仍保有鍵盤焦點"
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
    /// - Throws: 必要元素缺少時丟出測試錯誤
    func settledSearchBarPositions(
        of orders: OrdersScreen,
        in app: XCUIApplication,
        matching before: SearchBarPositions,
        context: String
    ) throws -> SearchBarPositions {
        let deadline = Date.now.addingTimeInterval(5)
        var layout = try searchBarPositions(of: orders, in: app, context: context)
        while !layout.matches(before), Date.now < deadline {
            // 導覽列在搜尋狀態切換時有動畫，讓出 run loop 後重量
            RunLoop.current.run(until: Date.now.addingTimeInterval(0.25))
            layout = try searchBarPositions(of: orders, in: app, context: context)
        }
        return layout
    }

    /// 確認搜尋結束後的標題為固定標題，且位置與搜尋前相同
    ///
    /// - Parameters:
    ///   - layout: 搜尋結束後的版面
    ///   - before: 搜尋前的版面
    ///   - app: 受測 App
    ///   - context: 失敗訊息中的檢查情境
    /// - Throws: 標題不符或位置改變時丟出測試錯誤
    func assertSearchBarPositions(
        _ layout: SearchBarPositions,
        matches before: SearchBarPositions,
        in app: XCUIApplication,
        context: String
    ) throws {
        try requireCondition(
            layout.listTitle == Self.listTitle,
            in: app,
            "標題不符：\(context)清單欄標題應為「\(Self.listTitle)」，實際為「\(layout.listTitle ?? "無")」"
        )
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

    /// 以搜尋欄的清除鈕清空文字
    ///
    /// - Parameters:
    ///   - orders: 訂單清單的 Page Object
    ///   - app: 受測 App
    /// - Throws: 清除鈕不可互動時丟出測試錯誤
    func clearSearch(_ orders: OrdersScreen, in app: XCUIApplication) throws {
        // 清除鈕的標籤隨系統語言變動，改取搜尋欄內唯一的按鈕
        let clearButton = try orders.hittableSearchField().buttons.firstMatch
        _ = try requireHittableFrame(of: clearButton, in: app, context: "搜尋欄清除鈕")
        clearButton.tap()
    }
}
