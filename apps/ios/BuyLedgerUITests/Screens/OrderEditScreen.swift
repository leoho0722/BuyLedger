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
    /// - Returns: 編輯表單的根 identifier
    var rootIdentifier: String {
        BLAccessibilityID.OrderEdit.root
    }

    /// 儲存按鈕目前是否可用
    /// - Returns: 儲存按鈕是否可用
    @MainActor
    var isSaveEnabled: Bool {
        let button = app.buttons[BLAccessibilityID.OrderEdit.saveButton]
        _ = button.waitForExistence(timeout: 10)

        return button.isEnabled
    }
}

// MARK: - Internal Method

@MainActor
extension OrderEditScreen {

    /// 清空並填入客戶名稱
    /// - Parameter name: 要填入的客戶名稱
    func typeCustomerName(_ name: String) {
        let field = app.textFields[BLAccessibilityID.OrderEdit.customerField]
        var scrollAttempts = 0
        while scrollAttempts < 8 {
            let fieldFrame = field.frame
            if !fieldFrame.isEmpty && rootElement.frame.intersects(fieldFrame) {
                break
            }
            rootElement.swipeDown()
            scrollAttempts += 1
        }
        guard field.waitForExistence(timeout: 5) else {
            return
        }
        field.clearAndType(name, in: app)
    }

    /// 送出文字欄位的 return，驗證一般鍵盤的收起路徑
    func submitCustomerName() {
        let field = app.textFields[BLAccessibilityID.OrderEdit.customerField]
        field.waitUntilHittable()
        field.typeText(XCUIKeyboardKey.return.rawValue)
    }

    /// 開啟訂單來源選擇器
    func openSourcePicker() {
        tapPickerRow(BLAccessibilityID.OrderEdit.sourceRow)
    }

    /// 開啟商品類別選擇器
    func openCategoryPicker() {
        tapPickerRow(BLAccessibilityID.OrderEdit.categoryRow)
    }

    /// 開啟付款方式選擇器
    func openPaymentPicker() {
        tapPickerRow(BLAccessibilityID.OrderEdit.paymentRow)
    }

    /// 填入客戶實付金額
    /// - Parameters:
    ///   - amount: 要填入的金額文字
    ///   - app: 受測 App
    ///   - dismissKeyboard: 是否在輸入後收起數字鍵盤
    func typeChargedAmount(
        _ amount: String,
        in app: XCUIApplication,
        dismissKeyboard: Bool = true
    ) {
        let field = app.textFields[BLAccessibilityID.OrderEdit.chargedAmountField]
        // 使用預設拖曳範圍，避免 iPhone 找不到可點擊位置
        app.scrollToHittableGently(field, within: rootElement)
        guard field.waitForExistence(timeout: 5) else {
            return
        }
        let doneButton = app.buttons[BLAccessibilityID.Common.keyboardDoneButton]
        var focusAttempts = 0
        repeat {
            // decimalPad 出現後 SwiftUI 會自動把此欄捲到鍵盤上方，聚焦與輸入才成立
            field.tap()
            focusAttempts += 1
        } while !doneButton.waitForExistence(timeout: 2) && focusAttempts < 3
        if let existing = field.value as? String, existing != amount {
            let deletes = String(repeating: XCUIKeyboardKey.delete.rawValue, count: existing.count)
            field.typeText(deletes)
        }
        field.typeText(amount)
        if dismissKeyboard {
            field.dismissNumericKeyboard(in: app)
        }
    }

    /// 點數字鍵盤工具列的完成鍵
    func tapNumericKeyboardDone() {
        let button = app.buttons[BLAccessibilityID.Common.keyboardDoneButton]
        button.waitUntilHittable()
        button.tap()
    }

    /// 捲到照片區並點指定序位的照片縮圖，開啟照片檢視器
    /// - Parameter index: 照片縮圖的序位
    func tapPhotoThumbnail(index: Int) {
        let thumbnail = app.descendants(matching: .any)[
            BLAccessibilityID.OrderEdit.photoThumbnail(index: index)
        ]
        var attempts = 0
        while !thumbnail.exists, attempts < 8 {
            rootElement.swipeUp()
            attempts += 1
        }
        app.scrollToHittable(thumbnail, within: rootElement)
        thumbnail.waitUntilHittable()
        thumbnail.tap()
    }

    /// 點工具列的儲存
    func tapSave() {
        let button = app.buttons[BLAccessibilityID.OrderEdit.saveButton]
        button.waitUntilHittable()
        button.tap()
    }

    /// 點工具列的取消
    func tapCancel() {
        let button = app.buttons[BLAccessibilityID.OrderEdit.cancelButton]
        button.waitUntilHittable()
        button.tap()
    }
}

// MARK: - Private Method

@MainActor
private extension OrderEditScreen {

    /// 點某個選擇器入口列開啟選擇器
    /// - Parameter identifier: 選擇器入口列的 accessibility identifier
    func tapPickerRow(_ identifier: String) {
        let row = app.descendants(matching: .any)[identifier]
        if !row.isHittable {
            app.scrollToHittable(row, within: rootElement)
        }
        row.waitUntilHittable()
        row.tap()
    }
}
