//
//  OrderEditDraftRotationUITests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/11/15.
//

import XCTest

/// 新增訂單草稿在轉向後保留欄位焦點、文字與單一表單的 UI 測試
@MainActor
final class OrderEditDraftRotationUITests: BLUITestCase {

    /// 驗證新增訂單草稿旋轉後仍保留欄位焦點與文字，續輸入寫回同一欄位，且始終只有一張表單
    ///
    /// - Throws: 訂單清單、新增表單或旋轉後的草稿與 sheet 數量不符合預期時丟出測試錯誤
    /// - Note: 對應驗收矩陣 N6
    /// - Note: 編輯草稿、開團草稿與主檔草稿由既有案例覆蓋
    func testDraft_新增訂單草稿轉向後續打_同欄且單一sheet() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .fullOrders))
        let edit = try OrdersScreen.open(in: app).tapAddOrder()
        try edit.typeCustomerName("DuoDraft")
        let keyboard = app.keyboards.firstMatch
        try requireCondition(keyboard.waitForExistence(timeout: 10), in: app, "客戶欄位鍵盤未出現")
        try requireCondition(edit.customerValue == "DuoDraft", in: app, "新增草稿初始值非預期")

        // When
        try rotateToLandscape(app)

        // Then
        try assertSingleEditSheet(
            edit,
            customerField: edit.customerField,
            expectedDraft: "DuoDraft",
            in: app
        )
        try requireCondition(keyboard.waitForExistence(timeout: 10), in: app, "轉向後新增表單鍵盤未保留")

        // When
        try edit.customerField.appendText("X", in: app)

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
            customerField: edit.customerField,
            expectedDraft: "DuoDraftX",
            in: app
        )

        // When
        try edit.tapCancel()

        // Then
        try requireCondition(
            app.alertPresented(timeout: 10),
            in: app,
            "取消新增草稿後未顯示既有捨棄確認"
        )
    }
}
