//
//  OrdersRegularSearchBarUITests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/10/20.
//

import CoreGraphics
import XCTest

/// regular 訂單清單欄搜尋結束後的標題與位置守門 UI 測試
@MainActor
final class OrdersRegularSearchBarUITests: BLUITestCase {

    // MARK: - Properties

    /// 仍符合選取訂單的搜尋文字 (單號片段)
    private static let matchingSearchText = "MRG-001"

    /// regular 清單欄導覽列固定的標題 (測試計畫鎖定正體中文)
    private static let listTitle = "訂單"

    /// 詳情導覽列的種子客戶名稱，不隨 App 語言變動
    private static let customerName = "林書宇"

    /// 驗證直向搜尋後清單標題保留，搜尋欄與詳情導覽列位置不變
    ///
    /// - Throws: 版面不適用、必要元素缺少或標題與位置改變時丟出測試錯誤
    func testSearchAndDismissKeyboard_直向收鍵盤_標題保留且位置不變() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .mergeCandidates))
        let orders = try OrdersScreen.open(in: app)
        try XCTSkipUnless(
            try ordersLayout(in: app) == .regular,
            OrdersRegularColumnScopeUITestSupport.layoutScopeReason
        )
        try orders.tapOrder(orderID: OrdersSeedFixture.mergeOrderID)
        let before = try searchBarPositions(of: orders, in: app, context: "直向搜尋前")
        let actualTitle = before.listTitle ?? "無"
        try requireCondition(
            before.listTitle == Self.listTitle,
            in: app,
            "搜尋前標題應為「\(Self.listTitle)」，實際「\(actualTitle)」"
        )

        // When
        try orders.searchAndDismissKeyboard(Self.matchingSearchText)

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

    /// 驗證直向清除搜尋文字後標題保留，搜尋欄與詳情導覽列位置不變
    ///
    /// - Throws: 版面不適用、必要元素缺少或標題與位置改變時丟出測試錯誤
    func testClearSearchText_直向搜尋後清除文字_標題保留且位置不變() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .mergeCandidates))
        let orders = try OrdersScreen.open(in: app)
        try XCTSkipUnless(
            try ordersLayout(in: app) == .regular,
            OrdersRegularColumnScopeUITestSupport.layoutScopeReason
        )
        try orders.tapOrder(orderID: OrdersSeedFixture.mergeOrderID)
        let before = try searchBarPositions(of: orders, in: app, context: "直向搜尋前")
        let actualTitle = before.listTitle ?? "無"
        try requireCondition(
            before.listTitle == Self.listTitle,
            in: app,
            "搜尋前標題應為「\(Self.listTitle)」，實際「\(actualTitle)」"
        )
        try orders.searchAndDismissKeyboard(Self.matchingSearchText)

        // When
        try app.clearSearchText()

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

    /// 驗證橫向搜尋後清單標題保留，搜尋欄與詳情導覽列位置不變
    ///
    /// - Throws: 版面不適用、必要元素缺少或標題與位置改變時丟出測試錯誤
    func testSearchAndDismissKeyboard_橫向收鍵盤_標題保留且位置不變() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .mergeCandidates))
        let orders = try OrdersScreen.open(in: app)
        try XCTSkipUnless(
            try ordersLayout(in: app) == .regular,
            OrdersRegularColumnScopeUITestSupport.layoutScopeReason
        )
        try orders.tapOrder(orderID: OrdersSeedFixture.mergeOrderID)
        try rotateToLandscape(app)
        let before = try searchBarPositions(of: orders, in: app, context: "橫向搜尋前")
        let actualTitle = before.listTitle ?? "無"
        try requireCondition(
            before.listTitle == Self.listTitle,
            in: app,
            "搜尋前標題應為「\(Self.listTitle)」，實際「\(actualTitle)」"
        )

        // When
        try orders.searchAndDismissKeyboard(Self.matchingSearchText)

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

    /// 驗證橫向清除搜尋文字後標題保留，搜尋欄與詳情導覽列位置不變
    ///
    /// - Throws: 版面不適用、必要元素缺少或標題與位置改變時丟出測試錯誤
    func testClearSearchText_橫向搜尋後清除文字_標題保留且位置不變() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .mergeCandidates))
        let orders = try OrdersScreen.open(in: app)
        try XCTSkipUnless(
            try ordersLayout(in: app) == .regular,
            OrdersRegularColumnScopeUITestSupport.layoutScopeReason
        )
        try orders.tapOrder(orderID: OrdersSeedFixture.mergeOrderID)
        try rotateToLandscape(app)
        let before = try searchBarPositions(of: orders, in: app, context: "橫向搜尋前")
        let actualTitle = before.listTitle ?? "無"
        try requireCondition(
            before.listTitle == Self.listTitle,
            in: app,
            "搜尋前標題應為「\(Self.listTitle)」，實際「\(actualTitle)」"
        )
        try orders.searchAndDismissKeyboard(Self.matchingSearchText)

        // When
        try app.clearSearchText()

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

