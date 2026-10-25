//
//  OrderEditScreen.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 訂單編輯表單的 Page Object
struct OrderEditScreen {

    // MARK: - Properties

    /// 受測 App
    let app: XCUIApplication
}

// MARK: - Computed Properties

@MainActor
extension OrderEditScreen {

    /// 基本資料區段的訂購日期選擇器
    var orderDatePicker: XCUIElement {
        app.descendants(matching: .any)[BLAccessibilityID.OrderEdit.orderDatePicker]
    }

    /// 基本資料區段頁尾的訂購時間戳
    var orderDateTimestamp: XCUIElement {
        app.descendants(matching: .any)[BLAccessibilityID.OrderEdit.orderDateTimestamp]
    }
}

// MARK: - Internal Method

@MainActor
extension OrderEditScreen {

    /// 判定儲存按鈕目前是否可用
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 儲存按鈕是否可用
    func isSaveEnabled(file: StaticString = #filePath, line: UInt = #line) -> Bool {
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
    func typeCustomerName(_ name: String, file: StaticString = #filePath, line: UInt = #line) {
        let field = app.textFields[BLAccessibilityID.OrderEdit.customerField]
        guard revealFormElement(field, isSwipingUp: false) else {
            app.failWithDiagnostics("捲到頂端或達 8 次上限後仍找不到可點的客戶名稱欄位", file: file, line: line)
            return
        }
        field.clearAndType(
            name,
            in: app,
            file: file,
            line: line
        )
    }

    /// 點客戶名稱欄後按 return 送出，走一般鍵盤的收起路徑
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

    /// 開啟幣別選擇器
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func openCurrencyPicker(file: StaticString = #filePath, line: UInt = #line) {
        let customerField = app.textFields[BLAccessibilityID.OrderEdit.customerField]
        let keyboard = app.keyboards.firstMatch
        if keyboard.exists {
            customerField.typeText(XCUIKeyboardKey.return.rawValue)
            if !keyboard.waitForDisappearance(timeout: 5) {
                app.failWithDiagnostics("訂單編輯的文字鍵盤未能收起", file: file, line: line)
                return
            }
        }

        let row = app.descendants(matching: .any)[BLAccessibilityID.OrderEdit.currencyRow]
        if !row.waitForExistence(timeout: 10) {
            app.failWithDiagnostics("找不到幣別選擇列", file: file, line: line)
            return
        }

        tapPickerRow(BLAccessibilityID.OrderEdit.currencyRow, file: file, line: line)
    }

    /// 填入客戶實付金額
    ///
    /// - Parameters:
    ///   - amount: 要填入的金額文字
    ///   - app: 受測 App
    ///   - shouldDismissKeyboard: 是否在輸入後收起數字鍵盤
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func typeChargedAmount(
        _ amount: String,
        in app: XCUIApplication,
        shouldDismissKeyboard: Bool = true,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let field = app.textFields[BLAccessibilityID.OrderEdit.chargedAmountField]
        // 使用預設拖曳範圍，避免 iPhone 找不到可點擊位置
        if !app.scrollToHittableGently(field, within: rootElement) {
            // XCTest 的第一次點擊會觸發原生 scroll-to-focus
            // 之後才由 `clearAndType` 輸入
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
        if shouldDismissKeyboard {
            field.dismissNumericKeyboard(in: app, file: file, line: line)
        }
    }

    /// 點數字鍵盤工具列的完成鍵
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func tapNumericKeyboardDone(file: StaticString = #filePath, line: UInt = #line) {
        let field = app.textFields[BLAccessibilityID.OrderEdit.chargedAmountField]
        field.dismissNumericKeyboard(in: app, file: file, line: line)
    }

    /// 捲到照片區並點指定序位的照片縮圖，開啟照片檢視器
    ///
    /// - Parameters:
    ///   - index: 照片縮圖的序位
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func tapPhotoThumbnail(index: Int, file: StaticString = #filePath, line: UInt = #line) {
        let thumbnail = app.descendants(matching: .any)[
            BLAccessibilityID.OrderEdit.photoThumbnail(index: index)
        ]
        if !revealFormElement(thumbnail, isSwipingUp: true),
           !app.scrollToHittable(thumbnail, within: rootElement) {
            app.failWithDiagnostics("捲到照片區底端或達上限後仍找不到可點的照片縮圖", file: file, line: line)
            return
        }
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

// MARK: - Screen

extension OrderEditScreen: Screen {

    /// 判定編輯表單已就緒的根 identifier (表單捲動容器)
    var rootIdentifier: String {
        BLAccessibilityID.OrderEdit.root
    }
}

// MARK: - Private Method

@MainActor
private extension OrderEditScreen {

    /// 依指定方向尋找表單元素，位置簽章不再變動或達八次上限時停止
    ///
    /// - Parameters:
    ///   - element: 要捲進可點範圍的表單元素
    ///   - isSwipingUp: 是否向上滑動以尋找下方內容
    /// - Returns: 目標是否已連續兩次取得相同的有效框線且可點
    func revealFormElement(_ element: XCUIElement, isSwipingUp: Bool) -> Bool {
        let container = rootElement
        guard container.waitForExistence(timeout: 5) else {
            return false
        }
        if element.snapshotFrame != nil, element.waitUntilStableAndHittable(timeout: 1) {
            return true
        }
        var previous = app.scrollPositionSignature(in: container)
        for _ in 0..<8 {
            if isSwipingUp {
                container.swipeUp()
            } else {
                container.swipeDown()
            }
            if element.waitUntilStableAndHittable(timeout: 1) {
                return true
            }
            let current = app.scrollPositionSignature(in: container)
            if let current, current == previous {
                return false
            }
            previous = current
        }
        return element.waitUntilStableAndHittable(timeout: 1)
    }

    /// 點某個選擇器入口列開啟選擇器
    ///
    /// - Parameters:
    ///   - identifier: 選擇器入口列的 accessibility identifier
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func tapPickerRow(_ identifier: String, file: StaticString = #filePath, line: UInt = #line) {
        let row = app.descendants(matching: .any)[identifier]
        if !row.isHittableOnScreen, !app.scrollToHittable(row, within: rootElement) {
            app.failWithDiagnostics("捲動後選擇器入口列仍未穩定或不可點", file: file, line: line)
            return
        }
        row.tapAfterWaiting(in: app, file: file, line: line)
    }
}
