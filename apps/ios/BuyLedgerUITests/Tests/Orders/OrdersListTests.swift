//
//  OrdersListTests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 訂單清單的瀏覽、狀態篩選、搜尋與空狀態流程測試
final class OrdersListTests: BLUITestCase {

    // MARK: - Static Properties

    /// confirmed 狀態的 filterID
    private static let confirmedFilterID = "confirmed"

    /// fullOrders 中唯一的「已確認」訂單編號
    private static let confirmedOrderID = "BL-2604-014"

    /// fullOrders 中狀態為「集運中」的訂單編號 (非已確認，供篩選排除斷言)
    private static let shippingOrderID = "BL-2604-018"

    /// fullOrders 中客戶為「林書宇」的兩筆訂單編號 (集運中與已交付各一)
    private static let linCustomerOrderIDs = ["BL-2604-018", "BL-2604-012"]

    /// fullOrders 中客戶為「Mika 周」的訂單編號 (供搜尋排除斷言)
    private static let mikaCustomerOrderID = "BL-2604-017"

    // MARK: - Tests

    /// 切到訂單分頁後清單就緒，且看得到既知的種子訂單
    @MainActor
    func testOrdersListReadyWithFullSeed() {
        let app = launch(LaunchOptions(seed: .fullOrders))
        let orders = openOrdersList(app)

        if !orders.hasOrder(orderID: Self.shippingOrderID) {
            failWithDiagnostics(in: app, "fullOrders 清單未見既知訂單「\(Self.shippingOrderID)」")
        }
    }

    /// 選某狀態後，屬該狀態的訂單列在、不屬該狀態的訂單列不在
    @MainActor
    func testStatusChipFiltersOutOtherStatuses() {
        let app = launch(LaunchOptions(seed: .fullOrders))
        let orders = openOrdersList(app)

        orders.selectStatusChip(filterID: Self.confirmedFilterID)

        // 屬「已確認」的訂單應留在清單
        if !orders.hasOrder(orderID: Self.confirmedOrderID) {
            failWithDiagnostics(
                in: app,
                "選「已確認」後，該狀態的訂單「\(Self.confirmedOrderID)」不在清單"
            )
        }
        // 「集運中」的訂單應被篩掉
        if !orders.orderRow(orderID: Self.shippingOrderID).waitForDisappearance() {
            failWithDiagnostics(
                in: app,
                "選「已確認」後，集運中訂單「\(Self.shippingOrderID)」仍留在清單"
            )
        }
    }

    /// 輸入某客戶名後，只剩該客戶的訂單列 (斷言以訂單列 identifier 為準)
    @MainActor
    func testSearchByCustomerNameKeepsOnlyThatCustomer() {
        let app = launch(LaunchOptions(seed: .fullOrders))
        let orders = openOrdersList(app)

        // 客戶名屬使用者資料、可作為文字輸入；斷言仍走訂單列 identifier
        orders.search("林書宇")

        for orderID in Self.linCustomerOrderIDs where !orders.hasOrder(orderID: orderID) {
            failWithDiagnostics(in: app, "搜尋「林書宇」後，其訂單「\(orderID)」不在清單")
        }
        if !orders.orderRow(orderID: Self.mikaCustomerOrderID).waitForDisappearance() {
            failWithDiagnostics(
                in: app,
                "搜尋「林書宇」後，他人訂單「\(Self.mikaCustomerOrderID)」仍留在清單"
            )
        }
    }

    /// 搜尋不存在的關鍵字時，清單顯示空狀態
    @MainActor
    func testSearchWithNoMatchShowsEmptyState() {
        let app = launch(LaunchOptions(seed: .fullOrders))
        let orders = openOrdersList(app)

        orders.search("ZZZ-NO-SUCH-ORDER")

        assertEmptyState(BLAccessibilityID.Orders.listEmptyState, in: app)
    }
}

// MARK: - Private Method

private extension OrdersListTests {

    /// 切到訂單分頁並等清單就緒，回傳訂單清單 Page Object
    /// - Parameters:
    ///   - app: 受測 App
    ///   - file: 失敗時回報的來源檔案
    ///   - line: 失敗時回報的來源行號
    /// - Returns: 已就緒的訂單清單 Page Object
    @MainActor
    func openOrdersList(
        _ app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> OrdersScreen {
        let root = RootNavigationScreen(app: app)
        if !root.goToOrders() {
            failWithDiagnostics(in: app, "切到訂單分頁後畫面未就緒", file: file, line: line)
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
}
