//
//  PaymentMethodEditorScreen.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/10/17.
//

import XCTest

/// 付款方式編輯器 (``PaymentMethodEditorSheet``) 的 Page Object
struct PaymentMethodEditorScreen {

    // MARK: - Properties

    /// 受測 App
    let app: XCUIApplication
}

// MARK: - Internal Method

@MainActor
extension PaymentMethodEditorScreen {

    /// 清空並填入付款方式名稱
    ///
    /// - Parameters:
    ///   - name: 要填入的付款方式名稱
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func typeName(_ name: String, file: StaticString = #filePath, line: UInt = #line) {
        let field = app.textFields[BLAccessibilityID.LookupManagement.paymentMethodNameField]
        field.clearAndType(
            name,
            in: app,
            file: file,
            line: line
        )
    }

    /// 點工具列的儲存按鈕
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func tapSave(file: StaticString = #filePath, line: UInt = #line) {
        let button = app.buttons[BLAccessibilityID.LookupManagement.paymentMethodSaveButton]
        button.tapAfterWaiting(in: app, file: file, line: line)
    }
}

// MARK: - Screen

extension PaymentMethodEditorScreen: Screen {

    /// 判定編輯器已就緒的根 identifier (表單容器)
    var rootIdentifier: String {
        BLAccessibilityID.LookupManagement.paymentMethodEditorRoot
    }
}
