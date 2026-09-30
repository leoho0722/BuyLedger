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

// MARK: - Computed Properties

extension LookupManagementScreen {

    /// 新增主檔項目的按鈕
    var addButton: XCUIElement {
        app.buttons[BLAccessibilityID.LookupManagement.addButton]
    }

    /// 主檔載入失敗文字
    var loadFailureMessage: XCUIElement {
        app.descendants(matching: .any)[BLAccessibilityID.LookupManagement.loadFailureMessage]
    }
}

// MARK: - Internal Method

@MainActor
extension LookupManagementScreen {

    /// 從更多頁開啟商品類別管理
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func openCategoryManagement(
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let root = RootNavigationScreen(app: app)
        guard root.goToMore(file: file, line: line) else {
            app.failWithDiagnostics(
                "切到更多分頁後畫面未就緒",
                file: file,
                line: line
            )
            return
        }

        let categoriesRow = app.descendants(matching: .any)[
            BLAccessibilityID.More.row(.categories)
        ]
        categoriesRow.tapAfterWaiting(
            in: app,
            elementName: "商品類別主檔入口",
            file: file,
            line: line
        )

        if !waitUntilReady() {
            app.failWithDiagnostics(
                "商品類別管理頁面未出現",
                file: file,
                line: line
            )
        }
    }

    /// 新增指定名稱的主檔項目
    ///
    /// - Parameters:
    ///   - name: 要新增的主檔名稱
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func addItem(
        named name: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
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
            app.failWithDiagnostics(
                "商品類別「\(oldName)」列未出現或無法操作",
                file: file,
                line: line
            )
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

    /// 取得指定名稱的主檔列
    ///
    /// - Parameter name: 主檔項目名稱
    /// - Returns: 對應的主檔列元素
    func itemRow(named name: String) -> XCUIElement {
        app.descendants(matching: .any)[BLAccessibilityID.LookupManagement.row(name)]
    }

    /// 刪除指定名稱的主檔項目並等待提示關閉
    ///
    /// - Parameters:
    ///   - name: 要刪除的主檔名稱
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func deleteItem(
        named name: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard requestDeletion(named: name, file: file, line: line) else {
            return
        }

        let alert = app.alerts.firstMatch
        if !alert.waitForDisappearance(timeout: 5) {
            app.failWithDiagnostics(
                "確認刪除後 alert 未收回",
                file: file,
                line: line
            )
        }
    }

    /// 送出指定名稱主檔項目的刪除請求
    ///
    /// - Parameters:
    ///   - name: 要刪除的主檔名稱
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 是否已送出刪除請求
    func requestDeletion(
        named name: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Bool {
        let row = itemRow(named: name)
        guard row.waitUntilHittable(timeout: 10) else {
            app.failWithDiagnostics(
                "商品類別「\(name)」列未出現或無法操作",
                file: file,
                line: line
            )
            return false
        }
        row.swipeLeft()
        let deleteButton = app.buttons[BLAccessibilityID.LookupManagement.deleteButton(name)]
        deleteButton.tapAfterWaiting(
            in: app,
            elementName: "主檔刪除按鈕",
            file: file,
            line: line
        )

        let alert = app.alerts.firstMatch
        guard alert.waitForExistence(timeout: 10) else {
            app.failWithDiagnostics(
                "刪除確認 alert 未出現",
                file: file,
                line: line
            )
            return false
        }
        app.tapAlertButton(label: "刪除", file: file, line: line)
        return true
    }
}

// MARK: - Screen

extension LookupManagementScreen: Screen {

    /// 判定主檔管理頁已就緒的根 identifier
    ///
    /// - Returns: 主檔管理頁根元素的 identifier
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
    func enterName(
        _ name: String,
        file: StaticString,
        line: UInt
    ) {
        let field = app.textFields[BLAccessibilityID.LookupManagement.nameField]
        field.clearAndType(name, in: app, file: file, line: line)

        let submitButton = app.buttons[BLAccessibilityID.LookupManagement.nameSubmitButton]
        submitButton.tapAfterWaiting(
            in: app,
            elementName: "主檔名稱表單送出按鈕",
            file: file,
            line: line
        )
    }
}
