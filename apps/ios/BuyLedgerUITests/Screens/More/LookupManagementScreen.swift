//
//  LookupManagementScreen.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/9/24.
//

import XCTest

/// 主檔管理頁的 Page Object，依種類操作不同主檔
struct LookupManagementScreen {

    // MARK: - Properties

    /// 受測 App
    let app: XCUIApplication
}

// MARK: - Nested Types

extension LookupManagementScreen {

    /// 主檔管理頁所操作的項目種類
    enum Kind {

        /// 商品類別
        case categories

        /// 付款方式
        case paymentMethods
    }

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
    /// - Parameter timeout: 等待欄位出現的秒數
    /// - Returns: 名稱欄的文字值；元素不存在或值不是字串時為 `nil`
    func nameFieldValue(timeout: TimeInterval = 10) -> String? {
        let field = app.textFields[BLAccessibilityID.LookupManagement.nameField]
        guard field.waitForExistence(timeout: timeout) else {
            return nil
        }
        return field.value as? String
    }

    /// 目前呈現中的名稱表單數量，用來確認表單沒有疊出第二層
    ///
    /// - Note: `app.sheets` 不含 SwiftUI sheet，故以名稱表單根識別碼計數
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

    /// 從更多分頁開啟指定種類的主檔管理頁
    ///
    /// - Parameters:
    ///   - kind: 主檔項目種類
    ///   - app: 受測 App
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 已進入前景的主檔管理頁
    /// - Throws: 分頁、入口或主檔前景未就緒時丟出測試錯誤
    @discardableResult
    static func open(
        _ kind: Kind,
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) -> LookupManagementScreen {
        let root = RootNavigationScreen(app: app)
        try root.goToMore(file: file, line: line)
        let row: BLAccessibilityID.More.Row
        switch kind {
        case .categories:
            row = .categories

        case .paymentMethods:
            row = .paymentMethods
        }
        let entry = app.descendants(matching: .any)[BLAccessibilityID.More.row(row)]
        try entry.tapAfterWaiting(in: app, file: file, line: line)
        try root.requireForeground(
            identifiers: [
                BLAccessibilityID.LookupManagement.root,
                BLAccessibilityID.LookupManagement.addButton,
                BLAccessibilityID.LookupManagement.loadFailureMessage,
            ],
            identifierPrefixes: [BLAccessibilityID.LookupManagement.row("")],
            message: "主檔管理頁前景內容未就緒",
            file: file,
            line: line
        )
        return LookupManagementScreen(app: app)
    }

    /// 開啟既有付款方式的編輯表單，不改動名稱
    ///
    /// - Parameters:
    ///   - name: 目前的付款方式名稱
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 已就緒的付款方式編輯表單
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    @discardableResult
    func beginEditPaymentMethod(
        named name: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) -> PaymentMethodEditorScreen {
        let row = itemRow(named: name)
        guard row.waitUntilHittable(timeout: 10) else {
            try app.stopWithDiagnostics(
                "付款方式「\(name)」列未出現或無法操作",
                file: file,
                line: line
            )
        }
        row.swipeLeft()
        let editButton = app.buttons[BLAccessibilityID.LookupManagement.editButton(name)]
        try editButton.tapAfterWaiting(in: app, file: file, line: line)
        let editor = PaymentMethodEditorScreen(app: app)
        try editor.requireReady(file: file, line: line)
        return editor
    }

    /// 以 return 收起單行名稱欄的鍵盤並確認焦點解除
    ///
    /// - Parameters:
    ///   - field: 主檔或付款方式的單行名稱欄位
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 欄位不存在或 Return 後焦點未解除時丟出測試錯誤
    func dismissKeyboard(
        for field: XCUIElement,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        try field.dismissKeyboardByReturn(in: app, file: file, line: line)
    }

    /// 新增指定名稱的主檔項目
    ///
    /// - Parameters:
    ///   - name: 要新增的主檔名稱
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    func addItem(
        named name: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        try addButton.tapAfterWaiting(
            in: app,
            elementName: "主檔新增按鈕",
            file: file,
            line: line
        )
        try enterName(name, file: file, line: line)
    }

    /// 將主檔項目改成指定名稱
    ///
    /// - Parameters:
    ///   - oldName: 目前的主檔名稱
    ///   - newName: 要套用的新名稱
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    func renameItem(
        from oldName: String,
        to newName: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        let row = itemRow(named: oldName)
        guard row.waitUntilHittable(timeout: 10) else {
            try app.stopWithDiagnostics(
                "主檔「\(oldName)」列未出現或無法操作",
                file: file,
                line: line
            )
        }
        row.swipeLeft()
        let renameButton = app.buttons[BLAccessibilityID.LookupManagement.renameButton(oldName)]
        try renameButton.tapAfterWaiting(
            in: app,
            elementName: "主檔重新命名按鈕",
            file: file,
            line: line
        )
        try enterName(newName, file: file, line: line)
    }

    /// 刪除指定名稱的主檔項目並等待提示關閉
    ///
    /// - Parameters:
    ///   - name: 要刪除的主檔名稱
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    func deleteItem(
        named name: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        try requestDeletion(named: name, file: file, line: line)
        let alert = app.alerts.firstMatch
        guard alert.waitForDisappearance(timeout: 5) else {
            try app.stopWithDiagnostics("確認刪除後 alert 未收回", file: file, line: line)
        }
    }