private extension OrdersRegularSearchBarUITests {

    /// 搜尋欄與詳情導覽列垂直位置的量測結果
    struct SearchBarPositions {

        /// 清單欄導覽列目前顯示的標題
        let listTitle: String?

        /// 搜尋欄上緣
        let searchFieldMinY: CGFloat

        /// 詳情欄導覽列上緣
        let detailBarMinY: CGFloat

        /// 判斷兩個上緣相差不超過 1 點
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

private extension OrdersRegularSearchBarUITests {

    /// 量測清單欄導覽列標題、搜尋欄與詳情欄導覽列的位置
    ///
    /// - Parameters:
    ///   - orders: 訂單清單的 Page Object
    ///   - app: 受測 App
    ///   - context: 失敗訊息中的檢查情境
    /// - Returns: 目前的版面
    /// - Throws: 清單欄標題、搜尋欄或詳情欄導覽列缺少時丟出測試錯誤
    /// - Note: iPadOS 27 詳情導覽列會延伸到清單欄底下，需依右緣辨識
    /// - Note: 橫向根 sidebar 導覽列在清單左側；清單導覽列須在清單框線內
    func searchBarPositions(
        of orders: OrdersScreen,
        in app: XCUIApplication,
        context: String
    ) throws(UITestError) -> SearchBarPositions {
        try requireCondition(
            app.waitForNavigationBarTitle(Self.listTitle),
            in: app,
            "找不到元素：\(context)，清單欄導覽列標題「\(Self.listTitle)」"
        )
        try requireCondition(
            app.waitForNavigationBarTitle(Self.customerName),
            in: app,
            "找不到元素：\(context)，詳情欄導覽列標題「\(Self.customerName)」"
        )
        let listFrame = try requireValidFrame(
            of: orders.rootElement,
            in: app,
            context: "\(context)，訂單清單根容器"
        )
        let navigationBars = app.navigationBars.allElementsBoundByIndex
            .filter(\.isHittableOnScreen)
        let listBar = try requireValue(
            navigationBars.first {
                $0.frame.minX >= listFrame.minX - 1
                    && $0.frame.maxX <= listFrame.maxX + 1
            },
            in: app,
            "找不到元素：\(context)，清單欄導覽列"
        )
        let detailBar = try requireValue(
            navigationBars.first { $0.frame.maxX > listFrame.maxX + 1 },
            in: app,
            "找不到元素：\(context)，詳情欄導覽列"
        )
        let searchField = try app.hittableSearchField()
        return SearchBarPositions(
            listTitle: app.visibleNavigationBarTitle(of: listBar),
            searchFieldMinY: searchField.frame.minY,
            detailBarMinY: detailBar.frame.minY
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
    ) throws(UITestError) -> SearchBarPositions {
        var latestLayout: SearchBarPositions?
        var measurementError: UITestError?
        _ = Polling.wait(timeout: 5, interval: 0.25) {
            if measurementError != nil {
                return true
            }
            do throws(UITestError) {
                let layout = try searchBarPositions(of: orders, in: app, context: context)
                latestLayout = layout
                return layout.matches(before)
            } catch {
                measurementError = error
                return true
            }
        }
        if let measurementError {
            throw measurementError
        }
        guard let latestLayout else {
            try app.stopWithDiagnostics("逾時仍無法量測搜尋列版面：\(context)")
        }
        return latestLayout
    }

    /// 確認搜尋結束後標題仍可見，且搜尋欄與詳情導覽列位置未變
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
    ) throws(UITestError) {
        try requireCondition(
            app.waitForNavigationBarTitle(Self.listTitle),
            in: app,
            "標題不符：\(context)清單欄標題應為「\(Self.listTitle)」"
        )
        try requireCondition(
            layout.listTitle == Self.listTitle,
            in: app,
            """
            標題不符：\(context)清單欄標題應為「\(Self.listTitle)」，\
            框線對應標題為「\(layout.listTitle ?? "無")」
            """
        )
        try requireCondition(
            layout.matches(before),
            in: app,
            """
            位置越界：\(context)，搜尋欄或詳情導覽列位置與搜尋前不同，\
            搜尋前 [\(before.searchFieldMinY), \(before.detailBarMinY)]，\
            \(context) [\(layout.searchFieldMinY), \(layout.detailBarMinY)]
            """
        )
    }
}
