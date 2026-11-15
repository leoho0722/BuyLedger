//
//  OrderEditAddOptionUITests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/10/17.
//

import XCTest

/// 訂單編輯表單新增來源與付款方式的 UI 測試
@MainActor
final class OrderEditAddOptionUITests: BLUITestCase {

    // MARK: - Properties

    /// 新增的訂單來源名稱，以英文避免輸入法影響輸入
    private static let newOrderSource = "Pinkoi"

    /// 新增的付款方式名稱，以英文避免輸入法影響輸入
    private static let newPaymentMethod = "JKO Pay"

    /// 驗證從訂單來源選擇器新增 Pinkoi 後，選擇器關閉且表單選取新增的來源
    ///
    /// - Throws: 必要的 UI 操作或新增來源前置不成立時丟出 UITestError.stopped
    func testAddOrderSourceTapped_從訂單來源選擇器輸入名稱新增_關閉選擇器並選取新來源() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .lookupsOnly))
        let edit = try OrdersScreen.open(in: app).tapAddOrder()
        try edit.submitCustomerName()
        let picker = try edit.openSourcePicker()
        try picker.tapAdd()
        try picker.typeNewOptionName(Self.newOrderSource)

        // When
        try picker.confirmAdd()

        // Then
        XCTAssertTrue(picker.rootElement.waitForDisappearance(), "送出後訂單來源選擇器未關閉")
        XCTAssertTrue(edit.waitUntilReady(), "送出後訂單表單未就緒，表單可能被關閉")
        XCTAssertTrue(edit.waitForSourceLabel(containing: Self.newOrderSource), "訂單表單的訂單來源未選取新增的項目")
    }

    /// 驗證新增 JKO Pay 後付款方式選擇器列出該項，返回時表單仍保留並選取新增項目
    ///
    /// - Throws: 必要的 UI 操作或返回選擇器的前置不成立時丟出 UITestError.stopped
    func testAddPaymentMethodTapped_從付款方式選擇器新增_回到選擇器且表單保留() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .lookupsOnly))
        let edit = try OrdersScreen.open(in: app).tapAddOrder()
        try edit.submitCustomerName()
        let picker = try edit.openPaymentPicker()
        let editor = try picker.tapAddPaymentMethod()
        try editor.typeName(Self.newPaymentMethod)

        // When
        try editor.tapSave()
        try requireCondition(editor.rootElement.waitForDisappearance(), in: app, "送出後付款方式編輯器未收起")
        try requireCondition(picker.waitUntilReady(), in: app, "送出後沒有回到付款方式選擇器")
        let hasNewPaymentMethod = picker.hasOption(Self.newPaymentMethod)
        try picker.tapBack()

        // Then
        XCTAssertTrue(hasNewPaymentMethod, "新增的付款方式未出現在選擇器")
        XCTAssertTrue(edit.waitUntilReady(), "從選擇器返回後訂單表單未就緒")
        XCTAssertTrue(
            edit.waitForPaymentLabel(containing: Self.newPaymentMethod),
            "訂單表單的付款方式未選取新增的項目"
        )
    }
}
