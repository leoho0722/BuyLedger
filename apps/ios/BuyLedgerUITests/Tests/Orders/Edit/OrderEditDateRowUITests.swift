//
//  OrderEditDateRowUITests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/10/17.
//

import XCTest

/// 訂單編輯表單的訂購日期列與頁尾時間戳 UI 測試
@MainActor
final class OrderEditDateRowUITests: BLUITestCase {

    // MARK: - Properties

    /// 訂購日期為參考日當天的訂單編號，位於 `minimalOrders` 種子中
    private static let orderID = "UITEST-MIN-001"

    /// 參考時間 2026-04-30 00:00 (UTC) 當天的頁尾時間戳，UI 測試模式的行事曆時區為 UTC
    private static let expectedTimestamp = "訂購日期：2026/04/30 00:00:00"

    /// 驗證編輯既有訂單時有訂購日期列，頁尾時間戳為訂購日期：2026/04/30 00:00:00
    ///
    /// - Throws: 必要的 UI 操作或編輯表單未就緒時丟出 UITestError.stopped
    func testEditTapped_編輯既有訂單_顯示日期列與頁尾時間戳() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .minimalOrders))
        let detail = try OrdersScreen.open(in: app).tapOrder(orderID: Self.orderID)
        try detail.openMoreMenu()

        // When
        let edit = try detail.tapEdit()

        // Then
        XCTAssertTrue(edit.orderDatePicker.waitForExistence(timeout: 10), "訂單編輯表單的訂購日期列未出現")
        let timestamp = edit.orderDateTimestamp
        XCTAssertTrue(timestamp.waitForExistence(timeout: 10), "基本資料區段頁尾的訂購時間戳未出現")
        XCTAssertEqual(timestamp.label, Self.expectedTimestamp)
    }
}