    /// 送出指定名稱主檔項目的刪除請求，並在確認對話框按下「刪除」
    ///
    /// - Parameters:
    ///   - name: 要刪除的主檔名稱
    ///   - trigger: 刪除的觸發方式，預設為滑動刪除
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    func requestDeletion(
        named name: String,
        via trigger: DeletionTrigger = .swipe,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        try beginDeletion(
            named: name,
            via: trigger,
            file: file,
            line: line
        )
        try app.tapAlertButton(label: "刪除", file: file, line: line)
    }

    /// 以指定方式刪除主檔列，等待確認對話框出現但不回應
    ///
    /// - Parameters:
    ///   - name: 要刪除的主檔名稱
    ///   - trigger: 刪除的觸發方式，預設為滑動刪除
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    func beginDeletion(
        named name: String,
        via trigger: DeletionTrigger = .swipe,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        let row = itemRow(named: name)
        guard row.waitUntilHittable(timeout: 10) else {
            try app.stopWithDiagnostics(
                "主檔「\(name)」列未出現或無法操作",
                file: file,
                line: line
            )
        }
        switch trigger {
        case .swipe:
            row.swipeLeft()
            let deleteButton = app.buttons[BLAccessibilityID.LookupManagement.deleteButton(name)]
            try deleteButton.tapAfterWaiting(
                in: app,
                elementName: "主檔刪除按鈕",
                file: file,
                line: line
            )

        case .contextMenu:
            row.press(forDuration: 1.0)
            try app.tapMenuItem(
                BLAccessibilityID.LookupManagement.deleteButton(name),
                file: file,
                line: line
            )
        }
        guard waitForDeleteConfirmation() else {
            try app.stopWithDiagnostics("刪除確認 alert 未出現", file: file, line: line)
        }
    }

    /// 判定名稱欄是否取得鍵盤焦點
    ///
    /// - Returns: 名稱欄是否為鍵盤焦點
    func isNameFieldFocused() -> Bool {
        nameField.hasKeyboardFocus
    }

    /// 清空名稱欄後輸入新文字，之後鍵盤焦點保留在名稱欄
    ///
    /// - Parameters:
    ///   - text: 要輸入的名稱
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    func replaceName(
        _ text: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        let field = app.textFields[BLAccessibilityID.LookupManagement.nameField]
        try field.clearAndType(
            text,
            in: app,
            file: file,
            line: line
        )
    }

    /// 依 App 的聚焦行為接續輸入，不清空既有內容
    ///
    /// - Parameters:
    ///   - text: 要續打的文字
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Note: 欄位已聚焦時不再點擊；未聚焦時由共用輸入 helper 取得焦點
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    func appendName(
        _ text: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        let field = app.textFields[BLAccessibilityID.LookupManagement.nameField]
        try field.appendText(text, in: app, file: file, line: line)
    }

    /// 點名稱表單的取消按鈕
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    func tapNameCancel(file: StaticString = #filePath, line: UInt = #line) throws(UITestError) {
        let button = app.buttons[BLAccessibilityID.LookupManagement.nameCancelButton]
        try button.tapAfterWaiting(
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
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    func beginAddItem(file: StaticString = #filePath, line: UInt = #line) throws(UITestError) {
        try addButton.tapAfterWaiting(
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
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    func beginRename(
        from name: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        let row = itemRow(named: name)
        guard row.waitUntilHittable(timeout: 10) else {
            try app.stopWithDiagnostics(
                "主檔「\(name)」列未出現或無法操作",
                file: file,
                line: line
            )
        }
        row.swipeLeft()
        let renameButton = app.buttons[BLAccessibilityID.LookupManagement.renameButton(name)]
        try renameButton.tapAfterWaiting(
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

    /// 等待清單列數符合預期
    ///
    /// - Parameters:
    ///   - count: 預期的列數
    ///   - timeout: 等待列數符合的秒數
    /// - Returns: 列數是否在逾時前符合預期
    func waitForRowCount(_ count: Int, timeout: TimeInterval = 10) -> Bool {
        Polling.wait(timeout: timeout) {
            rowCount == count
        }
    }

    /// 讀取指定付款方式列的分類 accessibility value
    ///
    /// - Parameter name: 付款方式名稱
    /// - Returns: 分類值；列不存在或值不是字串時為 `nil`
    func paymentMethodClassification(named name: String) -> String? {
        let row = itemRow(named: name)
        guard row.exists else {
            return nil
        }
        return row.value as? String
    }

    /// 等待刪除確認 alert 出現
    ///
    /// - Parameter timeout: 等待 alert 出現的秒數
    /// - Returns: alert 是否在逾時前出現
    func waitForDeleteConfirmation(timeout: TimeInterval = 10) -> Bool {
        app.alerts.firstMatch.waitForExistence(timeout: timeout)
    }
}

// MARK: - ScreenProtocol

extension LookupManagementScreen: ScreenProtocol {

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
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    func enterName(_ name: String, file: StaticString, line: UInt) throws(UITestError) {
        let field = app.textFields[BLAccessibilityID.LookupManagement.nameField]
        try field.clearAndType(
            name,
            in: app,
            file: file,
            line: line
        )

        let submitButton = app.buttons[BLAccessibilityID.LookupManagement.nameSubmitButton]
        try submitButton.tapAfterWaiting(
            in: app,
            elementName: "主檔名稱表單送出按鈕",
            file: file,
            line: line
        )
    }
}
