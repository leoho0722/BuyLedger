//
//  OrderEditRenamedCategoryUITests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/11/15.
//

import XCTest

/// 商品類別改名後新增訂單的類別選擇器只列出新名稱的 UI 測試
@MainActor
final class OrderEditRenamedCategoryUITests: BLUITestCase {

    /// 驗證商品類別「服飾」改名為「衣著」後，新增訂單的類別選擇器只列出「衣著」，不含「服飾」
    ///
    /// - Throws: 改名未完成，或訂單清單、新增訂單表單、類別選擇器未就緒時丟出測試錯誤
    /// - Note: 同次改名的結果須在新增訂單選擇器中讀回，確認名稱已同步且舊名未殘留
    func testCategoryPickerTapped_商品類別改名後_新訂單選擇器只顯示新名稱() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .minimalOrders))
        let lookupManagement = try LookupManagementScreen.open(.categories, in: app)
        try lookupManagement.renameItem(from: "服飾", to: "衣著")
        try requireCondition(
            lookupManagement.itemRow(named: "衣著").waitForExistence(timeout: 10),
            in: app,
            "改名後商品類別清單未出現「衣著」"
        )
        let orders = try OrdersScreen.open(in: app)
        try requireCondition(orders.waitUntilReady(), in: app, "訂單清單未出現")
        let orderEdit = try orders.tapAddOrder()

        // When
        let picker = try orderEdit.openCategoryPicker()

        // Then
        if !picker.hasOption("衣著") {
            failWithDiagnostics(in: app, "新訂單類別選擇器未出現「衣著」")
        }
        XCTAssertFalse(picker.hasOption("服飾", timeout: 0), "新訂單類別選擇器不應包含舊名稱「服飾」")
    }
}
