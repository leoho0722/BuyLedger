//
//  OrderEditRotationUITests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/11/15.
//

import XCTest

/// 訂單編輯表單在裝置轉向往返時，草稿、鍵盤焦點與單一表單 sheet 保留的 UI 測試
@MainActor
final class OrderEditRotationUITests: BLUITestCase {

    /// 驗證編輯草稿「DuoDraft」與鍵盤焦點在橫向與直向往返後保留，轉向後接續輸入落在同一欄位，且只有一層表單 sheet
    ///
    /// - Throws: 表單、草稿、鍵盤、轉向或 Orders path 不符合預期時丟出測試錯誤
    /// - Note: 轉回直向後確認 Orders path 仍是 BL-2604-017，最後點取消時呈現既有的捨棄確認
    func testDraft_編輯草稿與焦點轉向往返_保留草稿焦點與單一Sheet() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .fullOrders))
        let orders = try OrdersScreen.open(in: app)
        let detail = try orders.tapOrder(orderID: "BL-2604-017")
        let edit = try detail.openEdit()
        try edit.typeCustomerName("DuoDraft")
        let customerField = edit.customerField
        let keyboard = app.keyboards.firstMatch
        try requireCondition(keyboard.waitForExistence(timeout: 10), in: app, "客戶欄位鍵盤未出現")
        try requireCondition(edit.customerValue == "DuoDraft", in: app, "編輯草稿初始值非預期")

        // When
        try rotateToLandscape(app)

        // Then
        try assertSingleEditSheet(
            edit,
            customerField: customerField,
            expectedDraft: "DuoDraft",
            in: app
        )
        try requireCondition(keyboard.waitForExistence(timeout: 10), in: app, "轉向後編輯表單鍵盤未保留")

        // When
        try customerField.appendText("X", in: app)

        // Then
        try requireCondition(
            edit.customerValue == "DuoDraftX",
            in: app,
            "轉向後客戶欄位未保留焦點並接續輸入"
        )

        // When
        try rotateToPortrait(app)

        // Then
        try assertSingleEditSheet(
            edit,
            customerField: customerField,
            expectedDraft: "DuoDraftX",
            in: app
        )
        try requireCondition(keyboard.waitForExistence(timeout: 10), in: app, "轉回直向後編輯表單鍵盤未保留")
        let selectedOrderID = try requireValue(
            orders.pathProjectedOrderID(),
            in: app,
            "方向改變後 Orders path 標記不存在"
        )
        try requireCondition(
            selectedOrderID == "BL-2604-017",
            in: app,
            "方向改變後 Orders path 選取不應改變"
        )

        // When
        try edit.tapCancel()

        // Then
        try requireCondition(
            app.alertPresented(timeout: 10),
            in: app,
            "取消修改草稿後未顯示既有捨棄確認"
        )
    }
}
