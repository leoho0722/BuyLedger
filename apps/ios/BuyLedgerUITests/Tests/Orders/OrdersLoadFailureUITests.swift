//
//  OrdersLoadFailureUITests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/11/9.
//

import XCTest

/// 訂單清單載入失敗時的失敗訊息、重試鍵與重試後狀態的 UI 測試
@MainActor
final class OrdersLoadFailureUITests: BLUITestCase {

    /// 驗證訂單每次讀取皆延遲後失敗時，按下重試後重新讀取，清單再次穩定停在失敗訊息與重試鍵，不顯示空狀態
    ///
    /// - Throws: 訂單分頁、失敗畫面或重試鍵未就緒時丟出測試錯誤
    /// - Note: 失敗發生在啟動讀取的延遲之後，所以啟動後盡快切到訂單分頁，才能穩定停在「失敗加空狀態」的修改前狀態
    /// - Note: 等待失敗畫面的逾時由 `LaunchOptions.delayedReadFailureTimeout` 依延遲秒數推導
    func testRetryTapped_訂單每次讀取皆失敗_重新讀取後仍顯示失敗與重試鍵() throws {
        // Given
        let options = LaunchOptions(loadFailure: .ordersDelayed)
        let app = try launch(options)
        let orders = try OrdersScreen.open(in: app)
        try requireCondition(
            orders.waitForLoadFailure(timeout: options.delayedReadFailureTimeout),
            in: app,
            "訂單讀取失敗後清單未顯示載入失敗訊息"
        )
        try requireCondition(
            !orders.hasEmptyState(timeout: 0),
            in: app,
            "訂單載入失敗時仍顯示沒有符合的訂單空狀態"
        )

        // When
        try orders.tapRetry()

        // Then
        XCTAssertTrue(orders.waitForLoading(timeout: 2), "按下重試後未重新讀取訂單，清單沒有顯示載入中")
        try assertLoadStateStaysStable(
            in: app,
            waitingFor: BLAccessibilityID.Orders.listLoadFailure,
            present: [BLAccessibilityID.Orders.listLoadFailureRetryButton],
            absent: [BLAccessibilityID.Orders.listLoading, BLAccessibilityID.Orders.listEmptyState],
            context: "重試後再次失敗的訂單清單"
        )
    }
}
