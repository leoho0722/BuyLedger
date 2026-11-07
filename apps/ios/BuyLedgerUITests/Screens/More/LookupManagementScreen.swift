//
//  LookupManagementScreen.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/9/24.
//

import XCTest

/// 商品類別主檔管理頁的 Page Object
struct LookupManagementScreen {

    // MARK: - Properties

    /// 受測 App
    let app: XCUIApplication
}

// MARK: - Nested Types

extension LookupManagementScreen {

    /// 刪除主檔項目的觸發方式
    enum DeletionTrigger {

        /// 向左滑動列後點刪除鈕
        case swipe

        /// 長按列開啟內容選單後點刪除
        case contextMenu
    }
}

// MARK: - Computed Properties

@MainActor
extension LookupManagementScreen {

    /// 單欄主檔名稱輸入欄位
    var nameField: XCUIElement {
        app.textFields[BLAccessibilityID.LookupManagement.nameField]
    }

    /// 付款方式名稱輸入欄位
    var paymentMethodNameField: XCUIElement {
        app.textFields[BLAccessibilityID.LookupManagement.paymentMethodNameField]
    }

    /// 新增主檔項目的按鈕
    var addButton: XCUIElement {
        app.buttons[BLAccessibilityID.LookupManagement.addButton]
    }

    /// 主檔載入失敗文字
    var loadFailureMessage: XCUIElement {
        app.descendants(matching: .any)[BLAccessibilityID.LookupManagement.loadFailureMessage]
    }

    /// 目前清單中的主檔列數，以列識別碼前綴計數
    var rowCount: Int {
        let rowPrefix = BLAccessibilityID.LookupManagement.row("")
        return app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH %@", rowPrefix))
            .count
    }

    /// 清單標題的文字，例如「目前已建立 4 項」；標題不存在時為空字串
    var itemCountHeaderLabel: String {
        app.descendants(matching: .any)[BLAccessibilityID.LookupManagement.itemCountHeader]
            .firstMatch
            .label
    }

    /// 名稱表單的文字值
    ///
    /// - Returns: 名稱欄的文字值；元素不存在或值不是字串時為 `nil`
    var nameFieldValue: String? {
        let field = app.textFields[BLAccessibilityID.LookupManagement.nameField]
        guard field.waitForExistence(timeout: 10) else {
            return nil
        }
        return field.value as? String
    }

    /// 目前呈現中的名稱表單數量，用來確認表單沒有疊出第二層
    ///
    /// - Note: `app.sheets` 只對應動作表，不含 SwiftUI sheet，故以名稱表單根識別碼計數
    var presentedSheetCount: Int {
        app.descendants(matching: .any)
            .matching(identifier: BLAccessibilityID.LookupManagement.nameEditorRoot)
            .count
    }

    /// 名稱表單的根元素，用來等待表單關閉
    var nameEditorRoot: XCUIElement {
        let identifier = BLAccessibilityID.LookupManagement.nameEditorRoot
        return app.descendants(matching: .any)[identifier].firstMatch
    }
}

// MARK: - Internal Method

@MainActor
extension LookupManagementScreen {

    /// 從更多頁開啟付款方式管理
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func openPaymentMethodManagement(file: StaticString = #filePath, line: UInt = #line) {
        guard RootNavigationScreen(app: app).goToMore(file: file, line: line) else {
            app.failWithDiagnostics("切到更多分頁後畫面未就緒", file: file, line: line)
            return
        }
        let row = app.descendants(matching: .any)[BLAccessibilityID.More.row(.paymentMethods)]
        row.tapAfterWaiting(in: app, file: file, line: line)
        if !waitUntilReady() {
            app.failWithDiagnostics("付款方式管理頁面未出現", file: file, line: line)
        }
    }

    /// 開啟既有付款方式的編輯表單，不改動名稱
    ///
    /// - Parameters:
    ///   - name: 目前的付款方式名稱
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func beginEditPaymentMethod(
        named name: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let row = itemRow(named: name)
        guard row.waitUntilHittable(timeout: 10) else {
            app.failWithDiagnostics("付款方式「\(name)」列未出現或無法操作", file: file, line: line)
            return
        }
        row.swipeLeft()
        let editButton = app.buttons[BLAccessibilityID.LookupManagement.editButton(name)]
        editButton.tapAfterWaiting(in: app, file: file, line: line)
        let editor = PaymentMethodEditorScreen(app: app)
        if !editor.waitUntilReady() {
            app.failWithDiagnostics("付款方式編輯表單未出現", file: file, line: line)
        }
    }

