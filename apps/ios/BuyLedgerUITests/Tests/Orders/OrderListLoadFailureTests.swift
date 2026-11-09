//
//  OrderListLoadFailureTests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/11/9.
//

import XCTest

/// 訂單清單載入失敗時的失敗訊息、重試鍵與重試後狀態的 UI 測試
@MainActor
final class OrderListLoadFailureTests: BLUITestCase {

    /// 驗證訂單每次讀取皆延遲後失敗時，清單顯示失敗訊息與重試鍵且不顯示空狀態，按下重試後重新讀取並再次穩定停在失敗畫面
    ///
    /// - Throws: 訂單分頁、失敗畫面或重試鍵未就緒時丟出測試錯誤
    /// - Note: 失敗發生在啟動讀取的延遲之後，所以啟動後盡快切到訂單分頁，才能穩定停在「失敗加空狀態」的修改前狀態
    func testRetryTapped_訂單每次讀取皆失敗_顯示失敗與重試鍵且不顯示空狀態() throws {
        // Given
        let app = launch(LaunchOptions(loadFailure: .ordersDelayed))
        let failure = app.descendants(matching: .any)[BLAccessibilityID.Orders.listLoadFailure]
        let emptyState = app.descendants(matching: .any)[BLAccessibilityID.Orders.listEmptyState]
        let loading = app.descendants(matching: .any)[BLAccessibilityID.Orders.listLoading]
        let retry = app.buttons[BLAccessibilityID.Orders.listLoadFailureRetryButton]

        // When
        AppNavigator(app: app).selectTab(.orders)

        // Then
        try requireCondition(failure.waitForExistence(timeout: 15), in: app, "訂單讀取失敗後清單未顯示載入失敗訊息")
        XCTAssertFalse(emptyState.exists, "訂單載入失敗時仍顯示沒有符合的訂單空狀態")
        try requireCondition(retry.waitUntilHittable(), in: app, "訂單載入失敗畫面沒有可點的重試鍵")

        // When
        retry.tapAfterWaiting(in: app)

        // Then
        XCTAssertTrue(loading.waitForExistence(timeout: 2), "按下重試後未重新讀取訂單，清單沒有顯示載入中")
        assertLoadStateStaysStable(
            in: app,
            waitingFor: BLAccessibilityID.Orders.listLoadFailure,
            present: [BLAccessibilityID.Orders.listLoadFailureRetryButton],
            absent: [BLAccessibilityID.Orders.listLoading, BLAccessibilityID.Orders.listEmptyState],
            context: "重試後再次失敗的訂單清單"
        )
    }
}
