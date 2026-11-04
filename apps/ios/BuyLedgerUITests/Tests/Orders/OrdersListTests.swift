//
//  OrdersListTests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import CoreGraphics
import XCTest

/// 訂單清單的狀態篩選、搜尋與空狀態流程 UI 測試
@MainActor
final class OrdersListTests: BLUITestCase {

    // MARK: - Properties

    /// 「已確認」狀態膠囊的 `filterID`
    private static let confirmedFilterID = "confirmed"

    /// `fullOrders` 中唯一的「已確認」訂單編號
    private static let confirmedOrderID = "BL-2604-014"

    /// `fullOrders` 中狀態為「集運中」的訂單編號 (非已確認，供篩選排除斷言)
    private static let shippingOrderID = "BL-2604-018"

    /// `fullOrders` 中客戶為「林書宇」的兩筆訂單編號 (集運中與已交付各一)
    private static let linCustomerOrderIDs = ["BL-2604-018", "BL-2604-012"]

    /// `fullOrders` 中客戶為「Mika 周」的訂單編號 (供搜尋排除斷言)
    private static let mikaCustomerOrderID = "BL-2604-017"

    /// 版面不符時略過窄版搜尋測試的原因，說明並排清單欄由哪個測試覆蓋
    private static let compactSearchScopeReason = "只適用窄版清單，並排清單欄由 OrderRegularSearchBarTests 覆蓋"

    /// 驗證選「已確認」狀態後，已確認的訂單留在清單，集運中的訂單被篩掉
    func testSelectStatusChip_選已確認_留下已確認訂單並篩掉集運中訂單() {
        // Given
        let app = launch(LaunchOptions(seed: .fullOrders))
        let orders = openOrdersList(app)
        if !orders.hasOrder(orderID: Self.shippingOrderID) {
            failWithDiagnostics(in: app, "篩選前置條件未成立：\(Self.shippingOrderID)")
        }

        // When
        orders.selectStatusChip(filterID: Self.confirmedFilterID)

        // Then
        // 屬「已確認」的訂單應留在清單
        if !orders.hasOrder(orderID: Self.confirmedOrderID) {
            failWithDiagnostics(in: app, "選「已確認」後，該狀態的訂單「\(Self.confirmedOrderID)」不在清單")
        }
        // 「集運中」的訂單應被篩掉
        if !orders.orderRow(orderID: Self.shippingOrderID).waitForDisappearance() {
            failWithDiagnostics(in: app, "選「已確認」後，集運中訂單「\(Self.shippingOrderID)」仍留在清單")
        }
    }

    /// 驗證搜尋輸入「林書宇」後，該客戶的兩筆訂單留在清單，「Mika 周」的訂單被篩掉
    ///
    /// - Throws: 找不到可互動的搜尋欄時丟出測試錯誤
    func testSearch_輸入客戶名稱_留下該客戶訂單並篩掉他人訂單() throws {
        // Given
        let app = launch(LaunchOptions(seed: .fullOrders))
        let orders = openOrdersList(app)
        if !orders.hasOrder(orderID: Self.mikaCustomerOrderID) {
            failWithDiagnostics(in: app, "搜尋前置條件未成立：\(Self.mikaCustomerOrderID)")
        }

        // When
        // 客戶名屬使用者資料、可作為文字輸入；斷言仍走訂單列 identifier
        try orders.search("林書宇")

        // Then
        for orderID in Self.linCustomerOrderIDs where !orders.hasOrder(orderID: orderID) {
            failWithDiagnostics(in: app, "搜尋「林書宇」後，其訂單「\(orderID)」不在清單")
        }
        if !orders.orderRow(orderID: Self.mikaCustomerOrderID).waitForDisappearance() {
            failWithDiagnostics(in: app, "搜尋「林書宇」後，他人訂單「\(Self.mikaCustomerOrderID)」仍留在清單")
        }
    }

    /// 驗證窄版輸入文字後直接按關閉，導覽列標題恢復顯示，搜尋欄回到搜尋前的位置 (誤差 1 點內)
    ///
    /// - Throws: 版面不適用、必要元素缺少或標題與位置未恢復時丟出測試錯誤
    func testCloseSearch_窄版輸入後關閉搜尋_標題恢復且搜尋欄回到原位() throws {
        // Given
        let app = launch(LaunchOptions(seed: .fullOrders))
        let orders = openOrdersList(app)
        try XCTSkipUnless(isCompactLayout(app), Self.compactSearchScopeReason)
        let originalMinY = try orders.hittableSearchField().frame.minY
        try orders.search("林書宇")

        // When
        app.navigationBars.buttons["關閉"].firstMatch.tapAfterWaiting(in: app)

        // Then
        try assertSearchRestored(to: originalMinY, in: app)
    }

