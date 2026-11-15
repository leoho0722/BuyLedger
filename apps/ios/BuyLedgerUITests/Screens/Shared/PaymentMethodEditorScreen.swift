//
//  PaymentMethodEditorScreen.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/10/17.
//

import XCTest

/// 付款方式編輯器 (`PaymentMethodEditorSheet`) 的 Page Object
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
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    func typeName(
        _ name: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        let field = app.textFields[BLAccessibilityID.LookupManagement.paymentMethodNameField]
        try field.clearAndType(
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
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    func tapSave(file: StaticString = #filePath, line: UInt = #line) throws(UITestError) {
        let button = app.buttons[BLAccessibilityID.LookupManagement.paymentMethodSaveButton]
        try button.tapAfterWaiting(in: app, file: file, line: line)
    }

    /// 貨到付款開關目前是否為開啟狀態；開關不存在時為 `false`
    var isCashOnDeliveryOn: Bool {
        let toggle = cashOnDeliveryToggle
        return toggle.exists && (toggle.value as? String) == "1"
    }

    /// 將貨到付款開關捲入可點範圍
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 開關無法捲入可點範圍時丟出測試錯誤
    func revealCashOnDeliveryToggle(
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        let toggle = cashOnDeliveryToggle
        if toggle.waitUntilHittable() {
            return
        }
        try app.scrollToHittable(toggle, within: rootElement, file: file, line: line)
    }

    /// 點付款方式表單內的貨到付款開關並等待值翻轉
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 開關值無法讀取、無法點擊或點擊後未翻轉時丟出測試錯誤
    func toggleCashOnDelivery(
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        let toggle = cashOnDeliveryToggle
        try revealCashOnDeliveryToggle(file: file, line: line)
        guard let previousValue = toggle.value as? String else {
            try app.stopWithDiagnostics("貨到付款開關目前沒有可讀取的值", file: file, line: line)
        }
        try toggle.switches.firstMatch.tapAfterWaiting(in: app, file: file, line: line)
        guard Polling.wait(timeout: 5, until: { (toggle.value as? String) != previousValue }) else {
            try app.stopWithDiagnostics("點擊後貨到付款開關值未翻轉", file: file, line: line)
        }
    }
}

// MARK: - ScreenProtocol

extension PaymentMethodEditorScreen: ScreenProtocol {

    /// 判定編輯器已就緒的根 identifier (表單容器)
    var rootIdentifier: String {
        BLAccessibilityID.LookupManagement.paymentMethodEditorRoot
    }
}

// MARK: - Private Method

@MainActor
private extension PaymentMethodEditorScreen {

    /// 付款方式編輯表單中的貨到付款開關
    var cashOnDeliveryToggle: XCUIElement {
        app.switches[BLAccessibilityID.LookupManagement.paymentMethodCashOnDeliveryToggle]
    }
}
