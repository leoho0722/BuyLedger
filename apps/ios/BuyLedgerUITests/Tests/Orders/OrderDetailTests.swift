//
//  OrderDetailTests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 訂單詳情的進入、財務摘要與刪除流程測試
final class OrderDetailTests: BLUITestCase {

    // MARK: - Static Properties

    /// fullOrders 中用於詳情測試的訂單編號
    private static let sampleOrderID = "BL-2604-018"

    /// 詳情財務摘要卡的三個種類
    private static let summaryTiles: [BLAccessibilityID.Orders.SummaryTile] = [
        .revenue, .cost, .profit,
    ]

    // MARK: - Tests

    /// 從清單點一筆訂單進詳情，詳情根就緒
    @MainActor
    func testTapOrderOpensDetail() {
        let app = launch(LaunchOptions(seed: .fullOrders))
        let detail = openOrderDetail(app)

        _ = detail
    }

    /// 詳情財務摘要卡三個數值可各自讀到且非空
    @MainActor
    func testDetailSummaryTilesHaveValues() {
        let app = launch(LaunchOptions(seed: .fullOrders))
        let detail = openOrderDetail(app)

        for tile in Self.summaryTiles where detail.summaryValue(tile).isEmpty {
            failWithDiagnostics(
                in: app,
                "財務摘要卡「\(tile.rawValue)」的 accessibility value 為空"
            )
        }
    }

    /// 刪除流程：更多 → 刪除 → 確認 alert → 取消；alert 收回且訂單未被刪除
    @MainActor
    func testDeleteFlowCancelKeepsOrder() {
        let app = launch(LaunchOptions(seed: .fullOrders))
        let detail = openOrderDetail(app)

        detail.openMoreMenu()
        if !detail.tapDelete() {
            failWithDiagnostics(in: app, "更多選單的刪除項目未出現或不可點")
        }

        if !detail.deleteConfirmationExists() {
            failWithDiagnostics(in: app, "點刪除後，刪除確認 alert 未呈現")
        }

        detail.cancelDelete()

        // 取消後 alert 應收回，且訂單未被刪除、詳情仍停留
        if !detail.deleteConfirmationDismissed() {
            failWithDiagnostics(in: app, "點取消後，刪除確認 alert 未收回")
        }
        if !detail.waitUntilReady() {
            failWithDiagnostics(in: app, "取消刪除後詳情頁應仍停留，根 identifier 卻消失")
        }
    }
}

// MARK: - Private Method

private extension OrderDetailTests {

    /// 切到訂單分頁、點種子訂單進詳情並等就緒，回傳詳情 Page Object
    /// - Parameters:
    ///   - app: 受測 App
    ///   - file: 失敗時回報的來源檔案
    ///   - line: 失敗時回報的來源行號
    /// - Returns: 已就緒的訂單詳情 Page Object
    @MainActor
    func openOrderDetail(
        _ app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> OrderDetailScreen {
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

        orders.tapOrder(orderID: Self.sampleOrderID)

        let detail = OrderDetailScreen(app: app)
        if !detail.waitUntilReady() {
            failWithDiagnostics(
                in: app,
                "點訂單「\(Self.sampleOrderID)」後詳情根 identifier「\(detail.rootIdentifier)」逾時仍未出現",
                file: file,
                line: line
            )
        }
        return detail
    }
}