    /// 驗證窄版搜尋按 Return 收鍵盤後再按關閉，導覽列標題恢復顯示，搜尋欄回到搜尋前的位置 (誤差 1 點內)
    ///
    /// - Throws: 版面不適用、必要元素缺少、未收起鍵盤或標題與位置未恢復時丟出測試錯誤
    func testCloseSearch_窄版收鍵盤後關閉搜尋_標題恢復且搜尋欄回到原位() throws {
        // Given
        let app = launch(LaunchOptions(seed: .fullOrders))
        let orders = openOrdersList(app)
        try XCTSkipUnless(isCompactLayout(app), Self.compactSearchScopeReason)
        let originalMinY = try orders.hittableSearchField().frame.minY
        try orders.search("林書宇")
        let field = try orders.hittableSearchField()
        field.typeText(XCUIKeyboardKey.return.rawValue)
        try requireCondition(
            field.wait(for: NSPredicate(format: "hasKeyboardFocus == false"), timeout: 5),
            in: app,
            "按下 Return 後搜尋欄仍保有鍵盤焦點"
        )

        // When
        app.navigationBars.buttons["關閉"].firstMatch.tapAfterWaiting(in: app)

        // Then
        try assertSearchRestored(to: originalMinY, in: app)
    }

    /// 驗證窄版搜尋點清除鈕清空文字後再按關閉，導覽列標題恢復顯示，搜尋欄回到搜尋前的位置 (誤差 1 點內)
    ///
    /// - Throws: 版面不適用、必要元素缺少、文字未清除或標題與位置未恢復時丟出測試錯誤
    func testCloseSearch_窄版清除文字後關閉搜尋_標題恢復且搜尋欄回到原位() throws {
        // Given
        let app = launch(LaunchOptions(seed: .fullOrders))
        let orders = openOrdersList(app)
        try XCTSkipUnless(isCompactLayout(app), Self.compactSearchScopeReason)
        let originalMinY = try orders.hittableSearchField().frame.minY
        try orders.search("林書宇")
        let field = try orders.hittableSearchField()
        field.buttons.firstMatch.tapAfterWaiting(in: app)
        try requireCondition(
            pollUntil(timeout: 3) { field.value as? String != "林書宇" },
            in: app,
            "點清除鈕後搜尋欄仍有文字"
        )

        // When
        app.navigationBars.buttons["關閉"].firstMatch.tapAfterWaiting(in: app)

        // Then
        try assertSearchRestored(to: originalMinY, in: app)
    }

    /// 驗證搜尋不存在的關鍵字「ZZZ-NO-SUCH-ORDER」時，清單顯示空狀態
    ///
    /// - Throws: 找不到可互動的搜尋欄時丟出測試錯誤
    func testSearch_沒有符合的訂單_顯示空狀態() throws {
        // Given
        let app = launch(LaunchOptions(seed: .fullOrders))
        let orders = openOrdersList(app)

        // When
        try orders.search("ZZZ-NO-SUCH-ORDER")

        // Then
        assertEmptyState(BLAccessibilityID.Orders.listEmptyState, in: app)
    }
}

// MARK: - Private Method

private extension OrdersListTests {

    /// 切到訂單分頁並等清單就緒，回傳訂單清單 Page Object
    ///
    /// - Parameters:
    ///   - app: 受測 App
    ///   - file: 失敗時回報的來源檔案
    ///   - line: 失敗時回報的來源行號
    /// - Returns: 已就緒的訂單清單 Page Object
    func openOrdersList(
        _ app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> OrdersScreen {
        let root = RootNavigationScreen(app: app)
        if !root.goToOrders(file: file, line: line) {
            failWithDiagnostics(
                in: app,
                "切到訂單分頁後畫面未就緒",
                file: file,
                line: line
            )
        }

        let orders = OrdersScreen(app: app)
        if !orders.waitUntilReady() {
            failWithDiagnostics(
                in: app,
                "訂單清單根 identifier「\(orders.rootIdentifier)」逾時仍未出現",
                file: file,
                line: line
            )
        }
        return orders
    }

    /// 確認導覽列標題恢復顯示，且搜尋欄回到搜尋前的位置
    ///
    /// - Parameters:
    ///   - originalMinY: 搜尋前搜尋欄的上緣位置
    ///   - app: 受測 App
    ///   - file: 失敗時回報的來源檔案
    ///   - line: 失敗時回報的來源行號
    /// - Throws: 逾時仍未恢復時丟出測試錯誤
    func assertSearchRestored(
        to originalMinY: CGFloat,
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let title = app.navigationBars["訂單"].staticTexts["訂單"]
        let isRestored = pollUntil(timeout: 5) {
            let fields = app.searchFields.allElementsBoundByIndex
            guard let field = fields.first(where: \.isHittableOnScreen) else {
                return false
            }
            return title.isHittableOnScreen && abs(field.frame.minY - originalMinY) <= 1
        }
        try requireCondition(
            isRestored,
            in: app,
            "關閉搜尋後標題應恢復、搜尋欄應回到 y = \(originalMinY)",
            file: file,
            line: line
        )
    }
}
