//
//  OrdersUITests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import CoreGraphics
import XCTest

/// 訂單清單的狀態篩選、搜尋與空狀態流程 UI 測試
@MainActor
final class OrdersUITests: BLUITestCase {

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
    private static let compactSearchScopeReason =
        "只適用窄版清單，並排清單欄由 OrdersRegularSearchBarUITests 覆蓋"

    /// 驗證在完整訂單集合選「已確認」狀態膠囊後，已確認的訂單留在清單，集運中的訂單被篩掉
    ///
    /// - Throws: 訂單清單未就緒、篩選前置條件不成立或找不到狀態膠囊時丟出測試錯誤
    func testStatusFilterSelected_選已確認_留下已確認訂單並篩掉集運中訂單() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .fullOrders))
        let orders = try OrdersScreen.open(in: app)
        try requireCondition(
            orders.hasOrder(orderID: Self.shippingOrderID),
            in: app,
            "篩選前置條件未成立：\(Self.shippingOrderID)"
        )

        // When
        try orders.selectStatusChip(filterID: Self.confirmedFilterID)

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

    /// 驗證在完整訂單集合搜尋「林書宇」後，該客戶的兩筆訂單留在清單，「Mika 周」的訂單被篩掉
    ///
    /// - Throws: 訂單清單未就緒、搜尋前置條件不成立或找不到可互動的搜尋欄時丟出測試錯誤
    func testSearchTextChanged_輸入客戶名稱_留下該客戶訂單並篩掉他人訂單() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .fullOrders))
        let orders = try OrdersScreen.open(in: app)
        try requireCondition(
            orders.hasOrder(orderID: Self.mikaCustomerOrderID),
            in: app,
            "搜尋前置條件未成立：\(Self.mikaCustomerOrderID)"
        )

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
    func testTapSearchEndButton_窄版輸入後關閉搜尋_標題恢復且搜尋欄回到原位() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .fullOrders))
        let orders = try OrdersScreen.open(in: app)
        try XCTSkipUnless(try ordersLayout(in: app) == .compact, Self.compactSearchScopeReason)
        let originalMinY = try app.hittableSearchField().frame.minY
        try orders.search("林書宇")

        // When
        try app.tapSearchEndButton()

        // Then
        try assertSearchRestored(to: originalMinY, in: app)
    }

    /// 驗證窄版搜尋按 Return 收鍵盤後再按關閉，導覽列標題恢復顯示，搜尋欄回到搜尋前的位置 (誤差 1 點內)
    ///
    /// - Throws: 版面不適用、必要元素缺少、未收起鍵盤或標題與位置未恢復時丟出測試錯誤
    func testTapSearchEndButton_窄版收鍵盤後關閉搜尋_標題恢復且搜尋欄回到原位() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .fullOrders))
        let orders = try OrdersScreen.open(in: app)
        try XCTSkipUnless(try ordersLayout(in: app) == .compact, Self.compactSearchScopeReason)
        let originalMinY = try app.hittableSearchField().frame.minY
        try orders.search("林書宇")
        let field = try app.hittableSearchField()
        try app.dismissSearchKeyboard(in: field)

        // When
        try app.tapSearchEndButton()

        // Then
        try assertSearchRestored(to: originalMinY, in: app)
    }

    /// 驗證窄版搜尋點清除鈕清空文字後再按關閉，導覽列標題恢復顯示，搜尋欄回到搜尋前的位置 (誤差 1 點內)
    ///
    /// - Throws: 版面不適用、必要元素缺少、文字未清除或標題與位置未恢復時丟出測試錯誤
    func testTapSearchEndButton_窄版清除文字後關閉搜尋_標題恢復且搜尋欄回到原位() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .fullOrders))
        let orders = try OrdersScreen.open(in: app)
        try XCTSkipUnless(try ordersLayout(in: app) == .compact, Self.compactSearchScopeReason)
        let originalMinY = try app.hittableSearchField().frame.minY
        try orders.search("林書宇")
        let field = try app.hittableSearchField()
        try app.clearSearchText()
        try requireCondition(
            Polling.wait(timeout: 3) { field.value as? String != "林書宇" },
            in: app,
            "點清除鈕後搜尋欄仍有文字"
        )

        // When
        try app.tapSearchEndButton()

        // Then
        try assertSearchRestored(to: originalMinY, in: app)
    }

    /// 驗證搜尋不存在的關鍵字「ZZZ-NO-SUCH-ORDER」時，清單顯示空狀態
    ///
    /// - Throws: 訂單清單未就緒、找不到可互動的搜尋欄或空狀態逾時未出現時丟出測試錯誤
    func testSearchTextChanged_沒有符合的訂單_顯示空狀態() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .fullOrders))
        let orders = try OrdersScreen.open(in: app)

        // When
        try orders.search("ZZZ-NO-SUCH-ORDER")

        // Then
        try assertEmptyState(BLAccessibilityID.Orders.listEmptyState, in: app)
    }
}

// MARK: - Private Method

private extension OrdersUITests {

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
    ) throws(UITestError) {
        let isRestored = Polling.wait(timeout: 5) {
            guard let field = app.firstHittableSearchField else {
                return false
            }
            return app.isNavigationBarTitleVisible("訂單")
                && abs(field.frame.minY - originalMinY) <= 1
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
