//
//  OrderEditScreen.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 訂單編輯表單的 Page Object
struct OrderEditScreen: Screen {

    // MARK: - Data Properties

    /// 受測 App
    let app: XCUIApplication

    // MARK: - Computed Properties

    /// 判定編輯表單已就緒的根 identifier (表單捲動容器)
    ///
    /// - Returns: 編輯表單的根 identifier
    var rootIdentifier: String {
        BLAccessibilityID.OrderEdit.root
    }
}

// MARK: - Internal Method

@MainActor
extension OrderEditScreen {

    /// 儲存按鈕目前是否可用
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 儲存按鈕是否可用
    func isSaveEnabled(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Bool {
        let button = app.buttons[BLAccessibilityID.OrderEdit.saveButton]
        if !button.waitForExistence(timeout: 10) {
            let saveButtonID = BLAccessibilityID.OrderEdit.saveButton
            app.failWithDiagnostics(
                "找不到 identifier 為 \(saveButtonID) 的儲存按鈕",
                file: file,
                line: line
            )
            return false
        }

        return button.isEnabled
    }

    /// 清空並填入客戶名稱
    ///
    /// - Parameters:
    ///   - name: 要填入的客戶名稱
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func typeCustomerName(
        _ name: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let field = app.textFields[BLAccessibilityID.OrderEdit.customerField]
        var scrollAttempts = 0
        while scrollAttempts < 8 {
            if !field.exists {
                rootElement.swipeDown()
                scrollAttempts += 1
                continue
            }
            let fieldFrame = field.frame
            if !fieldFrame.isEmpty && rootElement.frame.intersects(fieldFrame) {
                break
            }
            rootElement.swipeDown()
            scrollAttempts += 1
        }
        guard field.exists else {
            app.failWithDiagnostics(
                "捲動 8 次後仍找不到客戶名稱欄位",
                file: file,
                line: line
            )
            return
        }
        field.clearAndType(
            name,
            in: app,
            file: file,
            line: line
        )
    }

    /// 送出文字欄位的 return，驗證一般鍵盤的收起路徑
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func submitCustomerName(file: StaticString = #filePath, line: UInt = #line) {
        let field = app.textFields[BLAccessibilityID.OrderEdit.customerField]
        field.tapAfterWaiting(in: app, file: file, line: line)
        field.typeText(XCUIKeyboardKey.return.rawValue)
    }

    /// 開啟訂單來源選擇器
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func openSourcePicker(file: StaticString = #filePath, line: UInt = #line) {
        tapPickerRow(BLAccessibilityID.OrderEdit.sourceRow, file: file, line: line)
    }

    /// 開啟商品類別選擇器
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func openCategoryPicker(file: StaticString = #filePath, line: UInt = #line) {
        tapPickerRow(BLAccessibilityID.OrderEdit.categoryRow, file: file, line: line)
    }

    /// 開啟付款方式選擇器
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func openPaymentPicker(file: StaticString = #filePath, line: UInt = #line) {
        tapPickerRow(BLAccessibilityID.OrderEdit.paymentRow, file: file, line: line)
    }

    /// 填入客戶實付金額
    ///
    /// - Parameters:
    ///   - amount: 要填入的金額文字
    ///   - app: 受測 App
    ///   - dismissKeyboard: 是否在輸入後收起數字鍵盤
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func typeChargedAmount(
        _ amount: String,
        in app: XCUIApplication,
        dismissKeyboard: Bool = true,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let field = app.textFields[BLAccessibilityID.OrderEdit.chargedAmountField]
        // 使用預設拖曳範圍，避免 iPhone 找不到可點擊位置
        if !app.scrollToHittableGently(field, within: rootElement) {
            // XCTest 的第一次點擊會觸發原生 scroll-to-focus
            // 之後再交給共用輸入 helper
            field.tap()
        }
        guard field.waitUntilHittableOrFail(
            in: app,
            timeout: 10,
            file: file,
            line: line
        ) else {
            return
        }
        field.clearAndType(
            amount,
            in: app,
            file: file,
            line: line
        )
        if dismissKeyboard {
            field.dismissNumericKeyboard(in: app, file: file, line: line)
        }
    }

    /// 點數字鍵盤工具列的完成鍵
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func tapNumericKeyboardDone(
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let field = app.textFields[BLAccessibilityID.OrderEdit.chargedAmountField]
        field.dismissNumericKeyboard(in: app, file: file, line: line)
    }

    /// 捲到照片區並點指定序位的照片縮圖，開啟照片檢視器
    ///
    /// - Parameters:
    ///   - index: 照片縮圖的序位
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func tapPhotoThumbnail(
        index: Int,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let thumbnail = app.descendants(matching: .any)[
            BLAccessibilityID.OrderEdit.photoThumbnail(index: index)
        ]
        var attempts = 0
        while !thumbnail.exists, attempts < 8 {
            rootElement.swipeUp()
            attempts += 1
        }
        app.scrollToHittable(thumbnail, within: rootElement)
        thumbnail.tapAfterWaiting(in: app, file: file, line: line)
    }

    /// 點工具列的儲存
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func tapSave(file: StaticString = #filePath, line: UInt = #line) {
        let button = app.buttons[BLAccessibilityID.OrderEdit.saveButton]
        button.tapAfterWaiting(in: app, file: file, line: line)
    }

    /// 點工具列的取消
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func tapCancel(file: StaticString = #filePath, line: UInt = #line) {
        let button = app.buttons[BLAccessibilityID.OrderEdit.cancelButton]
        button.tapAfterWaiting(in: app, file: file, line: line)
    }
}

// MARK: - Private Method

@MainActor
private extension OrderEditScreen {

    /// 點某個選擇器入口列開啟選擇器
    ///
    /// - Parameters:
    ///   - identifier: 選擇器入口列的 accessibility identifier
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func tapPickerRow(
        _ identifier: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let row = app.descendants(matching: .any)[identifier]
        if !row.isHittable {
            app.scrollToHittable(row, within: rootElement)
        }
        row.tapAfterWaiting(in: app, file: file, line: line)
    }
}
