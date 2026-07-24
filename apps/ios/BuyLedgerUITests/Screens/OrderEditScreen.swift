//
//  OrderEditScreen.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 訂單編輯表單的 Page Object
///
/// 以 accessibility identifier 對外暴露客戶名輸入、各選擇器入口、收款金額輸入與儲存／取消的語意操作，元素查詢細節不外洩給測試檔；
/// 新增與編輯共用同一組 identifier，故 Page Object 不分兩種流程
struct OrderEditScreen: Screen {

    // MARK: - Data Properties

    /// 受測 App
    let app: XCUIApplication

    // MARK: - Computed Properties

    /// 判定編輯表單已就緒的根 identifier (表單捲動容器)
    var rootIdentifier: String {
        BLAccessibilityID.OrderEdit.root
    }

    /// 儲存按鈕目前是否可用
    ///
    /// 讀值前先等按鈕存在，避免元素尚未出現時 `isEnabled` 回傳 `false` 被誤判為停用
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
    ///
    /// 客戶名欄在表單最上方，若先前操作把表單捲下去了，先向下滑回頂端把它帶回畫面再輸入
    /// - Parameter name: 要輸入的客戶名稱 (使用者資料)
    func typeCustomerName(_ name: String) {
        let field = app.textFields[BLAccessibilityID.OrderEdit.customerField]
        var attempts = 0
        while !field.exists, attempts < 5 {
            rootElement.swipeDown()
            attempts += 1
        }
        field.waitUntilHittable()
        field.clearAndType(name, in: app)
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

    /// 填入客戶實付金額後收起數字鍵盤
    ///
    /// 此欄在 iPad 置中 sheet 上僅差數點露出於表單底緣下方，整頁 swipe 的慣性會一口氣衝過它、把它捲離螢幕，
    /// 故改以小幅拖曳逐步逼近;此欄始終在樹上、frame 有效，可直接查可點
    /// - Parameters:
    ///   - amount: 要輸入的金額字串
    ///   - app: 受測 App，供收數字鍵盤時定位鍵盤工具列
    func typeChargedAmount(_ amount: String, in app: XCUIApplication) {
        let field = app.textFields[BLAccessibilityID.OrderEdit.chargedAmountField]
        app.scrollToHittableGently(field, within: rootElement)
        field.waitUntilHittable()
        // decimalPad 出現後 SwiftUI 會自動把此欄捲到鍵盤上方，聚焦與輸入才成立
        field.tap()
        if let existing = field.value as? String, existing != amount {
            let deletes = String(repeating: XCUIKeyboardKey.delete.rawValue, count: existing.count)
            field.typeText(deletes)
        }
        field.typeText(amount)
        field.dismissNumericKeyboard(in: app)
    }

    /// 捲到照片區並點指定序位的照片縮圖，開啟照片檢視器
    ///
    /// 縮圖是水平列內的 `Button`，XCUITest 可能歸為 button 或其他型別，故以 any 查詢。照片列在表單下半、屬離屏惰性列，
    /// 先以「查存在」逐次上滑把它捲入樹 (對尚未渲染的惰性列直接查 hittability 會因 frame 無效而報錯，非回 false)，
    /// 進樹 frame 穩定後再捲到可點才點
    /// - Parameter index: 縮圖序位 (0 起算)
    func tapPhotoThumbnail(index: Int) {
        let thumbnail = app.descendants(matching: .any)[BLAccessibilityID.OrderEdit.photoThumbnail(index: index)]
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
    ///
    /// 選擇器入口是 `Form` row 內的 Button，XCUITest 可能歸為 button 或 staticText，故以 any 查詢；離屏時先捲入可點位置
    /// - Parameter identifier: 該入口列的 accessibility identifier
    func tapPickerRow(_ identifier: String) {
        let row = app.descendants(matching: .any)[identifier]
        if !row.isHittable {
            app.scrollToHittable(row, within: rootElement)
        }
        row.waitUntilHittable()
        row.tap()
    }
}
