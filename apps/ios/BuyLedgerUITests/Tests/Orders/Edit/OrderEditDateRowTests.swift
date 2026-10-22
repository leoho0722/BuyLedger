//
//  OrderEditDateRowTests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/10/17.
//

import XCTest

/// 訂單編輯基本資料區段的訂購日期列與頁尾時間戳，取代該區段的像素比對
final class OrderEditDateRowTests: BLUITestCase {

    // MARK: - Properties

    /// `minimalOrders` 中訂購日期為參考日當天的訂單
    private static let orderID = "UITEST-MIN-001"

    /// 參考時間 2026-04-30 00:00 (UTC) 當天的頁尾時間戳，UI 測試模式的行事曆時區為 UTC
    private static let expectedTimestamp = "訂購日期：2026/04/30 00:00:00"

    /// 編輯既有訂單時，訂購日期列存在，頁尾時間戳顯示訂單的訂購時間
    @MainActor
    func testOrderDateRow_編輯既有訂單_顯示日期列與頁尾時間戳() {
        // Given
        let app = launch(LaunchOptions(seed: .minimalOrders))
        let detail = openOrderDetail(in: app)
        let edit = OrderEditScreen(app: app)

        // When
        detail.openMoreMenu()
        if !detail.tapEdit() {
            failWithDiagnostics(in: app, "詳情更多選單的編輯入口未出現或不可點")
        }

        // Then
        if !edit.waitUntilReady() {
            failWithDiagnostics(in: app, "點編輯後訂單編輯表單未出現")
        }
        if !edit.orderDatePicker.waitForExistence(timeout: 10) {
            failWithDiagnostics(in: app, "訂單編輯表單的訂購日期列未出現")
        }
        let timestamp = edit.orderDateTimestamp
        if !timestamp.waitForExistence(timeout: 10) {
            failWithDiagnostics(in: app, "基本資料區段頁尾的訂購時間戳未出現")
        }
        XCTAssertEqual(timestamp.label, Self.expectedTimestamp)
    }
}

// MARK: - Private Method

private extension OrderEditDateRowTests {

    /// 切到訂單分頁並開啟種子訂單的詳情
    ///
    /// - Parameter app: 受測 App
    /// - Returns: 已就緒的訂單詳情 Page Object
    @MainActor
    func openOrderDetail(in app: XCUIApplication) -> OrderDetailScreen {
        let root = RootNavigationScreen(app: app)
        if !root.goToOrders() {
            failWithDiagnostics(in: app, "切到訂單分頁後畫面未就緒")
        }
        let orders = OrdersScreen(app: app)
        if !orders.waitUntilReady() {
            failWithDiagnostics(in: app, "訂單清單未就緒")
        }
        orders.tapOrder(orderID: Self.orderID)
        let detail = OrderDetailScreen(app: app)
        if !detail.waitUntilReady() {
            failWithDiagnostics(in: app, "訂單 \(Self.orderID) 的詳情未顯示")
        }
        return detail
    }
}
