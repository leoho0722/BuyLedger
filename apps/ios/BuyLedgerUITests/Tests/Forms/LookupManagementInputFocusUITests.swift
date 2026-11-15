//
//  LookupManagementInputFocusUITests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/11/15.
//

import XCTest

/// 主檔與付款方式名稱重新聚焦後文字接續的 UI 測試
@MainActor
final class LookupManagementInputFocusUITests: BLUITestCase {

    /// 驗證分類名稱「服飾」失焦後從左側重新聚焦輸入「類」，欄位值為「服飾類」，游標在名稱尾端
    ///
    /// - Throws: 必要的 UI 操作或前置條件失敗時丟出 UITestError.stopped
    func testTapLeftToFocus_既有主檔名稱接續輸入_新增文字接在尾端() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .lookupsOnly))
        let management = try LookupManagementScreen.open(.categories, in: app)
        try management.beginRename(from: "服飾")
        try requireCondition(
            management.nameFieldValue() == "服飾",
            in: app,
            "前置主檔名稱應符合種子 (實際：\(String(describing: management.nameFieldValue())))"
        )
        try management.dismissKeyboard(for: management.nameField)
        try requireCondition(!management.isNameFieldFocused(), in: app, "點左側前名稱欄應已失焦")
        try requireCondition(
            management.nameFieldValue() == "服飾",
            in: app,
            "失焦不應改動原文 (實際：\(String(describing: management.nameFieldValue())))"
        )

        // When
        try management.nameField.tapLeftToFocus(in: app)
        management.nameField.typeText("類")

        // Then
        _ = Polling.wait(timeout: 3) {
            management.nameField.value as? String == "服飾類"
        }
        XCTAssertEqual(management.nameField.value as? String, "服飾類", "新增文字應接在主檔名稱尾端")
    }

    /// 驗證付款方式「信用卡」失焦後從左側重新聚焦輸入「新」，欄位值為「信用卡新」，游標在名稱尾端
    ///
    /// - Throws: 必要的 UI 操作或前置條件失敗時丟出 UITestError.stopped
    func testTapLeftToFocus_既有付款方式接續輸入_新增文字接在尾端() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .lookupsOnly))
        let management = try LookupManagementScreen.open(.paymentMethods, in: app)
        try management.beginEditPaymentMethod(named: "信用卡")
        let field = management.paymentMethodNameField
        try requireCondition(
            field.value as? String == "信用卡",
            in: app,
            "前置付款方式名稱應符合種子 (實際：\(String(describing: field.value as? String)))"
        )
        try management.dismissKeyboard(for: field)
        try requireCondition(!field.hasKeyboardFocus, in: app, "點左側前付款方式名稱欄應已失焦")
        try requireCondition(
            field.value as? String == "信用卡",
            in: app,
            "失焦不應改動原文 (實際：\(String(describing: field.value as? String)))"
        )

        // When
        try field.tapLeftToFocus(in: app)
        field.typeText("新")

        // Then
        _ = Polling.wait(timeout: 3) {
            field.value as? String == "信用卡新"
        }
        XCTAssertEqual(field.value as? String, "信用卡新", "新增文字應接在付款方式名稱尾端")
    }
}