    /// 以 return 收起單行名稱欄的鍵盤並確認焦點解除
    ///
    /// - Parameters:
    ///   - field: 主檔或付款方式的單行名稱欄位
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 欄位是否已失焦且鍵盤已收起
    func dismissKeyboard(
        for field: XCUIElement,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Bool {
        guard field.waitForExistence(timeout: 10) else {
            app.failWithDiagnostics("找不到要解除焦點的名稱欄位", file: file, line: line)
            return false
        }
        let predicate = NSPredicate(format: "hasKeyboardFocus == true")
        if predicate.evaluate(with: field) {
            field.typeText(XCUIKeyboardKey.return.rawValue)
        }
        let hasDismissed = pollUntil(timeout: 10) {
            !predicate.evaluate(with: field)
                && !app.keyboards.firstMatch.exists
                && !app.isNumericPopoverPresented
        }
        guard hasDismissed else {
            app.failWithDiagnostics("名稱欄的鍵盤或焦點仍未解除", file: file, line: line)
            return false
        }
        return true
    }

    /// 從更多頁開啟商品類別管理
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func openCategoryManagement(file: StaticString = #filePath, line: UInt = #line) {
        let root = RootNavigationScreen(app: app)
        guard root.goToMore(file: file, line: line) else {
            app.failWithDiagnostics("切到更多分頁後畫面未就緒", file: file, line: line)
            return
        }

        let categoriesRow = app.descendants(matching: .any)[BLAccessibilityID.More.row(.categories)]
        categoriesRow.tapAfterWaiting(
            in: app,
            elementName: "商品類別主檔入口",
            file: file,
            line: line
        )

        if !waitUntilReady() {
            app.failWithDiagnostics("商品類別管理頁面未出現", file: file, line: line)
        }
    }

    /// 新增指定名稱的主檔項目
    ///
    /// - Parameters:
    ///   - name: 要新增的主檔名稱
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func addItem(named name: String, file: StaticString = #filePath, line: UInt = #line) {
        addButton.tapAfterWaiting(
            in: app,
            elementName: "主檔新增按鈕",
            file: file,
            line: line
        )
        enterName(name, file: file, line: line)
    }

    /// 將主檔項目改成指定名稱
    ///
    /// - Parameters:
    ///   - oldName: 目前的主檔名稱
    ///   - newName: 要套用的新名稱
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func renameItem(
        from oldName: String,
        to newName: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let row = itemRow(named: oldName)
        guard row.waitUntilHittable(timeout: 10) else {
            app.failWithDiagnostics("商品類別「\(oldName)」列未出現或無法操作", file: file, line: line)
            return
        }
        row.swipeLeft()
        let renameButton = app.buttons[BLAccessibilityID.LookupManagement.renameButton(oldName)]
        renameButton.tapAfterWaiting(
            in: app,
            elementName: "主檔重新命名按鈕",
            file: file,
            line: line
        )
        enterName(newName, file: file, line: line)
    }

    /// 刪除指定名稱的主檔項目並等待提示關閉
    ///
    /// - Parameters:
    ///   - name: 要刪除的主檔名稱
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func deleteItem(named name: String, file: StaticString = #filePath, line: UInt = #line) {
        guard requestDeletion(named: name, file: file, line: line) else {
            return
        }

        let alert = app.alerts.firstMatch
        if !alert.waitForDisappearance(timeout: 5) {
            app.failWithDiagnostics("確認刪除後 alert 未收回", file: file, line: line)
        }
    }

    /// 送出指定名稱主檔項目的刪除請求，並在確認對話框按下「刪除」
    ///
    /// - Parameters:
    ///   - name: 要刪除的主檔名稱
    ///   - trigger: 刪除的觸發方式，預設為滑動刪除
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 是否已送出刪除請求
    func requestDeletion(
        named name: String,
        via trigger: DeletionTrigger = .swipe,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Bool {
        guard beginDeletion(
            named: name,
            via: trigger,
            file: file,
            line: line
        ) else {
            return false
        }
        app.tapAlertButton(label: "刪除", file: file, line: line)
        return true
    }

    /// 以指定方式刪除主檔列，等待確認對話框出現但不回應
    ///
    /// - Parameters:
    ///   - name: 要刪除的主檔名稱
    ///   - trigger: 刪除的觸發方式，預設為滑動刪除
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 確認對話框是否已出現
    func beginDeletion(
        named name: String,
        via trigger: DeletionTrigger = .swipe,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Bool {
        let row = itemRow(named: name)
        guard row.waitUntilHittable(timeout: 10) else {
            app.failWithDiagnostics("商品類別「\(name)」列未出現或無法操作", file: file, line: line)
            return false
        }
        switch trigger {
        case .swipe:
            row.swipeLeft()
            let deleteButton = app.buttons[BLAccessibilityID.LookupManagement.deleteButton(name)]
            deleteButton.tapAfterWaiting(
                in: app,
                elementName: "主檔刪除按鈕",
                file: file,
                line: line
            )

        case .contextMenu:
            row.press(forDuration: 1.0)
            guard app.tapMenuItem(
                BLAccessibilityID.LookupManagement.deleteButton(name),
                file: file,
                line: line
            ) else {
                return false
            }
        }
        return waitForDeletionConfirmation(file: file, line: line)
    }

    /// 判定名稱欄是否取得鍵盤焦點
    ///
    /// - Returns: 名稱欄是否為鍵盤焦點
    func isNameFieldFocused() -> Bool {
        let field = app.textFields[BLAccessibilityID.LookupManagement.nameField]
        return field.exists && NSPredicate(format: "hasKeyboardFocus == true").evaluate(with: field)
    }

    /// 清空名稱欄後輸入新文字，之後鍵盤焦點保留在名稱欄
    ///
    /// - Parameters:
    ///   - text: 要輸入的名稱
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func replaceName(_ text: String, file: StaticString = #filePath, line: UInt = #line) {
        let field = app.textFields[BLAccessibilityID.LookupManagement.nameField]
        field.clearAndType(
            text,
            in: app,
            file: file,
            line: line
        )
    }

    /// 續打名稱欄文字，呼叫端需先確認焦點，續打時不點擊
    ///
    /// - Parameter text: 要續打的文字
    func appendName(_ text: String) {
        let field = app.textFields[BLAccessibilityID.LookupManagement.nameField]
        field.typeText(text)
    }

    /// 點名稱表單的取消按鈕
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func tapNameCancel(file: StaticString = #filePath, line: UInt = #line) {
        let button = app.buttons[BLAccessibilityID.LookupManagement.nameCancelButton]
        button.tapAfterWaiting(
            in: app,
            elementName: "主檔名稱表單取消按鈕",
            file: file,
            line: line
        )
    }

    /// 點新增按鈕開啟新增表單，不輸入內容
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func beginAddItem(file: StaticString = #filePath, line: UInt = #line) {
        addButton.tapAfterWaiting(
            in: app,
            elementName: "主檔新增按鈕",
            file: file,
            line: line
        )
    }

    /// 開啟指定主檔列的改名表單，不輸入內容
    ///
    /// - Parameters:
    ///   - name: 目前的主檔名稱
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func beginRename(from name: String, file: StaticString = #filePath, line: UInt = #line) {
        let row = itemRow(named: name)
        guard row.waitUntilHittable(timeout: 10) else {
            app.failWithDiagnostics("商品類別「\(name)」列未出現或無法操作", file: file, line: line)
            return
        }
        row.swipeLeft()
        let renameButton = app.buttons[BLAccessibilityID.LookupManagement.renameButton(name)]
        renameButton.tapAfterWaiting(
            in: app,
            elementName: "主檔重新命名按鈕",
            file: file,
            line: line
        )
    }

    /// 取得指定名稱的主檔列
    ///
    /// - Parameter name: 主檔項目名稱
    /// - Returns: 對應的主檔列元素
    func itemRow(named name: String) -> XCUIElement {
        app.descendants(matching: .any)[BLAccessibilityID.LookupManagement.row(name)]
    }

    /// 等待清單列數符合預期，到逾時為止
    ///
    /// - Parameters:
    ///   - count: 預期的列數
    ///   - timeout: 等待列數符合的秒數
    /// - Returns: 列數是否在逾時前符合預期
    func waitForRowCount(_ count: Int, timeout: TimeInterval = 10) -> Bool {
        let deadline = Date.now.addingTimeInterval(timeout)
        while rowCount != count {
            guard Date.now < deadline else {
                return false
            }
            _ = XCTWaiter().wait(for: [XCTestExpectation()], timeout: 0.1)
        }
        return true
    }
}

// MARK: - Screen

extension LookupManagementScreen: Screen {

    /// 判定主檔管理頁已就緒的根 identifier
    var rootIdentifier: String {
        BLAccessibilityID.LookupManagement.root
    }
}

// MARK: - Private Method

@MainActor
private extension LookupManagementScreen {

    /// 在名稱表單填入內容並送出
    ///
    /// - Parameters:
    ///   - name: 要送出的主檔名稱
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func enterName(_ name: String, file: StaticString, line: UInt) {
        let field = app.textFields[BLAccessibilityID.LookupManagement.nameField]
        field.clearAndType(
            name,
            in: app,
            file: file,
            line: line
        )

        let submitButton = app.buttons[BLAccessibilityID.LookupManagement.nameSubmitButton]
        submitButton.tapAfterWaiting(
            in: app,
            elementName: "主檔名稱表單送出按鈕",
            file: file,
            line: line
        )
    }

    /// 等待刪除確認對話框出現
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 確認對話框是否在逾時前出現
    func waitForDeletionConfirmation(file: StaticString, line: UInt) -> Bool {
        let alert = app.alerts.firstMatch
        guard alert.waitForExistence(timeout: 10) else {
            app.failWithDiagnostics("刪除確認 alert 未出現", file: file, line: line)
            return false
        }
        return true
    }
}
